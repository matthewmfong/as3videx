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
import ca.ubc.ece.hct.myview.widgets.StarlingWidget;
import ca.ubc.ece.hct.myview.widgets.pixie.Pixie;
import ca.ubc.ece.hct.myview.widgets.subtitleviewer.Cue;

import org.osflash.signals.natives.StarlingNativeSignal;

import starling.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.BitmapFilterQuality;
import flash.filters.GlowFilter;
import flash.geom.Point;

import starling.display.Canvas;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;
import flash.utils.Timer;

import org.osflash.signals.Signal;

import starling.display.Quad;

public class Player extends StarlingWidget {

		public function get video():VideoMetadata { return _video; }
		private var _player:IVideoPlayer;
		private var _playerOverlay:Quad;
//		private var _playerMask:Quad;
		private var _playerBar:StarlingPlayerBar;
		private var _playerEnlarged:Boolean;

		private var _lastPlayedTime:Number;

		private var captions:VideoCaptions;
	    private var captionDisplay:TextField;
	    private var captionFormat:TextFormat;

		private var playSubsetTimer:Timer;

	    private var restrictPlayingCertainTimes:Boolean = false;
	    public var restrictPlayingCertainTimesSignal:Signal;
	    private var waitingForSeekForRestriction:Boolean = false;
	    private var timesAllowedToPlay:Array;
	    private var timesAllowedToPlayIndex:int;
	    private var highlightSprite:Canvas;

	    private var pix:Pixie;
		private var vcrTimer:Timer;
		private var lastUpdatedTime:int = -1;

		private var logPlayheadTimeTimer:Timer;
		private var pauseRecordUpdater:Timer;

		private var dynamicPlayBackSpeed:Boolean = false;
		private var currentPlaybackSpeed:Number = 1;
		private var predefinedPlaybackSpeed:Array;

		public var actionLogSignal:Signal;
		// public var playheadTimeUpdated:Signal;
//		public var reachedEndOfVideoSignal:Signal;

		public var idle:Boolean = false;

		private var alreadyLoadedOnce:Boolean = false;
//    	private var addedToStageSignal:StarlingNativeSignal;

		public function Player() {
			super();
			playSubsetTimer = new Timer(100);
			playSubsetTimer.addEventListener(TimerEvent.TIMER, playNextSubset);


			restrictPlayingCertainTimesSignal = new Signal(Boolean);

	        captionFormat = new TextFormat("Arial", 18, 0xFFFFE8, "center");
	        captionDisplay = new TextField(_width, 100);

			highlightSprite = new Canvas();

//            addedToStageSignal = new StarlingNativeSignal(this, Event.ADDED_TO_STAGE, Event);
//            addedToStageSignal.addOnce(addedToStage);
			
			CONFIG::AIR {
				_player = new FfmpegVideoPlayer();
			}
			CONFIG::WEB {
				_player = new XVideoPlayer();
			}

//            _playerMask = new Quad(_width, _height);
//            this.mask = _playerMask;

            _playerOverlay = new Quad(_width, _height);
//            addChild(_playerOverlay);


        }

		override protected function addedToStage(e:Event = null):void {
            addChild(_player);
            addChild(_playerBar);
			_player.addEventListener(TouchEvent.TOUCH, touched);
		}

		override protected function removedFromStage(e:Event = null):void {
			_player.removeFromParent(true);
		}

		private function touched(e:TouchEvent):void {
			var touch:Touch = e.getTouch(this, TouchPhase.ENDED);

			if(touch) {
                playVideo();
            }
		}

		public function bubbleActionLog(message:String):void {
			actionLogSignal.dispatch(message);
		}

