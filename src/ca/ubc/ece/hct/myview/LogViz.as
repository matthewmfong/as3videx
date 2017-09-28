////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.ui.UIScrollView;

import collections.HashMap;

import com.greensock.loading.LoaderMax;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.FileFilter;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import mx.formatters.DateFormatter;

public class LogViz extends MovieClip {
    private var userData:HashMap;
    private var videoData:HashMap;
    private var userVideoData:HashMap;
    private var logs:Array;
    private var loader:LoaderMax;
    private var user:String;

    public var uiscrollercontainer:Sprite;
    public var uiscroller:UIScrollView;

    private var userRecords:Array;

    public function LogViz():void {

        addEventListener(Event.ADDED_TO_STAGE, addedToStage);
    }

    public function addedToStage(e:Event):void {

        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        stage.nativeWindow.width = 1920;
        stage.nativeWindow.height = 1000;
        stage.nativeWindow.x = 0;
        stage.nativeWindow.y = 0;
        stage.stageWidth = stage.nativeWindow.width;
        stage.stageHeight = stage.nativeWindow.height;

        uiscroller = new UIScrollView(stage.stageWidth, stage.stageHeight);
        addChild(uiscroller);

        browseVideo(null);

    }

    private var file:File;
    private var fileString:String;
    public function browseVideo(e:MouseEvent):void {
        file = new File();
        var videoFilter:FileFilter = new FileFilter("json", "*.json");
        file.browseForOpen("Browse for json", [videoFilter]);
        file.addEventListener(Event.SELECT, fileSelected);
    }

    public function fileSelected(e:Event):void {
        trace("Open " + file.nativePath);
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.READ);
        fileString = fileStream.readUTFBytes(fileStream.bytesAvailable);
        fileStream.close();
        fileStream = null;

