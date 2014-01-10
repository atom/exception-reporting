Guid = require 'guid'

Reporter = require './reporter'

module.exports =
  activate: ->
    atom.config.set('exception-reporting.userId', Guid.raw()) unless atom.config.get('exception-reporting.userId')
    @uncaughtErrorSubscription = atom.on 'uncaught-error', (message, url, line) ->
      Reporter.send(message, url, line)

  deactivate: ->
    @uncaughtErrorSubscription?.off()
    @uncaughtErrorSubscription = null
