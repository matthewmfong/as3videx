package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.ColorUtil;
import ca.ubc.ece.hct.myview.Colours;
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

public class InstructorViewCountRecordSpriteV2 extends View {

    private var _video:VideoMetadata;
    private var graph:Sprite;
    private var aggregateViewCountRecordSprite:Shape;
    private var meanViewCountRecordSprite:Shape;
    private var maxViewCountRecordSprite:Shape;
    private var medianViewCountRecordSprite:Shape;
    private var highlightSprite:Shape;
    private var axis:Shape;
    private var cursor:Shape;
    private var floatingTime:FloatingTextField;
    private var floatingWindow:FloatingWindow;
    private var axisLabels:Sprite;

    private var aggregateVCR:Vector.<Number>;
    private var stackedVCRs:Vector.<ViewCountStackingShapes>;
    private var userDatas:Vector.<UserData>;

    private var slides:Vector.<SlideMarker>;
    private var editMode:Boolean;

    public var slideEdited:Signal;

    public function InstructorViewCountRecordSpriteV2(w:Number, h:Number) {
        _width = w;
        _height = h;

        graph = new Sprite();
        addChild(graph);

        axis = new Shape();
        graph.addChild(axis);

        aggregateViewCountRecordSprite = new Shape();
        graph.addChild(aggregateViewCountRecordSprite);

        highlightSprite = new Shape();
        graph.addChild(highlightSprite);

        meanViewCountRecordSprite = new Shape();
        graph.addChild(meanViewCountRecordSprite);

        maxViewCountRecordSprite = new Shape();
        graph.addChild(maxViewCountRecordSprite);

        medianViewCountRecordSprite = new Shape();
        graph.addChild(medianViewCountRecordSprite);

        cursor = new Shape();
        cursor.graphics.lineStyle(1, 0xff0000);
        cursor.graphics.moveTo(0, 0);
        cursor.graphics.lineTo(0, _height);

        floatingTime = new FloatingTextField();
        floatingWindow = new FloatingWindow();

        axisLabels = new Sprite();
        graph.addChild(axisLabels);

        slides = new Vector.<SlideMarker>();
        editMode = false;

        slideEdited = new Signal();

        stackedVCRs = new Vector.<ViewCountStackingShapes>();


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
            graph.addChild(slide);

            slide.click.add(deleteSlide);

            slides.push(slide);
        }
    }

    private function drawViewCountRecord(viewCountRecords:Vector.<Vector.<Number>>,
                                         includeIndices:Vector.<uint>,
                                         showAggregate:Boolean = true,
                                         showMean:Boolean = true,
                                         showMedian:Boolean = true,
                                         showMax:Boolean = true):void {

        drawBackground();

        var i:int;
        var vcrShape:ViewCountStackingShapes;
        var mean:Vector.<Number> = new Vector.<Number>();
        var max:Vector.<Number> = new Vector.<Number>();
        var median:Vector.<Number> = calculateMedianViewCounts(viewCountRecords);
        var maxViewCount:Number = 0;
        var maxAggregateViewCount:Number = 0;
        aggregateVCR = new Vector.<Number>();

        for (i = 0; i < _video.duration + 1; i++) {
            aggregateVCR.push(0);
            mean.push(0);
            max.push(0);
            median.push(0);
        }

        while(stackedVCRs.length > 0) {
            vcrShape = stackedVCRs.pop();
            if(graph.contains(vcrShape) && vcrShape) {
                graph.removeChild(vcrShape);
            }
        }

//        var maxViewCount:Number = allTimeMaxViewCount;

        var graphMaxHeight:int = _height;
//        var graphHeight:Number = 0;

        aggregateViewCountRecordSprite.graphics.clear();
        maxViewCountRecordSprite.graphics.clear();
        meanViewCountRecordSprite.graphics.clear();
        medianViewCountRecordSprite.graphics.clear();

//        trace(excludeIndices);
        for each(var viewCountRecord:Vector.<Number> in viewCountRecords) {
            if(viewCountRecord.length > 0) {
                for (i = 0; i < viewCountRecord.length; i++) {
                    aggregateVCR[i] += viewCountRecord[i];
                    mean[i] += viewCountRecord[i];
                    max[i] = Math.max(max[i], viewCountRecord[i]);
                    maxViewCount = Math.max(max[i], maxViewCount);
                }
            }
        }

        var index:int = 0;
        for each(var vcr:Vector.<Number> in viewCountRecords) {
            if(vcr.length > 0) {
                if (includeIndices.indexOf(index) != -1) {
                    vcrShape = new ViewCountStackingShapes(vcr,
                            aggregateVCR,
                            ColorUtil.HSVtoHEX(index / viewCountRecords.length * 300, 70, 100),
                            _width,
                            _height / maxViewCount,
                            _height);
                    graph.addChild(vcrShape);

                    stackedVCRs.push(vcrShape);
                }
            }
            index++;
        }

        for(i=0; i<aggregateVCR.length; i++) {
            maxAggregateViewCount = Math.max(maxAggregateViewCount, aggregateVCR[i]);
        }


        drawAxes(maxViewCount, maxAggregateViewCount);

        for(i= 0; i<mean.length; i++) {
            mean[i] /= viewCountRecords.length;
        }

        if(showAggregate || showMean || showMax || showMedian) {
            aggregateViewCountRecordSprite.graphics.lineStyle(2, Colours.DASHBOARD_VCR_GRAPH_AGGREGATE_COLOUR, 0.5);
            aggregateViewCountRecordSprite.graphics.moveTo(0, graphMaxHeight - aggregateVCR[0] / maxAggregateViewCount * graphMaxHeight);
            meanViewCountRecordSprite.graphics.lineStyle(2, Colours.DASHBOARD_VCR_GRAPH_MEAN_COLOUR);
            meanViewCountRecordSprite.graphics.moveTo(0, graphMaxHeight - mean[0] / maxViewCount * graphMaxHeight);
            maxViewCountRecordSprite.graphics.lineStyle(2, Colours.DASHBOARD_VCR_GRAPH_MAX_COLOUR);
            maxViewCountRecordSprite.graphics.moveTo(0, graphMaxHeight - max[0] / maxViewCount * graphMaxHeight);
            medianViewCountRecordSprite.graphics.lineStyle(2, Colours.DASHBOARD_VCR_GRAPH_MEDIAN_COLOUR);
            medianViewCountRecordSprite.graphics.moveTo(0, graphMaxHeight - median[0] / maxViewCount * graphMaxHeight);

            var calc:Number = 0;
            for (i = 0; i < aggregateVCR.length; i++) {

                if(showAggregate) {
                    calc = aggregateVCR[i] / maxAggregateViewCount * graphMaxHeight;
                    aggregateViewCountRecordSprite.graphics.lineTo((i + 0.5) / _video.duration * _width,
                            graphMaxHeight - calc);
                }

                if(showMean) {
                    calc = mean[i] / maxViewCount * graphMaxHeight;
                    meanViewCountRecordSprite.graphics.lineTo((i + 0.5) / _video.duration * _width,
                            graphMaxHeight - calc);
                }

                if(showMax) {
                    calc = max[i] / maxViewCount * graphMaxHeight;
                    maxViewCountRecordSprite.graphics.lineTo((i + 0.5) / _video.duration * _width,
                            graphMaxHeight - calc);
                }

                if(showMedian) {
                    calc = median[i] / maxViewCount * graphMaxHeight;
                    medianViewCountRecordSprite.graphics.lineTo((i + 0.5) / _video.duration * _width,
                            graphMaxHeight - calc);
                }

            }

            aggregateViewCountRecordSprite.graphics.lineStyle(NaN);
            aggregateViewCountRecordSprite.graphics.lineTo(_width, graphMaxHeight);
            aggregateViewCountRecordSprite.graphics.lineTo(0, graphMaxHeight);
        }

    }

    public function drawViewCountRecordFromUserDatas(userdatas:Vector.<UserData>,
                                                     userDrawList:Vector.<String>,
                                                     showAggregate:Boolean = true,
                                                     showMean:Boolean = true,
                                                     showMedian:Boolean = true,
                                                     showMax:Boolean = true):void {

        var viewCountRecords:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
        this.userDatas = userdatas;

        for each(var userData:UserData in userdatas) {
            viewCountRecords.push(userData.viewCountRecord)
        }

        var includeIndices:Vector.<uint> = new Vector.<uint>();
        for(var i:int = 0; i<userDrawList.length; i++) {

            for(var userDataIndex:int = 0; userDataIndex<userdatas.length; userDataIndex++) {

                if(userdatas[userDataIndex].userString == userDrawList[i]) {
                    includeIndices.push(userDataIndex);
                }
            }
        }

        drawViewCountRecord(viewCountRecords, includeIndices,
                showAggregate, showMean, showMedian, showMax);

    }

    public function drawAxes(allTimeMaxViewCount:Number, allTimeAggregateMaxViewCount:Number):void {

        axis.graphics.clear();
        axis.graphics.lineStyle(1, 0xcccccc);

        // one line for every view count
        var gap:Number = _height / allTimeMaxViewCount;
        while(_height/gap > 10) {
            gap *= 2;
        }

        if(graph.contains(axisLabels) && axisLabels) {
            graph.removeChild(axisLabels);
            axisLabels = new Sprite();
            graph.addChild(axisLabels);
        }
//        var counter:Number = 0;
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
            if(hasEventListener(MouseEvent.CLICK)) {
                removeEventListener(MouseEvent.CLICK, addSlide);
            }
        }

        drawBackground();
    }

    public function addSlide(e:MouseEvent):void {

        if(e.target == this || e.target == graph) {

            var slide:SlideMarker = new SlideMarker();
            slide.timestamp = e.currentTarget.mouseX/_width * _video.duration;
            slide.draw(_height);
            slide.x = e.currentTarget.mouseX;
            slide.click.add(deleteSlide);
            graph.addChild(slide);

            _video.slides.push(Math.round(slide.timestamp * 10)/10);
            _video.slides.sort(Array.NUMERIC);

//            trace(_video.slides);

            slides.push(slide);

            slideEdited.dispatch();
        }
    }

    private function deleteSlide(slide:SlideMarker):void {
        trace("lol");
        _video.slides.removeAt(_video.slides.indexOf(slide.timestamp));
        graph.removeChild(slide);
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

        if(!graph.contains(cursor)) {
            graph.addChild(cursor);
        }

        if(!graph.contains(floatingTime)) {
            graph.addChild(floatingTime);
        }

        if(!graph.contains(floatingWindow)) {
            graph.addChild(floatingWindow);
        }

        var time:Number = e.currentTarget.mouseX / _width * _video.duration;

        cursor.x = e.currentTarget.mouseX;
        floatingTime.x = e.currentTarget.mouseX - floatingTime.width - 2;
        floatingTime.y = e.currentTarget.mouseY;

        floatingTime.text = Util.timeInSecondsToTimeString(time);

//        floatingWindow.show(userDatas, Math.floor(time));
//        floatingWindow.x = e.currentTarget.mouseX - floatingTime.width - 2;
//        floatingWindow.y = e.currentTarget.mouseY;

        for each(var vcrShape:ViewCountStackingShapes in stackedVCRs) {
            vcrShape.showTime(e.currentTarget.mouseX / _width * _video.duration);
        }
    }

    private function rollOut(e:MouseEvent):void {

        if(graph.contains(cursor)) {
            graph.removeChild(cursor);
        }

        if(graph.contains(floatingTime)) {
            graph.removeChild(floatingTime);
        }

        for each(var vcrShape:ViewCountStackingShapes in stackedVCRs) {
            vcrShape.showTime(-1);
        }
    }

    private function calculateMedianViewCounts(vcrs:Vector.<Vector.<Number>>):Vector.<Number> {

        var median:Vector.<Number> = new Vector.<Number>();

        for(var i:int = 0; i<_video.duration; i++) {
            var counts:Vector.<Number> = new Vector.<Number>();

            for each(var vcr:Vector.<Number> in vcrs) {

                if(i+1 < vcr.length) {
                    counts.push(vcr[i]);
                } else {
                    counts.push(0);
                }
            }


            counts.sort(Array.NUMERIC);
            if(counts.length > 0) {
                if (counts.length % 2 == 0) {
                    median.push((counts[counts.length / 2 - 1] + counts[counts.length / 2]) / 2);
                } else {
                    median.push(counts[Math.floor(counts.length / 2)]);
                }
            } else {
                median.push(0);
            }
        }

        return median;
    }
}
}

