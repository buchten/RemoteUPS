// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_warningThreshold: warningThreshold.value
    property alias cfg_criticalThreshold: criticalThreshold.value

    QQC2.SpinBox {
        id: warningThreshold
        Kirigami.FormData.label: i18n("Warning level:")
        from: 1
        to: 100
        editable: true
        textFromValue: function(value) { return value + "%" }
        valueFromText: function(text) {
            return Math.max(from, Math.min(to, parseInt(text.replace("%", ""))))
        }
        onValueModified: {
            if (value <= criticalThreshold.value)
                criticalThreshold.value = Math.max(0, value - 1)
        }
    }

    QQC2.SpinBox {
        id: criticalThreshold
        Kirigami.FormData.label: i18n("Critical level:")
        from: 0
        to: 99
        editable: true
        textFromValue: function(value) { return value + "%" }
        valueFromText: function(text) {
            return Math.max(from, Math.min(to, parseInt(text.replace("%", ""))))
        }
        onValueModified: {
            if (value >= warningThreshold.value)
                warningThreshold.value = Math.min(100, value + 1)
        }
    }

    QQC2.Label {
        Kirigami.FormData.label: i18n("Colors:")
        text: i18n("Green above warning, orange at/below warning, red at/below critical")
        wrapMode: Text.Wrap
    }
}
