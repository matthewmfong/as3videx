////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.setup {
import ca.ubc.ece.hct.myview.*;

import ca.ubc.ece.hct.myview.Util;

import fl.controls.Button;
	import fl.controls.CheckBox;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.html.HTMLLoader;
    import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class ConsentForm extends Sprite {

		public static const ConsentFormAccept:String = "ConsentFormEventAccept";
		public static const ConsentFormCancel:String = "ConsentFormEventCancel";

		private var html:HTMLLoader;
		private var checkbox:CheckBox;
		private var checkboxText:TextField;
		private var submitButton:Button;
		private var cancelButton:Button;

		public function ConsentForm(width:Number, height:Number, consentFormURL:String) {

			graphics.beginFill(0xeeeeee);
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();

			html = new HTMLLoader();
			html.load(new URLRequest(consentFormURL));
			html.x = 10;
			html.y = 10;
			html.width = width - 20;
			html.height = height - 100;

			addChild(html);

			checkbox = new CheckBox();
			checkbox.label = "";
			checkbox.width = 20;
			checkbox.x = width/15;
			checkbox.y = html.y + html.height + 10;
			checkbox.addEventListener(Event.CHANGE, checkboxChange);
			checkbox.addEventListener(MouseEvent.ROLL_OVER, Util.mouseCursorButton);
			checkbox.addEventListener(MouseEvent.ROLL_OUT, Util.mouseCursorArrow);
			addChild(checkbox);

			checkboxText = new TextField();
			checkboxText.wordWrap = true;
			checkboxText.autoSize = "left";
			checkboxText.defaultTextFormat = new TextFormat("Arial", 15, 0x333333, true, false, false, null, null, "left", null, null, null, 4);
			checkboxText.selectable = false;
			checkboxText.width = width;
			checkboxText.text = "I agree to participate in the project as outlined above. My participation in this project is voluntary and I understand that I may withdraw at any time.";
			checkboxText.x = checkbox.x + checkbox.width + 10;
			checkboxText.y = checkbox.y;
			checkboxText.addEventListener(MouseEvent.CLICK, checkboxTextClick);
			checkboxText.addEventListener(MouseEvent.ROLL_OVER, Util.mouseCursorButton);
			checkboxText.addEventListener(MouseEvent.ROLL_OUT, Util.mouseCursorArrow);
			addChild(checkboxText);

			submitButton = new Button();
			submitButton.label = "Submit";
			submitButton.enabled = false;
			submitButton.x = width/2 - submitButton.width;
			submitButton.y = checkboxText.y + checkboxText.height + 20;
			submitButton.addEventListener(MouseEvent.CLICK, submit);
			addChild(submitButton);

			cancelButton = new Button();
			cancelButton.label = "Cancel";
			cancelButton.x = width/2;
			cancelButton.y = checkboxText.y + checkboxText.height + 20;
			cancelButton.addEventListener(MouseEvent.CLICK, cancel);
			addChild(cancelButton);
		}

		public function setSize(width:Number, height:Number):void {
			graphics.clear();
            graphics.beginFill(0xeeeeee);
            graphics.drawRect(0, 0, width, height);
            graphics.endFill();

            html.x = 10;
            html.y = 10;
            html.width = width - 20;
            html.height = height - 100;
            checkbox.width = 20;
            checkbox.x = width/15;
            checkbox.y = html.y + html.height + 10;
            checkboxText.width = width;
            checkboxText.x = checkbox.x + checkbox.width + 10;
            checkboxText.y = checkbox.y;
            cancelButton.x = width/2;
            cancelButton.y = checkboxText.y + checkboxText.height + 20;
            submitButton.x = width/2 - submitButton.width;
            submitButton.y = checkboxText.y + checkboxText.height + 20;
		}


		private function checkboxChange(e:Event):void {
			submitButton.enabled = checkbox.selected;
		}

		private function checkboxTextClick(e:MouseEvent):void {
			checkbox.selected = true;
			submitButton.enabled = checkbox.selected;
		}

		private function submit(e:MouseEvent):void {
			dispatchEvent(new Event(ConsentFormAccept));
		}

		private function cancel(e:MouseEvent):void {
			dispatchEvent(new Event(ConsentFormCancel));
		}

		public function destroy():void {
			html = null;
			checkbox.removeEventListener(Event.CHANGE, checkboxChange);
			checkbox.removeEventListener(MouseEvent.ROLL_OVER, Util.mouseCursorButton);
			checkbox.removeEventListener(MouseEvent.ROLL_OUT, Util.mouseCursorArrow);
			checkbox = null;
			checkboxText.removeEventListener(MouseEvent.CLICK, checkboxTextClick);
			checkboxText.removeEventListener(MouseEvent.ROLL_OVER, Util.mouseCursorButton);
			checkboxText.removeEventListener(MouseEvent.ROLL_OUT, Util.mouseCursorArrow);
			checkboxText = null;
			submitButton.removeEventListener(MouseEvent.CLICK, submit);
			submitButton = null;
			cancelButton.removeEventListener(MouseEvent.CLICK, cancel);
			cancelButton = null;
		}
	}
}