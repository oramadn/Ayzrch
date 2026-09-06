import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    readonly property var fallback: ({
        surface: "#1a1b26",
        surfaceElevated: "#24283b",
        foreground: "#c0caf5",
        muted: "#9aa5ce",
        accent: "#7aa2f7",
        border: "#3b4261",
        font: "JetBrains Mono NL SemiBold",
        radius: 10
    })
    property var values: fallback

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.local/state/noctalia/settings.toml"
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/noctalia/palettes/black-abstract-wallpaper-3840x2160-modern-geometric-shapes-26788-vib.json"
        watchChanges: true
        onLoaded: root.reload()
        onFileChanged: reload()
    }

    function reload() {
        var next = {}
        for (var key in fallback)
            next[key] = fallback[key]
        var settings = settingsFile.text()
        var font = settings.match(/font_family\s*=\s*"([^"]+)"/)
        if (font)
            next.font = font[1]
        var radius = settings.match(/corner_radius_scale\s*=\s*([0-9.]+)/)
        if (radius)
            next.radius = Math.max(0, Math.round(Number(radius[1]) * 5))
        var source = settings.match(/source\s*=\s*"([^"]+)"/)
        if (source && source[1] === "custom") {
            try {
                var palette = JSON.parse(paletteFile.text()).dark
                if (palette) {
                    next.surface = palette.mSurface || next.surface
                    next.surfaceElevated = palette.mSurfaceVariant || next.surfaceElevated
                    next.foreground = palette.mOnSurface || next.foreground
                    next.muted = palette.mOnSurfaceVariant || next.muted
                    next.accent = palette.mPrimary || next.accent
                    next.border = palette.mOutline || next.border
                }
            } catch (error) {}
        }
        values = next
    }

    Component.onCompleted: reload()
}
