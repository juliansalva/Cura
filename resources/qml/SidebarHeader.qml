// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

import "Menus"

Column
{
    id: base;

    property int currentExtruderIndex: Cura.ExtruderManager.activeExtruderIndex;
    property bool currentExtruderVisible: extrudersList.visible;

    spacing: Math.round(UM.Theme.getSize("sidebar_margin").width * 0.9)

    signal showTooltip(Item item, point location, string text)
    signal hideTooltip()

    Item
    {
        anchors
        {
            left: parent.left
            right: parent.right
        }
        visible: extruderSelectionRow.visible
        height: UM.Theme.getSize("default_lining").height
        width: height
    }

    // Extruder Row
    Item
    {
        id: extruderSelectionRow
        width: parent.width
        height: Math.round(UM.Theme.getSize("sidebar_tabs").height * 2 / 3)
        visible: machineExtruderCount.properties.value > 1 && !sidebar.monitoringPrint

        anchors
        {
            left: parent.left
            leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width * 0.7)
            right: parent.right
            rightMargin: Math.round(UM.Theme.getSize("sidebar_margin").width * 0.7)
            topMargin: UM.Theme.getSize("sidebar_margin").height
        }

        ListView
        {
            id: extrudersList
            property var index: 0

            height: UM.Theme.getSize("sidebar_header_mode_tabs").height
            width: Math.round(parent.width)
            boundsBehavior: Flickable.StopAtBounds

            anchors
            {
                left: parent.left
                leftMargin: Math.round(UM.Theme.getSize("default_margin").width / 2)
                right: parent.right
                rightMargin: Math.round(UM.Theme.getSize("default_margin").width / 2)
                verticalCenter: parent.verticalCenter
            }

            ExclusiveGroup { id: extruderMenuGroup; }

            orientation: ListView.Horizontal

            model: Cura.ExtrudersModel { id: extrudersModel; }

            Connections
            {
                target: Cura.MachineManager
                onGlobalContainerChanged: forceActiveFocus() // Changing focus applies the currently-being-typed values so it can change the displayed setting values.
            }

            delegate: Button
            {
                height: ListView.view.height
                width: Math.round(ListView.view.width / extrudersModel.rowCount())

                text: model.name
                tooltip: model.name
                exclusiveGroup: extruderMenuGroup
                checked: base.currentExtruderIndex == index

                MouseArea
                {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        switch (mouse.button) {
                            case Qt.LeftButton:
                                forceActiveFocus(); // Changing focus applies the currently-being-typed values so it can change the displayed setting values.
                                Cura.ExtruderManager.setActiveExtruderIndex(index);
                                break;
                            case Qt.RightButton:
                                extruderMenu.popup();
                                break;
                        }

                    }
                }

                Menu
                {
                    id: extruderMenu

                    MenuItem {
                        text: catalog.i18nc("@action:inmenu", "Enable Extruder")
                        onTriggered: Cura.MachineManager.setExtruderEnabled(model.index, true)
                        visible: !Cura.MachineManager.getExtruder(model.index).isEnabled
                    }

                    MenuItem {
                        text: catalog.i18nc("@action:inmenu", "Disable Extruder")
                        onTriggered: Cura.MachineManager.setExtruderEnabled(model.index, false)
                        visible: Cura.MachineManager.getExtruder(model.index).isEnabled
                    }
                }

                style: ButtonStyle
                {
                    background: Item
                    {
                        Rectangle
                        {
                            anchors.fill: parent
                            border.width: control.checked ? UM.Theme.getSize("default_lining").width * 2 : UM.Theme.getSize("default_lining").width
                            border.color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_border") :
                                          control.hovered ? UM.Theme.getColor("action_button_hovered_border") :
                                          UM.Theme.getColor("action_button_border")
                            color: (control.checked || control.pressed) ? UM.Theme.getColor("action_button_active") :
                                   control.hovered ? UM.Theme.getColor("action_button_hovered") :
                                   UM.Theme.getColor("action_button")
                            Behavior on color { ColorAnimation { duration: 50; } }
                        }

                        function buttonColor(index) {
                            var extruder = Cura.MachineManager.getExtruder(index);
                            if (extruder.isEnabled) {
                                return (
                                    control.checked || control.pressed) ? UM.Theme.getColor("action_button_active_text") :
                                    control.hovered ? UM.Theme.getColor("action_button_hovered_text") :
                                    UM.Theme.getColor("action_button_text");
                            } else {
                                return UM.Theme.getColor("action_button_disabled_text");
                            }
                        }

                        Item
                        {
                            id: extruderButtonFace
                            anchors.centerIn: parent
                            width: {
                                var extruderTextWidth = extruderStaticText.visible ? extruderStaticText.width : 0;
                                var iconWidth = extruderIconItem.width;
                                return Math.round(extruderTextWidth + iconWidth + UM.Theme.getSize("default_margin").width / 2);
                            }

                            // Static text "Extruder"
                            Label
                            {
                                id: extruderStaticText
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left

                                color: buttonColor(index)

                                font: UM.Theme.getFont("large_nonbold")
                                text: catalog.i18nc("@label", "Extruder")
                                visible: width < (control.width - extruderIconItem.width - UM.Theme.getSize("default_margin").width)
                                elide: Text.ElideRight
                            }

                            // Everthing for the extruder icon
                            Item
                            {
                                id: extruderIconItem
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right

                                property var sizeToUse:
                                {
                                    var minimumWidth = control.width < UM.Theme.getSize("button").width ? control.width : UM.Theme.getSize("button").width;
                                    var minimumHeight = control.height < UM.Theme.getSize("button").height ? control.height : UM.Theme.getSize("button").height;
                                    var minimumSize = minimumWidth < minimumHeight ? minimumWidth : minimumHeight;
                                    minimumSize -= Math.round(UM.Theme.getSize("default_margin").width / 2);
                                    return minimumSize;
                                }

                                width: sizeToUse
                                height: sizeToUse

                                UM.RecolorImage {
                                    id: mainCircle
                                    anchors.fill: parent

                                    sourceSize.width: parent.width
                                    sourceSize.height: parent.width
                                    source: UM.Theme.getIcon("extruder_button")

                                    color: extruderNumberText.color
                                }

                                Label
                                {
                                    id: extruderNumberText
                                    anchors.centerIn: parent
                                    text: index + 1;
                                    color: buttonColor(index)
                                    font: UM.Theme.getFont("default_bold")
                                }

                                // Material colour circle
                                // Only draw the filling colour of the material inside the SVG border.
                                Rectangle
                                {
                                    id: materialColorCircle

                                    anchors
                                    {
                                        right: parent.right
                                        top: parent.top
                                        rightMargin: Math.round(parent.sizeToUse * 0.01)
                                        topMargin: Math.round(parent.sizeToUse * 0.05)
                                    }

                                    color: model.color

                                    width: Math.round(parent.width * 0.35)
                                    height: Math.round(parent.height * 0.35)
                                    radius: Math.round(width / 2)

                                    border.width: 1
                                    border.color: UM.Theme.getColor("extruder_button_material_border")

                                    opacity: !control.checked ? 0.6 : 1.0
                                }
                            }
                        }
                    }
                    label: Item {}
                }
            }
        }
    }

    Item
    {
        id: variantRowSpacer
        height: Math.round(UM.Theme.getSize("sidebar_margin").height / 4)
        width: height
        visible: !extruderSelectionRow.visible
    }

    // Material Row
    Item
    {
        id: materialRow
        height: UM.Theme.getSize("sidebar_setup").height
        visible: Cura.MachineManager.hasMaterials && !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            id: materialLabel
            text: catalog.i18nc("@label", "Material");
            width: Math.round(parent.width * 0.45 - UM.Theme.getSize("default_margin").width)
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
        }

        ToolButton
        {
            id: materialSelection

            property var currentRootMaterialName:
            {
                var materials = Cura.MachineManager.currentRootMaterialName;
                var materialName = "";
                if (base.currentExtruderIndex in materials) {
                    materialName = materials[base.currentExtruderIndex];
                }
                return materialName;
            }

            text: currentRootMaterialName
            tooltip: currentRootMaterialName
            visible: Cura.MachineManager.hasMaterials
            enabled: !extrudersList.visible || base.currentExtruderIndex > -1
            height: UM.Theme.getSize("setting_control").height
            width: Math.round(parent.width * 0.7) + UM.Theme.getSize("sidebar_margin").width
            anchors.right: parent.right
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true;
            menu: MaterialMenu {
                extruderIndex: base.currentExtruderIndex
            }

            property var valueError: !isMaterialSupported()
            property var valueWarning: ! Cura.MachineManager.isActiveQualitySupported

            function isMaterialSupported () {
                return Cura.ContainerManager.getContainerMetaDataEntry(Cura.MachineManager.activeMaterialId, "compatible") == "True"
            }
        }
    }

    //Variant row
    Item
    {
        id: variantRow
        height: UM.Theme.getSize("sidebar_setup").height
        visible: Cura.MachineManager.hasVariants && !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            id: variantLabel
            text: Cura.MachineManager.activeDefinitionVariantsName;
            width: Math.round(parent.width * 0.45 - UM.Theme.getSize("default_margin").width)
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
        }

        ToolButton {
            id: variantSelection
            text: Cura.MachineManager.activeVariantName
            tooltip: Cura.MachineManager.activeVariantName;
            visible: Cura.MachineManager.hasVariants

            height: UM.Theme.getSize("setting_control").height
            width: Math.round(parent.width * 0.7 + UM.Theme.getSize("sidebar_margin").width)
            anchors.right: parent.right
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true;

            menu: NozzleMenu { extruderIndex: base.currentExtruderIndex }
        }
    }

    //Buildplate row separator
    Rectangle {
        id: separator

        anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width
        anchors.rightMargin: UM.Theme.getSize("sidebar_margin").width
        anchors.horizontalCenter: parent.horizontalCenter
        visible: buildplateRow.visible
        width: parent.width - UM.Theme.getSize("sidebar_margin").width * 2
        height: visible ? Math.floor(UM.Theme.getSize("sidebar_lining_thin").height / 2) : 0
        color: UM.Theme.getColor("sidebar_lining_thin")
    }

    //Buildplate row
    Item
    {
        id: buildplateRow
        height: UM.Theme.getSize("sidebar_setup").height
        visible: Cura.MachineManager.hasVariantBuildplates && !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Label
        {
            id: bulidplateLabel
            text: catalog.i18nc("@label", "Build plate");
            width: Math.floor(parent.width * 0.45 - UM.Theme.getSize("default_margin").width)
            font: UM.Theme.getFont("default");
            color: UM.Theme.getColor("text");
        }

        ToolButton {
            id: buildplateSelection
            text: Cura.MachineManager.activeVariantBuildplateName
            tooltip: Cura.MachineManager.activeVariantBuildplateName
            visible: Cura.MachineManager.hasVariantBuildplates

            height: UM.Theme.getSize("setting_control").height
            width: Math.floor(parent.width * 0.7 + UM.Theme.getSize("sidebar_margin").width)
            anchors.right: parent.right
            style: UM.Theme.styles.sidebar_header_button
            activeFocusOnPress: true;

            menu: BuildplateMenu {}

            property var valueError: !Cura.MachineManager.variantBuildplateCompatible && !Cura.MachineManager.variantBuildplateUsable
            property var valueWarning: Cura.MachineManager.variantBuildplateUsable
        }
    }

    // Material info row
    Item
    {
        id: materialInfoRow
        height: Math.round(UM.Theme.getSize("sidebar_setup").height / 2)
        visible: (Cura.MachineManager.hasVariants || Cura.MachineManager.hasMaterials) && !sidebar.monitoringPrint && !sidebar.hideSettings

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }

        Item {
            height: UM.Theme.getSize("sidebar_setup").height
            anchors.right: parent.right
            width: Math.round(parent.width * 0.7 + UM.Theme.getSize("sidebar_margin").width)

            UM.RecolorImage {
                id: warningImage
                anchors.right: materialInfoLabel.left
                anchors.rightMargin: UM.Theme.getSize("default_margin").width
                anchors.verticalCenter: parent.Bottom
                source: UM.Theme.getIcon("warning")
                width: UM.Theme.getSize("section_icon").width
                height: UM.Theme.getSize("section_icon").height
                color: UM.Theme.getColor("material_compatibility_warning")
                visible: !Cura.MachineManager.isCurrentSetupSupported
            }

            Label {
                id: materialInfoLabel
                wrapMode: Text.WordWrap
                text: "<a href='%1'>" + catalog.i18nc("@label", "Check compatibility") + "</a>"
                font: UM.Theme.getFont("default")
                color: UM.Theme.getColor("text")
                linkColor: UM.Theme.getColor("text_link")
                verticalAlignment: Text.AlignTop
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // open the material URL with web browser
                        var version = UM.Application.version;
                        var machineName = Cura.MachineManager.activeMachine.definition.id;
                        var url = "https://ultimaker.com/materialcompatibility/" + version + "/" + machineName + "?utm_source=cura&utm_medium=software&utm_campaign=resources";
                        Qt.openUrlExternally(url);
                    }
                    onEntered: {
                        var content = catalog.i18nc("@tooltip", "Click to check the material compatibility on Ultimaker.com.");
                        base.showTooltip(
                            materialInfoRow,
                            Qt.point(-UM.Theme.getSize("sidebar_margin").width, 0),
                            catalog.i18nc("@tooltip", content)
                        );
                    }
                    onExited: base.hideTooltip();
                }
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.I18nCatalog { id: catalog; name:"cura" }
}
