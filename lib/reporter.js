/** @babel */

import _ from 'underscore-plus'
import os from 'os'
import stackTrace from 'stack-trace'
import fs from 'fs-plus'
import path from 'path'

const API_KEY = '7ddca14cb60cbd1cd12d1b252473b076'
const LIB_VERSION = require('../package.json')['version']
const StackTraceCache = new WeakMap()

export default class Reporter {
  constructor (params = {}) {
    this.request = params.request || window.fetch
    this.alwaysReport = params.hasOwnProperty('alwaysReport') ? params.alwaysReport : false
    this.reportPreviousErrors = params.hasOwnProperty('reportPreviousErrors') ? params.reportPreviousErrors : true
    this.reportedErrors = []
    this.reportedAssertionFailures = []
  }

  buildNotificationJSON (error, params) {
    return {
      apiKey: API_KEY,
      notifier: {
        name: 'Atom',
        version: LIB_VERSION,
        url: 'https://www.atom.io'
      },
      events: [{
        payloadVersion: "2",
        exceptions: [this.buildExceptionJSON(error, params.projectRoot)],
        severity: params.severity,
        user: {
          id: params.userId
        },
        app: {
          version: params.appVersion,
          releaseStage: params.releaseStage
        },
        device: {
          osVersion: params.osVersion
        },
        metaData: error.metadata
      }]
    }
  }

  buildExceptionJSON (error, projectRoot) {
    return {
      errorClass: error.constructor.name,
      message: error.message,
      stacktrace: this.buildStackTraceJSON(error, projectRoot)
    }
  }

  buildStackTraceJSON (error, projectRoot) {
    return this.parseStackTrace(error).map(callSite => {
      return {
        file: this.normalizePath(callSite.getFileName()),
        method: callSite.getMethodName() || callSite.getFunctionName() || "none",
        lineNumber: callSite.getLineNumber(),
        columnNumber: callSite.getColumnNumber(),
        inProject: !/node_modules/.test(callSite.getFileName())
      }
    })
  }

  normalizePath (path) {
    return path.replace('file:///', '')                         // Randomly inserted file url protocols
               .replace(/[/]/g, '\\')                           // Temp switch for Windows home matching
               .replace(fs.getHomeDirectory(), '~')             // Remove users home dir for apm-dev'ed packages
               .replace(/\\/g, '/')                             // Switch \ back to / for everyone
               .replace(/.*(\/(app\.asar|packages\/).*)/, '$1') // Remove everything before app.asar or pacakges
  }

  getDefaultNotificationParams () {
    return {
      userId: atom.config.get('exception-reporting.userId'),
      appVersion: atom.getVersion(),
      releaseStage: this.getReleaseChannel(atom.getVersion()),
      projectRoot: atom.getLoadSettings().resourcePath,
      osVersion: `${os.platform()}-${os.arch()}-${os.release()}`
    }
  }

  getReleaseChannel (version) {
    return (version.indexOf('beta') > -1)
      ? 'beta'
      : (version.indexOf('dev') > -1)
        ? 'dev'
        : 'stable'
  }

  performRequest (json) {
    this.request.call(null, 'https://notify.bugsnag.com', {
      method: 'POST',
      headers: new Headers({'Content-Type': 'application/json'}),
      body: JSON.stringify(json)
    })
  }

  shouldReport (error) {
    if (this.alwaysReport) return true // Used in specs
    if (atom.config.get('core.telemetryConsent') !== 'limited') return false
    if (atom.inDevMode()) return false

    let topFrame = this.parseStackTrace(error)[0]
    return topFrame &&
           topFrame.getFileName() &&
           topFrame.getFileName().indexOf(atom.getLoadSettings().resourcePath) === 0
  }

  parseStackTrace (error) {
    let callSites = StackTraceCache.get(error)
    if (callSites) {
      return callSites
    } else {
      callSites = stackTrace.parse(error)
      StackTraceCache.set(error, callSites)
      return callSites
    }
  }

