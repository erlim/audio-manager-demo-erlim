/* SPDXLicenseID: MPL-2.0
*
* Copyright (C) 2014, GENIVI Alliance
*
* This file is part of AudioManager Monitor
*
* This Source Code Form is subject to the terms of the Mozilla Public
* License (MPL), v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
*/

import QtQuick 2.1
import QtQuick.Window 2.0
import com.windriver.ammonitor 1.0
import "code.js" as Code

Item {
    id: mainBox

    PAClient {
        id: paClient
        signal sinkInputProcessed(int processType, int index)
        signal sinkInfoProcessed(int processType, int index)

        onSinkInputChanged : {

            if (sinkinput.role && sinkinput.role != "event" && sinkinput.role != "filter") {
                console.log('onSinkInputChanged '+sinkinput.index+' Volume'+sinkinput.volume);
                Code.savePASinkInput(sinkinput);
                architectureDiagram.requestPaint();
                pulseaudioChart.updateData(sinkinput.role, sinkinput.index, sinkinput.volume);

                console.log('----');
                for (var prop in sinkinput)
                    console.log("Object item:", prop, "=", sinkinput[prop])
                console.log('----');
                sinkInputProcessed(0, sinkinput.index);
            }
        }
        onSinkInputRemoved : {
            console.log('onSinkInputRemoved '+index);
            var sinkinput = Code.takePASinkInput(index);

            if (sinkinput && sinkinput.role != "event") {
                console.log('----');
                for (var prop in sinkinput)
                    console.log("Object item:", prop, "=", sinkinput[prop])
                console.log('----');

                pulseaudioChart.removeData(sinkinput.role, sinkinput.index);
            }
            sinkInputProcessed(1, index);
	    architectureDiagram.requestPaint();

        }

        onSinkInfoChanged: {
            console.log("onSinkInfoChanged " + sinkinfo.index + " Volume " + sinkinfo.volume);
            Code.savePASinkInfo(sinkinfo);
            architectureDiagram.requestPaint();

            audiomanagerChart.updateData(sinkinfo.name, sinkinfo.index, sinkinfo.volume);
            sinkInfoProcessed(0, sinkinfo.index);
        }

        onSinkInfoRemoved: {
            console.log("onSinkInfoRemoved " + index);
            var sinkinfo = Code.takePASinkInfo(index);
            audiomanagerChart.removeData(sinkinfo.name, sinkinfo.index);
	    architectureDiagram.requestPaint();

        }

        onClientChanged: {
            console.log("onClientChanged " + client.index + " name " + client.name);
            Code.savePAClient(client);
	    architectureDiagram.requestPaint();
        }

        onClientRemoved: {
            console.log("onClientRemoved " + index);
            var client = Code.takePAClient(index);
	    architectureDiagram.requestPaint();

        }
    }

    AMClient {
        id: amClient
        property bool initialized: false
        onSinkAdded: {
	    // skip default AM Sinks
	    if(sink.name.substr(0, 2) == "my")
		return;
	    if(!initialized) {
		Code.amSinks[Code.amSinks.length] = sink
		console.log("SINK ADDED : " + sink.id + " / " + sink.name);
	    }
        }

        onSinkRemoved: {

        }

        onVolumeChanged: {
            console.log("**********************************");
            console.log("QML : VOLUME CHANGED : SINKID = " + sinkid + " / VOLUME = " + volume);
            console.log("**********************************");
        }

        onSourceAdded: {
	    // skip default AM Sources
	    if(source.name.substr(0, 2) == "my")
		return;
	    if(!initialized) {
		Code.amSources[Code.amSources.length] = source
		console.log("SOURCE ADDED : " + source.id + " / " + source.name);
	    }
        }

        onSourceRemoved: {

        }

        onConnectionAdded: {
            console.log("**********************************");
            console.log("QML : CONNECTION : " + connection.id+ " "+initialized);
            console.log("**********************************");
	    if(!initialized) {
		// remove previous connection
		amClient.disconnect(connection.id);
		return;
	    }
            Code.saveAMConnection(connection);
        }

        onConnectionRemoved: {
            console.log("**********************************");
            console.log("QML : CONNECTION REMOVED : " + index);
            console.log("**********************************");
	    var conn = Code.takeAMConnection(index);
        }

	onInitAMMonitorCompleted: {
	    console.log("onInitDBusCallCompleted");
	    amClient.initialized = true;
	}

    }


    Rectangle {
        id: buttonPanel
        color: "transparent"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: parent.height / 30
        width: parent.width 
        height: parent.height
        property int buttonWidth : width * 9 / 10
        property int buttonHeight : height / 7

        ListView {
            id: buttonsView

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.fill: parent
            orientation: ListView.Vertical

            model: VisualItemModel {
		Text {
		    text: "Naver Music"
		    font.pixelSize: parent.height / 30
		    anchors.horizontalCenter: parent.horizontalCenter
		}
                Button {
                    width: buttonPanel.buttonWidth
                    height: buttonPanel.buttonHeight

                    iconName: "music"
                    title: "Twice"

                    amCommandIF: amClient
                    amSource: "MediaPlayer"
                    amSink: "AlsaPrimary"
                    mediaRole: "MEDIA"
                    audioFilePath: "https://www.youtube.com/watch?v=9uypQGzzhns"
                }
	    }
        }
    }

    Rectangle {
        id: amVolumeChartPanel
        anchors.left: buttonPanel.right
        anchors.top: parent.top
        width: parent.width * 2 / 6
        height: parent.height / 2

        /*
        Text {
            text: "50"
            font.pixelSize: parent.height / 20
            anchors.right: audiomanagerChart.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 5
        }
        */
        Graph {
            id: audiomanagerChart
            graphName : "AudiomanagerChart"
            title: "Sinks of GENIVI® Audio Manager"
            description: "AM's Sink volume changes by Control Plugin"
            anchors.fill: parent
            defaultValue : 0
            maxDataLength: 100
            width: parent.width
            height: parent.height
            type: Code.GraphType.CONTINUOUS_LINE
        }
    }

    Rectangle {
        id: pulseaudioVolumeChartPanel
        anchors.left: buttonPanel.right
        anchors.top: amVolumeChartPanel.bottom
        width: parent.width * 2 / 6
        height: parent.height / 2

        Graph {
            id: pulseaudioChart
            title: "Sink Inputs of PulseAudio"
            description: "PA's Sink Input volume changes"
            anchors.fill: parent
            graphName : "PulseAudioChart"
            defaultValue : 0
            maxDataLength: 100
            width: parent.width
            height: parent.height
            type: Code.GraphType.TRANSIENT_LINE
        }
    }
}
