package ca.ubc.ece.hct.myview.dashboard.VideoSummary {

import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import flash.display.GradientType;

import flash.display.Shape;

import flash.display.Sprite;
import flash.geom.Matrix;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import spark.components.Label;
import spark.core.SpriteVisualElement;
import spark.formatters.DateTimeFormatter;

public class VideoSummaryVCRComponent extends SpriteVisualElement {

    public var video:VideoMetadata;

    public var _width:Number;
    public var _height:Number;

    public var vcr:Vector.<Number>;

    public var maxViewCount:Number;

    public static const HORIZONTAL_TICK_INTERVAL:int = 30;

    public function VideoSummaryVCRComponent() {
        super();
    }

    public function instantiate(video:VideoMetadata, viewCountRecord:Vector.<Number>, width:Number, height:Number, slides:Vector.<Number> = null) {

        this.video = video;

        _width = width;
        _height = height;

        vcr = viewCountRecord;

        var startTime:Number = 0;
        var endTime:Number = viewCountRecord.length-1;

        maxViewCount = 1;
        for (var i:int = 0; i < viewCountRecord.length; i++) {
            if (viewCountRecord[i] > maxViewCount) {
                maxViewCount = viewCountRecord[i];
            }
        }

        var graphMaxHeight:int = _height;

        var viewCountRecordSprite:Shape = new Shape();
        viewCountRecordSprite.graphics.clear();
        viewCountRecordSprite.graphics.beginFill(0xff0000, 0);
        viewCountRecordSprite.graphics.drawRect(0, 0, _width, graphMaxHeight);
        viewCountRecordSprite.graphics.endFill();

        var graphHeight:Number = 0;

        var colours:Array = [0x009900];
        var alphas:Array = [1];
        var ratios:Array = [0];
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

//        viewCountRecordSprite.graphics.lineTo((-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
//                graphMaxHeight - graphHeight)

        var calc:Number = 0;
        for (var i:int = forStart; i < forEnd; i++) {

//            calc = (Math.log(viewCountRecord[i] / maxViewCount + Math.pow(Math.E, -1.5)) + 1.5) /
//                    (Math.log(1 + Math.pow(Math.E, -1.5)) + 1.5) *
//                    graphMaxHeight;
            calc = viewCountRecord[i]/maxViewCount * graphMaxHeight;

            graphHeight = Math.min(graphMaxHeight, calc);

            viewCountRecordSprite.graphics.lineTo((i + 0.5 - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
                    graphMaxHeight - graphHeight)
        }
        viewCountRecordSprite.graphics.lineTo((forEnd - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
                graphMaxHeight - graphHeight)
        viewCountRecordSprite.graphics.lineTo(_width, graphMaxHeight);
        viewCountRecordSprite.graphics.lineTo(calc, graphMaxHeight);

        if(slides) {
            for(var i:int = 0; i<slides.length; i++) {
                viewCountRecordSprite.graphics.lineStyle(1, 0);
                viewCountRecordSprite.graphics.moveTo((slides[i] + 0.5 - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width, graphMaxHeight);
                viewCountRecordSprite.graphics.lineTo((slides[i] + 0.5 - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width, 0);
            }
        }

        addChild(viewCountRecordSprite);

        drawAxes();

    }

    public function drawAxes():void {
        var axes:Sprite = new Sprite();
        axes.graphics.lineStyle(1, 0);
        axes.graphics.lineTo(0,         _height);
        axes.graphics.lineTo(_width,  _height);

        var numberofHorizontalTicks:int = vcr.length/HORIZONTAL_TICK_INTERVAL;
        var numberOfVerticalTicks:int = _height/25;

        for(var i:int = 0; i<numberOfVerticalTicks; i++) {
            axes.graphics.moveTo(0, _height - (i+1) * _height/numberOfVerticalTicks);
            axes.graphics.lineTo(5, _height - (i+1) * _height/numberOfVerticalTicks);
        }

        var lastTimePosition:Number = 0;
        for(var i:int = 0; i<numberofHorizontalTicks; i++) {
            axes.graphics.moveTo((i+1) * _width/numberofHorizontalTicks, _height);
            axes.graphics.lineTo((i+1) * _width/numberofHorizontalTicks, _height - 5);

            if((i * _width/numberofHorizontalTicks) - lastTimePosition  > 20) {
                var time:TextField = new TextField();
                time.autoSize = TextFieldAutoSize.CENTER;
                time.text = Util.timeInSecondsToTimeString(HORIZONTAL_TICK_INTERVAL * i);
                time.x = (i) * _width / numberofHorizontalTicks;
                time.y = _height - time.height;
                axes.addChild(time);

                lastTimePosition = time.x + time.width;
            }
        }

        addChild(axes);

        var maxViews:TextField = new TextField();
        maxViews.autoSize = TextFieldAutoSize.CENTER;
        maxViews.text = maxViewCount.toString() + " total views";
        maxViews.x = 7;
        axes.addChild(maxViews);


    }
}
}
