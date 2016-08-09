_ = require 'underscore-plus'
os = require 'os'
stackTrace = require 'stack-trace'
API_KEY = '7ddca14cb60cbd1cd12d1b252473b076'
LIB_VERSION = require('../package.json')['version']

request = window.fetch
StackTraceCache = new WeakMap

buildNotificationJSON = (error, params) ->
  apiKey: API_KEY
  notifier:
    name: 'Atom'
    version: LIB_VERSION
    url: 'https://www.atom.io'
  events: [{
    payloadVersion: "2"
    exceptions: [buildExceptionJSON(error, params.projectRoot)]
    severity: params.severity
    user:
      id: params.userId
    app:
      version: params.appVersion
      releaseStage: params.releaseStage
    device:
      osVersion: params.osVersion
    metaData: error.metadata
  }]

buildExceptionJSON = (error, projectRoot) ->
  errorClass: error.constructor.name
  message: error.message
  stacktrace: buildStackTraceJSON(error, projectRoot)

buildStackTraceJSON = (error, projectRoot) ->
  projectRootRegex = ///^#{_.escapeRegExp(projectRoot)}[\/\\]///i
  parseStackTrace(error).map (callSite) ->
    file: callSite.getFileName().replace(projectRootRegex, '').replace(/\\/g, "/")
    method: callSite.getMethodName() ? callSite.getFunctionName() ? "none"
    lineNumber: callSite.getLineNumber()
    columnNumber: callSite.getColumnNumber()
    inProject: not /node_modules/.test(callSite.getFileName())

getDefaultNotificationParams = ->
  userId: atom.config.get('exception-reporting.userId')
  appVersion: atom.getVersion()
  releaseStage: if atom.isReleasedVersion() then 'production' else 'development'
  projectRoot: atom.getLoadSettings().resourcePath
  osVersion: "#{os.platform()}-#{os.arch()}-#{os.release()}"

performRequest = (json) ->
  request('https://notify.bugsnag.com', {
    method: 'POST'
    headers: new Headers({'Content-Type': 'application/json'})
    body: JSON.stringify(json)
  })

shouldReport = (error) ->
  return true if exports.alwaysReport # Used in specs
  return false unless atom.config.get('core.telemetryConsent') is 'limited'
  return false if atom.inDevMode()

  if topFrame = parseStackTrace(error)[0]
    # only report exceptions that originate from the application bundle
    topFrame.getFileName()?.indexOf(atom.getLoadSettings().resourcePath) is 0
  else
    false

parseStackTrace = (error) ->
  if callSites = StackTraceCache.get(error)
    callSites
  else
    callSites = stackTrace.parse(error)
    StackTraceCache.set(error, callSites)
    callSites

requestPrivateMetadataConsent = (error, message, reportFn) ->
  reportWithoutPrivateMetadata = ->
    dismissSubscription?.dispose()
    delete error.privateMetadata
    delete error.privateMetadataDescription
    reportFn(error)
    notification?.dismiss()

  reportWithPrivateMetadata = ->
    error.metadata ?= {}
    for key, value of error.privateMetadata
      error.metadata[key] = value
    reportWithoutPrivateMetadata()

  if name = error.privateMetadataRequestName
    if localStorage.getItem("private-metadata-request:#{name}")
      return reportWithoutPrivateMetadata(error)
    else
      localStorage.setItem("private-metadata-request:#{name}", true)

  notification = atom.notifications.addInfo message,
    detail: error.privateMetadataDescription
    description: "Are you willing to submit this information to a private server for debugging purposes?"
    dismissable: true
    buttons: [
      {
        text: "No"
        onDidClick: reportWithoutPrivateMetadata
      }
      {
        text: "Yes, Submit For Debugging"
        onDidClick: reportWithPrivateMetadata
      }
    ]

  dismissSubscription = notification.onDidDismiss(reportWithoutPrivateMetadata)

addPackageMetadata = (error) ->
  activePackages = atom.packages.getActivePackages()
  if activePackages.length > 0
    userPackages = {}
    bundledPackages = {}
    for pack in atom.packages.getActivePackages()
      if /\/app\.asar\//.test(pack.path)
        bundledPackages[pack.name] = pack.metadata.version
      else
        userPackages[pack.name] = pack.metadata.version

    error.metadata ?= {}
    error.metadata.bundledPackages = bundledPackages
    error.metadata.userPackages = userPackages

exports.reportUncaughtException = (error) ->
  return unless shouldReport(error)

  addPackageMetadata(error)

  if error.privateMetadata? and error.privateMetadataDescription?
    message = "The Atom team would like to collect the following information to resolve this error:"
    requestPrivateMetadataConsent(error, message, exports.reportUncaughtException)
    return

  params = getDefaultNotificationParams()
  params.severity = "error"
  json = buildNotificationJSON(error, params)
  performRequest(json)

exports.reportFailedAssertion = (error) ->
  return unless shouldReport(error)

  addPackageMetadata(error)

  if error.privateMetadata? and error.privateMetadataDescription?
    message = "The Atom team would like to collect some information to resolve an unexpected condition:"
    requestPrivateMetadataConsent(error, message, exports.reportFailedAssertion)
    return

  params = getDefaultNotificationParams()
  params.severity = "warning"
  json = buildNotificationJSON(error, params)
  performRequest(json)

# Used in specs
exports.setRequestFunction = (requestFunction) ->
  request = requestFunction

exports.API_KEY = API_KEY
exports.LIB_VERSION = LIB_VERSION
