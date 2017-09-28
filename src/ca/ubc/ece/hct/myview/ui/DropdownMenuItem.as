////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {

	import org.osflash.signals.Signal;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class DropdownMenuItem extends Sprite {

		public function get text():String { return textField.text; }
		public function set text(val:String):void { textField.text = val; }
		public var graphic:DisplayObject;
		public var value:*;

		private var _width:Number = 0;
		private static const _height:Number = 20;
		override public function get height():Number { return _height; }

		private var textField:TextField;
		private static const rollOutTextFormat:TextFormat = new TextFormat("Arial", 12, 0x3e3e3e);
		private static const rollOverTextFormat:TextFormat = new TextFormat("Arial", 12, 0xffffff);

		private var checkMark:Shape;

		public var toggleAble:Boolean;
		private var _toggleActive:Boolean;

		public var clicked:Signal;
		public var animationFinished:Signal;

		public function DropdownMenuItem(text:String, graphic:DisplayObject, value:*) {
			textField = new TextField();
			textField.autoSize = "left";
			textField.defaultTextFormat = rollOutTextFormat;
			textField.text = text;
			textField.x = 40;
			textField.y = _height/2 - textField.height/2;
			textField.mouseEnabled = false;
			textField.selectable = false;
			addChild(textField);
			this.graphic = graphic;
			// this.graphics.mouseEnabled = false
			this.value = value;

			if(this.graphic != null) {
				var graphicAspectRatio:Number = graphic.width/graphic.height;
				graphic.width = 13;
				graphic.height = graphic.width / graphicAspectRatio;
				graphic.x = 22;
				graphic.y = Math.max(2, _height/2 - graphic.height/2);
				addChild(graphic);
			}

			checkMark = new Shape();
			checkMark.x = 5;
			checkMark.y = 5;

			drawRollOut();

			clicked = new Signal(Object);
			animationFinished = new Signal();
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}

		public function mouseUp(e:MouseEvent):void {
			// dispatchEvent(new DropdownMenuItemEvent(DropdownMenuItemEvent.ITEM_CLICKED, value));
			clicked.dispatch(value);
			if(toggleAble) {
				toggleActive = !_toggleActive;
			}

			addEventListener(Event.ENTER_FRAME, animateFlash);
		}

		private var flashingFrameCounter:uint = 0;

		private function animateFlash(e:Event):void {
			if(flashingFrameCounter % 4 == 0) {
				drawRollOut();
			} else if(flashingFrameCounter % 2 == 0) {
				drawRollOver();
			}

			flashingFrameCounter++;

			if(flashingFrameCounter == 8) {
				flashingFrameCounter = 0;
				removeEventListener(Event.ENTER_FRAME, animateFlash);
				animationFinished.dispatch();
				// dispatchEvent(new DropdownMenuItemEvent(DropdownMenuItemEvent.ANIMATION_FINISHED));
			}
		}

		public function rollOver(e:MouseEvent):void {
			drawRollOver();
		}

		public function rollOut(e:MouseEvent):void {
			drawRollOut();
		}

		public function set toggleActive(val:Boolean):void {
			_toggleActive = val;
			if(_toggleActive && !contains(checkMark)) {
				drawRollOutCheckMark();
				addChild(checkMark);
			} else if(!_toggleActive && contains(checkMark)) {
				removeChild(checkMark);
			}
		}

		private function drawRollOutCheckMark():void {
			checkMark.graphics.clear();
			checkMark.graphics.lineStyle(2, 0x3e3e3e);
			checkMark.graphics.moveTo(2, 4);
			checkMark.graphics.lineTo(4, 7);
			checkMark.graphics.lineTo(8, 0);
		}

		private function drawRollOverCheckMark():void {
			checkMark.graphics.clear();
			checkMark.graphics.lineStyle(2, 0xffffff);
			checkMark.graphics.moveTo(2, 4);
			checkMark.graphics.lineTo(4, 7);
			checkMark.graphics.lineTo(8, 0);
		}

		private function drawRollOut():void {
			textField.defaultTextFormat = rollOutTextFormat;
			textField.text = textField.text;

			var drawWidth:Number = (_width != 0) ? _width : textField.x + textField.width + 10;
			graphics.beginFill(0xbfbfbf);
			graphics.drawRect(0, 0, drawWidth, _height);
			graphics.endFill();
			graphics.beginFill(0xf0f0f0);
			graphics.drawRect(1, 0, drawWidth - 2, _height);
			graphics.endFill();

			checkMark.graphics.clear();
			if(toggleAble && _toggleActive) {
				drawRollOutCheckMark();
			}
		}

		private function drawRollOver():void {
			textField.defaultTextFormat = rollOverTextFormat;
			textField.text = textField.text;

			var drawWidth:Number = (_width != 0) ? _width : textField.x + textField.width + 10;
			graphics.clear();
			graphics.beginFill(0xbfbfbf);
			graphics.drawRect(0, 0, drawWidth, _height);
			graphics.endFill();
			var matr:Matrix = new Matrix;
			matr.createGradientBox(drawWidth, _height, Math.PI/2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, 
			[0x2c86f7, 0x398ffa], // colour
			[1, 1],  // alpha
			[0, 255], // ratio
			matr);
			graphics.drawRect(1, 0, drawWidth-2, _height);
			graphics.endFill();

			checkMark.graphics.clear();
			if(toggleAble && _toggleActive) {
				drawRollOverCheckMark();
			}
		}

		override public function set width(val:Number):void {
			_width = val;
			drawRollOut();
		}
	}
}