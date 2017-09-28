////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.filmstrip {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.Colours;
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.UserDataViewMode;
import ca.ubc.ece.hct.myview.ui.FloatingTextField;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import collections.HashMap;

import flash.display.BitmapData;

import flash.display.Shape;
import flash.events.ErrorEvent;

import flash.events.TimerEvent;
import flash.geom.Rectangle;
import flash.utils.Timer;
import flash.utils.getTimer;

import org.osflash.signals.Signal;

import starling.display.Canvas;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.geom.Polygon;
import starling.text.TextFormat;
import starling.textures.Texture;

public class Filmstrip extends SimpleFilmstrip {

		public static const VIEW_COUNT_RECORD_HEIGHT:uint = 15;

		private var highlightSprite:Canvas;
		private var globalHighlightsSprite:Canvas;
		private var instructorHighlightSprite:Canvas;

		public var selectionHighlightSprite:Canvas;
		private var viewCountRecordSprite:ViewCountRecord;
        private var viewCountRecordSpriteLastUpdate:Number = 0;
		private var globalViewCountRecordSprite:ViewCountRecord;

//		public var viewCountRecordThickness:uint;

		private var playhead:Quad;
		private var cursor:Quad;
		protected var previewText:FloatingTextField;

		private var timeTicks:Quad;
		private var timeTexts:Sprite;
//		private var timeTickTF:Array;

//		private var _showViewCount:Boolean = true;
//		private var _showGlobalViewCount:Boolean = false;
//		private var _showHighlight:Boolean = true;
//		private var _showGlobalHighlights:Boolean = false;

		private var redrawAfterResizeTimer:Timer;

		public var playHighlightClicked:Signal;

		public function Filmstrip() {
			super();

			viewCountRecordSprite = new ViewCountRecord();
            globalViewCountRecordSprite = new ViewCountRecord();
			highlightSprite = new Canvas();
			instructorHighlightSprite = new Canvas();
			globalHighlightsSprite = new Canvas();
			selectionHighlightSprite = new Canvas();
			selectionHighlightSprite.touchable = false;

            playhead = new Quad(2, _height);
			playhead.touchable = false;
			cursor = new Quad(2, _height);
			cursor.touchable = false;

            previewText = new FloatingTextField("00:00", new TextFormat("Arial", 10, 0xFFFFE8, "center"));//true, false, false, null, null, "center", null, null, null, 4));

            timeTicks = new Quad(1, 1);
            timeTicks.touchable = false;
            addChild(timeTicks);

            timeTexts = new Sprite();
            timeTexts.touchable = false;
            addChild(timeTexts);

			playHighlightClicked = new Signal(Range);
		}


		override public function loadVideo(video:VideoMetadata):void {
			super.loadVideo(video);
		}

		override protected function addedToStage(e:Event = null):void {
			super.addedToStage(e);

            addChild(viewCountRecordSprite);
			if(_video) {
                drawViewCountRecord(viewCountRecordSprite, _video.userData.viewCountRecord);
            }

            // updateHighlights();
            addChild(selectionHighlightSprite);
            addChild(highlightSprite);

			drawPlayhead();
			addChild(playhead);

			drawCursor();
            drawTimeTicks();
		}

		override public function dispose():void {
			super.dispose();


            if(viewCountRecordSprite) {
                if(contains(viewCountRecordSprite)) {
                    removeChild(viewCountRecordSprite);
                }
                viewCountRecordSprite.dispose();
				viewCountRecordSprite = null;
            }


            if(globalViewCountRecordSprite) {
                if(contains(globalViewCountRecordSprite)) {
                    removeChild(globalViewCountRecordSprite);
                }
                globalViewCountRecordSprite.dispose();
				globalViewCountRecordSprite = null;
            }

			if(selectionHighlightSprite) {
				if(contains(selectionHighlightSprite)) {
                    removeChild(selectionHighlightSprite);
                }
                selectionHighlightSprite.dispose();
                selectionHighlightSprite = null;
            }

			if(highlightSprite) {
				if(contains(highlightSprite)) {
                    removeChild(highlightSprite);
                }
                highlightSprite.dispose();
                highlightSprite = null;
            }

			if(playhead) {
				if(contains(playhead)) {
                    removeChild(playhead);
                }
                playhead.dispose();
                playhead = null;
            }

			if(cursor) {
                if(contains(cursor)) {
                    removeChild(cursor);
                }
				cursor.dispose();
				cursor = null;
			}

			if(timeTicks) {
				if(contains(timeTicks)) {
					removeChild(timeTicks);
				}
				timeTicks.dispose();
				timeTicks = null;
			}



		}

