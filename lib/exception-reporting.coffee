{_} = require 'atom'
Guid = require 'guid'

Reporter = require './reporter'

module.exports =
  activate: (state) ->
    atom.config.set('exception-reporting.userId', Guid.raw()) unless atom.config.get('exception-reporting.userId')
    atom.on 'error.exception-reporting', (message, url, line) ->
      Reporter.send(message, url, line) unless atom.inDevMode()

  deactivate: ->
    atom.off 'error.exception-reporting'
