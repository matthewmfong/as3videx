////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.filmstrip {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.AnnotationCalloutFlash;
import ca.ubc.ece.hct.myview.Colours;
import ca.ubc.ece.hct.myview.AnnotationCallout;
import ca.ubc.ece.hct.myview.AnnotationCallout;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.common.Annotation;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.StarlingWidget;
import ca.ubc.ece.hct.myview.widgets.Widget;

import flash.text.TextField;

import flash.text.TextFormat;

import starling.core.Starling;

//import com.greensock.TweenLite;

import feathers.controls.Button;
import feathers.controls.Callout;
import feathers.layout.RelativePosition;

import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.utils.Timer;

import mx.effects.Tween;

import org.osflash.signals.Signal;

import starling.display.DisplayObject;

import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.events.TouchProcessor;

public class MultiFilmstrip extends StarlingWidget {

		public static const GAP:uint = 3; // gap between filmstrips
		public static const FILMSTRIP_MINIMUM_HEIGHT:uint = 75;
		private var filmstrips:Vector.<Filmstrip>;
		private var selectionRange:Range;
		
		private var mouseDownTime:Number; // keep track of the timestamp we started our selection.
		private var highlightsShowing:Boolean = true;
		private var vcrShowing:Boolean;

		// when the video is paused, the playhead will not change when the height is changed. set height will use this when that happens.
		private var lastSetPlayheadTime:Number; 

		private var resizingStatus:Boolean = false;

		private var showViewCount:Boolean = true;
		private var showGlobalViewCount:Boolean = false;
		private var showHighlights:Boolean = true;
		private var showGlobalHighlights:Boolean = false;

		private var highlightCallout:Callout;

		public static const padding:Number = 0;
		private var containerWidth:Number;
		private var containerHeight:Number;

		public var seekSignal:Signal;
		public var playRangeSignal:Signal;
		public var actionLogSignal:Signal;

		public function MultiFilmstrip() {
			super();
			actionLogSignal = new Signal(String);

			containerWidth = _width - padding*2;
			containerHeight =  _height - padding*2;
			filmstrips = new Vector.<Filmstrip>();
			selectionRange = new Range(0, 0);
			graphics.clear();
			graphics.beginFill(0);
			graphics.drawRectangle(0, 0, _width, _height);
			graphics.endFill();

			seekSignal = new Signal(Number, Number); // oldTime, newTime;
			playRangeSignal = new Signal(Range);
		}

		private function bubbleActionLog(message:String):void {
			actionLogSignal.dispatch(message);
		}

		override public function dispose():void {
			super.dispose();
			for each(var fs:Filmstrip in filmstrips) {
				removeChild(fs);
				fs.dispose();
				fs = null;
			}

			filmstrips = null;
			selectionRange = null;

			seekSignal = null;
			playRangeSignal = null;
			actionLogSignal = null

			_video = null;

		}

		override public function loadVideo(val:VideoMetadata):void {
			_video = val;

			for each(var filmstrip:Filmstrip in filmstrips) {
//				filmstrip.destroy();
				removeChild(filmstrip);
				filmstrip = null;
			}

            if(stage) {
                addedToStage();
            } else {
                addEventListener(Event.ADDED_TO_STAGE, addedToStage);
            }

		}

		override protected function addedToStage(e:Event = null):void {
			super.addedToStage(e);

            filmstrips = new Vector.<Filmstrip>();
            createOptimalNumberOfFilmstrips();
            addEventListener(TouchEvent.TOUCH, touched);

		}

		public function showImages():void {
			for each(var filmstrip:Filmstrip in filmstrips) {
				filmstrip.showImages();
			}
		}

		public function hideImages():void {
            for each(var filmstrip:Filmstrip in filmstrips) {
                filmstrip.hideImages();
            }
		}