		override public function loadVideo(video:VideoMetadata):void {
			_video = video;
			_player.load(_video.source[_video.primarySource].localPath, 
				         new Point(_video.source[_video.primarySource].width,
				         	       _video.source[_video.primarySource].height),
				         _video.duration, 
				         _video.source[_video.primarySource].keyframes);


            captions = _video.getCaptions("eng");

//                var captionsSources:Array = _video.getSources("vtt");
            if(captions && captions.cues.length > 0) {
                // captionsArray = video.captionsArray;

                captionDisplay.format = captionFormat;
//                captionDisplay.multiline = true;
                captionDisplay.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
//                captionDisplay.selectable = false;
                captionDisplay.wordWrap = true;
//                captionDisplay.condenseWhite = true;
//                captionDisplay.htmlText = "";
                captionDisplay.width = _player.width;
                // captionDisplay.height = 80;
                captionDisplay.x = _player.width/2 - captionDisplay.width/2;
                captionDisplay.y = _height - PlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;
//                captionDisplay.filters = [new GlowFilter(0x000000, 1, 5, 5, 8, BitmapFilterQuality.MEDIUM)];
                captionDisplay.touchable = false;
                // addChild(captionDisplay);
            }

			if(!alreadyLoadedOnce) {

				
				_playerEnlarged = false;

				_lastPlayedTime = 0;


				reachedEndOfVideoSignal = new Signal();
//				playbackRateChanged = new Signal(Number);
				_player.playheadUpdateSignal.add(playerUpdate);
				_player.reachedEndOfVideoSignal.add(
					function reachedEndOfVideoDispatch():void {
						// trace("reached end");
						reachedEndOfVideoSignal.dispatch();
					});
				_player.playbackRateChanged.add(
					function playbackRateChangedDispatch(rate:Number):void {
						playbackRateSet.dispatch(this, rate);
					});

				_playerOverlay.x = _player.x;
				_playerOverlay.y = _player.y;
				_playerOverlay.alpha = 0;
				_playerOverlay.addEventListener(MouseEvent.CLICK, playerClick);

				_playerBar = new StarlingPlayerBar();//PlayerBar(_video, _width, video.duration);
				_playerBar.player = this;
				_playerBar.setSize(_width, 35);
				_playerBar.x = 0;
//				_playerBar.y = 0;//_height - PlayerBar.PLAYERBAR_HEIGHT;

//                _playerBar.video = video;

				_playerBar.played.add(
					function playerBarPlay():void {
                        _player.play();
                        _player.playheadUpdateSignal.add(playerUpdate);
                        _playerBar.play();
                        vcrTimer.start();
                        // pix.start();
                        logPlayheadTimeTimer.start();

                        pauseRecordUpdater.stop();
                        pauseRecordUpdater.reset();

                        played.dispatch(_playerBar);
					});

				_playerBar.stopped.add(
						function playerBarStop():void {

                            _player.stop();
                            _player.playheadUpdateSignal.remove(playerUpdate);
                            if(_playerBar)
                                _playerBar.pause();
                            vcrTimer.stop();
                            // pix.stop();
                            logPlayheadTimeTimer.stop();

                            if(playheadTime < _video.duration - 5) {
                                pauseRecordUpdater.start();
                            }

                            // _viewCountRecordSnapshot = _video.userData.viewCountRecord.concat();

                            stopped.dispatch(_playerBar);
						}
				);
				_playerBar.fullscreenToggled.add(enlargeVideo);
				_playerBar.ccToggled.add(closedCaptions);
				_playerBar.seeked.add(playerBarSeek);
				
				_playerBar.playbackRateSet.add(
					function changePlaybackRate(rate:Number):void {
						setPlaybackRate(rate);
					});

//				_playerBar.actionLogSignal.add(bubbleActionLog);
				_playerBar.play();
				_playerBar.y = _height - PlayerBar.PLAYERBAR_HEIGHT;

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
				// playheadTimeUpdated = new Signal(Number);

				logPlayheadTimeTimer = new Timer(5000);
				logPlayheadTimeTimer.addEventListener(TimerEvent.TIMER, 
					function logPlayheadTime(e:TimerEvent):void {
						actionLogSignal.dispatch("Player playhead time: " + _player.playheadTime);
						});
				logPlayheadTimeTimer.start();

				pauseRecordUpdater = new Timer(100000);
				pauseRecordUpdater.addEventListener(TimerEvent.TIMER,
					function pauseRecordUpdate(e:TimerEvent):void {
						var index:uint = playheadTime;
						if(index < _video.userData.pauseRecord.length && !idle) {
							_video.userData.pauseRecord[index] = _video.userData.pauseRecord[index]+1;
						}
					});
				alreadyLoadedOnce = true;
			} else {
//				_playerBar.video = _video;
			}

			
			play();
//			seek(0);

		}

