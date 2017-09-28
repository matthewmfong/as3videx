////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {

	import com.greensock.*;
	import com.greensock.easing.*;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;

	import fl.core.UIComponent;
	import fl.managers.IFocusManagerComponent;

	public class SearchBar extends UIComponent implements IFocusManagerComponent {

		override public function get width():Number { return __width; }
		override public function get height():Number { return __height; }

		private static const __height:Number = 22;
		private static const _easing:Function = Regular.easeOut;

		public function get text():String { return (textInput.text == "Search") ? "" : textInput.text; }

		private var __width:Number;
		private var surroundingHighlight:Shape;
		private var surroundingHighlightOriginalSize:Rectangle;

		private var magnifyingGlass:Shape;
		private var textInput:TextField;
		private var textInputOriginalXPosition:Number;
		private var textInputChanged:Boolean;
		private var searchFormat:TextFormat = new TextFormat("Arial", 12, 0xadacad);
		private var searchFormatTyping:TextFormat = new TextFormat("Arial", 12, 0x333333);

		private var clearButton:Sprite;
		private var clearButtonOriginalSize:Rectangle;

		private var hasFocus:Boolean;

		public function SearchBar(width_:Number):void {
			__width = width_;

			hasFocus = false;

			surroundingHighlight = new Shape();
			surroundingHighlightOriginalSize = new Rectangle(-1, -1, __width + 3, __height + 3);
			surroundingHighlight.graphics.lineStyle(4, 0x8fbbea, 1);
			surroundingHighlight.graphics.drawRoundRect(surroundingHighlightOriginalSize.x,
														surroundingHighlightOriginalSize.y,
														surroundingHighlightOriginalSize.width,
														surroundingHighlightOriginalSize.height, 12);
			// the dimensions change once you draw it lol... (due to the lineStyle)
			surroundingHighlightOriginalSize.x = surroundingHighlight.x;
			surroundingHighlightOriginalSize.y = surroundingHighlight.y;
			surroundingHighlightOriginalSize.width = surroundingHighlight.width;
			surroundingHighlightOriginalSize.height = surroundingHighlight.height;

			textInput = new TextField();
			textInput.defaultTextFormat = searchFormat;
			textInput.autoSize = "left";
			textInput.text = "Search";
			textInput.type = TextFieldType.INPUT;
			textInputOriginalXPosition = Math.max(8 + 12 + 5, __width/2 - (textInput.width)/2);
			textInput.x = textInputOriginalXPosition; // 12 is the size of the magnifying glass
			textInput.y = __height/2 - 8;
			textInput.autoSize = "none";
			textInput.width = __width - textInput.x;
			textInputChanged = false;
			addChild(textInput);

			magnifyingGlass = new Shape();
			magnifyingGlass.graphics.lineStyle(1, 0xa5a5a5);
			magnifyingGlass.graphics.drawCircle(5, 5, 5);
			magnifyingGlass.graphics.moveTo(9, 9);
			magnifyingGlass.graphics.lineTo(12, 12);
			magnifyingGlass.x = textInput.x - (magnifyingGlass.width + 5);
			magnifyingGlass.y = __height/2 - magnifyingGlass.height/2;
			addChild(magnifyingGlass);

			clearButton = new Sprite();
			clearButton.graphics.beginFill(0x7d7d7d, 1);
			clearButton.graphics.drawCircle(7, 7, 7);
			clearButton.graphics.endFill();
			clearButton.graphics.lineStyle(1, 0xfbfbfb);
			clearButton.graphics.moveTo(4, 4);
			clearButton.graphics.lineTo(10, 10);
			clearButton.graphics.moveTo(10, 4);
			clearButton.graphics.lineTo(4, 10);
			clearButtonOriginalSize = new Rectangle(__width - clearButton.width - 5,
													__height/2 - clearButton.height/2,
													clearButton.width,
													clearButton.height);
			clearButton.x = clearButtonOriginalSize.x;
			clearButton.y = clearButtonOriginalSize.y;
			clearButton.addEventListener(MouseEvent.CLICK, clearButtonClicked);


			drawInactive();
			textInput.addEventListener(MouseEvent.CLICK, mouseClick);
		}

		public function mouseClick(e:MouseEvent):void {
			stage.focus = textInput;
			drawActive();
			if(!focusManager.form.hasEventListener(MouseEvent.CLICK)) {
				focusManager.form.addEventListener(MouseEvent.CLICK, focusOut);
			}
		}

		private function clearButtonClicked(e:MouseEvent):void {
			clearSearch();
		}

		public function clearSearch():void {
			textInput.text = "";
			drawInactive();
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function drawInactive():void {
			hasFocus = false;
			dispatchEvent(new FocusEvent(FocusEvent.FOCUS_OUT));
			graphics.clear();
			graphics.lineStyle(NaN);
			graphics.beginFill(0xafafaf);
			graphics.drawRoundRect(0, 0, __width, __height, 8);
			graphics.endFill();

			var matr:Matrix = new Matrix;
			matr.createGradientBox(__width, __height, Math.PI/2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, 
			[0xfcfcfc, 0xfafafa], // colour
			[1, 1],  // alpha
			[0, 255], // ratio
			matr);
			graphics.lineStyle(1, 0xffffff);
			graphics.drawRoundRect(0, 0, __width, __height - 1, 8);
			graphics.endFill();

			if(contains(surroundingHighlight)) {
				surroundingHighlight.alpha = 1;
				TweenLite.to(surroundingHighlight, 0.4, {alpha: 0, ease:_easing, onComplete: function removeSurroundingHighlight():void { removeChild(surroundingHighlight) }});
			}

			textInput.defaultTextFormat = searchFormat;
			textInput.scrollH = 0;
			if(textInput.text == "" || !textInputChanged) {
				textInputChanged = false;
				textInput.text = "Search";
				TweenLite.to(magnifyingGlass, 0.3, {x: textInputOriginalXPosition - (magnifyingGlass.width + 5), ease:_easing});
				TweenLite.to(textInput, 0.3, {x: textInputOriginalXPosition, ease:_easing});
				if(contains(clearButton)) {
					removeChild(clearButton);
				}
			} else {
				// make sure defaultTextFormat actually changes
				textInput.text = textInput.text;
			}
		}

		public function drawActive():void {
			hasFocus = true;
			dispatchEvent(new FocusEvent(FocusEvent.FOCUS_IN));
			graphics.clear();
			graphics.beginFill(0xf2f7fb);
			graphics.drawRoundRect(0, 0, __width, __height, 8);
			graphics.endFill();

			var matr:Matrix = new Matrix;
			matr.createGradientBox(__width, 16, Math.PI/2, 0, 4);
			graphics.beginGradientFill(GradientType.LINEAR, 
			[0xfcfbfc, 0xfafafa], // colour
			[1, 1],  // alpha
			[0, 255], // ratio
			matr);
			graphics.lineStyle(1, 0xffffff);
			graphics.drawRoundRect(0, 4, __width, 16, 8);
			graphics.endFill();

			textInput.defaultTextFormat = searchFormatTyping;
			if(textInputChanged) {
				// make sure defaultTextFormat actually changes
				textInput.text = textInput.text;
			}
			textInput.addEventListener(TextEvent.TEXT_INPUT, 
				function removeSearchText(e:TextEvent):void {
					if(!textInputChanged) {
						textInput.text = "";
						textInputChanged = true;
					}
					textInput.removeEventListener(TextEvent.TEXT_INPUT, removeSearchText);
					textInput.addEventListener(Event.CHANGE, textChanged);
				});

			if(!contains(surroundingHighlight)) {
				addChild(surroundingHighlight);
				surroundingHighlight.alpha = 0;
				surroundingHighlight.y = -surroundingHighlightOriginalSize.height* 1.4/2 + __height * 0.7;
				surroundingHighlight.height = surroundingHighlightOriginalSize.height * 1.4;
				TweenLite.to(surroundingHighlight, 0.3, {alpha: 1, y: surroundingHighlightOriginalSize.y, height:surroundingHighlightOriginalSize.height, ease:_easing});
			}

			if(!contains(clearButton)) {
				addChild(clearButton);
				clearButton.x = clearButtonOriginalSize.x + (clearButtonOriginalSize.width - clearButtonOriginalSize.width * 0.2)/2;
				clearButton.y = clearButtonOriginalSize.y + (clearButtonOriginalSize.height - clearButtonOriginalSize.height * 0.2)/2;
				clearButton.width = clearButtonOriginalSize.width * 0.2;
				clearButton.height = clearButtonOriginalSize.height * 0.2;
				TweenLite.to(clearButton, 0.2, {x:clearButtonOriginalSize.x, y:clearButtonOriginalSize.y, width:clearButtonOriginalSize.width, height:clearButtonOriginalSize.height, ease:_easing});
			}

			TweenLite.to(magnifyingGlass, 0.3, {x:8, ease:_easing});
			TweenLite.to(textInput, 0.3, {x: 8 + magnifyingGlass.width + 5, ease:_easing});

		}

		private function textChanged(e:Event):void {
			dispatchEvent(new Event(Event.CHANGE));
		}

		private function focusOut(e:MouseEvent):void {
			if(!(e.target is SearchBar || e.target.parent is SearchBar)) {
				drawInactive();
				if(focusManager)
					focusManager.form.removeEventListener(MouseEvent.CLICK, focusOut);
				if(stage)
					stage.focus = stage;
			}
		}

		override public function set width(val:Number):void {

			__width = val;
			surroundingHighlight.graphics.clear();
			surroundingHighlightOriginalSize = new Rectangle(-1, -1, __width + 3, __height + 3);
			surroundingHighlight.graphics.lineStyle(4, 0x8fbbea, 1);
			surroundingHighlight.graphics.drawRoundRect(surroundingHighlightOriginalSize.x,
														surroundingHighlightOriginalSize.y,
														surroundingHighlightOriginalSize.width,
														surroundingHighlightOriginalSize.height, 12);
			// the dimensions change once you draw it lol...
			surroundingHighlightOriginalSize.x = surroundingHighlight.x;
			surroundingHighlightOriginalSize.y = surroundingHighlight.y;
			surroundingHighlightOriginalSize.width = surroundingHighlight.width;
			surroundingHighlightOriginalSize.height = surroundingHighlight.height;

			textInput.defaultTextFormat = searchFormat;
			textInput.autoSize = "left";
			textInput.text = "Search";
			textInput.type = TextFieldType.INPUT;
			textInputOriginalXPosition = Math.max(8 + 12 + 5, __width/2 - (textInput.width)/2);
			textInput.x = textInputOriginalXPosition; // 12 is the size of the magnifying glass
			textInput.y = __height/2 - 8;
			textInput.autoSize = "none";
			textInput.width = __width - textInput.x;

			magnifyingGlass.x = textInput.x - (magnifyingGlass.width + 5);

			clearButtonOriginalSize = new Rectangle(__width - clearButton.width - 5,
													__height/2 - clearButton.height/2,
													clearButton.width,
													clearButton.height);
			clearButton.x = clearButtonOriginalSize.x;
			clearButton.y = clearButtonOriginalSize.y;

			if(hasFocus) {
				drawActive();
			} else {
				drawInactive();
			}
		}
	}
}