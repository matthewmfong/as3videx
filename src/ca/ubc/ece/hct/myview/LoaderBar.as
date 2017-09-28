////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

	import com.greensock.*;
	import com.greensock.easing.*;

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class LoaderBar extends Sprite {

		private var _width:Number;
		private var _height:Number;
		private var _mask:Shape;
		private var _background:Shape;
		private var _progressBar:Shape;
		private var _colour:uint = 0x999999;
		private var _backgroundColour:uint = 0xdddddd;
		private var _cornerRadius:uint = 4;

		public function LoaderBar(w:Number, h:Number) {
			_width = w;
			_height = h;
			_mask = new Shape();
			drawMask();
			addChild(_mask);
			this.mask = _mask;

			_background = new Shape();
			drawBackground();
			addChild(_background);

			_progressBar = new Shape();
			drawProgressBar();
			addChild(_progressBar);
		}

		public function setProgress(val:Number):void {
			_progressBar.x = val * _width - _width/2;
		}

		public function animateOut():void {
			if(contains(_background))
				removeChild(_background);
			TweenLite.to(_mask, 0.1, {x: -500, width: 2000, height: 2000, delay: 0.2});
			TweenLite.to(_progressBar, 0.5, 
						{width: 0, height: 0, alpha:0, delay: 0.2, ease: Back.easeIn,
						onComplete: function animationComplete():void {
										destroy();
										dispatchEvent(new Event(Event.COMPLETE));
									}});
		}

		public function destroy():void {
			if(contains(_mask))
				removeChild(_mask);
			if(contains(_background))
				removeChild(_background);
			if(contains(_progressBar))
				removeChild(_progressBar);
			_mask = null;
			_background = null;
			_progressBar = null;
		}

		public function set colour(val:uint):void {
			_colour = val;
			drawProgressBar();
		}

		public function set backgroundColour(val:uint):void {
			_backgroundColour = val;
			drawBackground();
		}

		public function set cornerRadius(val:uint):void {
			_cornerRadius = val;
			drawMask();
			drawProgressBar();
			drawBackground();
		}

		private function drawMask():void {
			_mask.graphics.clear();
			_mask.graphics.beginFill(0xff00ff);
			_mask.graphics.drawRoundRect(0, -_height/2, _width, _height, _cornerRadius);
			_mask.graphics.endFill();
		}

		private function drawProgressBar():void {
			_progressBar.graphics.clear();
			_progressBar.graphics.beginFill(_colour);
			_progressBar.graphics.drawRoundRect(-width/2, -_height/2, _width, _height, _cornerRadius);
			_progressBar.graphics.endFill();
		}

		private function drawBackground():void {
			_background.graphics.clear();
			_background.graphics.beginFill(_backgroundColour);
			_background.graphics.drawRoundRect(0, -_height/2, _width, _height, _cornerRadius);
			_background.graphics.endFill();
		}

		override public function get width():Number { return _width; }
		override public function set width(val:Number):void { _width = val; }
		override public function get height():Number { return _height; }
		override public function set height(val:Number):void { _height = val; }
	}
}