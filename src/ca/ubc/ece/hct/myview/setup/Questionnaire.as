////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.setup {

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

	public class Questionnaire extends Sprite {

		public static const QuestionnaireAccept:String = "QuestionnaireAccept";

		private var question:TextField;
		private var checkboxes:Array;
		private var submitButton:Button;

		public function Questionnaire(width:Number, height:Number) {

			graphics.beginFill(0xeeeeee);
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();

			question = new TextField();
			question.selectable = false;
			question.defaultTextFormat = new TextFormat("Arial", 20, 0x333333, true, false, false, null, null, "center", null, null, null, 4);
			question.wordWrap = true;
			question.autoSize = "left";
			question.text = "How much experience do you have in learning from video?  (check all that apply)";
			question.width = width * 6/8;
			question.x = width/2 - question.width/2;
			question.y = height * 1/3;
			addChild(question);

			// graphics.lineStyle(1, 0xff0000);
			// graphics.drawRect(question.x, question.y, question.width, question.height);

			checkboxes = [];
			var cbtf:TextFormat = new TextFormat("Arial", 15, 0x333333, true, false, false, null, null, "left", null, null, null, 4);

			var checkbox:CheckBox = new CheckBox();
			checkbox.width = 800;
			checkbox.setStyle("textFormat", cbtf);
			checkbox.label = "1. I took online courses.";
			checkbox.x = question.x + 100;
			checkbox.y = question.y + question.height + 20;
			checkboxes.push(checkbox);
			addChild(checkbox);

			checkbox = new CheckBox();
			checkbox.width = 800;
			checkbox.setStyle("textFormat", cbtf);
			checkbox.label = "2. I studied from video in on-campus courses";
			checkbox.x = checkboxes[checkboxes.length-1].x;
			checkbox.y = checkboxes[checkboxes.length-1].y + checkboxes[checkboxes.length-1].height + 10;
			checkboxes.push(checkbox);
			addChild(checkbox);

			checkbox = new CheckBox();
			checkbox.width = 800;
			checkbox.setStyle("textFormat", cbtf);
			checkbox.label = "3. I studied from videos for non-academic purposes (recipes, how-to’s)";
			checkbox.x = checkboxes[checkboxes.length-1].x;
			checkbox.y = checkboxes[checkboxes.length-1].y + checkboxes[checkboxes.length-1].height + 10;
			checkboxes.push(checkbox);
			addChild(checkbox);

			checkbox = new CheckBox();
			checkbox.width = 800;
			checkbox.setStyle("textFormat", cbtf);
			checkbox.label = "4. I have not studied from video";
			checkbox.x = checkboxes[checkboxes.length-1].x;
			checkbox.y = checkboxes[checkboxes.length-1].y + checkboxes[checkboxes.length-1].height + 10;
			checkboxes.push(checkbox);
			addChild(checkbox);

			submitButton = new Button();
			submitButton.label = "Submit";
			submitButton.x = width/2 - submitButton.width/2;
			submitButton.y = checkboxes[checkboxes.length-1].y + checkboxes[checkboxes.length-1].height + 10;
			submitButton.addEventListener(MouseEvent.CLICK, submit);
			addChild(submitButton);

		}

		public function setSize(width:Number, height:Number):void {

			graphics.clear();
            graphics.beginFill(0xeeeeee);
            graphics.drawRect(0, 0, width, height);
            graphics.endFill();

            question.width = width * 6/8;
            question.x = width/2 - question.width/2;
            question.y = height * 1/3;


            checkboxes[0].width = 800;
            checkboxes[0].x = question.x + 100;
            checkboxes[0].y = question.y + question.height + 20;

            checkboxes[1].width = 800;
            checkboxes[1].x = checkboxes[0].x;
            checkboxes[1].y = checkboxes[0].y + checkboxes[0].height + 10;

            checkboxes[2].width = 800;
            checkboxes[2].x = checkboxes[1].x;
            checkboxes[2].y = checkboxes[1].y + checkboxes[1].height + 10;

            checkboxes[3].width = 800;
            checkboxes[3].x = checkboxes[2].x;
            checkboxes[3].y = checkboxes[2].y + checkboxes[2].height + 10;

            submitButton.x = width/2 - submitButton.width/2;
            submitButton.y = checkboxes[3].y + checkboxes[3].height + 10;
		}

		private function submit(e:MouseEvent):void {
			dispatchEvent(new Event(QuestionnaireAccept));
		}

		public function get a():Boolean {
			return checkboxes[0].selected;
		}

		public function get b():Boolean {
			return checkboxes[1].selected;
		}

		public function get c():Boolean {
			return checkboxes[2].selected;
		}

		public function get d():Boolean {
			return checkboxes[3].selected;
		}

		public function destroy():void {
			question = null;
			for(var i:int = 0; i<checkboxes.length; i++) {
				checkboxes[i] = null;
			}
			submitButton.removeEventListener(MouseEvent.CLICK, submit);
			submitButton = null;
		}
	}
}
