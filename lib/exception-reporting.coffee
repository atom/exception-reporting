Reporter = null

module.exports =
  activate: ->
    unless atom.config.get('exception-reporting.userId')
      atom.config.set('exception-reporting.userId', require('guid').raw())

    @uncaughtErrorSubscription = atom.on 'uncaught-error', (message, url, line) ->
      Reporter ?= require './reporter'
      Reporter.send(message, url, line)

  deactivate: ->
    @uncaughtErrorSubscription?.off()
    @uncaughtErrorSubscription = null
