////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.filmstrip {
import ca.ubc.ece.hct.ImageLoader;
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.common.CaptionView;
import ca.ubc.ece.hct.myview.common.Highlightable;
import ca.ubc.ece.hct.myview.thumbnail.SlideThumbnailSegment;
import ca.ubc.ece.hct.myview.video.VideoCaptions;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.subtitleviewer.Cue;

import com.greensock.*;
import com.greensock.easing.*;

import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.PerspectiveProjection;
import flash.geom.Point;
import flash.text.TextFormat;

import org.osflash.signals.Signal;
import org.osflash.signals.natives.NativeSignal;

public class WebSlideFilmstrip extends Highlightable {

		private static const DEBUG:Boolean = false;

		private var _width:Number, _height:Number;

		private var interactiveSlideThumbnail:SlideThumbnailSegment;
		private var thumbnails:Vector.<SlideThumbnailSegment>;
		private var thumbnailRot:Number;
		private var activeThumbnail:uint;

		private var background:Shape;
		private var masker:Shape;
		private var activeFilmstrip:WebSimpleFilmstrip, inactiveFilmstrip:WebSimpleFilmstrip;
		private var closeFilmstripButton:ImageLoader;
		private var fadeOutOverlay:Sprite;
	    private var captionView:CaptionView;
	    private var captionFormat:TextFormat;

	    private var nextFilmstripButton:SwitchFilmstripButton;
	    private var previousFilmstripButton:SwitchFilmstripButton;

		private var _video:VideoMetadata;

		private static const thumbnailOffset:Number = 50;
		private static const filmstripPadding:Number = 30;
		
		private var perspectiveProjection:PerspectiveProjection;
		private var addedToStageBoolean:Boolean = false;
		private var addedToStageSignal:NativeSignal;
		private var removedFromStageSignal:NativeSignal;

		private var mouseOver:Boolean;

		public var seeked:Signal;
		public var actionLogSignal:Signal;
		// public var selected:Signal;

		public function WebSlideFilmstrip(width:Number, height:Number) {

			super();

			_width = width;
			_height = height;

			masker = new Shape();
			masker.graphics.beginFill(0xff00ff);
			masker.graphics.drawRect(0, 0, _width, _height);
			masker.graphics.endFill();
			addChild(masker);
			this.mask = masker;


			thumbnails = new Vector.<SlideThumbnailSegment>();
	        captionFormat = new TextFormat("Arial", 18, 0xffffff, true, false, false, null, null, "center", null, null, null, 4);

	        perspectiveProjection = new PerspectiveProjection();
			addedToStageSignal = new NativeSignal(this, Event.ADDED_TO_STAGE, Event);
			removedFromStageSignal = new NativeSignal(this, Event.REMOVED_FROM_STAGE, Event);
			addedToStageSignal.addOnce(addedToStage);

			seeked = new Signal(Number); // seeked time
			actionLogSignal = new Signal(String);
		}

		private function addedToStage(e:Event = null):void {
			addedToStageBoolean = true;
			removedFromStageSignal.addOnce(removedFromStage);
		}

		private function removedFromStage(e:Event = null):void {
			addedToStageBoolean = false;
			addedToStageSignal.addOnce(addedToStage);
		}

