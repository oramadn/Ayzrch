import QtQuick

// A single key chord rendered as a keycap. Sized to its text so a chord as short
// as "Esc" and as long as "Super + Shift + ←/↓/↑/→" both sit on one row.
Rectangle {
    id: root

    required property var themeData
    property alias text: label.text

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 20
    radius: Math.max(3, themeData.values.radius - 4)
    color: themeData.values.surfaceSelected
    border.width: 1
    border.color: themeData.values.border

    Text {
        id: label

        anchors.centerIn: parent
        // A generated palette can resolve muted to the same value as the body
        // text, so the de-emphasis is carried by opacity rather than by colour.
        color: root.themeData.values.muted
        opacity: 0.85
        font.family: root.themeData.values.font
        font.pixelSize: 11
    }
}
