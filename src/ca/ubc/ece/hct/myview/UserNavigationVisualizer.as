////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.Constants;
import ca.ubc.ece.hct.myview.View;
import ca.ubc.ece.hct.myview.ui.FloatingTextField;
import ca.ubc.ece.hct.myview.ui.UIScrollView;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.filmstrip.SimpleFilmstrip;

import collections.HashMap;

import com.greensock.events.LoaderEvent;
import com.greensock.loading.DataLoader;
import com.greensock.loading.LoaderMax;

import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.getTimer;

import mx.controls.Text;

import mx.formatters.DateFormatter;

import fl.controls.CheckBox;

public class UserNavigationVisualizer extends View  {

    private var data:Object;
    private var userData:HashMap;
    private var videoData:HashMap;
    private var loader:LoaderMax;
    private var video:VideoMetadata;
    private var user:String;

    private var userRecords:Array;

    public function UserNavigationVisualizer(width:Number, height:Number):void {
        _width = width;
        _height = height;
    }

    private var newTime:Number;
    public function loadVideo(video:VideoMetadata, user:String = null, userRecords:Array = null, range:Range = null):void {
        destroy();
        this.video = video;
        this.user = user;
        this.userRecords = userRecords;
        loader = new LoaderMax({name: "WebLoaderQueue", auditSize: false});

        var url:String;
        if(user == null) {
            url = "http://" + Constants.DOMAIN + "/admin/userNavigationDataTest.php?media_alias_id=" + video.media_alias_id;
            trace(url);
            loader.append(new DataLoader(url, {onComplete: jsonLoaded}));
        } else {
            url = "http://" + Constants.DOMAIN + "/admin/getLogsByUserForMediaAliasID.php?username=" + user + "&media_alias_id=" + video.media_alias_id;
            trace(url);
            loader.append(new DataLoader(url, {onComplete: jsonLoaded}));
        }

        loader.load();
    }

    public function destroy():void {
        data = null;
        userData = null;
        videoData = null;
        loader = null;
        video = null;
        user = null;

        while(this.numChildren > 0) {
            removeChildAt(0);
        }
    }

    public function jsonLoaded(e:LoaderEvent):void {
        data = JSON.parse(e.target.content);
        userData = new HashMap();
        videoData = new HashMap();

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
                                    videoPlayerState.play_state = (stateData[q] == "true" ? true : false);
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
                                case"to":
                                    videoPlayerEvent.to = Number(eventData[q]);
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

            if(!videoData.containsKey(log.state.videoFilename)) {
                videoData.put(log.state.videoFilename, [ log ]);
            } else {
                videoData.grab(log.state.videoFilename).push(log);
            }
        }

