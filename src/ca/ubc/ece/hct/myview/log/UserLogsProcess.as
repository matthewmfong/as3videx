/**
 * Created by iDunno on 2018-02-04.
 */
package ca.ubc.ece.hct.myview {


import ca.ubc.ece.hct.myview.log.Log;
import ca.ubc.ece.hct.myview.log.UserLogCollection;
import ca.ubc.ece.hct.myview.log.VideoLogCollection;
import ca.ubc.ece.hct.myview.log.VideoPlayerEvent;
import ca.ubc.ece.hct.myview.log.VideoPlayerState;

import com.adobe.serialization.json.JSONParseError;
import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;

import flash.net.SharedObject;

import flash.utils.ByteArray;

import ca.ubc.ece.hct.myview.Constants;

import flash.utils.getTimer;

public class UserLogsProcess implements Runnable {

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    public var dispatcher:CrossThreadDispatcher;

    public var orgUserRecords:Array;
    public var orgUserRecordsBA:ByteArray;

    public var orgVideoRecords:Array;
    public var orgVideoRecordsBA:ByteArray;

    public var timerStart:Number;

    public function putUserRecord(user:String, log:Log):void {

        var userIndex:int = -1;
        for (var i:int = 0; i < orgUserRecords.length; i++) {
            if (orgUserRecords[i].username == user) {
                userIndex = i;
                break;
            }
        }
        if (userIndex < 0) {
            orgUserRecords.push(new UserLogCollection(user));
            userIndex = orgUserRecords.length - 1;
        }

        orgUserRecords[userIndex].addRecord(log);
    }

    public function putVideoRecord(videoID:Number, log:Log):void {

        var videoIndex:int = -1;
        for (var i:int = 0; i < orgVideoRecords.length; i++) {
            if (orgVideoRecords[i].videoID == videoID) {
                videoIndex = i;
                break;
            }
        }
        if (videoIndex < 0) {
            orgVideoRecords.push(new VideoLogCollection(videoID));
            videoIndex = orgVideoRecords.length - 1;
        }

        orgVideoRecords[videoIndex].addRecord(log);
    }

    public function process(obj:UserLogsProcessArguments):int {
        orgUserRecords = [];
        orgVideoRecords = [];

        var byteArray:ByteArray = obj.byteArray;

        timerStart = getTimer();
        var i:int = 0;

        var char:String = "";
        var line:String = "";
        var record:Array;
        var lineNumber:Number = 0;
        var dateString:String, year:Number, month:Number, day:Number, hour:Number, minute:Number, second:Number,
                date:Date;
        var stateData:Object, eventData:Object, videoPlayerState:VideoPlayerState, videoPlayerEvent:VideoPlayerEvent;
        while (byteArray.bytesAvailable > 0) {

            while (char != "\n") {
                char = byteArray.readUTFBytes(1);
                line += char;
            }

            // e.g.
            // BCIT_CHEM0011_1_spring_2018_oSWSdijholHiGYLtnVzNoJUA \t
            // {"videoID":209,"videoFilename":"Expt_5_Introduction_to_Separation_Techniques_II_-_report_writing-N_KRreSxUZo","play_state":"true","playback_time":316.761,"playback_rate":1,"selection":"[ 0, 0 ]","active_highlight_colour":"#0","highlight_write_mode":"PRE_SELECT","highlight_read_mode":2,"view_count_read_mode":2,"pause_record_read_mode":2,"playback_rate_read_mode":2,"fullscreen":false,"closed_captions":false,"left_dimensions":"(x=0, y=0, w=1, h=1)","right_dimensions":"(x=0, y=0, w=1, h=1)","top_dimensions":"(x=0, y=0, w=1, h=1)","bottom_dimensions":"(x=0, y=0, w=1, h=1)","centre_dimensions":"(x=0, y=0, w=1, h=1)","stage_dimensions":"(x=35, y=23, w=1245, h=777)"} \t
            // {"source":"[object StarlingVideoPlayerModel]"} \t
            // 2018-02-05 02:53:31
            record = line.split("\t");

            try {
                var log:Log = new Log();
                log.user = record[0];
                dateString = record[3];
                // YYYY-MM-DD hh:mm:ss
                // 0123456789012345678
                year = Number(dateString.substr(0, 4));
                month = Number(dateString.substr(5, 2));
                day = Number(dateString.substr(8, 2));
                hour = Number(dateString.substr(11, 2));
                minute = Number(dateString.substr(14, 2));
                second = Number(dateString.substr(17, 2));
                date = new Date(year, month - 1, day, hour, minute, second);
                date.setTime(date.getTime() + Constants.SERVER_TO_LOCAL_TIME_DIFF * Constants.HOURS2MILLISECONDS);
                log.date = date;

                stateData = JSON.parse(record[1]);
                videoPlayerState = new VideoPlayerState();
                for (var q:Object in stateData) {
                    switch (q) {
                        case "videoID":
                            videoPlayerState.videoID = stateData[q];
                            break;
                        case "videoFilename":
                            videoPlayerState.videoFilename = stateData[q];
                            break;
                        case "playback_time":
                            videoPlayerState.playback_time = stateData[q];
                            break;
                        case "play_state":
                            videoPlayerState.play_state = (stateData[q] == "true");
                            break;
                        default:
                            break;
                    }
                }
                log.state = videoPlayerState;

                eventData = JSON.parse(record[2]);
                videoPlayerEvent = new VideoPlayerEvent();
                for (var q:Object in eventData) {
                    switch (q) {
                        case "source":
                            videoPlayerEvent.source = eventData[q];
                            break;
                        case "action":
                            videoPlayerEvent.action = eventData[q];
                            break;
                        case "time":
                            videoPlayerEvent.time = Number(eventData[q]);
                            break;
                        case "from":
                            videoPlayerEvent.from = Number(eventData[q]);
                            break;
                        case"to":
                            videoPlayerEvent.to = Number(eventData[q]);
                            break;
                        default:
                            break;
                    }
                }
                log.event = videoPlayerEvent;


//            trace("Time: " + (getTimer() - timerStart) / 1000 + " @ " + (i++) + " = " + (int)(i / ((getTimer() - timerStart) / 1000)) + "records/s");


                putUserRecord(log.user, log);
                if (log.state.videoID) {
                    putVideoRecord(log.state.videoID, log)
                }
            } catch (e:Error){} finally {} /* do nothing, it's not worth error checking so many logs.*/


            line = "";
            char = "";

            dispatcher.dispatchProgress(byteArray.position, byteArray.length);
        }

        // read from old files
        var oldUserRecords:ByteArray = new ByteArray();
        var oldVideoRecords:ByteArray = new ByteArray();

        var logs_so:SharedObject = SharedObject.getLocal("userLogs");

        var oldOrgUserRecordsArray:Array, oldVideoRecordsArray:Array;

        if(logs_so.size > 0) {
//            trace("Loader: Reading old files in array");
            Util.readFileIntoByteArray("user_logs", oldUserRecords);
            Util.readFileIntoByteArray("video_logs", oldVideoRecords);
            oldOrgUserRecordsArray = oldUserRecords.readObject() as Array;
            oldVideoRecordsArray = oldVideoRecords.readObject() as Array;
        } else {
//            trace("Loader: Old files don't exist");
            oldOrgUserRecordsArray = [];
            oldVideoRecordsArray = [];
        }

        orgUserRecords = oldOrgUserRecordsArray.concat(orgUserRecords);
        orgVideoRecords = oldVideoRecordsArray.concat(orgVideoRecords);

        logs_so.data.dataUpToDate = new Date();


        // write new records to files
        var records:ByteArray = new ByteArray();
        var records2:ByteArray = new ByteArray();
        records.writeObject(orgUserRecords);
        records2.writeObject(orgVideoRecords);

        Util.writeBytesToFile("user_logs", records);
        Util.writeBytesToFile("video_logs", records2);


        orgUserRecordsBA = new ByteArray();
        orgUserRecordsBA.shareable = true;
        orgUserRecordsBA.writeObject(orgUserRecords);
        orgUserRecordsBA.position = 0;
        dispatcher.setSharedProperty("orgUserRecordsBA", orgUserRecordsBA);


        orgVideoRecordsBA = new ByteArray();
        orgVideoRecordsBA.shareable = true;
        orgVideoRecordsBA.writeObject(orgVideoRecords);
        orgVideoRecordsBA.position = 0;
        dispatcher.setSharedProperty("orgVideoRecordsBA", orgVideoRecordsBA);

        return 1;

    }

    // Implements Runnable interface
    public function run(args:Array):void {
        var value:UserLogsProcessArguments = (UserLogsProcessArguments)(args[0]);
        dispatcher.dispatchResult(process(value));
    }

}
}