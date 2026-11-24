import QtQuick
import qs.Commons as Commons

Rectangle {
  id: root
  required property string label
  signal clicked()

  radius: 6
  color: tap.pressed ? Commons.Color.lock.selection : Commons.Color.lock.background
  opacity: enabled ? 1 : 0.55
  border.width: 1
  border.color: Commons.Color.lock.placeholder
  Accessible.role: Accessible.Button
  Accessible.name: label
  Accessible.onPressAction: if (enabled && visible) clicked()
  Text {
    anchors.fill: parent
    anchors.margins: 2
    text: root.label
    textFormat: Text.PlainText
    color: Commons.Color.lock.text
    font.pixelSize: Math.min(18, Math.round(root.height * 0.5))
    fontSizeMode: Text.Fit
    minimumPixelSize: 9
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
  TapHandler { id: tap; onTapped: root.clicked() }
}