		public function render(video:VideoMetadata, slideTimesByPercentChanged:Vector.<Number>):void {

			background = new Shape();
			background.graphics.beginFill(0xcccccc, 0.5);
			background.graphics.drawRect(0, 0, _width, _height);
			background.graphics.endFill();
			addChild(background);

			fadeOutOverlay = new Sprite();
			fadeOutOverlay.graphics.beginFill(0, 0.7);
			fadeOutOverlay.graphics.drawRect(0, 0, _width, _height);
			fadeOutOverlay.graphics.endFill();

			_video = video;

			// if(video.captionsArray != null) {
				captionView = new CaptionView(_width, captionFormat);
			// 	captionView.y = _height - Number(captionFormat.size) * 1.5;
			// }

			var rotationTestSprite:Shape = new Shape();
			rotationTestSprite.graphics.beginFill(0xff0000, 1);
			rotationTestSprite.graphics.drawRect(0, 0, _height * 0.8 / (video.tileSource[0].frameHeight/video.tileSource[0].frameWidth), _height * 0.8);
			rotationTestSprite.graphics.endFill();

			var thumbnailWidth:Number = (_width-thumbnailOffset)/slideTimesByPercentChanged.length;

			// this rotationTestSprite is used to determine a proper rotation for each of the thumbnails so that their VISISBLE width on screen
			// is what we want (based on overlapping of thumbnails etc.)
			// we put the rotationsTestSprite at the stage's centre of projection (we later set each thumbnail to have their own centre of projection)
			// and rotate it until we find our desired width. This is the rotation we want for ALL our thumbnails.
			var stageMiddle:Point = new Point(stage.stageWidth/2, stage.stageHeight/2);
			rotationTestSprite.x = globalToLocal(stageMiddle).x;
			rotationTestSprite.y = globalToLocal(stageMiddle).y;
			addChild(rotationTestSprite);

			for(var i:int = 0; i>-360; i--) {
				rotationTestSprite.rotationY = i;
				if(rotationTestSprite.width < thumbnailWidth) {
					thumbnailRot = i;
					removeChild(rotationTestSprite);
					break;
				}
			}

			for(i = 0; i<slideTimesByPercentChanged.length; i++) {

				var thumb:SlideThumbnailSegment;
				var endTime:Number = (i + 1 < slideTimesByPercentChanged.length) ? slideTimesByPercentChanged[i+1] : video.duration;
				thumb = new SlideThumbnailSegment(video, 
												  _height * 0.8 / (video.tileSource[0].frameHeight/video.tileSource[0].frameWidth), 
												  _height * 0.8, 
												  new Range(slideTimesByPercentChanged[i], endTime));
				if(!thumb.ready) {
					thumb.loaded.addOnce(
						function thumbnailLoaded(t:SlideThumbnailSegment):void {
							TweenLite.to(t, 2,
										{alpha: 1,
									  ease: Power2.easeInOut});	
						});
				} else {
					TweenLite.to(thumb, 2,
									{alpha: 1,
								  ease: Power2.easeInOut});	
				}
				addChild(thumb);
				thumbnails.push(thumb);



				thumb.x = thumbnailOffset + i/slideTimesByPercentChanged.length * (_width);
				thumb.transform.perspectiveProjection = new PerspectiveProjection();
				var localPoint:Point = new Point(thumb.x + thumb.width/2, thumb.y + thumb.height/2);
				thumb.transform.perspectiveProjection.projectionCenter = localPoint;

				thumb.rotationY = thumbnailRot;


				// thumb.x = thumbnailOffset + i/slideTimesByPercentChanged.length * (_width) + 1.5*_width;
				thumb.x = thumbnailOffset + i/slideTimesByPercentChanged.length * (_width-thumbnailOffset*3);
				thumb.alpha = 0;

				// thumb.clickSignal.add(mouseClick);
				

				thumb.y = _height * 0.1;

			}	

			interactiveSlideThumbnail = new SlideThumbnailSegment(video, _height * 0.8 / (video.tileSource[0].frameHeight/video.tileSource[0].frameWidth), _height * 0.8, new Range(0, 0));
			interactiveSlideThumbnail.highlighted.add( 
				function thumbnailHighlighted(videoFilename:String, colour:Number, interval:ca.ubc.ece.hct.Range) {

					// trace(activeThumbnail);
					thumbnails[activeThumbnail].drawHighlights(interactiveSlideThumbnail.highlightColours);


					actionLogSignal.dispatch("Slidestrip: Highlighted " + interval + " in #" + colour.toString(16));

					highlighted.dispatch(video.filename, colour, interval);


					// trace("LLL"+interactiveSlideThumbnail.highlightColours)
					// trace(video.filename + " " + colour + " " + interval)
				})
			interactiveSlideThumbnail.unhighlighted.add( 
				function thumbnailUnhighlighted(videoFilename:String, colour:Number, interval:ca.ubc.ece.hct.Range) {

					thumbnails[activeThumbnail].drawHighlights(interactiveSlideThumbnail.highlightColours);


					actionLogSignal.dispatch("Slidestrip: Unhighlighted " + interval + " in #" + colour.toString(16));

					unhighlighted.dispatch(video.filename, colour, interval);
				})
			interactiveSlideThumbnail.clickSignal.add(mouseClick);
			interactiveSlideThumbnail.seeked.add(sendSeek);
			interactiveSlideThumbnail.actionLogSignal.add(bubbleActionLog);
			// interactiveSlideThumbnail.alpha = 0;

	        closeFilmstripButton = new ImageLoader("uiimage/fancy_close.png");

	        nextFilmstripButton = new SwitchFilmstripButton(30, _height - filmstripPadding*2, SwitchFilmstripButton.RIGHT);
	        previousFilmstripButton = new SwitchFilmstripButton(30, _height - filmstripPadding*2, SwitchFilmstripButton.LEFT);

			addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
			// addEventListener(MouseEvent.CLICK, mouseClick);
		}

