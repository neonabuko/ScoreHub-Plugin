import FileIO 3.0
import MuseScore 3.0
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1

MuseScore {
    property string postresponse: ""
    property string baseDir: Qt.resolvedUrl(".").toString().replace("file://", "")
    property string homeDir: ""
    property string api_url: "http://100.102.72.128:5000"
    property string scoreName: ""
    property string scorePath
    property string jsonFilePath: ""

    function createDto(scoreName, author, scoreContent) {
        return {
            "name": scoreName,
            "title": scoreName,
            "author": author,
            "content": scoreContent.toString()
        }
    }

    function postDto(dto) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200)
                    postresponse = "Success"
                else
                    postresponse = "Error: " + xhr.status
            }
        }
        xhr.open("POST", api_url + "/scores/json")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify(dto))
    }

    function saveScoreNameToJson(scoreName) {
        var jsonContent = JSON.stringify({
            "lastScoreName": scoreName
        })
        jsonFilePath = baseDir + "last_score_name.json"
        jsonFile.write(jsonContent)
    }

    function getLastScoreName() {
        jsonFilePath = baseDir + "last_score_name.json"
        var jsonContent = jsonFile.read()
        if (jsonContent) {
            var jsonData = JSON.parse(jsonContent)
            if (jsonData && jsonData.lastScoreName) { 
                return jsonData.lastScoreName
            }
        }
        
        return null
    }

    onRun: {
        scoreName = getLastScoreName()
        homeDir = mei.homePath()
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
            scorePath = String(fileDialog.fileUrl)
            var segments = scorePath.split("/")
            scoreName = segments[segments.length - 1]
            saveScoreNameToJson(scoreName)
            fileDialog.visible = false
        }
        onRejected: {
            fileDialog.visible = false
        }
        visible: false
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: 10
        GroupBox {
            Layout.fillWidth: true
            ColumnLayout {
                Button {
                    text: "Select File"
                    onClicked: {
                        fileDialog.visible = true
                    }
                }
                
                Button {
                    text: "Commit"
                    onClicked: {
                        if (scoreName === "") {
                            postresponse = "No file selected"
                            return
                        }
                        var path = scorePath.replace("file://", "")
                        mei.source = path
                        var scoreContent = mei.read()
                        if (scoreContent === "") {
                            postresponse = "No content"
                            return 
                        }
                        var dto = createDto(scoreName, "Author", scoreContent)
                        postDto(dto)
                    }
                }

                GroupBox {
                    title: "POST response:"
                    TextField {
                        text: postresponse
                        readOnly: true
                        width: 400
                    }                    
                }

                GroupBox {
                    title: "File selected:"
                    TextField {
                        text: scoreName
                        readOnly: true
                        width: 400
                    }
                }             

            }

        }

    }

}
