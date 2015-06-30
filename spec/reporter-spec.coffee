Reporter = require '../lib/reporter'
os = require 'os'
osVersion = "#{os.platform()}-#{os.arch()}-#{os.release()}"

describe "Reporter", ->
  [requests, initialStackTraceLimit] = []

  beforeEach ->
    requests = []

    initialStackTraceLimit = Error.stackTraceLimit
    Error.stackTraceLimit = 1

    Reporter.setRequestFunction (request) -> requests.push(request)
    Reporter.alwaysReport = true

  afterEach ->
    Error.stackTraceLimit = initialStackTraceLimit

  describe ".reportUncaughtException(error)", ->
    it "posts errors to bugsnag", ->
      error = new Error
      Error.captureStackTrace(error)
      Reporter.reportUncaughtException(error)
      [lineNumber, columnNumber] = error.stack.match(/.coffee:(\d+):(\d+)/)[1..].map (s) -> parseInt(s)

      expect(requests).toEqual [
        {
          "method": "POST",
          "url": "https://notify.bugsnag.com",
          "headers": {
            "Content-Type": "application/json"
          },
          "body": JSON.stringify({
            "apiKey": Reporter.API_KEY
            "notifier": {
              "name": "Atom",
              "version": atom.getVersion(),
              "url": "https://www.atom.io"
            },
            "events": [
              {
                "payloadVersion": "2",
                "exceptions": [
                  {
                    "errorClass": "Error",
                    "message": "",
                    "stacktrace": [
                      {
                        "file": "/Users/nathansobo/github/exception-reporting/spec/reporter-spec.coffee",
                        "method": "",
                        "lineNumber": lineNumber,
                        "columnNumber": columnNumber,
                        "inProject": true
                      }
                    ]
                  }
                ],
                "severity": "error",
                "user": {},
                "app": {
                  "version": atom.getVersion(),
                  "releaseStage": "development"
                },
                "device": {
                  "osVersion": osVersion
                }
              }
            ]
          })
        }
      ]

  describe ".reportFailedAssertion(error)", ->
    it "posts warnings to bugsnag", ->
      error = new Error
      Error.captureStackTrace(error)
      Reporter.reportFailedAssertion(error)
      [lineNumber, columnNumber] = error.stack.match(/.coffee:(\d+):(\d+)/)[1..].map (s) -> parseInt(s)

      expect(requests).toEqual [
        {
          "method": "POST",
          "url": "https://notify.bugsnag.com",
          "headers": {
            "Content-Type": "application/json"
          },
          "body": JSON.stringify({
            "apiKey": Reporter.API_KEY
            "notifier": {
              "name": "Atom",
              "version": atom.getVersion(),
              "url": "https://www.atom.io"
            },
            "events": [
              {
                "payloadVersion": "2",
                "exceptions": [
                  {
                    "errorClass": "Error",
                    "message": "",
                    "stacktrace": [
                      {
                        "file": "/Users/nathansobo/github/exception-reporting/spec/reporter-spec.coffee",
                        "method": "",
                        "lineNumber": lineNumber,
                        "columnNumber": columnNumber,
                        "inProject": true
                      }
                    ]
                  }
                ],
                "severity": "warning",
                "user": {},
                "app": {
                  "version": atom.getVersion(),
                  "releaseStage": "development"
                },
                "device": {
                  "osVersion": osVersion
                }
              }
            ]
          })
        }
      ]
