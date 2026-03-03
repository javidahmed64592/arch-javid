/* SPDX-FileCopyrightText: no
 * SPDX-License-Identifier: CC0-1.0
 *
 * Minimal slideshow shown during installation.
 */

import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide()
    }

    Timer {
        id:       timer
        interval: 5000
        running:  false
        repeat:   true
        onTriggered: nextSlide()
    }

    Slide {
        anchors.fill: parent

        Text {
            anchors.centerIn: parent
            text: "Installing Arch Linux…"
            color: "#ffffff"
            font.pixelSize: 24
        }
    }

    function onActivate()   { timer.running = true  }
    function onLeave()      { timer.running = false }
}
