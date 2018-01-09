/**
 * Created by iDunno on 2017-07-25.
 */
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.widgets.StarlingWidget;

import com.greensock.TweenLite;
import com.greensock.TweenLite;

import feathers.controls.AutoSizeMode;
import feathers.controls.Callout;
import feathers.controls.LayoutGroup;
import feathers.controls.ToggleButton;
import feathers.core.FeathersControl;
import feathers.core.ToggleGroup;
import feathers.layout.HorizontalAlign;
import feathers.layout.HorizontalLayout;
import feathers.layout.RelativePosition;
import feathers.layout.VerticalAlign;

import mx.controls.Text;

import org.osflash.signals.Signal;

import starling.display.DisplayObject;

import starling.display.Image;
import starling.display.Quad;

import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.filters.ColorMatrixFilter;
import starling.text.TextFormat;

public class AnnotationCallout extends Sprite {

    public static const ADD_HIGHLIGHT_MODE:String = "AnnotationCallout.ADD_HIGHLIGHT_MODE";
    public static const DEL_HIGHLIGHT_MODE:String = "AnnotationCallout.DEL_HIGHLIGHT_MODE";

    public static const GAP:int = 5;
    public static const TAB_HEIGHT:int = 30;
    public static var TAB_ACTIVE:String = "HIGHLIGHT";

    private var background:Quad;
    private var highlightContainer:Sprite;
    private var circles:Array;
    private var deleteImage:Image;
    private var highlightable:Array;
    private var deletable:Array;
    private var circlesVisible:Array;

    private var tagContainer:Sprite;

    private var tabToggleGroup:ToggleGroup;
    private var highlightButton:ToggleButton;
    private var tagButton:ToggleButton;

    public var addDeleteMode:String;

    public var highlightSignal:Signal;
    public var keywordTagSignal:Signal;
    private var callout:Callout;
    public static var caller:*;

    public function AnnotationCallout() {
        highlightable = [];
        deletable = [];
        background = new Quad(1, 1);
        init();
        addDeleteMode = ADD_HIGHLIGHT_MODE;
        highlightSignal = new Signal(uint, String); // Colour
        keywordTagSignal = new Signal(KeywordTag);

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
                                       callReference:* = null):Callout {
        caller = callReference;

        var content:AnnotationCallout = new AnnotationCallout();
        content.setColours(highlightable, deletable);
        content.initTags();

        StarlingWidget.allWidgetSwapStarlingNative();
        var callout:Callout = Callout.show(content, target, new <String>[RelativePosition.TOP] );
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
        highlightContainer.y = TAB_HEIGHT;
    }

    private function init():void {
        highlightContainer = new Sprite();
        addChild(background);
        background.alpha = 0;
        background.touchable = false;

        tagContainer = new Sprite();

        var toggleButtonTextFormat:TextFormat = new TextFormat("Arial", 12);
        var selectedToggleButtonTextFormat:TextFormat = new TextFormat("Arial", 12, Colours.BUTTON_ACTIVATED_FONT_COLOUR);

        tabToggleGroup = new ToggleGroup();

        highlightButton = new ToggleButton();
        highlightButton.label = "Highlight";
        highlightButton.height = TAB_HEIGHT;
        highlightButton.fontStyles = toggleButtonTextFormat;
        highlightButton.selectedFontStyles = selectedToggleButtonTextFormat;
        highlightButton.padding = 3;
        addChild(highlightButton);
        highlightButton.validate();
        highlightButton.toggleGroup = tabToggleGroup;

        tagButton = new ToggleButton();
        tagButton.label = "Tag";
        tagButton.x = highlightButton.width;
        tagButton.height = TAB_HEIGHT;
        tagButton.fontStyles = toggleButtonTextFormat;
        tagButton.selectedFontStyles = selectedToggleButtonTextFormat;
        tagButton.padding = 3;
        tagButton.toggleGroup = tabToggleGroup;
        addChild(tagButton);

        if(TAB_ACTIVE == "HIGHLIGHT") {
            highlightButton.isSelected = true;
            tagButton.isSelected = false;

            addChild(highlightContainer);

        } else if(TAB_ACTIVE == "TAG") {
            highlightButton.isSelected = false;
            tagButton.isSelected = true;

            addChild(tagContainer);
        }

        tabToggleGroup.addEventListener(Event.CHANGE, tabToggleGroupChanged);

    }