		override public function highlight(colour:int, interval:ca.ubc.ece.hct.Range):void {

			for(var i:int = 0; i<thumbnails.length; i++) {
				if(thumbnails[i].startTime < interval.end && thumbnails[i].endTime > interval.start) {
					thumbnails[i].drawHighlights(_video.userData.getHighlightedColoursforTimeRange(interval));
				}
			}

			highlighted.dispatch(_video.filename, colour, interval);
		}

		override public function unhighlight(colour:int, interval:ca.ubc.ece.hct.Range):void {

			for(var i:int = 0; i<thumbnails.length; i++) {
				if(thumbnails[i].startTime < interval.end && thumbnails[i].endTime > interval.start) {
					thumbnails[i].drawHighlights(_video.userData.getHighlightedColoursforTimeRange(interval));
				}
			}

			unhighlighted.dispatch(_video.filename, colour, interval);

		}

		override public function updateHighlights():void {
			for(var i:int = 0; i<thumbnails.length; i++) {
				thumbnails[i].drawHighlights(_video.userData.getHighlightedColoursforTimeRange(new Range(thumbnails[i].startTime, thumbnails[i].endTime)));
			}

			if(activeFilmstrip) {
				activeFilmstrip.drawHighlights();
			}

			if(inactiveFilmstrip) {
				inactiveFilmstrip.drawHighlights();
			}
		}

		public function set playheadTime(time:Number):void {
			if(activeFilmstrip) {
				activeFilmstrip.setPlayhead(time);
			}

			for each(var thumb:SlideThumbnailSegment in thumbnails) {
				thumb.playheadTime = time;
			}

			interactiveSlideThumbnail.playheadTime = time;

			// if(!mouseOver) {
			// 	var gaussianWidth:Number = 2;
				
			// 	var a:Number;
			// 	var b:Number = 0;
			// 	var c:Number = _width/thumbnails.length/gaussianWidth;

			// 	var newActiveThumbnail:uint;
			// 	for(var i:int = 0; i < thumbnails.length; i++) {
			// 		// trace(time + " " + thumbnails[i].endTime)
			// 		if(time >= thumbnails[i].startTime && time < thumbnails[i].endTime) {
			// 			newActiveThumbnail = i;
			// 			// trace(i-1);
			// 			break;
			// 		}
			// 	}

			// 	setChildIndex(thumbnails[newActiveThumbnail], numChildren - 1);

			// 	if(newActiveThumbnail != activeThumbnail && contains(interactiveSlideThumbnail)) {
			// 		interactiveSlideThumbnail.makeHighlightButtonDisappear();
			// 		removeChild(interactiveSlideThumbnail);
			// 	}

			// 	if(newActiveThumbnail != activeThumbnail) {
			// 		for(var i:int = 0; i<thumbnails.length; i++) {
			// 			var thumb:SlideThumbnailSegment = thumbnails[i];
			// 			var xPos:Number = thumbnailOffset + i/thumbnails.length * (_width-thumbnailOffset*2);

			// 			var dist:Number = Math.abs(xPos - (thumbnailOffset) + 50);

			// 			var globalLocation:Point = localToGlobal(new Point(thumb.x, thumb.y));
			// 			a = -thumbnailRot;

			// 			setChildIndex(thumb, numChildren - 1);

			// 			if(i != newActiveThumbnail) {
			// 				TweenLite.to(thumb, 2, {x: Math.max(10, Math.min(_width - thumb.width, xPos - gaussian(dist/_width, thumbnailOffset, b, c))),
			// 										   z: gaussian(dist/_width, -20, b, c),
			// 										   rotationY: gaussian(dist/_width, a, b, c) - a,
			// 										   alpha: 0.7,
			// 										   ease: Power0.easeNone});
			// 			} else {

			// 				if(newActiveThumbnail != activeThumbnail) {

			// 	 				interactiveSlideThumbnail.interval = new Range(thumbnails[newActiveThumbnail].startTime, thumbnails[newActiveThumbnail].endTime);

			// 					TweenLite.to(thumb, 2, {x: Math.max(10, Math.min(_width - thumb.width, xPos - gaussian(0, thumbnailOffset, b, c))),
			// 											   z: 0,//gaussian(0, -20, b, c),
			// 											   rotationY: 0,//gaussian(0, a, b, c) - a, 
			// 											   alpha: 1,
			// 											   ease: Power0.easeNone,
			// 										 onComplete: function newSlideThumbnail() {
			// 										 				if(!contains(fadeOutOverlay)) {
			// 											 				interactiveSlideThumbnail.x = thumbnails[newActiveThumbnail].x;
			// 											 				interactiveSlideThumbnail.y = thumbnails[newActiveThumbnail].y;
			// 											 				addChild(interactiveSlideThumbnail);
			// 											 			}
			// 										 			 }
			// 								 			   });
			// 				}
			// 			}
			// 		}

			// 		activeThumbnail = newActiveThumbnail;

			// 		setChildIndex(thumbnails[activeThumbnail], numChildren - 1);
			// 		if(contains(interactiveSlideThumbnail)) {
			// 			setChildIndex(interactiveSlideThumbnail, numChildren - 1);
			// 		}
			// 	}
			// }
		}

