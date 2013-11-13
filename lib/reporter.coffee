request = require 'request'

module.exports =
  class Reporter
    @send: (message, url, line) ->
      params = @buildParams(message, url, line)

      requestOptions =
        method: 'POST'
        url: "https://collector.githubapp.com/atom/error"
        headers:
          'Content-Type' : 'application/vnd.github-octolytics+json'
        body: JSON.stringify(params)

      @request requestOptions

    @request: (options) ->
      request options, -> # Callback prevents errors from going to the console

    # Private:
    @buildParams: (message, url, line) ->
      message = message.substring(0, 5*1024)
      backtrace = "#{message}\nat (#{url}:#{line})"

      params =
        timestamp: new Date().getTime() / 1000
        context:
          backtrace: backtrace
        dimensions:
          actor_login: process.env.USER
          dev_mode: !!atom.getLoadSettings().devMode
          version: atom.getVersion()