		override public function set playheadTime(time:Number):void {

			if(time < startTime || time > endTime) {
				playhead.alpha = 0;
				playhead.x = -1;
			} else {
				playhead.alpha = 1;
//				if(playhead.x != -1)
//					TweenLite.to(playhead, 0.15, {x: (time - startTime) / duration * _width,
//												 ease: Power0.easeNone});
//				else
					playhead.x = (time - startTime) / duration * _width;
			}
			// currentTime = time;
            if(getTimer() - viewCountRecordSpriteLastUpdate > 1000) {
                drawViewCountRecord(viewCountRecordSprite, _video.userData.viewCountRecord);
                viewCountRecordSpriteLastUpdate = getTimer();
            }
		}

		public function setSeekLinePosition(val:Number):void {

			previewText.text = timeInSecondsToTimeString(getTimeFromXCoordinate(val));
			previewText.x = val - previewText.width - 2;

//			TweenLite.to(previewText, 0.15, {x: Math.max(0, val - previewText.width - 2),
//				ease: Power0.easeNone});
			cursor.x = val;
		}

		override protected function touched(e:TouchEvent):void {
			super.touched(e);

			if(touch) {
//				trace("touch");
				if(!contains(cursor)) {
					addChild(cursor);
                    addChild(previewText);
				}
                switch (touch.phase) {
					case TouchPhase.MOVED:
                    case TouchPhase.HOVER:
                        setSeekLinePosition(touch.getLocation(this).x);
                        break;
                }
            } else {
				if(contains(cursor)) {
                    removeChild(previewText);
					removeChild(cursor);
				}
			}
		}

		override public function select(selectionInterval:Range):void {
            if(contains(cursor)) {
                removeChild(previewText);
                removeChild(cursor);
            }

			var start:Number = (selectionInterval.start - startTime) / (endTime+1 - startTime) * _width;
			start = (start < 0) ? 0 : start;
			var end:Number = (selectionInterval.end - startTime) / (endTime+1 - startTime) * _width;
			end = (end > _width) ? _width: end;

			selectionHighlightSprite.clear();
			selectionHighlightSprite.beginFill(0x4444ff, 0.4);
			selectionHighlightSprite.drawRectangle(start, 0, (end - start), height);
			selectionHighlightSprite.endFill();
			if(!contains(selectionHighlightSprite)) {
				addChild(selectionHighlightSprite);
				reorderSpriteIndex()
			}
		}

		override public function deselect():void {
			selectionHighlightSprite.clear();
		}

		protected function drawPlayhead():void {
			playhead.setVertexColor(0, 0x0088aa);
			playhead.setVertexColor(1, 0x0088aa);
			playhead.setVertexColor(2, 0x00ccff);
			playhead.setVertexColor(3, 0x00ccff);
		}

		protected function drawCursor():void {
			cursor.setVertexColor(0, 0xaa0000);
            cursor.setVertexColor(1, 0xaa0000);
            cursor.setVertexColor(2, 0xff0000);
            cursor.setVertexColor(3, 0xff0000);
		}

		override protected function drawThumbnailMask():void {
//			_thumbnailContainer.mask = new Canvas();
//			var maskVertices:Array = [];
//			var numSpikes:int = 8;
//			var spikeWidth:int = 10;
//
//			if(interval.start == 0 && Math.abs(1 - interval.end) <= 0.05) {
//				maskVertices.push(0, 0,
//								  _width, 0,
//								  _width, _height,
//						          0, _height);
//			} else {
//
//				if(interval.start == 0) {
//					maskVertices.push(0, 0,
//									  _width - spikeWidth, 0);
//				} else {
//                    maskVertices.push(spikeWidth, 0,
//                            		  _width - spikeWidth, 0);
//				}
//
//				if(Math.abs(1 - interval.end) <= 0.05) {
//
//                    maskVertices.push(_width, 0,
//                            		  _width, _height);
//				} else {
//					for(var i:int = 1; i <= numSpikes; i++) {
//						maskVertices.push(_width, i*_height/numSpikes - _height/numSpikes/2,
//										  _width - spikeWidth, (i/numSpikes)*_height);
//					}
//				}
//
//				maskVertices.push(spikeWidth, _height);
//				if(interval.start == 0) {
//					maskVertices.push(0, _height,
//									  0, 0);
//				} else {
//					for(var j:int = 1; j <= numSpikes; j++) {
//						maskVertices.push(0, _height - (j*_height/numSpikes - _height/numSpikes/2),
//                                	      spikeWidth, _height - (j/numSpikes)*_height)
//					}
//					maskVertices.push(spikeWidth, 0);
//				}
//			}
//
//			(Canvas)(_thumbnailContainer.mask).clear();
//			(Canvas)(_thumbnailContainer.mask).drawPolygon(new Polygon(maskVertices));
		}

