////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.myview.ColorUtil;
import ca.ubc.ece.hct.myview.StarlingView;
import ca.ubc.ece.hct.myview.View;

import flash.geom.Point;

import flash.utils.getTimer;

import starling.display.Canvas;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.geom.Polygon;

public class ViewCountRecordBreakdown extends View {


    public function ViewCountRecordBreakdown() {

    }

    public function draw(viewCountRecords:Array):void {

        var vcrBars:Array = [];

        var vcrCounter:Number = 0;
        for each(var vcr:Array in viewCountRecords) {

            var counter:Number = 0;

            for each(var value:Number in vcr) {
//                var hue:int = (vcrCounter % 2) ?
//                        vcrCounter/viewCountRecords.length * 300 :
//                        (150 + vcrCounter/viewCountRecords.length * 300 > 300) ?
//                                -150 + vcrCounter/viewCountRecords.length * 300 : 150 + vcrCounter/viewCountRecords.length * 300;
                var hue:int = vcrCounter/viewCountRecords.length * 300;
                var lightness:int = (vcrCounter % 2) ? 50 : 100;
                var colour:uint = ColorUtil.HSVtoHEX(hue, 100, lightness);

                var bar:VCRBar = new VCRBar(value, colour, 5, (_width- 20) / vcr.length);
                addChild(bar);

                bar.x = counter * (_width- 20) / vcr.length;

                if(!vcrBars[counter]) {
                    vcrBars[counter] = [];
                    vcrBars[counter].push(bar);
//                    trace(bar.height)
                    bar.y = -bar.height
                } else {

                    bar.y = vcrBars[counter][vcrBars[counter].length-1].y - bar.height;
                    vcrBars[counter].push(bar);

                }

                counter++;
            }

            vcrCounter++;
        }
    }

    public function drawV2(viewCountRecords:Array):void {

        var aggregate:Array = [];

        for(var i:int = 0; i<viewCountRecords.length; i++) {
            for(var j:int = 0; j<viewCountRecords[i].length; j++) {
                if(aggregate.length > j) {
                    aggregate[j] += viewCountRecords[i][j];
                } else {
                    aggregate[j] = 1;
                }
            }
        }

        var vcrBars:Array = [];

        var vcrCounter:Number = 0;
        for each(var vcr:Array in viewCountRecords) {

            var counter:Number = 0;

            for each(var value:Number in vcr) {
//                var hue:int = (vcrCounter % 2) ?
//                        vcrCounter/viewCountRecords.length * 300 :
//                        (150 + vcrCounter/viewCountRecords.length * 300 > 300) ?
//                                -150 + vcrCounter/viewCountRecords.length * 300 : 150 + vcrCounter/viewCountRecords.length * 300;
                var hue:int = vcrCounter/viewCountRecords.length * 300;
                var lightness:int = (vcrCounter % 2) ? 50 : 100;
                var colour:uint = ColorUtil.HSVtoHEX(hue, 100, lightness);

//                trace(value/aggregate[counter]*_height);
                var bar:VCRMeanBar = new VCRMeanBar(value/aggregate[counter]*_height, colour, (_width- 20) / vcr.length);
                addChild(bar);

                bar.x = counter * (_width- 20) / vcr.length;

                if(!vcrBars[counter]) {
                    vcrBars[counter] = [];
                    vcrBars[counter].push(bar);
//                    trace(bar.height)
                    bar.y = -bar.supposedHeight
                } else {

                    bar.y = vcrBars[counter][vcrBars[counter].length-1].y - bar.supposedHeight;
                    vcrBars[counter].push(bar);

                }

                counter++;
            }

            vcrCounter++;
        }

        graphics.beginFill(0x666666);
        graphics.drawRect(0, 0, _width, -_height);
        graphics.endFill();
    }
}
}

import ca.ubc.ece.hct.myview.View;

import flash.display.Shape;

class VCRBar extends Shape {

    public function VCRBar(value:Number, colour:Number, scale:Number = 1, w:Number = 5):void {

        graphics.beginFill(colour);
//        trace(w + " " + (value*scale + 1));
        graphics.drawRect(0, 0, w, value*scale > 0 ? value*scale : 1);
        graphics.endFill();

        graphics.lineStyle(1, 0xffffff, 1);
        graphics.moveTo(0, 0);
        graphics.lineTo(w, 0);

//        _width = width;
//        _height = value*scale;
    }
}

class VCRMeanBar extends Shape {

    public var supposedHeight:Number;

    public function VCRMeanBar(value:Number, colour:Number, w:Number = 5):void {

        graphics.beginFill(colour);
        graphics.drawRect(0, 0, w, value > 0 ? value : 1);
        graphics.endFill();

        graphics.lineStyle(1, 0xffffff, 1);
        graphics.moveTo(0, 1);
        graphics.lineTo(w, 1);

        supposedHeight = value;

//        _width = width;
//        _height = value;
    }
}