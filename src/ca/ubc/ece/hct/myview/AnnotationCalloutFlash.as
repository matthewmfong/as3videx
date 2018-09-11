package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.ImageLoader;
import ca.ubc.ece.hct.myview.AnnotationCalloutFlash;
import ca.ubc.ece.hct.myview.common.Annotation;
import ca.ubc.ece.hct.myview.ui.button.ImageButton;

import com.greensock.TweenLite;

import fl.controls.TextArea;

import flash.display.Bitmap;
import flash.display.BitmapData;

import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;

import mx.effects.Tween;

import org.osflash.signals.Signal;

public class AnnotationCalloutFlash extends Sprite {

    public static var MARGIN:Number = 5;
    public static var TITLETEXT_HEIGHT:Number = 15;

    public static var callout:AnnotationCalloutFlash;
    public static var stage:Sprite;
    public static var origin:Point;
    public static var callReference:*;
    public static var interval:ca.ubc.ece.hct.Range;

    public var annotation:Annotation;

    private static var outsideClicker:Sprite;
    private var content:Sprite;
    private var highlightCircles:Array;
    private var note:ImageLoader;
    private var close:ImageLoader;
    private var trash:ImageLoader;
    private var noteText:TextArea;
    private var titleText:TextField;

    private var _width:Number;
    private var _height:Number;

    override public function get height():Number { return _height; }
    override public function get width():Number { return _width; }

    public var annotateSignal:Signal;

    public function AnnotationCalloutFlash() {

        // Starling still seems to get mouse (touch) events if you don't do this
        addEventListener(MouseEvent.MOUSE_MOVE, function (e:Event):void { e.stopPropagation(); e.stopImmediatePropagation(); });
        addEventListener(MouseEvent.MOUSE_DOWN, function (e:Event):void { e.stopPropagation(); e.stopImmediatePropagation(); });
        addEventListener(MouseEvent.MOUSE_UP, function (e:Event):void { e.stopPropagation(); e.stopImmediatePropagation(); });
        //

        annotateSignal = new Signal(Annotation);

        outsideClicker = new Sprite();

        addEventListener(Event.ADDED_TO_STAGE,
                function addedToStage(e:Event):void {
                    outsideClicker.graphics.clear();
                    outsideClicker.graphics.beginFill(0, 0);
                    outsideClicker.graphics.drawRect(0, 0, AnnotationCalloutFlash.stage.width, AnnotationCalloutFlash.stage.height);
                    outsideClicker.graphics.endFill();
                    outsideClicker.addEventListener(MouseEvent.MOUSE_DOWN, closeCallout);
                    if(!AnnotationCalloutFlash.stage.contains(outsideClicker)) {
                        AnnotationCalloutFlash.stage.addChild(outsideClicker);
                        AnnotationCalloutFlash.stage.setChildIndex(outsideClicker, 0);
                    }
                });

        content = new Sprite();

        highlightCircles = [];
        var highlightCircle:HighlightCircle;
        for(var i:int = 0; i<Colours.colours.length; i++) {

            highlightCircle = new HighlightCircle(Colours.colours[i], Colours.colourNames[i]);
            content.addChild(highlightCircle);
            highlightCircle.x = MARGIN + i * (HighlightCircle.radius + 1) * 2;
            highlightCircle.y = MARGIN + TITLETEXT_HEIGHT;
            highlightCircles.push(highlightCircle);
            highlightCircle.addEventListener(MouseEvent.ROLL_OUT, resetTitle);
            highlightCircle.addEventListener(MouseEvent.CLICK, highlight);
            highlightCircle.addEventListener(MouseEvent.ROLL_OVER, function(e:Event):void { titleText.text = "Highlight " + (HighlightCircle)(e.target).colourName; });

        }

        // erase circle
        highlightCircle = new HighlightCircle(0xffffff, "white");
        content.addChild(highlightCircle);
        highlightCircle.x = MARGIN + i * (HighlightCircle.radius+1) * 2;
        highlightCircle.y = MARGIN + TITLETEXT_HEIGHT;
        highlightCircles.push(highlightCircle);
        highlightCircle.addEventListener(MouseEvent.ROLL_OUT, resetTitle);
        highlightCircle.addEventListener(MouseEvent.ROLL_OVER, function(e:Event):void { titleText.text = "Erase highlight"; });

        addChild(content);

        loadImages();
    }

