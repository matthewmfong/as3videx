/**
 * Created by iDunno on 2017-07-23.
 */
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

public interface IWidget {

    function loadVideo(video:VideoMetadata):void;

    function play():void;
    function stop():void;
    function set playheadTime(time:Number):void;
    function receiveSeek(time:Number):void;

    function select(interval:Range):void;
    function deselect():void;

    function setHighlightsWriteMode(mode:String, colour:uint):void;
    function highlight(colour:int, interval:Range):void;
    function unhighlight(colour:int, interval:Range):void;
    function playHighlights(colour:int):void;

    function updateHighlights():void;

    function setPlaybackRate(rate:Number):void;
    function searchText(string:String):void;

    // bitwise or with UserDataViewMode
    function setHighlightReadMode(mode:uint):void;
    function setViewCountRecordReadMode(mode:uint):void;
    function setPauseRecordReadMode(mode:uint):void;
    function setPlaybackRateRecordReadMode(mode:uint):void;

    function startPlayingIntervals(intervals:Vector.<Range>):void;
    function stopPlayingIntervals(intervals:Vector.<Range>):void;
    function startPlayingHighlights(colour:uint):void;
    function stopPlayingHighlights():void;


    function setFullscreen(fullscreen:Boolean):void;
    function setClosedCaptions(closedCaptions:Boolean):void;

    function move(x:Number, y:Number):void;
    function setSize(width:Number, height:Number):void;
    function set resizing(val:Boolean):void;
}
}
