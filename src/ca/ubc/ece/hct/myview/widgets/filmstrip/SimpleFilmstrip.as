////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.filmstrip {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.thumbnail.ThumbnailSegment;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.StarlingWidget;

import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.utils.Timer;
import flash.utils.getTimer;

import org.osflash.signals.Signal;

import starling.display.Canvas;
import starling.display.Quad;
import starling.display.Shape;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;


public class SimpleFilmstrip extends StarlingWidget {

		public static const GAP:uint = 2; // gap between thumbnails
		public static const playheadLineThickness:uint = 2;

//		protected var maskingSprite:Canvas;
		protected var thumbnails:Vector.<ThumbnailSegment>;
		protected var _thumbnailContainer:Sprite;
		protected var numThumbnailsLoaded:int = 0;
		protected var interval:Range;
		protected var currentTime:Number = 0;

		protected var logTimer:Timer;

		public var mouseMoved:Signal;
		public var clicked:Signal;
		public var doubleClicked:Signal
		public var loaded:Signal;
		public var filmstripClosed:Signal;
		public var actionLogSignal:Signal;

		private var _background:Quad;
		private var _resizingOverlay:Quad;

		public function SimpleFilmstrip() {
			super();
            numThumbnailsLoaded = 0;

			actionLogSignal = new Signal(String);

			selected		= new Signal(Range);
			clicked 		= new Signal(Number); // newTime
			doubleClicked	= new Signal(Number, Number); // oldTime, newTime
			loaded 			= new Signal();
			mouseMoved 		= new Signal(Number);
			filmstripClosed = new Signal();

            thumbnails = new Vector.<ThumbnailSegment>();
			interval = new Range(0, 1);
			_background = new Quad(_width, _height, 0x000000);
			_background.touchable = false;
            _resizingOverlay = new Quad(_width, _height, 0x666666);
			_resizingOverlay.touchable = false;
			_thumbnailContainer = new Sprite();
		}

		override public function loadVideo(video:VideoMetadata):void {
			_video = video;
			if(_resizing) {
                showImages();
            }
		}

		override public function dispose():void {
			super.dispose();
			if(_background) {
				if(contains(_background)) {
                    removeChild(_background);
                }
                _background.dispose();
            }
            _background = null;

			if(_resizingOverlay) {
                if (contains(_resizingOverlay)) {
                    removeChild(_resizingOverlay);
                }
                _resizingOverlay.dispose();
            }
			_resizingOverlay = null;

			if(thumbnails) {
                for each(var thumb:ThumbnailSegment in thumbnails) {
                    _thumbnailContainer.removeChild(thumb);
                    thumb.dispose();
                    thumb = null;
                }
            }
            thumbnails = null;

			if(_thumbnailContainer) {
				if(contains(_thumbnailContainer)) {
                    removeChild(_thumbnailContainer);
                }

				_thumbnailContainer.dispose();
            }
			_thumbnailContainer = null;

		}

		override public function set width(val:Number):void {
			setSize(val, _height);
		}

		override public function set height(val:Number):void {
			setSize(_width, val);
		}

		override public function setSize(width:Number, height:Number):void {
			_width = width;
			_height = height;


			_background.readjustSize(_width, _height);
			_resizingOverlay.readjustSize(_width, _height);

			if(stage){
				drawThumbnailMask();
                createOptimalNumberOfThumbnails();
			}
		}

		override public function setInterval(interval:Range):void {
			this.interval = interval;

			var length:Number = interval.length/thumbnails.length;
			for(var i:int = 0; i<thumbnails.length; i++) {

				var range:Range = new Range(i*length, (i+1)*length);
				thumbnails[i].setInterval(range);

			}
		}

		public function showImages():void {
			if(_video) {
                for each(var thumbnail:ThumbnailSegment in thumbnails) {
                    thumbnail.loadVideo(_video);
                    thumbnail.showImage();
                }
            }

			if(_thumbnailContainer.contains(_resizingOverlay)) {
                _thumbnailContainer.removeChild(_resizingOverlay);
			}
		}

		public function hideImages():void {
			for each(var thumbnail:ThumbnailSegment in thumbnails) {
				thumbnail.hideImage();
			}

			_thumbnailContainer.addChild(_resizingOverlay);
		}

		override protected function addedToStage(e:Event = null):void {
			super.addedToStage(e);

			createOptimalNumberOfThumbnails();

			addEventListener(TouchEvent.TOUCH, touched);
//            addEventListener(MouseEvent.ROLL_OVER, filmstripMouseOver);
//            addEventListener(MouseEvent.ROLL_OUT, filmstripMouseOut);
//			thumbnailContainer.addEventListener(MouseEvent.CLICK, filmstripMouseClick);

			addChild(_background);
			addChild(_thumbnailContainer);


            reorderSpriteIndex();
		}

