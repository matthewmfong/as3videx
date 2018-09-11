////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.common.Annotation;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.IWidget;
import ca.ubc.ece.hct.myview.widgets.Widget;

import flash.desktop.NativeApplication;

import flash.events.Event;
import flash.events.TimerEvent;
import flash.geom.Rectangle;
import flash.utils.Timer;

import org.osflash.signals.Signal;

import starling.core.Starling;

public class StarlingVideoPlayerModel {

    private var _video:VideoMetadata;
    public function get video():VideoMetadata { return _video; }
    public var playing:Boolean;
    public var playheadTime:Number;
    public var playbackRate:Number;
    public var selection:Range;
    public var activeHighlightColour:int;

    public var fullscreen:Boolean;
    public var fullscreenSignal:Signal;
    public var closedCaptions:Boolean;

    public var leftDimensions:Rectangle;
    public var topDimensions:Rectangle;
    public var bottomDimensions:Rectangle;
    public var rightDimensions:Rectangle;
    public var centreDimensions:Rectangle;

    public function get state():String {
        var stateString:String = "{";
        if(_video) {
            stateString +=
                    "\"videoID\":" + _video.media_alias_id + "," +
                    "\"videoFilename\":" + "\"" + _video.filename + "\",";

        }
        stateString +=
                "\"play_state\":" + "\"" + playing + "\"," +
                "\"playback_time\":" + playheadTime + "," +
                "\"playback_rate\":" + playbackRate + "," +
                "\"selection\":" + "\"" + selection + "\"," +
                "\"active_highlight_colour\":" + "\"#" + activeHighlightColour.toString(16) + "\"," +
                "\"highlight_write_mode\":" + "\"" + highlightWriteMode + "\"," +
                "\"highlight_read_mode\":" + highlightReadMode + "," +
                "\"view_count_read_mode\":" + viewCountRecordReadMode + "," +
                "\"pause_record_read_mode\":" + pauseRecordReadMode + "," +
                "\"playback_rate_read_mode\":" + playbackRateReadMode + "," +
                "\"fullscreen\":" + fullscreen + "," +
                "\"closed_captions\":" + closedCaptions + "," +
                "\"left_dimensions\":\"" + leftDimensions.toString() + "\"," +
                "\"right_dimensions\":\"" + rightDimensions.toString() + "\"," +
                "\"top_dimensions\":\"" + topDimensions.toString() + "\"," +
                "\"bottom_dimensions\":\"" + bottomDimensions.toString() + "\"," +
                "\"centre_dimensions\":\"" + centreDimensions.toString() + "\"";

        if(!Starling.current.nativeStage.nativeWindow.closed) {
            stateString = stateString + "," +
            "\"stage_dimensions\":\"" +
                                new flash.geom.Rectangle(Starling.current.nativeStage.nativeWindow.x,
                                                        Starling.current.nativeStage.nativeWindow.y,
                                                        Starling.current.nativeStage.nativeWindow.width,
                                                        Starling.current.nativeStage.nativeWindow.height) + "\"";

        }

        stateString = stateString + "}";

        return stateString;
    }

    public static function eventToJSON(source:*, ...args):String {

        if(args.length % 2 != 0) {
            trace("args needs to be paired");
        }
        var eventString:String =
                "{" +
                "\"source\":\"" + source + "\",";
        for(var i:int = 0; i<args.length; i+=2) {
            eventString += "\"" + args[i] +"\":\"" + args[i+1] + "\",";
        }
        eventString = eventString.substr(0, eventString.length - 1);
        eventString += "}";

        return eventString;
    }

    // personal, class, instructor, hidden
    public var highlightReadMode:uint;
    public var viewCountRecordReadMode:uint;
    public var pauseRecordReadMode:uint;
    public var playbackRateReadMode:uint;

    // quick (select = highlight), slow (select first then highlight)
    public var highlightWriteMode:String;

    public var widgets:Array;
//    private var _sendVCRTimer:Timer;
    private var _pingStateTimer:Timer;

