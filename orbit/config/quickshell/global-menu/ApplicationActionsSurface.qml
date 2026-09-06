import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    required property var frontend
    required property var themeData
    required property var screenData

    readonly property real popupWidth: 240
    readonly property real popupHeight: 106
    readonly property real popupX: frontend.applicationPopupX(screenData.name, popupWidth)
    readonly property real popupY: frontend.rootPanelY(screenData.name)

    screen: screenData
    visible: frontend.applicationActionsOpen && frontend.applicationActionsOutput === screenData.name
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0
    anchors { top: true; left: true; right: true; bottom: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "noctalia-global-menu-application-actions"

    MouseArea {
        anchors.fill: parent
        onClicked: frontend.closeMenu()
    }

    Rectangle {
        id: popup
        x: root.popupX
        y: root.popupY
        width: root.popupWidth
        height: root.popupHeight
        radius: root.themeData.values.radius
        color: root.themeData.values.surfaceElevated
        border.width: 1
        border.color: root.themeData.values.border

        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: [
                    { label: "Open new window", action: "open-new-window", enabled: true },
                    { label: "Close window", action: "close", enabled: true },
                    { label: "Force quit application", action: "force-quit", enabled: true }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 30
                    radius: Math.max(0, root.themeData.values.radius - 3)
                    color: actionMouse.containsMouse ? root.themeData.values.accent : "transparent"

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.label
                        color: actionMouse.containsMouse ? "#ffffff" : root.themeData.values.foreground
                        font.family: root.themeData.values.font
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            var output = root.frontend.applicationActionsOutput
                            root.frontend.closeMenu()
                            Quickshell.execDetached([
                                Quickshell.env("HOME") + "/.local/bin/noctalia-application-menu",
                                "activate", output, modelData.action
                            ])
                        }
                    }
                }
            }
        }
    }
}