    private function tabToggleGroupChanged(e:Event):void {

        var oldTab:Sprite;
        var newTab:Sprite;

        if(tabToggleGroup.selectedItem == highlightButton) {

            TAB_ACTIVE = "HIGHLIGHT";
            newTab = highlightContainer;

            if(contains(tagContainer)) {
                removeChild(tagContainer);
                oldTab = tagContainer;
            }

            if(!contains(highlightContainer)) {
                addChild(highlightContainer);
            }

        } else if(tabToggleGroup.selectedItem == tagButton) {

            TAB_ACTIVE = "TAG";
            newTab = tagContainer;

            if(contains(highlightContainer)) {
                removeChild(highlightContainer);
                oldTab = highlightContainer;
            }

            if(!contains(tagContainer)) {
                addChild(tagContainer);
            }


        }


        callout.height = callout.height - oldTab.height + newTab.height;

        callout.invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
        callout.validate();

    }

    private function initTags():void {
        var likeTag:KeywordTag = new KeywordTag("Like", new ca.ubc.ece.hct.Range(1, 1), Colours.BLUE, KeywordTag.THUMBS_UP);
        var interestingTag:KeywordTag = new KeywordTag("Interesting", new ca.ubc.ece.hct.Range(1, 1), Colours.YELLOW, KeywordTag.STAR);
        var importantTag:KeywordTag = new KeywordTag("Important", new ca.ubc.ece.hct.Range(1, 1), Colours.RED, KeywordTag.CAUTION);
        var questionTag:KeywordTag = new KeywordTag("Question", new ca.ubc.ece.hct.Range(1, 1), Colours.BLUE, KeywordTag.QUESTION_MARK);

        tagContainer.y = TAB_HEIGHT;
        tagContainer.addChild(likeTag.sprite);
        tagContainer.addChild(interestingTag.sprite);
        tagContainer.addChild(importantTag.sprite);
        tagContainer.addChild(questionTag.sprite);

        var PADDING:uint = 2;
        likeTag.sprite.y = 0;
        interestingTag.sprite.y = likeTag.sprite.y + likeTag.sprite.height + PADDING;
        importantTag.sprite.y = interestingTag.sprite.y + interestingTag.sprite.height + PADDING;
        questionTag.sprite.y = importantTag.sprite.y + importantTag.sprite.height + PADDING;

        likeTag.sprite.addEventListener(TouchEvent.TOUCH, tagTouch);
        interestingTag.sprite.addEventListener(TouchEvent.TOUCH, tagTouch);
        importantTag.sprite.addEventListener(TouchEvent.TOUCH, tagTouch);
        questionTag.sprite.addEventListener(TouchEvent.TOUCH, tagTouch);

    }

    private function addButtons(colours:Array):void {

        circlesVisible = [];
        var i:int = 0;
        for(i = 0; i<Colours.colours.length; i++) {
            if(Util.arrayContains(colours, Colours.colours[i])){

                if(!highlightContainer.contains(circles[i])) {
                    highlightContainer.addChild(circles[i]);
                }

                circlesVisible.push(circles[i]);

            } else if(!Util.arrayContains(colours, Colours.colours[i]) && highlightContainer.contains(circles[i])) {
                Animate.shrinkAndDisappear(circles[i]).addOnce(
                        function remove(t:DisplayObject):void {
                            highlightContainer.removeChild(t);
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

        if(!highlightContainer.contains(deleteImage)) {
            highlightContainer.addChild(deleteImage);
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

        background.readjustSize((Colours.colours.length + 1) * (2 * HighlightCircle.radius + GAP) - GAP,
                                HighlightCircle.radius * 2 + TAB_HEIGHT);

    }

    private function circleTouch(e:TouchEvent):void {
        var circle:HighlightCircle = (HighlightCircle)(e.currentTarget);
        var touch:Touch = e.getTouch(circle, TouchPhase.ENDED);

        if(touch) {
            highlightSignal.dispatch(circle.colour, addDeleteMode);

            if(addDeleteMode == DEL_HIGHLIGHT_MODE) {
                Animate.shrinkAndDisappear(circle).addOnce(
                        function removeCirle(c:DisplayObject):void {
                            highlightContainer.removeChild(c);
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

    private function tagTouch(e:TouchEvent):void {
        var keywordTagSprite:KeywordTagSprite = (KeywordTagSprite)(e.currentTarget);
        var touch:Touch = e.getTouch(keywordTagSprite, TouchPhase.ENDED);

        if(touch) {
            keywordTagSignal.dispatch(keywordTagSprite.tag);
            callout.close();
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
