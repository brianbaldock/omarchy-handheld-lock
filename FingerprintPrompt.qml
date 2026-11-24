import QtQuick
import Quickshell.Services.Pam

Item {
  id: root
  required property Component pamFactory
  required property bool allowed
  readonly property bool scanning: attempt !== null
  readonly property bool cooling: cooldown.running
  property string notice: ""
  property var attempt: null
  property double deadline: 0
  signal matched()

  function finish(message, backoff) {
    const old = attempt
    attempt = null
    timeout.stop()
    deadline = 0
    notice = message
    if (backoff) cooldown.restart()
    if (old) {
      if (old.active) old.abort()
      old.destroy()
    }
  }

  function cancel() {
    finish(cooling ? notice : "", false)
  }

  function timedOut() {
    finish("Scan timed out. Use password or try again.", false)
  }

  function unavailable() {
    // PAM can report a generic device error even when fprintd knows it is thermal.
    finish("Reader unavailable. Let it cool down or use password.", true)
  }

  function start() {
    if (!allowed || scanning || cooling) return
    const pam = pamFactory.createObject(root)
    if (!pam) { unavailable(); return }
    attempt = pam
    deadline = Date.now() + timeout.interval
    notice = "Touch the fingerprint reader"
    timeout.start()
    pam.pamMessage.connect(function() {
      if (root.attempt !== pam) return
      const text = pam.message
      if (/overheat|too hot|cool down/i.test(text)) {
        root.finish("Reader cooling down. Use password.", true)
      } else if (/failed to match|no.match|not match|again|too fast|too short|not centered/i.test(text)) {
        root.finish("Scan not recognized. Try again or use password.", false)
      } else if (/timed out/i.test(text)) {
        root.timedOut()
      } else if (pam.messageIsError || /unknown error|unexpected error|unavailable|disconnected/i.test(text)) {
        root.unavailable()
      }
    })
    pam.completed.connect(function(result) {
      // A canceled attempt (including one from a previous lock) cannot unlock.
      if (root.attempt !== pam || !root.allowed) return
      if (Date.now() >= root.deadline) { root.timedOut(); return }
      if (result === PamResult.Success) {
        root.finish("", false)
        root.matched()
      } else if (result === PamResult.MaxTries) {
        root.finish("No match. Try again or use password.", false)
      } else {
        root.unavailable()
      }
    })
    pam.error.connect(function() { if (root.attempt === pam) root.unavailable() })
    if (!pam.start() && root.attempt === pam) unavailable()
  }

  onAllowedChanged: if (!allowed && scanning) cancel()
  Timer { id: timeout; interval: 15000; onTriggered: root.timedOut() }
  Timer { id: cooldown; interval: 30000; onTriggered: root.notice = "" }
}
