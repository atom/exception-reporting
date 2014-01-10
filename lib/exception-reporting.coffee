{_} = require 'atom'
Guid = require 'guid'

Reporter = require './reporter'

module.exports =
  activate: ->
    atom.config.set('exception-reporting.userId', Guid.raw()) unless atom.config.get('exception-reporting.userId')
    @errorSubscription = atom.on 'uncaught-error', (message, url, line) ->
      Reporter.send(message, url, line)

  deactivate: ->
    console.log @errorSubscription
    @errorSubscription?.off()
    @errorSubscription = null