		override public function deselect():void {
			
			if(activeFilmstrip) {
				activeFilmstrip.deselect();
			}

			if(inactiveFilmstrip) {
				inactiveFilmstrip.deselect();
			}
		}

		private function mouseClick():void {
			
			setChildIndex(thumbnails[activeThumbnail], numChildren - 1);
			TweenLite.to(thumbnails[activeThumbnail], 0.5, 
						{x: filmstripPadding, 
						 y: filmstripPadding,
						 z: 0,
					  ease:Power2.easeOut}
			);

			addChild(fadeOutOverlay);
			fadeOutOverlay.alpha = 0;
			TweenLite.to(fadeOutOverlay, 0.15, 
						{alpha: 1, 
						  ease: Power0.easeNone,
				    onComplete: function thumbnailTweenComplete():void {
									var time:ca.ubc.ece.hct.Range = new Range(thumbnails[activeThumbnail].startTime, thumbnails[activeThumbnail].endTime);
									addFilmstrip(time);
								}
						}
			);

			bubbleActionLog("Slidestrip: Expanded on thumbnail #" + activeThumbnail + " " + thumbnails[activeThumbnail].intervalString);

			activateFilmstripButtons();

			// removeEventListener(MouseEvent.CLICK, mouseClick);
			removeEventListener(MouseEvent.ROLL_OVER, rollOver);
			removeEventListener(MouseEvent.ROLL_OUT, rollOut);
			removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		}