import ca.ubc.ece.hct.myview.ColorUtil;
import ca.ubc.ece.hct.myview.Constants;
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.dashboard.UsersDictionary;
import ca.ubc.ece.hct.myview.dashboard.UsersDictionary;

import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
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

class ViewCountStackingShapes extends Sprite {
    public var viewCount:Vector.<Number>;
    public var aggregateVCR:Vector.<Number>;

    public var timeMarker:Shape;

    private var _width:Number, _height:Number, _heightRatio:Number;

    public function ViewCountStackingShapes(viewCount:Vector.<Number>, aggregateVCR:Vector.<Number>,
                                            colour:Number,
                                            width:Number,
                                            heightRatio:Number,
                                            height:Number) {

        mouseEnabled = false;

        this.viewCount = viewCount;
        this.aggregateVCR = aggregateVCR;
        _width = width;
        _height = height;
        _heightRatio = heightRatio;

        var rectangleWidth:Number = width/viewCount.length;
//        var asdf:String = "";

        graphics.beginFill(colour, 0.2);
        graphics.moveTo(0, height);
        graphics.lineStyle(1, colour);
        for(var i:int = 0; i<viewCount.length; i++) {

            graphics.lineTo(i*rectangleWidth, height - viewCount[i] * heightRatio);
//            var x:Number = i * rectangleWidth;
//            var y:Number = height - aggregateVCR[i] * heightRatio - viewCount[i] * heightRatio;
//            var w:Number = rectangleWidth;
//            var h:Number = viewCount[i] * heightRatio;
////
//            graphics.moveTo(x, y);
//            graphics.lineTo(x, y + h);
////            graphics.lineStyle(0);
//            graphics.lineTo(x + w, y + h);
////            graphics.lineStyle(NaN);
//            graphics.lineTo(x + w, y);
////            graphics.lineStyle(0);
//            graphics.lineTo(x, y);
////            graphics.lineStyle(NaN);
////            graphics.drawRect(x, y, w, h);
////            graphics.drawRect(
////                    i * rectangleWidth,
////                    height - aggregateVCR[i] * heightRatio - viewCount[i] * heightRatio,
////                    rectangleWidth,
////                    viewCount[i] * heightRatio);
        }

        graphics.lineTo(_width, _height);
        graphics.endFill();

        timeMarker = new Shape();
        timeMarker.graphics.beginFill(colour);
        timeMarker.graphics.drawCircle(0, 0, 5);
        timeMarker.graphics.endFill();
    }