		public function set video(val:VideoMetadata):void {
			if(_video != val) {
				_video = val;
				_player.load(_video.source[_video.primarySource].localPath, 
					         new Point(_video.source[_video.primarySource].width,
					         	       _video.source[_video.primarySource].height), 
					         _video.duration, 
					         _video.source[_video.primarySource].keyframes);
//				_playerBar.video = val;
			}
		}

		override public function play():void {
			_player.play();
			_player.playheadUpdateSignal.add(playerUpdate);
			_playerBar.play();
			vcrTimer.start();
			// pix.start();
			logPlayheadTimeTimer.start();

			pauseRecordUpdater.stop();
			pauseRecordUpdater.reset();

//			played.dispatch(this);
		}

		public var resizingPlayerState:String;
		override public function set resizing(val:Boolean):void {

			if(val) {
				resizingPlayerState = _player.state;
////				stop();
//			} else if(resizingPlayerState == VideoState.PLAYING) {
////				play();
			}
		}

		private function selfStop():void {

            _player.stop();
            _player.playheadUpdateSignal.remove(playerUpdate);
            if(_playerBar) {
                _playerBar.pause();
            }
            vcrTimer.stop();
            // pix.stop();
            logPlayheadTimeTimer.stop();

            if(playheadTime < _video.duration - 5) {
                pauseRecordUpdater.start();
            }

            // _viewCountRecordSnapshot = _video.userData.viewCountRecord.concat();

            // dispatchEvent(new PlayerEvent(PlayerEvent.PAUSE, _player.playheadTime));
            stopped.dispatch(this);
		}

		private function selfPlay():void {

            _player.play();
            _player.playheadUpdateSignal.add(playerUpdate);
            _playerBar.play();
            vcrTimer.start();
            // pix.start();
            logPlayheadTimeTimer.start();

            pauseRecordUpdater.stop();
            pauseRecordUpdater.reset();

            played.dispatch(this);
		}
		
		override public function stop():void {
			_player.stop();
			_player.playheadUpdateSignal.remove(playerUpdate);
			if(_playerBar) {
                _playerBar.pause();
            }
			vcrTimer.stop();
			// pix.stop();
			logPlayheadTimeTimer.stop();

			if(playheadTime < _video.duration - 5) {
				pauseRecordUpdater.start();
			}

			// _viewCountRecordSnapshot = _video.userData.viewCountRecord.concat();

			// dispatchEvent(new PlayerEvent(PlayerEvent.PAUSE, _player.playheadTime));
//			stopped.dispatch(this);
		}

