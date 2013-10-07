module.exports =
  class Collector
    # Private:
    getDevMode: ->
      !!atom.getLoadSettings().devMode

    # Private
    getUserAgent: ->
      navigator.userAgent

    # Public: Returns an object containing all data collected for a specific
    # error.
    getDataForError: (message, url, line) ->
      backtrace = "#{message}\n"
      backtrace += "at (#{url}:#{line})"

      data =
        backtrace: backtrace
        devMode: @getDevMode()
        user_agent: @getUserAgent()
