////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.subtitleviewer {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.UserDataViewMode;
import ca.ubc.ece.hct.myview.video.VideoCaptions;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import collections.HashMap;
	import fl.controls.Label;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class SubtitleWord extends Sprite {

		private var _width:Number;
		private var _height:Number;

		public var tf:TextField;
		public var id:int;
		public var video:VideoMetadata;
		public var cueIndex:uint;
		public var payloadIndex:uint;

		private var highlightSprite:Shape;
		private var instructorHighlightSprite:Shape;
		
		private var searchHighlightMode:Boolean = false;
		private var txtFormat:TextFormat = new TextFormat("Arial", 12, 0x000000, false, false, false, null, null, "left", null, null, null, 4);
		private var searchTxtFormat:TextFormat = new TextFormat("Arial", 12, 0xff0000, false, false, false, null, null, "left", null, null, null, 4);

		public var originalX:Number, originalY:Number;
		public var captions:VideoCaptions;

		private var highlightReadMode:uint = UserDataViewMode.PERSONAL;

		public function SubtitleWord(id:int, video:VideoMetadata, payloadIndex:uint) {
			this.id = id;
			this.video = video;
			this.cueIndex = cueIndex;
			this.payloadIndex = payloadIndex;
			captions = video.getCaptions("eng");
			// this.payload = payload;
			tf = new TextField();
			tf.cacheAsBitmap = true;
			tf.mouseEnabled = false;
			var payload:Payload = captions.words[payloadIndex];
			tf.defaultTextFormat = txtFormat;
			// tf.wordWrap = true;
			tf.autoSize = "center";
			tf.text = payload.display();

			_width = tf.width;
			_height = tf.height;

			tf.x = 0;
			tf.y = 0;

			tf.mouseEnabled = false;
			addChild(tf);

			highlightSprite = new Shape();
			highlightSprite.cacheAsBitmap = true;
			highlightSprite.x = tf.x;
			highlightSprite.graphics.beginFill(0xff0000, 0);
			highlightSprite.graphics.drawRect(0, 0, tf.width, tf.height);
			highlightSprite.graphics.endFill();
			addChild(highlightSprite);

			instructorHighlightSprite = new Shape();
			highlightSprite.cacheAsBitmap = true;
			highlightSprite.x = tf.x;
		}


		public function drawHighlights(highlightSprite:Shape, highlightData:HashMap):void {

			// video.traceHighlights();
			highlightSprite.graphics.clear();
			// highlightSprite.graphics.beginFill(0xff0000, 0);
			// highlightSprite.graphics.drawRect(tf.x, tf.y, tf.width, tf.height + 10);
			// highlightSprite.graphics.endFill();

			var totalTime:Number = (endTime - startTime)/1000;
			var highlightWidth:Number = tf.width / totalTime;

			var totalHighlights:int = 0, highlightColours:Array = [];
			var highlights:Array = [];

			var colours:Array = highlightData.keys();

			for each(var colour:int in colours) {
				// var i:int = 0;
				for each(var highlightInterval:ca.ubc.ece.hct.Range in highlightData.grab(colour).intervals) {
					if( startTime*0.001 < highlightInterval.end && endTime*0.001 > highlightInterval.start) {
						// trace(startTime/1000 + " " + endTime/1000 + ", " + video.highlights[i][j].start + " " + video.highlights[i][j].end)
						var highlightObject:Object = {};
						highlightObject.startTime = Math.max(startTime*0.001, highlightInterval.start);
						highlightObject.endTime = Math.min(endTime*0.001, highlightInterval.end);
						highlightObject.colour = colour;
						if(highlightColours.indexOf(colour) == -1) {
							highlightColours.push(colour);
						}
						highlights.push(highlightObject);
						// i++;
					}
				}
			}

			highlights.sortOn("colour", Array.DESCENDING | Array.NUMERIC);

			var highlightY:Number = 0;
			for(var i:int = 0; i<highlights.length; i++) {

				var start:Number = (highlights[i].startTime - startTime/1000)/totalTime;
				var end:Number   = (highlights[i].endTime -   startTime/1000)/totalTime;
				if(start < 0)
					start = 0;
				if(end > 1)
					end = 1;
					
				var lineThickness:Number = tf.height/highlightColours.length-1;
				highlightSprite.graphics.beginFill(highlights[i].colour, 0.6);
				highlightSprite.graphics.drawRect(start*tf.width, (highlightY)*lineThickness, (end-start)*tf.width, lineThickness);
				highlightSprite.graphics.endFill();
				highlightY++;

			}
			setChildIndex(tf, numChildren - 1);

		}

		public function setHighlightReadMode(mode:uint):void {
			highlightReadMode = mode;
			if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
				if(highlightSprite && contains(highlightSprite)) 
					removeChild(highlightSprite);
				// if(viewCountRecordSprite && contains(viewCountRecordSprite)) 
				// 	removeChild(viewCountRecordSprite);
			} else {
				if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
					if(highlightSprite && !contains(highlightSprite)) 
						addChild(highlightSprite)
				} else {
					if(highlightSprite && contains(highlightSprite))
						removeChild(highlightSprite);
				}

				if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
					
				}

				if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
					if(instructorHighlightSprite && !contains(instructorHighlightSprite)) {
						addChild(instructorHighlightSprite)
					}
				} else {
					if(instructorHighlightSprite && contains(instructorHighlightSprite)) {
						removeChild(instructorHighlightSprite);
					}
				}
			}
			updateHighlights();
		}

		public function updateHighlights():void {
			if((highlightReadMode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {

			} else {
				if((highlightReadMode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
					drawHighlights(highlightSprite, video.userData.highlights);
				}

				if((highlightReadMode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
					
				}

				if((highlightReadMode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
					var instructorHighlights:Vector.<UserData> = video.crowdUserData.grab(UserData.INSTRUCTOR);
					if(instructorHighlights.length > 0) {
						drawHighlights(instructorHighlightSprite, instructorHighlights[0].highlights);
					}
				}
			}
			

		}

//		override public function set width(val:Number):void {
//			tf.width = val;
//		}

		override public function get width():Number {
			return _width;
		}

		override public function get height():Number {
			return _height;
		}

		public function showHighlights(val:Boolean):void {

			if(!val && contains(highlightSprite)) {
				removeChild(highlightSprite);
			} else {
				addChild(highlightSprite);
				setChildIndex(tf, numChildren-1)
			}
		}

		public function searchHighlight(start:int, end:int):void {
			searchUnhighlight();
			var startIndex:int = Math.min(tf.text.length-1, Math.max(0, start));
			var endIndex:int = Math.max(1, Math.min(tf.text.length-1, end));
			tf.setTextFormat(searchTxtFormat, startIndex, endIndex);
			searchHighlightMode = true;
		}

		public function searchUnhighlight():void {
			searchHighlightMode = false;
			tf.setTextFormat(txtFormat, 0, text.length);
		}

		public function playheadHighlight(hl:Boolean = true):void {
			if(hl && !searchHighlightMode && tf.textColor != 0xdd0000) {
				tf.textColor = 0xdd0000;
			} else if(!searchHighlightMode && tf.textColor != 0x000000) {
				tf.textColor = 0x000000;
			}
		}

		public function selectionHighlight(hl:Boolean = true):void {
			if(hl) {
				graphics.clear();
				graphics.beginFill(0x8888ff, 0.6);
				graphics.drawRect(tf.x, tf.y, tf.width, tf.height);
				graphics.endFill();
			} else {
				graphics.clear();
			}
		}

		public function setSelectionInSeconds(range:ca.ubc.ece.hct.Range):void {
			var totalTime:Number = (endTime - startTime)/1000;
			if(startTime/1000 <= range.end && endTime/1000 >= range.start) {
						
				var start:Number = (range.start - startTime/1000)/totalTime * tf.width;
				var end:Number = (range.end - startTime/1000)/totalTime * tf.width;
				if(start < 0)
					start = 0;
				if(end > tf.width)
					end = tf.width;

				graphics.clear();
				graphics.beginFill(0x8888ff, 0.6);
				graphics.drawRect(start, 0, (end-start), tf.height);
				graphics.endFill();
			} else {
				deselect();
			}
		}

		public function get text():String {
			return tf.text;
		}

		public function drawBounds():void {
			graphics.clear();
			graphics.moveTo(0, 0);
			graphics.lineStyle(1, 0x00ff00);
			graphics.lineTo(width-1, 0);
			graphics.lineTo(width-1, height-1);
			graphics.lineTo(0, height-1);
			graphics.lineTo(0, 0);
		}

		public function deselect():void {
			graphics.clear();
		}

		public function get startTime():Number {
			return payload.startTime;
		}

		public function get endTime():Number {
			return payload.endTime;
		}

		public function get payload():Payload {
			return captions.words[payloadIndex];
		}

		public function toStr():String {
			return payload.toString();
		}
	}
}