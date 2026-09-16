import QtQuick

QtObject {
    id: root

    property string openSection: ""

    function toggle(section: string) {
        root.openSection = root.openSection === section ? "" : section;
    }

    function close(section: string) {
        if (root.openSection === section)
            root.openSection = "";
    }

    function dismiss() {
        root.openSection = "";
    }
}
