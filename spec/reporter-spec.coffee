{_} = require('atom')
Reporter = require '../lib/reporter'

describe "Reporter", ->
  beforeEach ->
    spyOn(Reporter, 'request')

  it "creates a request with the proper options", ->
    Reporter.send('message', 'file.coffee', 1)
    expect(Reporter.request).toHaveBeenCalled()

    requestArgs = Reporter.request.calls[0].args[0]
    body = JSON.parse(requestArgs.body)

    expect(requestArgs.method).toBe 'POST'
    expect(requestArgs.url).toBe 'https://collector.githubapp.com/atom/error'
    expect(requestArgs.headers['Content-Type']).toBe 'application/vnd.github-octolytics+json'
    expect(body.dimensions).toBeDefined()
    expect(body.context).toEqual {backtrace: 'message\nat (file.coffee:1)'}
    expect(body.timestamp).toBeDefined()

  it "truncates large backtraces", ->
    largeString = Array(1024*6).join("a")
    Reporter.send(largeString, 'file.coffee', 1)

    body = JSON.parse(Reporter.request.calls[0].args[0].body)
    Reporter.send(largeString, 'file.coffee', 1)
    expect(body.context.backtrace.length).toBeLessThan largeString.length
