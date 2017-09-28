////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.subtitleviewer {

import ca.ubc.ece.hct.myview.Util;

import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class SubtitleViewerTimeTextField extends Sprite {

		public var time:Number;
		private var textfield:TextField;
//		public var originalX:Number, originalY:Number;
//		private var highlightBalls:Shape;

		public function SubtitleViewerTimeTextField() {
			textfield = new TextField();
			textfield.mouseEnabled = false;
			textfield.x = 0;
			textfield.y = 0;
			addChild(textfield);
//			highlightBalls = new Shape();
//			highlightBalls.graphics.lineStyle(1, 0, 0);
//			highlightBalls.graphics.beginFill(0, 0);
//			highlightBalls.graphics.drawCircle(0, 0, 10);
//			highlightBalls.graphics.endFill();
//			addChild(highlightBalls);
			
			// graphics.lineStyle(1, 0);
			// graphics.beginFill(0xff0000, 0.3)
			// graphics.drawRect(0, 0, width, height);
			// graphics.endFill();
		}

		public function set text(val:String):void {
			textfield.text = val;
			textfield.x = 0;
		}

		public function get text():String {
			return textfield.text;
		}

		public function set defaultTextFormat(val:TextFormat):void {
			textfield.defaultTextFormat = val;
			textfield.x = 0;
		}

		public function set autoSize(val:String):void {
			textfield.autoSize = val;
			textfield.x = 0;
//			highlightBalls.x = textfield.width + 12;
//			highlightBalls.y = textfield.height/2 - 2;
		}

//		public function drawHighlights(highlights:Array):void {
//			highlightBalls.graphics.clear();
//			if(highlights.length > 0) {
//				highlightBalls.graphics.lineStyle(1, 0xcccccc);
//				highlightBalls.graphics.beginFill(0xdddddd, 1);
//				highlightBalls.graphics.drawCircle(0, 0, 10);
//				highlightBalls.graphics.endFill();
//
//				highlightBalls.graphics.beginFill(0xeeeeee, 1);
//				highlightBalls.graphics.drawCircle(0, 0, 7);
//				highlightBalls.graphics.endFill();
//				// highlightSprite.x = textfield.x;
//			}
//
//			for(var i:int = 0; i<highlights.length; i++) {
//				highlightBalls.graphics.lineStyle(1, Util.brighten(Util.changeSaturation(highlights[i], 5), 0.9));
//				highlightBalls.graphics.beginFill(Util.changeSaturation(highlights[i], 2));
//				var currentAngle:Number = 2*Math.PI*i/highlights.length - Math.PI/2;
//				highlightBalls.graphics.drawCircle(0 + 5 * Math.cos(currentAngle),
//												        5 * Math.sin(currentAngle), 4);
//				// highlightBalls.graphics.drawCircle(0, tf.height/2 + (i-highlights.length/2)*5, 5);
//				highlightBalls.graphics.endFill();
//			}
//		}
	}
}