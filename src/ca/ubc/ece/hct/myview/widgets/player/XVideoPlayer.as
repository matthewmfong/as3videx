////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {

import flash.events.Event;
import flash.events.StageVideoAvailabilityEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.StageVideo;
import flash.media.StageVideoAvailability;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.utils.Timer;

public class XVideoPlayer extends IVideoPlayer {

		private var _videoFilePath:String;
		// private var _videoDimensions:Rectangle;
		private var _videoDuration:Number;

		private var startTime:Number = 0;
		// public var aspectRatio:Number = 1;
		private var stageVideo:StageVideo;
		private var stageVideoViewPort:Rectangle;
		private var video:Video;
		private var netStream:NetStream;
		private var netConnection:NetConnection;
		private var timer:Timer;

		private var stageVideoInUse:Boolean;
		private var classicVideoInUse:Boolean;

		public function XVideoPlayer() {
			super();

			netConnection = new NetConnection();
			netConnection.connect(null);
			netStream = new NetStream(netConnection);
			netStream.client = {};

			stageVideoViewPort = new Rectangle(0, 0, 0, 0);

			state = VideoState.STOPPED;

			addEventListener(Event.ADDED_TO_STAGE, setupStageVideo);
			addEventListener(Event.REMOVED_FROM_STAGE, remove);

		}

		private function setupStageVideo(e:Event = null):void {
			// stageVideo = stage.stageVideos[0];
			// stageVideo.viewPort = stageVideoViewPort;
			// stageVideo.attachNetStream(netStream);

			video = new Video();
			video.smoothing = true;
			video.x = stageVideoViewPort.x;
			video.y = stageVideoViewPort.y;
			video.width = stageVideoViewPort.width;
			video.height = stageVideoViewPort.height;

			toggleStageVideo(true);
			// stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoState);
			// video.addEventListener(VideoEvent.RENDER_STATE, videoStateChange);
		}

		private function remove(e:Event = null):void {
			netStream.pause();

			width = 0;
			refreshViewPort();
		}

		private function onStageVideoState(event:StageVideoAvailabilityEvent):void {     
		    // Detect if StageVideo is available and decide what to do in toggleStageVideo 
		    toggleStageVideo(event.availability == StageVideoAvailability.AVAILABLE); 
		} 
		 
		private function toggleStageVideo(on:Boolean):void {     
		    // To choose StageVideo attach the NetStream to StageVideo 
		    // if (on) 
		    // { 
		    //     stageVideoInUse = true; 
		    //     if ( stageVideo == null ) 
		    //     { 
		    //         stageVideo = stage.stageVideos[0]; 
		    //         // stageVideo.addEventListener(StageVideoEvent.RENDER_STATE, stageVideoStateChange); 
	     //            stageVideo.attachNetStream(netStream); 
		    //     } 
		 
		    //     if (classicVideoInUse) 
		    //     { 
		    //         // If you use StageVideo, remove from the display list the 
		    //         // Video object to avoid covering the StageVideo object 
		    //         // (which is always in the background) 
		    //         stage.removeChild ( video ); 
		    //         classicVideoInUse = false; 
		    //     } 
		    // } else 
		    // { 
		        // Otherwise attach it to a Video object 
		        if (stageVideoInUse) 
		            stageVideoInUse = false; 
		        classicVideoInUse = true; 
		        video.attachNetStream(netStream); 
		        stage.addChildAt(video, 0); 
		    // } 

		} 

		public function playheadUpdate(e:Event):void {
			if(Math.abs(playheadTime - _videoDuration) < 0.1 && state != VideoState.REACHED_END) {
				pause();
				state = VideoState.REACHED_END;
				reachedEndOfVideoSignal.dispatch();
			}
		}

		override public function play():void {

			netStream.resume();
			state = VideoState.PLAYING;
			// playheadUpdateSignal.add(playheadUpdate);
		}

		override public function load(url:String, dimensions:Point, duration:Number, keyframes:Array = null):void {
			trace("Loading this url: " + url);
			_videoFilePath = url;
			// _videoDimensions = new Rectangle(0, 0, dimensions.x, dimensions.y);
			_videoDuration = duration;

			netStream.play(url);
			netStream.pause();
			state = VideoState.PAUSED;

		}

		override public function pause():void {
			netStream.pause();
			state = VideoState.PAUSED;
			
			// playheadUpdateSignal.remove(playheadUpdate);
		}

		override public function stop():void {
			pause();
		}

		override public function seek(time:Number):void {
			netStream.seek(time);
		}

		override public function get playheadTime():Number {
			return netStream.time;
		}

		override public function get playbackRate():Number {
			return 1;
		}

		override public function setPlaybackRate(rate:Number):void {
			trace("setPlaybackRate() unsupported using XVideoPlayer");
			return;
		}

		override public function setPredefinedPlaybackRate(val:Array):void {
			trace("setPredefinedPlaybackRate() unsupported using XVideoPlayer");
			return;
		}

		override public function set x(val:Number):void {
			_x = val;
			refreshViewPort();
		}

		override public function set y(val:Number):void {
			_y = val;
			refreshViewPort();
		}

		override public function set width(val:Number):void {
			_width = val;
			refreshViewPort();
		}

		override public function set height(val:Number):void {
			_height = val;
			refreshViewPort();
		}

		override public function set aspectRatio(val:Number):void {
			_aspectRatio = val;
			refreshViewPort();
		}

		private function refreshViewPort():void {
			var videoWidth:Number = Math.max(1, Math.min(_width, _height*_aspectRatio));
			var videoHeight:Number = Math.max(1, Math.min(_height, _width/_aspectRatio));


			var viewPortLocation:Point = new Point(_width/2 - videoWidth/2, 
												   _height/2 - videoHeight/2);

			stageVideoViewPort = new Rectangle(localToGlobal(new Point(_x,_y)).x + viewPortLocation.x, 
												localToGlobal(new Point(_x,_y)).y + viewPortLocation.y,  
												videoWidth, 
												videoHeight);
			if(stageVideo)
				stageVideo.viewPort = stageVideoViewPort;

			if(video) {
				video.x = stageVideoViewPort.x;
				video.y = stageVideoViewPort.y;
				video.width = stageVideoViewPort.width;
				video.height = stageVideoViewPort.height;
			}
			
			graphics.clear();
			graphics.beginFill(0);
			graphics.drawRect(0, 0, viewPortLocation.x, _height); 								// left
			graphics.drawRect(viewPortLocation.x + videoWidth, 0, viewPortLocation.x, _height); // right
			graphics.drawRect(0, 0, _width, viewPortLocation.y); 								// top
			graphics.drawRect(0, viewPortLocation.y + videoHeight, _width, viewPortLocation.y); // bottom
			graphics.endFill();
		}
	}
}