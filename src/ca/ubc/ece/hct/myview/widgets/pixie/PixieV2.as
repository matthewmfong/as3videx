////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.pixie {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.Colours;
import ca.ubc.ece.hct.myview.Highlights;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.Widget;

import flash.display.CapsStyle;
import flash.display.LineScaleMode;
import flash.display.Shape;
import flash.geom.Point;

public class PixieV2 extends Widget{

    private var pix:Pixie;
    private var playhead:Shape;
    private var viewCountRecord:Shape;
    private var highlights:Shape;

    public function PixieV2(width:Number, height:Number) {
        _width = width;
        _height = height;

//        graphics.lineStyle(1, 0xffff00, 0.4);
//        graphics.beginFill(0xffffff, 1)
//        for(var i:int = 0; i<181; i++) {
//            var r:Number = _height/2;
//            var theta:Number = i * Math.PI/180 - Math.PI/2;
//            var _x:Number = r * Math.cos(theta);
//            var _y:Number = r * Math.sin(theta) + _height/2;
//            graphics.lineTo(_x, _y);
//        }
//        graphics.lineTo(0, 0);
//        graphics.endFill();

        viewCountRecord = new Shape();
        addChild(viewCountRecord);

        highlights = new Shape();
        addChild(highlights);


        playhead = new Shape();
        playhead.graphics.lineStyle(1, 0xff0000);
        playhead.graphics.lineTo(0, -_height/2)
        addChild(playhead);
        playhead.y = _height/2;

        pix = new Pixie(_width/4, _height/4);
        addChild(pix);
        pix.y = _height/2 - pix.height/2;
    }

    private function drawViewCountRecord():void {
        var maxViewCount:Number = _video.userData.maxViewCount;
        var fullRadius:Number =  _height/4;

        var centre:Point = new Point(0, _height/2);
        viewCountRecord.graphics.clear();
        viewCountRecord.graphics.lineStyle(1, 0x00ff00);
        viewCountRecord.graphics.beginFill(0x00cc00);
//        viewCountRecord.graphics.moveTo(centre.x, centre.y);

        var i:int;
        for(i = 0; i<_video.userData.viewCountRecord.length; i++) {
//            var r:Number = _video.userData.viewCountRecord[i] / maxViewCount * fullRadius/4 + fullRadius * 3/4;
            var r:Number = _video.userData.viewCountRecord[i] / maxViewCount * (fullRadius - Colours.colours.length * fullRadius/15) + fullRadius * 3/4;//fullRadius - Colours.colours.length * fullRadius/15;
            var theta:Number = i/_video.duration * Math.PI - Math.PI/2;
            var _x:Number = r * Math.cos(theta) + centre.x;
            var _y:Number = r * Math.sin(theta) + centre.y;
            if(i == 0) {
                viewCountRecord.graphics.moveTo(_x, _y);
            } else {
                viewCountRecord.graphics.lineTo(_x, _y);
            }
        }

        for(i = _video.userData.viewCountRecord.length- 1; i >= 0; i--) {
//            var r:Number = _video.userData.viewCountRecord[i] / maxViewCount * fullRadius/4 + fullRadius * 3/4 - fullRadius / 15;
            var r:Number = _video.userData.viewCountRecord[i] / maxViewCount * (fullRadius - Colours.colours.length * fullRadius/15) + fullRadius * 3/4 - fullRadius / 15;
            var theta:Number = i/_video.duration * Math.PI - Math.PI/2;
            var _x:Number = r * Math.cos(theta) + centre.x;
            var _y:Number = r * Math.sin(theta) + centre.y;
            viewCountRecord.graphics.lineTo(_x, _y);
        }
        viewCountRecord.graphics.endFill();
    }

    override public function loadVideo(video:VideoMetadata):void {
        _video = video;
        pix.loadVideo(video);
        drawViewCountRecord();
        updateHighlights();
    }

    override public function play():void { trace(this + " play not implemented"); }
    override public function stop():void { trace(this + " stop not implemented"); }
    override public function set playheadTime(time:Number):void {
        playhead.rotation = time/_video.duration * 180;
        pix.playheadTime = time;
        drawViewCountRecord();
        updateHighlights();
    }
    override public function receiveSeek(time:Number):void { trace(this + " receiveSeek not implemented"); }

    override public function select(interval:Range):void { trace(this + " select not implemented"); }
    override public function deselect():void { trace(this + " deselect not implemented"); }

    override public function setHighlightsWriteMode(mode:String, colour:uint):void { trace(this + " setHighlightsWriteMode not implemented"); }
    override public function highlight(colour:int, interval:Range):void { trace(this + " highlight not implemented"); }
    override public function unhighlight(colour:int, interval:Range):void { trace(this + " unhighlight not implemented"); }
    override public function playHighlights(colour:int):void { trace(this + " playHighlights not implemented"); }

