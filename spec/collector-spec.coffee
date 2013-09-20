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
