import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import qs.Commons
import qs.Ui

Item {
    id: root
    property bool opened: false
    property int pendingX: 0
    property int pendingY: 0
    // Resolve the bundled script from this plugin's install directory.
    readonly property string backend: String(Qt.resolvedUrl("trackpad-input")).replace("file://", "")

    function open(payloadJson) { opened = true }
    function close() { opened = false }
    function toggle() { opened = !opened }
    function click(button) {
        clickProcess.command = [root.backend, "click", button]
        clickProcess.running = true
    }

    Process { id: clickProcess }
    Process { id: moveProcess }

    Timer {
        interval: 16
        running: root.opened
        repeat: true
        onTriggered: {
            if (moveProcess.running || (root.pendingX === 0 && root.pendingY === 0)) return
            const x = root.pendingX
            const y = root.pendingY
            root.pendingX = 0
            root.pendingY = 0
            moveProcess.command = [root.backend, "move", String(x), String(y)]
            moveProcess.running = true
        }
    }

    PanelWindow {
        id: panel
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        mask: Region { item: card }
        WlrLayershell.namespace: "io.github.frostmute.onscreen-trackpad"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        BorderSurface {
            id: card
            width: Style.space(500)
            height: Style.space(360)
            x: panel.width - width - Style.spacing.lg
            y: panel.height - height - Style.spacing.lg
            radius: Style.cornerRadius
            color: Color.popups.background
            borderSpec: Border.hyprlandActiveSpec(Color.accent, 2)

            Text {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: Style.spacing.sm }
                text: "Omaglide"
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.title
            }

            Rectangle {
                id: pad
                anchors { top: parent.top; left: parent.left; right: parent.right; bottom: buttonRow.top
                    margins: Style.spacing.md; bottomMargin: Style.spacing.sm }
                radius: Style.cornerRadius
                color: Util.alpha(Color.foreground, Style.normalFillAlpha)
                border.color: Util.alpha(Color.foreground, Style.pressedFillAlpha)
                border.width: Style.normalBorderWidth

                // Hyprland delivers the built-in screen as touch input, not
                // mouse emulation. Pointer Handlers explicitly accept both.
                DragHandler {
                    id: dragHandler
                    target: null
                    acceptedDevices: PointerDevice.TouchScreen
                    property real previousX: 0
                    property real previousY: 0
                    onActiveChanged: {
                        previousX = 0
                        previousY = 0
                    }
                    onTranslationChanged: {
                        root.pendingX += Math.round((translation.x - previousX) * 1.6)
                        root.pendingY += Math.round((translation.y - previousY) * 1.6)
                        previousX = translation.x
                        previousY = translation.y
                    }
                }
                TapHandler {
                    acceptedDevices: PointerDevice.TouchScreen
                    onDoubleTapped: root.click("0xC0")
                }
                // Explicit mouse fallback for layer-shell pointer input.
                MouseArea {
                    anchors.fill: parent
                    property real previousX: 0
                    property real previousY: 0
                    onPressed: function(mouse) { previousX = mouse.x; previousY = mouse.y }
                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        root.pendingX += Math.round((mouse.x - previousX) * 1.6)
                        root.pendingY += Math.round((mouse.y - previousY) * 1.6)
                        previousX = mouse.x
                        previousY = mouse.y
                    }
                    onDoubleClicked: root.click("0xC0")
                }
            }

            Row {
                id: buttonRow
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Style.spacing.md }
                spacing: Style.spacing.sm
                height: Style.space(60)

                Repeater {
                    model: [ { label: "Left click", code: "0xC0" }, { label: "Right click", code: "0xC1" }, { label: "Close", code: "" } ]
                    delegate: Rectangle {
                        required property var modelData
                        width: (buttonRow.width - buttonRow.spacing * 2) / 3
                        height: buttonRow.height
                        radius: Style.cornerRadius
                        color: buttonArea.pressed ? Color.accent : Util.alpha(Color.foreground, Style.normalFillAlpha)
                        Text { anchors.centerIn: parent; text: parent.modelData.label; color: Color.foreground; font.family: Style.font.family; font.pixelSize: Style.font.body }
                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            onClicked: parent.modelData.code ? root.click(parent.modelData.code) : root.close()
                        }
                    }
                }
            }
        }
    }
}
