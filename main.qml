import FileIO 3.0
import MuseScore 3.0
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1

MuseScore {
    property string postresponse: ""
    property string baseDir: Qt.resolvedUrl(".").replace("file://", "")
    property string homeDir: ""
    property string api_url: "http://100.102.72.128:5000"
    property string app_url: "http://100.102.72.128:5173"
    property string scoreName: "No file selected"
    property string scorePath: ""
    property string jsonFilePath: ""

    function createDto(scoreName, author, scoreContent) {
        return {
            "name": scoreName,
            "title": scoreName,
            "author": author,
            "content": scoreContent.toString()
        };
    }

    function postDto(dto) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200)
                    postresponse = "Commit successful! View score "
                             + "<a href='" + app_url + "/score/" + scoreName 
                             + "'>"
                             + "here"
                             + "</a>";
                else
                    postresponse = "Error: " + xhr.status;
            }
        };
        xhr.open("POST", api_url + "/scores/json");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify(dto));
    }

    function saveScoreNameToJson(scoreName) {
        var jsonContent = JSON.stringify({
            "lastScore": {
                "name": scoreName,
                "url": scorePath
            }
        });
        jsonFilePath = baseDir + "last_score_name.json";
        jsonFile.write(jsonContent);
    }

    function getLastScoreData() {
        jsonFilePath = baseDir + "last_score_name.json";
        var jsonContent = jsonFile.read();
        if (jsonContent) {
            var jsonData = JSON.parse(jsonContent);
            if (jsonData && jsonData.lastScore)
                return jsonData.lastScore;

        }
        return null;
    }

    onRun: {
        var lastScore = getLastScoreData();
        if (lastScore !== null) {
            scoreName = lastScore.name;
            scorePath = lastScore.url;
        }
        homeDir = mei.homePath();
    }
    version: "1.0"
    description: "Plugin to commit scores to ScoreHub"
    title: "ScoreManager"
    requiresScore: false
    pluginType: "dialog"
    categoryCode: "manage"
    width: 560
    height: 380

    FileIO {
        id: mei

        source: ""
    }

    FileIO {
        id: jsonFile

        source: jsonFilePath
    }

    FileDialog {
        id: fileDialog

        title: "Select a File to Commit"
        folder: homeDir
        onAccepted: {
            scorePath = String(fileDialog.fileUrl).replace("file://", "");
            var segments = scorePath.split("/");
            scoreName = segments[segments.length - 1];
            saveScoreNameToJson(scoreName, scorePath);
            fileDialog.visible = false;
        }
        onRejected: {
            fileDialog.visible = false;
        }
        visible: false
    }

    Rectangle {
        anchors.fill: parent
        color: "#2c3e50"

        Item {
            anchors.margins: 10
            anchors.fill: parent

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20

                GroupBox {
                    title: "File selected:"

                    ColumnLayout {
                        Text {
                            text: scoreName
                            color: "white"
                        }

                    }

                }

                Text {
                    text: "Supported formats: .mei, .musicxml"
                    font.italic: true
                    font.pixelSize: 13
                    color: "white"
                }

                Row {
                    spacing: 10

                    Button {
                        text: "Select File"
                        onClicked: {
                            fileDialog.visible = true;
                        }
                    }

                    Button {
                        text: "Commit"
                        enabled: !!scoreName
                        onClicked: {
                            mei.source = scorePath;
                            var scoreContent = mei.read();
                            if (scoreContent === "") {
                                postresponse = "Score has no content";
                                return ;
                            }
                            var dto = createDto(scoreName, "Author", scoreContent);
                            postDto(dto);
                        }
                    }

                }

                GroupBox {
                    title: "Status:"

                    Text {
                        text: postresponse
                        textFormat: Text.RichText
                        onLinkActivated: {
                            Qt.openUrlExternally(link)
                        }
                        color: "white"
                    }

                }
            }

        }

    }

}
