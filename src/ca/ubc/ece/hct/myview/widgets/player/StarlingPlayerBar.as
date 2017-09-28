////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////
package ca.ubc.ece.hct.myview.widgets.player {
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.VidexStarling;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.StarlingWidget;

import feathers.controls.Header;

import org.osflash.signals.Signal;

import starling.display.DisplayObject;

import starling.display.Image;

import starling.display.Quad;

import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;

public class StarlingPlayerBar extends StarlingWidget {

    public var player:Player;
    private var _this:StarlingPlayerBar;

    private var background:Header;
    private var playButton:Image;
    private var ccButton:Image;
    private var fullscreenButton:Image;
    private var timeLabel:TextField;

//    public var playSignal:Signal;
//    public var ccSignal:Signal;
//    public var enlargeSignal:Signal;
//    public var playbackRateSignal:Signal;
//    public var seekSignal:Signal;

    private var playing:Boolean = true;
    private var ccOn:Boolean = false;
    private var fullscreenOn:Boolean = false;

    public function StarlingPlayerBar() {
        _this = this;

        background = new Header();

        playButton = new Image(VidexStarling.assets.getTexture("playerBarPlay"));
        ccButton = new Image(VidexStarling.assets.getTexture("playerBarCCOff"));
        fullscreenButton = new Image(VidexStarling.assets.getTexture("playerBarFullscreenOn"));

    }

    override protected function addedToStage(e:Event = null):void {
        super.addedToStage(e);
        background.backgroundSkin = new Quad(_width, _height, 0x1b1b1b);
        background.setSize(_width, _height);
        background.alpha = 0.8;
        background.padding = 2;
        background.validate();
        addChild(background);

        timeLabel = new TextField(100, _height);
        timeLabel.autoSize = TextFieldAutoSize.HORIZONTAL;
        timeLabel.format = new TextFormat("Arial", 10, 0xFFFFFF);


        background.leftItems = new <DisplayObject> [ playButton, timeLabel ];
        background.rightItems = new <DisplayObject> [ ccButton, fullscreenButton ];

        background.addEventListener(TouchEvent.TOUCH, touched);

    }

    public function pause():void {
        playButton.texture = VidexStarling.assets.getTexture("playerBarPlay");
        playing = false;
    }

    override public function play():void {
        playButton.texture = VidexStarling.assets.getTexture("playerBarPause");
        playing = true;
    }

    public function setPlayTime(time:Number):void {

        timeLabel.text = Util.timeInSecondsToTimeString(time);

        if(player) {
            timeLabel.text += " / " + Util.timeInSecondsToTimeString(player.video.duration);
        }

    }

    private function touched(e:TouchEvent):void {
        var touch:Touch = e.getTouch(background, TouchPhase.ENDED);
        if(touch) {
            switch(e.target) {
                case playButton:
                        if(playing) {
                            pause();
                            stopped.dispatch(_this);
                        } else {
                            play();
                            played.dispatch(_this);
                        }
                    break;
                case ccButton:
                        if(ccOn) {
                            ccButton.texture = VidexStarling.assets.getTexture("playerBarCCOff");
                        } else {
                            ccButton.texture = VidexStarling.assets.getTexture("playerBarCCOn");
                        }
                        ccOn = !ccOn;
                        ccToggled.dispatch(_this, ccOn);
                    break;
                case fullscreenButton:

                    if(fullscreenOn) {
                        fullscreenButton.texture = VidexStarling.assets.getTexture("playerBarFullscreenOn");
                    } else {
                        fullscreenButton.texture = VidexStarling.assets.getTexture("playerBarFullscreenOff");
                    }
                    fullscreenOn = !fullscreenOn;
                    fullscreenToggled.dispatch(_this, fullscreenOn);
                    break;
            }
        }
    }

    public function maximize():void {}

    public function minimize():void {}

    override public function setSize(width:Number, height:Number):void {
        super.setSize(width, height);
        background.setSize(_width, _height);
        background.validate();
    }
}
}