		private function createOptimalNumberOfFilmstrips():void {
			if(_video) {

                var numFilmstrips:uint = Math.max(1, containerHeight / FILMSTRIP_MINIMUM_HEIGHT);

                var filmstripHeight:Number = containerHeight/numFilmstrips - (numFilmstrips - 1) * GAP/numFilmstrips;

                var intervalLength:Number = 1 / numFilmstrips;
                var startTime:Number, endTime:Number;
				var filmstripTweenTime:Number = 0.2;

				// not enough filmstrips
                if (filmstrips.length < numFilmstrips) {

                    for (var i:int = 0; i < filmstrips.length; i++) {
                        startTime = i * intervalLength;
                        endTime = i * intervalLength + intervalLength;

						filmstrips[i].resizing = _resizing;
                        filmstrips[i].setInterval(new Range(startTime, endTime));
                        filmstrips[i].setSize(containerWidth, filmstripHeight);
                        filmstrips[i].y = padding + (i) * (filmstripHeight + GAP);
                        filmstrips[i].x = 0;
//						TweenLite.to(filmstrips[i], filmstripTweenTime, {height: filmstripHeight, x: 0, y: padding + (i) * (filmstripHeight + GAP)});
                        // filmstrips[i].showGlobalViewCount(showGlobalViewCount);
                        // filmstrips[i].showGlobalHighlights(showGlobalHighlights);
                    }

                    var filmstrip:Filmstrip;

                    for (i = filmstrips.length; i < numFilmstrips; i++) {

                        startTime = i * intervalLength;
                        endTime = i * intervalLength + intervalLength;

                        filmstrip = new Filmstrip();
                        filmstrip.loadVideo(_video);
						filmstrip.setInterval(new Range(startTime, endTime));
						filmstrip.setSize(containerWidth, filmstripHeight);
                        filmstrip.y = padding + (i) * (filmstripHeight + GAP);
                        filmstrip.resizing = _resizing;
                        filmstrips.push(filmstrip);

                        addChild(filmstrip);
                        filmstrip.setHighlightReadMode(highlightReadMode);
//						filmstrip.addEventListener(TouchEvent.TOUCH, touched);
                        filmstrip.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);

                        filmstrip.clicked.add(filmstripSeek);
                        filmstrip.playHighlightClicked.add(playRange);
                        filmstrip.doubleClicked.add(doubleClick);
                        filmstrip.selected.add(
                                function selectViaVCR(timeRange:Range):void {
                                    selected.dispatch(this, selectionRange);
                                });
                        filmstrip.actionLogSignal.add(bubbleActionLog);
                    }

                } else if (filmstrips.length > numFilmstrips) {
                    while (filmstrips.length != numFilmstrips) {
                        removeChild(filmstrips.pop());
                    }

                    for (i = 0; i < filmstrips.length; i++) {
                        startTime = i * intervalLength;
                        endTime = i * intervalLength + intervalLength;
                        filmstrips[i].resizing = _resizing;
                        filmstrips[i].setInterval(new Range(startTime, endTime));
                        filmstrips[i].setSize(containerWidth, filmstripHeight);
						filmstrips[i].y = padding + (i) * (filmstripHeight + GAP);
                        filmstrips[i].x = 0;
//                        TweenLite.to(filmstrips[i], filmstripTweenTime, {x: 0, y: padding + (i) * (filmstripHeight + GAP)});

                    }
                } else {
                    for (i = 0; i < filmstrips.length; i++) {
                        filmstrips[i].resizing = _resizing;
                        filmstrips[i].setSize(containerWidth, filmstripHeight);
                        filmstrips[i].y = padding + (i) * (filmstripHeight + GAP);
						filmstrips[i].x = 0;
//                        TweenLite.to(filmstrips[i], filmstripTweenTime, {x: 0, y: padding + (i) * (filmstripHeight + GAP)});
                    }
                }

                updateHighlights();
            }
		}

		private function playRange(timeRange:Range):void {
			playRangeSignal.dispatch(timeRange);
		}

		private function filmstripSeek(time:Number):void {
			playheadTime = time;
			stoppedPlayingHighlights.dispatch(this);
			seeked.dispatch(this, time);
			// setPlayhead(newTime)
		}

		override public function receiveSeek(time:Number):void {
             playheadTime = time;
		}

		override public function set playheadTime(time:Number):void {
			for(var i:int = 0; i<filmstrips.length; i++) {
				filmstrips[i].playheadTime = time;
			}
			lastSetPlayheadTime = time;
		}

		override public function select(interval:Range):void {

			for(var i:int = 0; i<filmstrips.length; i++) {
				if(filmstrips[i].startTime <= interval.end && filmstrips[i].endTime >= interval.start) {
					filmstrips[i].select(interval);
				} else {
					filmstrips[i].deselect();
				}
			}
			selectionRange = interval;
		}

		override public function deselect():void {
			for each(var filmstrip:Filmstrip in filmstrips) {
				filmstrip.deselect();
			}
			selectionRange = new Range(0, 0);
		}

		override public function updateHighlights():void {

			for(var i:int = 0; i<filmstrips.length; i++) {
				filmstrips[i].updateHighlights();
			}
		}

		override public function setHighlightReadMode(mode:uint):void {
			highlightReadMode = mode;
			for each(var filmstrip:Filmstrip in filmstrips) {	
				filmstrip.setHighlightReadMode(mode);
			}
		}

		override public function setViewCountRecordReadMode(mode:uint):void {
			// showHighlights = val;
			// showGlobalHighlights = !val;
			for each(var filmstrip:Filmstrip in filmstrips) {	
				filmstrip.setViewCountRecordReadMode(mode);
			}
		}


		private function doubleClick(oldTime:Number, newTime:Number):void {
			var range:Range = new Range(Math.max(0, newTime - 10), newTime);

			select(range);
			selected.dispatch(this, range);
			// dispatchEvent(new HighlightEvent(HighlightEvent.SELECT, range.start, range.end));
		}

