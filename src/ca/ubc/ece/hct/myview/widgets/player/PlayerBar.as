////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {

import ca.ubc.ece.hct.ImageLoader;
import ca.ubc.ece.hct.myview.thumbnail.Thumbnail;
import ca.ubc.ece.hct.myview.ui.DropdownMenu;
import ca.ubc.ece.hct.myview.ui.DropdownMenuItem;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import fl.transitions.Tween;
import fl.transitions.TweenEvent;
import fl.transitions.easing.*;

import flash.display.Sprite;
import flash.events.*;
import flash.text.TextField;
import flash.text.TextFormat;

import org.osflash.signals.Signal;

public class PlayerBar extends Sprite {

		private static const SEEKBAR_HEIGHT:Number = 18; // top 10 of this height is invisible :D
		public static const TOOLBAR_HEIGHT:Number = 27;

		public static const PLAYERBAR_HEIGHT:Number = SEEKBAR_HEIGHT + TOOLBAR_HEIGHT;
		private static const CUT_OFF_RATIO:Number = 0.5;

		public static const PLAYBACK_RATES:Array = [0.5, 1, 1.25, 1.5, 2];

		private var _width:Number;

		private var playButton:ImageLoader;
		public var playSignal:Signal;
		private var ccButton:ImageLoader;
		public var ccSignal:Signal;
		private var enlargeButton:ImageLoader;
		public var enlargeSignal:Signal;
		private var seekPoint:ImageLoader;
		private var timeLabel:TextField;
		// private var playbackRateSlider:Slider;
		private var playbackRateLabel:TextField;
		private var playbackRateDropdownMenu:DropdownMenu;
		public var playbackRateSignal:Signal;
		public var seekSignal:Signal;
		// private var playbackRateChange:Signal;

		private var seekbarHeight:Number;
		private var seekbarY:Number;
		private var toolbarY:Number;
		private static const tweenLength:Number = 0.1;
		private var tweenFinished:Boolean = true;
		private var minimized:Boolean = false;

		private var playState:Boolean;
		private var ccState:Boolean;
		private var enlargeState:Boolean = false;

		private var seekbar:Sprite;
		private var seekbarEnabled:Boolean = false;
		private var toolbar:Sprite;
		private var viewCountVisualization:Sprite;
		private var previewThumbnail:Thumbnail;
		private var previewText:TextField;
		private var previewTextBackground:Sprite;

		private var _video:VideoMetadata;
		private var currentPlayTime:Number;
		// private var totalPlayTime:Number;

		// turn off animations when resizing please.
		public var allowAnimation:Boolean = true;

		// tweens
		private var toolbarYTween:Tween;
		private var toolbarHeightTween:Tween;
		private var seekbarYTween:Tween;
		private var seekbarHeightTween:Tween;
		private var seekPointAlphaTween:Tween;
		private var seekPointYTween:Tween;

		private var highlightSprite:Sprite;

		public var actionLogSignal:Signal;

