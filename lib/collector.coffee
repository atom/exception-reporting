module.exports =
  class Collector
    # Public: Returns an object containing all data collected for a specific
    # error.
    getDataForError: (message, url, line) ->
      backtrace = "#{message}\n"
      backtrace += "at (#{url}:#{line})"

      data =
        backtrace: backtrace
