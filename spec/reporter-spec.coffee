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
    expect(requestArgs.url).toBe 'https://notify.bugsnag.com'
    expect(requestArgs.headers['Content-Type']).toBe 'application/json'
    expect(body.apiKey).toBeDefined()
    expect(body.notifier).toBeDefined()
    expect(body.events).toBeDefined()
    expect(body.events[0].context).toEqual 'file.coffee'
    expect(body.events[0].exceptions[0].message).toEqual 'message'

  it "truncates large backtraces", ->
    largeString = Array(1024*6).join("a")
    Reporter.send(largeString, 'file.coffee', 1)

    body = JSON.parse(Reporter.request.calls[0].args[0].body)
    Reporter.send(largeString, 'file.coffee', 1)
    expect(body.events[0].exceptions[0].message.length).toBeLessThan largeString.length