		private function mouseMove(e:MouseEvent):void {

			mouseOver = true;

			if(DEBUG) {
				graphics.clear();
				graphics.lineStyle(1, 0);
				graphics.moveTo(thumbnailOffset, 300);
			}

			var gaussianWidth:Number = 2;
			// var gaussianWidth:Number = e.localY/_height * 10;
			
			var a:Number;
			var b:Number = 0;
			var c:Number = _width/thumbnails.length/gaussianWidth;

			var newActiveThumbnail:uint;
			newActiveThumbnail = (mouseX-thumbnailOffset)/(_width-thumbnailOffset) * (thumbnails.length);
			newActiveThumbnail = Math.max(0, Math.min(thumbnails.length - 1, newActiveThumbnail));
			setChildIndex(thumbnails[newActiveThumbnail], numChildren - 1);
			// if(contains(interactiveSlideThumbnail))
			// 	setChildIndex(interactiveSlideThumbnail, numChildren - 1);

			if(newActiveThumbnail != activeThumbnail && contains(interactiveSlideThumbnail)) {

				// trace("newActiveThumbnail = " + newActiveThumbnail);
				actionLogSignal.dispatch("Slidestrip: Mouse over thumbnail #" + newActiveThumbnail + " " + thumbnails[newActiveThumbnail].intervalString);
				interactiveSlideThumbnail.makeHighlightButtonDisappear();
				removeChild(interactiveSlideThumbnail);
			}

			for(var i:int = 0; i<thumbnails.length; i++) {
				var thumb:SlideThumbnailSegment = thumbnails[i];
				var xPos:Number = thumbnailOffset + i/thumbnails.length * (_width-thumbnailOffset*2);

				var dist:Number = Math.abs(xPos - (mouseX-thumbnailOffset) + 50);

				var globalLocation:Point = localToGlobal(new Point(thumb.x, thumb.y));
				a = -thumbnailRot;

				setChildIndex(thumb, numChildren - 1);

				if(i != newActiveThumbnail) {
					TweenLite.to(thumb, 0.35, {x: Math.max(10, Math.min(_width - thumb.width, xPos - gaussian(dist/_width, thumbnailOffset, b, c))),
											   z: gaussian(dist/_width, -20, b, c),
											   rotationY: gaussian(dist/_width, a, b, c) - a,
											   alpha: 0.7,
											   ease: Power0.easeNone});
				} else {

					if(newActiveThumbnail != activeThumbnail) {
						// if(contains(interactiveSlideThumbnail))
						// 	removeChild(interactiveSlideThumbnail);

		 				interactiveSlideThumbnail.interval = new Range(thumbnails[newActiveThumbnail].startTime, thumbnails[newActiveThumbnail].endTime);

						TweenLite.to(thumb, 0.35, {x: Math.max(10, Math.min(_width - thumb.width, xPos - gaussian(0, thumbnailOffset, b, c))),
												   z: 0,//gaussian(0, -20, b, c),
												   rotationY: 0,//gaussian(0, a, b, c) - a, 
												   alpha: 1,
												   ease: Power0.easeNone,
											 onComplete: function newSlideThumbnail() {
											 				if(!contains(fadeOutOverlay)) {
												 				interactiveSlideThumbnail.x = thumbnails[newActiveThumbnail].x;
												 				interactiveSlideThumbnail.y = thumbnails[newActiveThumbnail].y;
												 				addChild(interactiveSlideThumbnail);
												 			}
											 			 }
									 			   });
					}
				}

				if(DEBUG)
					graphics.lineTo(i/thumbnails.length * _width + thumbnailOffset, thumb.rotationY + 300);
			}

			activeThumbnail = newActiveThumbnail;

			// trace(activeThumbnail + " " + (numChildren - 1));
			setChildIndex(thumbnails[activeThumbnail], numChildren - 1);
			if(contains(interactiveSlideThumbnail)) {
				setChildIndex(interactiveSlideThumbnail, numChildren - 1);
			}


			if(DEBUG) {
				graphics.lineStyle(1, 0xff0000);
				graphics.moveTo(0, 300);
				for(var i:int = 0; i<stage.stageWidth; i++) {

					var dist:Number = Math.abs(i - mouseX);

					graphics.lineTo(i, thumbnails[0].width * Math.exp(-Math.pow(dist/_width-b, 2)/2*Math.pow(c,2)) + 300)
				}
			}
		}

		private function rollOver(e:MouseEvent):void {
			mouseOver = true;
			TweenLite.to(interactiveSlideThumbnail, 0.5,
						{alpha: 1});
		}

		private function rollOut(e:MouseEvent):void {
			mouseOver = false;
			activeThumbnail = -1;
			TweenLite.to(interactiveSlideThumbnail, 0.5,
						{alpha: 0});
			resetThumbnails(true);
		}

		private function resetThumbnails(animate:Boolean):void {
			for(var i:int = 0; i<thumbnails.length; i++) {
				var thumb:SlideThumbnailSegment = thumbnails[i];

				if(thumb.x != thumbnailOffset + i/thumbnails.length * (_width-thumbnailOffset*2) ||
				   thumb.y != _height * 0.1 ||
				   thumb.z != 0 ||
				   thumb.rotationY != thumbnailRot ||
				   thumb.alpha != 0.7) {

					if(animate)
						TweenLite.to(thumb, 0.15, {x: thumbnailOffset + i/thumbnails.length * (_width-thumbnailOffset*2),
												   y: _height * 0.1,
												   z: 0,
												   rotationY: thumbnailRot,
												   alpha: 0.7,
												   ease: Power0.easeNone});
					else {
						thumb.x = thumbnailOffset + i/thumbnails.length * (_width-thumbnailOffset*2);
						thumb.y = _height * 0.1;
						thumb.z = 0;
						thumb.rotationY = thumbnailRot;
						thumb.alpha = 0.7;
					}

				}

			}
		}

