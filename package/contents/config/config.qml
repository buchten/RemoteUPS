// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Battery levels")
        icon: "battery"
        source: "configGeneral.qml"
    }
}
