os = require 'os'
path = require 'path'
coffeestack = require 'coffeestack'

request = null # Defer require until error is actually sent

module.exports =
class Reporter
  @send: (message, url, line) ->
    return unless @shouldSendErrorFromUrl(url)
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

    releaseStage = if atom.isReleasedVersion() then 'production' else 'development'
    {line, column, source} = coffeestack.convertLine(url, line, 0) or {line: line, source: url, column: 0}
    context = path.basename(source)

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
            file: source
            method: ' '
            columnNumber: column
            lineNumber: line
            inProject: true
          ]
        ]
      ]

  @shouldSendErrorFromUrl: (url) ->
    resourcePath = atom.getLoadSettings().resourcePath
    not atom.inDevMode() and url.indexOf(resourcePath) == 0