		public function addFilmstrip(time:ca.ubc.ece.hct.Range):void {
			if(activeFilmstrip != null && contains(activeFilmstrip)) {
				removeChild(activeFilmstrip);
			}
			activeFilmstrip = new WebSimpleFilmstrip(_video, _width - filmstripPadding*2, _height - filmstripPadding*2, 1, time.start, time.end);
			activeFilmstrip.selectedSignal.          add(sendSelected);
			activeFilmstrip.filmstripClickSignal.    add(activeFilmstripClicked);
			activeFilmstrip.actionLogSignal.         add(bubbleActionLog);
			activeFilmstrip.filmstripMouseMoveSignal.add(seek);
			activeFilmstrip.x = filmstripPadding;
			activeFilmstrip.y = filmstripPadding;
			activeFilmstrip.drawHighlights();
			addChild(activeFilmstrip);

			// ----------------------------------
			nextFilmstripButton.alpha = 0;
			nextFilmstripButton.x = _width - previousFilmstripButton.width;
			nextFilmstripButton.y = filmstripPadding;
			previousFilmstripButton.alpha = 0;
			previousFilmstripButton.x = 0;
			previousFilmstripButton.y = filmstripPadding;;

			if(activeThumbnail != thumbnails.length - 1)
				addChild(nextFilmstripButton);

			if(activeThumbnail != 0)
		        addChild(previousFilmstripButton);

	        TweenLite.to(nextFilmstripButton, 0.35,
	        			{alpha: 1});
	        TweenLite.to(previousFilmstripButton, 0.35,
	        			{alpha: 1});
			// ----------------------------------
			TweenLite.to(thumbnails[activeThumbnail], 0.35, 
						{
				 rotationY: thumbnailRot, 
					 alpha: 0,
					  ease: Power0.easeNone });
			// ---------------------------------
			closeFilmstripButton.alpha = 0;
			closeFilmstripButton.x = _width - filmstripPadding - closeFilmstripButton.width/2;
			closeFilmstripButton.y = filmstripPadding - closeFilmstripButton.height/2;
			addChild(closeFilmstripButton);

			TweenLite.to(closeFilmstripButton, 0.35, 
						{
					 alpha: 1,
					  ease: Power0.easeNone });
			// ---------------------------------
			captionView.alpha = 1;
			addChild(captionView);
		}

		private function swapFilmstripCommon(newActiveThumbnail:Number):void {
			deactivateFilmstripButtons();

			resetThumbnails(false);

			setChildIndex(fadeOutOverlay, numChildren - 1);
			// setChildIndex(thumbnails[newActiveThumbnail], numChildren - 1);
			TweenLite.to(thumbnails[newActiveThumbnail], 0.5, 
						{x: filmstripPadding, 
						 y: filmstripPadding,
				 rotationY: 0,
						 z: 0,
					 alpha: 0,
					  ease:Power2.easeOut}
			);

			var activeFilmstripXDirection:Number = (newActiveThumbnail > activeThumbnail) ? -1 : 1;			

			var time:ca.ubc.ece.hct.Range = new Range(thumbnails[newActiveThumbnail].startTime, thumbnails[newActiveThumbnail].endTime);

			if(inactiveFilmstrip != null)
				inactiveFilmstrip.reset(_video, time.start, time.end);
			else {
				inactiveFilmstrip = new WebSimpleFilmstrip(_video, _width - filmstripPadding*2, _height - filmstripPadding*2, 1, time.start, time.end);
				inactiveFilmstrip.selectedSignal.add(sendSelected);
				inactiveFilmstrip.filmstripMouseMoveSignal.add(seek);
				inactiveFilmstrip.drawHighlights();
			}
			inactiveFilmstrip.x = (activeFilmstripXDirection == -1) ? _width : 0;
			inactiveFilmstrip.y = filmstripPadding;
			inactiveFilmstrip.alpha = 1;
			addChild(inactiveFilmstrip);


			setChildIndex(activeFilmstrip, numChildren - 1);
			if(contains(nextFilmstripButton))
				setChildIndex(nextFilmstripButton, numChildren - 1);
			if(contains(previousFilmstripButton))
				setChildIndex(previousFilmstripButton, numChildren - 1);
			setChildIndex(closeFilmstripButton, numChildren - 1);
			setChildIndex(captionView, numChildren - 1);

			TweenLite.to(activeFilmstrip, 0.5,
						{x: activeFilmstripXDirection * _width,
					 alpha: 0,
					  ease: Power0.easeNone,
			    onComplete: function filmstripFinishedAnimating():void {
					  			activateFilmstripButtons();
					  		}
					  	});

			TweenLite.to(inactiveFilmstrip, 0.5,
						{x: filmstripPadding,
					  ease: Back.easeOut });

			var tempFilmstrip:WebSimpleFilmstrip = activeFilmstrip;
			activeFilmstrip = inactiveFilmstrip;
			inactiveFilmstrip = tempFilmstrip;

			if(newActiveThumbnail == thumbnails.length - 1) {
				TweenLite.to(nextFilmstripButton, 0.15,
							{alpha: 0,
						onComplete: function removeNextFilmstripButton():void {
										removeChild(nextFilmstripButton);
									}});
			}

			if(newActiveThumbnail == 0) {
				TweenLite.to(previousFilmstripButton, 0.15,
							{alpha: 0,
						onComplete: function removePreviousFilmstripButton():void {
										removeChild(previousFilmstripButton);
									}});
			}

			if(newActiveThumbnail != 0 && !contains(previousFilmstripButton)) {
				addChild(previousFilmstripButton)
				previousFilmstripButton.alpha = 1;
				TweenLite.to(nextFilmstripButton, 0.15,
							{alpha: 1});
			}

			activeThumbnail = newActiveThumbnail;
		}

