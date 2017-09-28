////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

	import fl.controls.Button;
	import fl.controls.TextInput;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class ChooseUserID extends Sprite {

		public static const IDChosen:String = "IDChosen";

		private var titleText:TextField;
		public var inputField:TextInput;
		private var submitButton:Button;

		public function ChooseUserID(width:Number, height:Number) {

			graphics.beginFill(0xeeeeee);
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();

			titleText = new TextField();
			titleText.selectable = false;
			titleText.defaultTextFormat = new TextFormat("Arial", 20, 0x333333, true, false, false, null, null, "center", null, null, null, 4);
			titleText.wordWrap = true;
			titleText.autoSize = "left";
			titleText.text = "Please enter the last 2 digits of your address, last 2 digits of your student #, last 2 digits of your phone #";
			titleText.width = width * 6/8;
			titleText.x = width/2 - titleText.width/2;
			titleText.y = height * 1/3;
			addChild(titleText);

			inputField = new TextInput();
			inputField.text = "";
			addChild(inputField);
			inputField.width = 250;
			inputField.height = 50;
			inputField.x = width/2 - inputField.width/2;
			inputField.y = titleText.y + titleText.height + 20;

			inputField.graphics.beginFill(0xaaaaaa, 1);
			inputField.graphics.drawRect(0, 0, inputField.width, inputField.height);
			inputField.graphics.endFill();

			submitButton = new Button();
			submitButton.label = "Submit";
			submitButton.x = width/2 - submitButton.width/2;
			submitButton.y = inputField.y + inputField.height + 20;
			submitButton.addEventListener(MouseEvent.CLICK, submit);
			addChild(submitButton);
		}

		private function submit(e:MouseEvent):void {
			dispatchEvent(new Event(IDChosen));
		}

		public function get userID():String {
			return inputField.text;
		}

		public function destroy():void {
			titleText = null;
			inputField = null;
			submitButton.removeEventListener(MouseEvent.CLICK, submit);
			submitButton = null;
		}
	}
}
