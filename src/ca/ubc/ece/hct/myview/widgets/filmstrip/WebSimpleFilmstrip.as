////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.filmstrip  {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.common.Highlightable;
import ca.ubc.ece.hct.myview.thumbnail.WebThumbnailSegment;
import ca.ubc.ece.hct.myview.video.VideoCaptions;

import ca.ubc.ece.hct.myview.video.VideoMetadata;

import com.greensock.*;
	import com.greensock.easing.*;

	import org.osflash.signals.Signal;
	
	import ca.ubc.ece.hct.myview.ui.StarlingFloatingTextField;
	import ca.ubc.ece.hct.myview.widgets.filmstrip.FilmstripHighlight;
	import ca.ubc.ece.hct.myview.common.CaptionView;
	import ca.ubc.ece.hct.myview.widgets.subtitleviewer.Cue;

	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	// import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;

	public class WebSimpleFilmstrip extends Highlightable {

		public static const playheadLineThickness:uint = 2;
		public static const highlightLineThickness:uint = 4; // highlight line thickness

		public function set captionsEnabled(val:Boolean):void {
			if(val && !contains(captionView)) {
				addChild(captionView);
			} else if(!val && contains(captionView)) {
				removeChild(captionView);
			}
		}

		private var captionView:CaptionView;
		private var captionFormat:TextFormat;

		public var highlightSpriteThickness:uint = 4;

		private var maskingSprite:Sprite;
		private var thumbnails:Array;
		private var minimumThumbnails:int;
		private var thumbnailContainer:Sprite;
		private var thumbnailContainerOutline:Sprite;
		private var thumbnailContainerMask:Sprite;
		private var filmstripLoaded:Boolean;
		public var video:VideoMetadata;
		private var numThumbnailsLoaded:int = 0;
		private var _width:Number, _height:Number;
		private var interval:Range;
		private var currentTime:Number = 0;

		private var playhead:Shape;
		private var enableSeekLineBool:Boolean = true;
		private var seekLine:Shape;


		private var highlightSprite:Sprite;

		private var previewText:StarlingFloatingTextField;

		private var logTimer:Timer;

		private var resizingStatus:Boolean;
		private var mouseDownTime:Number;
		public var selectionRange:Range;
		private var selectionHighlightSprite:Sprite;

		public var filmstripMouseMoveSignal:Signal;
		public var filmstripClickSignal:Signal;
		public var filmstripDoubleClickSignal:Signal
		public var filmstripSelectSignal:Signal;
		public var filmstripLoadedSignal:Signal;
		public var filmstripClosed:Signal;
		public var actionLogSignal:Signal;

		public var selectedSignal:Signal;

		public function WebSimpleFilmstrip(video:VideoMetadata,
										   width_:int,
										   height_:int,
										   minimumThumbnails:int = 1,
										   startTime:Number = 0,
										   endTime:Number = -1,
										   resizingStatus:Boolean = false) {

			this.video = video;
			this.minimumThumbnails = minimumThumbnails;
			this.resizingStatus = resizingStatus;
			_width = width_;
			_height = height_

			actionLogSignal = new Signal(String);

			filmstripSelectSignal = 		new Signal(Range);	
			filmstripClickSignal = 			new Signal(Number, Number); // oldTime, newTime
			filmstripDoubleClickSignal = 	new Signal(Number, Number); // oldTime, newTime
			filmstripLoadedSignal = 		new Signal();	
			filmstripMouseMoveSignal = 		new Signal(Number);
			filmstripClosed = 				new Signal();
			selectedSignal =				new Signal(Range); // interval

			interval = new Range(0, 0);
			if(startTime >= 0 && startTime < video.duration) {
				interval.start = startTime;
			}

			if(endTime == -1) {
				interval.end = video.duration;
			} else if(endTime > startTime) {
				interval.end = endTime;
			} else if(endTime < startTime) {
				throw new Error("Filmstrip endTime (" + endTime + ") must be > startTime (" + startTime + ")");
			}


			logTimer = new Timer(2000);
			logTimer.addEventListener(TimerEvent.TIMER, logMouseOverLocation);


			maskingSprite = new Sprite();
			drawMask();
			addChild(maskingSprite)
			this.mask = maskingSprite;

			thumbnailContainer = new Sprite();
			thumbnailContainerOutline = new Sprite();
			thumbnailContainerMask = new Sprite();
			thumbnailContainer.mask = thumbnailContainerMask;
			drawThumbnailMask();
			addChild(thumbnailContainer);
			// thumbnailContainer.addChild(thumbnailContainerOutline);
			addChild(thumbnailContainerMask);
			thumbnails = [];
			numThumbnailsLoaded = 0;
			filmstripLoaded = true;

			createOptimalNumberOfThumbnails();

			selectionHighlightSprite = new Sprite();
			addChild(selectionHighlightSprite);

	        captionFormat = new TextFormat("Arial", 18, 0xffffff, true, false, false, null, null, "center", null, null, null, 4);
			captionView = new CaptionView(_width, captionFormat);
			captionView.y = height - 25;


			highlightSprite = new Sprite();
			highlightSpriteThickness = height/4;
			// highlightSprite.addEventListener(MouseEvent.ROLL_OVER, highlightSpriteMouseOver);
			// highlightSprite.mouseEnabled = false;
			addChild(highlightSprite);

			playhead = new Shape();
			drawPlayhead();
			addChild(playhead);

			seekLine = new Shape();
			drawSeekLine();
			setPlayhead(-1);
			addEventListener(MouseEvent.ROLL_OVER, filmstripMouseOver);
			addEventListener(MouseEvent.ROLL_OUT, filmstripMouseOut);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			thumbnailContainer.addEventListener(MouseEvent.CLICK, filmstripMouseClick);

			previewText = new StarlingFloatingTextField("00:00", new TextFormat("Arial", 10, 0xFFFFE8, true, false, false, null, null, "center", null, null, null, 4));

			drawHighlights();
			reorderSpriteIndex();
		}

		public function destroy():void {
			for(var i:int = 0; i<thumbnails.length; i++) {
				thumbnails[i].cleanup();
			}
			thumbnailContainer = null;
			thumbnailContainerMask = null;
			video = null;
			playhead = null;
			seekLine = null;

			previewText = null;
			thumbnails = null;
		}

		public function reset(video:VideoMetadata, startTime:Number, endTime:Number):void {
			this.video = video;
			interval.start = startTime;

			if(endTime == -1) {
				interval.end = video.duration;
			} else if(endTime > startTime && endTime <= video.duration) {
				interval.end = endTime;
			} else if(endTime < startTime) {
				throw new Error("Filmstrip endTime (" + endTime + ") must be > startTime (" + startTime + ")");
			}


			var thumbnailInterval:Range = new Range(0, 0);
			var thumbnailIntervalLength:Number = thumbnailInterval.length/thumbnails.length;

			for(var i:int = 0; i<thumbnails.length; i++) {

				thumbnailInterval.start = i 	* thumbnailIntervalLength + interval.start;
				thumbnailInterval.end   = (i+1) * thumbnailIntervalLength + interval.start;

				// thumbnails[i].video = video;
				thumbnails[i].startTime = thumbnailInterval.start;
				thumbnails[i].endTime = thumbnailInterval.end;
				filmstripLoadedSignal.dispatch();
			}
		}

		public function enableClick():void {
			if(!thumbnailContainer.hasEventListener(MouseEvent.CLICK))
				thumbnailContainer.addEventListener(MouseEvent.CLICK, filmstripMouseClick);
		}

		public function disableClick():void {
			if(thumbnailContainer.hasEventListener(MouseEvent.CLICK))
				thumbnailContainer.removeEventListener(MouseEvent.CLICK, filmstripMouseClick);
		}

		public function mouseDown(e:MouseEvent):void {
			// trace("start " + e.currentTarget.mouseX);
			mouseDownTime = e.currentTarget.getTimeFromXCoordinate(e.currentTarget.mouseX)

			addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);

			selectionRange = new Range(mouseDownTime, mouseDownTime);
		}

		public function mouseMove(e:MouseEvent):void {

			var mouseTime:Number = e.currentTarget.getTimeFromXCoordinate(e.currentTarget.mouseX);
			var mouseBeginTime:Number = mouseDownTime;

			var start:Number = (mouseTime < mouseBeginTime) ? mouseTime : mouseBeginTime;
			var end:Number = (mouseTime < mouseBeginTime) ? mouseBeginTime : mouseTime
			
			selectionRange = new Range(start, end);
		 	setSelectionInSeconds(selectionRange);
			// dispatchEvent(new HighlightEvent(HighlightEvent.SELECTING, selectionRange.start, selectionRange.end));

			disableClick();
		}

		public function mouseUp(e:MouseEvent):void {
			// trace("end " + e.currentTarget.mouseX);
			var mouseTime:Number = e.currentTarget.getTimeFromXCoordinate(e.currentTarget.mouseX);
			var mouseBeginTime:Number = mouseDownTime;

			var start:Number = (mouseTime < mouseBeginTime) ? mouseTime : mouseBeginTime;
			var end:Number = (mouseTime < mouseBeginTime) ? mouseBeginTime : mouseTime;
			// if(start != end)
			// 	actionLogSignal.dispatch("2D Filmstrip: Selected [" + Util.roundNumber(start, 2) + ", " + Util.roundNumber(end, 2) + "]");
			
			selectionRange = new Range(start, end);
			setSelectionInSeconds(selectionRange);
			// trace("Selected " + selectionRange);

			selectedSignal.dispatch(selectionRange);
			// dispatchEvent(new HighlightEvent(HighlightEvent.SELECT, selectionRange.start, selectionRange.end));
			// e.currentTarget.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);

			removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUp);

			var timer:Timer = new Timer(1000);
			timer.addEventListener(TimerEvent.TIMER,
				function enableClickFilmstrip(e:TimerEvent):void {
					enableClick();
					timer.stop();
				});
			timer.start();
		}

		public function setSelectionInSeconds(range:Range):void {
			var start:Number = (range.start - startTime) / (endTime+1 - startTime) * _width;
			start = (start < 0) ? 0 : start;
			var end:Number = (range.end - startTime) / (endTime+1 - startTime) * _width
			end = (end > _width) ? _width: end;

			selectionHighlightSprite.graphics.clear();
			selectionHighlightSprite.graphics.beginFill(0x4444ff, 0.4);
			selectionHighlightSprite.graphics.drawRect(start, 0, (end - start), height)
			selectionHighlightSprite.graphics.endFill();
			if(!contains(selectionHighlightSprite)) {
				addChild(selectionHighlightSprite);
				reorderSpriteIndex()
			}

			actionLogSignal.dispatch("Filmstrip: Selected " + range);
		}


		private function filmstripMouseOver(e:MouseEvent):void {
			if(enableSeekLineBool) {
				addChild(seekLine);
				addChild(previewText);
			}
			addEventListener(MouseEvent.MOUSE_MOVE, filmstripMouseMove);
			logTimer.start();
		}

		private function filmstripMouseMove(e:MouseEvent):void {
			var previewTextYMin:uint = 5;
			setSeekLinePosition(e.currentTarget.mouseX);

			if(contains(seekLine))
				setChildIndex(seekLine, numChildren - 1);
			if(contains(previewText))
				setChildIndex(previewText, numChildren - 1);

			captionSeek(getTimeFromXCoordinate(e.currentTarget.mouseX));

			filmstripMouseMoveSignal.dispatch(getTimeFromXCoordinate(e.currentTarget.mouseX))
		}

		public function setSeekLinePosition(val:Number):void {
			previewText.text = timeInSecondsToTimeString(getTimeFromXCoordinate(val));

			TweenLite.to(previewText, 0.15, {x: Math.max(0, val - previewText.width - 2),
										  	ease: Power0.easeNone});
			seekLine.x = val;
		}

		private function filmstripMouseOut(e:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_MOVE, filmstripMouseMove);
			if(enableSeekLineBool) {
				removeChild(seekLine);
				removeChild(previewText);
			}
			logTimer.stop();
		}

		private var clickTimer:Timer;
		private var numClicks:Number;
		private var clickMouseEvent:MouseEvent;
		private function filmstripMouseClick(e:MouseEvent):void {
			if(clickTimer == null) {
				clickTimer = new Timer(150);
				clickTimer.addEventListener(TimerEvent.TIMER,
					function singleClickTimer(e:TimerEvent):void {
						singleClick(clickMouseEvent);
					});
				numClicks = 0;
			}
			clickTimer.start();
			clickMouseEvent = e;
			numClicks++;
			if(numClicks == 2) {
				doubleClick(clickMouseEvent);
			}
		}

		private function singleClick(e:MouseEvent):void {
			var currentTime:Number 	= playhead.x 		     / _width * (endTime - startTime) + startTime;
			var newTime:Number 		= e.currentTarget.mouseX / _width * (endTime - startTime) + startTime;
			numClicks = 0;
			clickTimer.reset();
			clickTimer = null;
			filmstripClickSignal.dispatch(currentTime, newTime);
			actionLogSignal.dispatch("Filmstrip: Single Click at " + newTime);
		}

		private function doubleClick(e:MouseEvent):void {
			var currentTime:Number 	= playhead.x      		 / _width * (endTime - startTime) + startTime;
			var newTime:Number 		= e.currentTarget.mouseX / _width * (endTime - startTime) + startTime;
			numClicks = 0;
			clickTimer.reset();
			clickTimer = null;
			filmstripDoubleClickSignal.dispatch(currentTime, newTime);
			actionLogSignal.dispatch("Filmstrip: Double Click at " + newTime);
		}

		private var currentDisplayCaptionTime:Number = 0;
		private function captionSeek(time:Number):void {

			if(video.getSources("vtt")[0]) {

				var captions:VideoCaptions = video.getSources("vtt")[0].captions;
				var cue:Cue = captions.getCueAtTime(time);
				var text:String = cue.getText();

				if(contains(captionView)) {

	        		if(captionView.text != text) {
		        		var direction:Number = currentDisplayCaptionTime > time ? 1 : -1;
		        		captionView.displayText(text, direction);
		        	}

	        		captionView.cursor = (time - cue.startTime/1000)/(cue.duration/1000);
	        		currentDisplayCaptionTime = time;
	        	}
			}
		}

		private function createOptimalNumberOfThumbnails():void {
			
			var numThumbnails:uint = 1;

			for(var i:int = minimumThumbnails; i<20; i++) {
				var thumbnailNewWidth:Number = _width/i;

				var thumbnailNewHeight:Number = thumbnailNewWidth / video.aspectRatio;

				if(thumbnailNewHeight < _height && thumbnailNewWidth * i >= _width) {
					numThumbnails = i;
					// trace(i + " " + thumbnailNewWidth + "x" + thumbnailNewHeight + " " + _width + "x" + _height);
					break;
				}

				numThumbnails = i;
			}
			createThumbnails(numThumbnails);
		}

		private function createThumbnails(numThumbnails:uint):void {

			var thumbnailIntervalLength:Number = interval.length/numThumbnails;
			var thumbnailInterval:Range = new Range(0, 0);

			var thumbnailWidth:Number = _width/numThumbnails;

			if(thumbnails.length < numThumbnails) {
				// not enough thumbnails

				for(var i:int = 0; i<thumbnails.length; i++) {

					thumbnailInterval.start = i 	* thumbnailIntervalLength + interval.start;
					thumbnailInterval.end   = (i+1) * thumbnailIntervalLength + interval.start;

					thumbnails[i].video = 		video;
					thumbnails[i].startTime = 	thumbnailInterval.start;
					thumbnails[i].endTime = 	thumbnailInterval.end;
					thumbnails[i].resize		(thumbnailWidth, _height);
					thumbnails[i].x = 			i*thumbnailWidth;
				}

				for(i = thumbnails.length; i<numThumbnails; i++) {

					thumbnailInterval.start = i 	* thumbnailIntervalLength + interval.start;
					thumbnailInterval.end   = (i+1) * thumbnailIntervalLength + interval.start;

					var thumbnail:WebThumbnailSegment = new WebThumbnailSegment(video, thumbnailWidth, _height, thumbnailInterval.start, thumbnailInterval.end, resizingStatus);
					thumbnail.identifier = i;

					if(i != 0)
						thumbnail.x = (thumbnail.identifier-1)*thumbnailWidth;
					thumbnail.alpha = 0;
					thumbnail.y = _height/2 - (thumbnailWidth / video.aspectRatio)/2;

					// thumbnail.loaded.addOnce(
						// function thumbnailLoaded(thumb:WebThumbnailSegment):void {
							
							TweenLite.to(thumbnail, 0.5, 
										{x: thumbnail.identifier * thumbnailWidth, 
									 alpha: 1,
									  ease: Back.easeOut});
						// });

					thumbnail.addEventListener(MouseEvent.MOUSE_MOVE,
						function thumbnailSeek(e:MouseEvent):void {
							e.target.seekNormalized(e.localX/e.target.width);
							})

					thumbnails.push(thumbnail);
					thumbnailContainer.addChild(thumbnail);
					thumbnailContainer.setChildIndex(thumbnail, 0);			
				}
				filmstripLoadedSignal.dispatch();

			
			} else if (thumbnails.length > numThumbnails) {
				// too many thumbnails

				while(thumbnails.length > numThumbnails) {
					thumbnailContainer.removeChild(thumbnails.pop());
					numThumbnailsLoaded--;
				}

				for(i = 0; i<thumbnails.length; i++) {

					thumbnailInterval.start = i 	* thumbnailIntervalLength + interval.start;
					thumbnailInterval.end   = (i+1) * thumbnailIntervalLength + interval.start;

					thumbnails[i].video = video;
					thumbnails[i].startTime = thumbnailInterval.start;
					thumbnails[i].endTime = thumbnailInterval.end;
					thumbnails[i].resize(thumbnailWidth, _height);
					thumbnails[i].x = i*thumbnailWidth;
					filmstripLoadedSignal.dispatch();
				}

			
			} else {
				// number of thumbnails is correct

				for(i = 0; i<thumbnails.length; i++) {
					thumbnails[i].resize(thumbnailWidth, _height);
					thumbnails[i].x = i*thumbnailWidth;
					filmstripLoadedSignal.dispatch();
				}
			}

			reorderSpriteIndex();
		}

		public function retract():void {
			for(var i:int = 0; i<thumbnails.length; i++) {
				TweenLite.to(thumbnails[i], 0.25,
					        {x: 0,
					      ease: Power2.easeOut,
				    onComplete: retracted});
			}
		}
		
		private function retracted():void {
			filmstripClosed.dispatch();
		}

		public function removeThumbnails():void {
			while(thumbnails.length > 0) {
				thumbnailContainer.removeChild(thumbnails.pop());
			}
			numThumbnailsLoaded = 0;
		}

		public function setPlayhead(time:Number):void {
			if(time < startTime || time > endTime) {
				playhead.alpha = 0;
				playhead.x = -1;
			} else {
				playhead.alpha = 1;
				if(playhead.x != -1)
					TweenLite.to(playhead, 0.15, {x: (time - startTime) / (endTime - startTime) * _width,
												 ease: Power0.easeNone});
				else
					playhead.x = (time - startTime) / (endTime - startTime) * _width;
			}
			currentTime = time;
		}
		
		public function set playheadTime(time:Number):void {
			setPlayhead(time);
		}

		override public function updateHighlights():void {
			drawHighlights();
		}

		public function drawHighlights():void {
			var highlights:Array = video.userData.getHighlightsForTimeRange(interval);
			
			highlightSprite.graphics.clear();
			while(highlightSprite.numChildren > 0) {
				highlightSprite.removeChildAt(0);
			}
			var totalTime:Number = (endTime + 1 - startTime);
			var highlightWidth:Number = _width / totalTime;

			highlightSprite.graphics.beginFill(0, 0.3);
			highlightSprite.graphics.drawRect(0, 0, _width, highlights.length * highlightLineThickness);
			highlightSprite.graphics.endFill();

			// draw an invisible mouse_over area
			// highlightSprite.graphics.beginFill(0xff0000, 0);
			// highlightSprite.graphics.drawRect(0, 0, _width, highlightSpriteThickness);
			// highlightSprite.graphics.endFill();

			// trace("highlights length " + highlights.length);
			for(var i:int = 0; i<highlights.length; i++) {
				// trace("|||" + highlights[i])
				// trace("|||" + highlights[i].getString())
				// trace("|||" + highlights[i].intervals)
				// trace("|||" + i);

				for(var j:int = 0; j<highlights[i].intervals.length; j++) {
					// trace("highlights[" + i + "].intervals[" + j + "]: " + highlights[i].intervals[j]);
					// trace("video.highlights[" + i + "]" + video.highlights[i])
					if(startTime <= highlights[i].intervals[j].end && endTime >= highlights[i].intervals[j].start) {

						var timeRange:ca.ubc.ece.hct.Range = new Range(highlights[i].intervals[j].start, highlights[i].intervals[j].end)

						var xDimension:Number = Math.max(0, (highlights[i].intervals[j].start - startTime)/totalTime * _width)

						var widthDimension:Number = Math.min(_width, (highlights[i].intervals[j].end - startTime)/totalTime * _width) - xDimension;

						// trace("start = " + xDimension + " end = " + (xDimension + widthDimension))

						var dimensions:Rectangle = new Rectangle(xDimension, (i)*highlightLineThickness,
																 widthDimension, highlightLineThickness);
						var highlight:FilmstripHighlight = new FilmstripHighlight(timeRange, dimensions, highlights[i].colour);
						highlight.x = dimensions.x;
						highlight.y = dimensions.y;
						// highlight.clickSignal.add(
						// 	function highlightClicked(timeRange:Range, colour:uint):void {
						// 		filmstripPlayHighlightSignal.dispatch(timeRange);
						// 	});
						// highlight.actionLogSignal.add(
						// 	function bubbleActionLog(message:String):void {
						// 		actionLogSignal.dispatch(message);
						// 	});
						
						highlightSprite.addChild(highlight);
					}
				}
			}
		}

		override public function deselect():void {
			
			selectionRange = new Range(0, 0);
		 	setSelectionInSeconds(selectionRange);
		}

		private function reorderSpriteIndex():void {
			arrangeToTop(thumbnailContainer);
			arrangeToTop(selectionHighlightSprite);
			arrangeToTop(playhead);
			arrangeToTop(seekLine);
			arrangeToTop(previewText);
			arrangeToTop(highlightSprite);
		}

		private function arrangeToTop(obj:DisplayObject):void {
			if(obj && contains(obj)) {
				setChildIndex(obj, numChildren - 1);
			}
		}

		public function getTimeFromXCoordinate(_x:Number):Number {
			return _x / _width * (endTime + 1 - startTime) + startTime;
		}

		public function set startTime(val:Number):void {
			interval.start = val;
			retimeThumbnails();
		}

		public function get startTime():Number {
			return interval.start;
		}

		public function set endTime(val:Number):void {
			interval.end = val
			retimeThumbnails();
		}

		public function get endTime():Number {
			return interval.end;
		}

		public function getNumThumbnails():Number {
			return thumbnails.length;
		}

		private function retimeThumbnails():void {

			var thumbnailIntervalLength:Number = interval.length/thumbnails.length;

			for(var i:int = 0; i<thumbnails.length; i++) {

				thumbnails[i].startTime = 	i     * thumbnailIntervalLength + interval.start;
				thumbnails[i].endTime = 	(i+1) * thumbnailIntervalLength + interval.start;
			}
		}

		private function logMouseOverLocation(e:TimerEvent):void {
			actionLogSignal.dispatch("Filmstrip: Mouseover " + timeInSecondsToTimeString(getTimeFromXCoordinate(mouseX)) + ". " + video.filename);
		}

		private function drawMask():void {
			maskingSprite.graphics.clear();
			maskingSprite.graphics.beginFill(0xff00ff, 1);
			maskingSprite.graphics.drawRect(0, 0, _width, _height);
			maskingSprite.graphics.endFill();
		}

		private function drawThumbnailMask():void {
			thumbnailContainerMask.graphics.clear();
			thumbnailContainerMask.graphics.beginFill(0xff00ff, 1);
			thumbnailContainerMask.graphics.drawRect(0, 0, _width, _height);
			
			thumbnailContainerMask.graphics.endFill();
		}

		public function enableSeekLine():void {
			enableSeekLineBool = true;
		}

		public function disableSeekLine():void {
			enableSeekLineBool = false;
		}

		private function drawSeekLine():void {
			seekLine.graphics.clear();
			// seekLine.graphics.beginFill(0xff0000);
			var matr:Matrix = new Matrix;
			matr.createGradientBox(playheadLineThickness, _height, Math.PI/2, 0, 0);
			seekLine.graphics.beginGradientFill(GradientType.LINEAR, 
				[0xaa0000, 0xff0000, 0xaa0000], // colour
				[1, 1, 1],  // alpha
				[0, 127, 255], // ratio
				matr);
			seekLine.graphics.drawRoundRect(0, 0, playheadLineThickness, _height, 5);
			seekLine.graphics.endFill();
		}

		private function drawPlayhead():void {
			playhead.graphics.clear();
			// playhead.graphics.beginFill(0x00ccff, 0.8);
			var matr:Matrix = new Matrix;
			matr.createGradientBox(playheadLineThickness, _height, Math.PI/2, 0, playheadLineThickness);
			playhead.graphics.beginGradientFill(GradientType.LINEAR, 
				[0x0088aa, 0x00ccff, 0x0088aa], // colour
				[1, 1, 1],  // alpha
				[0, 127, 255], // ratio
				matr);
			playhead.graphics.drawRoundRect(0, 0, playheadLineThickness, _height, 5);
			playhead.graphics.endFill();
			playhead.graphics.beginFill(0x00ccff, 0.8);
			playhead.graphics.drawCircle(playheadLineThickness/2, _height/2, 5);
			playhead.graphics.endFill();
		}

		public function timeInSecondsToTimeString(timeX:Number):String {
			var newMinutes:String = uint(timeX/60).toString();
			newMinutes = newMinutes.length == 1 ? "0" + newMinutes : newMinutes;
			var newSeconds:String = uint(timeX%60).toString();
			newSeconds = newSeconds.length == 1 ? "0" + newSeconds : newSeconds;
			return newMinutes + ":" + newSeconds;
		}

		public function setResizingStatus(val:Boolean):void {
			resizingStatus = val;
			for(var i:int = 0; i<thumbnails.length; i++) {
				thumbnails[i].setResizingStatus(val);
			}

			if(resizingStatus == false) {
				actionLogSignal.dispatch("Filmstrip: Created " + thumbnails.length + " thumbnails");
			}
		}

		override public function set width(val:Number):void {
			_width = val;

			drawMask();
			drawThumbnailMask();
			createOptimalNumberOfThumbnails();
		}

		override public function set height(val:Number):void {
			_height = val;
			drawMask();
			drawThumbnailMask();
			drawPlayhead();
			drawSeekLine();
			createOptimalNumberOfThumbnails();
		}

		override public function get height():Number {
			return _height;
		}

		override public function set y(val:Number):void {
			super.y = val;

		}
	}
}