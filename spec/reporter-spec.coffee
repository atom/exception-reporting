Reporter = require '../lib/reporter'

describe "Reporter", ->
  subject = null
  beforeEach ->
    subject = new Reporter

  describe "send", ->
    beforeEach ->
      spyOn(console, 'log')
      subject.send(key: 'value')

    it "creates a request with the proper options", ->
      expect(console.log).toHaveBeenCalled()
      expect(console.log.calls[0].args[0].url).toBe 'https://haystack.githubapp.com/api'
      expect(console.log.calls[0].args[0].qs['key']).toBe 'value'
