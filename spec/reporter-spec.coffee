{_} = require('atom')
Reporter = require '../lib/reporter'

describe "Reporter", ->
  subject = null
  beforeEach ->
    spyOn(Reporter, 'request')

  it "creates a request with the proper options", ->
    Reporter.send('message', 'file.coffee', 1)
    expect(Reporter.request).toHaveBeenCalled()

    requestOptions = Reporter.request.calls[0].args[0]
    expect(requestOptions.method).toBe 'POST'
    expect(requestOptions.url).toBe 'https://collector.githubapp.com/atom/error'
    expect(requestOptions.headers['Content-Type']).toBe 'application/vnd.github-octolytics+json'

    body = JSON.parse(requestOptions.body)
    expect(Object.keys(body.dimensions)).toEqual ['actor_login', 'dev_mode', 'version']
    expect(body.context).toEqual {backtrace: 'message\nat (file.coffee:1)'}

  it "truncates large backtraces", ->
    largeString = Array(1024*6).join("a")
    Reporter.send(largeString, 'file.coffee', 1)

    body = JSON.parse(Reporter.request.calls[0].args[0].body)
    Reporter.send(largeString, 'file.coffee', 1)
    expect(body.context.backtrace.length).toBeLessThan largeString.length
