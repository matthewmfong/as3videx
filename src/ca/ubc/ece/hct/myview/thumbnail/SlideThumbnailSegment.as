////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {
import ca.ubc.ece.hct.ImageLoader;
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import com.greensock.*;

import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.utils.Timer;

import org.osflash.signals.Signal;

public class SlideThumbnailSegment extends WebThumbnailSegment {

		public static const BALL_RADIUS:Number = 10;
		public static const LEFT:String = "left";
		public static const CENTER:String = "centre";

		private var _video:VideoMetadata;
		private var highlightBalls:Vector.<Sprite>;
		private var highlightBallsLocation:String = LEFT;
		private var mouseOverTimer:Timer;
		private var highlightButton:ImageLoader;
		private var playButton:ImageLoader;
		private var toolBackground:Shape;
		private var _highlightColours:Array; public function get highlightColours():Array { return _highlightColours; }

		private var playhead:Shape;

		public var clickSignal:Signal;
		public var seeked:Signal;
		public var actionLogSignal:Signal;

		public function SlideThumbnailSegment(video:VideoMetadata, width:Number, height:Number, interval:ca.ubc.ece.hct.Range) {
			super(video, width, height, interval.start, interval.end, false);

			_video = video;
			interactive = false;

			clickSignal = new Signal(); // interval
			seeked = new Signal(Number); // seek time
			actionLogSignal = new Signal(String);

			playhead = new Shape();
			playhead.graphics.beginFill(0xff0000);
			playhead.graphics.drawCircle(0, 0, 2);
			playhead.graphics.endFill();
			playhead.y = height - playhead.height;

			drawHighlights(_video.userData.getHighlightedColoursforTimeRange(interval));

			toolBackground = new Shape();
			toolBackground.graphics.beginFill(0xfffffff, 0.6);
			toolBackground.graphics.drawRoundRect(0, 0, width * 0.1, height * 0.3, 5);
			toolBackground.graphics.endFill();
			toolBackground.y = height - toolBackground.height;
			toolBackground.alpha = 0;
			addChild(toolBackground);

			playButton = new ImageLoader("uiimage/playerbar/play.png");
			playButton.addEventListener(Event.COMPLETE,
				function positionHighlightButton(e:Event):void {	
					playButton.x = width/2 - playButton.width/2;
					playButton.y = highlightButton.y - playButton.height;
					// playButton.width = playButton.width/1.5;
					// playButton.height = playButton.height/1.5;
					playButton.alpha = 0;
				});
			playButton.addEventListener(MouseEvent.CLICK,
				function playButtonClicked(e:MouseEvent):void {
					actionLogSignal.dispatch("ca.ubc.ece.hct.myview.thumbnail.SlideThumbnailSegment" + this.intervalString + ": Clicked play");
					seeked.dispatch(startTime);
				});

			highlightButton = new ImageLoader("uiimage/highlight.png");
			highlightButton.addEventListener(MouseEvent.ROLL_OVER, highlightButtonRollOver);
			highlightButton.addEventListener(Event.COMPLETE,
				function positionHighlightButton(e:Event):void {	
					highlightButton.x = width/2 - highlightButton.width/2;
					highlightButton.y = height - highlightButton.height + 5;
					highlightButton.width = highlightButton.width/1.5;
					highlightButton.height = highlightButton.height/1.5;
					highlightButton.alpha = 0;

					playButton.y = highlightButton.y - playButton.height;
				});
			// if(contains(highlightButton)) {
			// 	removeChild(highlightButton);
			// }
			mouseOverTimer = new Timer(500);
			addEventListener(MouseEvent.ROLL_OVER,
				function mouseRollOver(e:MouseEvent):void {
					mouseOverTimer.addEventListener(TimerEvent.TIMER, timerUp);
					mouseOverTimer.start();
				});

			addEventListener(MouseEvent.CLICK, mouseClick);
			addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		}

