{_} = require 'atom'

Reporter = require './reporter'

module.exports =
  activate: (state) ->
    if _.isFunction(window.onerror)
      @originalOnError = window.onerror
    window.onerror = (message, url, line) =>
      Reporter.send(message, url, line)
      @originalOnError?(arguments...)

  deactivate: ->
    if @originalOnError?
      window.onerror = @originalOnError
    else
      window.onerror = null
