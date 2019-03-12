package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.View;
import ca.ubc.ece.hct.myview.ui.FloatingTextField;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import feathers.motion.Slide;

import flash.display.Shape;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.getTimer;

import mx.controls.Text;

import org.osflash.signals.Signal;

public class InstructorViewCountRecordSprite extends View {

    private var _video:VideoMetadata;
    private var viewCountRecordSprite:Shape;
    private var highlightSprite:Shape;
    private var axis:Shape;
    private var cursor:Shape;
    private var floatingTime:FloatingTextField;
    private var axisLabels:Sprite;

    private var aggregateVCR:Array;

//    private var slideLocations:Shape;
    private var slides:Vector.<SlideMarker>;
    private var editMode:Boolean;

    public var slideEdited:Signal;

    public function InstructorViewCountRecordSprite(w:Number, h:Number) {
        _width = w;
        _height = h;

        axis = new Shape();
        addChild(axis);

        viewCountRecordSprite = new Shape();
        addChild(viewCountRecordSprite);

        highlightSprite = new Shape();
        addChild(highlightSprite);

        cursor = new Shape();
        cursor.graphics.lineStyle(1, 0xff0000);
        cursor.graphics.moveTo(0, 0);
        cursor.graphics.lineTo(0, _height);

        floatingTime = new FloatingTextField();

        axisLabels = new Sprite();
        addChild(axisLabels);

//        slideLocations = new Shape();
//        addChild(slideLocations);

        slides = new Vector.<SlideMarker>();
        editMode = false;

        slideEdited = new Signal();


        addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
        addEventListener(MouseEvent.ROLL_OUT, rollOut);
    }

    public function set video(v:VideoMetadata):void {
        _video = v;

        for(var i:int = 0; i<v.slides.length; i++) {
            var slide:SlideMarker = new SlideMarker();
            slide.timestamp = v.slides[i];
            slide.draw(_height);
            slide.x = v.slides[i]/v.duration * _width;
            addChild(slide);

            slide.click.add(deleteSlide);

            slides.push(slide);
        }
    }

    public function drawViewCountRecord(viewCountRecords:Vector.<Vector.<Number>>, allTimeMaxViewCount:Number, allTimeAggregateMaxViewCount:Number):void {

        drawBackground();

        drawAxes(allTimeMaxViewCount, allTimeAggregateMaxViewCount);

        aggregateVCR = [];

        var maxViewCount:Number = allTimeMaxViewCount;

        var graphMaxHeight:int = _height;
        var graphHeight:Number = 0;

        viewCountRecordSprite.graphics.clear();

        for each(var viewCountRecord:Vector.<Number> in viewCountRecords) {

//            var viewCountRecord:Array = data.viewCountRecord;

            if(viewCountRecord.length > 0) {


                viewCountRecordSprite.graphics.beginFill(0xaaaaaa, 0.3);

//                viewCountRecordSprite.graphics.lineStyle(0.1, 0x777777);
                viewCountRecordSprite.graphics.moveTo(0, graphMaxHeight);

                var calc:Number;
                for (var i:int = 0; i < viewCountRecord.length; i++) {


                    if(aggregateVCR[i] || aggregateVCR[i] == 0) {
                        aggregateVCR[i] += viewCountRecord[i];
                    } else {
                        aggregateVCR.push(viewCountRecord[i]);
                    }
//
//                    aggregateMaxViewCount = Math.max(aggregateMaxViewCount, aggregateVCR[i]);

                    calc = viewCountRecord[i] / maxViewCount * graphMaxHeight;


                    viewCountRecordSprite.graphics.lineTo(((i + 0.5) / _video.duration) * _width,
                            graphMaxHeight - calc)
                }

//                trace("A: " + aggregateVCR + "\n");
                viewCountRecordSprite.graphics.lineTo(_width, graphMaxHeight);

                viewCountRecordSprite.graphics.lineTo(0, graphMaxHeight);
            }

//            trace(data.viewCountRecord);
        }

        viewCountRecordSprite.graphics.endFill();

        viewCountRecordSprite.graphics.lineStyle(1, 0x00ff00, 0.5)
//        viewCountRecordSprite.graphics.beginFill(0x00ff00, 0.1);
        viewCountRecordSprite.graphics.lineTo(0, graphMaxHeight);

//        trace(aggregateVCR);
        for(var i:int = 0; i<aggregateVCR.length; i++) {

//            trace("fack" + aggregateVCR[i] + " " + allTimeAggregateMaxViewCount)
            var calc:Number = aggregateVCR[i] / allTimeAggregateMaxViewCount * graphMaxHeight;


            viewCountRecordSprite.graphics.lineTo((i + 0.5) / _video.duration * _width,
                    graphMaxHeight - calc)

        }

        viewCountRecordSprite.graphics.lineTo(_width, graphMaxHeight);
        viewCountRecordSprite.graphics.lineTo(0, graphMaxHeight);
//        viewCountRecordSprite.graphics.endFill();
//        viewCountRecordSprite.graphics.lineTo(calc, graphMaxHeight);

    }

