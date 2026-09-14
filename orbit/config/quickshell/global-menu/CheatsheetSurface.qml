import Quickshell
import Quickshell.Wayland
import QtQuick

// Keyboard cheatsheet overlay. Every row comes from `orbit-compositor binds`,
// which reports Hyprland's binds and niri's hotkey-overlay titles in one shape,
// so the compositor configuration is the only source under either: a bind that
// carries a description appears here, one that does not is absent, and neither
// can drift.
PanelWindow {
    id: root

    required property var screenData
    property var modelData: null
    required property var frontend
    required property var themeData

    screenData: modelData

    readonly property real columnWidth: 332
    readonly property real columnSpacing: 20
    readonly property real cardPadding: 24
    readonly property int columnCount: Math.max(1, Math.min(3,
        Math.floor((screenData.width - 80 + columnSpacing) / (columnWidth + columnSpacing))))
    readonly property var columns: frontend.cheatsheetColumns(columnCount)
    readonly property real cardWidth: columnCount * columnWidth
        + (columnCount - 1) * columnSpacing + cardPadding * 2
    readonly property real headerHeight: 30
    readonly property real headerSpacing: 18
    // Derived from the screen alone. Sizing the body against the card it sits in
    // would make the card's height depend on itself.
    readonly property real bodyLimit: screenData.height - 48 - cardPadding * 2
        - headerHeight - headerSpacing

    screen: screenData
    visible: frontend.cheatsheetOpen && frontend.cheatsheetOutput === screenData.name
    color: "transparent"
    surfaceFormat.opaque: false
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "orbit-cheatsheet"
    // Exclusive focus is what lets Escape close the overlay. Compositor keybinds
    // are dispatched ahead of the focused client, so Super+/ still toggles it.
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Shortcut {
        sequence: "Escape"
        onActivated: root.frontend.closeCheatsheet()
    }

    // Dimming the desktop separates the card from whatever is behind it without
    // the overlay having to paint an opaque background of its own.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.visible ? 0.38 : 0

        Behavior on opacity {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.frontend.closeCheatsheet()
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(root.cardWidth, root.screenData.width - 48)
        height: root.cardPadding * 2 + root.headerHeight + root.headerSpacing + body.height
        radius: root.themeData.values.radius + 4
        color: root.themeData.values.surfaceElevated
        border.width: 1
        border.color: root.themeData.values.border
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.97

        Behavior on opacity {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }

        // Swallow clicks so a press inside the card does not reach the scrim.
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: header

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.cardPadding
            height: root.headerHeight

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Keyboard Shortcuts"
                color: root.themeData.values.foreground
                font.family: root.themeData.values.font
                font.pixelSize: 15
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "close"
                    color: root.themeData.values.muted
                    opacity: 0.7
                    font.family: root.themeData.values.font
                    font.pixelSize: 12
                }

                KeyChip {
                    anchors.verticalCenter: parent.verticalCenter
                    themeData: root.themeData
                    text: "Esc"
                }
            }
        }

        // A Flickable keeps the overlay usable on a short display; on a tall one
        // the card simply sizes to its content and never scrolls.
        Flickable {
            id: body

            anchors.top: header.bottom
            anchors.topMargin: root.headerSpacing
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.cardPadding
            anchors.rightMargin: root.cardPadding
            height: Math.min(contentHeight, root.bodyLimit)
            contentHeight: layout.height
            contentWidth: width
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: layout

                width: parent.width
                spacing: root.columnSpacing

                Repeater {
                    model: root.columns

                    delegate: Column {
                        required property var modelData

                        width: (layout.width - (root.columnCount - 1) * root.columnSpacing)
                            / root.columnCount
                        spacing: 16

                        Repeater {
                            model: parent.modelData

                            delegate: Column {
                                required property var modelData

                                width: parent.width
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    color: root.themeData.values.accent
                                    font.family: root.themeData.values.font
                                    font.pixelSize: 11
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.8
                                    bottomPadding: 4
                                }

                                Repeater {
                                    model: modelData.rows

                                    delegate: Item {
                                        required property var modelData

                                        width: parent.width
                                        height: 26

                                        Text {
                                            anchors.left: parent.left
                                            anchors.right: chip.left
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            color: root.themeData.values.foreground
                                            font.family: root.themeData.values.font
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }

                                        KeyChip {
                                            id: chip

                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            themeData: root.themeData
                                            text: modelData.chord
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
