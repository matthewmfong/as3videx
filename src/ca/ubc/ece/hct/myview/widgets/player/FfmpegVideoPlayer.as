////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {

import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.IOErrorEvent;
import flash.events.NativeProcessExitEvent;
import flash.events.ProgressEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.net.NetStreamAppendBytesAction;
import flash.system.Capabilities;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.getTimer;

import org.osflash.signals.natives.StarlingNativeSignal;

import starling.display.Canvas;
import starling.display.Quad;
import starling.events.Event;
import starling.textures.Texture;

public class FfmpegVideoPlayer extends IVideoPlayer {

    private static const BUFFER_AMOUNT:uint = 5;
    private var videoBuffer:ByteArray;

    private var _videoFilePath:String;
    private var _videoDimensions:Rectangle;
    private var _videoDuration:Number;
    private var _videoKeyframes:Array;

    private var stageVideoWidth:uint;
    private var stageVideoHeight:uint;

    private var texture:Texture;
    private var textureSize:Rectangle;
    private var stageVideo:Quad;
    private var netStream:NetStream;

    private var netConnection:NetConnection;
    private var renderTimer:Timer;

    private var firstRun:Boolean = true;
    public static var ffmpeg:NativeProcess;
    private var ffmpegStartupInfo:NativeProcessStartupInfo;
    private var ffmpegArgs:Vector.<String>;

    private var _playbackRate:Number = 1;
    public var currentPlaybackRate:Number = 1;
    override public function get playbackRate():Number { return currentPlaybackRate };
    private var seekPoint:Number = 0;
    private var ffmpegLaunchTime:Number = 0;
    private var nextFfmpegLaunchTime:Number = 0;
    private var firstFrameAvailable:Boolean = true;
    // private var runFfmpegWithNewParameters:Boolean = false;
    private var seekActionWaiting:Boolean = false;
    private var playbackRateActionWaiting:Boolean = false;
    private var loadActionWaiting:Boolean = false;

    private var addedToStageSignal:StarlingNativeSignal;

    private var background:Canvas;

    public function FfmpegVideoPlayer() {
        super();

        netConnection = new NetConnection();
        netConnection.connect(null);
        netStream = new NetStream(netConnection);
        netStream.client = {};


        texture = Texture.fromNetStream(netStream, 1, updateVideoTexture);
        textureSize = new Rectangle(0, 0, 0, 0);
        netStream.play(null);

        state = VideoState.STOPPED;
        aspectRatio = 16/9;

        videoBuffer = new ByteArray();

        renderTimer = new Timer(10000);

        background = new Canvas();
        stageVideo = new Quad(100, 100);

//        addEventListener()
//        addedToStageSignal = new StarlingNativeSignal(this, Event.ADDED_TO_STAGE, Event);
//        addedToStageSignal.addOnce(addedToStage);
    }

    override protected function addedToStage(e:Event):void {
        super.addedToStage(e)
        addChild(background);
        addChild(stageVideo);
    }

    override protected function removedFromStage(e:Event):void {
        super.removedFromStage(e);
    }

    override public function dispose():void {
        super.dispose();
        netStream.dispose();
//        netStream = null;
        netConnection = null;
        try {
            texture.dispose();
        } catch(e:Error) {
        /* Error: Error #3694: The object was disposed by an earlier call of dispose() on it.
            at flash.display3D.texture::VideoTextxure/attachCamera()
            at ConcreteVideoTexture/dispose()[/tlef-flash-demo/src/starling/textures/ConcreteVideoTexture.as:49]
            at ca.ubc.ece.hct.myview.widgets.player::FfmpegVideoPlayer/dispose()[/tlef-flash-demo/src/ca/ubc/ece/hct/myvie/widgets/player/FfmpegVideoPlayer.as:120] */
        }
//        texture = null;
        videoBuffer = null;
        if(renderTimer) {
            renderTimer.stop();
            renderTimer.removeEventListener(TimerEvent.TIMER, bufferTimerFunction);
            renderTimer = null;
        }
        background.removeFromParent(true);
        stageVideo.removeFromParent(true);
        if(FfmpegVideoPlayer.ffmpeg) {
            FfmpegVideoPlayer.ffmpeg.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
            FfmpegVideoPlayer.ffmpeg.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
            FfmpegVideoPlayer.ffmpeg.removeEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
            FfmpegVideoPlayer.ffmpeg.removeEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
            FfmpegVideoPlayer.ffmpeg.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
            FfmpegVideoPlayer.ffmpeg = null;
        }
    }

