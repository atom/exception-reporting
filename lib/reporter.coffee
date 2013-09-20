{_} = require 'atom'
request = require 'request'

module.exports =
  class Reporter
    constructor: ->
      @request = request

    send: (data) ->
      params = app: 'atom'
      _.extend(params, data)

      #@request
      console.log
        url: "https://haystack.githubapp.com/api"
        qs: params