    public function StarlingVideoPlayerModel() {

        highlightReadMode		= UserDataViewMode.PERSONAL;
        viewCountRecordReadMode	= UserDataViewMode.PERSONAL;
        pauseRecordReadMode		= UserDataViewMode.PERSONAL;
        playbackRateReadMode	= UserDataViewMode.PERSONAL;

        highlightWriteMode = HighlightMode.PRE_SELECT;
        selection = new Range(0, 0);

        widgets = [];

//        _sendVCRTimer = new Timer(10000);
//        _sendVCRTimer.addEventListener(TimerEvent.TIMER, sendVCR);

        _pingStateTimer = new Timer(5000);
        _pingStateTimer.addEventListener(TimerEvent.TIMER, pingState);

        fullscreenSignal = new Signal(Boolean);

        leftDimensions = new flash.geom.Rectangle(0, 0, 1, 1);
        rightDimensions = new flash.geom.Rectangle(0, 0, 1, 1);
        topDimensions = new flash.geom.Rectangle(0, 0, 1, 1);
        bottomDimensions = new flash.geom.Rectangle(0, 0, 1, 1);
        centreDimensions = new flash.geom.Rectangle(0, 0, 1, 1);
    }

    public function loadVideo(video:VideoMetadata):void {
//        _sendVCRTimer.start();
        _pingStateTimer.start();
        _video = video;
        playheadTime = 0;
        playbackRate = 1;

//			ServerDataLoader.addLog(UserID.id, "loadVideo " + video.filename);
        ServerDataLoader.addLoadMediaLog(UserID.id, _video.media_alias_id);
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(this, "action", "loadVideo", "video", _video.filename));
        ServerDataLoader.getCrowdHighlights(_video.media_alias_id).add(crowdHighlightsLoaded);
        ServerDataLoader.getCrowdVCRs(_video.media_alias_id).add(crowdVCRsLoaded);

        for each(var widget:IWidget in widgets) {
            widget.loadVideo(video);
        }

