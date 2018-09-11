/**
 * Created by iDunno on 2017-07-25.
 */
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.myview.widgets.StarlingWidget;

import com.greensock.TweenLite;
import com.greensock.TweenLite;

import feathers.controls.AutoSizeMode;
import feathers.controls.Callout;
import feathers.controls.LayoutGroup;
import feathers.layout.HorizontalAlign;
import feathers.layout.HorizontalLayout;
import feathers.layout.RelativePosition;
import feathers.layout.VerticalAlign;

import org.osflash.signals.Signal;

import spark.components.Callout;

import starling.core.Starling;

import starling.display.DisplayObject;

import starling.display.Image;
import starling.display.Quad;

import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.filters.ColorMatrixFilter;

public class HighlightCallout extends Sprite {

    public static const ADD_HIGHLIGHT_MODE:String = "HighlightCallout.ADD_HIGHLIGHT_MODE";
    public static const DEL_HIGHLIGHT_MODE:String = "HighlightCallout.DEL_HIGHLIGHT_MODE";

    public static const GAP:int = 5;

    private var background:Quad;
    private var container:Sprite;
    private var circles:Array;
    private var deleteImage:Image;
    private var highlightable:Array;
    private var deletable:Array;
    private var circlesVisible:Array;

    public var addDeleteMode:String;

    public var highlightSignal:Signal;
    private var callout:feathers.controls.Callout;
    public static var caller:*;

    public function HighlightCallout() {
        highlightable = [];
        deletable = [];
        background = new Quad(1, 1);
        init();
        addDeleteMode = ADD_HIGHLIGHT_MODE;
        highlightSignal = new Signal(uint, String); // Colour

        circles = [];
        for(var i:int = 0; i<Colours.colours.length; i++) {
            var circle:HighlightCircle = new HighlightCircle(Colours.colours[i]);
            circle.addEventListener(TouchEvent.TOUCH, circleTouch);
            circles.push(circle);
        }
    }

    public static function showCallout(target:DisplayObject,
                                       highlightable:Array = null,
                                       deletable:Array = null,
                                       callReference:* = null):feathers.controls.Callout {
        caller = callReference;

        var flexCallout:spark.components.Callout = new spark.components.Callout();


        Starling.current.nativeOverlay.addChild(flexCallout);
        flexCallout.open(Starling.current.nativeOverlay, true);

        trace(flexCallout);

        var content:HighlightCallout = new HighlightCallout();
        content.setColours(highlightable, deletable);

        StarlingWidget.allWidgetSwapStarlingNative();
        var callout:feathers.controls.Callout = feathers.controls.Callout.show(content, target, new <String>[RelativePosition.TOP] );
        callout.closeOnTouchEndedOutside = false;
        callout.disposeContent = true;
        content.callout = callout;
        content.callout.addEventListener(Event.CLOSE,
                function calloutClosed():void {
                    StarlingWidget.allWidgetSwapStarlingNative();
                });

        callout.alpha = 0;
        TweenLite.to(callout, Animate.TWEENTIME, {alpha: 1});

        return callout;
    }

    public function setColours(highlightable:Array, deletable:Array):void {
        this.highlightable = highlightable != null ? highlightable : [];
        this.deletable = deletable != null ? deletable : [];

        addButtons(highlightable);
        addDeleteButton();
    }

    private function init():void {
        container = new Sprite();
        addChild(background);
        background.alpha = 0;
        background.touchable = false;
        addChild(container);
    }

    private function addButtons(colours:Array):void {

        circlesVisible = [];
        var i:int = 0;
        for(i = 0; i<Colours.colours.length; i++) {
            if(Util.arrayContains(colours, Colours.colours[i])){

                if(!container.contains(circles[i])) {
                    container.addChild(circles[i]);
                }

                circlesVisible.push(circles[i]);

            } else if(!Util.arrayContains(colours, Colours.colours[i]) && container.contains(circles[i])) {
                Animate.shrinkAndDisappear(circles[i]).addOnce(
                        function remove(t:DisplayObject):void {
                            container.removeChild(t);
                        });
            }
        }

        var allCirclesWidth:Number = Colours.colours.length * (2 * HighlightCircle.radius + GAP) - GAP;
        var totalCirclesVisibleWidth:Number = circlesVisible.length * (2 * HighlightCircle.radius + GAP) - GAP;
        var leftPoint:Number = allCirclesWidth/2 - totalCirclesVisibleWidth/2;
        for(i = 0; i<circlesVisible.length; i++) {

            circlesVisible[i].x = leftPoint + i * (2 * HighlightCircle.radius + GAP);
            circlesVisible[i].y = 0;
            Animate.growAndAppear(circlesVisible[i]);

        }

//        trace(circlesVisible.length);

//        TweenLite.delayedCall(Animate.TWEENTIME,
//            function():void {
//                callout.setSize(numCirclesVisible * (2 * HighlightCircle.radius + GAP), HighlightCircle.radius * 2);
//            });

    }

