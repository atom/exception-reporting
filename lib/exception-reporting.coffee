{_} = require 'atom'
Guid = require 'guid'

Reporter = require './reporter'

module.exports =
  activate: (state) ->
    atom.config.set('exception-reporting.userId', Guid.raw()) unless atom.config.get('exception-reporting.userId')

    if _.isFunction(window.onerror)
      @originalOnError = window.onerror
    window.onerror = (message, url, line) =>
      Reporter.send(message, url, line) unless atom.inDevMode()
      @originalOnError?(arguments...)

  deactivate: ->
    if @originalOnError?
      window.onerror = @originalOnError
    else
      window.onerror = null
