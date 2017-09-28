////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {

import starling.display.Shape;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;

public class FloatingTextField extends Shape {

		private var textField:TextField;
		private var background:Shape;

		public function FloatingTextField(str:String = null, textFormat:TextFormat = null):void {
			mouseEnabled = false;

			textField = new TextField(200, 200);
			textField.touchable = false;
			textField.format = (textFormat != null) ? textFormat : new TextFormat("Arial", 10, 0xFFFFE8, "center");
//					new TextFormat("Arial", // font
//							10, // size
//							0xFFFFE8, // color
//							true, // bold
//							false, // italic
//							false, // underline
//							null, // url
//							null, // target
//							"center", // align
//							null, // left margin
//							null, // right margin
//							null, // indent
//							4); // leading
			textField.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
			textField.text = (str != null) ? str : "";

			background = new Shape();

			draw();

			addChild(background);
			addChild(textField);
		}

		public function set text(str:String):void {
			textField.text = str;
			textField.x = 0;
			draw();
		}

		 public function set mouseEnabled(val:Boolean):void {
			if(textField)
				textField.touchable = val;
		}

		public function set defaultTextFormat(val:TextFormat):void {
			textField.format = val;
		}

		private function draw():void {
			background.graphics.clear();
			background.graphics.beginFill(0x333333, 0.5);
			background.graphics.drawRoundRect(textField.x - 2, textField.y - 1, textField.width + 2, textField.height + 2, 4);
			background.graphics.endFill();  
		}
	}
}