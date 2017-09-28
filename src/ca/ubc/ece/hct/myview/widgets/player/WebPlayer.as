////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.video.VideoCaptions;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import com.greensock.*;
	import com.greensock.easing.*;
	
	import org.osflash.signals.Signal;
	import ca.ubc.ece.hct.myview.widgets.pixie.Pixie;
	import ca.ubc.ece.hct.myview.widgets.pixie.PixieEvent;
	import ca.ubc.ece.hct.myview.widgets.subtitleviewer.Cue;
	// import ca.ubc.ece.hct.myview.video.Video;
	import ca.ubc.ece.hct.myview.widgets.player.WebPlayerBar;
	import ca.ubc.ece.hct.myview.widgets.player.IVideoPlayer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;


	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import flash.utils.Timer;
	import flash.events.TimerEvent;

	public class WebPlayer extends Sprite {

		private var _video:VideoMetadata;
		public function get video():VideoMetadata { return _video; }
		private var _player:IVideoPlayer;
		private var _playerOverlay:Sprite;
		private var _playerMask:Sprite;
		private var _playerBar:WebPlayerBar;
		private var _playerEnlarged:Boolean;
		private var _width:Number, _height:Number;
		private var _lastPlayedTime:Number;
		private var _viewCountRecordSnapshot:Array;

	    private var captionDisplay:TextField;
	    private var captionFormat:TextFormat;


		private var playSubsetTimer:Timer;

	    private var restrictPlayingCertainTimes:Boolean = false;
	    public var restrictPlayingCertainTimesSignal:Signal;
	    private var waitingForSeekForRestriction:Boolean = false;
	    private var timesAllowedToPlay:Array;
	    private var timesAllowedToPlayIndex:int;
	    private var highlightSprite:Sprite;

	    private var pix:Pixie;
		private var vcrTimer:Timer;
		private var lastUpdatedTime:int = -1;

		private var logPlayheadTimeTimer:Timer;
		private var pauseRecordUpdater:Timer;

		private var dynamicPlayBackSpeed:Boolean = false;
		private var currentPlaybackSpeed:Number = 1;
		private var predefinedPlaybackSpeed:Array;

		public var actionLogSignal:Signal;
		public var playerUpdateSignal:Signal;
		public var reachedEndOfVideoSignal:Signal;
		public var playbackRateChanged:Signal;

		public var idle:Boolean = false;

		public function WebPlayer(video:VideoMetadata, width:Number, height:Number, time:Number = 0) {
			_width = width;
			_height = height;
			_video = video;

			if(_video.userData.viewCountRecord)
				_viewCountRecordSnapshot = _video.userData.viewCountRecord.concat(); // create a snapshot

			// playSubsetTimer = new Timer(100);
			// playSubsetTimer.addEventListener(TimerEvent.TIMER, playNextSubset);

			_playerMask = new Sprite();
			_playerMask.graphics.beginFill(0, 0);
			_playerMask.graphics.drawRect(0, 0, _width, _height);
			_playerMask.graphics.endFill();
			this.mask = _playerMask;
			addChild(_playerMask);

			restrictPlayingCertainTimesSignal = new Signal(Boolean);


			var videoSource:Object = video.getSources("flv")[0];
			_player = new XVideoPlayer();
			_player.aspectRatio = videoSource.width/videoSource.height;
			addChild(_player);
			_player.x = 0;
			_player.y = 0;

			_player.width = width;
			_player.height = height - WebPlayerBar.PLAYERBAR_HEIGHT;
			
			_playerEnlarged = false;

			_lastPlayedTime = 0;

			_player.load(videoSource.url, null, video.duration, null);

			reachedEndOfVideoSignal = new Signal();
			playbackRateChanged = new Signal(Number);
			_player.playheadUpdateSignal.add(playerUpdate);
			_player.reachedEndOfVideoSignal.add(
				function reachedEndOfVideoDispatch():void {
					// trace("reached end");
					reachedEndOfVideoSignal.dispatch();
				});
			_player.playbackRateChanged.add(
				function playbackRateChangedDispatch(rate:Number):void {
					playbackRateChanged.dispatch(rate);
				});

			_playerOverlay = new Sprite();
			_playerOverlay.graphics.beginFill(0xff0000, 0);
			_playerOverlay.graphics.drawRect(_player.x, _player.y, _width, _height);
			_playerOverlay.graphics.endFill();
			addChild(_playerOverlay);
			_playerOverlay.addEventListener(MouseEvent.CLICK, playerClick);

			_playerBar = new WebPlayerBar(_video, _width, video.duration);
			// _playerBar.x = 0;
			// trace(_playerBar.height + " " + PlayerBar.PLAYERBAR_HEIGHT)
			// _playerBar.y = 0;//_height - PlayerBar.PLAYERBAR_HEIGHT;
			_playerBar.playSignal.add(
				function playerBarPlay(val:Boolean):void {
					if(val) {
						play();
					} else {
						stop();
					}
					});
			_playerBar.enlargeSignal.add(enlargeVideo);
			_playerBar.ccSignal.add(closedCaptions);
			_playerBar.seekSignal.add(playerBarSeek);
			_playerBar.playbackRateSignal.add(
				function changePlaybackRate(rate:Number):void {
					setPlaybackRate(rate);
				});
			addChild(_playerBar);

			_playerBar.showEnlarge = false;
			_playerBar.showPlaybackRate = false;

			_playerBar.actionLogSignal.add(bubbleActionLog);
			// _playerBar.play();
			// _playerBar.disableSeekbar();
			_playerBar.y = _height - WebPlayerBar.PLAYERBAR_HEIGHT;


	        captionFormat = new TextFormat("Arial", 18, 0xFFFFE8, true, false, false, null, null, "center", null, null, null, 4);
	        captionDisplay = new TextField();
			// if(video.captionsArray != null) {
				// captionsArray = video.captionsArray;

		        captionDisplay.defaultTextFormat = captionFormat;
		        captionDisplay.multiline = true;
		        captionDisplay.autoSize = "center";
		        captionDisplay.selectable = false;
		        captionDisplay.wordWrap = true;
		        captionDisplay.condenseWhite = true;
		        captionDisplay.htmlText = "";
		        captionDisplay.width = _player.width;
		        // captionDisplay.height = 80;
		        captionDisplay.x = _player.width/2 - captionDisplay.width/2;
		        captionDisplay.y = _height - WebPlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;
		        captionDisplay.filters = [new GlowFilter(0x000000, 1, 5, 5, 8, BitmapFilterQuality.MEDIUM)];
		        captionDisplay.mouseEnabled = false;
		        // addChild(captionDisplay);
			// }


			highlightSprite = new Sprite();

			// pix = new Pixie();
			// addChild(pix);
			// pix.width = 100;
			// pix.height = 100;

			// pix.x = pix.width/2 + 5;
			// pix.y = _height - _playerBar.height - pix.height/2 - 10;

			vcrTimer = new Timer(500);
			vcrTimer.addEventListener(TimerEvent.TIMER, updateViewCount);
			vcrTimer.start();

			actionLogSignal = new Signal(String);
			playerUpdateSignal = new Signal();

			logPlayheadTimeTimer = new Timer(5000);
			logPlayheadTimeTimer.addEventListener(TimerEvent.TIMER, 
				function logPlayheadTime(e:TimerEvent):void {
					actionLogSignal.dispatch("Player playhead time: " + _player.playheadTime);
					})
			logPlayheadTimeTimer.start();

			pauseRecordUpdater = new Timer(1000);
			pauseRecordUpdater.addEventListener(TimerEvent.TIMER,
				function pauseRecordUpdate(e:TimerEvent):void {
					var index:uint = playheadTime;
					if(index < _video.userData.pauseRecord.length && !idle) {
						_video.userData.pauseRecord[index] = _video.userData.pauseRecord[index]+1;
					}
				});
		}

		public function bubbleActionLog(message:String):void {
			actionLogSignal.dispatch(message);
		}

		// public function enable():void {
		// 	if(!contains(pix))
		// 		addChild(pix);
		// 	else
		// 		removeChild(pix);
		// }

		public function set video(val:VideoMetadata):void {
			if(_video != val) {
				_video = val;
				_player.load(_video.getSources("flv")[0].url, null, _video.duration, null);

				var videoSource:Object = video.getSources("flv")[0];
				_player.aspectRatio = videoSource.width/videoSource.height;
				
				_playerBar.video = val;
			}
		}

		public function play(e:Event = null):void {
			_player.play();
			_player.playheadUpdateSignal.add(playerUpdate);
			_playerBar.play();
			vcrTimer.start();
			// pix.start();
			logPlayheadTimeTimer.start();

			pauseRecordUpdater.stop();
			pauseRecordUpdater.reset();
			
			_playerOverlay.graphics.clear();
			_playerOverlay.graphics.beginFill(0x444444, 1);
			_playerOverlay.graphics.drawRect(_player.x, _player.y, _width, _height);
			_playerOverlay.graphics.endFill();
			TweenLite.to(_playerOverlay, 0.25, {alpha: 0});

			dispatchEvent(new PlayerEvent(PlayerEvent.PLAY, _player.playheadTime));
		}
		
		public function stop(e:Event = null):void {
			_player.stop();
			_player.playheadUpdateSignal.remove(playerUpdate);
			_playerBar.pause();
			vcrTimer.stop();
			// pix.stop();
			logPlayheadTimeTimer.stop();


			_playerOverlay.graphics.clear();
			_playerOverlay.graphics.beginFill(0x444444, 0.5);
			_playerOverlay.graphics.drawRect(_player.x, _player.y, _width, _height);
			_playerOverlay.graphics.endFill();
			_playerOverlay.graphics.beginFill(0xffffff);
			_playerOverlay.graphics.moveTo(_width/2 - 50, _height/2 - 50);
			_playerOverlay.graphics.lineTo(_width/2 + 50, _height/2);
			_playerOverlay.graphics.lineTo(_width/2 - 50, _height/2 + 50);
			_playerOverlay.graphics.endFill();
			_playerOverlay.alpha = 0;
			TweenLite.to(_playerOverlay, 0.25, {alpha: 1});


			if(playheadTime < _video.duration - 5) {
				pauseRecordUpdater.start();
			}

			_viewCountRecordSnapshot = _video.userData.viewCountRecord.concat();

			dispatchEvent(new PlayerEvent(PlayerEvent.PAUSE, _player.playheadTime));
		}

		public function setPlaybackRate(val:Number):void {
			currentPlaybackSpeed = val;
			_playerBar.setPlaybackRate(val);
			if(val == 0) {
				dynamicPlayBackSpeed = true;
			} else {
				dynamicPlayBackSpeed = false;
				_player.setPlaybackRate(val);
			}

		}

		public function autoHighlightOff():void {
			// pix.recordingColour = 0;
		}

		private function updateViewCount(e:TimerEvent):void {
			var index:uint = _player.playheadTime;
			if(index != lastUpdatedTime && index < _video.userData.viewCountRecord.length) {
				_video.userData.setViewCountRecord(index, _video.userData.viewCountRecord[index]+1);
				_video.userData.setPlaybackRateRecord(index, uint(currentPlaybackSpeed * 100)/100);
				lastUpdatedTime = index;
				// trace(_video.userData.viewCountRecord)
			}
		}

		public function seek(time:Number):void {
			// hack. called by playerview... should we use playerevents here?
			dispatchEvent(new PlayerEvent(PlayerEvent.SEEK, _player.playheadTime, time));
			_player.seek(time);
			_playerBar.setPlayTime(time);
			captionSeek(_player.playheadTime);
			removeRestriction();
		}

		// private var lastShowingCue:Cue;
		private function captionSeek(time:Number):void {
			if(contains(captionDisplay) && _video.getSources("vtt")[0]) {

				var captions:VideoCaptions = _video.getSources("vtt")[0].captions;
				var cue:Cue = captions.getCueAtTime(time);
				var text:String = cue.getText();

				// if(contains(captionView)) {

	        		if(captionDisplay.text != text) {
		        		// var direction:Number = currentDisplayCaptionTime > time ? 1 : -1;
		        		// captionView.displayText(text, direction);
		        		captionDisplay.text = text;
		        	}

	        		// captionView.cursor = (time - cue.startTime/1000)/(cue.duration/1000);
	        		// currentDisplayCaptionTime = time;
	        	// }

				// var videoCaptionsArray:Array = _video.captionsArray;
				// var videoCaptionsArrayLength:int = videoCaptionsArray.length;
				// var foundCaption:Boolean = false;
				// if(lastShowingCue != null && !(lastShowingCue.startTime*0.001 < time && lastShowingCue.endTime*0.001 > time)) {
				// 	for(var i:int = 0; i <= videoCaptionsArrayLength; i++) {

				// 		if(i == videoCaptionsArrayLength) {
				// 			captionDisplay.text = "";
				// 			break;
				// 		}
				// 		var cue:Cue = videoCaptionsArray[i];
			 //        	if(cue.startTime*0.001 < time && cue.endTime*0.001 > time) {
			        		
			 //        		captionDisplay.text = videoCaptionsArray[i].getText();
			 //        		foundCaption = true;
			 //        		lastShowingCue = cue;
			 //        		break;
			 //        	}
			 //        }
			 //    }

		        // if(!foundCaption)
		        	// captionDisplay.text = "";

		        captionDisplay.y = _height - WebPlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;
		    }
		}

		private function playerUpdate(e:Event = null):void {
			playerUpdateSignal.dispatch(_player.playheadTime);
			dispatchEvent(new PlayerEvent(PlayerEvent.PLAYHEAD_UPDATE, _player.playheadTime));
			// pix.setBalls(_video.userData.getHighlightedColoursforTimeRange(new Range(_player.playheadTime, _player.playheadTime)));
			_playerBar.setPlayTime(_player.playheadTime);

			captionSeek(_player.playheadTime);

			// if(_player.predefinedPlaybackSpeed != null) {
			// 	_playerBar.setPlaybackRate(_player.predefinedPlaybackSpeed[])
			// }
			
			if(dynamicPlayBackSpeed) {

			// 	// make the vcr low resolution (5 seconds per entry) so that the speed doesn't change to often, otherwise it will stutter.
			// 	var vcrLowRes:Vector.<Number> = new Vector.<Number>;
			// 	var numPerBin:int = 5;
			// 	var sum:int = 0;
			// 	var maxViewcount:Number = 1;
			// 	for(var i:int = 0; i<_viewCountRecordSnapshot.length; i++) {
			// 		sum += _viewCountRecordSnapshot[i];
			// 		if(i%numPerBin == 0 && i != 0) {
			// 			vcrLowRes.push(sum/numPerBin);
			// 			maxViewcount = Math.max(maxViewcount, sum/numPerBin);
			// 			sum = 0;
			// 		}
			// 	}
			// 	vcrLowRes.push(sum/(_viewCountRecordSnapshot.length%numPerBin));

			// 	var binNumber:int = Math.max(0, Math.min(vcrLowRes.length, int(_player.playheadTime/numPerBin)));
			// 	var viewCountRecordRatio:Number = vcrLowRes[binNumber]/maxViewcount;

			// 	// if the regular vcr is 0, then make it play at normal speed.
			// 	if(_viewCountRecordSnapshot[int(_player.playheadTime)] == 0)
			// 		viewCountRecordRatio = 0;

			// 	// trace(vcrLowRes)
			// 	// trace("vcrLowRes[" + binNumber + "] = " + vcrLowRes[binNumber] + " " + _video.getMaxViewCount() + " " + viewCountRecordRatio);

			// 	var playbackSpeed = Math.pow((viewCountRecordRatio - 1), 4) + 1;
			// 	// trace("playbackSpeed = " + playbackSpeed);
			// 	if(viewCountRecordRatio == 0)
			// 		playbackSpeed = 1;
			// 	// trace(playbackSpeed);
				// _player.setPlaybackRate(playbackSpeed);
					// if(_player.playheadTime/5 < predefinedPlaybackSpeed.length) {
					// 	// trace("predefinedPlaybackSpeed[" + (uint)(_player.playheadTime/5) + "] = " + predefinedPlaybackSpeed[(uint)(_player.playheadTime/5)])
					// 	_player.setPlaybackRate(predefinedPlaybackSpeed[(uint)(_player.playheadTime/5)]);
					// }
			}

		    _lastPlayedTime = _player.playheadTime;
		}

		public function setPredefinedPlaybackSpeed(val:Array):void {
			trace("setPredefinedPlaybackSpeed(" + val + ")")
			_player.setPredefinedPlaybackRate(val);
		}

		private function playSubsetOnly(timesArray:Array):void {

			timesAllowedToPlay = timesArray;
			timesAllowedToPlayIndex = 0;

			playSubsetTimer.delay = timesAllowedToPlay[timesAllowedToPlayIndex].length * 1000 / currentPlaybackSpeed;
			playSubsetTimer.start();
			_player.seek(timesAllowedToPlay[timesAllowedToPlayIndex].start);

		}

		private function playNextSubset(e:TimerEvent):void {
			timesAllowedToPlayIndex += 1;
			playSubsetTimer.reset();

			if(timesAllowedToPlayIndex < timesAllowedToPlay.length) {
				playSubsetTimer.delay = timesAllowedToPlay[timesAllowedToPlayIndex].length * 1000 / currentPlaybackSpeed;
				playSubsetTimer.start();
				_player.seek(timesAllowedToPlay[timesAllowedToPlayIndex].start);
			} else {
				stop();
				removeRestriction();
			}
		}

		private function removeRestriction():void {
			restrictPlayingCertainTimes = false;
			restrictPlayingCertainTimesSignal.dispatch(false);
			timesAllowedToPlay = [];
			timesAllowedToPlayIndex = -1;
			if(contains(highlightSprite)) {
				removeChild(highlightSprite);
			}
		}

		public function playHighlight(colour:uint):void {
			var timesHighlighted:Array = _video.userData.highlights.grab(colour);

			if(timesHighlighted) {
				playSubsetOnly(timesHighlighted);
				play();
			}
		}

		public function playRange(range:ca.ubc.ece.hct.Range):void {
			playSubsetOnly([range]);
		}

		private function playerClick(e:Event = null):void {
			playVideo();
			actionLogSignal.dispatch("Player: Clicked player to " + ((_player.state == VideoState.PLAYING) ? "pause" : "play") + " video.");
		}

		public function playVideo(e:Event = null):void {
			// trace(_player.paused)
			if(!(_player.state == VideoState.PLAYING)) {
				play();
			} else {
				stop();
			}
		}

		private function playerBarSeek(oldTime:Number, newTime:Number):void {
			dispatchEvent(new PlayerEvent(PlayerEvent.SEEK, _player.playheadTime, newTime));
			_player.seek(newTime);
			captionSeek(_player.playheadTime);
			removeRestriction();

			// if(e.pause) {
			// 	stop();
			// }
		}

		public function enableSeekbar():void {
			_playerBar.enableSeekbar();
		}

		public function disableSeekbar():void {
			_playerBar.disableSeekbar();
		}

		private function enlargeVideo(e:Event = null):void {
			dispatchEvent(new PlayerEvent(PlayerEvent.ENLARGE, -1));
		}

		private function closedCaptions(e:Event = null):void {
			if(contains(captionDisplay)) {
				removeChild(captionDisplay);
			} else {
				addChild(captionDisplay);
			}
		}

		private function mouseMove(e:MouseEvent):void {
			_playerBar.maximize();
		}

		private function mouseOut(e:MouseEvent):void {
			if(e.stageX < x || e.stageX > x + width || e.stageY < y || e.stageY > y + height)
				_playerBar.minimize();
		}

		private function mouseOver(e:MouseEvent):void {
			_playerBar.maximize();
		}

		public function get playheadTime():Number {
			return _player.playheadTime;
		}

		override public function set width(val:Number):void {

			_width = val;

			_player.width = val;

			_playerBar.width = val;


	        captionDisplay.width = val;

			captionDisplay.y = _height - WebPlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;


			// pix.x = pix.width/2 + 5;
			// pix.y = _height - _playerBar.height - pix.height/2 - 10;

			_playerOverlay.graphics.clear();
			_playerOverlay.graphics.beginFill(0xff0000, 0);
			_playerOverlay.graphics.drawRect(0, 0, val, _height);
			_playerOverlay.graphics.endFill();


			_playerMask.graphics.clear();
			_playerMask.graphics.beginFill(0, 0);
			_playerMask.graphics.drawRect(0, 0, _width, _height);
			_playerMask.graphics.endFill();

		}

		override public function set height(val:Number):void {

			_height = val;

			_player.height = val;

			_playerBar.y = _height - WebPlayerBar.PLAYERBAR_HEIGHT;//_height - _playerBar.height;//PlayerBar.PLAYERBAR_HEIGHT;

			captionDisplay.y = _height - WebPlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;


			// pix.x = pix.width/2 + 5;
			// pix.y = _height - _playerBar.height - pix.height/2 - 10;

			_playerOverlay.graphics.clear();
			_playerOverlay.graphics.beginFill(0xff0000, 0);
			_playerOverlay.graphics.drawRect(0, 0, _width, _height);
			_playerOverlay.graphics.endFill();


			_playerMask.graphics.clear();
			_playerMask.graphics.beginFill(0, 0);
			_playerMask.graphics.drawRect(0, 0, _width, _height);
			_playerMask.graphics.endFill();
		}

		override public function set x(val:Number):void {
			super.x = val;
			_player.x = 0;
		}

		override public function set y(val:Number):void {
			super.y = val;
			_player.y = 0;
		}

		public function set allowAnimation(val:Boolean):void {
			_playerBar.allowAnimation = val;
		}

		public function get allowAnimation():Boolean {
			return _playerBar.allowAnimation;
		}
	}
}