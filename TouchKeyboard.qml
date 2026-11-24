import QtQuick

Column {
  id: root
  property bool symbols: false
  property bool shifted: false
  readonly property var rows: symbols
    ? ["1234567890", "!@#$%^&*()", "-_=+[]{}\\|", ";:'\",.<>/?`~"]
    : ["1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm"]
  signal keyEntered(string key)
  spacing: 3
  readonly property real keyHeight: (height - 4 * spacing) / 5
  onVisibleChanged: if (!visible) { symbols = false; shifted = false }

  Repeater {
    model: root.rows
    delegate: Row {
      id: keyRow
      required property string modelData
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 3
      Repeater {
        model: keyRow.modelData.split("")
        delegate: TouchKey {
          required property string modelData
          label: root.shifted && !root.symbols ? modelData.toUpperCase() : modelData
          width: (root.width - (root.symbols ? 11 : 9) * keyRow.spacing) / (root.symbols ? 12 : 10)
          height: root.keyHeight
          onClicked: { root.keyEntered(label); root.shifted = false }
        }
      }
    }
  }
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 3
    Repeater {
      model: ["Shift", "#+=", "Space", "Backspace", "Enter"]
      delegate: TouchKey {
        required property string modelData
        label: modelData === "#+=" && root.symbols ? "ABC" : modelData === "Shift" && root.shifted ? "SHIFT" : modelData
        enabled: modelData !== "Shift" || !root.symbols
        width: (root.width - 12) / 5
        height: root.keyHeight
        onClicked: {
          if (modelData === "Shift") root.shifted = !root.shifted
          else if (modelData === "#+=") { root.symbols = !root.symbols; root.shifted = false }
          else root.keyEntered(modelData === "Space" ? " " : modelData)
        }
      }
    }
  }
}
