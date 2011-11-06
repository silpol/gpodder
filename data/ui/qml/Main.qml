
import Qt 4.7
import com.nokia.meego 1.0

import 'config.js' as Config

Image {
    id: main
    focus: true

    function _(x) {
        return controller.translate(x)
    }

    function n_(x, y, z) {
        return controller.ntranslate(x, y, z)
    }

    property alias podcastModel: podcastList.model
    property alias episodeModel: episodeList.model
    property alias currentEpisode: mediaPlayer.episode

    property bool playing: mediaPlayer.playing
    property bool canGoBack: (closeButton.isRequired || mediaPlayer.visible) && !progressIndicator.opacity && !myGpoSheetVisible
    property bool hasPlayButton: nowPlayingThrobber.shouldAppear && !progressIndicator.opacity && !myGpoSheetVisible
    property bool hasSearchButton: searchButton.visible && !mediaPlayer.visible && !progressIndicator.opacity && !myGpoSheetVisible
    property bool myGpoSheetVisible: false

    function openMyGpo() {
        myGpoEnableSwitch.checked = controller.myGpoEnabled
        myGpoUsernameField.text = controller.myGpoUsername
        myGpoPasswordField.text = controller.myGpoPassword
        myGpoDeviceCaptionField.text = controller.myGpoDeviceCaption
        myGpoSheet.open()
        myGpoSheetVisible = true
    }

    function goBack() {
        if (nowPlayingThrobber.opened) {
            nowPlayingThrobber.opened = false
        } else {
            closeButton.clicked()
        }
    }

    function clickPlayButton() {
        nowPlayingThrobber.clicked()
    }

    function clickSearchButton() {
        searchButton.clicked()
    }

    Keys.onPressed: {
        console.log(event.key)
        if (event.key == Qt.Key_Escape) {
            goBack()
        }
        if (event.key == Qt.Key_F && event.modifiers & Qt.ControlModifier) {
            searchButton.clicked()
        }
    }

    width: 800
    height: 480
    source: 'artwork/background-harmattan.png'

    state: 'podcasts'

    function togglePlayback(episode) {
        if (episode.qfiletype == 'video') {
            controller.playVideo(episode)
        } else {
            controller.currentEpisodeChanging()
            mediaPlayer.togglePlayback(episode)
        }
    }

    function openShowNotes(episode) {
        showNotes.episode = episode
        main.state = 'shownotes'
    }

    function openContextMenu(items) {
        hrmtnContextMenu.items = items
        hrmtnContextMenu.open()
    }

    function startProgress(text) {
        progressIndicator.text = text
        progressIndicator.opacity = 1
    }

    function endProgress() {
        progressIndicator.opacity = 0
    }

    states: [
        State {
            name: 'podcasts'
            PropertyChanges {
                target: podcastList
                opacity: 1
            }
            PropertyChanges {
                target: episodeList
                anchors.leftMargin: 100
                opacity: 0
            }
            PropertyChanges {
                target: showNotes
                opacity: 0
            }
            StateChangeScript {
                script: episodeList.resetSelection()
            }
        },
        State {
            name: 'episodes'
            PropertyChanges {
                target: episodeList
                opacity: 1
            }
            PropertyChanges {
                target: podcastList
                opacity: 0
                anchors.leftMargin: -100
            }
            PropertyChanges {
                target: showNotes
                opacity: 0
                anchors.leftMargin: main.width
            }
        },
        State {
            name: 'shownotes'
            PropertyChanges {
                target: listContainer
                opacity: 0
            }
            PropertyChanges {
                target: showNotes
                opacity: 1
                anchors.leftMargin: 0
            }
        }
    ]

    Item {
        id: listContainer
        anchors.fill: parent

        PodcastList {
            id: podcastList
            opacity: 0

            anchors.fill: parent

            onPodcastSelected: controller.podcastSelected(podcast)
            onPodcastContextMenu: controller.podcastContextMenu(podcast)

            Behavior on opacity { NumberAnimation { duration: Config.slowTransition } }
            Behavior on anchors.leftMargin { NumberAnimation { duration: Config.slowTransition } }
        }

        EpisodeList {
            id: episodeList

            opacity: 0

            anchors.fill: parent

            onEpisodeContextMenu: controller.episodeContextMenu(episode)

            Behavior on opacity { NumberAnimation { duration: Config.slowTransition } }
            Behavior on anchors.leftMargin { NumberAnimation { duration: Config.slowTransition } }
        }

        Behavior on opacity { NumberAnimation { duration: Config.slowTransition } }
        Behavior on scale { NumberAnimation { duration: Config.fadeTransition } }
    }

    ShowNotes {
        id: showNotes

        anchors {
            left: parent.left
            top: titleBar.bottom
            bottom: parent.bottom
        }
        width: parent.width

        Behavior on opacity { NumberAnimation { duration: Config.slowTransition } }
        Behavior on anchors.leftMargin { NumberAnimation { duration: Config.slowTransition } }
    }

    Item {
        id: overlayInteractionBlockWall
        anchors.fill: parent
        anchors.topMargin: (nowPlayingThrobber.opened || messageDialog.opacity > 0 || inputDialog.opacity > 0 || progressIndicator.opacity > 0)?0:titleBar.height
        z: (contextMenu.state != 'opened')?2:0

        opacity: (nowPlayingThrobber.opened || contextMenu.state == 'opened' || messageDialog.opacity || inputDialog.opacity || progressIndicator.opacity)?1:0
        Behavior on opacity { NumberAnimation { duration: Config.slowTransition } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (contextMenu.state == 'opened') {
                    // do nothing
                } else if (progressIndicator.opacity) {
                    // do nothing
                } else if (inputDialog.opacity) {
                    inputDialog.close()
                } else if (messageDialog.opacity) {
                    messageDialog.opacity = 0
                } else {
                    nowPlayingThrobber.opened = false
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: 'black'
            opacity: .7
        }

        Image {
            anchors.fill: parent
            source: 'artwork/mask.png'
        }
    }

    CornerButton {
        id: extraCloseButton
        visible: false
        z: (contextMenu.state == 'opened')?2:0
        tab: 'artwork/back-tab.png'
        icon: 'artwork/back.png'
        isLeftCorner: true
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        onClicked: closeButton.clicked()
        opened: !(!Config.hasCloseButton && closeButton.isRequired)
    }

    CornerButton {
        z: 3

        property bool shouldAppear: ((contextMenu.state != 'opened') && (mediaPlayer.episode !== undefined))

        id: nowPlayingThrobber
        visible: false
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        opacity: shouldAppear

        caption: (mediaPlayer.episode!=undefined)?mediaPlayer.episode.qtitle:''

        opened: false
        onClicked: { opened = !opened }
    }

    MediaPlayer {
        id: mediaPlayer
        visible: nowPlayingThrobber.opened

        z: 3

        anchors.top: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: nowPlayingThrobber.opened?-(height+(parent.height-height)/2):0

        Behavior on anchors.topMargin { PropertyAnimation { duration: Config.quickTransition; easing.type: Easing.OutCirc } }
    }

    ContextMenu {
        id: hrmtnContextMenu
        property variant items: []

        MenuLayout {
            Repeater {
                model: hrmtnContextMenu.items

                MenuItem {
                    text: modelData.caption
                    onClicked: {
                        hrmtnContextMenu.close()
                        controller.contextMenuResponse(index)
                    }
                }
            }
        }
    }

    ContextMenuArea {
        id: contextMenu

        width: parent.width
        opacity: 0

        anchors {
            top: parent.top
            bottom: parent.bottom
        }

        onClose: contextMenu.state = 'closed'
        onResponse: controller.contextMenuResponse(index)

        state: 'closed'

        Behavior on opacity { NumberAnimation { duration: Config.fadeTransition } }

        states: [
            State {
                name: 'opened'
                PropertyChanges {
                    target: contextMenu
                    opacity: 1
                }
                AnchorChanges {
                    target: contextMenu
                    anchors.right: main.right
                }
            },
            State {
                name: 'closed'
                PropertyChanges {
                    target: contextMenu
                    opacity: 0
                }
                AnchorChanges {
                    target: contextMenu
                    anchors.right: main.left
                }
                StateChangeScript {
                    script: controller.contextMenuClosed()
                }
            }
        ]

        transitions: Transition {
            AnchorAnimation { duration: Config.slowTransition }
        }
    }

    Item {
        id: titleBar
        height: taskSwitcher.height*.8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        //anchors.topMargin: mediaPlayer.fullscreen?-height:0
        //opacity: mediaPlayer.fullscreen?0:1

        Behavior on opacity { PropertyAnimation { } }
        Behavior on anchors.topMargin { PropertyAnimation { } }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: .9

            MouseArea {
                // clicks should not fall through!
                anchors.fill: parent
            }
        }

        Item {
            id: taskSwitcher
            visible: contextMenu.state != 'opened' && Config.hasTaskSwitcher
            anchors.left: parent.left
            anchors.top: parent.top
            width: Config.switcherWidth
            height: Config.headerHeight

            MouseArea {
                anchors.fill: parent
                onClicked: controller.switcher()
            }

            ScaledIcon {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: (parent.width * .8 - width) / 2
                }
                source: 'artwork/switch.png'
            }
        }

        Label {
            id: titleBarText
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: taskSwitcher.visible?taskSwitcher.right:taskSwitcher.left
            anchors.leftMargin: (contextMenu.state == 'opened')?(Config.largeSpacing):(Config.hasTaskSwitcher?0:Config.largeSpacing)
            anchors.right: searchButton.visible?searchButton.left:searchButton.right
            wrapMode: Text.NoWrap
            clip: true
            text: (contextMenu.state == 'opened')?(contextMenu.subscribeMode?_('Add a new podcast'):_('Context menu')):((main.state == 'episodes' || main.state == 'shownotes')?controller.episodeListTitle:"gPodder")
            color: 'white'
            font.pixelSize: parent.height * .5
            font.bold: false
        }

        Binding {
            target: controller
            property: 'windowTitle'
            value: titleBarText.text
        }

        TitlebarButton {
            id: searchButton
            anchors.right: closeButton.visible?closeButton.left:closeButton.right

            source: 'artwork/subscriptions.png'

            onClicked: contextMenu.showSubscribe()

            visible: (contextMenu.state == 'closed' && main.state == 'podcasts')
            opacity: 0
        }

        TitlebarButton {
            id: closeButton
            anchors.right: parent.right
            property bool isRequired: main.state != 'podcasts' || contextMenu.state != 'closed'
            visible: extraCloseButton.opened && (Config.hasCloseButton || isRequired)

            source: (main.state == 'podcasts' && contextMenu.state == 'closed')?'artwork/close.png':'artwork/back.png'
            rotation: 0

            onClicked: {
                if (contextMenu.state == 'opened') {
                    contextMenu.state = 'closed'
                } else if (main.state == 'podcasts') {
                    mediaPlayer.stop()
                    controller.quit()
                } else if (main.state == 'episodes') {
                    main.state = 'podcasts'
                } else if (main.state == 'shownotes') {
                    main.state = 'episodes'
                }
            }
        }
    }

    function showMessage(message) {
        messageDialogText.text = message
        messageDialog.opacity = 1
    }

    Item {
        id: messageDialog
        anchors.fill: parent
        opacity: 0
        z: 20

        Behavior on opacity { PropertyAnimation { } }

        Label {
            id: messageDialogText
            anchors.centerIn: parent
            color: 'white'
            font.pixelSize: 20
            font.bold: true
        }
    }

    function showInputDialog(message, value, accept, reject, textInput) {
        inputDialogText.text = message
        inputDialogField.text = value
        inputDialogAccept.text = accept
        inputDialogReject.text = reject
        inputDialogField.visible = textInput

        if (textInput) {
            inputSheet.open()
        } else {
            queryDialog.open()
        }
    }

    QueryDialog {
        id: queryDialog

        acceptButtonText: inputDialogAccept.text
        rejectButtonText: inputDialogReject.text

        message: inputDialogText.text

        onAccepted: inputDialog.accept()
        onRejected: inputDialog.close()
    }

    Sheet {
        id: inputSheet

        acceptButtonText: inputDialogAccept.text
        rejectButtonText: inputDialogReject.text

        content: Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: console.log('caught')
            }

            Column {
                anchors.fill: parent
                anchors.margins: Config.smallSpacing
                spacing: Config.smallSpacing

                Item {
                    height: 1
                    width: parent.width
                }

                Label {
                    id: inputDialogText
                    anchors.margins: Config.smallSpacing
                    width: parent.width
                }

                Item {
                    height: 1
                    width: parent.width
                }

                InputField {
                    id: inputDialogField
                    width: parent.width
                    onAccepted: {
                        inputDialog.accept()
                        inputSheet.close()
                    }
                    actionName: inputDialogAccept.text
                }
            }
        }

        onAccepted: inputDialog.accept()
        onRejected: inputDialog.close()
    }

    Item {
        id: inputDialog
        anchors.fill: parent
        opacity: 0

        function accept() {
            opacity = 0
            scale = .5
            controller.inputDialogResponse(true, inputDialogField.text,
                                           inputDialogField.visible)
        }

        function close() {
            opacity = 0
            scale = .5
            controller.inputDialogResponse(false, inputDialogField.text,
                                           inputDialogField.visible)
        }

        SimpleButton {
            id: inputDialogReject
            width: parent.width / 2
            onClicked: inputDialog.close()
        }

        SimpleButton {
            id: inputDialogAccept
            width: parent.width / 2
            onClicked: inputDialog.accept()
        }
    }

    Column {
        id: progressIndicator
        property string text: '...'
        anchors.centerIn: parent
        opacity: 0
        spacing: Config.largeSpacing * 2
        z: 40

        Behavior on opacity { NumberAnimation { duration: Config.slowTransition } }

        Label {
            text: parent.text
            anchors.horizontalCenter: parent.horizontalCenter
        }

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: parent.opacity > 0
        }
    }

    Sheet {
        id: myGpoSheet

        acceptButtonText: _('Save')
        rejectButtonText: _('Cancel')
        visualParent: main

        content: Item {
            id: myGpoSheetContent
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: console.log('caught')
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: Config.largeSpacing
                contentWidth: myGpoSettingsColumn.width
                contentHeight: myGpoSettingsColumn.height

                Column {
                    id: myGpoSettingsColumn
                    width: myGpoSheetContent.width - Config.largeSpacing * 2
                    spacing: Config.smallSpacing

                    Item {
                        width: parent.width
                        height: myGpoEnableSwitch.height

                        Label {
                            id: enableText
                            anchors.left: parent.left
                            anchors.right: myGpoEnableSwitch.left
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            text: _('Enable gpodder.net syncing')
                        }
                        Switch {
                            id: myGpoEnableSwitch
                            anchors.right: parent.right
                        }
                    }

                    Item { height: Config.largeSpacing; width: 1 }

                    Label { text: _('Username') }
                    InputField { id: myGpoUsernameField; anchors.left: parent.left; anchors.right: parent.right }

                    Item { height: 1; width: 1 }

                    Label { text: _('Password') }
                    InputField { id: myGpoPasswordField; anchors.left: parent.left; anchors.right: parent.right; echoMode: TextInput.Password }

                    Item { height: 1; width: 1 }

                    Label { text: _('Device name') }
                    InputField { id: myGpoDeviceCaptionField; anchors.left: parent.left; anchors.right: parent.right }

                    Item { height: Config.largeSpacing; width: 1 }

                    Button {
                        text: _('Replace list on server')
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: {
                            myGpoSheet.accept()
                            controller.myGpoUploadList()
                        }
                    }

                    /*Button {
                        text: _('Download list from server')
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: controller.myGpoDownloadList()
                    }*/

                    Item { height: Config.largeSpacing; width: 1 }

                    Button {
                        text: _('No account? Register here')
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: Qt.openUrlExternally('http://gpodder.net/register/')
                    }
                }
            }

        }

        onAccepted: {
            controller.myGpoUsername = myGpoUsernameField.text
            controller.myGpoPassword = myGpoPasswordField.text
            controller.myGpoDeviceCaption = myGpoDeviceCaptionField.text
            controller.myGpoEnabled = myGpoEnableSwitch.checked && (controller.myGpoUsername != '' && controller.myGpoPassword != '')
            controller.saveMyGpoSettings()
            main.myGpoSheetVisible = false
        }

        onRejected: {
            main.myGpoSheetVisible = false
        }
    }

}