        jsonLoaded();
    }


    public function destroy():void {
        userData = null;
        videoData = null;
        loader = null;
        user = null;

        while(this.numChildren > 0) {
            removeChildAt(0);
        }
    }

    public function jsonLoaded():void {
        var data:Object = JSON.parse(fileString);
        userData = new HashMap();
        videoData = new HashMap();
        userVideoData = new HashMap();
        logs = [];

        for(var o:Object in data) {
            var log:Log = new Log();
            for(var p:Object in data[o]) {
                switch(p) {
                    case "user":
                        log.user = data[o][p];
                        break;
                    case "state":
                        var stateData:Object = JSON.parse(data[o][p]);
                        var videoPlayerState:VideoPlayerState = new VideoPlayerState();
                        for(var q:Object in stateData) {
                            switch(q) {
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
                        break;
                    case "event":
                        var eventData:Object = JSON.parse(data[o][p]);
                        var videoPlayerEvent:VideoPlayerEvent = new VideoPlayerEvent();
                        for(var q:Object in eventData) {
                            switch(q) {
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
                                case "to":
                                    videoPlayerEvent.to = Number(eventData[q]);
                                    break;
                                case "selection":
                                    videoPlayerEvent.selection = Range.fromString(eventData[q]);
                                    break;
                                case "interval":
                                    videoPlayerEvent.interval = Range.fromString(eventData[q]);
                                    break;
                                case "colour":
                                    videoPlayerEvent.colour = Number("0x" + (String)(eventData[q]).substring(1, eventData[q].length));
                                    break;
                                default:
                                    break;
                            }
                        }
                        log.event = videoPlayerEvent;
                        break;
                    case "date_time":
                        log.date = DateFormatter.parseDateString(data[o][p]);
                        break;
                    default:
                        break;
                }
            }
            if(!userData.containsKey(log.user)) {
                userData.put(log.user, [ log ]);
            } else {
                userData.grab(log.user).push(log);
            }

            if(!userVideoData.containsKey(log.user)) {

                var newHM:HashMap = new HashMap();
                newHM.put(log.state.videoFilename, [ log ]);
                userVideoData.put(log.user, newHM);

            } else if(!userVideoData.grab(log.user).containsKey(log.state.videoFilename)) {

                userVideoData.grab(log.user).put(log.state.videoFilename, [ log ]);

            } else {

                userVideoData.grab(log.user).grab(log.state.videoFilename).push(log);

            }

            if(!videoData.containsKey(log.state.videoFilename)) {
                videoData.put(log.state.videoFilename, [ log ]);
            } else {
                videoData.grab(log.state.videoFilename).push(log);
            }

            if(log.user.indexOf("matt") < 0 && log.user.indexOf("INSTRUCTOR") < 0)
                logs.push(log);
        }

        main();
    }

    public var _loadVideo:Number = 0;
    public var _play:Number = 0;
    public var _stop:Number = 0;
    public var _seek:Number = 0;
    public var _select:Number = 0;
    public var _deselect:Number = 0;
    public var _highlight:Number = 0;

    public function main():void {

        trace("Done Loading");

        var traceSprite:Sprite = new Sprite();

        var videoLoadTime:Date;
        var i:int = 0;
        var y:int = 0;
        var playhead:Number;

        var tickLength:Number = 2;
//        var actionLength:Number = 5;
        var tickGap:Number = 20;// + actionLength;

        var timeScale:Number = 1;///3;

        var lastTime:Date = new Date(2000, 0, 0, 0, 0, 0);
        var lastTimePlayAction:Date = new Date(2000, 0, 0, 0, 0, 0);
        var lastAction:String = "";
        var lastPlayStop:String = "";
        var lastSelection:Range;


        traceSprite.graphics.lineStyle(1);
        traceSprite.graphics.moveTo(0, y);

        var users:Array = userVideoData.keys();


        trace("user, " +
                "numSeeks, " +
                "numSeekForward, " +
                "numSeekBackward, " +
                "totalDistanceSeekForward, " +
                "averageDistanceSeekForward, " +
                "totalDistanceSeekBackward, " +
                "averageDistanceSeekBackward, " +
                "averageTimeSpentPlayingBeforeSeek, " +
                "averageTimeSpentPlayingBeforeStop");

        for each(var user:String in users) {

            if (user.indexOf("matt") == -1 && user.indexOf("demo_course") == -1 && user.indexOf("INSTRUCTOR") == -1) {

                var numStops:Number = 0;
                var numSeeks:Number = 0;
                var numSeekForward:Number = 0;
                var numSeekBackward:Number = 0;
                var totalDistanceSeekForward:Number = 0;
                var totalDistanceSeekBackward:Number = 0;
                var timeSpentPlayingUntilStop:Number = 0;
                var timeSpentPlayingUntilSeek:Number = 0;

                var usertf:TextField = new TextField();
                usertf.autoSize = TextFieldAutoSize.LEFT;
                usertf.text = user;
                usertf.y = y;
                usertf.mouseEnabled = false;
                traceSprite.addChild(usertf);

                y += usertf.height;

                var userHM:HashMap = (HashMap)(userVideoData.grab(user));
                var videos:Array = userHM.keys();


                for each(var video:String in videos) {

                    var videotf:TextField = new TextField();
                    videotf.autoSize = TextFieldAutoSize.LEFT;
                    videotf.text = video;
                    videotf.y = y;
                    videotf.mouseEnabled = false;
                    traceSprite.addChild(videotf);

                    var lastPlayTime:Date;

                    y += videotf.height;

                    var logs1:Array = userHM.grab(video);

                    i = 0;

                    for each(var log:Log in logs1) {
                        //            trace(i + log.user);
                        if (lastAction != "seek") {
                            playhead = log.state.playback_time;
                        }

                        if(lastPlayStop == "play" && log.event.action == "seek") {
                            timeSpentPlayingUntilSeek += log.date.time - lastPlayTime.time;
                        }

                        if(lastPlayStop == "play" && log.event.action == "stop") {
                            timeSpentPlayingUntilStop += log.date.time - lastPlayTime.time;
                        }

                        var skip:Boolean = false;
                        switch (log.event.action) {
                            case "loadVideo":
                                _loadVideo++;
                                videoLoadTime = log.date;
                                i += 3;
                                var tf:TextField = new TextField();
                                tf.text = log.user;
                                tf.y = y;
                                tf.width = 500;
//                            traceSprite.addChild(tf);
                                traceSprite.graphics.moveTo(i * tickGap, y);
                                traceSprite.graphics.lineStyle(2, 0x00ff00);
                                lastPlayStop = "play";
                                lastPlayTime = log.date;
                                break;
                            case "play":
                                _play++;
                                traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y);
                                traceSprite.graphics.lineStyle(2, 0x00ff00);
                                lastPlayStop = "play";
                                lastPlayTime = log.date;
                                break;
                            case "stop":
                                _stop++;
                                traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y);
                                traceSprite.graphics.lineStyle(2, 0xff0000);
                                lastPlayStop = "stop";
                                numStops++;
                                break;
                            case "seek":
                                _seek++;
                                var seekFrom:Number = playhead;
                                var seekTo:Number = log.event.to;
                                traceSprite.graphics.lineTo(i * tickGap, seekFrom * timeScale + y);
                                traceSprite.graphics.lineStyle(2, 0x0000ff);
                                traceSprite.graphics.lineTo(i * tickGap, seekTo * timeScale + y);
                                playhead = seekTo;
                                numSeeks++;
                                if(seekTo > seekFrom) {
                                    numSeekForward++;
                                    totalDistanceSeekForward += (seekTo - seekFrom);
                                } else {
                                    numSeekBackward++;
                                    totalDistanceSeekBackward += (seekFrom - seekTo);
                                }

//                            traceSprite.graphics.lineStyle(2, 0x00ff00);
                                switch (lastPlayStop) {
                                    case "play":
                                        traceSprite.graphics.lineStyle(2, 0x00ff00);
                                        break;
                                    case "stop":
                                        traceSprite.graphics.lineStyle(2, 0xff0000);
                                        break;
                                }
                                break;
                            case "select":
                                if (log.event.selection.length > 0.5) {
                                    _select++;
                                    traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y);
                                    traceSprite.graphics.lineStyle(0, 0, 0);
                                    traceSprite.graphics.beginFill(0xcccccc, 0.5);
                                    traceSprite.graphics.drawRect(
                                            i * tickGap - tickGap / 2,
                                            log.event.selection.start * timeScale + y,
                                            tickGap / 2,
                                            log.event.selection.end * timeScale - log.event.selection.start * timeScale);
                                    traceSprite.graphics.endFill();
                                    switch (lastPlayStop) {
                                        case "play":
                                            traceSprite.graphics.lineStyle(2, 0x00ff00);
                                            break;
                                        case "stop":
                                            traceSprite.graphics.lineStyle(2, 0xff0000);
                                            break;
                                    }
                                    traceSprite.graphics.moveTo(i * tickGap, playhead * timeScale + y);
                                    lastSelection = log.event.selection;
                                } else {
                                    skip = true;
                                }
                                break;
                            case "deselect":
                                if (lastSelection) {
                                    _deselect++;
                                    traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y);
                                    traceSprite.graphics.lineStyle(0, 0, 0);
                                    traceSprite.graphics.beginFill(0, 0.5);
                                    traceSprite.graphics.drawRect(
                                            i * tickGap - tickGap / 2,
                                            lastSelection.start * timeScale + y,
                                            tickGap / 2,
                                            lastSelection.end * timeScale - lastSelection.start * timeScale);
                                    traceSprite.graphics.endFill();
                                    switch (lastPlayStop) {
                                        case "play":
                                            traceSprite.graphics.lineStyle(2, 0x00ff00);
                                            break;
                                        case "stop":
                                            traceSprite.graphics.lineStyle(2, 0xff0000);
                                            break;
                                    }
                                    traceSprite.graphics.moveTo(i * tickGap, playhead * timeScale + y);
                                    lastSelection = null;
                                } else {
                                    skip = true;
                                }
                                break;
                            case "highlight":
                                if (log.event.interval.length > 0.5) {
                                    _highlight++;
                                    traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y);
                                    traceSprite.graphics.lineStyle(0, 0, 0);
                                    traceSprite.graphics.beginFill(log.event.colour, 1);
                                    traceSprite.graphics.drawRect(
                                            i * tickGap - tickGap / 2,
                                            log.event.interval.start * timeScale + y,
                                            tickGap / 2,
                                            log.event.interval.end * timeScale - log.event.interval.start * timeScale);
                                    traceSprite.graphics.endFill();
                                    switch (lastPlayStop) {
                                        case "play":
                                            traceSprite.graphics.lineStyle(2, 0x00ff00);
                                            break;
                                        case "stop":
                                            traceSprite.graphics.lineStyle(2, 0xff0000);
                                            break;
                                    }
                                    traceSprite.graphics.moveTo(i * tickGap, playhead * timeScale + y);
                                } else {
                                    skip = true;
                                }
                                break;
                            default:
//                            traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y);
//                            traceSprite.graphics.lineStyle(1);
//
//                            trace(log.event.action);
                                skip = true;
                                break;
                        }

                        if (!skip) {
                            traceSprite.graphics.moveTo(i * tickGap, playhead * timeScale + y);
                            traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y - tickLength);
                            traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y + tickLength);
                            traceSprite.graphics.moveTo(i * tickGap, playhead * timeScale + y);

                            i++;

                            lastTime = log.date;
                            lastAction = log.event.action;
                        }

                    }

                    traceSprite.graphics.lineStyle(2, 0xcccccc);
                    traceSprite.graphics.moveTo(0, traceSprite.height + 10);
                    traceSprite.graphics.lineTo(stage.stageWidth, traceSprite.height + 10);

                    y = traceSprite.height + 10;

                }

                traceSprite.graphics.lineStyle(5);
                traceSprite.graphics.moveTo(0, traceSprite.height + 10);
                traceSprite.graphics.lineTo(stage.stageWidth, traceSprite.height + 10);

                y = traceSprite.height + 10;


