Reporter = require '../lib/reporter'
os = require 'os'
osVersion = "#{os.platform()}-#{os.arch()}-#{os.release()}"

# TODO: Remove me after Electron 0.37 is on stable
if parseFloat(process.versions.electron) >= 0.37
  method = ".<anonymous>"
else
  method = ""

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
      expect(body.events[0].exceptions[0].stacktrace[0].file).not.toMatch /\\/
      delete body.events[0].exceptions[0].stacktrace[0].file
      delete body.events[0].exceptions[0].stacktrace[0].inProject

      expect(body).toEqual {
        "apiKey": Reporter.API_KEY
        "notifier": {
          "name": "Atom",
          "version": Reporter.LIB_VERSION,
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
                    "method": method,
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
        spyOn(Reporter, 'reportUncaughtException').andCallThrough()
        Reporter.reportUncaughtException(error)
        Reporter.reportUncaughtException.reset()

        [notification] = atom.notifications.getNotifications()

        notificationOptions = atom.notifications.addInfo.argsForCall[0][1]
        expect(notificationOptions.buttons[1].text).toMatch /Yes/

        notificationOptions.buttons[1].onDidClick()
        expect(Reporter.reportUncaughtException).toHaveBeenCalledWith(error)
        expect(Reporter.reportUncaughtException.callCount).toBe 1
        expect(error.privateMetadata).toBeUndefined()
        expect(error.privateMetadataDescription).toBeUndefined()
        expect(error.metadata).toEqual {foo: "bar", baz: "quux"}

        expect(notification.isDismissed()).toBe true

      it "submits the error without the private metadata if the user does not consent", ->
        spyOn(Reporter, 'reportUncaughtException').andCallThrough()
        Reporter.reportUncaughtException(error)
        Reporter.reportUncaughtException.reset()

        [notification] = atom.notifications.getNotifications()

        notificationOptions = atom.notifications.addInfo.argsForCall[0][1]
        expect(notificationOptions.buttons[0].text).toMatch /No/

        notificationOptions.buttons[0].onDidClick()
        expect(Reporter.reportUncaughtException).toHaveBeenCalledWith(error)
        expect(Reporter.reportUncaughtException.callCount).toBe 1
        expect(error.privateMetadata).toBeUndefined()
        expect(error.privateMetadataDescription).toBeUndefined()
        expect(error.metadata).toEqual {foo: "bar"}

        expect(notification.isDismissed()).toBe true

      it "submits the error without the private metadata if the user dismisses the notification", ->
        spyOn(Reporter, 'reportUncaughtException').andCallThrough()
        Reporter.reportUncaughtException(error)
        Reporter.reportUncaughtException.reset()

        [notification] = atom.notifications.getNotifications()
        notification.dismiss()

        expect(Reporter.reportUncaughtException).toHaveBeenCalledWith(error)
        expect(Reporter.reportUncaughtException.callCount).toBe 1
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
      expect(body.events[0].exceptions[0].stacktrace[0].file).not.toMatch /\\/
      delete body.events[0].exceptions[0].stacktrace[0].file
      delete body.events[0].exceptions[0].stacktrace[0].inProject

      expect(body).toEqual {
        "apiKey": Reporter.API_KEY
        "notifier": {
          "name": "Atom",
          "version": Reporter.LIB_VERSION,
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
                    "method": method,
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
        Reporter.reportFailedAssertion(error)
        expect(atom.notifications.addInfo).toHaveBeenCalled()

      it "submits the error with the private metadata if the user consents", ->
        spyOn(Reporter, 'reportFailedAssertion').andCallThrough()
        Reporter.reportFailedAssertion(error)
        Reporter.reportFailedAssertion.reset()

        [notification] = atom.notifications.getNotifications()

        notificationOptions = atom.notifications.addInfo.argsForCall[0][1]
        expect(notificationOptions.buttons[1].text).toMatch /Yes/

        notificationOptions.buttons[1].onDidClick()
        expect(Reporter.reportFailedAssertion).toHaveBeenCalledWith(error)
        expect(Reporter.reportFailedAssertion.callCount).toBe 1
        expect(error.privateMetadata).toBeUndefined()
        expect(error.privateMetadataDescription).toBeUndefined()
        expect(error.metadata).toEqual {foo: "bar", baz: "quux"}

        expect(notification.isDismissed()).toBe true

      it "submits the error without the private metadata if the user does not consent", ->
        spyOn(Reporter, 'reportFailedAssertion').andCallThrough()
        Reporter.reportFailedAssertion(error)
        Reporter.reportFailedAssertion.reset()

        [notification] = atom.notifications.getNotifications()

        notificationOptions = atom.notifications.addInfo.argsForCall[0][1]
        expect(notificationOptions.buttons[0].text).toMatch /No/

        notificationOptions.buttons[0].onDidClick()
        expect(Reporter.reportFailedAssertion).toHaveBeenCalledWith(error)
        expect(Reporter.reportFailedAssertion.callCount).toBe 1
        expect(error.privateMetadata).toBeUndefined()
        expect(error.privateMetadataDescription).toBeUndefined()
        expect(error.metadata).toEqual {foo: "bar"}

        expect(notification.isDismissed()).toBe true

      it "submits the error without the private metadata if the user dismisses the notification", ->
        spyOn(Reporter, 'reportFailedAssertion').andCallThrough()
        Reporter.reportFailedAssertion(error)
        Reporter.reportFailedAssertion.reset()

        [notification] = atom.notifications.getNotifications()
        notification.dismiss()

        expect(Reporter.reportFailedAssertion).toHaveBeenCalledWith(error)
        expect(Reporter.reportFailedAssertion.callCount).toBe 1
        expect(error.privateMetadata).toBeUndefined()
        expect(error.privateMetadataDescription).toBeUndefined()
        expect(error.metadata).toEqual {foo: "bar"}

      it "only notifies the user once for a given 'privateMetadataRequestName'", ->
        fakeStorage = {}
        spyOn(global.localStorage, 'setItem').andCallFake (key, value) -> fakeStorage[key] = value
        spyOn(global.localStorage, 'getItem').andCallFake (key) -> fakeStorage[key]

        error.privateMetadataRequestName = 'foo'

        Reporter.reportFailedAssertion(error)
        expect(atom.notifications.addInfo).toHaveBeenCalled()
        atom.notifications.addInfo.reset()

        Reporter.reportFailedAssertion(error)
        expect(atom.notifications.addInfo).not.toHaveBeenCalled()

        error2 = new Error
        Error.captureStackTrace(error2)
        error2.privateMetadataDescription = 'Something about you'
        error2.privateMetadata = {baz: 'quux'}
        error2.privateMetadataRequestName = 'bar'

        Reporter.reportFailedAssertion(error2)
        expect(atom.notifications.addInfo).toHaveBeenCalled()