		public function PlayerBar(video:VideoMetadata, width:Number, totalTime:Number) {
			super();
			_video = video;
			// totalPlayTime = totalTime;
			currentPlayTime = 0;
			_width = width;

			toolbar = new Sprite();
			toolbar.y = SEEKBAR_HEIGHT;
			drawToolbar();
			addChild(toolbar);

			seekbar = new Sprite();
			seekbar.y = 0;
			drawSeekbar();
			addChild(seekbar);
			seekbar.addEventListener(MouseEvent.MOUSE_OVER, seekbar_mouseOver);
			seekbar.addEventListener(MouseEvent.MOUSE_OUT, seekbar_mouseOut);
			seekbar.addEventListener(MouseEvent.MOUSE_MOVE, seekbar_mouseMove);
			seekbar.addEventListener(MouseEvent.CLICK, seekbar_click);

			previewThumbnail = new Thumbnail();
//			previewThumbnail.init(_video, 240, 240 * _video.source[_video.primarySource].height/_video.source[_video.primarySource].width);
			// previewThumbnail.width = 150;
			// previewThumbnail.height = 80;
			previewThumbnail.y = -previewThumbnail.height - 8;
			previewThumbnail.touchable = false;
			previewText = new TextField();
			previewText.text = "00:00";
			previewText.width = 34;
			previewText.height = 13;
			previewText.y = previewThumbnail.y + previewThumbnail.height - previewText.height;
			previewText.textColor = 0xffffff;
			previewText.mouseEnabled = false;
			previewTextBackground = new Sprite();

			playButton = new ImageLoader("uiimage/playerbar/play.png");
			// playButton.load(new URLRequest("uiimage/playerbar/play.png"));
			// playButton.y = SEEKBAR_HEIGHT + 10;
			playSignal = new Signal(Boolean);
			playButton.addEventListener(MouseEvent.CLICK, playButtonPressed);

			enlargeButton = new ImageLoader("uiimage/playerbar/fullscreen.png");
			// enlargeButton.load(new URLRequest("uiimage/playerbar/fullscreen.png"));
			enlargeButton.x = _width - 44;
			enlargeSignal = new Signal();
			// enlargeButton.y = SEEKBAR_HEIGHT + 10;
			enlargeButton.addEventListener(MouseEvent.CLICK, enlargeButtonPressed);

			ccButton = new ImageLoader("uiimage/playerbar/cc_off.png");
			// ccButton.load(new URLRequest("uiimage/playerbar/cc_off.png"));
			ccButton.x = enlargeButton.x - 44;
			ccSignal = new Signal();
			// ccButton.y = SEEKBAR_HEIGHT + 10;
			ccButton.addEventListener(MouseEvent.CLICK, ccButtonPressed);

			playbackRateLabel = new TextField();
			playbackRateLabel.selectable = false;
			playbackRateLabel.defaultTextFormat = new TextFormat("Arial", 10, 0xFFFFFF, true, false, false, null, null, "center", null, null, null, 4);
			playbackRateLabel.autoSize = "right";
			playbackRateLabel.text = "1.0X";
			playbackRateSignal = new Signal(Number);
			// playbackRateLabel.mouseEnabled = false;
			playbackRateLabel.x = ccButton.x - playbackRateLabel.width - 10;//playbackRateSlider.x - playbackRateLabel.width - 10;
			playbackRateLabel.y = 5;
			playbackRateLabel.addEventListener(MouseEvent.CLICK,
				function playbackRateClick(e:MouseEvent):void {
					if(!contains(playbackRateDropdownMenu))
						addChild(playbackRateDropdownMenu);
					else
						removeChild(playbackRateDropdownMenu);
				});

			playbackRateDropdownMenu = new DropdownMenu();
			playbackRateDropdownMenu.itemClicked.add(
				function playbackRateChanged(val:Object):void {
					playbackRateLabel.text = (val as Number).toString() + "X";
					playbackRateSignal.dispatch(val as Number);
				});
			playbackRateDropdownMenu.closeMe.add(
				function closePlaybackRateDropdownMenu():void {
					if(contains(playbackRateDropdownMenu)) {
						removeChild(playbackRateDropdownMenu);
					}
				});
			for(var i:int = 0; i<PLAYBACK_RATES.length; i++) {
				var item:DropdownMenuItem = new DropdownMenuItem(PLAYBACK_RATES[i].toString() + "X", null, PLAYBACK_RATES[i]);
				item.toggleAble = true;
				item.toggleActive = (PLAYBACK_RATES[i] == 1);
				playbackRateDropdownMenu.addDropdownMenuItem(item);
			}
			playbackRateDropdownMenu.x = playbackRateLabel.x;
			playbackRateDropdownMenu.y = -playbackRateDropdownMenu.height;

			seekPoint = new ImageLoader("uiimage/seekPoint.png");
			// seekPoint.load(new URLRequest("uiimage/seekPoint.png"));
			seekPoint.y = 6;
			seekPoint.mouseEnabled = false;

			seekSignal = new Signal(Number, Number); // new Signal(oldTime, newTime);

			timeLabel = new TextField();
			// timeLabel.textColor = 0xffffff;
			timeLabel.width = 200;
			timeLabel.height = 15;
			timeLabel.y = toolbar.height/2 - timeLabel.height/2;
			timeLabel.mouseEnabled = false;
			timeLabel.x = 50; // uiimage/play.png is 44 pixels wide

			timeLabel.defaultTextFormat = new TextFormat("Arial", 10, 0xFFFFFF);

			toolbar.addChild(playButton);
			toolbar.addChild(enlargeButton);
			toolbar.addChild(ccButton);
			// toolbar.addChild(playbackRateSlider);
			toolbar.addChild(playbackRateLabel);
			toolbar.addChild(timeLabel);

			// viewCountVisualization = new Sprite();
			// viewCountVisualization.mouseEnabled = false;
			// viewCountVisualization.addEventListener(MouseEvent.MOUSE_OVER, seekbar_mouseOver);
			// viewCountVisualization.addEventListener(MouseEvent.MOUSE_MOVE, seekbar_mouseMove);
			// addChild(viewCountVisualization);
			addChild(seekPoint);
			setPlayTime(0);

			seekbarY = seekbar.y;
			toolbarY = toolbar.y;
			seekbarHeight = seekbar.height;

			highlightSprite = new Sprite();
			// addChild(highlightSprite);
			// highlightSprite.alpha = 0;
			highlightSprite.mouseEnabled = false;
			drawHighlights();

			actionLogSignal = new Signal(String);

		}

