os = require 'os'
path = require 'path'

coffeestack = require 'coffeestack'
request = require 'request'

module.exports =
class Reporter
  @send: (message, url, line, column, error) ->
    return unless @shouldSendErrorFromUrl(url)
    @request
      method: 'POST'
      url: 'https://notify.bugsnag.com'
      headers: 'Content-Type' : 'application/json'
      body: JSON.stringify(@buildParams(message, url, line, column, error))

  @request: (options) ->
    request options, -> # Callback prevents errors from going to the console

  @buildParams: (message, url, line, column, error) ->
    message = message.substring(0, 5*1024)
    unless errorClass = error?.name
      if errorClass = message.split(':', 1)[0]
        errorClass = errorClass.replace('Uncaught ', '')
      else
        errorClass = "UncaughtError"

    releaseStage = if atom.isReleasedVersion() then 'production' else 'development'
    {line, column, source} = coffeestack.convertLine(url, line, column) ? {line, column, source: url}
    context = path.basename(source)

    stacktrace = []
    if error?.stack?
      atLinePattern = /^(\s+at (.*) )\((.*):(\d+):(\d+)\)/
      for line in coffeestack.convertStackTrace(error.stack).split('\n')
        if match = atLinePattern.exec(line)
          stacktrace.push
            file: match[3].replace(/(.*[\/\\]Resources[\/\\])/, '')
            method: match[2].replace(/^(HTMLDocument|HTML[^\.]*Element|Object)\./, '')
            columnNumber: parseInt(match[5])
            lineNumber: parseInt(match[4])
            inProject: !/node_modules/.test(match[3])
    else
      stacktrace.push
        file: source
        method: ' '
        columnNumber: column
        lineNumber: line
        inProject: true

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
        exceptions: [{errorClass, message, stacktrace}]
        metaData: error?.metadata
      ]

  @shouldSendErrorFromUrl: (url) ->
    {resourcePath} = atom.getLoadSettings()
    not atom.inDevMode() and url.indexOf(resourcePath) == 0