        main();
    }


    public var userTraces:Array;
    public var userTraceCheckBoxes:Array;
    public var userTraceCheckboxesContainerWidth:Number = 300;
    public var checkboxContainer:Sprite;
    public var uiscrollercontainer:Sprite;
    public var uiscroller:UIScrollView;

    public function main():void {
//        var users:Array = userData.keys();
//        if(user != null) {
//            userTraceCheckboxesContainerWidth = 0;
//        }
//        var logsToDraw:Array = ["loadVideo", "play", "stop", "seek"];
//        var userTimeScale:Number = 1;//0.3;
//        var userTracesWidth:Number = _width - userTraceCheckboxesContainerWidth
//        var videoTimeScale:Number = (userTracesWidth)/video.duration;
//
//        var simpleFilmstrip:SimpleFilmstrip = new SimpleFilmstrip(userTracesWidth, 100);
//        simpleFilmstrip.loadVideo(video, new Range(0, video.duration));
//        addChild(simpleFilmstrip);
//        simpleFilmstrip.x = userTraceCheckboxesContainerWidth;
//
//        var actionTextField:TextField = new TextField();
//        actionTextField.defaultTextFormat = Constants.DEFAULT_TEXT_FORMAT;
//        actionTextField.width = _width - userTraceCheckboxesContainerWidth;
//        actionTextField.height = 20;
//        actionTextField.x = userTraceCheckboxesContainerWidth;
//        actionTextField.y = simpleFilmstrip.height + 10;
//        addChild(actionTextField);
//
//        userTraces = [];
//        if(user == null) {
//            userTraceCheckBoxes = [];
//            checkboxContainer = new Sprite();
//            addChild(checkboxContainer);
//        }
//        uiscrollercontainer = new Sprite();
//        uiscroller = new UIScrollView(_width - userTraceCheckboxesContainerWidth, _height - simpleFilmstrip.height- actionTextField.height);
//        uiscroller.source = uiscrollercontainer;
//        uiscroller.x = userTraceCheckboxesContainerWidth;
//        uiscroller.y = actionTextField.y + actionTextField.height + 10;
//        addChild(uiscroller);
//
//        drawTimeTicks();
//
//
//        for each(var userString:String in users) {
//            // BCIT_CHEM0011_1_spring_2017_MmysCbdUSDKvNQfmJtRILByY is a good one
//            var userLogs:Array = userData.grab(userString);
//            var userTrace:Sprite = new Sprite();
//            userTraces.push(userTrace);
//            if(user != null)
//                uiscrollercontainer.addChild(userTrace);
//
//            if(user == null) {
//                var userTraceCheckBox:CheckBox = new CheckBox();
//                userTraceCheckBoxes.push(userTraceCheckBox);
//                addChild(userTraceCheckBox);
//                userTraceCheckBox.width = _width;
//                userTraceCheckBox.label = userString.split("_")[userString.split("_").length - 1];
//                userTraceCheckBox.x = 10;
//                userTraceCheckBox.y = userTraceCheckBoxes.length * 20;
//                userTraceCheckBox.selected = false;
//                userTraceCheckBox.addEventListener(Event.CHANGE,
//                        function userTraceHiddenChange(e:Event):void {
//                            var targetTrace:Sprite = userTraces[userTraceCheckBoxes.indexOf(e.target)];
//                            targetTrace.alpha = e.target.selected ? 1 : 0;
//                            if (!e.target.selected && checkboxContainer.contains(targetTrace)) {
//                                uiscrollercontainer.removeChild(targetTrace);
//                            } else if (e.target.selected && !checkboxContainer.contains(targetTrace)) {
//                                uiscrollercontainer.addChild(targetTrace);
//                            }
//                            uiscroller.update();
//                        });
//            }
//
//            userTrace.graphics.lineStyle(1, 0xcccccc);
//            userTrace.graphics.moveTo(0, 0);
//            var firstLog:Log = null;
//            var idx:int = 0;
//            var lineEndPoint:Point = new Point(0, 0);
//
//            var forwardColour:uint = 0x00cc00;
//            var backwardColour:uint = 0x0000ff;
//            var regularColour:uint = 0;
//
//            for each(var log:Log in userLogs) {
//                if (firstLog == null) {
//                    firstLog = log;
//                }
//
//                if (logsToDraw.indexOf(log.event.action) > -1) {
//                    var userTime:Number = (log.date.time / 1000 - firstLog.date.time / 1000) * userTimeScale;
//                    var videoTime:Number = log.state.playback_time * videoTimeScale;
//
//                    var traceAction:TraceActionSprite = new TraceActionSprite();
//                    traceAction.log = log;
//                    traceAction.logIndex = idx;
//                    userTrace.addChild(traceAction);
//
//                    traceAction.graphics.moveTo(lineEndPoint.x, lineEndPoint.y);
//
//                    if (log.event.action == "seek") {
//
//                        var seekToTime:Number = log.event.to * videoTimeScale;
//                        var seekFromTime:Number = log.event.from * videoTimeScale;
//
//                        // draw mouse hit region
//                        traceAction.graphics.lineStyle(20, 0, 0);
//                        traceAction.graphics.lineTo(videoTime, userTime);
//                        traceAction.graphics.curveTo((Math.max(seekFromTime,seekToTime) - Math.min(seekFromTime,seekToTime))/2 + Math.min(seekFromTime, seekToTime),
//                                userTime - 50,
//                                seekToTime,
//                                userTime);
//
//                        // draw visible line
//                        traceAction.graphics.lineStyle(3, regularColour);
//                        traceAction.graphics.lineTo(videoTime, userTime);
//                        if (seekToTime > seekFromTime) {
//                            traceAction.graphics.lineStyle(4, forwardColour);
//                        } else {
//                            traceAction.graphics.lineStyle(4, backwardColour);
//                        }
//                        traceAction.graphics.curveTo((Math.max(seekFromTime,seekToTime) - Math.min(seekFromTime,seekToTime))/2 + Math.min(seekFromTime, seekToTime),
//                                                   userTime - 50,
//                                                   seekToTime,
//                                                   userTime);
//                        traceAction.graphics.drawCircle(seekToTime, userTime, 10);
//                        traceAction.graphics.moveTo(seekToTime, userTime);
//                        lineEndPoint = new Point(seekToTime, userTime);
//                    } else if (log.event.action == "loadVideo") {
//                        traceAction.graphics.lineStyle(3, regularColour);
//                        traceAction.graphics.moveTo(videoTime, userTime);
//                        traceAction.graphics.drawCircle(videoTime, userTime, 10);
//                        traceAction.graphics.moveTo(videoTime, userTime);
//                        lineEndPoint = new Point(videoTime, userTime);
//                    } else if (log.event.action == "play" ||
//                               log.event.action == "stop") {
//
//                        // draw mouse hit region
//                        traceAction.graphics.lineStyle(20, 0, 0);
//                        traceAction.graphics.lineTo(videoTime, userTime);
//
//                        // draw visible line
//                        traceAction.graphics.moveTo(lineEndPoint.x, lineEndPoint.y);
//                        traceAction.graphics.lineStyle(3, regularColour);
//                        traceAction.graphics.lineTo(videoTime, userTime);
//                        traceAction.graphics.drawCircle(videoTime, userTime, 10);
//                        traceAction.graphics.moveTo(videoTime, userTime);
//                        lineEndPoint = new Point(videoTime, userTime);
//                    }
//
//                    traceAction.addEventListener(MouseEvent.ROLL_OVER,
//                        function traceActionRollOver(e:MouseEvent):void {
//                            var target:TraceActionSprite = (TraceActionSprite)(e.target);
//                            var actionString:String = "[" + target.logIndex + "] " + target.log.date + ", " + "" +
//                                                      "Action: " + target.log.event.action + " at playhead time " + Math.round(target.log.state.playback_time * 10)/10;
//                            if(!isNaN(target.log.event.from)) {
//                                actionString += " from " + Math.round(target.log.event.from * 10)/10;
//                            }
//                            if(!isNaN(target.log.event.to)) {
//                                actionString += " to " + Math.round(target.log.event.to * 10)/10;
//                            }
//                            actionTextField.text = actionString;
//                        });
//                    traceAction.addEventListener(MouseEvent.ROLL_OUT,
//                        function traceActionRollOut(e:MouseEvent):void {
//                            actionTextField.text = "";
//                        });
//
//                    var idxtxt:TextField = new TextField();
//                    idxtxt.autoSize = "center";
//                    idxtxt.text = idx.toString();
//                    userTrace.addChild(idxtxt);
//                    idxtxt.x = videoTime - idxtxt.width / 2;
//                    idxtxt.y = userTime - idxtxt.height / 2;
//
////                    var icon:Shape = new Shape();
////                    if(log.state.play_state) {
////                        // draw a play icon
////                        icon.graphics.lineStyle(1, 0);
////                        icon.graphics.beginFill(0, 1);
////                        icon.graphics.moveTo(0 , 0);
////                        icon.graphics.lineTo(0 , 10);
////                        icon.graphics.lineTo(10, 5);
////                        icon.graphics.endFill();
////                        icon.x = 5;
////
////                        icon.graphics.lineStyle(1, 0xeeeeee, 0.5);
////                        icon.graphics.moveTo(10, 5);
////                        icon.graphics.lineTo(videoTime, 5);
////                    } else {
////                        // draw a stop icon
////                        icon.graphics.lineStyle(1, 0);
////                        icon.graphics.beginFill(0, 1);
////                        icon.graphics.drawRect(0, 0, 10, 10);
////                        icon.graphics.endFill();
////                        icon.x = userTracesWidth - 15;
////
////                        icon.graphics.lineStyle(1, 0xeeeeee, 0.5);
////                        icon.graphics.moveTo(0, 5);
////                        icon.graphics.lineTo(videoTime - icon.x, 5);
////
////                    }
//
////                    icon.y = userTime - 5;
//
////                    userTrace.addChild(icon);
//
//                    userTrace.graphics.moveTo(lineEndPoint.x, lineEndPoint.y);
//
//
//                    trace("\t\t[" + idx + "] " + log.date + " " + log.state.playback_time + " " + log.event.action + " " + log.event.from + " " + log.event.to);
//                    idx++;
//                }
//            }
//        }
//
//        if(user == null) {
//            var checkAllCheckBox:CheckBox = new CheckBox();
//            userTraceCheckBoxes.push(checkAllCheckBox);
//            checkAllCheckBox.width = _width
//            checkAllCheckBox.label = "Uncheck All";
//            checkAllCheckBox.x = 10;
//            checkAllCheckBox.y = userTraceCheckBoxes.length * 20;
//            checkAllCheckBox.selected = false;
//            checkAllCheckBox.addEventListener(MouseEvent.CLICK,
//                    function userTraceHiddenChange(e:Event):void {
//                        for (var i:int = 0; i < userTraceCheckBoxes.length - 1; i++) {
//                            userTraceCheckBoxes[i].selected = e.target.selected;
//
//                            var targetTrace:Sprite = userTraces[i];
//                            targetTrace.alpha = e.target.selected ? 1 : 0;
//                            if (!e.target.selected && uiscrollercontainer.contains(targetTrace)) {
//                                uiscrollercontainer.removeChild(targetTrace);
//                            } else if (e.target.selected && !uiscrollercontainer.contains(targetTrace)) {
//                                uiscrollercontainer.addChild(targetTrace);
//                            }
//
//                        }
//                        e.target.label = e.target.selected ? "Uncheck All" : "Check All";
//                        uiscroller.update();
//                    });
//            addChild(checkAllCheckBox)
//        }
//
//        uiscroller.update();
    }

    public var timeTicks:Sprite = new Sprite();
    public var timeTickTF:Array = [];
    private function drawTimeTicks():void {

//        var startTime:Number = 0;
//        var endTime:Number = video.duration;
//        var _width:Number = uiscroller.width;
//        var _height:Number = 10;
//
//        timeTicks.graphics.clear();
//        timeTicks.graphics.lineStyle(1, 0xcccccc);
//
//        for(var i:int = 0; i<timeTickTF.length; i++) {
//            timeTicks.removeChild(timeTickTF[i]);
//        }
//        timeTickTF = [];
//
//        var totalTime:Number = (uint(endTime+1) - uint(startTime));
//
//        var numTicks:int = Math.min(_width/10, totalTime)
//
//        for(var i:int = uint(startTime); i<uint(endTime+1); i+=Math.round(totalTime/numTicks)) {
//            var x_:Number = (i - uint(startTime))/(uint(endTime+1) - uint(startTime)) * _width;
//            var tickHeight:Number = (i%30 == 0) ? 9 : 4;
//
//            timeTicks.graphics.moveTo(x_, _height - tickHeight);
//            timeTicks.graphics.lineTo(x_, _height - 1);
//        }
//        timeTicks.graphics.moveTo(0, _height)
//        timeTicks.graphics.lineTo(_width, _height);
//
//        var textFormat:TextFormat = new TextFormat("Arial", 10, 0xFFFFE8, true, false, false, null, null, "center", null, null, null, 4);
//        for(var i:int = 1; i<3; i++) {
//            var tickText:FloatingTextField = new FloatingTextField(timeInSecondsToTimeString(getTimeFromXCoordinate(_width*(i/3))), textFormat);
//
//            tickText.x = _width*(i/3) - tickText.width/2;
//            tickText.y = _height - tickText.height - 10;
//
//            timeTicks.addChild(tickText);
//
//            timeTickTF.push(tickText);
//        }
//
//        addChild(timeTicks);
//        timeTicks.x = uiscroller.x;
    }
    public function getTimeFromXCoordinate(_x:Number):Number {
        return _x / uiscroller.width * (video.duration+1 - 0);
    }
    public function timeInSecondsToTimeString(timeX:Number):String {
        var newMinutes:String = uint(timeX/60).toString();
        newMinutes = newMinutes.length == 1 ? "0" + newMinutes : newMinutes;
        var newSeconds:String = uint(timeX%60).toString();
        newSeconds = newSeconds.length == 1 ? "0" + newSeconds : newSeconds;
        return newMinutes + ":" + newSeconds;
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
}

class TraceActionSprite extends Sprite {
    public var logIndex:uint;
    public var log:Log;
}