    override public function updateHighlights():void {
        var centre:Point = new Point(0, _height/2);
        var fullRadius:Number =  _height/2;

        var highlightsArray:Array = _video.userData.highlights.values();
        highlights.graphics.clear();


        highlights.graphics.lineStyle(1, 0xcccccc);
        highlights.graphics.beginFill(0xcccccc, 0.5);

        var i:int;
        for(i = -90; i <= 90; i++) {
            var r:Number = fullRadius;
            var theta:Number =  i * Math.PI/180;
            var _x:Number = r * Math.cos(theta) + centre.x;
            var _y:Number = r * Math.sin(theta) + centre.y;
            if(i == -90) {
                highlights.graphics.moveTo(_x, _y);
            } else {
                highlights.graphics.lineTo(_x, _y);
            }
        }

        for(i = 90; i >= -90; i--) {
            var r:Number = fullRadius - highlightsArray.length * fullRadius/15;
            var theta:Number = i * Math.PI/180;
            var _x:Number = r * Math.cos(theta) + centre.x;
            var _y:Number = r * Math.sin(theta) + centre.y;
            highlights.graphics.lineTo(_x, _y);
        }
        highlights.graphics.endFill();

        var colourIndex:int = 0;

        for each(var colour:Highlights in highlightsArray) {

            for each(var interval:Range in colour.intervals) {
                var arcDegreeInterval:Range = new Range(Math.floor(interval.start/_video.duration * 180 - 90),
                                                     Math.floor(interval.end/_video.duration * 180 - 90));

                var brightenAmount:Number = (playhead.rotation > (arcDegreeInterval.start+90) && playhead.rotation < (arcDegreeInterval.end+90)) ? 3 : -1.5;

                highlights.graphics.lineStyle(2, Util.brighten(colour.colour, 1.1), 1, false, LineScaleMode.NORMAL, CapsStyle.NONE);

                highlights.graphics.beginFill(Util.changeSaturation(colour.colour, 2 + brightenAmount));

                for(var i:int = arcDegreeInterval.start; i <= arcDegreeInterval.end; i++) {
                    var r:Number = fullRadius - colourIndex * fullRadius/15;
                    var theta:Number =  i * Math.PI/180;
                    var _x:Number = r * Math.cos(theta) + centre.x;
                    var _y:Number = r * Math.sin(theta) + centre.y;
                    if(i == arcDegreeInterval.start) {
                        highlights.graphics.moveTo(_x, _y);
                    } else {
                        highlights.graphics.lineTo(_x, _y);
                    }
                }

                highlights.graphics.lineStyle(0, 0, 0, false, LineScaleMode.NORMAL, CapsStyle.NONE);

                for(var i:int = arcDegreeInterval.end; i >= arcDegreeInterval.start; i--) {
                    var r:Number = fullRadius - colourIndex * fullRadius/15 - fullRadius / 15 ;
                    var theta:Number = i * Math.PI/180;
                    var _x:Number = r * Math.cos(theta) + centre.x;
                    var _y:Number = r * Math.sin(theta) + centre.y;
                    if(i == arcDegreeInterval.end - 1) {
                        highlights.graphics.lineStyle(2, Util.brighten(colour.colour, 0.9), 1, false, LineScaleMode.NORMAL, CapsStyle.NONE);
                    }
                    highlights.graphics.lineTo(_x, _y);
                }

                highlights.graphics.lineStyle(0, 0, 0, false, LineScaleMode.NORMAL, CapsStyle.NONE);

                highlights.graphics.endFill();
            }

            colourIndex++;
        }
    }

    override public function setPlaybackRate(rate:Number):void { trace(this + " setPlaybackRate not implemented"); }
    override public function searchText(string:String):void { trace(this + " searchedText not implemented"); }

    // bitwise or with UserDataViewMode
    override public function setHighlightReadMode(mode:uint):void { trace(this + " setHighlightsViewMode not implemented"); }
    override public function setViewCountRecordReadMode(mode:uint):void { trace(this + " setViewCountRecordViewMode not implemented"); }
    override public function setPauseRecordReadMode(mode:uint):void { trace(this + " setPauseRecordViewMode not implemented"); }
    override public function setPlaybackRateRecordReadMode(mode:uint):void { trace(this + " setPlaybackRateRecordViewMode not implemented"); }

    override public function startPlayingIntervals(intervals:Vector.<Range>):void { trace(this + " startPlayingIntervals not implemented"); }
    override public function stopPlayingIntervals(intervals:Vector.<Range>):void { trace(this + " stopPlayingIntervals not implemented"); }
    override public function startPlayingHighlights(colour:uint):void { trace(this + " startPlayingHighlights not implemented"); }
    override public function stopPlayingHighlights():void { trace(this + " stopPlayingHighlights not implemented"); }
}
}
