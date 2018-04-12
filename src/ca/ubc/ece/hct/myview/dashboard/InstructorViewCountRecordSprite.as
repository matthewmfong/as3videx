package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.View;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import flash.display.Shape;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import mx.controls.Text;

public class InstructorViewCountRecordSprite extends View {

    private var _video:VideoMetadata;
    private var viewCountRecordSprite:Sprite;
    private var axis:Shape;
    private var cursor:Shape;
    private var axisLabels:Sprite;

    private var aggregateVCR:Array;

    public function InstructorViewCountRecordSprite(w:Number, h:Number) {
        _width = w;
        _height = h;

        axis = new Shape();
        addChild(axis);

        viewCountRecordSprite = new Sprite();
        addChild(viewCountRecordSprite);

        cursor = new Shape();
        cursor.graphics.lineStyle(1, 0xff0000);
        cursor.graphics.moveTo(0, 0);
        cursor.graphics.lineTo(0, _height);

        axisLabels = new Sprite();
        addChild(axisLabels);


        addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
        addEventListener(MouseEvent.ROLL_OUT, rollOut);
    }

    public function set video(v:VideoMetadata):void {
        _video = v;
    }

    public function drawViewCountRecord(userdatas:Vector.<UserData>, allTimeMaxViewCount:Number, allTimeAggregateMaxViewCount:Number):void {

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
            textfield.defaultTextFormat = new TextFormat("Arial", 10, 0x999999);
            textfield.autoSize = TextFieldAutoSize.LEFT;
            textfield.text = Math.round((_height - i)/_height*allTimeMaxViewCount).toString();
            axisLabels.addChild(textfield);
            textfield.y = i - textfield.height;

            textfield = new TextField();
            textfield.autoSize = TextFieldAutoSize.RIGHT;
            textfield.defaultTextFormat = new TextFormat("Arial", 10, 0x00ff00);
            textfield.text = Math.round((_height - i)/_height*allTimeAggregateMaxViewCount).toString();
            axisLabels.addChild(textfield);
            textfield.x = _width - textfield.width;
            textfield.y = i - textfield.height;;

        }

//        var userdatas:Vector.<UserData> = _video.crowdUserData.grab(UserData.CLASS);
        aggregateVCR = [];

        graphics.clear();
        graphics.beginFill(0xffffff);
        graphics.drawRect(0, 0, _width, _height);
        graphics.endFill();

        var maxViewCount:Number = allTimeMaxViewCount;
        var data:UserData;
//        for each(data in userdatas) {
//            maxViewCount = Math.max(data.maxViewCount, maxViewCount);
//        }

//        var aggregateMaxViewCount:Number = allTimeAggregateMaxViewCount;

        var graphMaxHeight:int = _height;
        var graphHeight:Number = 0;

        viewCountRecordSprite.graphics.clear();
        for each(data in userdatas) {

            var viewCountRecord:Array = data.viewCountRecord;

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

    private function mouseMove(e:MouseEvent):void {

        if(!contains(cursor)) {
            addChild(cursor);
        }

        cursor.x = e.localX;
    }

    private function rollOut(e:MouseEvent):void {

        if(contains(cursor)) {
            removeChild(cursor);
        }
    }
}
}