		protected var touch:Touch;
		protected var movedSinceMouseDown:Boolean;
//		protected var clickTimer:Timer;
//		protected var numClicks:Number;
		protected function touched(e:TouchEvent):void {
			touch = e.getTouch(_thumbnailContainer);

			if(touch) {
                switch (touch.phase) {
                    case TouchPhase.HOVER:
                        break;
                    case TouchPhase.BEGAN:
							movedSinceMouseDown = false;
                        break;
					case TouchPhase.MOVED:
							movedSinceMouseDown = true;
						break;
                    case TouchPhase.ENDED:
//                        if (clickTimer == null) {
//                            clickTimer = new Timer(150);
//                            clickTimer.addEventListener(TimerEvent.TIMER,
//                                    function singleClickTimer(e:TimerEvent):void {
							if(!movedSinceMouseDown)
                                        singleClick(touch);
//                                    });
//                            numClicks = 0;
//                        }
//                        clickTimer.start();
//                        numClicks++;
//                        if (numClicks == 2) {
//                            doubleClick(touch);
//                        }
                        break;
                }
            }
		}

		protected function filmstripMouseOver(e:MouseEvent):void {
			addEventListener(MouseEvent.MOUSE_MOVE, filmstripMouseMove);
			logTimer.start();
		}

		protected function filmstripMouseMove(e:MouseEvent):void {
//			var previewTextYMin:uint = 5;
//			setSeekLinePosition(e.currentTarget.mouseX);
//
//			if(contains(seekLine))
//				setChildIndex(seekLine, numChildren - 1);
//			if(contains(previewText))
//				setChildIndex(previewText, numChildren - 1);
//
//			mouseMoved.dispatch(getTimeFromXCoordinate(e.currentTarget.mouseX))
		}

		protected function filmstripMouseOut(e:MouseEvent):void {
//			removeEventListener(MouseEvent.MOUSE_MOVE, filmstripMouseMove);
//			if(enableSeekLineBool) {
//				removeChild(seekLine);
//				removeChild(previewText);
//			}
//			logTimer.stop();
		}

//		protected function filmstripMouseClick(e:MouseEvent):void {
//			if(clickTimer == null) {
//				clickTimer = new Timer(150);
//				clickTimer.addEventListener(TimerEvent.TIMER,
//					function singleClickTimer(e:TimerEvent):void {
//						singleClick(clickTarget);
//					});
//				numClicks = 0;
//			}
//			clickTimer.start();
//			clickTarget = (Sprite)(e.currentTarget);
//			numClicks++;
//			if(numClicks == 2) {
//				doubleClick(clickTarget);
//			}
//		}

		protected function singleClick(t:Touch):void {
			var newTime:Number 		= getTimeFromXCoordinate(t.getLocation(this).x);
//			numClicks = 0;
//			clickTimer.reset();
//			clickTimer = null;
			clicked.dispatch(newTime);
			actionLogSignal.dispatch("Filmstrip: Single Click at " + newTime);
		}

		protected function doubleClick(t:Touch):void {
//            var newTime:Number 		= getTimeFromXCoordinate(t.getLocation(this).x);
//			numClicks = 0;
//			clickTimer.reset();
//			clickTimer = null;
//			doubleClicked.dispatch(newTime);
//			actionLogSignal.dispatch("Filmstrip: Double Click at " + newTime);
		}

		protected function createOptimalNumberOfThumbnails():void {

			var numThumbnails:uint = 1;

			for (var i:int = 1; i < 500; i++) {
				var thumbnailNewWidth:Number = _width / i;

				var aspectRatio:Number = _video ? _video.aspectRatio : 4 / 3;

				var thumbnailNewHeight:Number = thumbnailNewWidth / aspectRatio;

				if (thumbnailNewHeight < _height) {
					break;
				}
				numThumbnails = i;
			}

            if(stage) {
//                trace(numThumbnails + " numThumbnails")
//                trace(new Error().getStackTrace())
                createThumbnails(numThumbnails);
            }
		}

