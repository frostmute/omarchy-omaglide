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
    property int pendingWheel: 0
    property real lastClickTime: 0
    property bool userMoved: false

    // Resolve the bundled script from this plugin's install directory.
    readonly property string backend: String(Qt.resolvedUrl("trackpad-input")).replace("file://", "")

    function open(payloadJson) {
        opened = true
        root.initPosition()
    }
    function close() { opened = false }
    function toggle() {
        if (opened) close()
        else open()
    }

    function click(button) {
        const now = Date.now()
        if (now - lastClickTime < 80) return
        lastClickTime = now
        clickProcess.command = [root.backend, "click", button]
        clickProcess.running = true
    }

    function clampPosition() {
        const screenW = panel.screen ? panel.screen.width : panel.width
        const screenH = panel.screen ? panel.screen.height : panel.height
        if (screenW > 0 && card.width > 0) {
            const minX = Style.spacing.xs
            const maxX = Math.max(minX, screenW - card.width - Style.spacing.xs)
            if (card.x < minX) card.x = minX
            else if (card.x > maxX) card.x = maxX
        }
        if (screenH > 0 && card.height > 0) {
            const minY = Style.spacing.xs
            const maxY = Math.max(minY, screenH - card.height - Style.spacing.xs)
            if (card.y < minY) card.y = minY
            else if (card.y > maxY) card.y = maxY
        }
    }

    function resetPosition() {
        root.userMoved = false
        const screenW = panel.screen ? panel.screen.width : panel.width
        const screenH = panel.screen ? panel.screen.height : panel.height
        if (screenW > 0 && screenH > 0) {
            card.x = Math.round(screenW - card.width - Style.spacing.lg)
            card.y = Math.round(screenH - card.height - Style.spacing.lg)
        }
    }

    function initPosition() {
        if (root.userMoved) {
            root.clampPosition()
        } else {
            root.resetPosition()
        }
    }

    Process { id: clickProcess }
    Process { id: moveProcess }
    Process { id: scrollProcess }

    Timer {
        interval: 16
        running: root.opened
        repeat: true
        onTriggered: {
            if (!moveProcess.running && (root.pendingX !== 0 || root.pendingY !== 0)) {
                const x = root.pendingX
                const y = root.pendingY
                root.pendingX = 0
                root.pendingY = 0
                moveProcess.command = [root.backend, "move", String(x), String(y)]
                moveProcess.running = true
            }
            if (!scrollProcess.running && root.pendingWheel !== 0) {
                const w = root.pendingWheel
                root.pendingWheel = 0
                scrollProcess.command = [root.backend, "scroll", String(w)]
                scrollProcess.running = true
            }
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

        onWidthChanged: root.initPosition()
        onHeightChanged: root.initPosition()

        BorderSurface {
            id: card
            width: Style.space(500)
            height: Style.space(380)
            x: Math.round((panel.screen ? panel.screen.width : panel.width) - width - Style.spacing.lg)
            y: Math.round((panel.screen ? panel.screen.height : panel.height) - height - Style.spacing.lg)
            radius: Style.cornerRadius
            color: Color.popups.background
            borderSpec: Border.hyprlandActiveSpec(Color.accent, 2)

            onXChanged: root.clampPosition()
            onYChanged: root.clampPosition()

            // Draggable header bar across the top of the card
            Item {
                id: dragBar
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: Style.space(38)

                DragHandler {
                    id: windowDragHandler
                    target: card
                    onActiveChanged: {
                        if (active) root.userMoved = true
                    }
                }

                TapHandler {
                    onDoubleTapped: root.resetPosition()
                }

                MouseArea {
                    id: headerMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    onDoubleClicked: root.resetPosition()
                }

                // Left: Icon + Title
                Row {
                    anchors {
                        left: parent.left
                        leftMargin: Style.spacing.md
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Style.spacing.xs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰟸"
                        color: (windowDragHandler.active || headerMouseArea.pressed) ? Color.accent : Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.body
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Omaglide"
                        color: Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.body
                        font.weight: Font.Medium
                    }
                }

                // Center: Draggable pill / grip handle
                Rectangle {
                    anchors.centerIn: parent
                    width: Style.space(48)
                    height: Style.space(4)
                    radius: Style.space(2)
                    color: (windowDragHandler.active || headerMouseArea.pressed)
                        ? Color.accent
                        : Util.alpha(Color.foreground, Style.pressedFillAlpha)
                }

                // Right: Close button
                Rectangle {
                    id: headerCloseBtn
                    anchors {
                        right: parent.right
                        rightMargin: Style.spacing.sm
                        verticalCenter: parent.verticalCenter
                    }
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: headerCloseArea.pressed
                        ? Color.accent
                        : (headerCloseArea.containsMouse ? Util.alpha(Color.foreground, Style.normalFillAlpha) : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: headerCloseArea.pressed
                            ? Color.background
                            : (headerCloseArea.containsMouse ? Color.foreground : Color.muted)
                        font.family: Style.font.family
                        font.pixelSize: Style.font.bodySmall
                    }

                    MouseArea {
                        id: headerCloseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                id: pad
                anchors {
                    top: dragBar.bottom
                    left: parent.left
                    right: parent.right
                    bottom: buttonRow.top
                    margins: Style.spacing.md
                    topMargin: Style.spacing.xs
                    bottomMargin: Style.spacing.sm
                }
                radius: Style.cornerRadius
                color: Util.alpha(Color.foreground, (singleDragHandler.active || padMouseArea.pressed) ? Style.pressedFillAlpha : Style.normalFillAlpha)
                border.color: Util.alpha(Color.foreground, Style.pressedFillAlpha)
                border.width: Style.normalBorderWidth

                property bool isDragging: false

                Timer {
                    id: dragResetTimer
                    interval: 60
                    onTriggered: pad.isDragging = false
                }

                // Single finger touch drag: Moves pointer
                DragHandler {
                    id: singleDragHandler
                    target: null
                    acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Stylus
                    minimumPointCount: 1
                    maximumPointCount: 1
                    property real previousX: 0
                    property real previousY: 0
                    onActiveChanged: {
                        previousX = 0
                        previousY = 0
                        if (active) {
                            pad.isDragging = true
                        } else {
                            dragResetTimer.restart()
                        }
                    }
                    onTranslationChanged: {
                        pad.isDragging = true
                        root.pendingX += Math.round((translation.x - previousX) * 1.6)
                        root.pendingY += Math.round((translation.y - previousY) * 1.6)
                        previousX = translation.x
                        previousY = translation.y
                    }
                }

                // Two finger touch drag: Vertical wheel scroll
                // Two finger touch tap: Right click
                DragHandler {
                    id: twoFingerScrollHandler
                    target: null
                    acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Stylus
                    minimumPointCount: 2
                    maximumPointCount: 2
                    property real totalDy: 0
                    property real totalDx: 0
                    property real previousY: 0
                    onActiveChanged: {
                        if (active) {
                            previousY = 0
                            totalDy = 0
                            totalDx = 0
                            pad.isDragging = true
                        } else {
                            if (Math.abs(totalDy) < 10 && Math.abs(totalDx) < 10) {
                                root.click("0xC1")
                            }
                            dragResetTimer.restart()
                        }
                    }
                    onTranslationChanged: {
                        pad.isDragging = true
                        let dy = translation.y - previousY
                        totalDy += Math.abs(dy)
                        totalDx += Math.abs(translation.x)
                        root.pendingWheel += Math.round(dy / 10)
                        previousY = translation.y
                    }
                }

                // Single finger touch tap: Left click
                TapHandler {
                    id: padTapHandler
                    acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Stylus
                    gesturePolicy: TapHandler.DragThreshold
                    onTapped: {
                        if (!pad.isDragging) {
                            root.click("0xC0")
                        }
                    }
                }

                // Mouse / Trackpoint interaction
                MouseArea {
                    id: padMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.ArrowCursor
                    property real totalDistance: 0
                    property real previousX: 0
                    property real previousY: 0

                    onPressed: function(mouse) {
                        totalDistance = 0
                        previousX = mouse.x
                        previousY = mouse.y
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        let dx = mouse.x - previousX
                        let dy = mouse.y - previousY
                        totalDistance += Math.hypot(dx, dy)
                        root.pendingX += Math.round(dx * 1.6)
                        root.pendingY += Math.round(dy * 1.6)
                        previousX = mouse.x
                        previousY = mouse.y
                    }

                    onClicked: function(mouse) {
                        if (totalDistance < 8) {
                            root.click(mouse.button === Qt.RightButton ? "0xC1" : "0xC0")
                        }
                    }

                    onWheel: function(wheel) {
                        let delta = wheel.angleDelta.y / 120
                        if (delta !== 0) {
                            root.pendingWheel += Math.round(delta)
                        }
                    }
                }
            }

            Row {
                id: buttonRow
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: Style.spacing.md
                }
                spacing: Style.spacing.sm
                height: Style.space(56)

                Repeater {
                    model: [
                        { label: "Left click", code: "0xC0" },
                        { label: "Right click", code: "0xC1" },
                        { label: "Close", code: "" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: Math.floor((buttonRow.width - buttonRow.spacing * 2) / 3)
                        height: buttonRow.height
                        radius: Style.cornerRadius
                        color: (buttonArea.pressed || buttonTapHandler.pressed)
                            ? Color.accent
                            : Util.alpha(Color.foreground, Style.normalFillAlpha)

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: (buttonArea.pressed || buttonTapHandler.pressed) ? Color.background : Color.foreground
                            font.family: Style.font.family
                            font.pixelSize: Style.font.body
                        }

                        TapHandler {
                            id: buttonTapHandler
                            onTapped: parent.modelData.code ? root.click(parent.modelData.code) : root.close()
                        }

                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.code ? root.click(parent.modelData.code) : root.close()
                        }
                    }
                }
            }
        }
    }
}