    private function loadImages():void {
        close = new ImageLoader("uiimage/annotation/close.png");
        note = new ImageLoader("uiimage/annotation/note.png");
        trash = new ImageLoader("uiimage/annotation/trash.png");


        close.addEventListener(MouseEvent.CLICK, closeCallout);
        note.addEventListener(MouseEvent.CLICK, expandTextField);
        trash.addEventListener(MouseEvent.CLICK, deleteAnnotation);

        close.addEventListener(Event.COMPLETE, imagesLoaded);
        note.addEventListener(Event.COMPLETE, imagesLoaded);
        trash.addEventListener(Event.COMPLETE, imagesLoaded);
    }

    private function imagesLoaded(e:Event):void {

        if(close.loaded && note.loaded && trash.loaded) {
            positionImages();
            drawNoteText();
            drawBackground();

            dispatchEvent(new Event(Event.COMPLETE));

        }

    }

    private function positionImages():void {
        content.addChild(note);
        note.x = highlightCircles[highlightCircles.length-1].x + highlightCircles[highlightCircles.length-1].width + 2;
        note.y = MARGIN + TITLETEXT_HEIGHT;
        note.addEventListener(MouseEvent.ROLL_OUT, resetTitle);
        note.addEventListener(MouseEvent.ROLL_OVER, function noteRollOver(e:Event):void { titleText.text = "Make a note"; });

        content.addChild(close);
        close.x = note.x + note.width + 2;
        close.y = MARGIN + TITLETEXT_HEIGHT;
        close.addEventListener(MouseEvent.CLICK, closeCallout);
        close.addEventListener(MouseEvent.ROLL_OUT, resetTitle);
        close.addEventListener(MouseEvent.ROLL_OVER, function closeRollOver(e:Event):void { titleText.text = "Close"; });

        titleText = new TextField();
        titleText.defaultTextFormat = new TextFormat("Arial", 12, 0x666666);
        titleText.text = "Annotate";
        titleText.x = MARGIN;
        titleText.y = MARGIN;
        titleText.width = close.x + close.width - MARGIN;
        titleText.height = TITLETEXT_HEIGHT;
        titleText.mouseEnabled = false;
        content.addChild(titleText);
    }

    private function drawNoteText():void {

        noteText = new TextArea();
        noteText.wordWrap = true;
        noteText.editable = true;
        noteText.x = MARGIN;
        noteText.height = 50;
        noteText.width = content.width - MARGIN;
        noteText.addEventListener(Event.CHANGE, noteChanged);

    }

    private function drawBackground():void {

        content.graphics.clear();
        content.graphics.beginFill(0xcccccc);
        content.graphics.drawRoundRect(0, 0, content.width + MARGIN * 2, content.height + MARGIN * 2, 5);
        content.graphics.endFill();

        _width = content.width;
        _height = content.height;

    }

    private function resetTitle(e:Event = null):void {
        titleText.text = "Annotate";
    }

    private function expandTextField(e:Event = null):void {

        content.addChild(noteText);

        drawBackground();

        // .... if you set the TextArea.y before you add it to the stage, the
        // content.height = other content height + TextArea.y + TextArea.height
        // WHY TextArea.y is included, I have no idea. So add set the TextArea.y to 0 and
        // position it properly after you've drawn the background.
        noteText.y = highlightCircles[highlightCircles.length - 1].y + HighlightCircle.radius * 2 + MARGIN;

        var point:Point = getProperPositionForCallout();

        TweenLite.to(callout, 0.2, {y: point.y});
    }

