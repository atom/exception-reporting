{CompositeDisposable} = require 'atom'

Reporter = null

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable

    unless atom.config.get('exception-reporting.userId')
      atom.config.set('exception-reporting.userId', require('guid').raw())

    @subscriptions.add atom.onDidThrowError ({message, url, line, column, originalError}) ->
      try
        Reporter ?= require './reporter'
        Reporter.reportUncaughtException(originalError)
      catch secondaryException
        try
          console.error "Error reporting uncaught exception", secondaryException
          Reporter.reportUncaughtException(secondaryException)

    if atom.onDidFailAssertion?
      @subscriptions.add atom.onDidFailAssertion (error) ->
        try
          Reporter ?= require './reporter'
          Reporter.reportFailedAssertion(error)
        catch secondaryException
          try
            console.error "Error reporting assertion failure", secondaryException
            Reporter.reportUncaughtException(secondaryException)

  deactivate: ->
    @subscriptions?.dispose()
    @subscriptions = null