    private function updateVideoTexture():void {
        stageVideo.texture = texture;
    }

    override public function play():void {

        netStream.resume();

        state = VideoState.PLAYING;

        renderTimer.delay = Math.max(0, netStream.bufferLength * 1000 - (BUFFER_AMOUNT*0.1) * 1000);
        // trace("renderTimer.delay = " + renderTimer.delay);

        if(nextFfmpegLaunchTime < _videoDuration)
            renderTimer.start();

        playheadUpdateSignal.add(playheadUpdate);
        // netStream.pause();
    }


    override public function load(url:String, dimensions:Point, duration:Number, keyframes:Array = null):void {
        _videoFilePath = url;
        _videoDimensions = new Rectangle(0, 0, dimensions.x, dimensions.y);
        _videoDuration = duration;
        _videoKeyframes = keyframes;

        aspectRatio = _videoDimensions.width/_videoDimensions.height;

        netStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
        seek(0);

        refreshViewPort();

        if(FfmpegVideoPlayer.ffmpeg) {
            loadActionWaiting = true;
            FfmpegVideoPlayer.ffmpeg.exit();
        } else {
            launchFFmpeg(0, BUFFER_AMOUNT);
            play();
        }

    }

    override public function pause():void {
        netStream.pause();
        state = VideoState.STOPPED;
        if(playheadUpdateSignal) {
            playheadUpdateSignal.remove(playheadUpdate);
        }
    }

    override public function stop():void {
        pause();
    }

    override public function seek(time:Number):void {
        // netStream.seek(time);
        seekPoint = time;
        nextFfmpegLaunchTime = time;
        seekActionWaiting = true;

        if(FfmpegVideoPlayer.ffmpeg && FfmpegVideoPlayer.ffmpeg.running)
            FfmpegVideoPlayer.ffmpeg.exit();
        else {
            // trace("launching ffmpeg from seek")
            launchFFmpeg(nextFfmpegLaunchTime, BUFFER_AMOUNT);
        }

        if(state == VideoState.REACHED_END) {
            play();
        }

    }

    private var lastTimePlayheadUpdated:Number = 0;
    private function playheadUpdate(e:Event):void {

        if(getTimer() - lastTimePlayheadUpdated > 100) {
//            trace(getTimer() - lastTimePlayheadUpdated);
            lastTimePlayheadUpdated = getTimer();

            if (Math.abs(playheadTime - _videoDuration) < 0.1 && state != VideoState.REACHED_END) {
                pause();
                state = VideoState.REACHED_END;
                reachedEndOfVideoSignal.dispatch();
            }

            if (predefinedPlaybackRate != null &&
                    currentPlaybackRate != predefinedPlaybackRate[Math.min((uint)(playheadTime / playbackRateBucketSize), predefinedPlaybackRate.length - 1)]) {

                currentPlaybackRate = predefinedPlaybackRate[Math.min((uint)(playheadTime / playbackRateBucketSize), predefinedPlaybackRate.length - 1)];
                playbackRateChanged.dispatch(currentPlaybackRate);
            }


//			if(textureSize.width != texture.frameWidth || textureSize.height != texture.frameHeight) {
//				textureSize.width = texture.frameWidth;
//				textureSize.height = texture.frameHeight;
//                texture.dispose();
//                texture = Texture.fromNetStream(netStream, 1, updateVideoTexture);
//            }
        }
    }

