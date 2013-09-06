_ = require 'underscore'

module.exports =
  class Collector
    # Public: Returns an object containing all data collected for a specific
    # error.
    getDataForError: (message, url, line) ->
      backtrace = "#{message} #{url}:#{line}"

      data =
        backtrace: backtrace
      _.extend(data, additionalData)