		private function activateFilmstripButtons():void {
			fadeOutOverlay.addEventListener(MouseEvent.CLICK, fadeOutOverlayClick);
			nextFilmstripButton.addEventListener(MouseEvent.CLICK, nextFilmstripButtonClick);
			previousFilmstripButton.addEventListener(MouseEvent.CLICK, previousFilmstripButtonClick);
			closeFilmstripButton.addEventListener(MouseEvent.CLICK, closeFilmstripButtonClick);
		}

		private function deactivateFilmstripButtons():void {
			fadeOutOverlay.removeEventListener(MouseEvent.CLICK, fadeOutOverlayClick);
			nextFilmstripButton.removeEventListener(MouseEvent.CLICK, nextFilmstripButtonClick);
			previousFilmstripButton.removeEventListener(MouseEvent.CLICK, previousFilmstripButtonClick);
			closeFilmstripButton.removeEventListener(MouseEvent.CLICK, closeFilmstripButtonClick);
		}

		private function nextFilmstripButtonClick(e:MouseEvent):void {
			actionLogSignal.dispatch("Slidestrip: Next filmstrip: #" + (activeThumbnail+1) + " " + thumbnails[activeThumbnail+1].intervalString);

			swapFilmstripCommon(Math.min(thumbnails.length - 1, activeThumbnail + 1));

		}

		private function previousFilmstripButtonClick(e:MouseEvent):void {

			actionLogSignal.dispatch("Slidestrip: Previous filmstrip: #" + (activeThumbnail-1) + " " + thumbnails[activeThumbnail-1].intervalString);
			swapFilmstripCommon(Math.max(0, activeThumbnail - 1));
		}

		private function closeFilmstripButtonClick(e:MouseEvent):void {

			actionLogSignal.dispatch("Slidestrip: Close filmstrip");
			closeFilmstrip();
		}

		private function fadeOutOverlayClick(e:MouseEvent):void {
			closeFilmstrip();
		}

		private function closeFilmstrip():void {
			fadeOutOverlay.removeEventListener(MouseEvent.CLICK, fadeOutOverlayClick);
			closeFilmstripButton.removeEventListener(MouseEvent.CLICK, closeFilmstripButtonClick);

			activeFilmstrip.filmstripClosed.addOnce(removeFilmstrip);
			activeFilmstrip.retract();
		}