		public function drawViewCountRecord(viewCountRecordSprite:ViewCountRecord, viewCountRecord:Array,
											colours:Array = null,
											alphas:Array = null,
    										ratios:Array = null):void {

			if(viewCountRecord.length > 0 && contains(viewCountRecordSprite)) {
				viewCountRecordSprite.width = _width;
				viewCountRecordSprite.height = _height/4;
				viewCountRecordSprite.y = _height - viewCountRecordSprite.height;
				viewCountRecordSprite.draw(viewCountRecord, startTime, endTime, colours, alphas, ratios);
			}
		}

		private function drawHighlights(highlightSprite:Canvas, highlightData:HashMap):void {
			var highlightLineThickness:uint = 4;
			var highlightSpriteThickness:uint = 10;

			if(highlightSprite) {
                highlightSprite.clear();
                while (highlightSprite.numChildren > 0) {
                    highlightSprite.removeChildAt(0);
                }
//			var totalTime:Number = (endTime - startTime);
//			var highlightWidth:Number = _width / totalTime;

                highlightSprite.beginFill(0, 0.3);
                highlightSprite.drawRectangle(0, 0, _width, highlightData.values().length * highlightLineThickness);
                highlightSprite.endFill();

                // draw an invisible mouse_over area
                highlightSprite.beginFill(0xff0000, 0);
                highlightSprite.drawRectangle(0, 0, _width, highlightSpriteThickness);
                highlightSprite.endFill();

                var colours:Array = Colours.sortColours(highlightData.keys());

                var i:int = 0;
                for each(var colour:int in colours) {

                    for each(var highlightInterval:Range in highlightData.grab(colour).intervals) {

                        if (startTime <= highlightInterval.end && endTime >= highlightInterval.start) {

                            var timeRange:Range = highlightInterval;
                            var xDimension:Number = Math.max(0, (highlightInterval.start - startTime) / duration * _width);
                            var widthDimension:Number = Math.min(_width, (highlightInterval.end - startTime) / duration * _width) - xDimension;
                            var dimensions:Rectangle = new Rectangle(xDimension, (i) * highlightLineThickness,
                                    widthDimension, highlightLineThickness);

                            var highlight:FilmstripHighlight = new FilmstripHighlight(timeRange, dimensions, colour);
                            highlight.x = dimensions.x;
                            highlight.y = dimensions.y;
                            highlight.clickSignal.add(
                                    function highlightClicked(timeRange:Range, colour:uint):void {
                                        playHighlightClicked.dispatch(timeRange);
                                    });
                            highlight.actionLogSignal.add(
                                    function bubbleActionLog(message:String):void {
                                        actionLogSignal.dispatch(message);
                                    });

                            highlightSprite.addChild(highlight);

                        }

                    }
                    i++;
                }
            }
		}

		private function drawGlobalHighlights(highlightSprite:Canvas, highlightHeatmap:Array):void {
            var maxViewCount:Number = 1;
            var highlightsHeight:Number = 8;

			var i:int;

            for(i = 0; i<highlightHeatmap.length; i++) {
                maxViewCount = Math.max(maxViewCount, highlightHeatmap[i]);
            }


            highlightSprite.clear();
            highlightSprite.beginFill(0x222222, 0.8);
            highlightSprite.drawRectangle(0, 0, _width, highlightsHeight);
            highlightSprite.endFill();
            for(i = 0; i<highlightHeatmap.length; i++) {
                var transparency:Number = highlightHeatmap[i]/maxViewCount == 0 ? 0 : (highlightHeatmap[i]/maxViewCount) * 0.7 + 0.3;
                highlightSprite.beginFill(0x00cc00, transparency);
                highlightSprite.drawRectangle((i - uint(startTime))/(uint(endTime+1) - uint(startTime)) * _width, 0,
                        (1 - uint(startTime))/(uint(endTime+1) - uint(startTime)) * _width, highlightsHeight);
                highlightSprite.endFill();
            }
			// TODO
//            highlightSprite.graphics.lineStyle(0, 0xcccccc);
//            highlightSprite.graphics.moveTo(0, highlightsHeight);
//            highlightSprite.graphics.lineTo(_width, highlightsHeight);

        }

