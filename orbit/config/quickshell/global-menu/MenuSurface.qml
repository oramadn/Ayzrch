import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    property var frontend: null
    property var themeData: null
    property var screenData: null
    property var node: null
    property bool rootSurface: false
    property var parentWindow: null
    property int anchorRow: -1
    property int openChild: -1
    property bool dismissing: false
    property var menuPath: []
    property real surfaceX: 0
    property real surfaceY: 0
    property var submenuItems: []
    property bool loadingSubmenu: false
    property string expansionPath: ""
    property string expansionSource: ""
    readonly property real surfaceWidth: root.implicitWidth
    readonly property real surfaceHeight: root.implicitHeight

    visible: {
        var result = frontend.menuOpen && frontend.activeOutput === screenData.name
            && node !== null && !loadingSubmenu && submenuItems.length > 0
        return result
    }
    implicitWidth: Math.max(190, widthFor(node))
    implicitHeight: Math.max(44, heightForItems(submenuItems) + 12)
    screen: screenData
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: root.rootSurface ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "noctalia-global-menu-surface"
    mask: Region { item: menuFrame }

    Process {
        id: expansionProcess
        stdout: StdioCollector {
            onStreamFinished: root.finishExpansion(text)
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: root.visible
        onTriggered: root.updateSurface()
    }

    function updateSurface() {
        if (root.rootSurface) {
            root.surfaceX = root.frontend.anchorX(root.screenData)
            root.surfaceY = root.frontend.rootPanelY(root.screenData.name)
        } else if (root.parentWindow) {
            root.surfaceX = root.parentWindow.surfaceX
                + (root.opensLeft() ? -root.surfaceWidth : root.parentWindow.surfaceWidth)
            root.surfaceY = root.submenuTop()
        }
    }

    function childrenFor(value) {
        var result = []
        function append(item) {
            if (!item || item.visible === false)
                return
            if (!String(item.label || "") && item.children && item.children.length) {
                item.children.forEach(append)
                return
            }
            result.push(item)
        }
        ;((value && value.children) || []).forEach(append)
        return result
    }

    function normalizeExpanded(value) {
        var item = {
            id: String(value.id || ""),
            label: String(value.label || ""),
            type: String(value.type || "standard"),
            enabled: value.enabled !== false,
            visible: value.visible !== false,
            checked: value.checked === true,
            shortcut: String(value.shortcut || ""),
            children: [],
            action: {
                source: "atspi",
                service: String(value.service || ""),
                path: String(value.path || "")
            }
        }
        ;(value.children || []).forEach(function(child) {
            item.children.push(root.normalizeExpanded(child))
        })
        return item
    }

    function normalizeDirect(value) {
        var properties = value.properties || ({})
        var item = {
            id: String(value.id || ""),
            label: String(properties.label || ""),
            type: String(properties.type || "standard"),
            enabled: properties.enabled !== false,
            visible: properties.visible !== false,
            checked: properties["toggle-state"] === 1,
            shortcut: String(properties.shortcut || ""),
            childrenDisplay: String(properties["children-display"] || ""),
            children: [],
            action: {
                source: String(value.source || "direct-dbusmenu"),
                service: String(value.service || ""),
                path: String(value.path || ""),
                id: Number(value.id || 0)
            }
        }
        ;(value.children || []).forEach(function(child) { item.children.push(root.normalizeDirect(child)) })
        return item
    }

    function hasChildren(item) {
        return Boolean(item && ((item.children && item.children.length)
            || item.childrenDisplay === "submenu"))
    }

    function heightForItems(items) {
        var total = 0
        ;(items || []).forEach(function(item) { total += rowHeight(item) })
        return total
    }

    function needsExpansion() {
        if (!root.node || !root.node.action)
            return false
        if (root.node.action.source === "direct-dbusmenu")
            return root.hasChildren(root.node) && (!root.node.children || root.node.children.length === 0)
        if (root.rootSurface)
            return false
        if (root.node.action.source !== "atspi" || !root.node.children
                || root.node.children.length === 0)
            return false
        return root.node.children.every(function(item) {
            return !String(item.label || "") && (!item.children || item.children.length === 0)
        })
    }

    function resetItems() {
        root.loadingSubmenu = false
        root.expansionPath = ""
        root.expansionSource = ""
        root.submenuItems = root.childrenFor(root.node)
        if (root.needsExpansion()) {
            var action = root.node.action
            root.loadingSubmenu = true
            root.submenuItems = []
            root.expansionPath = String(action.path || "")
            root.expansionSource = String(action.source || "")
            if (root.expansionSource === "direct-dbusmenu") {
                expansionProcess.command = [
                    Quickshell.env("HOME") + "/.local/bin/orbit-appmenu",
                    "expand-direct", String(action.service || ""), String(action.path || ""),
                    String(root.node.id)
                ]
            } else {
                expansionProcess.command = [
                    Quickshell.env("HOME") + "/.local/bin/orbit-appmenu-atspi",
                    "expand", String(action.service || ""), String(action.path || "")
                ]
            }
            expansionProcess.running = true
        }
    }

    function finishExpansion(raw) {
        if (!root.expansionPath)
            return
        var expanded = []
        try { expanded = JSON.parse(raw || "[]") || [] }
        catch (error) { expanded = [] }
        var currentAction = root.node && root.node.action
        if (!currentAction || String(currentAction.path || "") !== root.expansionPath)
            return
        var normalized = expanded.map(function(item) {
            return root.expansionSource === "direct-dbusmenu"
                ? root.normalizeDirect(item) : root.normalizeExpanded(item)
        })
        root.submenuItems = root.childrenFor({ children: normalized })
        root.loadingSubmenu = false
    }

    function rowHeight(item) { return item.type === "separator" ? 9 : 30 }

    function heightFor(value) {
        return heightForItems(root.childrenFor(value))
    }

    function widthFor(value) {
        var widest = 0
        var items = value === root.node ? root.submenuItems : root.childrenFor(value)
        items.forEach(function(item) {
            var label = String(item.label || "")
            var width = label.length * 7.2 + 64 + (item.children && item.children.length ? 18 : 0)
            widest = Math.max(widest, width)
        })
        return Math.min(440, widest + 12)
    }

    function rowY(index) {
        var y = 6
        var rows = root.submenuItems
        for (var i = 0; i < index; i++)
            y += rowHeight(rows[i])
        return y
    }

    function opensLeft() {
        if (!root.parentWindow)
            return false
        return root.parentWindow.surfaceX + root.parentWindow.surfaceWidth + root.surfaceWidth
            > root.frontend.monitorWidth(screenData.name) - 4
    }

    function submenuTop() {
        var desired = root.parentWindow.surfaceY + root.parentWindow.rowY(root.anchorRow)
        var limit = root.frontend.monitorHeight(screenData.name) - root.surfaceHeight - 4
        return Math.max(0, Math.min(desired, limit))
    }

    function closeBranch() { openChild = -1 }

    function syncChild() {
        if (!childLoader.item)
            return
        childLoader.item.node = root.submenuItems[root.openChild] || null
        childLoader.item.anchorRow = root.openChild
        childLoader.item.menuPath = root.menuPath.concat([root.openChild])
        childLoader.item.openChild = -1
        childLoader.item.updateSurface()
    }

    onOpenChildChanged: syncChild()
    onNodeChanged: {
        root.resetItems()
        root.syncChild()
    }

    function activate(item) {
        if (item.enabled === false || item.type === "separator" || root.hasChildren(item))
            return
        var output = root.frontend.activeOutput
        root.frontend.closeMenu()
        var payload = JSON.stringify(item.action || ({}))
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/noctalia-global-menu", "activate", output, payload])
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.frontend.closeMenu()
    }

    MouseArea {
        anchors.fill: parent
        z: 0
        hoverEnabled: true
        onEntered: root.frontend.menuSurfaceEntered()
        onExited: root.frontend.menuSurfaceExited()
        onClicked: function(mouse) {
            if (mouse.x < root.surfaceX || mouse.x > root.surfaceX + root.surfaceWidth
                    || mouse.y < root.surfaceY || mouse.y > root.surfaceY + root.surfaceHeight) {
                if (root.rootSurface)
                    root.frontend.closeMenu()
                else
                    root.parentWindow.closeBranch()
            }
        }
    }

    Item {
        id: menuFrame
        x: root.surfaceX
        y: root.surfaceY
        width: root.surfaceWidth
        height: root.surfaceHeight
        z: 1

        Rectangle {
            anchors.fill: parent
        anchors.margins: 1
        radius: themeData.values.radius
            color: themeData.values.surfaceElevated
        border.width: 1
        border.color: themeData.values.border

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 0

            Repeater {
        model: root.submenuItems

                delegate: Item {
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: modelData.type === "separator" ? 9 : 30

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: modelData.type === "separator" ? 4 : 0
                        visible: modelData.type === "separator"
                        height: 1
                        color: themeData.values.border
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: modelData.type !== "separator"
                        radius: Math.max(0, themeData.values.radius - 3)
                        color: menuMouse.containsMouse ? themeData.values.accent : "transparent"
                        opacity: modelData.enabled === false ? 0.42 : 1

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: (modelData.checked ? "✓  " : "") + String(modelData.label || "")
                            color: menuMouse.containsMouse ? "#ffffff" : themeData.values.foreground
                            font.family: themeData.values.font
                            font.pixelSize: 12
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.children && modelData.children.length ? "›" : String(modelData.shortcut || "")
                            color: menuMouse.containsMouse ? "#ffffff" : themeData.values.muted
                            font.family: themeData.values.font
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData.enabled !== false
                            onEntered: {
                                root.dismissing = false
                                root.frontend.updateHover(root.menuPath, index,
                                    root.hasChildren(modelData))
                                if (root.hasChildren(modelData))
                                    root.openChild = index
                                else
                                    root.closeBranch()
            }
                            onClicked: {
                                if (root.hasChildren(modelData))
                                    root.openChild = index
                                else
                                    root.activate(modelData)
                            }
                        }
                    }
                }
            }
            }
        }
    }

    Loader {
        id: childLoader
        active: root.openChild >= 0 && root.submenuItems[root.openChild] !== undefined
        source: Qt.resolvedUrl("MenuSurface.qml")
        onLoaded: {
            item.frontend = root.frontend
            item.themeData = root.themeData
            item.screenData = root.screenData
            item.node = root.submenuItems[root.openChild]
            item.rootSurface = false
            item.parentWindow = root
            item.anchorRow = root.openChild
            item.menuPath = root.menuPath.concat([root.openChild])
            item.updateSurface()
        }
    }
}