//		public override function hitTest(localPoint:Point):DisplayObject
//		{
//			var target:DisplayObject = super.hitTest(localPoint);
//            trace("target = " + target);
//			while(!(target is Filmstrip) && (!target is MultiFilmstrip)) {
//				target = target.parent;
//
//			}
//			return (target is MultiFilmstrip ? null : target);
//		}

		protected function touched(e:TouchEvent):void {
			var touch:Touch = e.getTouch(this);

			var filmstrip:Filmstrip;// = (Filmstrip)(e.currentTarget);

			for each(var fs:Filmstrip in filmstrips) {
				if(touch && touch.isTouching(fs)) {
					filmstrip = fs;
				}
			}

			if(touch && filmstrip) {

//				var filmstrip:Filmstrip = (Filmstrip)(e.currentTarget);
//                trace(touch.phase + " " + touch.getLocation(this));
//				if(e.currentTarget)
//				trace((Filmstrip)(e.currentTarget).startTime + " " + (Filmstrip)(e.currentTarget).endTime)
//				trace("FS: " + filmstrip.startTime + " " + filmstrip.endTime);

				var mouseTime:Number;
				var mouseBeginTime:Number;
				var start:Number, end:Number;

				switch(touch.phase) {
					case TouchPhase.HOVER:
						break;
					case TouchPhase.BEGAN:
                        TouchProcessor.PROCESS_TARGETS_WHILE_MOVING = true;
//                        if(e.currentTarget is Filmstrip) {
                            mouseDownTime = filmstrip.getTimeFromXCoordinate(touch.getLocation(this).x);

                            for(var i:int = 0; i<filmstrips.length; i++) {
                                filmstrips[i].addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
                                filmstrips[i].addEventListener(MouseEvent.MOUSE_UP, mouseUp);
                            }
                            selectionRange = new Range(mouseDownTime, mouseDownTime);
//                        }
						break;
					case TouchPhase.MOVED:
						mouseTime = filmstrip.getTimeFromXCoordinate(touch.getLocation(this).x);
						mouseBeginTime = mouseDownTime;

						start = (mouseTime < mouseBeginTime) ? mouseTime : mouseBeginTime;
						end = (mouseTime < mouseBeginTime) ? mouseBeginTime : mouseTime;

                        selectionRange = new Range(start, end);
                        select(selectionRange);
                        selecting.dispatch(this, selectionRange);
						break;
					case TouchPhase.ENDED:

                        mouseTime = filmstrip.getTimeFromXCoordinate(touch.getLocation(this).x);
                        mouseBeginTime = mouseDownTime;

						start = (mouseTime < mouseBeginTime) ? mouseTime : mouseBeginTime;
						end = (mouseTime < mouseBeginTime) ? mouseBeginTime : mouseTime;
                        if(start != end) {
                            actionLogSignal.dispatch("2D Filmstrip: Selected [" + Util.roundNumber(start, 2) + ", " + Util.roundNumber(end, 2) + "]");

                            selectionRange = new Range(start, end);
                            select(selectionRange);
                            selected.dispatch(this, selectionRange);
                            TouchProcessor.PROCESS_TARGETS_WHILE_MOVING = false;

//							AnnotationCalloutFlash.showCallout(
//									new Point(touch.globalX, touch.globalY),
//									this,
//									Starling.current.nativeOverlay,
//									null,
//									selectionRange).
//							annotateSignal.add(annotate);

                            highlightCallout = AnnotationCallout.showCallout(
                                    filmstrip.selectionHighlightSprite,
                                    Colours.colours,
                                    _video.userData.getHighlightedColoursforTimeRange(selectionRange),
								    this);
							(AnnotationCallout)(highlightCallout.content).highlightSignal.add(
                                    function highlightme(colour:uint, mode:String):void {
										if(mode == AnnotationCallout.ADD_HIGHLIGHT_MODE) {
                                            highlighted.dispatch(AnnotationCallout.caller, colour, selectionRange);
											highlightCallout.close(true);
                                        } else if(mode == AnnotationCallout.DEL_HIGHLIGHT_MODE) {
											unhighlighted.dispatch(AnnotationCallout.caller, colour, selectionRange);
										}
                                    });
							highlightCallout.addEventListener(Event.CLOSE,
									function calloutClosed(e:Event):void {
										deselect();
										deselected.dispatch(AnnotationCallout.caller);
                                        highlightCallout.removeEventListener(Event.CLOSE, calloutClosed);
									}
							);
                        }

						break;
				}
			}

		}

		override public function annotate(annotation:Annotation):void {
			annotated.dispatch(this, annotation);
		}


		protected function mouseDown(e:MouseEvent):void {
			if(e.currentTarget is Filmstrip) {
				mouseDownTime = e.currentTarget.getTimeFromXCoordinate(e.currentTarget.mouseX);

				for(var i:int = 0; i<filmstrips.length; i++) {
					filmstrips[i].addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
					filmstrips[i].addEventListener(MouseEvent.MOUSE_UP, mouseUp);
				}
				selectionRange = new Range(mouseDownTime, mouseDownTime);
			}
		}

		protected function mouseMove(e:MouseEvent):void {

			var mouseTime:Number = e.currentTarget.getTimeFromXCoordinate(e.currentTarget.mouseX);
			var mouseBeginTime:Number = mouseDownTime;

			var start:Number = (mouseTime < mouseBeginTime) ? mouseTime : mouseBeginTime;
			var end:Number = (mouseTime < mouseBeginTime) ? mouseBeginTime : mouseTime;
			
			selectionRange = new Range(start, end);
		 	select(selectionRange);
		 	selecting.dispatch(this, selectionRange);

//			for(var i:int = 0; i<filmstrips.length; i++) {
//				filmstrips[i].disableClick();
//			}

		}

		public function mouseUp(e:MouseEvent):void {

			var mouseTime:Number = e.currentTarget.getTimeFromXCoordinate(e.currentTarget.mouseX);
			var mouseBeginTime:Number = mouseDownTime;

			var start:Number = (mouseTime < mouseBeginTime) ? mouseTime : mouseBeginTime;
			var end:Number = (mouseTime < mouseBeginTime) ? mouseBeginTime : mouseTime;
			if(start != end)
				actionLogSignal.dispatch("2D Filmstrip: Selected [" + Util.roundNumber(start, 2) + ", " + Util.roundNumber(end, 2) + "]");
			
			selectionRange = new Range(start, end);
			select(selectionRange);
			selected.dispatch(this, selectionRange);

			for(var i:int = 0; i<filmstrips.length; i++) {
				filmstrips[i].removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				filmstrips[i].removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			}

			var timer:Timer = new Timer(1000);
			timer.addEventListener(TimerEvent.TIMER,
				function enableClickFilmstrip(e:TimerEvent):void {
//					for(var i:int = 0; i<filmstrips.length; i++) {
//						filmstrips[i].enableClick();
//					}
					timer.stop();
				});
			timer.start();
		}

