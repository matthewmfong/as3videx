////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {

import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.VideoATFManager;
import ca.ubc.ece.hct.myview.View;
import ca.ubc.ece.hct.myview.ui.FloatingTextField;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoUtil;

import fl.transitions.Tween;

import flash.display.Bitmap;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import org.osflash.signals.Signal;

import starling.display.Image;
import starling.display.Quad;
import flash.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.textures.Texture;

// import flash.display.Loader;
//import starling.display.Sprite;
//	import flash.events.Event;
public class ThumbnailNative extends View {

    public static var idIncrementer:uint = 0;

    protected var video:VideoMetadata;
    override public function get width():Number { return _width; }
    override public function get height():Number { return _height; }

    private var id:uint;
    protected var _timestamp:Number;

    private var vu:VideoUtil;
    private var vuRenderedSignal:Signal;

    protected var image:Bitmap;
    private var bmpD:BitmapData;

    public var imageLoaded:Boolean = true;

    private var maskingSprite:Shape;

    public var loaded:Signal;
    private var _background:Shape;
    private var floatingTime:FloatingTextField;
    public function set floatingTimeVisible(v:Boolean):void {
        if(v && !contains(floatingTime)) {
            addChild(floatingTime);
        } else if(!v && contains(floatingTime)) {
            removeChild(floatingTime);
        }
    }

    public function ThumbnailNative() {
        super();
        id = ThumbnailNative.idIncrementer++;
        vu = VideoUtil.getInstance();

        _background = new Shape();
        _background.graphics.beginFill(0xCCCCCC);
        _background.graphics.drawRect(0, 0, _width, _height);
        _background.graphics.endFill();
        maskingSprite = new Shape();
        maskingSprite.graphics.beginFill(0xCCCCCC);
        maskingSprite.graphics.drawRect(0, 0, _width, _height);
        maskingSprite.graphics.endFill();
//        this.mask = maskingSprite;

        image = new Bitmap();

        floatingTime = new FloatingTextField("0");
    }

    override protected function addedToStage(e:Event = null):void {
        super.addedToStage(e);

        addChild(_background);
    }

    public function setSize(width:Number, height:Number):void {
        _width = width;
        _height = height;

        maskingSprite.graphics.clear();
        maskingSprite.graphics.beginFill(0xCCCCCC);
        maskingSprite.graphics.drawRect(0, 0, _width, _height);
        maskingSprite.graphics.endFill();
        _background.graphics.clear();

        _background.graphics.beginFill(0xCCCCCC);
        _background.graphics.drawRect(0, 0, _width, _height);
        _background.graphics.endFill();

        if(image && contains(image)) {
            image.width = _width;
            image.height = _width / video.aspectRatio;
            image.y = _height / 2 - image.height / 2;
        }

        floatingTime.x = _width/2 - floatingTime.width/2;
        floatingTime.y = _height - floatingTime.height;
    }

    public function loadVideo(video:VideoMetadata):void {
        this.video = video;
        loaded = new Signal(ThumbnailNative);
        vuRenderedSignal = new Signal(Rectangle, ByteArray); // Dimensions, Data

        vuRenderedSignal.add(renderedFrame);
        _timestamp = 0;
    }

    public function showImage():void {
        if(video && !contains(image)) {
            seekTimeInSeconds(_timestamp);
            addEventListener(MouseEvent.MOUSE_MOVE, touched);
        }
    }

    public function hideImage():void {
        if(contains(image)) {
            removeChild(image);
            removeEventListener(MouseEvent.MOUSE_MOVE, touched);
        }
    }

    public function seekTimeInSeconds(time:Number, exact:Boolean = false, mustLoad:Boolean = false, useATF:Boolean = false):void {

        _timestamp = time;


            CONFIG::AIR {
                if (imageLoaded) {
                    imageLoaded = false;


                    vu.renderFrame(video.source[video.primarySource].localPath,
                            new Point(video.source[video.primarySource].width, video.source[video.primarySource].height),
                            video.source[video.primarySource].keyframes,
                            time,
                            _width,
                            id,
                            false,
                            exact,
                            1,
                            vuRenderedSignal);
                }
            }
    }

    private var fadeInTween:Tween;
    private var resizeFadeIn:Boolean;
    public function renderedFrame(dimensions:Rectangle, data:ByteArray):void {

        if(!bmpD || bmpD.width != dimensions.width || bmpD.height != dimensions.height) {
            if(bmpD) {
                bmpD.dispose();
            }
            bmpD = new BitmapData(dimensions.width, dimensions.height, false);
        }

        try {
            bmpD.lock();
            bmpD.setPixels(new Rectangle(0, 0, dimensions.width, dimensions.height), data);
            bmpD.unlock();
        } catch (e:Error) { }

        if(!image) {
            image = new Bitmap(bmpD);
        } else {
            image.bitmapData = bmpD;
        }

        image.width = _width;
        image.height = _width / video.aspectRatio;

        image.y = _height/2 - image.height/2;

        if(!contains(image)) {
            addChild(image);
        }

        loaded.dispatch(this);
        imageLoaded = true;

        floatingTime.text = Util.timeInSecondsToTimeString(_timestamp);
    }

    public function seekNormalized(location:Number, exact:Boolean = false, mustLoad:Boolean = false):void {
        seekTimeInSeconds(location * video.duration, exact, mustLoad);
    }

    protected function touched(e:MouseEvent):void {
        seekNormalized(e.localX / _width);
    }

//		private function mouseOut(e:MouseEvent):void {
//			 timer.addEventListener(TimerEvent.TIMER, timerComplete);
//			 timer.start();
//		}

}
}