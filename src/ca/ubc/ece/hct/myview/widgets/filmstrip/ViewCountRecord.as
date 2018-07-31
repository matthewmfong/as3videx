////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.filmstrip {
import ca.ubc.ece.hct.myview.StarlingView;

import flash.display.Bitmap;
import flash.display.BitmapData;

import flash.display.GradientType;

import flash.display.Shape;
import flash.events.ErrorEvent;
import flash.geom.Matrix;

import flash.geom.Point;
import flash.utils.getTimer;

import mx.controls.Text;

import starling.textures.Texture;

//import flash.utils.getTimer;

import starling.display.Canvas;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.geom.Polygon;

public class ViewCountRecord extends StarlingView {

//    private var _backgrounds:Vector.<Quad>;
    private var _background:Quad;
//    private var _mask:Sprite;
//    private var colours:Array;
//    private var alphas:Array;
//    private var ratios:Array;

    private var lastRenderedVCR:Array;

    public function ViewCountRecord() {
        _background = new Quad(1, 1);
//        _mask = new Sprite();
    }

    override protected function addedToStage(e:Event = null):void {
        super.addedToStage(e);

//        _background.mask = _mask;
        addChild(_background);
//        addChild(_mask);
    }

    public function draw(viewCountRecord:Array,
                         startTime:Number = -1, endTime:Number = -1,
                         colours:Array = null,
                         alphas:Array = null,
                         ratios:Array = null):void {

//        var asdf:Number = getTimer();
//
//        if (colours == null) colours = [0xffff00, 0xffff00, 0xffa500, 0xff0000, 0xff0000];
//        if (alphas == null) alphas = [0.8, 0.8, 0.8, 0.8, 0.8];
//        if (ratios == null) ratios = [0, 50, 180, 230, 255];
//
//        if(colours.length != alphas.length && colours.length != ratios.length) {
//            trace("ViewCountRecord.draw(): Array lengths not equal.");
//            trace("colours.length = " + colours.length +
//                    " alphas.length = " + alphas.length +
//                    " ratios.length = " + ratios.length);
//            return;
//        }
//
//        var i:int;
//
//        if(colours != this.colours || alphas != this.alphas || ratios != this.ratios) {
//
//            _background.removeChildren(0, _background.numChildren - 1, true);
//            _backgrounds = new Vector.<Quad>();
//
//            var numColours:int = colours.length;
//
//            for (i = 0; i < numColours - 1; i++) {
//                var quadHeight:Number = _height * (ratios[i + 1] - ratios[i]) / 255;
//                var bg:Quad = new Quad(_width, quadHeight);
//                _backgrounds.push(bg);
//
//                if (i > 0) {
//                    bg.y = _backgrounds[i - 1].y + _backgrounds[i - 1].height;
//                }
//                bg.setVertexColor(0, colours[i]);
//                bg.setVertexColor(1, colours[i]);
//                bg.setVertexColor(2, colours[i + 1]);
//                bg.setVertexColor(3, colours[i + 1]);
//
//                bg.setVertexAlpha(0, alphas[i]);
//                bg.setVertexAlpha(1, alphas[i]);
//                bg.setVertexAlpha(2, alphas[i + 1]);
//                bg.setVertexAlpha(3, alphas[i + 1]);
//
//                _background.addChild(bg);
//            }
//        }
//
//
//
//        var maxViewCount:Number = 1;
//        for (i = 0; i < viewCountRecord.length; i++) {
//            if (viewCountRecord[i] > maxViewCount) {
//                maxViewCount = viewCountRecord[i];
//            }
//        }
//
////        maxViewCount += 5;
//
//        var graphHeight:Number;
//        var graphMaxHeight:Number = _height;
//
//        var forStart:uint = startTime == -1 ? 0 : startTime;
//        forStart = Math.max(0, Math.min(viewCountRecord.length - 1, forStart));
//        startTime = startTime == -1 ? 0 : startTime;
//
//        var forEnd:uint = endTime == -1 ? viewCountRecord.length : endTime;
//        forEnd = Math.max(0, Math.min(viewCountRecord.length, forEnd));
//        endTime = endTime == -1 ? viewCountRecord.length : endTime;
//
////        var timer:Number = getTimer();
//
//        var quad:Quad;
//        var numQuads:Number = forEnd - forStart + 1;
//
//        if (_mask.numChildren < numQuads) {
//            for (i = _mask.numChildren; i < numQuads + 1; i++) {
//                quad = new Quad(1, 1);
//                quad.touchable = false;
//                _mask.addChild(quad);
//            }
//        }
//
////        var poly:Polygon = new Polygon();
////        poly.addVertices(0, _height,
////                (-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width, 0);
//
//        var calc:Number;
//        var lastVertex:Point = new Point((-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width, 0);
//        for (i = forStart; i < forEnd; i++) {
//
////            calc = viewCountRecord[i] / maxViewCount * _height;
//
//            calc = (Math.log(viewCountRecord[i] / maxViewCount + Math.pow(Math.E, -1.5)) + 1.5) /
//                    (Math.log(1 + Math.pow(Math.E, -1.5)) + 1.5) *
//                    graphMaxHeight;
//
//            graphHeight = Math.min(graphMaxHeight, calc);
//
//            var newVertex:Point = new Point(
//                    int((i + 0.5 - uint(startTime)) / (uint(endTime) - uint(startTime)) * _width),
//                    int(graphMaxHeight - graphHeight));
//
////            trace(i + " " + _mask.numChildren + " " + numQuads + " " +forStart + " " + forEnd);
//            quad = (Quad)(_mask.getChildAt(i - forStart));
//
//            quad.setVertexPosition(0, lastVertex.x, lastVertex.y);
//            quad.setVertexPosition(1, newVertex.x, newVertex.y);
//            quad.setVertexPosition(2, lastVertex.x, _height);
//            quad.setVertexPosition(3, newVertex.x, _height);
//            quad.alpha = 1;
//
//            lastVertex = newVertex;
//
//        }
//
//        // hide the extra quads.
//        for(i = forEnd; i<_mask.numChildren; i++) {
//            quad = (Quad)(_mask.getChildAt(i - forStart));
//
//            if(quad.alpha != 0) {
//
//                quad.setVertexPosition(0, 0, 0);
//                quad.setVertexPosition(1, 1, 0);
//                quad.setVertexPosition(2, 0, 1);
//                quad.setVertexPosition(3, 1, 1);
//
//                quad.alpha = 0;
//            }
//        }


//        trace("VCR drawtime: " + (getTimer() - timer));

//        poly.addVertices(_width, _height);
//        poly.addVertices(0, _height);

//        trace("numQuads = " + numQuads);

//        _mask.clear();
//        _mask.beginFill(0xff0000);
//        _mask.drawPolygon(poly);
//        _mask.endFill();

//        trace("_____________");
//        lastRenderedVCR = viewCountRecord;

        var maxViewCount:Number = 1;
        for (var i:int = 0; i < viewCountRecord.length; i++) {
            if (viewCountRecord[i] > maxViewCount) {
                maxViewCount = viewCountRecord[i];
            }
        }

        maxViewCount += 5;

        var graphMaxHeight:int = _height;

        var viewCountRecordSprite:Shape = new Shape();
        viewCountRecordSprite.graphics.clear();
        viewCountRecordSprite.graphics.beginFill(0xff0000, 0);
        viewCountRecordSprite.graphics.drawRect(0, 0, _width, graphMaxHeight);
        viewCountRecordSprite.graphics.endFill();

        var graphHeight:Number;

        if (colours == null) colours = [0xffff00, 0xffff00, 0xffa500, 0xff0000, 0xff0000];
        if (alphas == null) alphas = [1, 1, 1, 1, 1];
        if (ratios == null) ratios = [0, 50, 180, 230, 255];
        var matr:Matrix = new Matrix;
        matr.createGradientBox(_width, graphMaxHeight, Math.PI / 2, 0, 0);
        viewCountRecordSprite.graphics.beginGradientFill(GradientType.LINEAR,
                colours, // colour
                alphas,  // alpha
                ratios, // ratio
                matr);

//        viewCountRecordSprite.graphics.lineStyle(0.1, 0x777777);
        viewCountRecordSprite.graphics.moveTo(0, graphMaxHeight);
        var forStart:uint = startTime;
        forStart = Math.max(0, Math.min(viewCountRecord.length - 1, forStart));
        var forEnd:uint = endTime;
        forEnd = Math.max(0, Math.min(viewCountRecord.length - 1, forEnd));

        viewCountRecordSprite.graphics.lineTo((-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
                graphMaxHeight - graphHeight)

        var calc:Number;
        for (var i:int = forStart; i < forEnd; i++) {

            calc = (Math.log(viewCountRecord[i] / maxViewCount + Math.pow(Math.E, -1.5)) + 1.5) /
                    (Math.log(1 + Math.pow(Math.E, -1.5)) + 1.5) *
                    graphMaxHeight;

            graphHeight = Math.min(graphMaxHeight, calc);

            viewCountRecordSprite.graphics.lineTo((i + 0.5 - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
                    graphMaxHeight - graphHeight)
        }
        viewCountRecordSprite.graphics.lineTo((forEnd - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
                graphMaxHeight - graphHeight)
        viewCountRecordSprite.graphics.lineTo(_width, graphMaxHeight);
        viewCountRecordSprite.graphics.lineTo(calc, graphMaxHeight);

        var bmpD:BitmapData = new BitmapData(viewCountRecordSprite.width, viewCountRecordSprite.height, true, 0x000000);
        bmpD.draw(viewCountRecordSprite);

        _background.readjustSize(viewCountRecordSprite.width, viewCountRecordSprite.height);
        _background.texture = Texture.fromBitmapData(bmpD, false, false, 1, "bgra", false,
                function(texture:Texture, error:ErrorEvent):void { });
    }
}
}


//////////////////////////////////////////////////////////////////////////
////                                                                    //
////  Author: Matthew Fong                                              //
////          Human Communication Laboratories - http://hct.ece.ubc.ca  //
////          The University of British Columbia                        //
////                                                                    //
//////////////////////////////////////////////////////////////////////////
//
//package ca.ubc.ece.hct.myview.widgets.filmstrip {
//import ca.ubc.ece.hct.myview.StarlingView;
//
//import flash.geom.Point;
//
//import flash.utils.getTimer;
//
//import starling.display.Canvas;
//import starling.display.Quad;
//import starling.display.Sprite;
//import starling.events.Event;
//import starling.geom.Polygon;
//
//public class ViewCountRecord extends StarlingView {
//
//    private var _backgrounds:Vector.<Quad>;
//    private var _background:Sprite;
//    private var _mask:Canvas;
//    private var colours:Array;
//    private var alphas:Array;
//    private var ratios:Array;
//
//    private var lastRenderedVCR:Array;
//
//    public function ViewCountRecord() {
//        _background = new Sprite();
//        _mask = new Canvas();
//    }
//
//    override protected function addedToStage(e:Event = null):void {
//        super.addedToStage(e);
//
//        _background.mask = _mask;
//        addChild(_background);
//        addChild(_mask);
//    }
//
//    public function draw(viewCountRecord:Array,
//                         startTime:Number = -1, endTime:Number = -1,
//                         colours:Array = null,
//                         alphas:Array = null,
//                         ratios:Array = null):void {
//
//        if (colours == null) colours = [0xffff00, 0xffff00, 0xffa500, 0xff0000, 0xff0000];
//        if (alphas == null) alphas = [0.8, 0.8, 0.8, 0.8, 0.8];
//        if (ratios == null) ratios = [0, 50, 180, 230, 255];
//
//        if(colours.length != alphas.length && colours.length != ratios.length) {
//            trace("ViewCountRecord.draw(): Array lengths not equal.");
//            trace("colours.length = " + colours.length +
//                    " alphas.length = " + alphas.length +
//                    " ratios.length = " + ratios.length);
//            return;
//        }
//
//        var i:int;
//
//        if(colours != this.colours || alphas != this.alphas || ratios != this.ratios) {
//
//            _background.removeChildren(0, _background.numChildren - 1, true);
//            _backgrounds = new Vector.<Quad>();
//
//            var numColours:int = colours.length;
//
//            for (i = 0; i < numColours - 1; i++) {
//                var quadHeight:Number = _height * (ratios[i + 1] - ratios[i]) / 255;
//                var bg:Quad = new Quad(_width, quadHeight);
//                _backgrounds.push(bg);
//
//                if (i > 0) {
//                    bg.y = _backgrounds[i - 1].y + _backgrounds[i - 1].height;
//                }
//                bg.setVertexColor(0, colours[i]);
//                bg.setVertexColor(1, colours[i]);
//                bg.setVertexColor(2, colours[i + 1]);
//                bg.setVertexColor(3, colours[i + 1]);
//
//                bg.setVertexAlpha(0, alphas[i]);
//                bg.setVertexAlpha(1, alphas[i]);
//                bg.setVertexAlpha(2, alphas[i + 1]);
//                bg.setVertexAlpha(3, alphas[i + 1]);
//
//                _background.addChild(bg);
//            }
//        }
//
//
//
//        var maxViewCount:Number = 1;
//        for (i = 0; i < viewCountRecord.length; i++) {
//            if (viewCountRecord[i] > maxViewCount) {
//                maxViewCount = viewCountRecord[i];
//            }
//        }
//
////        maxViewCount += 5;
//
//        var graphHeight:Number;
//        var graphMaxHeight:Number = _height;
//
//        var forStart:uint = startTime == -1 ? 0 : startTime;
//        forStart = Math.max(0, Math.min(viewCountRecord.length - 1, forStart));
//        startTime = startTime == -1 ? 0 : startTime;
//
//        var forEnd:uint = endTime == -1 ? viewCountRecord.length : endTime;
//        forEnd = Math.max(0, Math.min(viewCountRecord.length, forEnd));
//        endTime = endTime == -1 ? viewCountRecord.length : endTime;
//
//        var poly:Polygon = new Polygon();
//        poly.addVertices(0, _height,
//                (-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width, 0);
//
//
//        var calc:Number;
//        var lastVertex:Point = new Point((-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width, 0)
//        for (i = forStart; i < forEnd; i++) {
//
////            calc = viewCountRecord[i] / maxViewCount * _height;
//
//            calc = (Math.log(viewCountRecord[i] / maxViewCount + Math.pow(Math.E, -1.5)) + 1.5) /
//                    (Math.log(1 + Math.pow(Math.E, -1.5)) + 1.5) *
//                    graphMaxHeight;
//
//            graphHeight = Math.min(graphMaxHeight, calc);
//
//            var newVertex:Point = new Point(
//                    int((i + 0.5 - uint(startTime)) / (uint(endTime) - uint(startTime)) * _width),
//                    int(graphMaxHeight - graphHeight));
//
//            if(lastVertex.y == newVertex.y) {
//                poly.setVertex(poly.numVertices - 1, newVertex.x, newVertex.y);
//            } else {
//                poly.addVertices(newVertex.x, newVertex.y);
//            }
//
//        }
//
//        poly.addVertices(_width, _height);
//        poly.addVertices(0, _height);
//
//        trace(_width + " " + (forEnd - forStart));
//
//        trace(poly.numVertices + " " + poly.numTriangles);
//        trace("_____________");
//        var aasdf:Number = getTimer();
//        _mask.clear();
//        _mask.beginFill(0xff0000);
//        _mask.drawPolygon(poly);
//        _mask.endFill();
//
//        trace(getTimer() - aasdf);
//        trace("_____________");
//        lastRenderedVCR = viewCountRecord;
//    }
//}
//}

