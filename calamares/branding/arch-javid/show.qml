/* Calamares slideshow shown while the system installs */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#292F34"
        }
        Column {
            anchors.centerIn: parent
            spacing: 16
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Welcome to arch-javid"
                font.pixelSize: 28
                font.bold: true
                color: "#FFFFFF"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "A clean Arch Linux system with KDE Plasma on Wayland"
                font.pixelSize: 16
                color: "#CCCCCC"
            }
        }
    }

    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#292F34"
        }
        Column {
            anchors.centerIn: parent
            spacing: 16
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "KDE Plasma on Wayland"
                font.pixelSize: 28
                font.bold: true
                color: "#FFFFFF"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Enjoy a modern, smooth Wayland desktop experience"
                font.pixelSize: 16
                color: "#CCCCCC"
            }
        }
    }

    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#292F34"
        }
        Column {
            anchors.centerIn: parent
            spacing: 16
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Almost there..."
                font.pixelSize: 28
                font.bold: true
                color: "#FFFFFF"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Your system will be ready shortly"
                font.pixelSize: 16
                color: "#CCCCCC"
            }
        }
    }
}