    private function addDeleteButton():void {
        if(!deleteImage) {
            deleteImage = new Image(VidexStarling.assets.getTexture("ms_Icon_Delete"));
            deleteImage.readjustSize(HighlightCircle.radius * 2 * (deleteImage.width / deleteImage.height),
                    HighlightCircle.radius * 2);
            deleteImage.addEventListener(TouchEvent.TOUCH, deleteTouch);
        }

        if(!container.contains(deleteImage)) {
            container.addChild(deleteImage);
            deleteImage.x = Colours.colours.length * (2 * HighlightCircle.radius + GAP);
            deleteImage.y = 0;
            Animate.growAndAppear(deleteImage);
        }

        if(deletable.length == 0) {
            deleteImage.texture = VidexStarling.assets.getTexture("ms_Icon_Delete_disabled");
            deleteImage.removeEventListener(TouchEvent.TOUCH, deleteTouch);
        } else {
            deleteImage.addEventListener(TouchEvent.TOUCH, deleteTouch);
        }

        background.readjustSize((Colours.colours.length + 1) * (2 * HighlightCircle.radius + GAP) - GAP, HighlightCircle.radius * 2)

    }

    private function circleTouch(e:TouchEvent):void {
        var circle:HighlightCircle = (HighlightCircle)(e.currentTarget);
        var touch:Touch = e.getTouch(circle, TouchPhase.ENDED);

        if(touch) {
            highlightSignal.dispatch(circle.colour, addDeleteMode);

            if(addDeleteMode == DEL_HIGHLIGHT_MODE) {
                Animate.shrinkAndDisappear(circle).addOnce(
                        function removeCirle(c:DisplayObject):void {
                            container.removeChild(c);
                        });
            }
//            trace("clicked circle" + circle.colour.toString(16));
        }
    }

    private function deleteTouch(e:TouchEvent):void {
        var touch:Touch = e.getTouch(deleteImage, TouchPhase.ENDED);
        if(touch) {
//            trace("lol");
            addDeleteMode = (addDeleteMode == ADD_HIGHLIGHT_MODE) ? DEL_HIGHLIGHT_MODE : ADD_HIGHLIGHT_MODE;

//            removeButtons();

            switch(addDeleteMode) {
                case ADD_HIGHLIGHT_MODE:
                    deleteImage.texture = VidexStarling.assets.getTexture("ms_Icon_Delete");
                    addButtons(highlightable);
//                        TweenLite.to(deleteImage, Animate.TWEENTIME, {x: numCirclesVisible * (2 * HighlightCircle.radius + GAP)});
                    break;
                case DEL_HIGHLIGHT_MODE:
                    deleteImage.texture = VidexStarling.assets.getTexture("ms_Icon_Delete_active");
//                    container.removeChild(deleteImage);
                    addButtons(deletable);

//                    background.readjustSize((numCirclesVisible + 1) * (2 * HighlightCircle.radius + GAP) - GAP, HighlightCircle.radius * 2);
//                        trace(background.width + " " + ((numCirclesVisible + 1) * (2 * HighlightCircle.radius + GAP) - GAP));
//
//                    TweenLite.delayedCall(Animate.TWEENTIME,
//                            function():void {
//                                callout.validate();//setSize(background.width + 2*callout.padding, callout.height);
//                            });
//                    TweenLite.to(deleteImage, Animate.TWEENTIME, {x: numCirclesVisible * (2 * HighlightCircle.radius + GAP)});
                    break;
            }

//            trace(container.width + " " + container.height)
//            container.validate();
//            trace(container.width + " " + container.height)
//            callout.validate();
        }
    }
}
}

import ca.ubc.ece.hct.myview.Util;

import starling.display.Canvas;
import starling.filters.FragmentFilter;
import starling.rendering.FilterEffect;

class HighlightCircle extends Canvas {

    public static const radius:Number = 18;
    public var colour:uint;

    public function HighlightCircle(colour:uint):void {
        this.colour = colour;
        beginFill(0xcccccc);
        drawCircle(radius, radius, radius);
        endFill();
        beginFill(Util.changeSaturation(colour, 3));
        drawCircle(radius, radius, radius - 0.5);
        endFill();
        beginFill(Util.changeSaturation(colour, 1));
        drawCircle(radius, radius, radius - 3.5);
        endFill();
    }
}