		public function set playheadTime(time:Number):void {
			if(time >= startTime && time < endTime) {
				if(!contains(playhead))
					addChild(playhead);
				playhead.x = (time - startTime)/(endTime - startTime) * thumbnailWidth;
			} else {
				if(contains(playhead))
					removeChild(playhead);
			}
		}

		override public function mouseMove(e:MouseEvent):void {
			toolBackground.x = e.currentTarget.mouseX - toolBackground.width/2;
			highlightButton.x = e.currentTarget.mouseX - highlightButton.width/2;
			playButton.x = e.currentTarget.mouseX - playButton.width/2;

			if(highlightBallsLocation == CENTER) {
				for each(var ball:Sprite in highlightBalls) {
					TweenLite.to(ball, 0.1,
								{x: mouseX});
				}
			}
		}

		private function mouseClick(e:MouseEvent):void {
			// if(e.currentTarget.mouseX > highlightButton.x + highlightButton.width + 2 || 
						 // e.currentTarget.mouseX < highlightButton.x - 2) {
			if(e.target == this) {
				clickSignal.dispatch();
			}
			// }
		}

		private function highlightButtonRollOver(e:MouseEvent):void {

			actionLogSignal.dispatch("ca.ubc.ece.hct.myview.thumbnail.SlideThumbnailSegment" + this.intervalString + ": Rolled over highlight button");

			moveHighlightBallsToCentre();
			addEventListener(MouseEvent.MOUSE_MOVE,
				function mouseMovedOutofBoundsOfHighlights(e:MouseEvent):void {

					if( (e.currentTarget.mouseX > highlightButton.x + highlightButton.width + 2 || 
						 e.currentTarget.mouseX < highlightButton.x - 2) &&
						highlightBallsLocation != LEFT) {
						moveHighlightBallsToLeft();
					}
				});
		}

		private function timerUp(e:TimerEvent):void {
			mouseOverTimer.removeEventListener(TimerEvent.TIMER, timerUp);
			makeButtonsAppear();
		}

		public function makeButtonsAppear():void {
			toolBackground.alpha = 0;
			toolBackground.x = mouseX - toolBackground.width/2;

			TweenLite.to(toolBackground, 0.5, 
						{alpha: 1});
			addChild(toolBackground);

			highlightButton.alpha = 0;
			highlightButton.x = mouseX - highlightButton.width/2;

			TweenLite.to(highlightButton, 0.5, 
						{alpha: 1});
			addChild(highlightButton);

			playButton.alpha = 0;
			playButton.x = mouseX - playButton.width/2;
			TweenLite.to(playButton, 0.5, 
						{alpha: 1});
			addChild(playButton);

		}

		public function makeHighlightButtonDisappear():void {
			toolBackground.alpha = 0;
			if(contains(toolBackground))
				removeChild(toolBackground);

			highlightButton.alpha = 0;
			if(contains(highlightButton))
				removeChild(highlightButton);

			playButton.alpha = 0;
			if(contains(playButton))
				removeChild(playButton);
		}

		private function moveHighlightBallsToCentre():void {
			for(var i:int = 0; i<highlightBalls.length; i++) {

				var ball:Sprite = highlightBalls[i];

				if(contains(ball)) {

					TweenLite.to(ball, 0.35,
								{x: mouseX,
								 y: (BALL_RADIUS * 1.8 + 5) * i + BALL_RADIUS,
							 delay: 0.05 * i});
				} else {
					addChild(ball);
					ball.alpha = 0;
					ball.x = mouseX;
					ball.y = (BALL_RADIUS * 1.8 + 5) * i + BALL_RADIUS;
					TweenLite.to(ball, 0.35,
								{alpha: 1,
								 delay: 0.1 * i,
							onComplete: function ballsMovedCentre():void {
											highlightBallsLocation = CENTER;
										}
								});
				}

			}
		}

