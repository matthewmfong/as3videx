////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.common.Highlightable;

// import ca.ubc.ece.hct.myview.video.VideoInfo;

	import org.osflash.signals.Signal;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;

	public class WebThumbnail extends Highlightable {

		private var _initialTime:Number;
		public var _lastTime:Number;

		private var videoFilename:String

		// if you resize things afterwards, MouseEvent.localX still uses the original size.
		private var originalWidth:uint;
		private var originalHeight:uint;

		private var bmp:Bitmap;
		private var bmpD:BitmapData
		private var overlay:Sprite;
		protected var thumbnailWidth:uint = 240;
		protected var thumbnailHeight:uint;

		private var maskingSprite:Sprite;

		private var wtg:WebThumbnailGenerator;

		public var loaded:Signal;
		public var ready:Boolean;

		public var interactive:Boolean;

		public function WebThumbnail(videoFilename:String, width:Number, height:Number, initialTime:Number = 0) {

			loaded = new Signal(WebThumbnail);

			this.videoFilename = videoFilename;

        	maskingSprite = new Sprite();
        	maskingSprite.graphics.beginFill(0xff00ff);
        	maskingSprite.graphics.drawRect(0, 0, width, height);
        	maskingSprite.graphics.endFill();
        	addChild(maskingSprite);
        	this.mask = maskingSprite;

	        thumbnailWidth = width;
	        thumbnailHeight = height;

			bmp = new Bitmap();
			bmp.cacheAsBitmap = true;
			// bmp.opaqueBackground = 0;
			bmpD = new BitmapData(thumbnailWidth, thumbnailHeight);
			bmp.bitmapData = bmpD;
			addChild(bmp);

			overlay = new Sprite();
			addChild(overlay);

			originalWidth = width;
			originalHeight = height;

			// if(initialTime > _video.duration)
				// initialTime = 0;	

			_initialTime = initialTime;
			_lastTime = _initialTime;

			// trace("HAHAHAH" + initialTime);
			ready = false;

			seekTimeInSeconds(initialTime);

			if(interactive) {
				addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				addEventListener(MouseEvent.ROLL_OUT, mouseOut);
			}
		}

		// public function get video():Video {
		// 	return _video;
		// }

		public function set video(val:String):void {
			videoFilename = val;
		}

		public function cleanup():void {
			// _video = null;

			if(interactive) {
				removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				removeEventListener(MouseEvent.ROLL_OUT, mouseOut);
			}
		}

		public function seekTimeInSeconds(time:Number):void {

			_lastTime = time;

			if(wtg == null)
				wtg = WebThumbnailGeneratorManager.getGenerator(videoFilename);

			ready = false;

			wtg.thumbnailLoaded.add(receivedThumbnail);
			wtg.getThumbnailInSeconds(time, this);

		}

		private function receivedThumbnail(bmpData:BitmapData, target:Object):void {
			if(target == this) {
				bmp.bitmapData = bmpData;
				wtg.thumbnailLoaded.remove(receivedThumbnail);

				bmp.width = thumbnailWidth;
				bmp.height = thumbnailHeight;

				ready = true;
				loaded.dispatch(this);
			}
		}

		public function seekNormalized(location:Number):void {
			seekTimeInSeconds(location * 240);//video.duration);
		}

		public function resize(newWidth:uint, newHeight:uint):void {
			thumbnailWidth = newWidth;
			thumbnailHeight = newHeight;

			bmp.width = newWidth;
			bmp.height = newHeight;

			maskingSprite.graphics.clear();
        	maskingSprite.graphics.beginFill(0xff00ff);
        	maskingSprite.graphics.drawRect(0, 0, newWidth, newHeight);
        	maskingSprite.graphics.endFill();

			overlay.graphics.clear();
			overlay.graphics.lineStyle(2, 0x111111)
			overlay.graphics.beginFill(0x555555, 0.4);
			overlay.graphics.drawRect(0, 0, thumbnailWidth, thumbnailHeight);
			overlay.graphics.endFill();
		}

		override public function set width(val:Number):void {
			resize(val, thumbnailHeight);
		}
		override public function set height(val:Number):void {
			resize(thumbnailWidth, val);
		}

		public function mouseMove(e:MouseEvent):void {
			seekNormalized(e.localX/originalWidth);
		}

		public function mouseOut(e:MouseEvent):void {
			// timer.addEventListener(TimerEvent.TIMER, timerComplete);
			// timer.start();
		}

	}
}