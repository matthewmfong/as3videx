////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////
package ca.ubc.ece.hct.myview.log {
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.log.UserLogDBManager;

import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;

import flash.events.Event;
import flash.events.ProgressEvent;
import flash.events.SQLEvent;

import flash.net.SharedObject;
import flash.utils.ByteArray;

import com.doublefx.as3.thread.util.ThreadRunnerX;

import flash.filesystem.File;

public class UserLogsProcess implements Runnable {

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */

    private var asdf:ThreadRunnerX;
    public var dispatcher:CrossThreadDispatcher;

    public var orgUserRecords:Array;
    public var orgUserRecordsBA:ByteArray;

    public var orgVideoRecords:Array;
    public var orgVideoRecordsBA:ByteArray;

    public var db:UserLogDBManager;

    private var byteArray:ByteArray;

//    public var timerStart:Number;

//    public function putUserRecord(user:String, log:Log):void {
//
//        var userIndex:int = -1;
//        for (var i:int = 0; i < orgUserRecords.length; i++) {
//            if (orgUserRecords[i].username == user) {
//                userIndex = i;
//                break;
//            }
//        }
//        if (userIndex < 0) {
//            orgUserRecords.push(new UserLogCollection(user));
//            userIndex = orgUserRecords.length - 1;
//        }
//
//        orgUserRecords[userIndex].addRecord(log);
//    }
//
//    public function putVideoRecord(videoID:Number, log:Log):void {
//
//        var videoIndex:int = -1;
//        for (var i:int = 0; i < orgVideoRecords.length; i++) {
//            if (orgVideoRecords[i].videoID == videoID) {
//                videoIndex = i;
//                break;
//            }
//        }
//        if (videoIndex < 0) {
//            orgVideoRecords.push(new VideoLogCollection(videoID));
//            videoIndex = orgVideoRecords.length - 1;
//        }
//
//        orgVideoRecords[videoIndex].addRecord(log);
//    }

    public function init(obj:UserLogsProcessArguments):void {

        orgUserRecords = [];
        orgVideoRecords = [];

        byteArray = obj.byteArray;
        db = new UserLogDBManager(obj.dbPath);
        db.addEventListener(SQLEvent.OPEN, dbOpen);
        db.openAsync();

    }


    public function dbOpen(e:SQLEvent):void {
        db.removeEventListener(SQLEvent.OPEN, dbOpen);
        db.addEventListener(SQLEvent.BEGIN, dbBegin);
        db.beginTransaction();
    }

    public function dbBegin(e:SQLEvent):void {
        db.conn.removeEventListener(SQLEvent.BEGIN, dbBegin);
        process();
    }

    public function process():void {

//        timerStart = getTimer();

        var character:String = "";
        var line:String = "";
        var record:Array;
        var dateString:String, year:Number, month:Number, day:Number, hour:Number, minute:Number, second:Number,
                date:Date;
        var stateData:Object, eventData:Object, videoPlayerState:VideoPlayerState, videoPlayerEvent:VideoPlayerEvent;

        var lineCount:Number = 0;
        while (byteArray.bytesAvailable > 0) {

            while (character != "\n") {
                character = byteArray.readUTFBytes(1);
                line += character;
            }

            // e.g.
            // BCIT_CHEM0011_1_spring_2018_oSWSdijholHiGYLtnVzNoJUA \t
            // {"videoID":209,"videoFilename":"Expt_5_Introduction_to_Separation_Techniques_II_-_report_writing-N_KRreSxUZo","play_state":"true","playback_time":316.761,"playback_rate":1,"selection":"[ 0, 0 ]","active_highlight_colour":"#0","highlight_write_mode":"PRE_SELECT","highlight_read_mode":2,"view_count_read_mode":2,"pause_record_read_mode":2,"playback_rate_read_mode":2,"fullscreen":false,"closed_captions":false,"left_dimensions":"(x=0, y=0, w=1, h=1)","right_dimensions":"(x=0, y=0, w=1, h=1)","top_dimensions":"(x=0, y=0, w=1, h=1)","bottom_dimensions":"(x=0, y=0, w=1, h=1)","centre_dimensions":"(x=0, y=0, w=1, h=1)","stage_dimensions":"(x=35, y=23, w=1245, h=777)"} \t
            // {"source":"[object StarlingVideoPlayerModel]"} \t
            // 2018-02-05 02:53:31
            record = line.split("\t");

            var log:Log = new Log();
            try {
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

                var q:Object;

                stateData = JSON.parse(record[1]);
                videoPlayerState = new VideoPlayerState();
                for (q in stateData) {
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
                for (q in eventData) {
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


//                if(log.state.videoID > 0) {
//                    putUserRecord(log.user, log);
//                    if (log.state.videoID) {
//                        putVideoRecord(log.state.videoID, log)
//                    }
//                }
                //            trace("3 not coercible? ");
//            trace(db);
//            trace(line);
//            trace(log.date + " " + log.date.getTime());
                db.addRecord(log.user, log.date.getTime(), log.state.videoID, log.state.videoFilename, log.state.play_state ? 1 : 0, log.state.playback_time,
                        log.state.playback_rate, log.state.selection_start, log.state.selection_end, log.state.active_highlight_colour,
                        log.state.highlight_write_mode, log.state.highlight_read_mode, log.state.view_count_read_mode,
                        log.state.pause_record_read_mode, log.state.playback_rate_read_mode,
                        log.event.source, log.event.action,
                        log.event.time, log.event.from,
                        log.event.to);

//            trace("4 not coercible? ");
            } catch (e:Error){} finally {} /* do nothing, it's not worth error checking so many logs.*/



            line = "";
            character = "";

//            trace(lineCount++ + "progress: " + byteArray.position + "/" + byteArray.length + "=" + byteArray.position/byteArray.length)

            dispatcher.dispatchProgress(byteArray.position/byteArray.length * 100, 200);
        }

        trace("I think we're all done.");

        db.addEventListener(SQLEvent.COMMIT, finish);
        db.addEventListener(ProgressEvent.PROGRESS, commitProgress);
        db.commitTransaction();
    }

    private function commitProgress(e:ProgressEvent):void {
        dispatcher.dispatchProgress(e.bytesLoaded/e.bytesTotal*100 + 100, 200);
    }

    private function finish(e:SQLEvent):void {
        db.close();
        dispatcher.dispatchResult(1);
    }


    // Implements Runnable interface
    public function run(args:Array):void {
        var value:UserLogsProcessArguments = (UserLogsProcessArguments)(args[0]);

        init(value);

        trace("thread.run() - " + args.length + " " + value.dbPath)
//        dispatcher.dispatchResult(process(value));
    }

}
}