    public function drawViewCountRecordFromUserDatas(userdatas:Vector.<UserData>, allTimeMaxViewCount:Number, allTimeAggregateMaxViewCount:Number):void {

        var viewCountRecords:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();

        for each(var userData:UserData in userdatas) {
            viewCountRecords.push(userData.viewCountRecord)
        }

        drawViewCountRecord(viewCountRecords, allTimeMaxViewCount, allTimeAggregateMaxViewCount);

    }

    public function drawAxes(allTimeMaxViewCount:Number, allTimeAggregateMaxViewCount:Number):void {

        axis.graphics.clear();
        axis.graphics.lineStyle(1, 0xcccccc);

        // one line for every view count
        var gap:Number = _height / allTimeMaxViewCount;
        while(_height/gap > 10) {
            gap *= 2;
        }

        if(contains(axisLabels) && axisLabels) {
            removeChild(axisLabels);
            axisLabels = new Sprite();
            addChild(axisLabels);
        }
        var counter:Number = 0;
        for(var i:int = _height; i>0; i-=gap) {
            axis.graphics.moveTo(0, i);
            axis.graphics.lineTo(_width, i);

            var textfield:TextField = new TextField();
            textfield.mouseEnabled = false;
            textfield.defaultTextFormat = new TextFormat("Arial", 10, 0x999999);
            textfield.autoSize = TextFieldAutoSize.LEFT;
            textfield.text = Math.round((_height - i)/_height*allTimeMaxViewCount).toString();
            axisLabels.addChild(textfield);
            textfield.y = i - textfield.height;

            textfield = new TextField();
            textfield.mouseEnabled = false;
            textfield.autoSize = TextFieldAutoSize.RIGHT;
            textfield.defaultTextFormat = new TextFormat("Arial", 10, 0x00ff00);
            textfield.text = Math.round((_height - i)/_height*allTimeAggregateMaxViewCount).toString();
            axisLabels.addChild(textfield);
            textfield.x = _width - textfield.width;
            textfield.y = i - textfield.height;

        }
    }

    public function drawHighlights():void {


        var maxViewCount:Number = 1;
        var highlightsHeight:Number = 8;

        var startTime:Number = 0;
        var endTime:Number = _video.duration;

        var i:int;

        var crowdHighlights:Vector.<Number> = _video.currentClassCrowdHighlights;
//        trace(_video.crowdHighlights.length);
        for(i = 0; i<crowdHighlights.length; i++) {
            maxViewCount = Math.max(maxViewCount,crowdHighlights[i]);
        }

//        trace(crowdHighlights)

        highlightSprite.graphics.clear();
//        highlightSprite.graphics.beginFill(0x222222, 0.8);
//        highlightSprite.graphics.drawRect(0, 0, _width, highlightsHeight);
//        highlightSprite.graphics.endFill();
        for(i = 0; i<crowdHighlights.length; i++) {
            var transparency:Number = crowdHighlights[i]/maxViewCount == 0 ? 0 : (crowdHighlights[i]/maxViewCount) * 0.7 + 0.3;
            highlightSprite.graphics.beginFill(0x00cc00, transparency);
            highlightSprite.graphics.drawRect((i - uint(startTime))/(uint(endTime+1) - uint(startTime)) * _width, 0,
                    (1 - uint(startTime))/(uint(endTime+1) - uint(startTime)) * _width, highlightsHeight);
            highlightSprite.graphics.endFill();
        }

    }

