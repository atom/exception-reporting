{_} = require 'atom'
Guid = require 'guid'

Reporter = require './reporter'

module.exports =
  activate: ->
    atom.config.set('exception-reporting.userId', Guid.raw()) unless atom.config.get('exception-reporting.userId')
    atom.on 'uncaught-error.exception', (message, url, line) ->
      Reporter.send(message, url, line)


  deactivate: ->
    atom.off 'uncaught-error.exception-reporting'