		public function set video(val:VideoMetadata):void {
			_video = val;
//			previewThumbnail.video = val;
		}

		public function resize(width:Number):void {
			_width = width;
			this.graphics.clear();
			this.graphics.beginFill(0x1b1b1b1b, 0.8);
			this.graphics.drawRect(0, 0, width, TOOLBAR_HEIGHT);
			this.graphics.endFill();

			seekbar.graphics.clear();
			seekbar.graphics.beginFill(0x777777, seekbarEnabled ? 1 : 0);
			seekbar.graphics.drawRect(0, 0, width, SEEKBAR_HEIGHT);
			seekbar.graphics.endFill();

			enlargeButton.x = _width - 44;
		}

		public function play():void {
			if(playState != true) {
				playState = true;
				playButton.load("uiimage/playerbar/pause.png");
				playButton.removeEventListener(MouseEvent.CLICK, playButtonPressed);
				playButton.addEventListener(MouseEvent.CLICK, pauseButtonPressed);
			}
		}

		public function pause():void {
			if(playState != false) {
				playState = false;
				playButton.load("uiimage/playerbar/play.png");
				playButton.removeEventListener(MouseEvent.CLICK, pauseButtonPressed);
				playButton.addEventListener(MouseEvent.CLICK, playButtonPressed);
			}
		}

		public function enlarge():void {
			enlargeState = !enlargeState
			if(enlargeState == true) {
				enlargeButton.load("uiimage/playerbar/unfullscreen.png");
				enlargeButton.removeEventListener(MouseEvent.CLICK, unenlargeButtonPressed);
				enlargeButton.addEventListener(MouseEvent.CLICK, enlargeButtonPressed);
			} else {
				enlargeButton.load("uiimage/playerbar/fullscreen.png");
				enlargeButton.removeEventListener(MouseEvent.CLICK, enlargeButtonPressed);
				enlargeButton.addEventListener(MouseEvent.CLICK, unenlargeButtonPressed);
			}
		}

		// public function unenlarge():void {
			// enlargeState = false;
			// enlargeButton.load(new URLRequest("uiimage/playerbar/fullscreen.png"));
			// enlargeButton.removeEventListener(MouseEvent.CLICK, unenlargeButtonPressed);
			// enlargeButton.addEventListener(MouseEvent.CLICK, enlargeButtonPressed);
		// }

		public function setPlayTime(timeX:Number):void {
			currentPlayTime = timeX;
			timeLabel.text = timeInSecondsToTimeString(timeX) + " / " + timeInSecondsToTimeString(_video.duration);
			seekPoint.x = currentPlayTime/_video.duration * _width - seekPoint.width/2;

			drawSeekbar(currentPlayTime/_video.duration);
			if(highlightSprite && contains(highlightSprite))
				drawHighlights();
		}

		public function setPlaybackRate(val:Number):void {
			playbackRateLabel.text = val.toString() + "X";
		}

		public function enableSeekbar():void {
			seekbarEnabled = true;
			seekbar.mouseEnabled = true;
			seekPoint.alpha = 1;
			// highlightSprite.alpha = 1;
			drawSeekbar(currentPlayTime/_video.duration);
			if(!contains(highlightSprite))
				addChild(highlightSprite);
		}

		public function disableSeekbar():void {
			seekbarEnabled = false;
			seekbar.mouseEnabled = false;
			seekPoint.alpha = 0;
			drawSeekbar(currentPlayTime/_video.duration);
			if(contains(highlightSprite))
				removeChild(highlightSprite);
		}

		// change 100 to 1:40~
		public function timeInSecondsToTimeString(timeX:Number):String {
			var newMinutes:String = uint(timeX/60).toString();
			newMinutes = newMinutes.length == 1 ? "0" + newMinutes : newMinutes;
			var newSeconds:String = uint(timeX%60).toString();
			newSeconds = newSeconds.length == 1 ? "0" + newSeconds : newSeconds;
			return newMinutes + ":" + newSeconds;
		}

		private function playButtonPressed(e:MouseEvent):void {
			actionLogSignal.dispatch("PlayerBar: Pressed Play button.");
			playSignal.dispatch(true);
		}