		override public function setViewCountRecordReadMode(mode:uint):void {
            viewCountRecordReadMode = mode;
            if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
                if(viewCountRecordSprite && contains(viewCountRecordSprite)) {
                    removeChild(viewCountRecordSprite);
                }
                if(globalViewCountRecordSprite && contains(globalViewCountRecordSprite)) {
                    removeChild(globalViewCountRecordSprite);
                }
            } else {
                if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
                    if(viewCountRecordSprite && !contains(viewCountRecordSprite))
                        addChild(viewCountRecordSprite)
                } else {
                    if(viewCountRecordSprite && contains(viewCountRecordSprite))
                        removeChild(viewCountRecordSprite);
                }

                if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
                    if(globalViewCountRecordSprite && !contains(globalViewCountRecordSprite))
                        addChild(globalViewCountRecordSprite);
					drawViewCountRecord(globalViewCountRecordSprite, _video.crowdUserViewCounts, [0x00cc00, 0x008800], [1, 1], [0, 255]);
                } else {
                    if(globalViewCountRecordSprite && contains(globalViewCountRecordSprite))
                        removeChild(globalViewCountRecordSprite);
                }
            }
		}

		override public function setHighlightReadMode(mode:uint):void {
			highlightReadMode = mode;
			if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
				if(highlightSprite && contains(highlightSprite)) 
					removeChild(highlightSprite);
                if(globalHighlightsSprite && contains(globalHighlightsSprite)) {
                    removeChild(globalHighlightsSprite);
                }
                if(instructorHighlightSprite && contains(instructorHighlightSprite)) {
                    removeChild(instructorHighlightSprite);
                }
			} else {
				if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
					if(highlightSprite && !contains(highlightSprite)) 
						addChild(highlightSprite)
				} else {
					if(highlightSprite && contains(highlightSprite))
						removeChild(highlightSprite);
				}

				if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
                    if(globalHighlightsSprite && !contains(globalHighlightsSprite)) {
                        addChild(globalHighlightsSprite)
                    }
					drawGlobalHighlights(globalHighlightsSprite, _video.crowdHighlights);
                } else {
                    if(globalHighlightsSprite && contains(globalHighlightsSprite)) {
                        removeChild(globalHighlightsSprite);
                    }
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

		override public function updateHighlights():void {
			if(_video) {
                if ((highlightReadMode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {

                } else {
                    if ((highlightReadMode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
                        drawHighlights(highlightSprite, _video.userData.highlights);
                    }

                    if ((highlightReadMode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {

                    }

                    if ((highlightReadMode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
                        var instructorHighlights:Vector.<UserData> = _video.crowdUserData.grab(UserData.INSTRUCTOR);
                        if (instructorHighlights && instructorHighlights.length > 0) {
                            drawHighlights(instructorHighlightSprite, instructorHighlights[0].highlights);
                        }
                    }
                }
            }
		}

		private function drawTimeTicks():void {
			if(stage) {

                var timeTicksVector:Shape = new Shape();
                timeTicksVector.graphics.clear();
                timeTicksVector.graphics.lineStyle(1, 0xcccccc);

                var totalTime:Number = (uint(endTime+1) - uint(startTime));

                var shortTickLength:Number = 4;
                var longTickLength:Number = 9;

                var numTicks:int = Math.min(_width/10, totalTime);

                for(var i:int = uint(startTime); i<uint(endTime+1); i+=Math.round(totalTime/numTicks)) {
                    var x_:Number = (i - uint(startTime))/(uint(endTime+1) - uint(startTime)) * _width;
                    var tickHeight:Number = (i%30 == 0) ? longTickLength : shortTickLength;

                    timeTicksVector.graphics.moveTo(x_, longTickLength);
                    timeTicksVector.graphics.lineTo(x_, longTickLength - tickHeight);
                }

                var timeTicksBmpD:BitmapData = new BitmapData(timeTicksVector.width, timeTicksVector.height, true, 0x000000);
                timeTicksBmpD.draw(timeTicksVector);

                timeTicks.readjustSize(timeTicksBmpD.width, timeTicksBmpD.height);
                timeTicks.texture = Texture.fromBitmapData(timeTicksBmpD, false, false, 1, "bgra", false, function(texture:Texture, error:ErrorEvent):void { });

                timeTicks.y = _height - timeTicks.height;

//                var totalTime:Number = uint(endTime) - uint(startTime) + 1;
//
//                var numTicks:int = Math.min(_width / 10, totalTime);
//                var quad:Quad;
//
//
//                var i:int, j:int = 0;
//                for (i = uint(startTime); i < uint(endTime); i += int(totalTime / numTicks)) {
//                    var x_:int = (i - uint(startTime)) / totalTime * _width;
//
//                    var tickHeight:Number = (i % 30 == 0) ? 9 : 4;
//
//					if(j + 1 > timeTicks.numChildren) {
//                        quad = new Quad(2, tickHeight, 0xcccccc);
//                        quad.touchable = false;
//                        timeTicks.addChild(quad);
//					}
//
//                    quad = (Quad)(timeTicks.getChildAt(j++));
//                    if(quad.height != tickHeight) {
//                        quad.height = tickHeight;
//                    }
//                    quad.x = x_;
//                    quad.y = _height - tickHeight;
//                    quad.alpha = 1;
//                }
//
//                for (i = j; i < timeTicks.numChildren; i++) {
//                    quad = (Quad)(timeTicks.getChildAt(i));
//
//                    if (quad.alpha != 0) {
//                        quad.alpha = 0;
//                    }
//                }

                var tickText:FloatingTextField;
                var textFormat:TextFormat = new TextFormat("Arial", 10, 0xFFFFE8);
                for (i = 1; i <= 2; i++) {

                    if(i > timeTexts.numChildren) {

                        tickText = new FloatingTextField(timeInSecondsToTimeString(getTimeFromXCoordinate(_width * (i / 3))), textFormat);
                        tickText.touchable = false;
                        timeTexts.addChild(tickText);

                    } else {

                        tickText = (FloatingTextField)(timeTexts.getChildAt(i - 1));
                        tickText.text = timeInSecondsToTimeString(getTimeFromXCoordinate(_width * (i / 3)));

                    }

                    tickText.x = _width * (i / 3) - tickText.width / 2;
                    tickText.y = _height - tickText.height - 10;

                }
            }
		}

		override protected function reorderSpriteIndex():void {
			super.reorderSpriteIndex();

			bringChildToFront(viewCountRecordSprite);
			bringChildToFront(highlightSprite);
			bringChildToFront(instructorHighlightSprite);
			bringChildToFront(selectionHighlightSprite);
			bringChildToFront(timeTicks);
            bringChildToFront(timeTexts);
			bringChildToFront(playhead);
		}

		override public function setSize(width:Number, height:Number):void {
			super.setSize(width, height);

			if(playhead) {
				playhead.readjustSize(2, _height);
			}

			if(cursor) {
				cursor.readjustSize(2, _height);
			}

			if(previewText) {
                previewText.y = _height/2 - previewText.height/2;
			}


            drawTimeTicks();
            drawViewCountRecord(viewCountRecordSprite, _video.userData.viewCountRecord);
            drawViewCountRecord(globalViewCountRecordSprite, _video.crowdUserViewCounts);
//			timeTicks.clear();

//			trace("filmstrip.setSize(" + width + ", " + height + ")");

			if(stage && _video && !_resizing) {


				if(!redrawAfterResizeTimer) {
					redrawAfterResizeTimer = new Timer(500);
				}
                redrawAfterResizeTimer.addEventListener(TimerEvent.TIMER, redrawAfterResizeDelayed);
                redrawAfterResizeTimer.reset();
                redrawAfterResizeTimer.start();
            }
		}

		private function redrawAfterResizeDelayed(e:TimerEvent):void {
            updateHighlights();


            reorderSpriteIndex();
//            viewCountRecordSprite.y = _height - VIEW_COUNT_RECORD_HEIGHT;


			redrawAfterResizeTimer.stop();
            redrawAfterResizeTimer.removeEventListener(TimerEvent.TIMER, redrawAfterResizeDelayed);
			redrawAfterResizeTimer = null;
		}

	}
}