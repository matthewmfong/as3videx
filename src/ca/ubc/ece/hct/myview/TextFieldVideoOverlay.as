////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {
	
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class TextFieldVideoOverlay extends Sprite {

		private var tf:TextField;
		private var uiscroll:UIScrollView;

		public function TextFieldVideoOverlay(text:String, maxWidth:Number, maxHeight:Number) {


			tf = new TextField();
			tf.defaultTextFormat = new TextFormat("Arial", 10, 0xFFFFE8, true, false, false, null, null, "left", null, null, null, 4);
			tf.autoSize = "left"
			tf.wordWrap = true;
			tf.multiline = true;
			tf.text = text;

			uiscroll = new UIScrollView(Math.min(tf.width, maxWidth), Math.min(tf.height, maxHeight));
			addChild(uiscroll);
			uiscroll.source = tf;


			graphics.beginFill(0x666666, 0.6);
			graphics.drawRoundRect(0, 0, Math.min(tf.width, maxWidth), Math.min(tf.height, maxHeight), 30);
			graphics.endFill();
		}
	}
}