//                if(numSeeks > 0) {
                    timeSpentPlayingUntilStop /= 1000;
                    timeSpentPlayingUntilSeek /= 1000;
                    trace(user.substring(user.lastIndexOf("_") + 1) + ", " +
                            numSeeks + ", " +
                            numSeekForward + ", " +
                            numSeekBackward + ", " +
                            Math.round(totalDistanceSeekForward * 10) / 10 + ", " +
                            Math.round(totalDistanceSeekForward / numSeekForward * 10) / 10 + ", " +
                            Math.round(totalDistanceSeekBackward * 10) / 10 + ", " +
                            Math.round(totalDistanceSeekBackward / numSeekBackward * 10) / 10 + ", " +
                            Math.round(timeSpentPlayingUntilSeek / numSeeks * 10) / 10 + ", " +
                            Math.round(timeSpentPlayingUntilStop / numStops * 10) / 10);
//                }
//                trace("user: " + user);
//                trace("numSeeks: " + numSeeks);
//                trace("numSeekForward: " + numSeekForward);
//                trace("numSeekBackward: " + numSeekBackward);
//                trace("totalDistanceSeekForward: " + totalDistanceSeekForward);
//                trace("averageDistanceSeekForward: " + Math.round(totalDistanceSeekForward/numSeekForward * 10)/10);
//                trace("totalDistanceSeekBackward: " + totalDistanceSeekBackward);
//                trace("averageDistanceSeekBackward: " + Math.round(totalDistanceSeekBackward/numSeekBackward * 10)/10);

            }
        }