		private function pauseButtonPressed(e:MouseEvent):void {
			actionLogSignal.dispatch("PlayerBar: Pressed Pause button.");
			playSignal.dispatch(false);
		}

		private function enlargeButtonPressed(e:MouseEvent):void {
			actionLogSignal.dispatch("PlayerBar: Pressed Enlarge Button.");
			enlarge();
			enlargeSignal.dispatch();
		}

		private function unenlargeButtonPressed(e:MouseEvent):void {
			actionLogSignal.dispatch("PlayerBar: Pressed Unenlarge Button.");
			enlarge();
			enlargeSignal.dispatch();
		}

		private function ccButtonPressed(e:MouseEvent):void {
			ccState = !ccState;
			if(ccState) {
				ccButton.load("uiimage/playerbar/cc_on.png");
			} else {
				ccButton.load("uiimage/playerbar/cc_off.png");
			}
			actionLogSignal.dispatch("PlayerBar: Pressed CC Button.");
			ccSignal.dispatch();
		}

		private function seekbar_mouseOver(e:MouseEvent):void {
//			addChild(previewThumbnail);
			addChild(previewTextBackground);
			addChild(previewText);
		}

		private function seekbar_mouseOut(e:MouseEvent):void {
//			removeChild(previewThumbnail);
			removeChild(previewText);
			removeChild(previewTextBackground);
		}

		private function seekbar_mouseMove(e:MouseEvent):void {
			previewThumbnail.seekNormalized(e.localX / _width);
			var previewThumbnailX:Number = e.localX - previewThumbnail.width/2
			previewThumbnailX = e.localX - previewThumbnail.width/2;
			if(previewThumbnailX < 0)
				previewThumbnail.x = 0;
			else if(previewThumbnailX + previewThumbnail.width > _width)
				previewThumbnail.x = _width - previewThumbnail.width;
			else
				previewThumbnail.x = previewThumbnailX;

			previewText.text = timeInSecondsToTimeString(e.localX/_width * _video.duration);
			previewText.x = previewThumbnail.x + previewThumbnail.width/2 - previewText.width/2;
			previewTextBackground.graphics.clear();
			previewTextBackground.graphics.beginFill(0x333333, 0.5);
			previewTextBackground.graphics.drawRoundRect(previewText.x, previewText.y, previewText.width, previewText.height, 10);
			previewTextBackground.graphics.endFill();
		}

		private function seekbar_click(e:MouseEvent):void {
			setPlayTime(e.localX/_width * _video.duration);
			seekSignal.dispatch(currentPlayTime, e.localX/_width * _video.duration);
		}

		private function drawToolbar():void {
			toolbar.graphics.clear();
			// if(Main.DEBUG)
			// 	toolbar.graphics.lineStyle(1, 0xff0000)
			toolbar.graphics.beginFill(0x1b1b1b1b, 0.9);
			toolbar.graphics.drawRect(0, 0, _width, TOOLBAR_HEIGHT);
			toolbar.graphics.endFill();
		}

		private function drawSeekbar(split:Number = 0):void {
			seekbar.graphics.clear();
			// if(Main.DEBUG)
			// 	seekbar.graphics.lineStyle(1, 0xffccf);
			seekbar.graphics.beginFill(0xFF00ff, 0);
			seekbar.graphics.drawRect(0, 0, width, 10);
			seekbar.graphics.endFill();

			seekbar.graphics.beginFill(0x777777, seekbarEnabled ? 1 : 0);
			seekbar.graphics.drawRect(0, 10, width, SEEKBAR_HEIGHT - 10);
			seekbar.graphics.endFill();
			seekbar.graphics.beginFill(0xff0000, seekbarEnabled ? 1 : 0);
			seekbar.graphics.drawRect(0, 10, split * _width, SEEKBAR_HEIGHT - 10);
			seekbar.graphics.endFill();
		}

