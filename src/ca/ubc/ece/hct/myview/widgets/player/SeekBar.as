////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {

import ca.ubc.ece.hct.myview.thumbnail.WebThumbnail;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import com.greensock.*;
	import com.greensock.easing.*;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import ca.ubc.ece.hct.ImageLoader;
	import ca.ubc.ece.hct.myview.ui.StarlingFloatingTextField;

	import org.osflash.signals.Signal;

	public class SeekBar extends Sprite {

		private var _width:Number;
		private var _height:Number;
		private var _video:VideoMetadata;
		private var _showPreviewThumbnail:Boolean;
		private var previewThumbnail:WebThumbnail;
		private var previewText:StarlingFloatingTextField;
		private var seekPoint:ImageLoader;

		private var redBar:Shape;
		private var seekbar:Shape;
		private var _mask:Shape;

		public var clicked:Signal;

		public function SeekBar(video:VideoMetadata, width:Number, height:Number) {
			_width = width;
			_height = height;
			_video = video;

			addEventListener(MouseEvent.ROLL_OVER, mouseOver);
			addEventListener(MouseEvent.CLICK, mouseClick);

			_showPreviewThumbnail = true;
			previewThumbnail = new WebThumbnail(_video.filename, 240, 240 / _video.aspectRatio);
			previewThumbnail.y = -previewThumbnail.height - 10;
			previewThumbnail.mouseEnabled = false
			previewText = new StarlingFloatingTextField();
			previewText.y = previewThumbnail.y + previewThumbnail.height - previewText.height;

			seekPoint = new ImageLoader("uiimage/seekpoint.png");
			seekPoint.y = 6;
			seekPoint.mouseEnabled = false;

			_mask = new Shape();
			addChild(_mask);
			this.mask = _mask;

			seekbar = new Shape();
			addChild(seekbar);

			redBar = new Shape();
			addChild(redBar);

			render();

			clicked = new Signal(Number); // time
		}

		public function seek(time:Number):void {
			var newPoint:Number = time/_video.duration * _width;

			seekPoint.x = newPoint - seekPoint.width/2;
			redBar.x = newPoint;
		}

		public function set showPreviewThumbnail(val:Boolean):void {
			_showPreviewThumbnail = val;
			if(!val) {
				if(contains(previewThumbnail)) removeChild(previewThumbnail);
				if(contains(previewText)) removeChild(previewText);
			} else {
				if(!contains(previewThumbnail)) addChild(previewThumbnail);
				if(!contains(previewText)) addChild(previewText);
			}
		}

		private function mouseClick(e:MouseEvent):void {
			clicked.dispatch(e.localX/_width * _video.duration);
		}

		private function mouseOver(e:MouseEvent):void {

			removeEventListener(MouseEvent.ROLL_OVER, mouseOver);
			addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			addEventListener(MouseEvent.ROLL_OUT, mouseOut);
			if(_showPreviewThumbnail) {
				if(!contains(previewThumbnail)) addChild(previewThumbnail);
				if(!contains(previewText)) addChild(previewText);
				previewText.alpha = 0;
				previewThumbnail.alpha = 0;
				TweenLite.to([previewThumbnail, previewText], 0.5,
							{alpha: 1,
						onComplete: function mouseOverComplete():void {
							}});
			}
		}

		private function mouseOut(e:MouseEvent):void {

			removeEventListener(MouseEvent.ROLL_OUT, mouseOut);
			removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			addEventListener(MouseEvent.ROLL_OVER, mouseOver);
			if(_showPreviewThumbnail) {
				TweenLite.to([previewThumbnail, previewText], 0.2,
							{alpha: 0,
						onComplete: function mouseOutComplete():void {
										if(contains(previewThumbnail))
											removeChild(previewThumbnail);
										if(contains(previewText))
											removeChild(previewText);
							}});
			}
		}

		private function mouseMove(e:MouseEvent):void {
			if(e.localY < seekbar.y - 20 && hasEventListener(MouseEvent.ROLL_OUT)) {
				mouseOut(null);
				return;
			}
			previewThumbnail.seekNormalized(e.localX / _width);
			var previewThumbnailX:Number = e.localX - previewThumbnail.width/2
			previewThumbnailX = e.localX - previewThumbnail.width/2;
			if(previewThumbnailX < 0)
				previewThumbnail.x = 0;
			else if(previewThumbnailX + previewThumbnail.width > _width)
				previewThumbnail.x = _width - previewThumbnail.width;
			else
				previewThumbnail.x = previewThumbnailX;

			previewText.text = timeInSecondsToTimeString(e.localX/_width * _video.duration);
			previewText.x = previewThumbnail.x + previewThumbnail.width/2 - previewText.width/2;

		}

		private function render():void {
			_mask.graphics.beginFill(0xff00ff, 1);
			_mask.graphics.drawRect(0, -300, _width, 300 + height);
			_mask.graphics.endFill();

			graphics.beginFill(0xFF00FF, 0);
			graphics.drawRect(0, -10, _width, 10);
			graphics.endFill();

			seekbar.graphics.beginFill(0x777777);
			seekbar.graphics.drawRect(0, 0, _width, _height);
			seekbar.graphics.endFill();

			redBar.graphics.beginFill(0xff0000);
			redBar.graphics.drawRect(-_width, 0, _width, _height);
			redBar.graphics.endFill();
		}

		public function set video(val:VideoMetadata):void {
			_video = val;
		}

		override public function set width(val:Number):void {
			_width = val;
			render();
		}

		override public function set height(val:Number):void {
			_height = val;
			render();
		}

		override public function get width():Number { return _width; }
		override public function get height():Number { return _height; }

		public function timeInSecondsToTimeString(timeX:Number):String {
			var newMinutes:String = uint(timeX/60).toString();
			newMinutes = newMinutes.length == 1 ? "0" + newMinutes : newMinutes;
			var newSeconds:String = uint(timeX%60).toString();
			newSeconds = newSeconds.length == 1 ? "0" + newSeconds : newSeconds;
			return newMinutes + ":" + newSeconds;
		}
	}
}