    public function setEditMode(editMode:Boolean):void {
        this.editMode = editMode;

        if(editMode) {
            if(!hasEventListener(MouseEvent.CLICK)) {
                addEventListener(MouseEvent.CLICK, addSlide);
            }
        } else {
            if(hasEventListener(MouseEvent.CLICK))
                removeEventListener(MouseEvent.CLICK, addSlide);
        }

        drawBackground();
    }

    public function addSlide(e:MouseEvent):void {

        if(e.target == this) {

            var slide:SlideMarker = new SlideMarker();
            slide.timestamp = e.currentTarget.mouseX/_width * _video.duration;
            slide.draw(_height);
            slide.x = e.currentTarget.mouseX;
            addChild(slide);

            _video.slides.push(Math.round(slide.timestamp * 10)/10);
            _video.slides.sort(Array.NUMERIC);

            trace(_video.slides);

            slides.push(slide);

            slideEdited.dispatch();
        }
    }

    private function deleteSlide(slide:SlideMarker):void {
        _video.slides.removeAt(_video.slides.indexOf(slide.timestamp));
        removeChild(slide);
        slides.removeAt(slides.indexOf(slide));
        slideEdited.dispatch();
    }

    public function drawBackground():void {
        graphics.clear();
        if(editMode) {
            graphics.lineStyle(3, 0xff0000);
        }
        graphics.beginFill(0xffffff);
        graphics.drawRect(0, 0, _width, _height);
        graphics.endFill();
    }

    private function mouseMove(e:MouseEvent):void {

        if(!contains(cursor)) {
            addChild(cursor);
        }

        if(!contains(floatingTime)) {
            addChild(floatingTime);
        }

        cursor.x = e.currentTarget.mouseX;
        floatingTime.x = e.currentTarget.mouseX - floatingTime.width - 2;
        floatingTime.y = e.currentTarget.mouseY;

        floatingTime.text = Util.timeInSecondsToTimeString(e.currentTarget.mouseX / _width * _video.duration);
    }

    private function rollOut(e:MouseEvent):void {

        if(contains(cursor)) {
            removeChild(cursor);
        }

        if(contains(floatingTime)) {
            removeChild(floatingTime);
        }
    }
}
}

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.ui.Mouse;

import org.osflash.signals.Signal;

class SlideMarker extends Sprite {
    public var timestamp:Number;
    private var _height:Number;
    public var click:Signal;

    public function SlideMarker(timestamp:Number = 0) {
        this.timestamp = timestamp;
        click = new Signal(SlideMarker);
        addEventListener(MouseEvent.ROLL_OVER, rolledOver);
        addEventListener(MouseEvent.ROLL_OUT, rolledOut);
        addEventListener(MouseEvent.CLICK, clicked);
    }

    public function draw(h:Number):void {
        _height = h;
        drawNormal();
    }

    private function rolledOver(e:MouseEvent):void {
        drawRollOver();
    }

    private function rolledOut(e:MouseEvent):void {
        drawNormal();
    }

    private function clicked(e:MouseEvent):void {
        trace("hm really?");
        click.dispatch(this);
    }

    private function drawNormal():void {
        graphics.clear();
        graphics.beginFill(0);
        graphics.drawRect(0, 0, 3, _height);
        graphics.endFill();
    }

    private function drawRollOver():void {
        graphics.clear();
        graphics.beginFill(0xff0000);
        graphics.drawRect(0, 0, 3, _height);
        graphics.endFill();
        graphics.lineStyle(3, 0xff0000);
        graphics.moveTo(-11, 0);
        graphics.lineTo(11, 12);
        graphics.moveTo(11, 0);
        graphics.lineTo(-11, 12);
    }
}
