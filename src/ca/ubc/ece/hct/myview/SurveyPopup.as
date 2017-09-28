////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

import ca.ubc.ece.hct.myview.ui.UIScrollView;

import fl.controls.Button;
import fl.controls.CheckBox;
import fl.controls.TextInput;

import flash.display.Shape;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.net.SharedObject;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.Timer;

import org.osflash.signals.Signal;
import org.osflash.signals.natives.NativeSignal;

public class SurveyPopup extends View {

	private var addedToStageSignal:NativeSignal;
	public var launchedSurveySignal:Signal;
	public var closeMeSignal:Signal;

	private var container:Sprite;
	private var uiscroller:UIScrollView;
	private var uiscrollerSource:Sprite;

	private var surveyID:String;
	private var surveyURL:String;

	private var launchSurveyButton:Button;

	private var finishedSurveyText:TextField;
	private var finishedSurveyTextField:TextInput;

	private var survey_so:SharedObject;

	private var closeButton:Button;
	private var closeButtonTimeToActivate:Number = 5;
	private var closeButtonTimer:Timer;

	private var completedSurvey:Boolean = false;
	private var confirmCompletionText:String;
	private var checkMark:Shape;

	public function SurveyPopup(surveyID:String, surveyURL:String, confirmCompletionText:String = "?") {

		this.surveyID = surveyID;
		this.surveyURL = surveyURL;
		this.confirmCompletionText = confirmCompletionText;
        survey_so = SharedObject.getLocal("survey");

		addedToStageSignal = new NativeSignal(this, Event.ADDED_TO_STAGE, Event);
		addedToStageSignal.addOnce(addedToStage);
		closeMeSignal = new Signal(Boolean); // was the survey completed?

		launchedSurveySignal = new Signal();

		closeButtonTimer = new Timer(1000);
		closeButtonTimer.addEventListener(TimerEvent.TIMER, closeButtonCountDown);
		closeButtonTimer.start();
		checkMark = new Shape();
	}

	override protected function addedToStage(e:Event = null):void {
		if(container == null) {


			graphics.beginFill(0, 0.8);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();

			_width = stage.stageWidth * 0.5;
			_height = stage.stageHeight * 0.5;


			container = new Sprite();
			container.x = stage.stageWidth/2 - _width/2;
			container.y = stage.stageHeight/2 - _height/2;
			addChild(container);

			container.graphics.beginFill(0xdddddd);
			container.graphics.drawRoundRect(0, 0, _width, _height, 20);
			container.graphics.endFill();
			container.graphics.beginFill(0xffffff);
			container.graphics.drawRoundRect(5 , 5, _width-10, _height-10, 20);
			container.graphics.endFill();

            uiscroller = new UIScrollView(container.width - 10, container.height - 10);
			uiscroller.x = 10;
			uiscroller.y = 10;
            container.addChild(uiscroller);

			uiscrollerSource = new Sprite();
			uiscroller.source = uiscrollerSource;
            uiscrollerSource.addChild(checkMark);

			var tf:TextField = new TextField();
			tf.width = _width - 30;
			tf.height = 150;
			tf.autoSize = "center";
			tf.multiline = true;
			tf.wordWrap = true;
			tf.defaultTextFormat = new TextFormat("Arial", 30, 0x666666, false, false, false, null, null, "center");
			tf.htmlText = "Survey"
			tf.defaultTextFormat = new TextFormat("Arial", 20, 0x666666, false, false, false, null, null, "center");
			tf.htmlText += "<br />Thank you for using this application. To help us improve it for the future, " +
					  "please complete the following survey. <br /><br />Your User ID is: <br />";

			tf.defaultTextFormat = new TextFormat("Arial", 25, 0xff0000, false, false, false, null, null, "center");
			tf.htmlText += surveyID;

//				tf.defaultTextFormat = new TextFormat("Arial", 20, 0x0000ff, false, null, false);
//				tf.htmlText += "<br /> <br /><a href='" + surveyURL + "'>" + surveyURL + "</a>";
			tf.x = _width/2 - tf.width/2;
			tf.y = 30;//stage.stageHeight/2 - tf.height/2;
            uiscrollerSource.addChild(tf);


			launchSurveyButton = new Button();
			launchSurveyButton.label = "Launch Survey!";
			launchSurveyButton.x = _width/2 - launchSurveyButton.width/2;
			launchSurveyButton.y = tf.y + tf.height + 10;
			launchSurveyButton.addEventListener(MouseEvent.CLICK, launchSurvey);

            uiscrollerSource.addChild(launchSurveyButton);


			closeButton = new Button();
			closeButton.enabled = false;
			closeButton.mouseEnabled = false;
			closeButton.label = "Close - " + closeButtonTimeToActivate;
			closeButton.addEventListener(MouseEvent.CLICK,
				function closeMe(e:MouseEvent):void {
					if(completedSurvey) {}
						closeMeSignal.dispatch(completedSurvey);
					})
			closeButton.x = _width/2 - closeButton.width/2;
			closeButton.y = launchSurveyButton.y + launchSurveyButton.height + 10;
            uiscrollerSource.addChild(closeButton);

			uiscroller.update();
		}

	}

