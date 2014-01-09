{_} = require('atom')
path = require 'path'
Reporter = require '../lib/reporter'

describe "Reporter", ->
  beforeEach ->
    spyOn(Reporter, 'request')
    spyOn(atom, 'inDevMode').andReturn false # exceptions are never send if atom is in dev mode

  describe "when the exception is from atom core", ->
    filePath = null

    beforeEach ->
      filePath = path.join(atom.getLoadSettings().resourcePath, 'file.coffee')

    it "sends a request with the proper options", ->
      Reporter.send('message', filePath, 1)
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
      Reporter.send(largeString, filePath, 1)

      body = JSON.parse(Reporter.request.calls[0].args[0].body)
      Reporter.send(largeString, 'file.coffee', 1)
      expect(body.events[0].exceptions[0].message.length).toBeLessThan largeString.length

  describe "when the exception is not from atom core", ->
    it "doesn't send a request with the proper options", ->
      Reporter.send('message', 'file.coffee', 1)
      expect(Reporter.request).not.toHaveBeenCalled()
