////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {

import ca.ubc.ece.hct.myview.StarlingView;
import ca.ubc.ece.hct.myview.VideoATFManager;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoUtil;
import ca.ubc.ece.hct.myview.video.VideoUtilEvent;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import org.osflash.signals.Signal;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;

import starling.display.Canvas;

import starling.display.Image;

import starling.display.Quad;

import starling.display.Shape;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.textures.Texture;

// import flash.display.Loader;
	import starling.display.Sprite;
//	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	public class Thumbnail extends StarlingView {

        public static var idIncrementer:uint = 0;

		protected var video:VideoMetadata;
        override public function get width():Number { return _width; }
        override public function get height():Number { return _height; }

		private var id:uint;
		protected var _timestamp:Number;

		private var vu:VideoUtil;
		private var vuRenderedSignal:Signal;

		protected var image:Image;
		private var bmpD:BitmapData;

		public var imageLoaded:Boolean = true;

		private var maskingSprite:Quad;

		public var loaded:Signal;
		private var _background:Quad;

		public function Thumbnail() {
			super();
			id = Thumbnail.idIncrementer++;
			vu = VideoUtil.getInstance();

			_background = new Quad(_width, _height, 0xCCCCCC);
            mask = new Quad(_width, _height);
		}

		override protected function addedToStage(e:Event = null):void {
			super.addedToStage(e);

            addChild(_background);
		}

        public function setSize(width:Number, height:Number):void {
            _width = width;
            _height = height;

			(Quad)(mask).readjustSize(_width, _height);
            _background.readjustSize(_width, _height);

            if(image && contains(image)) {
                image.width = _width;
                image.height = _width / video.aspectRatio;
                image.y = _height / 2 - image.height / 2;
            }
        }

		public function loadVideo(video:VideoMetadata):void {
			this.video = video;
            loaded = new Signal(Thumbnail);
            vuRenderedSignal = new Signal(Rectangle, ByteArray); // Dimensions, Data
			_timestamp = 0;
		}

		public function showImage():void {
			if(video && !contains(image)) {
                seekTimeInSeconds(_timestamp);
                addEventListener(TouchEvent.TOUCH, touched);
            }
		}

		public function hideImage():void {
			if(contains(image)) {
				removeChild(image);
                removeEventListener(TouchEvent.TOUCH, touched);
			}
		}

		public function seekTimeInSeconds(time:Number, exact:Boolean = false, mustLoad:Boolean = false, useATF:Boolean = false):void {

            _timestamp = time;


			// if VideoATFManager has loaded the correct video && is finished loading
			if(VideoATFManager.video == video && !VideoATFManager.openingInProgress) {

                if(!image) {
                    image = new Image(VideoATFManager.getTexture(time));
                } else {
                    image.texture.dispose();
                    image.texture = VideoATFManager.getTexture(time);
                }

                image.width = _width;
                image.height = _width / video.aspectRatio;

                image.y = _height/2 - image.height/2;

                if(!contains(image)) {
                    addChild(image);
                }

                loaded.dispatch(this);
                imageLoaded = true;

            } else {

                CONFIG::AIR {
                    if (imageLoaded) {
                        imageLoaded = false;

                        vuRenderedSignal.addOnce(renderedFrame);

                        vu.renderFrame(video.source[video.primarySource].localPath,
                                new Point(video.source[video.primarySource].width, video.source[video.primarySource].height),
                                video.source[video.primarySource].keyframes,
                                time,
                                _width,
                                id,
                                true,
                                exact,
                                1,
                                vuRenderedSignal);
//					trace(id + " RENDER ME PLX");
                    }
                }
			}
		}

		private function imageLoadedFromWeb(time:Number, data:Image, target:*):void {
			if(target == this) {
                image = data;
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
                image = new Image(Texture.fromBitmapData(bmpD));
            } else {
				image.texture.dispose();
                image.texture = Texture.fromBitmapData(bmpD);
            }

			image.width = _width;
			image.height = _width / video.aspectRatio;

			image.y = _height/2 - image.height/2;

			if(!contains(image)) {
                addChild(image);
			}

			loaded.dispatch(this);
			imageLoaded = true;
		}

		public function seekNormalized(location:Number, exact:Boolean = false, mustLoad:Boolean = false):void {
			seekTimeInSeconds(location * video.duration, exact, mustLoad);
		}

		private var touch:Touch;
		protected function touched(e:TouchEvent):void {
			touch = e.getTouch(this, TouchPhase.HOVER)
			if(touch) {
                seekNormalized(touch.getLocation(this).x / _width);
            }
		}

//		private function mouseOut(e:MouseEvent):void {
//			 timer.addEventListener(TimerEvent.TIMER, timerComplete);
//			 timer.start();
//		}

	}
}