		private function moveHighlightBallsToLeft():void {
			var ballsAdded:uint = 0;

			for(var i:int = 0; i<highlightBalls.length; i++) {

				var ball:Sprite = highlightBalls[i];

				if(_highlightColours.indexOf(Colours.colours[i]) > -1) {

					TweenLite.to(ball, 0.35,
								{x: 0,
								 y: (BALL_RADIUS * 2 + 5) * ballsAdded + BALL_RADIUS});
					ballsAdded++;
				} else {
					TweenLite.to(ball, 0.35,
								{alpha: 0,
					  onCompleteParams: [ball],
							onComplete: function removeBall(p:Sprite):void {
											if(contains(p))
												removeChild(p);
											highlightBallsLocation = LEFT;
								}});
				}

			}

		}

		public function drawHighlights(highlightColours:Array):void {
			_highlightColours = highlightColours;

			if(highlightBalls == null) {
				highlightBalls = new Vector.<Sprite>();
			}

			while(highlightBalls.length > 0) {
				var ball:Sprite = highlightBalls.pop();
				if(contains(ball))
					removeChild(ball);
			}

			var ballsAdded:uint = 0;

			for(var i:int = 0; i<Colours.colours.length; i++) {

				highlightBalls.push(new Sprite());
				var ball:Sprite = highlightBalls[highlightBalls.length-1];

				ball.graphics.lineStyle(5, 0x333333, 0.4);
				ball.graphics.drawCircle(0, 0, BALL_RADIUS);

				ball.graphics.lineStyle(3, Util.brighten(Util.changeSaturation(Colours.colours[i], 5), 0.9));
				if(highlightColours.indexOf(Colours.colours[i]) > -1)
					ball.graphics.beginFill(Util.changeSaturation(Colours.colours[i], 2));
				else
					ball.graphics.beginFill(0xffffff);
				ball.graphics.drawCircle(0, 0, BALL_RADIUS);
				ball.graphics.endFill();

				ball.y = (BALL_RADIUS * 2 + 5) * ballsAdded + BALL_RADIUS ;

				if(highlightColours.indexOf(Colours.colours[i]) > -1) {
					ballsAdded++;
					addChild(ball);
				}

				ball.addEventListener(MouseEvent.CLICK, highlightBallClicked(Colours.colours[i]))
			}
		}

		private function highlightBallClicked(colour:Number):Function {
			return function(e:MouseEvent):void {


				actionLogSignal.dispatch("ca.ubc.ece.hct.myview.thumbnail.SlideThumbnailSegment" + intervalString + ": Highlighted in #" + colour.toString(16));
				var ball:Sprite = (Sprite)(e.currentTarget);

				var indexOfColour:Number = _highlightColours.indexOf(colour);

				if(indexOfColour < 0) {
					ball.graphics.beginFill(Util.changeSaturation(colour, 2));
				} else {
					ball.graphics.beginFill(0xffffff);
				}
				ball.graphics.drawCircle(0, 0, BALL_RADIUS);
				ball.graphics.endFill();

				if(indexOfColour < 0) {

					_highlightColours.push(colour);
					highlighted.dispatch(_video.filename, colour, new Range(startTime, endTime));
				} else {

					_highlightColours.splice(indexOfColour, 1);
					unhighlighted.dispatch(_video.filename, colour, new Range(startTime, endTime));
				}

			};
		}

		override public function set interval(range:ca.ubc.ece.hct.Range):void {
			super.startTime = range.start;
			super.endTime = range.end;
			drawHighlights(_video.userData.getHighlightedColoursforTimeRange(range));
			moveHighlightBallsToLeft();
		}

		override public function set startTime(val:Number):void {
			super.startTime = val;
			// drawHighlights(video.getHighlightedColoursforTimeRange(new Range(startTime, endTime)));
		}

		override public function set endTime(val:Number):void {
			super.endTime = val;
			// drawHighlights(video.getHighlightedColoursforTimeRange(new Range(startTime, endTime)));
		}
	}
}


