// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property string upsStatus: "Loading…"
    property real batteryCharge: -1
    property string timeLeft: "—"
    property string lineVoltage: "—"
    property string loadPercent: "—"
    property string batteryVoltage: "—"
    property string lastUpdate: "—"
    property string errorText: ""
    property bool commandRunning: false

    readonly property string command: "/usr/bin/apcaccess status"
    readonly property int refreshIntervalMs: 15000
    readonly property bool hasData: batteryCharge >= 0
    readonly property bool onBattery: upsStatus.indexOf("ONBATT") >= 0
    readonly property bool communicationError: errorText.length > 0

    // Configuration is persisted by Plasma. Keep a valid ordering even if the
    // config file is edited manually: critical < warning.
    readonly property int warningThreshold: Math.max(1, Math.min(100, plasmoid.configuration.warningThreshold))
    readonly property int criticalThreshold: Math.max(0, Math.min(warningThreshold - 1, plasmoid.configuration.criticalThreshold))

    // Fixed semantic colors requested for the battery gauge.
    readonly property color normalColor: "#2ecc71"   // green
    readonly property color warningColor: "#f39c12"  // orange
    readonly property color criticalColor: "#e74c3c" // red

    Plasmoid.title: "Remote UPS Monitor"
    Plasmoid.icon: communicationError ? "dialog-error" : "battery"

    toolTipMainText: "Remote UPS"
    toolTipTextFormat: Text.PlainText
    toolTipSubText: {
        if (communicationError)
            return errorText
        if (!hasData)
            return upsStatus
        var text = Math.round(batteryCharge) + "% — " + upsStatus
        if (timeLeft !== "—")
            text += " — " + timeLeft + " left"
        return text
    }

    function batteryColor() {
        if (communicationError)
            return Kirigami.Theme.negativeTextColor
        if (!hasData)
            return Kirigami.Theme.disabledTextColor
        if (batteryCharge <= criticalThreshold)
            return criticalColor
        if (batteryCharge <= warningThreshold)
            return warningColor
        return normalColor
    }

    function valueOrDash(map, key) {
        return map[key] !== undefined && map[key] !== "" ? map[key] : "—"
    }

    function parseApcaccess(output) {
        var values = {}
        var lines = output.split(/\r?\n/)

        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i]
            var colon = line.indexOf(":")
            if (colon <= 0)
                continue

            var key = line.substring(0, colon).trim()
            var value = line.substring(colon + 1).trim()
            values[key] = value
        }

        var parsedCharge = parseFloat(values["BCHARGE"])
        if (isNaN(parsedCharge)) {
            errorText = "apcaccess returned no battery charge"
            upsStatus = valueOrDash(values, "STATUS")
            batteryCharge = -1
            return
        }

        batteryCharge = Math.max(0, Math.min(100, parsedCharge))
        upsStatus = valueOrDash(values, "STATUS")
        timeLeft = valueOrDash(values, "TIMELEFT")
        lineVoltage = valueOrDash(values, "LINEV")
        loadPercent = valueOrDash(values, "LOADPCT")
        batteryVoltage = valueOrDash(values, "BATTV")
        errorText = ""
        lastUpdate = Qt.formatDateTime(new Date(), "HH:mm:ss")
    }

    function refresh() {
        if (commandRunning)
            return
        commandRunning = true
        executable.connectSource(command)
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            disconnectSource(source)
            root.commandRunning = false

            var exitCode = data["exit code"]
            var stdout = data["stdout"] || ""
            var stderr = (data["stderr"] || "").trim()

            if (Number(exitCode) !== 0) {
                root.errorText = stderr.length > 0
                    ? "apcaccess failed: " + stderr
                    : "apcaccess failed (exit " + exitCode + ")"
                root.upsStatus = "Unavailable"
                return
            }

            root.parseApcaccess(stdout)
        }
    }

    Timer {
        interval: root.refreshIntervalMs
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    compactRepresentation: MouseArea {
        id: compact

        // A moderately wide compact representation so the percentage fits inside
        // the gauge without taking excessive horizontal panel space. Plasma may
        // still constrain this in unusually narrow or vertical panels.
        implicitWidth: Kirigami.Units.iconSizes.smallMedium * 1.85
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight

        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Item {
            anchors.fill: parent
            anchors.leftMargin: Math.max(1, parent.width * 0.04)
            anchors.rightMargin: Math.max(1, parent.width * 0.04)
            anchors.topMargin: Math.max(1, parent.height * 0.13)
            anchors.bottomMargin: Math.max(1, parent.height * 0.13)

            Rectangle {
                id: batteryBody
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.91
                radius: Math.max(2, height * 0.12)
                color: "transparent"
                border.width: Math.max(1, Math.round(height * 0.06))
                border.color: root.communicationError
                    ? Kirigami.Theme.negativeTextColor
                    : root.batteryColor()
                clip: true

                Rectangle {
                    id: batteryFill
                    anchors.left: parent.left
                    anchors.leftMargin: batteryBody.border.width + 2
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.max(1, parent.height - 2 * (batteryBody.border.width + 2))
                    width: root.hasData
                        ? Math.max(0, (parent.width - 2 * (batteryBody.border.width + 2)) * root.batteryCharge / 100)
                        : 0
                    radius: Math.max(1, batteryBody.radius * 0.55)
                    color: root.batteryColor()
                }

                Rectangle {
                    id: percentBacking
                    anchors.centerIn: parent
                    width: percentLabel.implicitWidth + Kirigami.Units.smallSpacing
                    height: Math.min(parent.height - 4, percentLabel.implicitHeight + 2)
                    radius: 2
                    color: Kirigami.Theme.backgroundColor
                    opacity: 0.78
                    visible: percentLabel.visible
                }

                PlasmaComponents.Label {
                    id: percentLabel
                    anchors.centerIn: parent
                    text: root.communicationError
                        ? "!"
                        : (root.hasData ? Math.round(root.batteryCharge) + "%" : "…")
                    font.pixelSize: Math.max(8, batteryBody.height * 0.45)
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    visible: root.communicationError || root.hasData
                }
            }

            Rectangle {
                anchors.left: batteryBody.right
                anchors.leftMargin: 1
                anchors.verticalCenter: batteryBody.verticalCenter
                width: Math.max(2, parent.width * 0.055)
                height: batteryBody.height * 0.42
                radius: Math.max(1, width * 0.25)
                color: root.communicationError
                    ? Kirigami.Theme.negativeTextColor
                    : root.batteryColor()
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: details.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: details
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: root.communicationError ? "UPS unavailable" : root.upsStatus
                    font.bold: true
                    Layout.fillWidth: true
                }

                PlasmaComponents.Button {
                    text: "Refresh"
                    icon.name: "view-refresh"
                    enabled: !root.commandRunning
                    onClicked: root.refresh()
                }
            }

            PlasmaComponents.Label {
                visible: root.communicationError
                text: root.errorText
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            GridLayout {
                visible: !root.communicationError
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing
                Layout.fillWidth: true

                PlasmaComponents.Label { text: "Battery" }
                PlasmaComponents.Label {
                    text: root.hasData ? Math.round(root.batteryCharge) + "%" : "—"
                    font.bold: true
                    color: root.hasData ? root.batteryColor() : Kirigami.Theme.textColor
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label { text: "Runtime" }
                PlasmaComponents.Label { text: root.timeLeft; Layout.fillWidth: true }

                PlasmaComponents.Label { text: "Load" }
                PlasmaComponents.Label { text: root.loadPercent; Layout.fillWidth: true }

                PlasmaComponents.Label { text: "Line voltage" }
                PlasmaComponents.Label { text: root.lineVoltage; Layout.fillWidth: true }

                PlasmaComponents.Label { text: "Battery voltage" }
                PlasmaComponents.Label { text: root.batteryVoltage; Layout.fillWidth: true }

                PlasmaComponents.Label { text: "Thresholds" }
                PlasmaComponents.Label {
                    text: "Warning " + root.warningThreshold + "% / Critical " + root.criticalThreshold + "%"
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label { text: "Updated" }
                PlasmaComponents.Label { text: root.lastUpdate; Layout.fillWidth: true }
            }

            PlasmaComponents.Label {
                text: "Source: /usr/bin/apcaccess status"
                opacity: 0.65
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                Layout.fillWidth: true
            }
        }
    }
}
