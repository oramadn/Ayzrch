import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    required property var screenData
    property var modelData: null
    required property var frontend
    required property var themeData

    screenData: modelData

    screen: screenData
    visible: (frontend.menuOpen || frontend.applicationActionsOpen)
        && (frontend.activeOutput === screenData.name || frontend.applicationActionsOutput === screenData.name)
    color: "transparent"
    surfaceFormat.opaque: false
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "noctalia-global-menu-anchor"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        anchors.fill: parent
        focus: root.visible

        Keys.onEscapePressed: root.frontend.closeMenu()

        MouseArea {
            anchors.fill: parent
            onClicked: root.frontend.closeMenu()
        }
    }

    MenuSurface {
        frontend: root.frontend
        themeData: root.themeData
        screenData: root.screenData
        node: root.frontend.activeRoot()
        rootSurface: true
    }

    ApplicationActionsSurface {
        frontend: root.frontend
        themeData: root.themeData
        screenData: root.screenData
    }
}