        sendVCR();

    }

    public function linkWidget(widget:StarlingWidget):void {
        widget.played.add(play);
        widget.stopped.add(stop);
        widget.seeked.add(seek);
        widget.ccToggled.add(setClosedCaptions);
        widget.fullscreenToggled.add(setFullscreen);
        widget.selected.add(select);
        widget.selecting.add(selecting);
        widget.deselected.add(deselect);
        widget.annotated.add(annotate);
        widget.highlighted.add(highlight);
        widget.unhighlighted.add(unhighlight);
        widget.playbackRateSet.add(setPlaybackRate);
        widget.playheadTimeUpdated.add(updatePlayhead);
        widget.highlightsViewModeSet.add(setHighlightReadMode);
        widget.viewCountRecordViewModeSet.add(setViewCountRecordReadMode);
        widget.highlightsWriteModeSet.add(highlightWriteModeSelected);
//			widget.startedPlayingIntervals.add();
//			widget.stoppedPlayingIntervals.add();
        widget.startedPlayingHighlights.add(startPlayingHighlights);
        widget.stoppedPlayingHighlights.add(stopPlayingHighlights);
        widget.searchedText.add(searchText);
        widget.reachedEndOfVideoSignal.add(reachedEndOfVideo);

        widgets.push(widget);
    }

    public function exit():void {
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON("toolbar", "action", "playerExit"));
        ServerDataLoader.setVCR(UserID.id, _video.media_alias_id, _video.userData.viewCountRecord);
        _video = null;
    }

    public function keyboardPlayPauseToggle():void {

        sendVCR();

        if(playing) {
            playing = false;
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON("keyboard", "action", "stop", "time", playheadTime));
            for each(var widget:IWidget in widgets) {
                widget.stop();
            }
        } else {
            playing = true;
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON("keyboard", "action", "play", "time", playheadTime));
            for each(var widget2:IWidget in widgets) {
                widget2.play();
            }
        }
    }

    public function keyboardSeek(time:Number):void {

        sendVCR();

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON("keyboard", "action", "seek", "from", playheadTime, "to", time));
        for each(var widget:IWidget in widgets) {
            widget.receiveSeek(time);
        }
    }

    public function play(source:IWidget):void {

        sendVCR();

        playing = true;
//			trace(state);
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "play", "time", playheadTime));
//            ServerDataLoader.addLog(UserID.id, source + " start playback from " + playheadTime);
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.play();
        }
    }

    public function stop(source:IWidget):void {

        sendVCR();

        playing = false;
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "stop", "time", playheadTime));
//            ServerDataLoader.addLog(UserID.id, source + " stop playback at " + playheadTime);
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.stop();
        }
    }

    public function reachedEndOfVideo():void {

        sendVCR();

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(null, "action", "reachedEndOfVideo"));
    }

    public var resizingPlayingState:Boolean;
    public function set resizing(val:Boolean):void {

        if(val) {
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(null, "action", "resize_pause_video"));
        } else {
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(null, "action", "resize_resume_video"));
        }

        var widget:IWidget;

        if(val) {
            resizingPlayingState = playing;
            for each(widget in widgets) {
                widget.stop();
            }
        } else if(resizingPlayingState) {
            for each(widget in widgets) {
                widget.play();
            }
        }

    }

    private function updatePlayhead(source:IWidget, time:Number):void {
        playheadTime = time;
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.playheadTime = time;
        }
    }

    private function seek(source:IWidget, time:Number):void {

        sendVCR();

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "seek", "from", playheadTime, "to", time));
//            ServerDataLoader.addLog(UserID.id, source + " seek to " + time + " from " + playheadTime);
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.receiveSeek(time);
        }
    }

    private function select(source:IWidget, interval:Range):void {

        if(highlightWriteMode == HighlightMode.POST_SELECT) {
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "highlight", "interval", interval, "colour", "#" + activeHighlightColour.toString(16)));
//                ServerDataLoader.addLog(UserID.id, source + " highlight " + interval + " in #" + activeHighlightColour.toString(16));
            if (activeHighlightColour != 0xffffff) {
                highlight(source, activeHighlightColour, interval);
            } else if(activeHighlightColour == 0xffffff) {
                unhighlight(source, activeHighlightColour, interval);
            }

        } else if(highlightWriteMode == HighlightMode.PRE_SELECT) {
            selection = interval;
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "select", "selection", selection));
//                ServerDataLoader.addLog(UserID.id, source + " select " + interval);
            for each(var widget:IWidget in widgets) {
                if(widget != source)
                    widget.select(interval);
            }
        }
    }

    private function selecting(source:IWidget, interval:Range):void {
        selection = interval;
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.select(interval);
        }
    }

    private function deselect(source:IWidget):void {

        sendVCR();

        selection = new Range(0, 0);
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "deselect", "selection", selection));
//            ServerDataLoader.addLog(UserID.id, source + " deselect");
        for each(var widget:IWidget in widgets) {
            // if(widget != source)
            widget.deselect();
        }
    }

    private function setPlaybackRate(source:IWidget, rate:Number):void {

        sendVCR();

        playbackRate = rate;
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_playback_rate", "rate", rate));
//            ServerDataLoader.addLog(UserID.id, source + " changed playbackRate to " + rate);
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.setPlaybackRate(rate);
        }
    }

    private function setFullscreen(source:IWidget, fullscreen:Boolean):void {

        sendVCR();

        this.fullscreen = fullscreen;
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_fullscreen", "fullscreen", fullscreen));

        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.setFullscreen(fullscreen);
        }

        fullscreenSignal.dispatch(fullscreen);

    }

    private function setClosedCaptions(source:IWidget, closedCaptions:Boolean):void {

        sendVCR();

        this.closedCaptions = closedCaptions;
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_cc", "cc", closedCaptions));
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.setClosedCaptions(closedCaptions);
        }
    }

    private function highlightWriteModeSelected(source:IWidget, mode:String, colour:uint):void {

        activeHighlightColour = colour;
        switch(selection.length > 0) {

            case false:
                highlightWriteMode = mode;
                ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_highlight_write_mode", "mode", mode));
//                    ServerDataLoader.addLog(UserID.id, source + " set highlight write mode " + mode);
                for each(var widget:IWidget in widgets) {
                    if(widget != source)
                        widget.setHighlightsWriteMode(mode, colour);
                }
                break;

            case true:
                if(mode == HighlightMode.POST_SELECT) {
                    if (activeHighlightColour != 0xffffff) {
                        highlight(source, colour, selection);
                    } else if(activeHighlightColour == 0xffffff) {
                        unhighlight(source, colour, selection);
                    }

                    highlightWriteMode = HighlightMode.PRE_SELECT;
                    for each(var widget2:IWidget in widgets) {
                        widget2.setHighlightsWriteMode(highlightWriteMode, colour);
                    }

                } else if(mode == HighlightMode.POST_SELECT) {
                    // ??? You cannot select anything in POST_SELECT mode.
                }
                break;
        }
    }


    private function annotate(source:IWidget, annotation:Annotation):void {
        _video.userData.annotate(annotation);

        sendVCR();

        ServerDataLoader.addLog_v2(UserID.id,
                state,
                eventToJSON(source, "action", "annotate",
                                    "interval", annotation.interval,
                                    "colour", "#" + annotation.colour.toString(16),
                                    "note", annotation.note));
        ServerDataLoader.annotate(UserID.id, _video.media_alias_id, annotation);
    }

    private function highlight(source:IWidget, colour:int, interval:Range):void {
        _video.userData.highlight(colour, interval);


        sendVCR();

        updateHighlights();

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "highlight", "interval", interval, "colour", "#" + colour.toString(16)));
        ServerDataLoader.highlight(UserID.id, _video.media_alias_id, colour, _video.userData.highlights.grab(colour).toString());
    }

    private function unhighlight(source:IWidget, colour:int, interval:Range):void {
//        _video.userData.unhighlightAll(interval);
        _video.userData.unhighlight(colour, interval);


        sendVCR();

        updateHighlights();

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "unhighlight", "interval", interval, "colour", "#" + colour.toString(16)));
        var colours:Array = _video.userData.highlights.keys();
        for(var i:int = 0; i<colours.length; i++) {
            ServerDataLoader.highlight(UserID.id, _video.media_alias_id, colours[i], _video.userData.highlights.grab(colours[i]).toString());
        }
