Reporter = null

module.exports =
  activate: ->
    unless atom.config.get('exception-reporting.userId')
      atom.config.set('exception-reporting.userId', require('guid').raw())

    @uncaughtErrorSubscription = atom.on 'uncaught-error', (message, url, line, column, error) ->
      Reporter ?= require './reporter'
      Reporter.send(message, url, line, column, error)

  deactivate: ->
    @uncaughtErrorSubscription?.off()
    @uncaughtErrorSubscription = null
