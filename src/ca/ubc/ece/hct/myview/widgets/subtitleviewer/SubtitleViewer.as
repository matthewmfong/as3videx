////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.subtitleviewer {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.Colours;
import ca.ubc.ece.hct.myview.AnnotationCallout;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.ui.SearchBar;
import ca.ubc.ece.hct.myview.widgets.player.PlayerEvent;
import ca.ubc.ece.hct.myview.ui.UIScrollView;
import ca.ubc.ece.hct.myview.video.VideoCaptions;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.Widget;

import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.text.TextFormat;
import flash.utils.getTimer;

import org.osflash.signals.Signal;

public class SubtitleViewer extends Widget {

//		public static const SEARCH_INPUT_FOCUS_IN:String = "SearchInputFocusIn";
//		public static const SEARCH_INPUT_FOCUS_OUT:String = "SearchInputFocusOut";

		public var highlightModeChanged:Signal;
		public var highlightApplied:Signal;

		// protected var svm.video:Video;
		// private var cue:Array;
		protected var captions:VideoCaptions;
		protected var subtitleWords:Vector.<SubtitleWord>;
		protected var subtitleWordsInLine:Vector.<Array>;
		protected var timeStamps:Array;
		protected var currentHighlightedTextFieldIndex:uint = uint.MAX_VALUE;
		protected var currentHighlightedTextLine:uint = uint.MAX_VALUE;
		protected var subtitleWordStartSelect:SubtitleWord, subtitleWordEndSelect:SubtitleWord;
		// protected var selectStart:Number = 0, selectEnd:Number = 0;
		// make sure mouseMoveOnLabel doesn't activate if mouse is up
		protected var mouseDown:Boolean;

		protected var containerMask:Shape;
		protected var container:Sprite;

		protected var scrollPane:UIScrollView;
		protected var background:Sprite;

//		protected var toolbar:SubtitleViewerToolbar;

		protected var txtFormat:TextFormat = new TextFormat("Arial", 10, 0x000000, false, false, false, null, null, "left", null, null, null, 4);
		protected var rollOverTxtFormat:TextFormat = new TextFormat("Arial", 10, 0x0000ff, false, false, true, null, null, "left", null, null, null, 4);


		public var svm:SubtitleViewerModel;

		public var actionLogSignal:Signal;

		public var viewChanged:Boolean = false;

		private var longtimeTextfieldWidth:Number;
		private var longtimeTextfieldHeight:Number;


		public function SubtitleViewer() {
			_width = 100;
			_height = 100;
			// highlightMode = HIGHLIGHT_MODE_OFF;
			highlightModeChanged = new Signal(String); // HIGHLIGHT_MODE_ON or HIGHLIGHT_MODE_OFF
			highlightApplied = new Signal(uint, Range); // colour, Range(startTime, endTime);

//			toolbar = new SubtitleViewerToolbar(_width+1);

			actionLogSignal = new Signal(String);

            svm = new SubtitleViewerModel();
            svm.highlightMode = SubtitleViewerModel.HIGHLIGHT_MODE_OFF;

            scrollPane = new UIScrollView(_width, _height);
            container = new Sprite();
            scrollPane.source = container;
            background = new Sprite();

            addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}

		override protected function addedToStage(e:Event = null):void {
			super.addedToStage(e);
            background.addEventListener(MouseEvent.CLICK, mouseSelectNone);
            background.addEventListener(MouseEvent.MOUSE_UP, mouseUpOnBackground);
            addEventListener(MouseEvent.ROLL_OUT, mouseUpOnBackground);


            addChild(scrollPane);
            updateHighlights();
			viewChanged = true;
		}

		override public function dispose():void {
			for each(var sw:SubtitleWord in subtitleWords) {
				container.removeChild(sw);
			}

			subtitleWords = null;
			subtitleWordsInLine = null;
			subtitleWordStartSelect = null;
			subtitleWordEndSelect = null;
            container.removeChild(background);
            background = null;
			container = null;
			removeChild(scrollPane);
			scrollPane = null;

			actionLogSignal = null;
			highlightModeChanged = null;
			highlightApplied = null;

		}

