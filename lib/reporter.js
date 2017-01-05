/** @babel */

import _ from 'underscore-plus'
import os from 'os'
import stackTrace from 'stack-trace'

let API_KEY = '7ddca14cb60cbd1cd12d1b252473b076'
let LIB_VERSION = require('../package.json')['version']

let request = window.fetch
let StackTraceCache = new WeakMap()

let buildNotificationJSON = (error, params) =>
  ({
    apiKey: API_KEY,
    notifier: {
      name: 'Atom',
      version: LIB_VERSION,
      url: 'https://www.atom.io'
    },
    events: [{
      payloadVersion: "2",
      exceptions: [buildExceptionJSON(error, params.projectRoot)],
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
  })

let buildExceptionJSON = (error, projectRoot) =>
  ({
    errorClass: error.constructor.name,
    message: error.message,
    stacktrace: buildStackTraceJSON(error, projectRoot)
  })


let buildStackTraceJSON = function(error, projectRoot) {
  let projectRootRegex = new RegExp(`^${_.escapeRegExp(projectRoot)}[\\/\\\\]`, 'i')
  return parseStackTrace(error).map(callSite => {
    return {
      file: callSite.getFileName().replace(projectRootRegex, '').replace(/\\/g, "/"),
      method: callSite.getMethodName() || callSite.getFunctionName() || "none",
      lineNumber: callSite.getLineNumber(),
      columnNumber: callSite.getColumnNumber(),
      inProject: !/node_modules/.test(callSite.getFileName())
    }
  })
}

let getDefaultNotificationParams = () =>
  ({
    userId: atom.config.get('exception-reporting.userId'),
    appVersion: atom.getVersion(),
    releaseStage: getReleaseChannel(atom.getVersion()),
    projectRoot: atom.getLoadSettings().resourcePath,
    osVersion: `${os.platform()}-${os.arch()}-${os.release()}`
  })


let getReleaseChannel = version =>
  (version.indexOf('beta') > -1)
    ? 'beta'
    : (version.indexOf('dev') > -1)
    ? 'dev'
    : 'stable'

let performRequest = json => {
  request('https://notify.bugsnag.com', {
    method: 'POST',
    headers: new Headers({'Content-Type': 'application/json'}),
    body: JSON.stringify(json)
  })
}

let shouldReport = error => {
  if (exports.alwaysReport) return true // Used in specs
  if (atom.config.get('core.telemetryConsent') !== 'limited') return false
  if (atom.inDevMode()) return false

  let topFrame = parseStackTrace(error)[0]
  return topFrame &&
         topFrame.getFileName() &&
         topFrame.getFileName().indexOf(atom.getLoadSettings().resourcePath) === 0
}

let parseStackTrace = error => {
  let callSites = StackTraceCache.get(error)
  if (callSites) {
    return callSites
  } else {
    callSites = stackTrace.parse(error)
    StackTraceCache.set(error, callSites)
    return callSites
  }
}

let requestPrivateMetadataConsent = (error, message, reportFn) => {
  let notification, dismissSubscription

  let reportWithoutPrivateMetadata = () => {
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

  let reportWithPrivateMetadata = () => {
    if (error.metadata == null) {
      error.metadata = {}
    }
    for (let key in error.privateMetadata) {
      let value = error.privateMetadata[key]
      error.metadata[key] = value
    }
    reportWithoutPrivateMetadata()
  }

  let name = error.privateMetadataRequestName
  if (name != null && name != undefined) {
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

let addPackageMetadata = error => {
  let activePackages = atom.packages.getActivePackages()
  if (activePackages.length > 0) {
    let userPackages = {}
    let bundledPackages = {}
    for (let pack of atom.packages.getActivePackages()) {
      if (/\/app\.asar\//.test(pack.path)) {
        bundledPackages[pack.name] = pack.metadata.version
      } else {
        userPackages[pack.name] = pack.metadata.version
      }
    }

    if (error.metadata == null) { error.metadata = {} }
    error.metadata.bundledPackages = bundledPackages
    error.metadata.userPackages = userPackages
  }
}

exports.reportUncaughtException = error => {
  if (!shouldReport(error)) return

  addPackageMetadata(error)

  if ((error.privateMetadata != null) && (error.privateMetadataDescription != null)) {
    requestPrivateMetadataConsent(error, "The Atom team would like to collect the following information to resolve this error:", exports.reportUncaughtException)
    return
  }

  let params = getDefaultNotificationParams()
  params.severity = "error"
  performRequest(buildNotificationJSON(error, params))
}

exports.reportFailedAssertion = error => {
  if (!shouldReport(error)) return

  addPackageMetadata(error)

  if ((error.privateMetadata != null) && (error.privateMetadataDescription != null)) {
    requestPrivateMetadataConsent(error, "The Atom team would like to collect some information to resolve an unexpected condition:", exports.reportFailedAssertion)
    return
  }

  let params = getDefaultNotificationParams()
  params.severity = "warning"
  performRequest(buildNotificationJSON(error, params))
}

// Used in specs
exports.setRequestFunction = (requestFunction) => {
  request = requestFunction
}

exports.API_KEY = API_KEY
exports.LIB_VERSION = LIB_VERSION
