////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.UserDataViewMode;
import ca.ubc.ece.hct.myview.View;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import org.osflash.signals.Signal;

public class Widget extends View implements IWidget{

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

	protected var _resizing:Boolean;
	public function set resizing(val:Boolean):void { _resizing = val; }

	protected var highlightReadMode:uint;
	protected var viewCountRecordReadMode:uint;
	protected var pauseRecordReadMode:uint;
	protected var playbackrateRecordReadMode:uint;

	public function Widget() {
		played							= new Signal(Widget);
		stopped							= new Signal(Widget);
		seeked 							= new Signal(Widget, Number);
        ccToggled                       = new Signal(StarlingWidget, Boolean);
        fullscreenToggled               = new Signal(StarlingWidget, Boolean);
		selected 						= new Signal(Widget, Range);
		selecting						= new Signal(Widget, Range);
		deselected 						= new Signal(Widget);
		highlighted 					= new Signal(Widget, int, Range); // colour, interval
		unhighlighted 					= new Signal(Widget, int, Range); // colour, interval
		searchedText					= new Signal(Widget, String);
		playbackRateSet					= new Signal(Widget, Number); // rate
		playHighlightSelected			= new Signal(Widget, int);
		playheadTimeUpdated 			= new Signal(Widget, Number);
		highlightsViewModeSet 			= new Signal(Widget, uint); // UserDataViewMode
		highlightsWriteModeSet			= new Signal(Widget, String, Number); // colour
		viewCountRecordViewModeSet 		= new Signal(Widget, uint); // UserDataViewMode
		pauseRecordViewModeSet 			= new Signal(Widget, uint); // UserDataViewMode
		playbackrateRecordViewModeSet 	= new Signal(Widget, uint); // UserDataViewMode
		startedPlayingIntervals			= new Signal(Widget, Vector.<Range>); // intervals
		stoppedPlayingIntervals			= new Signal(Widget, Vector.<Range>); // intervals
		startedPlayingHighlights		= new Signal(Widget, uint); // colour
		stoppedPlayingHighlights		= new Signal(Widget); // colour

		highlightReadMode 				= UserDataViewMode.PERSONAL;
		viewCountRecordReadMode			= UserDataViewMode.PERSONAL;
		pauseRecordReadMode				= UserDataViewMode.PERSONAL;
		playbackrateRecordReadMode		= UserDataViewMode.PERSONAL;
	}

	public function dispose():void {

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
	}

	public function loadVideo(video:VideoMetadata):void { /*trace(this + " not implemented");*/ }

	public function play():void { /*trace(this + " play not implemented");*/ }
	public function stop():void { /*trace(this + " stop not implemented");*/ }
	public function set playheadTime(time:Number):void { /*trace(this + " set playheadTime not implemented");*/ }
	public function receiveSeek(time:Number):void { /*trace(this + " receiveSeek not implemented");*/ }

	public function select(interval:Range):void { /*trace(this + " select not implemented");*/ }
	public function deselect():void { /*trace(this + " deselect not implemented");*/ }

	public function setHighlightsWriteMode(mode:String, colour:uint):void { /*trace(this + " setHighlightsWriteMode not implemented");*/ }
	public function highlight(colour:int, interval:Range):void { /*trace(this + " highlight not implemented");*/ }
	public function unhighlight(colour:int, interval:Range):void { /*trace(this + " unhighlight not implemented");*/ }
	public function playHighlights(colour:int):void { /*trace(this + " playHighlights not implemented");*/ }

	public function updateHighlights():void { /*trace(this + " updateHighlights not implemented");*/ }

	public function setPlaybackRate(rate:Number):void { /*trace(this + " setPlaybackRate not implemented");*/ }
	public function searchText(string:String):void { /*trace(this + " searchedText not implemented");*/ }

	// bitwise or with UserDataViewMode
	public function setHighlightReadMode(mode:uint):void { /*trace(this + " setHighlightsViewMode not implemented");*/ }
	public function setViewCountRecordReadMode(mode:uint):void { /*trace(this + " setViewCountRecordViewMode not implemented");*/ }
	public function setPauseRecordReadMode(mode:uint):void { /*trace(this + " setPauseRecordViewMode not implemented");*/ }
	public function setPlaybackRateRecordReadMode(mode:uint):void { /*trace(this + " setPlaybackRateRecordViewMode not implemented");*/ }

	public function startPlayingIntervals(intervals:Vector.<Range>):void { /*trace(this + " startPlayingIntervals not implemented");*/ }
	public function stopPlayingIntervals(intervals:Vector.<Range>):void { /*trace(this + " stopPlayingIntervals not implemented");*/ }
	public function startPlayingHighlights(colour:uint):void { /*trace(this + " startPlayingHighlights not implemented");*/ }
	public function stopPlayingHighlights():void { /*trace(this + " stopPlayingHighlights not implemented");*/ }


    public function setFullscreen(fullscreen:Boolean):void { }
    public function setClosedCaptions(closedCaptions:Boolean):void { }

    override public function move(x:Number, y:Number):void { super.move(x, y); }
    public function setSize(width:Number, height:Number):void { }

}
}