//	    	ServerDataLoader.highlight(UserID.id, _video.media_alias_id, colour, _video.userData.highlights.grab(colour).toString());
    }

    private function startPlayingHighlights(source:IWidget, colour:int):void {


        sendVCR();

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "play_highlights", "colour", colour.toString(16)));
//            ServerDataLoader.addLog(UserID.id, source + " startPlayingHighlights " + colour.toString(16))
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.startPlayingHighlights(colour);
        }
    }

    private function stopPlayingHighlights(source:IWidget):void {


        sendVCR();
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "stop_playing_highlights"));
//			ServerDataLoader.addLog(UserID.id, "stopPlayingHighlights");
        for each(var widget:IWidget in widgets) {
            if(widget != source)
                widget.stopPlayingHighlights();
        }
    }

    private function updateHighlights():void {
        for each(var widget:IWidget in widgets) {
            widget.updateHighlights();
        }
    }

    // bitwise or with UserDataViewMode
    private function setHighlightReadMode(source:IWidget, mode:uint):void {
        var modeString:String = "";
        if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
            modeString += " HIDE ";
        }
        if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
            modeString += " CLASS ";
        }
        if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
            modeString += " PERSONAL ";
        }
        if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
            modeString += " INSTRUCTOR ";
        }

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_highlight_read_mode", "mode", modeString));
//            ServerDataLoader.addLog(UserID.id, source + " highlightReadMode " + modeString);
        for each(var widget:IWidget in widgets) {
            widget.setHighlightReadMode(mode);
        }
    }
    private function setViewCountRecordReadMode(source:IWidget, mode:uint):void {
        var modeString:String = "";
        if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
            modeString += " HIDE ";
        }
        if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
            modeString += " CLASS ";
        }
        if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
            modeString += " PERSONAL ";
        }
        if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
            modeString += " INSTRUCTOR ";
        }

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_view_count_record_read_mode", "mode", modeString));
//            ServerDataLoader.addLog(UserID.id, source + " viewCountRecordReadMode " + modeString);
        for each(var widget:IWidget in widgets) {
            widget.setViewCountRecordReadMode(mode);
        }
    }
    private function setPauseRecordReadMode(source:IWidget, mode:uint):void {
        var modeString:String = "";
        if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
            modeString += " HIDE ";
        }
        if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
            modeString += " CLASS ";
        }
        if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
            modeString += " PERSONAL ";
        }
        if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
            modeString += " INSTRUCTOR ";
        }

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_pause_record_read_mode", "mode", modeString));
//            ServerDataLoader.addLog(UserID.id, source + " pauseRecordReadMode " + modeString);
        for each(var widget:IWidget in widgets) {
            widget.setPauseRecordReadMode(mode);
        }
    }
    private function setPlaybackRateRecordReadMode(source:IWidget, mode:uint):void {
        var modeString:String = "";
        if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
            modeString += " HIDE ";
        }
        if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
            modeString += " CLASS ";
        }
        if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
            modeString += " PERSONAL ";
        }
        if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
            modeString += " INSTRUCTOR ";
        }

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_playback_rate_record_read_mode", "mode", modeString));
//            ServerDataLoader.addLog(UserID.id, source + " playbackRateRecordReadMode " + modeString);
        for each(var widget:IWidget in widgets) {
            widget.setPlaybackRateRecordReadMode(mode);
        }
    }

    private function searchText(source:IWidget, searchString:String):void {

        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "searchText", "string", searchString));
        for each(var widget:IWidget in widgets) {
            widget.searchText(searchString);
        }

    }

    private function sendVCR(e:Event = null):void {
        if(_video != null) {
            ServerDataLoader.setVCR(UserID.id, _video.media_alias_id, _video.userData.viewCountRecord);
        }
    }

    private function crowdVCRsLoaded(object:Object):void {
        var obj:* = JSON.parse((String)(object));

        for(var n:String in obj) {
            if(obj.hasOwnProperty(n)) {
                var user_string:String;
                var view_count_record_string:String;

                for (var m:String in obj[n]) {
                    if (obj[n].hasOwnProperty(m)) {
                        switch (m) {
                            case "user_id":
                                user_string = obj[n][m];
                                break;
                            case "view_count_record":
                                view_count_record_string = obj[n][m];
                                break;
                        }
                    }
                }


                if (_video) {
                    var userData:UserData = _video.grabCrowdUserData(UserData.CLASS, user_string);

                    if (userData && view_count_record_string) {
                        userData.view_count_record = view_count_record_string;
                    } else if (view_count_record_string && user_string) {
                        userData = new UserData();
                        userData.userString = user_string;
                        userData.view_count_record = view_count_record_string;
                        _video.addCrowdUserData(UserData.CLASS, userData);
                    }
                }
            }
        }
        
    }

    private function crowdHighlightsLoaded(object:Object):void {
        var obj:* = JSON.parse((String)(object));
        for(var n:String in obj) {
            if (obj.hasOwnProperty(n)) {

                var user_string:String;
                var colour_string:String;
                var intervals_string:String;

                for (var m:String in obj[n]) {
                    if(obj[n].hasOwnProperty(m)) {
                        switch (m) {
                            case "user_id":
                                user_string = obj[n][m];
                                break;
                            case "colour":
                                colour_string = obj[n][m];
                                break;
                            case "intervals":
                                intervals_string = obj[n][m];
                                break;
                        }
                    }
                }

                var userData:UserData = _video.grabCrowdUserData(UserData.CLASS, user_string);

                if (userData && colour_string && intervals_string) {
                    userData.setHighlights(colour_string, intervals_string);
                } else {
                    userData = new UserData();
                    userData.setHighlights(colour_string, intervals_string);
                    _video.addCrowdUserData(UserData.CLASS, userData);
                }
            }
        }
    }

    private function pingState(e:TimerEvent):void {
        ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(this));

    }
}
}