//        traceSprite.graphics.lineStyle(1);
//        traceSprite.graphics.moveTo(0, y);
//        for each(var log:Log in logs) {
////            trace(i + log.user);
//            playhead = log.state.playback_time;
//
////            if(log.date.valueOf() - lastTime.valueOf() > 1000) {
//                switch (log.event.action) {
//                    case "loadVideo":
//                        videoLoadTime = log.date;
//                        y += 50
//                        i = 0;
//                        var tf:TextField = new TextField();
//                        tf.text = log.user;
//                        tf.y = y;
//                        tf.width = 500;
//                        traceSprite.addChild(tf);
//                        traceSprite.graphics.moveTo(0, y);
//                        break;
//                    case "play":
//                        traceSprite.graphics.lineStyle(1, Colours.GREEN);
//                        break;
//                    case "stop":
//                        traceSprite.graphics.lineStyle(1, Colours.RED);
//                        break;
//                    case "seek":
//                        traceSprite.graphics.lineStyle(1, Colours.BLUE);
//                        break;
//                    default:
//                        traceSprite.graphics.lineStyle(1);
//                        break;
//                }
//
//                traceSprite.graphics.lineTo(i * tickGap, playhead * timeScale + y);
//                traceSprite.graphics.lineTo(i * tickGap + actionLength/2, playhead * timeScale + y);
//
//                traceSprite.graphics.lineTo(i * tickGap + actionLength/2, playhead * timeScale + y - tickLength);
//                traceSprite.graphics.lineTo(i * tickGap + actionLength/2, playhead * timeScale + y + tickLength);
//                traceSprite.graphics.moveTo(i * tickGap + actionLength/2, playhead * timeScale + y);
//
//                traceSprite.graphics.lineTo(i * tickGap + actionLength, playhead * timeScale + y);
//
//
//                i++;
////            }
//
//            lastTime = log.date;
//
//        }

        uiscroller.source = traceSprite;
        uiscroller.update();

        trace("Done drawing.");

        trace("number of users: " + userData.keys().length);
        trace("number of videos: " + videoData.keys().length);

        trace("_loadVideo = " + _loadVideo);
        trace("_play = " + _play);
        trace("_stop = " + _stop);
        trace("_seek = " + _seek);
        trace("_select = " + _select);
        trace("_deselect = " + _deselect);
        trace("_highlight = " + _highlight);


//        public var _loadVideo:Number = 0;
//        public var _play:Number = 0;
//        public var _stop:Number = 0;
//        public var _seek:Number = 0;
//        public var _select:Number = 0;
//        public var _deselect:Number = 0;
//        public var _highlight:Number = 0;
    }

}
}

import ca.ubc.ece.hct.Range;

import flash.display.Sprite;

class Log {
    public var user:String;
    public var event:VideoPlayerEvent;
    public var state:VideoPlayerState;
    public var date:Date;
}

class VideoPlayerState {
    public var videoID:int;
    public var videoFilename:String;
    public var play_state:Boolean;
    public var playback_time:Number;
    public var playback_rate:Number;
    public var selection:Range;
    public var active_highlight_colour:Number;
    public var highlight_write_mode:String;
    public var highlight_read_mode:int;
    public var view_count_read_mode:int;
    public var pause_record_read_mode:int;
    public var playback_rate_read_mode:int;
}

class VideoPlayerEvent {
    public var source:String;
    public var action:String;
    public var time:Number;
    public var from:Number;
    public var to:Number;
    public var selection:Range;
    public var interval:Range;
    public var colour:uint;
}

class TraceActionSprite extends Sprite {
    public var logIndex:uint;
    public var log:Log;
}