		public function drawHighlights():void {

			// if(_video.userData.highlights.values()) {
			// 	highlightSprite.graphics.clear();
			// 	var totalTime:Number = _video.duration;
			// 	var highlightWidth:Number = _width / totalTime;

			// 	var lineThickness:Number = 4;//_height/video.highlightColours.length;
			// 	highlightSprite.graphics.beginFill(0, 0.3);
			// 	highlightSprite.graphics.drawRect(0, 0, _width, _video.userData.highlights.values().length * lineThickness);
			// 	highlightSprite.graphics.endFill();

			// 	for(var i:int = 0; i<_video.userData.highlights.values().length; i++) {

			// 		for(var j:int = 0; j<_video.userData.highlights[i].length; j++) {

			// 			if(0 <= _video.userData.highlights[i][j].end && _video.duration >= _video.userData.highlights[i][j].start) {
							
			// 				var start:Number = (_video.userData.highlights[i][j].start)/totalTime * _width;
			// 				var end:Number = (_video.userData.highlights[i][j].end)/totalTime * _width;
			// 				if(start < 0)
			// 					start = 0;
			// 				if(end > _width)
			// 					end = _width;

			// 				highlightSprite.graphics.beginFill(Util.changeSaturation(_video.userData.highlights.values()[i], 3), 1);
			// 				highlightSprite.graphics.drawRect(start, (i)*lineThickness, (end-start), lineThickness);
			// 				highlightSprite.graphics.endFill();

			// 				highlightSprite.graphics.beginFill(Util.brighten(_video.userData.highlights.values()[i], 1.1), 1);
			// 				highlightSprite.graphics.drawRect(start, (i)*lineThickness, end-start, 1);
			// 				highlightSprite.graphics.endFill();
			// 				highlightSprite.graphics.beginFill(Util.brighten(_video.userData.highlights.values()[i], 0.9), 1);
			// 				highlightSprite.graphics.drawRect(start, (i+1)*lineThickness-1, end-start, 1);
			// 				highlightSprite.graphics.endFill();
			// 			}
			// 		}
			// 	}
			// 	highlightSprite.y = SEEKBAR_HEIGHT - 8 - highlightSprite.height;
			// }
		}

		public function maximize():void {
			if(tweenFinished && minimized && allowAnimation) {
				tweenFinished = false;
				toolbarYTween = new Tween(toolbar, "y", None.easeNone, toolbar.y, toolbarY, tweenLength, true);
				toolbarHeightTween = new Tween(toolbar, "height", None.easeNone, 0, TOOLBAR_HEIGHT, tweenLength, true);


				seekbarYTween = new Tween(seekbar, "y", None.easeNone, seekbar.y, seekbarY, tweenLength, true);
				seekbarHeightTween = new Tween(seekbar, "height", None.easeNone, seekbar.height, seekbarHeight, tweenLength, true);

				seekPointYTween = new Tween(seekPoint, "y", None.easeNone, seekPoint.y, 6, tweenLength, true);
				seekPointAlphaTween = new Tween(seekPoint, "alpha", None.easeNone, 0, seekbarEnabled ? 1 : 0, tweenLength, true);
				seekPointAlphaTween.addEventListener(TweenEvent.MOTION_FINISH,
					function tweenFinished(e:TweenEvent):void {
						tweenFinished = true;
						minimized = false;
						// trace("maximized height = " + height);
					});
			}
		}

		public function minimize():void {
			if(tweenFinished && !minimized && allowAnimation) {

				tweenFinished = false;

				seekbarYTween = new Tween(seekbar, "y", None.easeNone, seekbarY, PLAYERBAR_HEIGHT - 10, tweenLength, true);
				seekbarHeightTween = new Tween(seekbar, "height", None.easeNone, seekbar.height, 10, tweenLength, true);

				toolbarYTween = new Tween(toolbar, "y", None.easeNone, toolbarY, PLAYERBAR_HEIGHT, tweenLength, true);
				toolbarHeightTween = new Tween(toolbar, "height", None.easeNone, toolbar.height, 0, tweenLength, true);

				seekPointYTween = new Tween(seekPoint, "y", None.easeNone, seekPoint.y, PLAYERBAR_HEIGHT - 4, tweenLength, true);
				seekPointAlphaTween = new Tween(seekPoint, "alpha", None.easeNone, seekbarEnabled ? 1 : 0, 0, tweenLength, true);
				seekPointAlphaTween.addEventListener(TweenEvent.MOTION_FINISH,
					function tweenFinished(e:TweenEvent):void {
						tweenFinished = true;
						minimized = true;
						// trace("minimized height = " + height);
					});
			}
		}

		override public function set width(val:Number):void {

			_width = val;

			drawSeekbar(currentPlayTime/_video.duration);

			drawToolbar();
			drawHighlights();

			enlargeButton.x = _width - 44;
			ccButton.x = enlargeButton.x - 44;
			// playbackRateSlider.x = ccButton.x - playbackRateSlider.width - 10;
			playbackRateLabel.x = ccButton.x - playbackRateLabel.width - 10;//playbackRateSlider.x - playbackRateLabel.width - 10;
			playbackRateDropdownMenu.x = playbackRateLabel.x;

		}
	}
}