    override public function get playheadTime():Number {

        var netStreamTime:Number;
        if(seekActionWaiting || playbackRateActionWaiting)
            netStreamTime = 0;
        else {
            netStreamTime = netStream.time*_playbackRate;
        }

        var returnTime:Number = seekPoint;

        if(predefinedPlaybackRate == null) {
            returnTime = Math.max(0, Math.min(seekPoint + netStreamTime, _videoDuration));
        } else if(!seekActionWaiting) {

            var lastKnownTime:Number = seekPoint;
            var playbackRateIndexAtLastKnownTime:uint = lastKnownTime / playbackRateBucketSize;
            var questionTime:Number = netStream.time + lastKnownTime;

            var playbackSpeedAtLastKnownTime:Number = predefinedPlaybackRate[playbackRateIndexAtLastKnownTime];

            var remainingFromLastKnownTime:Number;
            if (netStream.time > playbackRateBucketSize / playbackSpeedAtLastKnownTime - (lastKnownTime / playbackSpeedAtLastKnownTime) % (playbackRateBucketSize / playbackSpeedAtLastKnownTime)) {
                remainingFromLastKnownTime = playbackRateBucketSize / playbackSpeedAtLastKnownTime - (lastKnownTime / playbackSpeedAtLastKnownTime) % (playbackRateBucketSize / playbackSpeedAtLastKnownTime);
                // trace("case 1");
            } else {
                remainingFromLastKnownTime = netStream.time;
                // trace("case 2");
            }

            // trace("lastKnownTime = " + lastKnownTime);
            // trace("playbackRateBucketSize - lastKnownTime%playbackRateBucketSize = " + (playbackRateBucketSize/playbackSpeedAtLastKnownTime - lastKnownTime%(playbackRateBucketSize/playbackSpeedAtLastKnownTime)))
            // trace("netStream.time = " + netStream.time);
            // trace("remainingFromLastKnownTime = " + remainingFromLastKnownTime);
            // trace("playbackSpeedAtLastKnownTime = " + playbackSpeedAtLastKnownTime)

            returnTime = lastKnownTime + remainingFromLastKnownTime * playbackSpeedAtLastKnownTime;

            // trace("returnTime = " + returnTime)
            // trace(predefinedPlaybackRate);
            // trace("/____");

            // trace("netStream.time = " + netStream.time);

            var netStreamTimeCounter:Number = remainingFromLastKnownTime;
            var ppbrIndex:uint = playbackRateIndexAtLastKnownTime + 1;

            var breakCounter:uint = 0;
            var remainingTime:Number = netStream.time - netStreamTimeCounter
            while (remainingTime > 0 && breakCounter < 10000) {
                // trace(breakCounter);

                remainingTime = netStream.time - netStreamTimeCounter;

                var maxStreamTimeForBucket:Number = playbackRateBucketSize / predefinedPlaybackRate[Math.min(ppbrIndex, predefinedPlaybackRate.length - 1)];

                // trace("/predefinedPlaybackRate[" + Math.min(ppbrIndex, predefinedPlaybackRate.length -1) + "] = " + predefinedPlaybackRate[Math.min(ppbrIndex, predefinedPlaybackRate.length -1)])
                // trace("remainingTime = " + remainingTime);
                // trace("maxStreamTimeForBucket = " + maxStreamTimeForBucket);

                // trace("netStreamTimeCounter = " + netStreamTimeCounter);

                if (remainingTime > maxStreamTimeForBucket) {
                    returnTime += playbackRateBucketSize;
                    netStreamTimeCounter += maxStreamTimeForBucket;
                } else {
                    returnTime += remainingTime * predefinedPlaybackRate[Math.min(ppbrIndex, predefinedPlaybackRate.length - 1)];
                    break;
                }

                // trace("maxStreamTimeForBucket = " + maxStreamTimeForBucket)

                // netStreamTimeCounter += maxStreamTimeForBucket;

                // trace("netStreamTimeCounter = " + netStreamTimeCounter);
                // trace("returnTime = " + returnTime + "/");

                ppbrIndex++;

                breakCounter++;
            }
            // trace("___/" + returnTime);

        }

        return returnTime;
    }

