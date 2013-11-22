request = require 'request'

module.exports =
class Reporter
  @send: (message, url, line) ->
    @request
      method: 'POST'
      url: "https://collector.githubapp.com/atom/error"
      headers: 'Content-Type' : 'application/vnd.github-octolytics+json'
      body: JSON.stringify(@buildParams(message, url, line))

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
        user_agent: navigator.userAgent
        dev_mode: !!atom.getLoadSettings().devMode
        version: atom.getVersion()