		override public function loadVideo(video:VideoMetadata):void {
			svm.video = video;
			captions = svm.video.getCaptions("eng");

            populate();

            background.graphics.beginFill(0xffffff, 1);
            background.graphics.drawRect(0, 0, container.width, container.height);
            background.graphics.endFill();
            container.addChild(background);
			container.setChildIndex(background, 0);
            viewChanged = true;

            var tfTest:SubtitleViewerTimeTextField = new SubtitleViewerTimeTextField();
            tfTest.defaultTextFormat = txtFormat;
            tfTest.autoSize = "center";
            tfTest.text = "[" + Util.millisecondsToHMS(captions.words[captions.words.length-1].startTime) + "]";

			longtimeTextfieldWidth = tfTest.width;
			longtimeTextfieldHeight = tfTest.height;
			tfTest = null;
		}


		private function mouseSelectNone(e:MouseEvent):void {
			actionLogSignal.dispatch("SubtitleViewer: Deselected all words.");
			deselect();
			deselected.dispatch(this);
		}

		public function set video(val:VideoMetadata):void {
			svm.video = val;
			var remove:DisplayObject;
			while(container.numChildren > 0) {
				remove = container.getChildAt(0);
				container.removeChild(remove);
				remove = null;
				// subtitleWords = [];	
			}

			container = new Sprite();

			container.addChild(background);

			populate();

			background.graphics.beginFill(0xffffff, 1);
			background.graphics.drawRect(0, 0, container.width, container.height);
			background.graphics.endFill();
			updateHighlights();

			scrollPane.source = container;
		}

//		public function enable():void {
//			if(!contains(disableSprite))
//				addChild(disableSprite);
//			else
//				removeChild(disableSprite);
//		}

		public function setHighlightMode(val:String):void {
			svm.highlightMode = val;
		}

		override public function setHighlightReadMode(mode:uint):void {
			for each(var subtitleWord:SubtitleWord in subtitleWords) {	
				subtitleWord.setHighlightReadMode(mode);
			}
		}

		public function setHighlightColour(val:uint):void {
			svm.highlightColour = val;
		}