		private function removeFilmstrip():void {
			TweenLite.to(activeFilmstrip, 0.25,
						{alpha: 0,
					onComplete: function removeFilmstrip():void {
									removeChild(activeFilmstrip);
								}});
			TweenLite.to(fadeOutOverlay, 0.15,
						{alpha: 0,
					onComplete: function removeFadeoutOverlay():void {
									removeChild(fadeOutOverlay);
								}});
			TweenLite.to(closeFilmstripButton, 0.15,
						{alpha: 0,
					onComplete: function removeCloseFilmstripButton():void {
									removeChild(closeFilmstripButton);
								}});
			TweenLite.to(nextFilmstripButton, 0.15,
						{alpha: 0,
					onComplete: function removeNextFilmstripButton():void {
									if(contains(nextFilmstripButton))
										removeChild(nextFilmstripButton);
								}});
			TweenLite.to(previousFilmstripButton, 0.15,
						{alpha: 0,
					onComplete: function removePreviousFilmstripButton():void {
									if(contains(previousFilmstripButton))
										removeChild(previousFilmstripButton);
								}});
			TweenLite.to(captionView, 0.15,
						{alpha: 0,
					onComplete: function removeCaptionView():void {
									removeChild(captionView);

									for(var i:int = 0; i<thumbnails.length; i++) {
										setChildIndex(thumbnails[i], numChildren - 1);
									}
								}});
			TweenLite.to(thumbnails[activeThumbnail], 0.5, 
						{x: thumbnailOffset + activeThumbnail/thumbnails.length * (_width-thumbnailOffset*2),
						 y: _height * 0.1,
						 z: 0,
				 rotationY: thumbnailRot,
					 alpha: 1,
					  ease: Power2.easeOut });

			if(contains(interactiveSlideThumbnail))
				removeChild(interactiveSlideThumbnail)

			resetThumbnails(true);

			addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
			// addEventListener(MouseEvent.CLICK, mouseClick);
		}

		private function activeFilmstripClicked(currentTime:Number, newTime:Number):void {
			sendSeek(newTime);
		}

		private function sendSeek(time:Number):void {
			seeked.dispatch(time);
		}

		private function sendSelected(interval:ca.ubc.ece.hct.Range):void {
			selected.dispatch(interval);
		}

		public function seek(time:Number):void {
			captionSeek(time);
		}

		private var currentDisplayCaptionTime:Number = 0;
		private function captionSeek(time:Number):void {

			if(_video.getSources("vtt")[0]) {

				var captions:VideoCaptions = _video.getSources("vtt")[0].captions;
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

		private function gaussian(x:Number, a:Number, b:Number, c:Number):Number {
			return a * Math.exp(-Math.pow(x-b, 2)/2*Math.pow(c,2));
		}

		private function bubbleActionLog(message:String):void {
			trace(message + "...")
			actionLogSignal.dispatch(message);
		}

	}
}

import flash.display.Sprite;
import flash.events.MouseEvent;

class SwitchFilmstripButton extends Sprite {

	public static const LEFT:String = "left";
	public static const RIGHT:String = "right";

	private var _width:Number, _height:Number;
	private var _leftRight:String;

	public function SwitchFilmstripButton(width:Number, height:Number, leftRight:String) {

		_width = width;
		_height = height;

		_leftRight = leftRight;
		drawNeutral();
		addEventListener(MouseEvent.ROLL_OVER, rollOver);
		addEventListener(MouseEvent.ROLL_OUT, rollOut);
	}

	private function rollOver(e:MouseEvent):void {
		drawHover();
	}

	private function rollOut(e:MouseEvent):void {
		drawNeutral();
	}

	private function drawNeutral():void {
		drawBackground();
		drawArrow();
	}

	private function drawHover():void {
		drawBackground(true);
		drawArrow();
	}

	private function drawBackground(hover:Boolean = false):void {
		graphics.clear();
		if(!hover)
			graphics.beginFill(0, 0.5);
		else
			graphics.beginFill(0x666666, 0.8);
		graphics.drawRoundRect(0, 0, _width, _height, 5);
		graphics.endFill();
	}

	private function drawArrow():void {
		graphics.lineStyle(2, 0xcccccc);
		if(_leftRight == RIGHT) {
			graphics.moveTo(10, _height/2 - (_width - 20));
			graphics.lineTo(_width - 10, _height/2);
			graphics.lineTo(10, _height/2 + (_width - 20));
		} else {
			graphics.moveTo(_width - 10, _height/2 - (_width - 20));
			graphics.lineTo(10, _height/2);
			graphics.lineTo(_width - 10, _height/2 + (_width - 20));
		}
	
	}
}
