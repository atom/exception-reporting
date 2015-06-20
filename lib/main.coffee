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

      try
        NewReporter ?= require './new-reporter'
        NewReporter.reportUncaughtException(originalError)
      catch secondaryException
        try
          console.error "Error reporting uncaught exception", secondaryException
          NewReporter.reportUncaughtException(secondaryException)

    if atom.onDidFailAssertion?
      @subscriptions.add atom.onDidFailAssertion (error) ->
        try
          NewReporter ?= require './new-reporter'
          NewReporter.reportFailedAssertion(error)
        catch secondaryException
          try
            console.error "Error reporting assertion failure", secondaryException
            NewReporter.reportUncaughtException(secondaryException)

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptions = null
