Reporter = null
NewReporter = null

module.exports =
  activate: ->
    unless atom.config.get('exception-reporting.userId')
      atom.config.set('exception-reporting.userId', require('guid').raw())

    @uncaughtErrorSubscription = atom.onDidThrowError ({message, url, line, column, originalError}) ->
      Reporter ?= require './reporter'
      Reporter.send(message, url, line, column, originalError)

      NewReporter ?= require './new-reporter'
      NewReporter.reportUncaughtException(originalError)

  deactivate: ->
    @uncaughtErrorSubscription?.dispose()
    @uncaughtErrorSubscription = null
