////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

import starling.display.Canvas;
import starling.display.DisplayObject;

import starling.display.Sprite;
import starling.events.Event;

public class StarlingView extends Sprite implements IView {

    protected var _width:Number;
    protected var _height:Number;
    private var _background:Canvas;

    public function StarlingView() {
        super();
        _width = 100;
        _height = 100;
        _background = new Canvas();
        _background.touchable = false;
        addChild(_background);

        addEventListener(Event.ADDED_TO_STAGE, addedToStage);
    }

    protected function addedToStage(e:Event = null):void {
        removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
    }

    protected function removedFromStage(e:Event = null):void {
        addEventListener(Event.ADDED_TO_STAGE, addedToStage);
        removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
    }

    public function get graphics():Canvas {
        return _background;
    }

    public function bringChildToFront(displayObject:DisplayObject):void {
        if(displayObject && contains(displayObject)) {
            setChildIndex(displayObject, numChildren - 1);
        }
    }

    public function move(x:Number, y:Number):void {
        this.x = x;
        this.y = y;
    }

    override public function get width():Number {
        return _width;
    }

    override public function set width(value:Number):void {
        _width = value;
    }

    override public function get height():Number {
        return _height;
    }

    override public function set height(value:Number):void {
        _height = value;
    }
}
}