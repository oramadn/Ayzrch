import Quickshell
import Quickshell.Io
import QtQuick

// Presentation values for every surface this shell draws.
//
// Colours come from the semantic palette orbit-theme regenerates whenever the
// Noctalia palette changes, and shape and typography come from Orbit's own
// appearance policy. Both are the same inputs the GTK, Qt and terminal adapters
// read, so the shell cannot drift from the rest of the desktop.
Item {
    id: root

    readonly property var fallback: ({
        surface: "#1a1b26",
        surfaceElevated: "#24283b",
        surfaceSelected: "#2f334d",
        foreground: "#c0caf5",
        muted: "#9aa5ce",
        accent: "#7aa2f7",
        border: "#3b4261",
        font: "JetBrains Mono",
        radius: 11
    })
    property var values: fallback

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/orbit/generated/noctalia/semantic.json"
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    FileView {
        id: appearanceFile
        path: Quickshell.env("HOME") + "/.config/hypr/appearance.toml"
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    // Returns the body of a TOML table, up to the next table header.
    function section(text, name) {
        var escaped = name.split(".").join("\\.")
        var match = String(text || "").match(new RegExp("\\[" + escaped + "\\]([^\\[]*)"))
        return match ? match[1] : ""
    }

    function reload() {
        var next = {}
        for (var key in fallback)
            next[key] = fallback[key]

        try {
            var semantic = JSON.parse(paletteFile.text()).semantic
            if (semantic) {
                next.surface = semantic.surface || next.surface
                next.surfaceElevated = semantic.surface_elevated || next.surfaceElevated
                next.surfaceSelected = semantic.surface_selected || next.surfaceSelected
                next.foreground = semantic.text || next.foreground
                next.muted = semantic.text_muted || next.muted
                next.accent = semantic.accent || next.accent
                next.border = semantic.border || next.border
            }
        } catch (error) {
            // A partially written palette leaves the previous values in place.
        }

        var appearance = appearanceFile.text()
        var radius = root.section(appearance, "shape").match(/corner_radius\s*=\s*([0-9.]+)/)
        if (radius)
            next.radius = Math.max(0, Math.round(Number(radius[1])))
        var font = root.section(appearance, "typography.body").match(/family\s*=\s*"([^"]+)"/)
        if (font)
            next.font = font[1]

        values = next
    }

    Component.onCompleted: reload()
}
