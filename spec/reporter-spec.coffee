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

      expect(requests.length).toBe 1
      [request] = requests
      expect(request.method).toBe "POST"
      expect(request.url).toBe "https://notify.bugsnag.com"
      expect(request.headers).toEqual {"Content-Type": "application/json"}
      body = JSON.parse(request.body)

      # asserting the correct path is difficult on CI. let's do 'close enough'.
      expect(body.events[0].exceptions[0].stacktrace[0].file).toMatch /reporter-spec/
      delete body.events[0].exceptions[0].stacktrace[0].file
      delete body.events[0].exceptions[0].stacktrace[0].inProject

      expect(body).toEqual {
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
                    "method": "",
                    "lineNumber": lineNumber,
                    "columnNumber": columnNumber
                  }
                ]
              }
            ],
            "severity": "error",
            "user": {},
            "app": {
              "version": atom.getVersion(),
              "releaseStage": if atom.isReleasedVersion() then 'production' else 'development'
            },
            "device": {
              "osVersion": osVersion
            }
          }
        ]
      }

    describe "when the error object has `privateMetadata` and `privateMetadataDescription` fields", ->
      [error, notification] = []

      beforeEach ->
        atom.notifications.clear()
        spyOn(atom.notifications, 'addInfo').andCallThrough()

        error = new Error
        Error.captureStackTrace(error)

        error.metadata = {foo: "bar"}
        error.privateMetadata = {baz: "quux"}
        error.privateMetadataDescription = "The contents of baz"

      it "posts a notification asking for consent", ->
        Reporter.reportUncaughtException(error)
        expect(atom.notifications.addInfo).toHaveBeenCalled()

      it "submits the error with the private metadata if the user consents", ->
        Reporter.reportUncaughtException(error)

        [notification] = atom.notifications.getNotifications()
        spyOn(notification, 'dismiss')

        notificationOptions = atom.notifications.addInfo.argsForCall[0][1]
        expect(notificationOptions.buttons[1].text).toMatch /Yes/

        spyOn(Reporter, 'reportUncaughtException')
        notificationOptions.buttons[1].onDidClick()
        expect(Reporter.reportUncaughtException).toHaveBeenCalledWith(error)
        expect(error.privateMetadata).toBeUndefined()
        expect(error.privateMetadataDescription).toBeUndefined()
        expect(error.metadata).toEqual {foo: "bar", baz: "quux"}

        expect(notification.dismiss).toHaveBeenCalled()

      it "submits the error without the private metadata if the user does not consent", ->
        Reporter.reportUncaughtException(error)

        [notification] = atom.notifications.getNotifications()
        spyOn(notification, 'dismiss')

        notificationOptions = atom.notifications.addInfo.argsForCall[0][1]
        expect(notificationOptions.buttons[0].text).toMatch /No/

        spyOn(Reporter, 'reportUncaughtException')
        notificationOptions.buttons[0].onDidClick()
        expect(Reporter.reportUncaughtException).toHaveBeenCalledWith(error)
        expect(error.privateMetadata).toBeUndefined()
        expect(error.privateMetadataDescription).toBeUndefined()
        expect(error.metadata).toEqual {foo: "bar"}

        expect(notification.dismiss).toHaveBeenCalled()

      it "submits the error without the private metadata if the user dismisses the notification", ->
        Reporter.reportUncaughtException(error)

        spyOn(Reporter, 'reportUncaughtException')

        [notification] = atom.notifications.getNotifications()
        notification.dismiss()

        expect(Reporter.reportUncaughtException).toHaveBeenCalledWith(error)
        expect(error.privateMetadata).toBeUndefined()
        expect(error.privateMetadataDescription).toBeUndefined()
        expect(error.metadata).toEqual {foo: "bar"}

  describe ".reportFailedAssertion(error)", ->
    it "posts warnings to bugsnag", ->
      error = new Error
      Error.captureStackTrace(error)
      Reporter.reportFailedAssertion(error)
      [lineNumber, columnNumber] = error.stack.match(/.coffee:(\d+):(\d+)/)[1..].map (s) -> parseInt(s)

      expect(requests.length).toBe 1
      [request] = requests
      expect(request.method).toBe "POST"
      expect(request.url).toBe "https://notify.bugsnag.com"
      expect(request.headers).toEqual {"Content-Type": "application/json"}
      body = JSON.parse(request.body)

      # asserting the correct path is difficult on CI. let's do 'close enough'.
      expect(body.events[0].exceptions[0].stacktrace[0].file).toMatch /reporter-spec/
      delete body.events[0].exceptions[0].stacktrace[0].file
      delete body.events[0].exceptions[0].stacktrace[0].inProject

      expect(body).toEqual {
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
                    "method": "",
                    "lineNumber": lineNumber,
                    "columnNumber": columnNumber
                  }
                ]
              }
            ],
            "severity": "warning",
            "user": {},
            "app": {
              "version": atom.getVersion(),
              "releaseStage": if atom.isReleasedVersion() then 'production' else 'development'
            },
            "device": {
              "osVersion": osVersion
            }
          }
        ]
      }