    public function showTime(time:Number):void {

        if(contains(timeMarker) && time == -1) {
            removeChild(timeMarker);
        } else {
            if(!contains(timeMarker)) {
                addChild(timeMarker);
            }

            timeMarker.x = time/viewCount.length * width;
            var cappedIndex:int = Math.max(0, Math.min(Math.floor(time), viewCount.length-1));
            timeMarker.y = _height - viewCount[cappedIndex] * _heightRatio;
        }

    }
}

class FloatingWindow extends Sprite {

    private var textfield:TextField;
    private var colours:Vector.<Shape>;

    public function FloatingWindow() {

        textfield = new TextField();
        textfield.autoSize = TextFieldAutoSize.LEFT;
        textfield.defaultTextFormat = new TextFormat("Arial", // font
                10, // size
                0x0, // color
                true, // bold
                false, // italic
                false, // underline
                null, // url
                null, // target
                "center", // align
                null, // left margin
                null, // right margin
                null, // indent
                4); // leading
        addChild(textfield);

        colours = new Vector.<Shape>();
    }

    public function show(userDatas:Vector.<UserData>, time:int):void {

        var count:int = 0;
        textfield.text = "";

        var userData:UserData;
        for each(userData in userDatas) {

            if(time > 0) {
                var viewCountTime:Number = userData.viewCountRecord.length > time ? userData.viewCountRecord[time] : 0;
                textfield.text += "S" + UsersDictionary.getUserNumber(userData.userString) + " " + userData.userString + ": " + viewCountTime + "\n";
            }
        }

        if(colours.length == 0) {
            for each(userData in userDatas) {

                var shape:Shape = new Shape();
                shape.graphics.beginFill(ColorUtil.HSVtoHEX(count / userDatas.length * 300, 70, 100));
                shape.graphics.drawCircle(0, count++ * 14, 5);
                shape.graphics.endFill();
                addChild(shape);

                colours.push(shape);

            }
        }
    }
}