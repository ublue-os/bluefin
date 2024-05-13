/*
    SPDX-FileCopyrightText: 2014 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.5
import QtQuick.Window 2.2
import org.kde.plasma.core 2.0 as PlasmaCore

Rectangle {
    id: root
    color: "black"

    property int stage

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        } else if (stage == 5) {
            introAnimation.target = busyIndicator;
            introAnimation.from = 1;
            introAnimation.to = 0;
            introAnimation.running = true;
        }
    }

    width: 1280
    height: 800

    Component.onCompleted: stage = 2

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: logo
            //match SDDM/lockscreen avatar positioning
            property real size: PlasmaCore.Units.gridUnit * 24

            anchors.centerIn: parent

            source: "images/aurora_logo.svgz"

            sourceSize.width: 128
            sourceSize.height: 128
        }

        // TODO: port to PlasmaComponents3.BusyIndicator
        Image {
            id: busyIndicator
            //in the middle of the remaining space
            y: parent.height - (parent.height - logo.y) / 3 - height/2
            anchors.horizontalCenter: parent.horizontalCenter
            source: "images/busywidget.svgz"
            sourceSize.height: PlasmaCore.Units.gridUnit
            sourceSize.width: PlasmaCore.Units.gridUnit
            RotationAnimator on rotation {
                id: rotationAnimator
                from: 0
                to: 360
                // Not using a standard duration value because we don't want the
                // animation to spin faster or slower based on the user's animation
                // scaling preferences; it doesn't make sense in this context
                duration: 2000
                loops: Animation.Infinite
                // Don't want it to animate at all if the user has disabled animations
                running: PlasmaCore.Units.longDuration > 1
            }
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: PlasmaCore.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