    public static function showCallout(point:Point,
                                       callReference:* = null,
                                       stage:Sprite = null,
                                       annotation:Annotation = null,
                                       interval:ca.ubc.ece.hct.Range = null):AnnotationCalloutFlash {

        if(stage != null) {

            callout = new AnnotationCalloutFlash();
            callout.addEventListener(Event.COMPLETE, positionCallout);

            callout.alpha = 0;

            TweenLite.to(callout, 0.1, {alpha: 1});


            AnnotationCalloutFlash.stage = stage;
            AnnotationCalloutFlash.origin = point;
            AnnotationCalloutFlash.callReference = callReference;

            callout.annotation = annotation;

            AnnotationCalloutFlash.interval = interval;

        } else {

            throw new Error("AnnotationCalloutFlash: showCallout() stage must not be NULL");

        }

        return callout;

    }

    private static function getProperPositionForCallout():Point {

        var point:Point = new Point(0, 0);
        point.x = Math.max(0, Math.min(AnnotationCalloutFlash.stage.width - callout.width, origin.x - callout.width/2));

        if(origin.y + callout.height < AnnotationCalloutFlash.stage.height) {
            point.y = origin.y - callout.height - MARGIN;
        } else {
            point.y = origin.y - MARGIN;
        }

        return point;
    }

    private static function positionCallout(e:Event = null):void {

        AnnotationCalloutFlash.stage.addChild(callout);
        AnnotationCalloutFlash.stage.setChildIndex(callout, stage.numChildren-1);

        var point:Point = getProperPositionForCallout();
        callout.x = point.x;
        callout.y = point.y;

    }

    private static function closeCallout(e:Event = null):void {

        if(AnnotationCalloutFlash.stage.contains(outsideClicker))
            AnnotationCalloutFlash.stage.removeChild(outsideClicker);

        TweenLite.to(callout, 0.2, {alpha: 0,
            onComplete:
                    function removeCallout():void {

                        if(AnnotationCalloutFlash.stage.contains(callout))
                            AnnotationCalloutFlash.stage.removeChild(callout);

                    }
            });

    }

    private function highlight(e:Event):void {

        if(annotation == null) {
            annotation = new Annotation();
            annotation.interval = interval;
        }

        annotation.colour = (HighlightCircle)(e.target).colour;

        annotateSignal.dispatch(annotation);
    }

    private function noteChanged(e:Event):void {

        if(annotation == null) {
            annotation = new Annotation();
            annotation.interval = interval;
        }

        annotation.note = noteText.text;

        annotateSignal.dispatch(annotation);

    }

    private function deleteAnnotation(e:Event):void {

        if(annotation != null) {
            annotation.deleteFlag = true;
            annotateSignal.dispatch(annotation);

            // Todo: Popup window confirming deletion
        }

    }
}
}

import ca.ubc.ece.hct.myview.Util;

import flash.display.Sprite;


class HighlightCircle extends Sprite {

    public static const radius:Number = 12;
    public var colour:uint;
    public var colourName:String;

    public function HighlightCircle(colour:uint, colourName:String):void {
        this.colour = colour;
        this.colourName = colourName;
        graphics.beginFill(0xcccccc);
        graphics.drawCircle(radius, radius, radius);
        graphics.endFill();
        graphics.beginFill(Util.changeSaturation(colour, 3));
        graphics.drawCircle(radius, radius, radius - 0.5);
        graphics.endFill();
        graphics.beginFill(Util.changeSaturation(colour, 1));
        graphics.drawCircle(radius, radius, radius - 3.5);
        graphics.endFill();

        if(colour == 0xffffff) {
            graphics.lineStyle(1, 0xff00000);
            graphics.moveTo(0, 0);
            graphics.lineTo(radius * 2, radius * 2);
        }
    }
}