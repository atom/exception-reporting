Guid = require 'guid'
Reporter = null

module.exports =
  activate: ->
    atom.config.set('exception-reporting.userId', Guid.raw()) unless atom.config.get('exception-reporting.userId')
    @uncaughtErrorSubscription = atom.on 'uncaught-error', (message, url, line) ->
      Reporter ?= require './reporter'
      Reporter.send(message, url, line)

  deactivate: ->
    @uncaughtErrorSubscription?.off()
    @uncaughtErrorSubscription = null
