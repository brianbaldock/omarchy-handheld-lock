import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool fingerprintScanning: false
  property bool fingerprintCooling: false
  property string fingerprintNotice: ""
  property bool keyboardOpen: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property string placeholderText: "Enter Password"
  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Commons.Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Commons.Color.lock.borderActive, root.outlineThickness, "border-alpha")

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()
  signal fingerprintRequested()
  signal passwordModeRequested()

  function toggleFingerprint() {
    if (!inputEnabled || authenticatingPassword || fingerprintCooling) return
    wakeRequested()
    if (fingerprintScanning) passwordModeRequested()
    else fingerprintRequested()
    forcePasswordFocus()
  }

  function submitInput() {
    if (!inputEnabled || authenticatingPassword || !passwordText.length) return
    const value = passwordText
    passwordTextEdited("")
    submitPassword(value)
  }

  function touchKey(key) {
    if (!inputEnabled || authenticatingPassword || !keyboardOpen) return
    wakeRequested()
    forcePasswordFocus()
    if (key === "Enter") { submitInput(); return }
    const start = passwordInput.selectionStart
    const end = passwordInput.selectionEnd
    if (end > start) passwordInput.remove(start, end)
    if (key === "Backspace") {
      if (end === start && start > 0) {
        const prev = Array.from(passwordInput.text.slice(0, start)).pop()
        passwordInput.remove(start - prev.length, start)
      }
    } else {
      passwordInput.insert(start, key)
      passwordInput.cursorPosition = start + key.length
    }
  }

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
    else keyboardOpen = false
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Commons.Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    BorderSurface {
      id: inputField
      width: Math.min(root.fieldWidth, parent.width - 16)
      height: root.fieldHeight
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.max(4, (parent.height - height - actions.height - feedback.height - 24 - (keyboard.visible ? keyboard.height + 12 : 0)) / 2)
      color: Commons.Color.lock.background
      borderSpec: root.inputBorderSpec
      radius: Style.cornerRadius
      clip: true

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        // Reserve the fingerprint icon's width on both sides so the centered
        // dots stay symmetric and never slide under the icon as they grow.
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: Commons.Color.lock.text
        selectionColor: Commons.Color.lock.selection
        selectedTextColor: Commons.Color.lock.text
        font.family: Style.font.family
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: Commons.Color.lock.text
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) {
            if (root.fingerprintScanning) root.passwordModeRequested()
            root.passwordTextEdited(text)
          }
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: root.submitInput()

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? Commons.Color.lock.text : (root.failureMessage.length > 0 ? Commons.Color.lock.textError : Commons.Color.lock.placeholder)
        font.family: Style.font.family
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      // Fingerprint hint pinned inside the field's right edge when a sensor is
      // enrolled, so the user knows they can touch to unlock instead of typing.
      // Matches hyprlock, which draws its fingerprint icon in the same spot.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: "󰈷"
        color: Commons.Color.lock.placeholder
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        TapHandler {
          enabled: root.inputEnabled && !root.authenticatingPassword && !root.fingerprintCooling
          onTapped: root.toggleFingerprint()
        }
      }
    }

    Row {
      id: actions
      anchors.top: inputField.bottom
      anchors.topMargin: 8
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8
      TouchKey {
        label: root.keyboardOpen ? "Hide keyboard" : "Show keyboard"
        width: (inputField.width - actions.spacing) / 2
        height: 44
        enabled: root.inputEnabled && !root.authenticatingPassword
        onClicked: {
          root.wakeRequested()
          root.passwordModeRequested()
          root.keyboardOpen = !root.keyboardOpen
          root.forcePasswordFocus()
        }
      }
      TouchKey {
        label: root.fingerprintScanning ? "Cancel scan" : root.fingerprintCooling ? "Reader unavailable" : root.fingerprintNotice ? "Try again" : "Use fingerprint"
        visible: root.fingerprintConfigured
        enabled: root.inputEnabled && !root.authenticatingPassword && !root.fingerprintCooling
        width: (inputField.width - actions.spacing) / 2
        height: 44
        onClicked: root.toggleFingerprint()
      }
    }
    Text {
      id: feedback
      anchors.top: actions.bottom
      anchors.topMargin: 4
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width - 16
      visible: text.length > 0
      text: root.fingerprintNotice
      textFormat: Text.PlainText
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      font.pixelSize: 16
      color: Commons.Color.lock.text
    }
    TouchKeyboard {
      id: keyboard
      visible: root.keyboardOpen && root.inputEnabled
      enabled: !root.authenticatingPassword
      anchors.top: feedback.bottom
      anchors.topMargin: 8
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(800, parent.width - 12)
      height: Math.min(245, parent.height * 0.43)
      onKeyEntered: key => root.touchKey(key)
    }
  }
}