//		public function getNumThumbnailsPerFilmstrip():Number {
//			if(filmstrips.length > 0) {
//				return filmstrips[0].getNumThumbnails();
//			} else {
//				return 0;
//			}
//		}

		public function setResizingStatus(val:Boolean):void {
			resizingStatus = val;
//			for each(var filmstrip:Filmstrip in filmstrips) {
//				filmstrip.setResizingStatus(val);
//			}

			if(resizingStatus == false) {
				actionLogSignal.dispatch("2D Filmstrip: Created " + filmstrips.length + " filmstrips");
			}
		}

		override public function setSize(width:Number, height:Number):void {
			_width = width;
			_height = height;

			graphics.clear();
			graphics.beginFill(0);
			graphics.drawRectangle(0, 0, _width, _height);
			graphics.endFill();

			containerWidth = _width - padding*2;
			containerHeight =  _height - padding*2;

//			for(var i:int = 0; i<filmstrips.length; i++) {
//				filmstrips[i].width = containerWidth;
//			}

			playheadTime = (lastSetPlayheadTime);
			select(selectionRange);
			if(stage) {
                createOptimalNumberOfFilmstrips();
//                updateHighlights();
            }
		}

		override public function set resizing(val:Boolean):void {
			_resizing = val;

			for each(var filmstrip:Filmstrip in filmstrips) {
				filmstrip.resizing = val;
			}

			if(!_resizing) {
				setSize(_width, _height);
			}
		}
	}
}