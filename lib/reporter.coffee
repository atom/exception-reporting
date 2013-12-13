os = require 'os'
path = require 'path'

request = null # Defer require until error is actually sent

module.exports =
class Reporter
  @send: (message, url, line) ->
    @request
      method: 'POST'
      url: "https://notify.bugsnag.com"
      headers: 'Content-Type' : 'application/json'
      body: JSON.stringify(@buildParams(message, url, line))

  @request: (options) ->
    request ?= require 'request'
    request options, -> # Callback prevents errors from going to the console

  # Private:
  @buildParams: (message, url, line) ->
    message = message.substring(0, 5*1024)

    if errorClass = message.split(':', 1)[0]
      errorClass = errorClass.replace('Uncaught ', '')
    else
      errorClass = "UncaughtError"

    context = path.basename(url)
    releaseStage = if atom.isReleasedVersion() then 'production' else 'development'

    params =
      apiKey: '7ddca14cb60cbd1cd12d1b252473b076'
      notifier:
        name: 'Atom'
        version: atom.getVersion()
        url: 'https://www.atom.io'
      events: [
        userId: atom.config.get('exception-reporting.userId')
        appVersion: atom.getVersion()
        osVersion: "#{os.platform()}-#{os.arch()}-#{os.release()}"
        releaseStage: releaseStage
        context: context
        groupingHash: message
        exceptions: [
          errorClass: errorClass
          message: message
          stacktrace: [
            file: url
            method: 'N/A'
            columnNumber: 0
            lineNumber: line
            inProject: true
          ]
        ]
      ]
