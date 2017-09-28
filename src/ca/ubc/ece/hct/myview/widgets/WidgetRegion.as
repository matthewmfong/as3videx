/**
 * Created by matth on 2017-07-10.
 */
package ca.ubc.ece.hct.myview.widgets {
import ca.ubc.ece.hct.myview.IView;
import ca.ubc.ece.hct.myview.StarlingView;

import flash.geom.Point;

import org.osflash.signals.Signal;

import starling.core.Starling;

import starling.display.Quad;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.utils.Color;

public class WidgetRegion extends StarlingView {

    public static const PADDING:Number = 10;
    public var _widget:StarlingWidget;
    public var _nativeWidget:Widget;
    public function get isEmpty():Boolean { return (_widget == null && _nativeWidget == null); }
    private var topResize:Quad, leftResize:Quad, bottomResize:Quad, rightResize:Quad;
    public var topResizable:Boolean = false, leftResizable:Boolean = false,
             bottomResizable:Boolean  = false, rightResizable:Boolean = false;
    private var regionName:TextField;

    private var mouseDown:Touch, mouseMove:Touch, mouseUp:Touch;

    private var resizeDiff:Number;
    public var topResizeSignal:Signal, leftResizeSignal:Signal, rightResizeSignal:Signal, bottomResizeSignal:Signal;
    public var resizingSignal:Signal;
    public var handleSelfResize:Boolean = true;

    public var savedDimensions:flash.geom.Rectangle;

    public function WidgetRegion() {
        super();
        topResize = new Quad(1, 5, Color.WHITE);
        leftResize = new Quad(5, 1, Color.WHITE);
        bottomResize = new Quad(1, 5, Color.WHITE);
        rightResize = new Quad(5, 1, Color.WHITE);

        topResize.addEventListener(TouchEvent.TOUCH, moveTop);
        leftResize.addEventListener(TouchEvent.TOUCH, moveLeft);
        bottomResize.addEventListener(TouchEvent.TOUCH, moveBottom);
        rightResize.addEventListener(TouchEvent.TOUCH, moveRight);

        topResize.alpha = 0.2;
        leftResize.alpha = 0.2;
        bottomResize.alpha = 0.2;
        rightResize.alpha = 0.2;

        addChild(topResize);
        addChild(leftResize);
        addChild(bottomResize);
        addChild(rightResize);

        resizingSignal = new Signal(Boolean); // are we currently resizing?
        topResizeSignal = new Signal(Number); // diff
        leftResizeSignal = new Signal(Number); // diff
        rightResizeSignal = new Signal(Number); // diff
        bottomResizeSignal = new Signal(Number); // diff
    }

    override public function dispose():void {
        super.dispose();

        resizingSignal = null
        topResizeSignal = null;
        leftResizeSignal = null;
        rightResizeSignal = null;
        bottomResizeSignal = null;

        topResize.removeEventListener(TouchEvent.TOUCH, moveTop);
        leftResize.removeEventListener(TouchEvent.TOUCH, moveLeft);
        bottomResize.removeEventListener(TouchEvent.TOUCH, moveBottom);
        rightResize.removeEventListener(TouchEvent.TOUCH, moveRight);

        removeChild(topResize);
        removeChild(leftResize);
        removeChild(bottomResize);
        removeChild(rightResize);

        topResize.dispose();
        leftResize.dispose();
        bottomResize.dispose();
        rightResize.dispose();

        if(_widget) {
            _widget.dispose();
        }

        if(_nativeWidget) {
            _nativeWidget.dispose();
        }
    }

    private function moveTop(e:TouchEvent):void {
        mouseDown = e.getTouch(topResize, TouchPhase.BEGAN);
        mouseMove = e.getTouch(topResize, TouchPhase.MOVED);
        mouseUp = e.getTouch(topResize, TouchPhase.ENDED);

        if(mouseDown) {
//            trace("MOUSE DOWN");
            resizingSignal.dispatch(true);
        }

        if(mouseMove) {
            resizeDiff = (mouseMove.globalY - mouseMove.previousGlobalY);
            if(handleSelfResize) {
                y = y + resizeDiff;
                setSize(_width, _height - resizeDiff);
            }
            topResizeSignal.dispatch(resizeDiff);
        }

        if(mouseUp) {
//            trace("MOUSE UP");
            resizingSignal.dispatch(false);
        }
    }

    private function moveBottom(e:TouchEvent):void {
        mouseDown = e.getTouch(bottomResize, TouchPhase.BEGAN);
        mouseMove = e.getTouch(bottomResize, TouchPhase.MOVED);
        mouseUp = e.getTouch(bottomResize, TouchPhase.ENDED);

        if(mouseDown) {
//            trace("MOUSE DOWN");
            resizingSignal.dispatch(true);
        }

        if(mouseMove) {
            resizeDiff = (mouseMove.globalY - mouseMove.previousGlobalY);
            if(handleSelfResize) {
                setSize(_width, _height + resizeDiff);
            }
            bottomResizeSignal.dispatch(resizeDiff);
        }

        if(mouseUp) {
//            trace("MOUSE UP");
            resizingSignal.dispatch(false);
        }
    }

    private function moveLeft(e:TouchEvent):void {
        mouseDown = e.getTouch(leftResize, TouchPhase.BEGAN);
        mouseMove = e.getTouch(leftResize, TouchPhase.MOVED);
        mouseUp = e.getTouch(leftResize, TouchPhase.ENDED);

        if(mouseDown) {
//            trace("MOUSE DOWN");
            resizingSignal.dispatch(true);
        }

        if(mouseMove) {
            resizeDiff = (mouseMove.globalX - mouseMove.previousGlobalX);
            if(handleSelfResize) {
                x = x + resizeDiff;
                setSize(_width - resizeDiff, _height);
            }
            leftResizeSignal.dispatch(resizeDiff);
        }

        if(mouseUp) {
//            trace("MOUSE UP");
            resizingSignal.dispatch(false);
        }
    }

    private function moveRight(e:TouchEvent):void {
        mouseDown = e.getTouch(rightResize, TouchPhase.BEGAN);
        mouseMove = e.getTouch(rightResize, TouchPhase.MOVED);
        mouseUp = e.getTouch(rightResize, TouchPhase.ENDED);

        if(mouseDown) {
//            trace("MOUSE DOWN");
            resizingSignal.dispatch(true);
        }

        if(mouseMove) {
            resizeDiff = (mouseMove.globalX - mouseMove.previousGlobalX);
            if(handleSelfResize) {
                setSize(_width + resizeDiff, _height);
            }
            rightResizeSignal.dispatch(resizeDiff);
        }

        if(mouseUp) {
//            trace("MOUSE UP");
            resizingSignal.dispatch(false);
        }
    }

    public function setName(name:String):void {
        regionName = new TextField(200, 200, name);
        regionName.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
        regionName.x = _width/2;
        regionName.y = _height/2;
//        addChild(regionName);
    }

    public function setWidget(widget:StarlingWidget):void {
        unsetWidget();

        if(widget) {
            _widget = widget;
        }
    }

    public function setNativeWidget(nativeWidget:Widget):void {
        unsetWidget();

        if(nativeWidget) {
            _nativeWidget = nativeWidget;
        }
    }

    public function unsetWidget():void {
        if(_widget && contains(_widget)) {
            removeChild(_widget);
            _widget = null;
        }

        if(_nativeWidget && Starling.current.nativeOverlay.contains(_nativeWidget)) {
            Starling.current.nativeOverlay.removeChild(_nativeWidget);
            _nativeWidget = null;
        }
    }

    public function renderWidget():void {
        if(_widget) {
            positionWidget();
            addChild(_widget);
        }

        if(_nativeWidget) {
            positionWidget();
            Starling.current.nativeOverlay.addChild(_nativeWidget);
        }
    }

    public function setResizeable(top:Boolean = false, left:Boolean = false,
                                  bottom:Boolean = false, right:Boolean = false):void {
        topResizable = top;
        leftResizable = left;
        bottomResizable = bottom;
        rightResizable = right;

        topResize.touchable = topResizable;
        bottomResize.touchable = bottomResizable;
        leftResize.touchable = leftResizable;
        rightResize.touchable = rightResizable;

        topResize.readjustSize(_width, (top) ? PADDING : 1);
        bottomResize.readjustSize(_width, (bottom) ? PADDING : 1);
        leftResize.readjustSize((left) ? PADDING : 1, _height);
        rightResize.readjustSize((right) ? PADDING : 1, _height);
    }

    public function setSize(width:Number, height:Number):void {
        _width = width;
        _height = height;

        topResize.readjustSize(_width, (topResizable) ? PADDING : 1);
        bottomResize.readjustSize(_width, (bottomResizable) ? PADDING : 1);
        bottomResize.y = _height - bottomResize.height;

        leftResize.readjustSize((leftResizable) ? PADDING : 1 , _height);
        rightResize.readjustSize((rightResizable) ? PADDING : 1 , _height);
        rightResize.x = _width - rightResize.width;

        if(regionName && contains(regionName)) {
            regionName.x = _width/2 - regionName.width/2;
            regionName.y = _height/2 - regionName.height/2;
        }

//        graphics.clear();
//        graphics.beginFill(0x00ff00);
//        graphics.drawEllipse(PADDING, PADDING, width - PADDING*2, height - PADDING * 2);
//        graphics.endFill();

        if((_widget && contains(_widget)) ||
                (_nativeWidget && Starling.current.nativeOverlay.contains(_nativeWidget)) ) {
            positionWidget();
        }
    }

    public function saveDimensions():void {
        savedDimensions = new flash.geom.Rectangle(x, y, _width, _height);
    }

    public function restoreSavedDimensions():void {
        if(savedDimensions) {
            x = savedDimensions.x;
            y = savedDimensions.y;
            setSize(savedDimensions.width, savedDimensions.height);
        }
    }

    private function positionWidget():void {
        if(_widget) {
            _widget.move(leftResizable ? PADDING : 0,
                         topResizable ? PADDING : 0);
            _widget.setSize(_width - _widget.x - (rightResizable ? PADDING : 0),
                            _height - _widget.y - (bottomResizable ? PADDING : 0));
        }

        if(_nativeWidget) {

            var zero:Point = localToGlobal(new Point(0, 0));

            _nativeWidget.move(leftResizable ? zero.x + PADDING : zero.x,
                    topResizable ? zero.y + PADDING : zero.y);
            _nativeWidget.setSize(_width - _nativeWidget.x - (rightResizable ? PADDING : 0),
                    _height - _nativeWidget.y - (bottomResizable ? PADDING : 0));
        }
    }
}
}
