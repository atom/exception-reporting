{_} = require 'atom'
Collector = require '../lib/collector'

describe "Collector", ->
  subject = null
  beforeEach ->
    subject = new Collector

  describe "getDataForError", ->
    it "creates a request with the proper options", ->
      keys = _.keys(subject.getDataForError('error', 'file.coffee', 1))
      expect(keys).toContain 'backtrace'
      expect(keys).toContain 'devMode'
      expect(keys).toContain 'user_agent'

    it "truncates large backtraces", ->
      largeString = Array(1024*5).join("a")
      url = 'file.coffee'
      line = 1
      data = subject.getDataForError(largeString, url, line)
      expect(data.backtrace.length).toBe (5*1024 + 6 + url.length + line.toString().length)
