////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui.button {

import ca.ubc.ece.hct.myview.Util;

import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	import flash.events.MouseEvent;

	public class ColourButton extends Sprite {

		private var _colour:uint;
		private var backgroundColour1:uint = 0xeeeeee, backgroundColour2:uint = 0xcccccc;
		private var saturation:Number = 1;
		private var _width:Number = 0, _height:Number = 0;
		public function ColourButton() {
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
		}

		private function draw():void {
			graphics.clear();
			graphics.lineStyle(1, 0xaaaaaa);
			// graphics.beginFill(0xeeeeee);
			var matr:Matrix = new Matrix;
			matr.createGradientBox(_width, _height, Math.PI/2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, 
				[backgroundColour1, backgroundColour2], // colour
				[1, 1],  // alpha
				[0, 255], // ratio
				matr);
			graphics.drawRoundRect(0, 0, _width, _height, 5);
			graphics.endFill();
			graphics.beginFill(Util.changeSaturation(_colour, saturation), 1);
			graphics.drawCircle(_width/2, _height/2, (_height - 5)/2);
			graphics.endFill();
		}

		private function rollOver(e:MouseEvent):void {
			backgroundColour1 = 0xcccccc;
			backgroundColour2 = 0xaaaaaa;
			saturation = 3
			draw();
		}

		private function rollOut(e:MouseEvent):void {
			backgroundColour1 = 0xeeeeee;
			backgroundColour2 = 0xcccccc;
			saturation = 2
			draw();
		}

		override public function get width():Number {
			return _width;
		}

		override public function get height():Number {
			return _height;
		}

		override public function set width(val:Number):void {
			_width = val;
			draw();
		}

		override public function set height(val:Number):void {
			_height = val;
			draw();
		}

		public function get colour():uint {
			return _colour;
		}

		public function set colour(col:uint):void {
			_colour = col;
			draw();
		}
	}
}