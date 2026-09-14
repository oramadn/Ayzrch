import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    readonly property string statePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/noctalia-global-menu-state.json"
    property var state: ({ outputs: ({}) })
    property var sessionState: null
    property var pendingState: null
    property string sessionCandidate: ""
    property string sessionSignature: ""
    property var activePath: []
    property var hoveredItemPerLevel: ({})
    property bool pointerInsideAnyMenuSurface: false
    property string activeOutput: ""
    property int activeIndex: -1
    property real pointerX: -1
    property real pointerY: -1
    property string activeCandidate: ""
    property bool menuOpen: false
    property bool applicationActionsOpen: false
    property string applicationActionsOutput: ""
    property string applicationActionsCandidate: ""
    property int requestGeneration: 0
    property var pendingOpen: null
    property string pendingApplicationOutput: ""
    property var monitorGeometry: ({})
    property var panelGeometry: ({})
    property bool cheatsheetOpen: false
    property string cheatsheetOutput: ""
    property var cheatsheetGroups: []

    // Modifier bits reported by `orbit-compositor binds`, in the order a chord
    // reads. They are Hyprland's numbering under either compositor.
    readonly property var cheatsheetModifiers: [
        { mask: 64, name: "Super" },
        { mask: 4, name: "Ctrl" },
        { mask: 8, name: "Alt" },
        { mask: 1, name: "Shift" }
    ]
    // Keysyms whose printed form differs from the reported name. Both scroll
    // directions collapse to one label so they merge into a single row.
    readonly property var cheatsheetKeyNames: ({
        "left": "←", "right": "→", "up": "↑", "down": "↓",
        "Return": "Enter", "Escape": "Esc", "TAB": "Tab", "space": "Space",
        "grave": "`", "slash": "/", "comma": ",", "period": ".",
        "minus": "-", "equal": "=", "bracketleft": "[", "bracketright": "]",
        "semicolon": ";", "apostrophe": "'", "backslash": "\\",
        "mouse:272": "Left click", "mouse:273": "Right click",
        "mouse:274": "Middle click", "mouse_up": "Scroll", "mouse_down": "Scroll"
    })

    ThemeAdapter { id: theme }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        onLoaded: root.reloadState()
        onFileChanged: {
            reload()
            Qt.callLater(root.reloadState)
        }
    }

    Process {
        id: cursorProcess
        command: ["orbit-compositor", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: root.finishCursorOpen(text)
        }
    }

    Process {
        id: monitorProcess
        command: ["orbit-compositor", "monitors"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var next = {}
                    JSON.parse(text || "[]").forEach(function(monitor) {
                        next[String(monitor.name)] = monitor
                    })
                    root.monitorGeometry = next
                } catch (error) { root.monitorGeometry = ({}) }
            }
        }
    }

    Process {
        id: focusProcess
        command: ["orbit-compositor", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: root.checkFocusedApplication(text)
        }
    }

    Process {
        id: panelProcess
        command: ["orbit-compositor", "layers"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var next = {}
                    function visit(value) {
                        if (!value || typeof value !== "object")
                            return
                        if (value.namespace === "noctalia-bar-Top") {
                            next[String(value.x)] = value
                            return
                        }
                        for (var key in value)
                            visit(value[key])
                    }
                    visit(JSON.parse(text || "{}"))
                    root.panelGeometry = next
                } catch (error) { root.panelGeometry = ({}) }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!monitorProcess.running) monitorProcess.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: if (!panelProcess.running) panelProcess.running = true
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: if (!focusProcess.running) focusProcess.running = true
    }

    Timer {
        id: pointerExitTimer
        interval: 120
        onTriggered: root.pointerInsideAnyMenuSurface = false
    }

    // The cheatsheet resolves its own monitor and bind list on every open rather
    // than reusing the polled copies, so the overlay can never land on the
    // monitor that was focused a second ago or show a stale bind.
    Process {
        id: cheatsheetMonitorProcess
        command: ["orbit-compositor", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: root.finishCheatsheetOutput(text)
        }
    }

    Process {
        id: cheatsheetBindsProcess
        command: ["orbit-compositor", "binds"]
        stdout: StdioCollector {
            onStreamFinished: root.finishCheatsheetOpen(text)
        }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle() { root.toggleCheatsheet() }

        function open() { root.openCheatsheet() }

        function close() { root.closeCheatsheet() }
    }

    IpcHandler {
        target: "global-menu"

        function open(output: string, index: string, x: string, y: string, generation: string) {
            root.requestOpen(String(output || ""), Number(index) - 1, Number(x), Number(y), String(generation || ""))
        }

        function openApplication(output: string, generation: string) {
            root.requestApplicationOpen(String(output || ""), String(generation || ""))
        }

        function close() { root.closeMenu() }
    }

    function reloadState() {
        var nextState
        try { nextState = JSON.parse(stateFile.text()) || ({ outputs: ({}) }) }
        catch (error) { nextState = ({ outputs: ({}) }) }
        state = nextState
        var watchedOutput = applicationActionsOpen ? applicationActionsOutput : activeOutput
        var current = state.outputs && state.outputs[watchedOutput]
        var nextCandidate = current && current.candidate ? String(current.candidate.address || "") : ""
        activeCandidate = nextCandidate
        if (applicationActionsOpen) {
            var applicationCandidate = current && current.candidate
                ? String(current.candidate.address || "") : ""
            if (applicationCandidate !== applicationActionsCandidate) {
                closeMenu()
            }
            return
        }
        if (!menuOpen)
            return
        var candidate = candidateIdentity(current && current.candidate)
        var signature = outputSignature(current)
        if (!current || !current.available || candidate !== sessionCandidate) {
            closeMenu()
            return
        }
        if (signature !== sessionSignature) {
            pendingState = clone(nextState)
        }
    }

    function outputState(output) {
        return state.outputs && state.outputs[output] ? state.outputs[output] : null
    }

    function checkFocusedApplication(raw) {
        if (!applicationActionsOpen)
            return
        try {
            var focused = JSON.parse(raw || "{}")
            if (String(focused.address || "") !== applicationActionsCandidate)
                closeMenu()
        } catch (error) {
            // Keep the popup open on a transient compositor query failure.
        }
    }

    function activeRoot() {
        var output = sessionState && sessionState.outputs ? sessionState.outputs[activeOutput] : null
        return output && output.menus && activeIndex >= 0 ? output.menus[activeIndex] : null
    }

    function clone(value) {
        return JSON.parse(JSON.stringify(value))
    }

    function candidateIdentity(candidate) {
        if (!candidate)
            return ""
        return String(candidate.address || "") + ":" + String(candidate.pid || "")
    }

    function outputSignature(output) {
        if (!output)
            return ""
        function itemSignature(item) {
            var action = item.action || ({})
            var children = (item.children || []).map(itemSignature).join(",")
            return [item.id, item.label, item.type, item.enabled, item.visible, item.checked,
                item.shortcut, action.source, action.service, action.path, action.windowId, action.id,
                "[" + children + "]"].join("|")
        }
        return (output.menus || []).map(itemSignature).join(";")
    }

    function requestOpen(output, index, x, y, generation) {
        closeCheatsheet()
        var value = outputState(output)
        if (!value || !value.available || !value.menus || !value.menus[index]) {
            closeMenu()
            return
        }
        activeOutput = output
        activeIndex = index
        activeCandidate = String(value.candidate && value.candidate.address || "")
        sessionState = clone(state)
        sessionCandidate = candidateIdentity(value.candidate)
        sessionSignature = outputSignature(value)
        pendingState = null
        activePath = []
        hoveredItemPerLevel = ({})
        pointerInsideAnyMenuSurface = false
        requestGeneration = requestGeneration + 1
        pendingOpen = { x: x, y: y, generation: generation }
        menuOpen = false
        if (x >= 0) {
            pointerX = x
            menuOpen = true
        } else if (!cursorProcess.running) {
            cursorProcess.running = true
        }
    }

    function finishCursorOpen(raw) {
        if (pendingApplicationOutput !== "") {
            var applicationOutput = pendingApplicationOutput
            pendingApplicationOutput = ""
            try {
                var applicationCursor = JSON.parse(raw || "{}")
                pointerX = Number(applicationCursor.x)
                pointerY = Number(applicationCursor.y)
            } catch (error) {
                pointerX = -1
                pointerY = -1
            }
            if (pointerX >= 0 && pointerY >= 0) {
                applicationActionsOutput = applicationOutput
                applicationActionsOpen = true
            }
            return
        }
        if (!pendingOpen)
            return
        var request = pendingOpen
        pendingOpen = null
        try {
            var cursor = JSON.parse(raw || "{}")
            pointerX = Number(cursor.x)
            pointerY = Number(cursor.y)
        } catch (error) {
            pointerX = -1
            pointerY = -1
        }
        if (pointerX >= 0)
            menuOpen = true
    }

    function closeMenu() {
        pendingOpen = null
        pendingApplicationOutput = ""
        menuOpen = false
        applicationActionsOpen = false
        applicationActionsOutput = ""
        applicationActionsCandidate = ""
        activeOutput = ""
        activeIndex = -1
        sessionState = null
        sessionCandidate = ""
        sessionSignature = ""
        pendingState = null
        activePath = []
        hoveredItemPerLevel = ({})
        pointerInsideAnyMenuSurface = false
    }

    function requestApplicationOpen(output, generation) {
        closeCheatsheet()
        var value = outputState(output)
        var candidate = value && value.candidate ? value.candidate : null
        var address = candidate ? String(candidate.address || "") : ""
        if (!value || !candidate || address === "" || (generation && generation !== address)) {
            closeMenu()
            return
        }
        closeMenu()
        applicationActionsOutput = String(output)
        applicationActionsCandidate = address
        pendingApplicationOutput = String(output)
        if (!cursorProcess.running)
            cursorProcess.running = true
    }

    function menuSurfaceEntered() {
        pointerExitTimer.stop()
        pointerInsideAnyMenuSurface = true
    }

    function menuSurfaceExited() {
        pointerExitTimer.restart()
    }

    function updateHover(path, index, hasChildren) {
        var nextHovered = {}
        for (var key in hoveredItemPerLevel)
            nextHovered[key] = hoveredItemPerLevel[key]
        nextHovered[String(path.length)] = index
        hoveredItemPerLevel = nextHovered
        activePath = hasChildren ? path.concat([index]) : path.slice(0)
    }

    function anchorX(screen) {
        var monitor = monitorGeometry[String(screen.name)] || ({})
        return Math.max(0, pointerX - Number(monitor.x || 0))
    }

    function applicationPopupX(output, popupWidth) {
        var monitor = monitorGeometry[String(output)] || ({})
        var localX = pointerX - Number(monitor.x || 0) - popupWidth / 2
        return Math.max(6, Math.min(localX, monitorWidth(output) - popupWidth - 6))
    }

    function rootPanelY(output) {
        var monitor = monitorGeometry[String(output)] || ({})
        var panel = panelGeometry[String(monitor.x || 0)] || ({})
        return Math.max(0, Number(panel.y || 0) + Number(panel.h || 0) - Number(monitor.y || 0) + 4)
    }

    function monitorWidth(output) {
        return Number((monitorGeometry[String(output)] || ({})).width || 0)
    }

    function monitorHeight(output) {
        return Number((monitorGeometry[String(output)] || ({})).height || 0)
    }

    function toggleCheatsheet() {
        if (cheatsheetOpen)
            closeCheatsheet()
        else
            openCheatsheet()
    }

    function openCheatsheet() {
        // The menu and the cheatsheet both take the overlay layer, so only one
        // of them is ever up.
        closeMenu()
        if (!cheatsheetMonitorProcess.running)
            cheatsheetMonitorProcess.running = true
    }

    function closeCheatsheet() {
        cheatsheetOpen = false
        cheatsheetOutput = ""
    }

    function finishCheatsheetOutput(raw) {
        var output = ""
        try {
            JSON.parse(raw || "[]").forEach(function(monitor) {
                if (monitor.focused === true)
                    output = String(monitor.name)
            })
        } catch (error) {
            output = ""
        }
        cheatsheetOutput = output
        if (output === "")
            return
        if (!cheatsheetBindsProcess.running)
            cheatsheetBindsProcess.running = true
    }

    function finishCheatsheetOpen(raw) {
        loadCheatsheet(raw)
        cheatsheetOpen = cheatsheetOutput !== "" && cheatsheetGroups.length > 0
    }

    function cheatsheetModifierText(mask) {
        var parts = []
        cheatsheetModifiers.forEach(function(modifier) {
            if ((mask & modifier.mask) !== 0)
                parts.push(modifier.name)
        })
        return parts.join(" + ")
    }

    function cheatsheetKeyText(key) {
        if (cheatsheetKeyNames[key] !== undefined)
            return cheatsheetKeyNames[key]
        return key.length === 1 ? key.toUpperCase() : key
    }

    function cheatsheetChord(modifiers, keys) {
        // A run of digits is a range in every case Orbit binds one, so the ten
        // workspace keys read as 1–0 instead of a slash-separated wall.
        var everyDigit = keys.every(function(key) { return /^[0-9]$/.test(key) })
        var text = keys.length > 3 && everyDigit
            ? keys[0] + "–" + keys[keys.length - 1]
            : keys.join("/")
        return modifiers ? modifiers + " + " + text : text
    }

    // Binds are grouped and merged by the "Group | Label" description they carry.
    // Binds sharing a group, a label and a modifier set become one row whose keys
    // are joined, which is what collapses the directional and workspace loops.
    function loadCheatsheet(raw) {
        var entries = []
        try { entries = JSON.parse(raw || "[]") || [] }
        catch (error) { entries = [] }
        var groups = []
        var groupByName = ({})
        var rowByIdentity = ({})
        entries.forEach(function(entry) {
            var description = String(entry.description || "")
            var separator = description.indexOf(" | ")
            if (separator < 0)
                return
            var groupName = description.substring(0, separator).trim()
            var label = description.substring(separator + 3).trim()
            var key = cheatsheetKeyText(String(entry.key || ""))
            if (groupName === "" || label === "" || key === "")
                return
            var modifiers = cheatsheetModifierText(Number(entry.modmask || 0))
            var group = groupByName[groupName]
            if (!group) {
                group = { name: groupName, rows: [] }
                groupByName[groupName] = group
                groups.push(group)
            }
            var identity = [groupName, label, modifiers].join(" ")
            var row = rowByIdentity[identity]
            if (!row) {
                row = { label: label, modifiers: modifiers, keys: [] }
                rowByIdentity[identity] = row
                group.rows.push(row)
            }
            if (row.keys.indexOf(key) < 0)
                row.keys.push(key)
        })
        groups.forEach(function(group) {
            group.rows.forEach(function(row) {
                row.chord = root.cheatsheetChord(row.modifiers, row.keys)
            })
        })
        cheatsheetGroups = groups
    }

    // Greedy balance: each group lands in the shortest column so far, counting
    // its heading as two rows. Groups keep their configuration order otherwise.
    function cheatsheetColumns(count) {
        var columns = []
        var weights = []
        for (var index = 0; index < count; index++) {
            columns.push([])
            weights.push(0)
        }
        cheatsheetGroups.forEach(function(group) {
            var lightest = 0
            for (var index = 1; index < count; index++) {
                if (weights[index] < weights[lightest])
                    lightest = index
            }
            columns[lightest].push(group)
            weights[lightest] += group.rows.length + 2
        })
        return columns
    }

    Variants {
        model: Quickshell.screens
        AnchorSurface {
            modelData: modelData
            frontend: root
            themeData: theme
        }
    }

    Variants {
        model: Quickshell.screens
        CheatsheetSurface {
            modelData: modelData
            frontend: root
            themeData: theme
        }
    }

    Component.onCompleted: root.reloadState()
}
