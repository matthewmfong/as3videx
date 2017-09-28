////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.filmstrip {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.Util;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

import org.osflash.signals.Signal;
import org.osflash.signals.natives.NativeSignal;

import starling.display.Canvas;

import starling.display.Sprite;

//import starling.display.Shape;

public class FilmstripHighlight extends Canvas {

		public var timeRange:Range;
		public var colour:uint;
		public var _width:Number, _height:Number;
		public var glowValue:Number;

		public var actionLogSignal:Signal;
		public var clickSignal:Signal;
		private var enterFrameSignal:NativeSignal;

		public function FilmstripHighlight(timeRange:Range,
											dimensions:Rectangle,
											colour:uint) {
			this.timeRange = timeRange;
			this.colour = colour;

			_width = dimensions.width;
			_height = dimensions.height;

			glowValue = 0;

			actionLogSignal = new Signal(String);
//			addEventListener(MouseEvent.CLICK, click);
//			addEventListener(MouseEvent.ROLL_OVER, rollOver);
//			addEventListener(MouseEvent.ROLL_OUT, rollOut);
			clickSignal = new Signal(Range, uint); // timeRange, colour
//			enterFrameSignal = new NativeSignal(this, Event.ENTER_FRAME, Event);

			draw();
		}

//		private function click(e:MouseEvent):void {
//			actionLogSignal.dispatch("Filmstrip: Highlight - Click - #" + colour.toString(16) + " - " + timeRange);
//			clickSignal.dispatch(timeRange, colour);
//		}
//
//		private function rollOver(e:MouseEvent):void {
//			actionLogSignal.dispatch("Filmstrip: Highlight - Mouse Over - #" + colour.toString(16) + " - " + timeRange);
////			enterFrameSignal.add(glowPositive);
//		}
//
//		private function rollOut(e:MouseEvent):void {
////			enterFrameSignal.add(glowNegative);
//		}

		private function glowPositive(e:Event = null):void {
			if(glowValue < 0.5) {
				glowValue += 0.05;
				draw();
			} else {
//				enterFrameSignal.remove(glowPositive);
			}
		}

		private function glowNegative(e:Event = null):void {
			if(glowValue > 0) {
				glowValue -= 0.2;
				draw();
			} else {
//				enterFrameSignal.remove(glowPositive);
			}
		}

		private function draw():void {
			// main line
			beginFill(Util.changeSaturation(colour, 2 + glowValue), 1);
			drawRectangle(0, 0, _width, _height);
			endFill();

			// top shine
			beginFill(Util.brighten(colour, 1.1 + glowValue), 1);
			drawRectangle(0, 0, _width, 1);
			endFill();

			// bottom shadow
			beginFill(Util.brighten(colour, 0.9 + glowValue), 1);
			drawRectangle(0, _height-1, _width, 1);
			endFill();
		}
	}
}