		private function populate():void {
			subtitleWords = new <SubtitleWord>[];
			var lineNumber:int = 0;
			var lab:SubtitleWord;
			var subtitleWordId:int = 0;
			mouseDown = false;

			if(captions.cues.length > 0) {

				for(var i:int = 0; i<captions.words.length; i++) {

					lab = new SubtitleWord(subtitleWordId, svm.video, i);
					subtitleWordId++;

					subtitleWords.push(lab);
					container.addChild(lab);

					lab.doubleClickEnabled = true;
					lab.addEventListener(MouseEvent.CLICK, mouseClickOnLabel);
					lab.addEventListener(MouseEvent.DOUBLE_CLICK, mouseDoubleClickOnLabel);
					lab.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownOnLabel);
					lab.addEventListener(MouseEvent.MOUSE_UP, mouseUpOnLabel);
					lab.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveOnLabel);
					lab.addEventListener(MouseEvent.ROLL_OVER, Util.mouseCursorIBeam);
					lab.addEventListener(MouseEvent.ROLL_OUT, Util.mouseCursorArrow);
				}
			}

			container.graphics.beginFill(0xffffff)
			container.graphics.drawRect(0, 0, container.width, container.height + 10);
			container.graphics.endFill();
		}

		override public function set playheadTime(timex:Number):void {

			for(var i:int = 0; i<subtitleWordsInLine.length; i++) {

				if(subtitleWordsInLine[i][0].payload.startTime <= timex * 1000 &&
					subtitleWordsInLine[i][subtitleWordsInLine[i].length-1].payload.endTime >= timex * 1000 &&
					i != currentHighlightedTextLine) {

					for(var j:int = 0; j<subtitleWordsInLine[i].length; j++) {
						subtitleWordsInLine[i][j].playheadHighlight();
					}
					currentHighlightedTextLine = i;
                    viewChanged = true;

				} else if(i != currentHighlightedTextLine) {

					for(var k:int = 0; k<subtitleWordsInLine[i].length; k++) {
						subtitleWordsInLine[i][k].playheadHighlight(false);
					}

				}
			}

		}

		override public function receiveSeek(time:Number):void { }

		override public function searchText(searchString:String):void {

			var range:Range;
			
			if(searchString != ""){
//
				// searching for something
				var regex:RegExp = new RegExp(searchString, "ig")
				var result:Object = null;

				if(captions.rawText != null) {
					result = regex.exec(captions.rawText);
				}

				var highlightRanges:Array = [];
				while(result != null) {
					range = new Range(result.index, result.index + searchString.length-1);

					highlightRanges.push(range);
					result = regex.exec(captions.rawText);
				}

				scrollPane.searchUnhighlight();
				for(var i:int = 0; i<subtitleWords.length; i++) {
					subtitleWords[i].searchUnhighlight();
				}

				var characterCounter:int = 0;
				var nextSubWord:int = 0;
				var wordsHighlighted:Array = [];
				for(i = 0; i<highlightRanges.length; i++) {
					// trace("Highlight : " + highlightRanges[i]);

					for(var j:int = nextSubWord; j<subtitleWords.length; j++) {
						range = new Range(characterCounter, characterCounter + subtitleWords[j].text.length);

						// trace("Try range " + range + " in [" + j + "] " + subtitleWords[j].text);

						characterCounter += subtitleWords[j].text.length;

						if(highlightRanges[i].start < range.end && highlightRanges[i].end >= range.start) {

							var lastCharCount:int = characterCounter - subtitleWords[j].text.length;
							// trace("highlighting [" +
							// 		(highlightRanges[i].start - lastCharCount) + ", " +
							// 		(highlightRanges[i].end - lastCharCount) + "] of " + subtitleWords[j].text);

							subtitleWords[j].searchHighlight(highlightRanges[i].start - lastCharCount, highlightRanges[i].end - lastCharCount + 1);
							wordsHighlighted.push(j);


							if(subtitleWords[j].text.length-1 >= highlightRanges[i].end - lastCharCount) {
								// trace("NEXT HIGHLIGHT");
								characterCounter -= subtitleWords[j].text.length;
								nextSubWord = j;
								break;
							}
						}
					}
				}

				// trace(wordsHighlighted)
				var wordsHighlightedLength:uint = wordsHighlighted.length;
				var highlightRects:Vector.<Rectangle> = new Vector.<Rectangle>;
				for(i = 0; i<wordsHighlightedLength; i++) {
					// if(i >= 1)
						// trace(subtitleWords[wordsHighlighted[i]].y + "  " + subtitleWords[wordsHighlighted[i]].y);
					// trace(subtitleWords[wordsHighlighted[i]].height);
					// trace("i = " + i);
					if(i >= 1 && subtitleWords[wordsHighlighted[i]].y != highlightRects[highlightRects.length - 1].y) {
						highlightRects.push(new Rectangle(0, subtitleWords[wordsHighlighted[i]].y, 0, subtitleWords[wordsHighlighted[i]].height));
					} else if (i == 0) {
						highlightRects.push(new Rectangle(0, subtitleWords[wordsHighlighted[i]].y, 0, subtitleWords[wordsHighlighted[i]].height));
					}
				}

				scrollPane.searchHighlights(highlightRects);
//
//				background.graphics.clear();
//				background.graphics.beginFill(0xffffff, 1);
//				background.graphics.drawRect(0, 0, container.width, container.height);
//				background.graphics.endFill();
			}
// else {
//				// not searching
//				scrollPane.searchUnhighlight();
//				for(var k:int = 0; k<subtitleWords.length; k++) {
//					subtitleWords[k].searchUnhighlight();
//				}
//			}
//
//			searchedText.dispatch(this, string);
            viewChanged = true;

		}

		public function addToolbarListeners():void {

//			toolbar.searchFocus.add(
//				function searchInputFocusIn(val:String):void {
//					if(val == SubtitleViewerToolbar.SEARCH_INPUT_FOCUS_IN)
//						dispatchEvent(new Event(SubtitleViewerToolbar.SEARCH_INPUT_FOCUS_IN));
//					else if (val == SubtitleViewerToolbar.SEARCH_INPUT_FOCUS_OUT)
//						dispatchEvent(new Event(SubtitleViewerToolbar.SEARCH_INPUT_FOCUS_OUT));
//				});

		}

		override public function updateHighlights():void {

			if(subtitleWords) {
                for (var i:int = 0; i < subtitleWords.length; i++) {
                    subtitleWords[i].updateHighlights();
                }
            }

			viewChanged = true;

//			for(i = 0; i<timeStamps.length; i++) {
//				if(subtitleWordsInLine[i][0] != null) {
//					var range:Range = new Range(subtitleWordsInLine[i][0].startTime/1000, subtitleWordsInLine[i][subtitleWordsInLine[i].length-1].endTime/1000);
//					timeStamps[i].drawHighlights(svm.video.userData.getHighlightedColoursforTimeRange(range));
//				}
//			}
		}

		public function showHighlights(val:Boolean):void {
			for(var i:int = 0; i<subtitleWords.length; i++) {
				subtitleWords[i].showHighlights(val);
			}
            viewChanged = true;
		}

		private function mouseClickOnTime(e:MouseEvent):void {
			// trace(e.currentTarget.time);
			actionLogSignal.dispatch("SubtitleViewer: Clicked time - " + e.currentTarget.time/1000);

            stoppedPlayingHighlights.dispatch(this);
			seeked.dispatch(this, e.currentTarget.time/1000);
			dispatchEvent(new PlayerEvent(PlayerEvent.SEEK, -1, e.currentTarget.time/1000));
		}

		private function mouseRollOverOnTime(e:MouseEvent):void {
			Util.mouseCursorButton();
			e.target.defaultTextFormat = rollOverTxtFormat;
			e.target.text = e.target.text;
		}

		private function mouseRollOutOnTime(e:MouseEvent):void {
			Util.mouseCursorArrow();
			e.target.defaultTextFormat = txtFormat;
			e.target.text = e.target.text;
		}

		private function mouseClickOnLabel(e:MouseEvent):void {
			deselect();
		}

		private function mouseDoubleClickOnLabel(e:MouseEvent):void {
			var subtitleWordSelect:SubtitleWord = (SubtitleWord)(e.target);
			// subtitleWordSelect.selectionHighlight();
			// dispatchEvent(new HighlightEvent(HighlightEvent.SELECT, subtitleWordSelect.payload.startTime/1000, subtitleWordSelect.payload.endTime/1000))
			var startTime:Number = Math.max(0, subtitleWordSelect.payload.startTime/1000 - 10);
			var endTime:Number = subtitleWordSelect.payload.endTime/1000;

			actionLogSignal.dispatch("SubtitleViewer: Double Click \"" + (SubtitleWord)(e.target) + "\", selected [" + startTime + ", " + endTime + "]");

			select(new Range(startTime, endTime));
			selected.dispatch(this, new Range(startTime, endTime))
		}

		private function mouseDownOnLabel(e:MouseEvent):void {
			// trace(e.target.payload);
			subtitleWordStartSelect = (SubtitleWord)(e.target);
			svm.selection.start = subtitleWordStartSelect.startTime/1000;
			mouseDown = true;
		}

		private function mouseMoveOnLabel(e:MouseEvent):void {
			if(mouseDown) {
				var subtitleWordEndSelect:SubtitleWord = (SubtitleWord)(e.target);

				var smallerId:int = subtitleWordEndSelect.id > subtitleWordStartSelect.id ? subtitleWordStartSelect.id : subtitleWordEndSelect.id;
				var biggerId:int = subtitleWordEndSelect.id > subtitleWordStartSelect.id ? subtitleWordEndSelect.id : subtitleWordStartSelect.id;

				// dispatchEvent(new HighlightEvent(HighlightEvent.SELECTING, subtitleWords[smallerId].payload.startTime/1000, subtitleWords[biggerId].payload.endTime/1000))
				selecting.dispatch(this, new Range(subtitleWords[smallerId].payload.startTime/1000, subtitleWords[biggerId].payload.endTime/1000));

				for(var i:int = 0; i<subtitleWords.length; i++) {
					if(i >= smallerId && i <= biggerId) {
						subtitleWords[i].selectionHighlight();
					} else {
						subtitleWords[i].selectionHighlight(false);
					}
						
				}
			}
		}

		private function mouseUpOnLabel(e:MouseEvent):void {

			if(mouseDown) {
				subtitleWordEndSelect = (SubtitleWord)(e.target);
				
				var smaller:SubtitleWord = subtitleWordEndSelect.id > subtitleWordStartSelect.id ? subtitleWordStartSelect : subtitleWordEndSelect;
				var bigger:SubtitleWord = subtitleWordEndSelect.id > subtitleWordStartSelect.id ? subtitleWordEndSelect : subtitleWordStartSelect;

				svm.selection.start = smaller.startTime/1000;
				svm.selection.end = bigger.endTime/1000;


				actionLogSignal.dispatch("SubtitleViewer: Selected [" + Util.roundNumber(svm.selection.start, 2) + ", " + Util.roundNumber(svm.selection.end, 2) + "]");


				var selectionRange:Range = new Range(smaller.payload.startTime/1000, bigger.payload.endTime/1000);

				if(selectionRange.length > 0.5) {
                    selected.dispatch(this, selectionRange);
                }
			}
			mouseDown = false;
		}

		private function mouseUpOnBackground(e:MouseEvent):void {
			mouseDown = false;
			actionLogSignal.dispatch("SubtitleViewer: Selected [" + Util.roundNumber(svm.selection.start, 2) + ", " + Util.roundNumber(svm.selection.end, 2) + "]");
		}

		override public function select(range:Range):void {
			deselect();
			svm.selection.start = range.start;
			svm.selection.end = range.end;
			for(var i:int = 0; i<subtitleWords.length; i++) {
				if(subtitleWords[i].startTime/1000 <= range.end && subtitleWords[i].endTime/1000 >= range.start)
					subtitleWords[i].setSelectionInSeconds(range);
			}
            viewChanged = true;

			// if(range.length == 0) {
			// 	highlightButtonMaster.enabled = false;
			// } else {
			// 	highlightButtonMaster.enabled = true;
			// }
		}

		override public function deselect():void {
			for(var i:int = 0; i<subtitleWords.length; i++) {
				subtitleWords[i].deselect();
			}

            viewChanged = true;
			// highlightButtonMaster.enabled = false;
		}

		override public function setSize(width:Number, height:Number):void {
			_width = width;
			_height = height;
//            var asdfTime:Number = getTimer();


            scrollPane.setSize(_width, _height);
            background.graphics.clear();
            background.graphics.beginFill(0xffffff, 1);
            background.graphics.drawRect(0, 0, _width, _height);
            background.graphics.endFill();

            graphics.clear();
            graphics.beginFill(0xffffff, 1);
            graphics.drawRect(0, 0, _width, _height);
            graphics.endFill();
            graphics.lineStyle(1, 0xcccccc);

			if(timeStamps) {
                for (var i:int = 0; i < timeStamps.length; i++) {
                    container.removeChild(timeStamps[i]);
                }
            }

            var xLoc:Number = 0;
            var yLoc:Number = 0;
            var lineNumber:int = 0;
            timeStamps = [];
            subtitleWordsInLine = new <Array>[];
            if(captions && captions.cues.length > 0) {


                var tf:SubtitleViewerTimeTextField = new SubtitleViewerTimeTextField();
                tf.defaultTextFormat = txtFormat;

                tf.text = "[" + Util.millisecondsToHMS(captions.words[0].startTime) + "]";
                tf.time = captions.words[0].startTime;
                tf.autoSize = "center";
                tf.x = xLoc + longtimeTextfieldWidth - tf.width;
                tf.y = yLoc;
//                tf.originalX = tf.x;
//                tf.originalY = tf.y;
                container.addChild(tf);
                tf.addEventListener(MouseEvent.CLICK, mouseClickOnTime);
                tf.addEventListener(MouseEvent.ROLL_OVER, mouseRollOverOnTime);
                tf.addEventListener(MouseEvent.ROLL_OUT, mouseRollOutOnTime);
                timeStamps.push(tf);
                xLoc = tf.x + tf.width;
                subtitleWordsInLine.push([]);

                var newParagraph:Boolean = false;
                var startParagraphTime:Number = captions.words.length > 0 ? captions.words[0].startTime : 0;

                for(var j:int = 0; j<subtitleWords.length; j++) {

					if(newParagraph) {
                        lineNumber++;
                        subtitleWordsInLine.push([]);


                        tf = new SubtitleViewerTimeTextField();
                        tf.defaultTextFormat = txtFormat;
                        tf.text = "[" + Util.millisecondsToHMS(captions.words[j].startTime) + "]";
                        tf.time = captions.words[j].startTime;
                        tf.autoSize = "center";

                        xLoc = longtimeTextfieldWidth - tf.width;
						yLoc = tf.height + yLoc + 20;

                        tf.x = xLoc;
                        tf.y = yLoc;
//                        tf.originalX = tf.x;
//                        tf.originalY = tf.y;
                        container.addChild(tf);
                        tf.addEventListener(MouseEvent.CLICK, mouseClickOnTime);
                        tf.addEventListener(MouseEvent.ROLL_OVER, mouseRollOverOnTime);
                        tf.addEventListener(MouseEvent.ROLL_OUT, mouseRollOutOnTime);
                        timeStamps.push(tf);

						xLoc = longtimeTextfieldWidth;

                        startParagraphTime = lab.startTime;
                        newParagraph = false;
					}

                    var lab:SubtitleWord = subtitleWords[j];
                    lab.x = xLoc;
                    lab.y = yLoc;
                    lab.originalX = xLoc;
                    lab.originalY = yLoc;

                    if(lab.x + lab.width > _width && subtitleWordsInLine[lineNumber].length > 0 /* make sure there's at least 1 word per line*/ ) {

                        lineNumber++;
                        subtitleWordsInLine.push([]);
                        xLoc = longtimeTextfieldWidth;
                        yLoc += lab.height;

                        lab.x = xLoc;
                        lab.y = yLoc;
                    }

                    subtitleWordsInLine[lineNumber].push(lab);
                    xLoc = lab.x + lab.width;

                    if(subtitleWords[j].endTime - startParagraphTime > 30000 && subtitleWords[j].text.indexOf(".") > -1) {
//                        trace("new paragraph: " + lab.endTime + " - " + startParagraphTime)
                        newParagraph = true;
                    }

//					if(j > 0)
//						trace(subtitleWords[j].startTime - subtitleWords[j-1].endTime);
//					if(j > 0 && subtitleWords[j].startTime - subtitleWords[j-1].endTime > 20  && (subtitleWords[j].text.indexOf(". ") > -1)) {
//						trace("new pa: " + subtitleWords[j-1].text + ", " + subtitleWords[j].text);
//						newParagraph = true;
//					}
                }


            }
//            updateHighlights();

            container.graphics.clear();
            container.graphics.beginFill(0xffffff);
            container.graphics.drawRect(0, 0, container.width, yLoc + 10);
            container.graphics.endFill();

            scrollPane.update();
            viewChanged = true;
//            trace(subtitleWords.length + " " + (getTimer() - asdfTime));
		}

		override public function get width():Number {
			return _width;
		}

		override public function set width(val:Number):void {
			setSize(val, _height);
		}

		override public function get height():Number {
			return _height;
		}

		override public function set height(val:Number):void {
			setSize(_width, val);
		}
	}
	
}