    override public function setPlaybackRate(rate:Number):void {

        // Clamp the rate to [0.5, 2], as setps and atempo from ffmpeg support only that
        var newPlaybackRate:Number = Math.max(0.5, Math.min(2, rate));

        if(Math.abs(_playbackRate - newPlaybackRate) >= 0.1 && !seekActionWaiting) {

            seekPoint += netStream.time * _playbackRate;
            nextFfmpegLaunchTime = seekPoint;

            _playbackRate = newPlaybackRate;

            currentPlaybackRate = newPlaybackRate;

            playbackRateActionWaiting = true;

            if(FfmpegVideoPlayer.ffmpeg && FfmpegVideoPlayer.ffmpeg.running) {
                // trace("waiting for exit");
                FfmpegVideoPlayer.ffmpeg.exit();
            } else {
                // trace("doing it right away")
                launchFFmpeg(nextFfmpegLaunchTime, BUFFER_AMOUNT);
            }
        }

    }

    public var predefinedPlaybackRate:Array;
    private static const playbackRateBucketSize:Number = 1;
    override public function setPredefinedPlaybackRate(val:Array):void {

        predefinedPlaybackRate = val;

        if(val != null) {

            seekPoint += netStream.time * _playbackRate;
            nextFfmpegLaunchTime = seekPoint;

            if(FfmpegVideoPlayer.ffmpeg && FfmpegVideoPlayer.ffmpeg.running) {
                FfmpegVideoPlayer.ffmpeg.exit();
            } else {
                launchFFmpeg(nextFfmpegLaunchTime, -1);
            }
        }
    }