		override public function setPlaybackRate(val:Number):void {
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
			}
		}

		public function seek(time:Number):void {
			// hack. called by playerview... should we use playerevents here?
			// dispatchEvent(new PlayerEvent(PlayerEvent.SEEK, _player.playheadTime, time));
			_player.seek(time);
			_playerBar.setPlayTime(time);
			captionSeek(_player.playheadTime);
			removeRestriction();

			seeked.dispatch(this, time);
		}

		override public function receiveSeek(time:Number):void {
//			trace(time);
			_player.seek(time);
			_playerBar.setPlayTime(time);
			captionSeek(_player.playheadTime);
			removeRestriction();
		}

		private var lastShowingCue:Cue;
		private function captionSeek(time:Number):void {
			 if(captions && contains(captionDisplay)) {

			 	var videoCaptionsArray:Array = captions.cues;
			 	var foundCaption:Boolean = false;
			 	if(lastShowingCue == null || !(lastShowingCue.startTime*0.001 <= time && lastShowingCue.endTime*0.001 >= time)) {
			 		for(var i:int = 0; i <= videoCaptionsArray.length; i++) {
//			 			trace(videoCaptionsArray[i].startTime * 0.001 + " " + videoCaptionsArray[i].endTime * 0.001 + " " + time)
			 			if(i == videoCaptionsArray.length) {
			 				captionDisplay.text = "";
			 				break;
			 			}

			 			var cue:Cue = videoCaptionsArray[i];
			         	if(cue.startTime*0.001 <= time && cue.endTime*0.001 >= time) {
			        		
			         		captionDisplay.text = videoCaptionsArray[i].getText();
			         		foundCaption = true;
			         		lastShowingCue = cue;
			         		break;
			         	}
			         }
			     } else {
			     	foundCaption = true;
			     }


		         if(!foundCaption)
		         	captionDisplay.text = "";

		         captionDisplay.y = _height - PlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;
		     }
		}


		// private var xxj:int = 0;
		private function playerUpdate(e:Event = null):void {
			// trace("Player.playerUpdate(): " + xxj++);
			var playerPlayheadTime:Number = _player.playheadTime;
			playheadTimeUpdated.dispatch(this, playerPlayheadTime);
			// dispatchEvent(new PlayerEvent(PlayerEvent.PLAYHEAD_UPDATE, _player.playheadTime));
			// pix.setBalls(_video.userData.getHighlightedColoursForTime(_player.playheadTime));
			_playerBar.setPlayTime(playerPlayheadTime);

			captionSeek(playerPlayheadTime);

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

		    _lastPlayedTime = playerPlayheadTime;
		}

		public function setPredefinedPlaybackSpeed(val:Array):void {
			trace("setPredefinedPlaybackSpeed(" + val + ")");
			_player.setPredefinedPlaybackRate(val);
		}

		private function playSubsetOnly(timesArray:Array):void {

			timesAllowedToPlay = timesArray;
			timesAllowedToPlayIndex = 0;

			playSubsetTimer.delay = timesAllowedToPlay[timesAllowedToPlayIndex].length * 1000 / currentPlaybackSpeed;
			playSubsetTimer.start();
			_player.seek(timesAllowedToPlay[timesAllowedToPlayIndex].start);

		}

		private function playNextSubset(e:TimerEvent = null):void {
			timesAllowedToPlayIndex += 1;
			playSubsetTimer.reset();

			if(timesAllowedToPlayIndex < timesAllowedToPlay.length) {
				playSubsetTimer.delay = timesAllowedToPlay[timesAllowedToPlayIndex].length * 1000 / currentPlaybackSpeed;
				playSubsetTimer.start();
				_player.seek(timesAllowedToPlay[timesAllowedToPlayIndex].start);
			} else {
				selfStop();
				removeRestriction();
				stoppedPlayingHighlights.dispatch(this);
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

		override public function startPlayingHighlights(colour:uint):void {
			var timesHighlighted:Array = _video.userData.getHighlightedTimes(colour);

			if(timesHighlighted) {
				playSubsetOnly(timesHighlighted);
				selfPlay();
			} else {
                stoppedPlayingHighlights.dispatch(this);
			}
		}

//		override public function stopPlayingHighlights():void {
//
//		}

		public function playRange(range:Range):void {
			playSubsetOnly([range]);
		}

		private function playerClick(e:Event = null):void {
			playVideo();
			actionLogSignal.dispatch("Player: Clicked player to " + ((_player.state == VideoState.PLAYING) ? "pause" : "play") + " video.");
		}

		public function playVideo(e:Event = null):void {
			if(_player.state == VideoState.PLAYING) {
				selfStop();
			} else {
				selfPlay();
			}
		}

		private function playerBarSeek(oldTime:Number, newTime:Number):void {
//			dispatchEvent(new PlayerEvent(PlayerEvent.SEEK, _player.playheadTime, newTime));
			_player.seek(newTime);
			captionSeek(_player.playheadTime);
			removeRestriction();

			seeked.dispatch(this, newTime);

			// if(e.pause) {
			// 	stop();
			// }
		}

//		public function enableSeekbar():void {
//			_playerBar.enableSeekbar();
//		}
//
//		public function disableSeekbar():void {
//			_playerBar.disableSeekbar();
//		}

		private function enlargeVideo(s:StarlingWidget, fullscreenOn:Boolean):void {
			fullscreenToggled.dispatch(_playerBar, fullscreenOn);
		}

		private function closedCaptions(s:StarlingWidget, ccOn:Boolean):void {
			if(!ccOn && contains(captionDisplay)) {
				removeChild(captionDisplay);
			} else if(ccOn && !contains(captionDisplay)) {
				addChild(captionDisplay);
			}

			ccToggled.dispatch(s, ccOn);
		}

//		private function mouseMove(e:MouseEvent):void {
//			_playerBar.maximize();
//		}
//
//		private function mouseOut(e:MouseEvent):void {
//			if(e.stageX < x || e.stageX > x + width || e.stageY < y || e.stageY > y + height)
//				_playerBar.minimize();
//		}
//
//		private function mouseOver(e:MouseEvent):void {
//			_playerBar.maximize();
//		}

		public function get playheadTime():Number {
			return _player.playheadTime;
		}

		override public function select(interval:Range):void {}
		override public function deselect():void {}
		override public function highlight(colour:int, interval:Range):void {}
		override public function unhighlight(colour:int, interval:Range):void {}
		override public function updateHighlights():void {}

		override public function set width(val:Number):void {

			_width = val;
			_player.width = val;
			_playerBar.width = val;


	        captionDisplay.width = val;

			captionDisplay.y = _height - PlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;


			// pix.x = pix.width/2 + 5;
			// pix.y = _height - _playerBar.height - pix.height/2 - 10;

			_playerOverlay.readjustSize(val, _height);

//			_playerMask.readjustSize(_width, _height);
		}

		override public function set height(val:Number):void {

			_height = val;

			_player.height = val;

			_playerBar.y = _height - PlayerBar.PLAYERBAR_HEIGHT;//_height - _playerBar.height;//PlayerBar.PLAYERBAR_HEIGHT;

			captionDisplay.y = _height - PlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;


			// pix.x = pix.width/2 + 5;
			// pix.y = _height - _playerBar.height - pix.height/2 - 10;

            _playerOverlay.readjustSize(_width, _height);

//            _playerMask.readjustSize(_width, _height);

		}

//		override public function set x(val:Number):void {
//			super.x = val;
//			_player.x = 0;
//		}

//		override public function set y(val:Number):void {
//			super.y = val;
//			_player.y = 0;
//		}

		override public function setSize(width:Number, height:Number):void {
			super.setSize(width, height);

//			if(stage) {
                _player.setSize(_width, _height);

            _playerBar.y = _height - _playerBar.height;// - PlayerBar.PLAYERBAR_HEIGHT;//_height - _playerBar.height;//PlayerBar.PLAYERBAR_HEIGHT;
            _playerBar.setSize(_width, 35);

//            captionDisplay.y = _height - PlayerBar.PLAYERBAR_HEIGHT - captionDisplay.height - 5;


                // pix.x = pix.width/2 + 5;
                // pix.y = _height - _playerBar.height - pix.height/2 - 10;

                _playerOverlay.readjustSize(_width, _height);

//                _playerMask.readjustSize(_width, _height);
//            }

		}

//		public function set allowAnimation(val:Boolean):void {
//			_playerBar.allowAnimation = val;
//		}
//
//		public function get allowAnimation():Boolean {
//			return _playerBar.allowAnimation;
//		}


		override public function setHighlightReadMode(mode:uint):void {
			// highlightReadMode = mode;
			// if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
			// 	if(highlightSprite && !contains(highlightSprite)) 
			// 		addChild(highlightSprite)
			// } else {
			// 	if(highlightSprite && contains(highlightSprite))
			// 		removeChild(highlightSprite);
			// }

			// if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
				
			// }

			// if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
			// 	if(instructorHighlightSprite && !contains(instructorHighlightSprite)) {
			// 		addChild(instructorHighlightSprite)
			// 	}
			// } else {
			// 	if(instructorHighlightSprite && contains(instructorHighlightSprite)) {
			// 		removeChild(instructorHighlightSprite);
			// 	}
			// }
		}
		override public function setViewCountRecordReadMode(mode:uint):void { /* do nothing */ }
	}
}