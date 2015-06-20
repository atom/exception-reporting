{CompositeDisposable} = require 'atom'

Reporter = null
NewReporter = null

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable

    unless atom.config.get('exception-reporting.userId')
      atom.config.set('exception-reporting.userId', require('guid').raw())

    @subscriptions.add atom.onDidThrowError ({message, url, line, column, originalError}) ->
      Reporter ?= require './reporter'
      Reporter.send(message, url, line, column, originalError)

      NewReporter ?= require './new-reporter'
      NewReporter.reportUncaughtException(originalError)

    if atom.onDidFailAssertion?
      @subscriptions.add atom.onDidFailAssertion (error) ->
        NewReporter ?= require './new-reporter'
        NewReporter.reportFailedAssertion(error)

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptions = null