    private var renderTimerX:Number;
    private var lengthToRender:Number;
    private function launchFFmpeg(startTime:Number, length:Number):void {
        startTime = Math.max(0, uint(startTime * 100)/100);

        if(startTime > _videoDuration)
            startTime = _videoDuration;

        renderTimer.reset();

        ffmpegLaunchTime = startTime;
        if(firstRun) {
            ffmpegStartupInfo = new NativeProcessStartupInfo();
        }

        var operatingSystem:String = Capabilities.os;
        var file:File;
        if(operatingSystem.indexOf("Mac") >= 0) {
            file = File.applicationDirectory.resolvePath("ffmpeg");
        } else if(operatingSystem.indexOf("Windows") >= 0) {
            file = File.applicationDirectory.resolvePath("ffmpeg.exe");
        }

        ffmpegStartupInfo.executable = file;

        if(predefinedPlaybackRate != null && startTime/playbackRateBucketSize < predefinedPlaybackRate.length) {
            // trace(startTime  + ": predefinedPlaybackRate[" + (uint)(startTime/playbackRateBucketSize) + "] = " + predefinedPlaybackRate[(uint)(startTime/playbackRateBucketSize)])


            var lastKnownTime:Number = startTime;
            var playbackRateIndexAtLastKnownTime:uint = lastKnownTime/playbackRateBucketSize;

            var playbackSpeedAtLastKnownTime:Number = predefinedPlaybackRate[playbackRateIndexAtLastKnownTime];

            var remainingFromLastKnownTime:Number = (playbackRateBucketSize/playbackSpeedAtLastKnownTime) -
                    (lastKnownTime/playbackSpeedAtLastKnownTime) %
                    (playbackRateBucketSize/playbackSpeedAtLastKnownTime);

            // trace(lastKnownTime);
            // trace(playbackRateBucketSize/playbackSpeedAtLastKnownTime + " " + (lastKnownTime/playbackSpeedAtLastKnownTime)%(playbackRateBucketSize/playbackSpeedAtLastKnownTime))

            _playbackRate = playbackSpeedAtLastKnownTime;
            length = remainingFromLastKnownTime;
            if(length < 1/30) {
                length = playbackRateBucketSize / playbackSpeedAtLastKnownTime;
            }
            // trace("length = " + length);
        } else {}

        // trace("_playbackRate = " + _playbackRate)

        var inputSeek:Number = findKeyframe(startTime);
        var outputSeek:Number = (startTime - inputSeek)/_playbackRate;

        // libx264 requires the width of the video to be a multiple of 2
//			var videoWidth:uint = uint(Math.min(_videoDimensions.width, stageVideoWidth)/2 /1.0 ) * 2;
		/* lower the resolution a bit to make it faster :P   ^^^ */
        var videoWidth:uint = uint(_videoDimensions.width);

        lengthToRender = Math.min(length, Math.max(0, _videoDuration/_playbackRate - startTime/_playbackRate));
        // trace("length = " + length);
        // trace(_videoDuration + "/" + _playbackRate + " - " + startTime + "/" + _playbackRate + "=" + (_videoDuration/_playbackRate - startTime/_playbackRate) )
        // trace(Math.max(0, _videoDuration/_playbackRate - startTime/_playbackRate));
        ffmpegArgs = new Vector.<String>();
        ffmpegArgs.push("-ss", inputSeek,
                "-i", _videoFilePath,
                "-ss", outputSeek,
                "-vcodec", "libx264",
                "-profile:v", "high10",
                "-level", "5.2",
                "-crf", "28",
                "-vf", "setpts=" + 1/_playbackRate + "*PTS,scale=" + videoWidth + ":trunc(ow/a/2)*2",
                "-af", "atempo=" + _playbackRate,
                "-t", (uint)(lengthToRender * 100)/100,
                "-preset", "ultrafast",
                "-ar", "44100",
                "-threads", "1",
                "-f", "flv",
                "-loglevel", "panic",
                "-");
        ffmpegStartupInfo.arguments = ffmpegArgs;

        // var traceString:String = "";
        // traceString += (file.nativePath);
        // for(var i:int = 0; i<ffmpegArgs.length; i++) {
        // 	traceString += (" " + ffmpegArgs[i])
        // }
        // trace(traceString);
        // trace("startTime = " + startTime + "\t-ss " + inputSeek + "\t-ss " + outputSeek + "\t-t " + lengthToRender);

        if(firstRun)
            FfmpegVideoPlayer.ffmpeg = new NativeProcess();

        firstFrameAvailable = false;
        if(firstRun) {
            FfmpegVideoPlayer.ffmpeg.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
            FfmpegVideoPlayer.ffmpeg.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
            FfmpegVideoPlayer.ffmpeg.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
            FfmpegVideoPlayer.ffmpeg.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
            FfmpegVideoPlayer.ffmpeg.addEventListener(NativeProcessExitEvent.EXIT, onExit);
        }
        firstRun = false;
        loadActionWaiting = false;

        if(!FfmpegVideoPlayer.ffmpeg.running) {
            renderTimerX = getTimer();
            FfmpegVideoPlayer.ffmpeg.start(ffmpegStartupInfo);
        } else {
            FfmpegVideoPlayer.ffmpeg.exit();
        }

    }

    private var videoStream:ByteArray = new ByteArray();
    private function onOutputData(event:ProgressEvent):void {

        videoStream.clear();
        FfmpegVideoPlayer.ffmpeg.standardOutput.readBytes(videoStream, 0, FfmpegVideoPlayer.ffmpeg.standardOutput.bytesAvailable);

        if(!firstFrameAvailable) {
            if(seekActionWaiting || playbackRateActionWaiting) {
                netStream.seek(0);
                seekActionWaiting = false;
                playbackRateActionWaiting = false;
            }
            netStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);

            firstFrameAvailable = true;
        }