	private function closeButtonCountDown(e:TimerEvent):void {
		closeButtonTimeToActivate--;

		closeButton.label = "Close - " + closeButtonTimeToActivate;

		if(closeButtonTimeToActivate <= 0) {
			closeButtonTimer.stop();
			closeButton.label = "Close";
			closeButton.enabled = true;
			closeButton.mouseEnabled = true;
		}
	}

	private function launchSurvey(e:MouseEvent):void {

		launchedSurveySignal.dispatch();

		navigateToURL(new URLRequest(surveyURL));

		container.graphics.lineStyle(1, 0x666666);
        container.graphics.moveTo(30, launchSurveyButton.y + launchSurveyButton.height + 10);
        container.graphics.lineTo(_width - 30, launchSurveyButton.y + launchSurveyButton.height + 10);

		finishedSurveyText = new TextField();
        finishedSurveyText.width = _width - 100;
		finishedSurveyText.autoSize = "center";
		finishedSurveyText.wordWrap = true;
		finishedSurveyText.defaultTextFormat = new TextFormat("Arial", 20, 0x666666, false, false, false, null, null, "center");
		finishedSurveyText.htmlText = "Please enter the code given to you at the end of the survey. <br /> Thanks!";
		finishedSurveyText.x = _width/2 - finishedSurveyText.width/2;
		finishedSurveyText.y = launchSurveyButton.y + launchSurveyButton.height + 10;
        uiscrollerSource.addChild(finishedSurveyText);

		finishedSurveyTextField = new TextInput();
		finishedSurveyTextField.width = _width * 0.5;
        finishedSurveyTextField.x = _width/2 - finishedSurveyTextField.width/2;
        finishedSurveyTextField.y = finishedSurveyText.y + finishedSurveyText.height + 10;
        uiscrollerSource.addChild(finishedSurveyTextField);

		checkMark.x = finishedSurveyTextField.x + finishedSurveyTextField.width + 10;
		checkMark.y = finishedSurveyTextField.y;

		finishedSurveyTextField.addEventListener(Event.CHANGE,
		function(e:Event):void {
			completedSurvey = finishedSurveyTextField.text.indexOf(confirmCompletionText) > -1;
            checkMark.graphics.clear();
			if(completedSurvey) {
                checkMark.graphics.lineStyle(7, 0x00aa00);
                checkMark.graphics.moveTo(0, 12);
                checkMark.graphics.lineTo(8, 20);
                checkMark.graphics.lineTo(25, 0);
			} else {
				checkMark.graphics.lineStyle(7, 0xaa0000);
				checkMark.graphics.moveTo(0, 0);
				checkMark.graphics.lineTo(25, 25);
				checkMark.graphics.moveTo(0, 25);
				checkMark.graphics.lineTo(25, 0);
			}
		});

        closeButton.y = finishedSurveyTextField.y + finishedSurveyTextField.height + 10;

        uiscroller.update();
	}

}
}