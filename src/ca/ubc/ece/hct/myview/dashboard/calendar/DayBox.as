/**
 * Created by iDunno on 2018-02-16.
 */
package ca.ubc.ece.hct.myview.dashboard.calendar {
import ca.ubc.ece.hct.myview.View;

import flash.display.Shape;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

public class DayBox extends View {

    public var date:Date;

//    public var colour:Array = [0xff0000, 0xffa200, 0xfcff00, 0x00ff24, 0x00f0ff, 0x0012ff, 0xba00ff];
    public var _colour:Number;
    private var _selected:Boolean;
    public var text:TextField;
    public var rollOverString:String = "";
    public var rollOverTextField:TextField;
    public var rollOverBackground:Shape;

    public function DayBox(d:Date, colour:Number, w:Number, h:Number) {
        date = d;
        _width = w;
        _height= h;
        _colour = colour;
        text = new TextField();
        text.defaultTextFormat = new TextFormat("Arial", _height/2);
        text.mouseEnabled = false;
        rollOverTextField = new TextField();
        rollOverTextField.mouseEnabled = false;
        rollOverBackground = new Shape();
        addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
    }

    private function addedToStageHandler(e:Event):void {
        draw();

        addEventListener(MouseEvent.ROLL_OVER, rollOver);
        addEventListener(MouseEvent.ROLL_OUT, rollOut);
    }

    private function draw():void {

        graphics.clear();
        graphics.beginFill(_colour, 1);
        graphics.drawRect(0, 0, _width, _height);
        graphics.endFill();

        if (_selected) {
            graphics.lineStyle(1, 0xff0000);
            graphics.drawRect(0, 0, _width, _height);
        }

//        text.width = _width;
//        text.height = _height;
        text.autoSize = TextFormatAlign.LEFT;
        text.text = date.date.toString();
        text.x = _width / 2 - text.width / 2;
        text.y = _height / 2 - text.height / 2;

        if (!contains(text)) {
            addChild(text);
        }
    }

    public function setColour(c:Number):void {
        _colour = c;

        draw();
    }

    public function setSize(w:Number, h:Number):void {
        _width = w;
        _height = h;
        draw();
    }

    public function set selected(val:Boolean):void {
        if(val != _selected) {
            _selected = val;
            draw();
        }
    }

    private function rollOver(e:MouseEvent):void {

        if(!contains(rollOverBackground)) {

            addChild(rollOverBackground);
        }

        if(!contains(rollOverTextField)) {
            rollOverTextField.text = rollOverString;
            rollOverTextField.autoSize = TextFieldAutoSize.CENTER;
            addChild(rollOverTextField);
        }

        rollOverTextField.x = _width;
        rollOverBackground.x = _width;
        rollOverBackground.graphics.clear();
        rollOverBackground.graphics.lineStyle(0, 0xff0000);
        rollOverBackground.graphics.beginFill(0xeeeeee);
        rollOverBackground.graphics.drawRect(0, 0, rollOverTextField.width, rollOverTextField.height);
        rollOverBackground.graphics.endFill();

    }

    private function rollOut(e:MouseEvent):void {

        if(contains(rollOverTextField)) {
            removeChild(rollOverTextField);
        }

        if(contains(rollOverBackground)) {
            removeChild(rollOverBackground);
        }
    }

}
}