        netStream.appendBytes(videoStream);

    }

    private function onErrorData(event:ProgressEvent):void {
        var message:String = FfmpegVideoPlayer.ffmpeg.standardError.readUTFBytes(FfmpegVideoPlayer.ffmpeg.standardError.bytesAvailable)
        trace("\n______\nerrorOutput: \n"+ message + "\n______\n\n");
    }

    private function onIOError(event:IOErrorEvent):void {
        trace((event.toString()) + "\n");
    }

    private var nextRenderLength:Number;
    private function onExit(event:NativeProcessExitEvent):void {
        // trace("videowidth = " + stageVideoViewPort.width + ", render time = " + (flash.utils.getTimer() - renderTimerX) + ", exit code = " + event.exitCode);

        // called NativeProcess.exit()
        if(isNaN(event.exitCode)) {
            if(seekActionWaiting || playbackRateActionWaiting || loadActionWaiting)
                launchFFmpeg(nextFfmpegLaunchTime, BUFFER_AMOUNT);

        } else {

            if(!seekActionWaiting && !playbackRateActionWaiting) {
                nextFfmpegLaunchTime += lengthToRender * _playbackRate;
            } else if(playbackRateActionWaiting) {
                nextFfmpegLaunchTime = playheadTime;
            }


            // trace("nextFfmpegLaunchTime = " + nextFfmpegLaunchTime)

            renderTimer.delay = Math.max(0, netStream.bufferLength * 1000 - (lengthToRender*0.5) * 1000);

            if(nextFfmpegLaunchTime < _videoDuration && state == VideoState.PLAYING) {
                renderTimer.start();
            }

            nextRenderLength = predefinedPlaybackRate == null ? BUFFER_AMOUNT : -1;

            renderTimer.addEventListener(TimerEvent.TIMER, bufferTimerFunction);

            if(seekActionWaiting || playbackRateActionWaiting) {
                launchFFmpeg(nextFfmpegLaunchTime, nextRenderLength);
            }
        }
    }

    private function bufferTimerFunction(e:TimerEvent):void {
        // bufferLaunch = true;
        launchFFmpeg(nextFfmpegLaunchTime, nextRenderLength);
        renderTimer.removeEventListener(TimerEvent.TIMER, bufferTimerFunction);
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

    override public function setSize(width:Number, height:Number):void {
        _width = width;
        _height = height;
        refreshViewPort();
    }

    override public function move(x:Number, y:Number):void {
        this.x = x;
        this.y = y;
    }

    private function refreshViewPort():void {
        stageVideoWidth = uint(Math.max(1, Math.min(_width, _height*aspectRatio)));
        stageVideoHeight = uint(stageVideoWidth/aspectRatio);

        stageVideo.x = _width/2 - stageVideoWidth/2;
        stageVideo.y = _height/2 - stageVideoHeight/2;

        if(stageVideo.width != stageVideoWidth || stageVideo.height != stageVideoHeight) {
            stageVideo.readjustSize(stageVideoWidth, stageVideoHeight);
//                trace("StageVideo: x" + stageVideo.x + " y" + stageVideo.y + " w" + stageVideo.width + " h" + stageVideo.height)
//                trace("Texture: w" + texture.frameWidth + " h" + texture.frameHeight);
        }


        background.clear();
        background.beginFill(0);
        background.drawRectangle(0, 0, _width, _height);
        background.endFill();
    }

    private function findKeyframe(time:Number):Number {

        var keyframesLength:int = _videoKeyframes.length;
        for(var i:int = 1; i<keyframesLength; i++) {
            if(_videoKeyframes[i] > time) {
                return _videoKeyframes[i-1];
            }
        }
        return _videoKeyframes[_videoKeyframes.length - 1];
    }
}
}