  requestPrivateMetadataConsent (error, message, reportFn) {
    let notification, dismissSubscription

    function reportWithoutPrivateMetadata () {
      if (dismissSubscription) {
        dismissSubscription.dispose()
      }
      delete error.privateMetadata
      delete error.privateMetadataDescription
      reportFn(error)
      if (notification) {
        notification.dismiss()
      }
    }

    function reportWithPrivateMetadata () {
      if (error.metadata == null) {
        error.metadata = {}
      }
      for (let key in error.privateMetadata) {
        let value = error.privateMetadata[key]
        error.metadata[key] = value
      }
      reportWithoutPrivateMetadata()
    }

    const name = error.privateMetadataRequestName
    if (name != null) {
      if (localStorage.getItem(`private-metadata-request:${name}`)) {
        return reportWithoutPrivateMetadata(error)
      } else {
        localStorage.setItem(`private-metadata-request:${name}`, true)
      }
    }

    notification = atom.notifications.addInfo(message, {
      detail: error.privateMetadataDescription,
      description: "Are you willing to submit this information to a private server for debugging purposes?",
      dismissable: true,
      buttons: [
        {
          text: "No",
          onDidClick: reportWithoutPrivateMetadata
        },
        {
          text: "Yes, Submit for Debugging",
          onDidClick: reportWithPrivateMetadata
        }
      ]
    })

    dismissSubscription = notification.onDidDismiss(reportWithoutPrivateMetadata)
  }

  addPackageMetadata (error) {
    let activePackages = atom.packages.getActivePackages()
    const availablePackagePaths = atom.packages.getPackageDirPaths()
    if (activePackages.length > 0) {
      let userPackages = {}
      let bundledPackages = {}
      for (let pack of atom.packages.getActivePackages()) {
        if (availablePackagePaths.includes(path.dirname(pack.path))) {
          userPackages[pack.name] = pack.metadata.version
        } else {
          bundledPackages[pack.name] = pack.metadata.version
        }
      }

      if (error.metadata == null) { error.metadata = {} }
      error.metadata.bundledPackages = bundledPackages
      error.metadata.userPackages = userPackages
    }
  }

  addPreviousErrorsMetadata (error) {
    if (!this.reportPreviousErrors) return
    if (!error.metadata) error.metadata = {}
    error.metadata.previousErrors = this.reportedErrors.map(error => error.message)
    error.metadata.previousAssertionFailures = this.reportedAssertionFailures.map(error => error.message)
  }

  reportUncaughtException (error) {
    if (!this.shouldReport(error)) return

    this.addPackageMetadata(error)
    this.addPreviousErrorsMetadata(error)

    if ((error.privateMetadata != null) && (error.privateMetadataDescription != null)) {
      this.requestPrivateMetadataConsent(error, "The Atom team would like to collect the following information to resolve this error:", error => this.reportUncaughtException(error))
      return
    }

    let params = this.getDefaultNotificationParams()
    params.severity = "error"
    this.performRequest(this.buildNotificationJSON(error, params))
    this.reportedErrors.push(error)
  }

  reportFailedAssertion (error) {
    if (!this.shouldReport(error)) return

    this.addPackageMetadata(error)
    this.addPreviousErrorsMetadata(error)

    if ((error.privateMetadata != null) && (error.privateMetadataDescription != null)) {
      this.requestPrivateMetadataConsent(error, "The Atom team would like to collect some information to resolve an unexpected condition:", error => this.reportFailedAssertion(error))
      return
    }

    let params = this.getDefaultNotificationParams()
    params.severity = "warning"
    this.performRequest(this.buildNotificationJSON(error, params))
    this.reportedAssertionFailures.push(error)
  }

  // Used in specs
  setRequestFunction (requestFunction) {
    this.request = requestFunction
  }
}

Reporter.API_KEY = API_KEY
Reporter.LIB_VERSION = LIB_VERSION
