////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.common {

	import com.greensock.*;
	import com.greensock.easing.*;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class CaptionView extends Sprite {

		private var activeDisplay:uint;
		private var inactiveDisplay:uint;

	    private var captionDisplay:Array;
	    private var captionFormat:TextFormat;

	    private var _mask:Shape;

	    private var _width:Number; override public function get width():Number { return _width; }

		public function CaptionView(width:Number, textFormat:TextFormat = null) {

			_width = width;

			captionDisplay = [];

			if(textFormat == null)
		        captionFormat = new TextFormat("Arial", 18, 0x000000, true, false, false, null, null, "left", null, null, null, 4);
		    else
		    	captionFormat = textFormat;

		    for(var i:int = 0; i<2; i++) {
		        captionDisplay.push(new TextFieldWithCursor());
		        captionDisplay[i].defaultTextFormat = captionFormat;
                captionDisplay[i].y = i * captionDisplay[i].height;

		        addChild(captionDisplay[i]);
		    }


		    _mask = new Shape();
		    _mask.graphics.beginFill(0xff00ff);
		    _mask.graphics.drawRect(0, 0, width, Number(captionFormat.size) * 1.3);
		    _mask.graphics.endFill();
//		    addChild(_mask);
//		    this.mask = _mask;

		    activeDisplay = 0;
		}

//		public function set wordwrap(val:Boolean):void {
//			for each(var textfield:TextFieldWithCursor in captionDisplay) {
//				textfield.width = _width;
//				textfield.wordwrap = val;
//			}
//		}

		public function set text(val:String):void {
			displayText(val);
		}

		public function get text():String {
			return captionDisplay[activeDisplay].text;
		}

		public function displayText(text:String, direction:Number = -1):void {

			if(captionDisplay[activeDisplay].text != text) {
				activeDisplay   = (activeDisplay == 0) ? 1 : 0;
				inactiveDisplay = (activeDisplay == 0) ? 1 : 0;

				captionDisplay[activeDisplay].y = (direction == 1) ? -captionDisplay[activeDisplay].height : captionDisplay[activeDisplay].height;
				captionDisplay[activeDisplay].text = text;
				captionDisplay[activeDisplay].x = width/2 - captionDisplay[activeDisplay].width/2;

				TweenLite.to(captionDisplay[activeDisplay], 0.25,
							{alpha: 1,
							     y: 0,
							 delay: 0.05,
						   	  ease: Power1.easeOut,
					   	 overwrite: "all" })
				TweenLite.to(captionDisplay[inactiveDisplay], 0.15,
							{alpha: 0,
							     y: direction * captionDisplay[activeDisplay].height,
							  ease: Power1.easeIn,
					   	 overwrite: "all" })
			}
		}

		public function set cursor(normalizedValue:Number):void {
			captionDisplay[activeDisplay].cursor = normalizedValue;
		}


	}
}


import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.filters.BitmapFilterQuality;
import flash.filters.GlowFilter;

class TextFieldWithCursor extends Sprite {

	private var format:TextFormat;
	public function set defaultTextFormat(tf:TextFormat):void {
		textField.defaultTextFormat = tf;
		textMask.defaultTextFormat = tf;
		format = tf;
	}

	private var textField:TextField;
	private var textMask:TextField;
	private var _cursor:Shape;

	public function TextFieldWithCursor():void {

		textField = new TextField();

		textField.autoSize = "left";
		textField.selectable = false;
		textField.wordWrap = false;
		textField.condenseWhite = true;
		textField.filters = [new GlowFilter(0x000000, 1, 5, 5, 8, BitmapFilterQuality.MEDIUM)];
		textField.mouseEnabled = false;

		textMask = new TextField();
		textMask.autoSize = "left";
		textMask.selectable = false;
		textMask.wordWrap = false;
		textMask.condenseWhite = true;
		textMask.mouseEnabled = false;

		addChild(textField);
		addChild(textMask);

		textMask.cacheAsBitmap = true;

		_cursor = new Shape();
		_cursor.cacheAsBitmap = true;
		addChild(_cursor);
		_cursor.mask = textMask;
	}

	public function set cursor(normalizedValue:Number):void {

		_cursor.x = textField.x + textField.width * normalizedValue;
	}

	public function get text():String {
		return textField.text;
	}

	public function set text(s:String):void {
		textField.text = s;
		textMask.text = s;

		_cursor.graphics.clear();
		_cursor.graphics.beginFill(0xff0000, 1);
		_cursor.graphics.drawRect(-textField.width, 0, textField.width, Number(format.size) * 1.5);
		_cursor.graphics.endFill();
		_cursor.graphics.beginFill(0xffffff, 1);
		_cursor.graphics.drawRect(0, 0, textField.width, Number(format.size) * 1.5);
		_cursor.graphics.endFill();
	}

//	public function set wordwrap(val:Boolean):void {
//		textField.wordWrap = true;
//		textMask.wordWrap = true;
//	}

	override public function set width(val:Number):void {
		textField.width = val;
		textMask.width = val;
	}

	override public function get width():Number {
		return textField.width;
	}
}