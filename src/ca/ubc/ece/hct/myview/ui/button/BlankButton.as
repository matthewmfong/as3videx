////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui.button {

import flash.geom.Point;
import flash.geom.Rectangle;

import org.osflash.signals.Signal;

	import fl.core.UIComponent;
	import fl.managers.IFocusManagerComponent;

	import flash.display.Sprite;
	import flash.net.URLRequest;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;

	public class BlankButton extends UIComponent implements IFocusManagerComponent {

		override public function get width():Number { return __width; }
		override public function get height():Number { return __height; }

		protected var __width:Number;
		protected static const __height:Number = 22;
		public static const cornerDiameter:Number = 8
		public static const cornerRadius:Number = cornerDiameter/2;
		public var toggleAble:Boolean;
		public var toggleActive:Boolean;

		public var value:Object;

		public var clicked:Signal;
		public var toggled:Signal;

		private var altTextField:TextField;
		public static const altTextFormat:TextFormat = new TextFormat("Arial", 10, 0x000000);
		private var altTextTimer:Timer;

		public function BlankButton(width_:Number, altText:String = null) {
			super();
			__width = width_;

			clicked = new Signal(BlankButton); 
			toggled = new Signal(BlankButton, Boolean);

			toggleAble = false;
			toggleActive = false;

			drawButtonUp();

			if(altText) {
				altTextField = new TextField();
				altTextField.autoSize = "center";
				altTextField.defaultTextFormat = altTextFormat;
				altTextField.text = altText;
				altTextField.background = true;
				altTextField.backgroundColor = 0xffffff;
				altTextTimer = new Timer(500);
			}

			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
		}

		public function set active(val:Boolean):void {
			toggleActive = val;
			if(val) {
				if(!hasEventListener(MouseEvent.MOUSE_DOWN)) {
					addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				}

				if(!hasEventListener(MouseEvent.MOUSE_UP)) {
					addEventListener(MouseEvent.MOUSE_UP, mouseUp);
				}
			} else {

				if(hasEventListener(MouseEvent.MOUSE_DOWN)) {
					removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				}

				if(hasEventListener(MouseEvent.MOUSE_UP)) {
					removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				}
			}
		}

		public function set toggle(val:Boolean):void {
			toggleActive = val;
			if(toggleAble && toggleActive) {
				drawButtonDown();
			} else if(toggleAble && toggleActive) {
				drawButtonUp();
			}
		}

		protected function mouseDown(e:MouseEvent):void {
			drawButtonDown();
		}

		protected function mouseUp(e:MouseEvent):void {
			if(toggleAble && !toggleActive) {
				toggleActive = true;
				toggle = true;
				toggled.dispatch(this, true);
			} else if(toggleAble && toggleActive) {
				toggleActive = false;
				toggle = false;
				toggled.dispatch(this, false);
				drawButtonUp();
			} else if(!toggleAble) {
				drawButtonUp();
				clicked.dispatch(this);
			}
		}

		protected function rollOver(e:MouseEvent):void {
			if(altTextField) {
				altTextTimer.addEventListener(TimerEvent.TIMER, rollOverAltText);
				altTextTimer.start();
			}
		}

		private function rollOverAltText(e:TimerEvent):void {
			altTextVisible = true;
		}

		protected function set altTextVisible(val:Boolean):void {
			if(altTextField) {
				altTextTimer.reset();
				altTextTimer.removeEventListener(TimerEvent.TIMER, rollOverAltText);
				if(val == true) {
					altTextField.x = 10;
					altTextField.y = height;
					if(!contains(altTextField))
						addChild(altTextField);
					var bounds:Rectangle = altTextField.getBounds(stage);

                    var stageX:Number = bounds.x;
                    var maxStageX:Number = stage.stageWidth - altTextField.width;

                    if(stageX > maxStageX)
                        altTextField.x = altTextField.x - (stageX - maxStageX);


                    var stageY:Number = bounds.y;
                    var maxStageY:Number = stage.stageHeight - altTextField.height;

                    if(stageY > maxStageY)
                        altTextField.y = altTextField.y - (stageY - maxStageY);

				} else {
					if(contains(altTextField))
						removeChild(altTextField);
				}
			}
		}

		protected function rollOut(e:MouseEvent):void {
			if(!toggleActive) {
				drawButtonUp();
			}
			if(altTextField)
				altTextVisible = false;
		}

		protected function drawButtonUp():void {

			graphics.clear();
			graphics.lineStyle(NaN);
			// back shadow
			graphics.beginFill(0xafafaf);
			graphics.drawRoundRect(0, 0, __width, __height, cornerDiameter);
			graphics.endFill();

			var matr:Matrix = new Matrix;
			matr.createGradientBox(__width, __height, Math.PI/2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, 
			[0xfcfcfc	, 0xfafafa], // colour
			[1, 1],  // alpha
			[0, 255], // ratio
			matr);
			graphics.lineStyle(1, 0xffffff);
			graphics.drawRoundRect(0, 0, __width, __height-1, cornerDiameter);
			graphics.endFill();

		}

		protected function drawButtonDown():void {
			
			graphics.clear();
			graphics.lineStyle(NaN);
			// back shadow
			graphics.beginFill(0xafafaf);
			graphics.drawRoundRect(0, 0, __width, __height, cornerDiameter);
			graphics.endFill();
			graphics.beginFill(0xf0f0f0);
			graphics.drawRoundRect(0, 0, __width, __height-1, cornerDiameter);
			graphics.endFill();

			var matr:Matrix = new Matrix();
			matr.createGradientBox(__width, __height, Math.PI/2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, 
				[0xe4e4e4	, 0xe2e2e2], // colour
				[1, 1],  // alpha
				[0, 255], // ratio
				matr);
			graphics.drawRoundRect(0, 2, __width, __height-2, cornerDiameter);
			graphics.endFill();
		}
	}
}