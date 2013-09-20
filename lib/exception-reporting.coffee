{_} = require 'atom'

Collector = require './collector'
Reporter = require './reporter'

module.exports =
  collector: new Collector()
  reporter: new Reporter()

  activate: (state) ->
    if _.isFunction(window.onerror)
      @originalOnError = window.onerror
    window.onerror = (message, url, line) =>
      @reporter.send(@collector.getDataForError(message, url, line))
      @originalOnError(arguments...)

  deactivate: ->
    if @originalOnError
      window.onerror = @originalOnError
    else
      window.onerror = null
