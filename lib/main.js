/** @babel */

import {CompositeDisposable} from 'atom'

let Reporter = null

export default {
  activate() {
    this.subscriptions = new CompositeDisposable()

    if (!atom.config.get('exception-reporting.userId')) {
      atom.config.set('exception-reporting.userId', require('node-uuid').v4())
    }

    this.subscriptions.add(atom.onDidThrowError(({message, url, line, column, originalError}) => {
      try {
        Reporter = Reporter || require('./reporter')
        Reporter.reportUncaughtException(originalError)
      } catch (secondaryException) {
        try {
          console.error("Error reporting uncaught exception", secondaryException)
          Reporter.reportUncaughtException(secondaryException)
        } catch (error) { }
      }
    })
    )

    if (atom.onDidFailAssertion != null) {
      this.subscriptions.add(atom.onDidFailAssertion(error => {
        try {
          Reporter = Reporter || require('./reporter')
          Reporter.reportFailedAssertion(error)
        } catch (secondaryException) {
          try {
            console.error("Error reporting assertion failure", secondaryException)
            Reporter.reportUncaughtException(secondaryException)
          } catch (error) {}
        }
      })
      )
    }
  }
}
