exceptionReporting = require '../lib/exception-reporting'

describe "Exception reporting", ->
  describe "upon loading", ->
    beforeEach ->
      window.onerror = null

    it "reports a page view", ->
      expect(window.onerror).toBe null
      exceptionReporting.activate()
      expect(window.onerror).not.toBe null

  describe "upon unloading", ->
    beforeEach ->
      window.onerror = ->

    it "reports a page view", ->
      expect(window.onerror).not.toBe null
      exceptionReporting.deactivate()
      expect(window.onerror).toBe null
