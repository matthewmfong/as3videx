////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.HighlightMode;
import ca.ubc.ece.hct.myview.UserDataViewMode;
import ca.ubc.ece.hct.myview.widgets.Widget;
import ca.ubc.ece.hct.myview.ui.button.ImageButton;
	import ca.ubc.ece.hct.myview.ui.button.ImageDropdownButton;
	import ca.ubc.ece.hct.myview.ui.TintableHighlightButton;
	import ca.ubc.ece.hct.myview.ui.MulticolourImageButton;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import org.osflash.signals.Signal;

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.geom.Matrix;

	public class PlayerToolbar extends Widget {

		public static const HEIGHT:Number = 38;

		public var hideButton:ImageButton;
		public var playButton:MulticolourImageButton;
		public var highlightButton:MulticolourImageButton;
		public var personalButton:ImageButton;
        public var instructorButton:ImageButton;
        public var classButton:ImageButton;

		public var hideHighlights:Signal;

		public var actionLogSignal:Signal;

		public function PlayerToolbar(width_:Number) {
			_width = width_;
			_height = HEIGHT;

			hideButton = new ImageButton(30, "uiimage/eye.png", "Toggle Highlights");
			hideButton.disabledImage = "uiimage/no_eye.png";
			playButton = new MulticolourImageButton("uiimage/playHighlight", "f7e1a0", "Play Highlights", false);
			highlightButton = new MulticolourImageButton("uiimage/highlight", "f7e1a0", "Highlight");

			personalButton = new ImageButton(30, "uiimage/viewcount.png", "Toggle Personal Mode");
			personalButton.disabledImage = "uiimage/viewcount_active.png";

			instructorButton = new ImageButton(30, "uiimage/instructor_view_mode.png", "Toggle Instructor Mode");
			instructorButton.disabledImage = "uiimage/instructor_view_mode_active.png";

            classButton = new ImageButton(30, "uiimage/globalviewcount.png", "Toggle Class Mode");
            classButton.disabledImage = "uiimage/globalviewcount_active.png";

			hideHighlights = new Signal(Boolean);		// Signal(hideBoolean);
			// playHighlights = new Signal(Boolean, uint);	// Signal(playAll, colour);
			highlighted = new Signal(Boolean, uint);		// Signal(toggle, colour);

			actionLogSignal = new Signal(String);

			drawMe();
		}

		private function drawMe():void {
			drawBackground();

			hideButton.toggleAble = true;
			hideButton.x = 10;
			hideButton.y = _height/2 - hideButton.height/2;
			addChild(hideButton);
			hideButton.toggled.add(hideButtonToggled);

			playButton.setSelectedIndex(1);
			playButton.toggleAble = true;
			playButton.x = hideButton.x + hideButton.width + 5;
			playButton.y = _height/2 - playButton.height/2;
			addChild(playButton)
			playButton.toggled.add(playButtonToggled);
			playButton.selected.add(playHighlightButtonSelected);

			highlightButton.setSelectedIndex(1);
			highlightButton.toggleAble = true;
			highlightButton.x = playButton.x + playButton.width + 5;
			highlightButton.y = _height/2 - highlightButton.height/2;
			addChild(highlightButton);
			highlightButton.toggled.add(highlightButtonToggled);
			highlightButton.selected.add(highlightColourSelected);

			instructorButton.toggleAble = true;
			instructorButton.x = _width - instructorButton.width - 5;
			instructorButton.y = _height/2 - instructorButton.height/2;
			addChild(instructorButton);
			instructorButton.toggled.add(instructorButtonToggled);

            classButton.toggleAble = true;
			classButton.x = instructorButton.x - classButton.width - 5;
			classButton.y = _height/2 - classButton.height/2;
			addChild(classButton);
			classButton.toggled.add(classButtonToggled);

            personalButton.toggleAble = true;
            personalButton.toggle = true;
			personalButton.x = classButton.x - personalButton.width - 5;
			personalButton.y = _height/2 - personalButton.height/2;
			addChild(personalButton);
			personalButton.toggled.add(personalButtonToggled);



		}

		override public function setSize(width:Number, height:Number):void {
			_width = width;
			_height = height;
            drawBackground();
            instructorButton.x = _width - instructorButton.width - 5;
            classButton.x = instructorButton.x - classButton.width - 5;
            personalButton.x = classButton.x - personalButton.width - 5;
		}

		override public function set width(val:Number):void {
			_width = val;
			drawBackground();
			instructorButton.x = _width - instructorButton.width - 5;
			personalButton.x = instructorButton.x - personalButton.width - 5;
		}

		public function get selectedHighlightColour():uint {
			return highlightButton.selectedValue as uint;
		}

		private function drawBackground():void {
			var backMatrix:Matrix = new Matrix();
			backMatrix.createGradientBox(_width, _height, Math.PI/2, 0, 0);
			graphics.clear();
			graphics.beginGradientFill(GradientType.LINEAR, 
				[0xe1e1e1, 0xc4c4c4], // colour
				[1, 1],  // alpha
				[0, 255], // ratio
				backMatrix);
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();
		}

		private function hideButtonToggled(target:Object, val:Object):void {
			// trace("Hide Toggle " + val);	
			var hideValue:uint = val ? 1 : 0;
			// set HIDE bit to val
			highlightReadMode ^= (-hideValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.HIDE)/Math.log(2));
			// highlightReadMode ^= (-hideValue ^ highlightReadMode) & (1 << UserDataViewMode.HIDE);

			highlightsViewModeSet.dispatch(this, highlightReadMode);
			actionLogSignal.dispatch("PlayerToolbar: Hide highlights button - " + (val ? "HIDE" : "UNHIDE"));
			// hideHighlights.dispatch(val);
		}

		private function playButtonToggled(target:Object, val:Object):void {
			// trace("Play Toggle " + val);
			actionLogSignal.dispatch("PlayerToolbar: Play highlights button - " + (playButton.toggled ? "ON" : "OFF") + ") - #" + (playButton.selectedValue as uint).toString(16));
			
			if(playButton.toggled)
				startedPlayingHighlights.dispatch(this, playButton.selectedValue as uint);
			else
				stoppedPlayingHighlights.dispatch(this);
		}

		private function playHighlightButtonSelected(val:Object):void {
			actionLogSignal.dispatch("PlayerToolbar: Play highlights dropdown selected colour - #" + (playButton.selectedValue as uint).toString(16));
			startedPlayingHighlights.dispatch(this, (playButton.selectedValue as uint));
		}

		private function highlightButtonToggled(target:Object, val:Object):void {
			// trace("Highlight Toggle " + val);
			actionLogSignal.dispatch("PlayerToolbar: Highlights button - " + (val ? "ON" : "OFF") + " - #" + (highlightButton.selectedValue as uint).toString(16));
			var newMode:String = val ? HighlightMode.POST_SELECT : HighlightMode.PRE_SELECT;
			highlightsWriteModeSet.dispatch(this, newMode, highlightButton.selectedValue as uint);
		}

		private function highlightColourSelected(val:Object):void {
			// trace("Highlight Colour Select " + val)
			actionLogSignal.dispatch("PlayerToolbar: Highlights dropdown selected colour - #" + (highlightButton.selectedValue as uint).toString(16));
            var newMode:String = highlightButton.toggleActive ? HighlightMode.POST_SELECT : HighlightMode.PRE_SELECT;
            highlightsWriteModeSet.dispatch(this, newMode, highlightButton.selectedValue as uint);
//			highlighted.dispatch(highlightButton.toggleActive, val as uint);
		}

		private function personalButtonToggled(target:Object, val:Object):void {

			var personalValue:uint = val ? 1 : 0;
			// set HIDE bit to val
			highlightReadMode ^= (-personalValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.PERSONAL)/Math.log(2));
			highlightsViewModeSet.dispatch(this, highlightReadMode)
			highlightsViewModeSet.dispatch(this, highlightReadMode);

			viewCountRecordReadMode ^= (-personalValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.PERSONAL)/Math.log(2));
			highlightsViewModeSet.dispatch(this, viewCountRecordReadMode)
			viewCountRecordViewModeSet.dispatch(this, highlightReadMode)

		}

        private function instructorButtonToggled(target:Object, val:Object):void {

            var instructorValue:uint = val ? 1 : 0;
            // set HIDE bit to val
            highlightReadMode ^= (-instructorValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.INSTRUCTOR)/Math.log(2));
            highlightsViewModeSet.dispatch(this, highlightReadMode)

            viewCountRecordReadMode ^= (-instructorValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.INSTRUCTOR)/Math.log(2));
            viewCountRecordViewModeSet.dispatch(this, highlightReadMode)
        }

        private function classButtonToggled(target:Object, val:Object):void {

            var instructorValue:uint = val ? 1 : 0;
            // set HIDE bit to val
            highlightReadMode ^= (-instructorValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.CLASS)/Math.log(2));
            highlightsViewModeSet.dispatch(this, highlightReadMode)

            viewCountRecordReadMode ^= (-instructorValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.CLASS)/Math.log(2));
            viewCountRecordViewModeSet.dispatch(this, highlightReadMode)
        }

		public function setHighlightButtonToggle(val:Boolean):void {
			highlightButton.toggle = val;
		}

		public function setPlayButtonToggle(val:Boolean):void {
			playButton.toggle = val;
		}

		override public function stopPlayingHighlights():void {
			playButton.toggle = false;
		}

		public function set highlightEnabled(val:Boolean):void {
			highlightButton.mouseEnabled = val;
			playButton.mouseEnabled = val;
		}

		override public function setHighlightsWriteMode(mode:String, colour:uint):void {
			switch(mode) {
				case HighlightMode.POST_SELECT:
					highlightButton.toggle = true;
					break;
				case HighlightMode.PRE_SELECT:
					highlightButton.toggle = false;
					break;
				default:
					trace("PlayerToolbar.setHighlightMode(" + mode + ") - ???");
					trace(new Error().getStackTrace());
					break;
			}
		}
		override public function loadVideo(video:VideoMetadata):void { /* do nothing */ }
		override public function set playheadTime(time:Number):void { /* do nothing */ }
		override public function receiveSeek(time:Number):void { /* do nothing */ }
		override public function select(interval:Range):void { /* do nothing */ }
		override public function deselect():void { /* do nothing */ }
		override public function highlight(colour:int, interval:Range):void { /* do nothing */ }
		override public function unhighlight(colour:int, interval:Range):void { /* do nothing */ }
		override public function updateHighlights():void { /* do nothing */ }
		override public function setHighlightReadMode(mode:uint):void { /* do nothing */ }
		override public function setViewCountRecordReadMode(mode:uint):void { /* do nothing */ }
		override public function setPauseRecordReadMode(mode:uint):void { /* do nothing */ }
		override public function setPlaybackRateRecordReadMode(mode:uint):void { /* do nothing */ }
	}
}