		protected function createThumbnails(numThumbnails:uint):void {

//			trace("_WIDTH = " + _width);
//			trace("NUM THUMBNAILS = " + numThumbnails);

			var thumbnailIntervalLength:Number = interval.length/numThumbnails;
			var thumbnailInterval:Range;

			var thumbnailWidth:Number = _width/numThumbnails - (numThumbnails - 1) * GAP/numThumbnails;

			if(thumbnails.length < numThumbnails) {
				// not enough thumbnails

				for(var i:int = 0; i<thumbnails.length; i++) {

					thumbnailInterval = new Range(i * thumbnailIntervalLength + interval.start,
							                      (i+1) * thumbnailIntervalLength + interval.start);

					if(_video) {
                        thumbnails[i].loadVideo(_video);
                    }
					thumbnails[i].setInterval(thumbnailInterval);
					thumbnails[i].setSize(thumbnailWidth, _height);
					thumbnails[i].x = i * (thumbnailWidth + GAP);
				}

				for(i = thumbnails.length; i<numThumbnails; i++) {

                    thumbnailInterval = new Range(i * thumbnailIntervalLength + interval.start,
                                                  (i+1) * thumbnailIntervalLength + interval.start);

					var thumbnail:ThumbnailSegment = new ThumbnailSegment();
					if(_video) {
						thumbnail.loadVideo(_video);
					}
					thumbnail.setSize(thumbnailWidth, _height);
					thumbnail.setInterval(thumbnailInterval);

					thumbnail.x = i * (thumbnailWidth + GAP);

					thumbnails.push(thumbnail);
					_thumbnailContainer.addChild(thumbnail);
//					thumbnailContainer.setChildIndex(thumbnail, 0);
				}
				loaded.dispatch();

			
			} else if (thumbnails.length > numThumbnails) {
				// too many thumbnails

				while(thumbnails.length > numThumbnails) {
					_thumbnailContainer.removeChild(thumbnails.pop());
					numThumbnailsLoaded--;
				}

				for(i = 0; i<thumbnails.length; i++) {

					thumbnailInterval = new Range(i	* thumbnailIntervalLength + interval.start,
										          (i+1) * thumbnailIntervalLength + interval.start);

					if(_video) {
                        thumbnails[i].loadVideo(_video);
                    }
					thumbnails[i].setInterval(thumbnailInterval);
					thumbnails[i].setSize(thumbnailWidth, _height);
					thumbnails[i].x = i * (thumbnailWidth + GAP);
					loaded.dispatch();
				}

			
			} else {
				// number of thumbnails is correct

				for(i = 0; i<thumbnails.length; i++) {
					if(_video) {
						thumbnails[i].loadVideo(_video);
					}
					thumbnails[i].setSize(thumbnailWidth, _height);
					thumbnails[i].x = i*(thumbnailWidth + GAP);
					loaded.dispatch();
				}
			}

			reorderSpriteIndex();
		}

//		public function retract():void {
//			for(var i:int = 0; i<thumbnails.length; i++) {
//				TweenLite.to(thumbnails[i], 0.25,
//					        {x: 0,
//					      ease: Power2.easeOut,
//				    onComplete: retracted});
//			}
//		}
//
//		protected function retracted():void {
//			filmstripClosed.dispatch();
//		}

		protected function reorderSpriteIndex():void {
//			bringChildToFront(thumbnailContainer);
//			bringChildToFront(playhead);
//			bringChildToFront(seekLine);
//			bringChildToFront(previewText);
			if(_thumbnailContainer.contains(_resizingOverlay)) {
                _thumbnailContainer.setChildIndex(_resizingOverlay, _thumbnailContainer.numChildren - 1);
            }
			// if(thumbnailContainer && contains(thumbnailContainer))
			// 	setChildIndex(thumbnailContainer, numChildren - 1);
			// if(playhead && contains(playhead))
			// 	setChildIndex(playhead, numChildren - 1);
			// if(seekLine && contains(seekLine))
			// 	setChildIndex(seekLine, numChildren - 1);
			// if(previewText && contains(previewText))
			// 	setChildIndex(previewText, numChildren - 1);
		}


		public function getTimeFromXCoordinate(_x:Number):Number {
			return _x / _width * (endTime+1 - startTime) + startTime;
		}

		public function get startTime():Number {
			return _video ? interval.start * _video.duration : -1;
		}

		public function get endTime():Number {
			return _video ? interval.end * _video.duration : -1;
		}

		public function get duration():Number {
			return _video ? interval.length * _video.duration : -1;
		}

		protected function logMouseOverLocation(e:TimerEvent):void {
			// TODO
			//actionLogSignal.dispatch("Filmstrip: Mouseover " + timeInSecondsToTimeString(getTimeFromXCoordinate(mouseX)) + ". " + video.filename);
		}

		protected function drawMask():void {
		}

		protected function drawThumbnailMask():void {
		}


		public function timeInSecondsToTimeString(timeX:Number):String {
			var newMinutes:String = uint(timeX/60).toString();
			newMinutes = newMinutes.length == 1 ? "0" + newMinutes : newMinutes;
			var newSeconds:String = uint(timeX%60).toString();
			newSeconds = newSeconds.length == 1 ? "0" + newSeconds : newSeconds;
			return newMinutes + ":" + newSeconds;
		}


		override public function set resizing(val:Boolean):void {

			_resizing = val;

			if(_resizing) {
				hideImages();
			} else if(!_resizing) {
				showImages();
			}
//            _resizing = val;

		}

		override public function get height():Number {
			return _height;
		}

	}
}