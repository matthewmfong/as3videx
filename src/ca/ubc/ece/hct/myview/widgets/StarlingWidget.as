////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.KeywordTag;
import ca.ubc.ece.hct.myview.StarlingView;
import ca.ubc.ece.hct.myview.UserDataViewMode;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import org.osflash.signals.Signal;

import starling.core.Starling;

public class StarlingWidget extends StarlingView implements IWidget {

    // collection of widgets that contain Flash native elements
    // so that they can be put under Starling elements when needed (i.e. NativeFriendlyCallout)
    public static var mixedWidgets:Vector.<StarlingWidget> = new Vector.<StarlingWidget>();

    protected var _video:VideoMetadata;

    public var played:Signal;
    public var stopped:Signal;
    public var seeked:Signal;
    public var ccToggled:Signal;
    public var fullscreenToggled:Signal;
    public var selected:Signal;
    public var selecting:Signal; // Useful to make sure that highlights don't get applied until the mouse button is up
    public var deselected:Signal;
    public var highlighted:Signal;
    public var unhighlighted:Signal;
    public var keywordTagged:Signal;
    public var searchedText:Signal;
    public var playbackRateSet:Signal;
    public var playHighlightSelected:Signal;
    public var playheadTimeUpdated:Signal;
    public var highlightsViewModeSet:Signal;
    public var highlightsWriteModeSet:Signal;
    public var viewCountRecordViewModeSet:Signal;
    public var pauseRecordViewModeSet:Signal;
    public var playbackrateRecordViewModeSet:Signal;
    public var startedPlayingIntervals:Signal;
    public var stoppedPlayingIntervals:Signal;
    public var startedPlayingHighlights:Signal;
    public var stoppedPlayingHighlights:Signal;
    public var reachedEndOfVideoSignal:Signal;

    protected var _resizing:Boolean;
    public function set resizing(val:Boolean):void { _resizing = val; }

    protected var highlightReadMode:uint;
    protected var viewCountRecordReadMode:uint;
    protected var pauseRecordReadMode:uint;
    protected var playbackrateRecordReadMode:uint;

    public function StarlingWidget() {
        played							= new Signal(StarlingWidget);
        stopped							= new Signal(StarlingWidget);
        seeked 							= new Signal(StarlingWidget, Number);
        ccToggled                       = new Signal(StarlingWidget, Boolean);
        fullscreenToggled               = new Signal(StarlingWidget, Boolean);
        selected 						= new Signal(StarlingWidget, Range);
        selecting						= new Signal(StarlingWidget, Range);
        deselected 						= new Signal(StarlingWidget);
        highlighted 					= new Signal(StarlingWidget, int, Range); // colour, interval
        unhighlighted 					= new Signal(StarlingWidget, int, Range); // colour, interval
        keywordTagged                   = new Signal(StarlingWidget, KeywordTag);
        searchedText					= new Signal(StarlingWidget, String);
        playbackRateSet					= new Signal(StarlingWidget, Number); // rate
        playHighlightSelected			= new Signal(StarlingWidget, int);
        playheadTimeUpdated 			= new Signal(StarlingWidget, Number);
        highlightsViewModeSet 			= new Signal(StarlingWidget, uint); // UserDataViewMode
        highlightsWriteModeSet			= new Signal(StarlingWidget, String, Number); // colour
        viewCountRecordViewModeSet 		= new Signal(StarlingWidget, uint); // UserDataViewMode
        pauseRecordViewModeSet 			= new Signal(StarlingWidget, uint); // UserDataViewMode
        playbackrateRecordViewModeSet 	= new Signal(StarlingWidget, uint); // UserDataViewMode
        startedPlayingIntervals			= new Signal(StarlingWidget, Vector.<Range>); // intervals
        stoppedPlayingIntervals			= new Signal(StarlingWidget, Vector.<Range>); // intervals
        startedPlayingHighlights		= new Signal(StarlingWidget, uint); // colour
        stoppedPlayingHighlights		= new Signal(StarlingWidget); // colour
        reachedEndOfVideoSignal         = new Signal();

        _resizing                       = false;

        highlightReadMode 				= UserDataViewMode.PERSONAL;
        viewCountRecordReadMode			= UserDataViewMode.PERSONAL;
        pauseRecordReadMode				= UserDataViewMode.PERSONAL;
        playbackrateRecordReadMode		= UserDataViewMode.PERSONAL;
    }

    override public function dispose():void {
        super.dispose();
        played = null;
        stopped = null;
        seeked = null;
        ccToggled = null;
        fullscreenToggled = null;
        selected = null;
        selecting = null;
        deselected = null;
        highlighted = null;
        unhighlighted = null;
        keywordTagged = null;
        searchedText = null;
        playbackRateSet = null;
        playHighlightSelected = null;
        playheadTimeUpdated = null;
        highlightsViewModeSet = null;
        highlightsWriteModeSet = null;
        viewCountRecordViewModeSet = null;
        pauseRecordViewModeSet = null;
        playbackrateRecordViewModeSet = null;
        startedPlayingIntervals = null;
        stoppedPlayingIntervals = null;
        startedPlayingHighlights = null;
        stoppedPlayingIntervals = null;
        reachedEndOfVideoSignal = null;
    }

    public function loadVideo(video:VideoMetadata):void { }
    public function setInterval(interval:Range):void { }

    public function play():void { }
    public function stop():void { }
    public function set playheadTime(time:Number):void { }
    public function receiveSeek(time:Number):void { }
    public function ccToggle():void { }
    public function fullScreen():void { }

    public function select(interval:Range):void { }
    public function deselect():void { }

    public function setHighlightsWriteMode(mode:String, colour:uint):void { }
    public function highlight(colour:int, interval:Range):void { }
    public function unhighlight(colour:int, interval:Range):void { }
    public function keywordTag(keywordTag:KeywordTag):void { }
    public function playHighlights(colour:int):void { }

    public function updateHighlights():void { }

    public function setPlaybackRate(rate:Number):void { }
    public function searchText(string:String):void { }

    // bitwise or with UserDataViewMode
    public function setHighlightReadMode(mode:uint):void { }
    public function setViewCountRecordReadMode(mode:uint):void { }
    public function setPauseRecordReadMode(mode:uint):void { }
    public function setPlaybackRateRecordReadMode(mode:uint):void { }

    public function startPlayingIntervals(intervals:Vector.<Range>):void { }
    public function stopPlayingIntervals(intervals:Vector.<Range>):void { }
    public function startPlayingHighlights(colour:uint):void { }
    public function stopPlayingHighlights():void { }

    override public function move(x:Number, y:Number):void { super.move(x, y); }
    public function setSize(width:Number, height:Number):void { _width = width; _height = height; }

    public function setFullscreen(fullscreen:Boolean):void { }
    public function setClosedCaptions(closedCaptions:Boolean):void { }

    public function swapStarlingNative():void { }

    public static function allWidgetSwapStarlingNative():void {
        for each(var widget:StarlingWidget in mixedWidgets) {
            widget.swapStarlingNative();
        }
    }

}
}