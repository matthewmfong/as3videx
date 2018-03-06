////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.video {
import ca.ubc.ece.hct.myview.*;

	import com.adobe.serialization.json.JSON;
	import collections.HashMap;

import flash.events.Event;

import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import flash.filesystem.FileStream;
import flash.utils.getTimer;

import org.osflash.signals.Signal;

	import com.greensock.*;
	import com.greensock.loading.*;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.display.*;

	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
    import flash.filesystem.File;
	import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.NativeProcessExitEvent;
    import flash.events.ProgressEvent;
    import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
    import flash.utils.ByteArray;
    import flash.display.Bitmap;

import spark.primitives.Rect;

import starling.core.Starling;

import starling.display.Image;

import starling.textures.Texture;

public class VideoUtil extends EventDispatcher {

		public var message:String;
		public var streamData:Signal;
		public var imageLoadSignal:Signal;
		public var queue:LoaderMax;
		private static var _instance:VideoUtil;

		public function VideoUtil() {
	        if(_instance){
	            throw new Error("VideoUtil is a Singleton. Use getInstance()!");
	        } 

            streamData = new Signal(VideoStreamData);
            imageLoadSignal = new Signal(Number, Object, Bitmap); // time, target, image bitmap
			queue = new LoaderMax({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});
			queue.autoLoad = true;
			queue.maxConnections = 5;

	        _instance = this;
	    }

	    public static function getInstance():VideoUtil {
	        if(!_instance){
	            _instance = new VideoUtil();
	        } 
	        return _instance;
	    }


CONFIG::AIR {
// ---------------------------------------------------------------------------------------------- //
//  get stream data                                                                               //
// ---------------------------------------------------------------------------------------------- //
		private var ffprobe:NativeProcess;
		private var ffprobeStartupInfo:NativeProcessStartupInfo;
		private var ffprobeArgs:Vector.<String>;
		
		public function getStreamData(videoFilename:String, absolutePath:Boolean = false):void {
			if(!absolutePath)
				videoFilename = resolveFilename(videoFilename);

			ffprobeStartupInfo = new NativeProcessStartupInfo();

            var file:File = File.applicationDirectory.resolvePath("ffprobe");
            ffprobeStartupInfo.executable = file;

            ffprobeArgs = new Vector.<String>();
            ffprobeArgs.push(videoFilename,
            				 "-v", "quiet",
            				 // "-show_entries", "stream=width,height,duration,avg_frame_rate,codec_type",
            				 "-show_streams",
            				 "-print_format", "json");
            ffprobeStartupInfo.arguments = ffprobeArgs;

            // trace(file.nativePath);

            // for(var i:int = 0; i<ffmpegArgs.length; i++) {
            	// trace(" \n" + i + ": " + ffmpegArgs[i])
            // }

            // trace("\n")
            var traceString:String = "";
            traceString += (file.nativePath);
            for(var i:int = 0; i<ffprobeArgs.length; i++) {
            	traceString += " " + ffprobeArgs[i];
            }
            trace(traceString);

        	ffprobe = new NativeProcess();
            ffprobe.start(ffprobeStartupInfo);

            ffprobe.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, ffprobeOnOutputData);
            ffprobe.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, ffprobeOnErrorData);
            ffprobe.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ffprobeOnIOError);
            ffprobe.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, ffprobeOnIOError);
            ffprobe.addEventListener(NativeProcessExitEvent.EXIT, ffprobeOnExit);
		}

		private function ffprobeOnOutputData(e:ProgressEvent):void {
			message = ffprobe.standardOutput.readUTFBytes(ffprobe.standardOutput.bytesAvailable)
	        // trace("______Output: \n"+ message + "______");

	        var obj:* = com.adobe.serialization.json.JSON.decode(message);

	        var streams:VideoStreamData = new VideoStreamData();
	        
	        for(var id:String in obj.streams) {
	          var value:Object = obj.streams[id];

	          var stream:Stream = new Stream(value.codec_type)

	          streams.add(stream);

	          for(var id2:String in value) {
		          var value2:Object = value[id2];
		          stream.put(id2, value2);

		        }
	        }
			
			streamData.dispatch(streams);
		}

		private function ffprobeOnErrorData(e:ProgressEvent):void {
			message = ffprobe.standardError.readUTFBytes(ffprobe.standardError.bytesAvailable)
	        trace("\n______\nOutput: "+ message + "\n______\n\n");
		}

		private function ffprobeOnIOError(e:IOErrorEvent):void {

		}

		private function ffprobeOnExit(e:NativeProcessExitEvent):void {
	        dispatchEvent(new VideoUtilEvent(VideoUtilEvent.EXIT));
		}

// ---------------------------------------------------------------------------------------------- //
//  get keyframes                                                                                 //
// ---------------------------------------------------------------------------------------------- //

		private var ffprobeKeyframes:NativeProcess;
		private var ffprobeKeyframesStartupInfo:NativeProcessStartupInfo;
		private var ffprobeKeyframesArgs:Vector.<String>;
		private var keyframes:Array;
		public static const ffprobeKeyframesTimeRegex:RegExp = /[0-9]{1,}\.[0-9]{1,}/g;

		public function getKeyframes(videoFilename:String, absolutePath:Boolean = false):void {
			if(!absolutePath)
				videoFilename = resolveFilename(videoFilename);
			
			keyframes = [];
			ffprobeKeyframesStartupInfo = new NativeProcessStartupInfo();

			var file:File = File.applicationDirectory.resolvePath("ffprobe");
            // var file:File = new File("/opt/local/bin/ffprobe");
            ffprobeKeyframesStartupInfo.executable = file;

            ffprobeKeyframesArgs = new Vector.<String>();
            ffprobeKeyframesArgs.push("-select_streams", "v",
            				 "-show_frames",
            				 "-v", "quiet",
            				 "-show_entries", "frame=best_effort_timestamp_time",
            				 "-skip_frame", "nokey",
            				 videoFilename);
            ffprobeKeyframesStartupInfo.arguments = ffprobeKeyframesArgs;

            // trace(file.nativePath);

            // for(var i:int = 0; i<ffmpegArgs.length; i++) {
            	// trace(" \n" + i + ": " + ffmpegArgs[i])
            // }

            // trace("\n")
            var traceString:String = "";
            traceString += file.nativePath;
            for(var i:int = 0; i<ffprobeKeyframesArgs.length; i++) {
            	traceString += (" " + ffprobeKeyframesArgs[i])
            }
            trace(traceString);

        	ffprobeKeyframes = new NativeProcess();
            ffprobeKeyframes.start(ffprobeKeyframesStartupInfo);

            ffprobeKeyframes.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, ffprobeKeyframesOnOutputData);
            ffprobeKeyframes.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, ffprobeKeyframesOnErrorData);
            ffprobeKeyframes.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ffprobeKeyframesOnIOError);
            ffprobeKeyframes.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, ffprobeKeyframesOnIOError);
            ffprobeKeyframes.addEventListener(NativeProcessExitEvent.EXIT, ffprobeKeyframesOnExit);
		}

		private function ffprobeKeyframesOnOutputData(e:ProgressEvent):void {
			message = ffprobeKeyframes.standardOutput.readUTFBytes(ffprobeKeyframes.standardOutput.bytesAvailable)
	        // trace("\n______\nOutput: "+ message + "\n______\n\n");

	        var result:String = ffprobeKeyframesTimeRegex.exec(message);
         
	        while (result != null) {
	            // trace (result + " = " + Number(result) + "\n");
	        	keyframes.push(Number(result));
	            dispatchEvent(new VideoUtilEvent(VideoUtilEvent.KEYFRAMES_PROGRESS, null, 0, null, Number(result)));
	            result = ffprobeKeyframesTimeRegex.exec(message);
	        }
		}

		private function ffprobeKeyframesOnErrorData(e:ProgressEvent):void {
			message = ffprobeKeyframes.standardError.readUTFBytes(ffprobeKeyframes.standardError.bytesAvailable)
	        // trace("______Output: "+ message + "______");
		}

		private function ffprobeKeyframesOnIOError(e:IOErrorEvent):void {

		}

		private function ffprobeKeyframesOnExit(e:NativeProcessExitEvent):void {
			// video.keyframes = keyframes;
			// trace("ffprobe finished running. Found " + keyframes.length + " keyframes.");
			var st:String = "";
			for(var i:int = 0; i<keyframes.length; i++) {
				st += keyframes[i] + ", ";
			}
			trace(st);

			dispatchEvent(new VideoUtilEvent(VideoUtilEvent.KEYFRAMES_LOADED,
											 null,
											 -1,
											 keyframes));
			// launchFFmpeg(4);
		}


// ---------------------------------------------------------------------------------------------- //
//  render frame                                                                                 //
// ---------------------------------------------------------------------------------------------- //

		private var ffmpegFile:File;
		private var ffmpeg:NativeProcess;
		public static var numRunning:uint;
		private var ffmpegStartupInfo:NativeProcessStartupInfo;
		private var ffmpegArgs:Vector.<String>;
		private var startDate:Number;
		private var outputWidth:uint, outputHeight:uint;

		public var renderQueue:Array = [];
		public var currentRenderObject:Object;

		public static var RESET_INTERVAL:Number = 10;
		public var framesRenderedSinceLastReset:Number = 0;
		public var timeSpentRenderingSinceLastReset:Number = 0;
		private var shrinkRenderToSpeedUpRenderingRatio:Number = 1;

		public function renderFrame(absolutePath:String,
									dimensions:Point,
									keyframes:Array,
									time:Number,
									outputWidth:uint,
									thumbnailID:uint = -1,
									autosize:Boolean = true,
									exact:Boolean = false,
									numSequentialFrames:Number = 1,
									callbackSignal:Signal = null):void {

			// trace("Already rendering... pushing. queue length" + renderQueue.length);

			if(ffmpeg && ffmpeg.running) {
				var queueObject:Object = {absolutePath:absolutePath,
										  dimensions:dimensions,
					keyframes:keyframes,
					time:time,
					outputWidth:outputWidth,
					thumbnailID:thumbnailID,
					numSequentialFrames:numSequentialFrames,
					callbackSignal:callbackSignal};
//				trace("QUEUEING LOL " + callbackSignal);
				renderQueue.push(queueObject);
				// trace("currently rendering... pushing. queue length" + renderQueue.length);
			} else {
				currentRenderObject = {absolutePath:absolutePath,
					dimensions:dimensions,
					keyframes:keyframes,
					time:time,
					outputWidth:outputWidth,
					thumbnailID:thumbnailID,
					numSequentialFrames:numSequentialFrames,
					callbackSignal:callbackSignal};
//				trace("LET'S DO THIS: " + callbackSignal);
				// trace(currentRenderObject.absolutePath + " " + currentRenderObject.time + " " + currentRenderObject.thumbnailID)
				// var video:Video = VideoManager.getInstance().getVideo(videoFilename.substring("/Videos/".length-1, videoFilename.length));
				// trace(videoFilename.substring("/Videos/".length, videoFilename.length))
				// if(!absolutePath)
				// 	videoFilename = resolveFilename(videoFilename);

				if(!ffmpegFile) {
					var operatingSystem:String = Capabilities.os;
//					trace("shit, this isn't right.")
			        if(operatingSystem.indexOf("Mac") >= 0) {
                        trace(File.applicationDirectory.nativePath);
                        trace(File.applicationDirectory.resolvePath("ffmpeg").nativePath);
						ffmpegFile = File.applicationDirectory.resolvePath("ffmpeg");
                        Util.chmod("", "+x", ffmpegFile.nativePath);
					} else if(operatingSystem.indexOf("Windows") >= 0) {
						ffmpegFile = File.applicationDirectory.resolvePath("ffmpeg.exe");
					}

					ffmpegStartupInfo = new NativeProcessStartupInfo();
		            ffmpegStartupInfo.executable = ffmpegFile;
	            	ffmpeg = new NativeProcess();
		            ffmpeg.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
		            ffmpeg.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
		            ffmpeg.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
		            ffmpeg.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
		            ffmpeg.addEventListener(NativeProcessExitEvent.EXIT, onExit);
				}

				var inputSeek:Number = findKeyframe(time, keyframes);
				var outputSeek:Number = (time - inputSeek);

				// anything bigger makes it REEEEALLY slow...
				if(outputSeek > 0.5 && !exact) {
					outputSeek = 0;
				}
				// trace("outputSeek = " + outputSeek);

				 if(autosize)
				 	this.outputWidth = outputWidth / shrinkRenderToSpeedUpRenderingRatio;
				 else
					this.outputWidth = outputWidth;

	            ffmpegArgs = new Vector.<String>();
	            ffmpegArgs.push(
				            	"-ss", inputSeek,
	            				"-i", currentRenderObject.absolutePath,
	            				"-ss", outputSeek,
	            				"-frames:v", currentRenderObject.numSequentialFrames,
	            				"-vf", "scale=" + this.outputWidth + ":trunc(ow/a/2)*2",
	            				"-pix_fmt", "argb",
	            				"-f", "rawvideo",
	            				"-loglevel", "panic",
	            				// "-threads", "1",
	            				"-"
	            				);
	            ffmpegStartupInfo.arguments = ffmpegArgs;

	            if(!ffmpeg.running) {
	            	
		            // var traceString:String = "";
		            // traceString += (ffmpegFile.nativePath);
		            // for(var i:int = 0; i<ffmpegArgs.length; i++) {
		            // 	traceString += (" " + ffmpegArgs[i])
		            // }
		           	// trace(traceString);

					// trace(video.filename);
					this.outputHeight = uint(this.outputWidth * (dimensions.y/dimensions.x) / 2) *2;

					startDate = flash.utils.getTimer();

//					for(var id:String in currentRenderObject) {
//						trace(id + " " + currentRenderObject[id]);
//					}
//                    trace(ffmpegStartupInfo);
//                    trace(ffmpegStartupInfo.arguments);
//					trace(ffmpeg);

					try {
                        ffmpeg.start(ffmpegStartupInfo);
                    } catch(e:Error) {
						trace(e);
					}
		           	// trace("numRunning = " + (++VideoUtil.numRunning));
		        } 
		    }
	        // else {
	        // 	trace("cancelled");
	        // }

	        // firstRun = false;
			// runFfmpegWithNewParameters = false;

		}

		private var abc:ByteArray = new ByteArray();
		private var videoStream:ByteArray = new ByteArray();


		private function onOutputData(event:ProgressEvent):void {
			videoStream.clear();
			ffmpeg.standardOutput.readBytes(videoStream, 0, ffmpeg.standardOutput.bytesAvailable);
			abc.writeBytes(videoStream, 0, videoStream.length);
	    }

	    private function onErrorData(event:ProgressEvent):void {
	    	message = ffmpeg.standardError.readUTFBytes(ffmpeg.standardError.bytesAvailable)
	        trace("\n______\nerrorOutput: "+ message + "\n______\n\n"); 
	    	// dispatchEvent(new FfmpegEvent(FfmpegEvent.PROGRESS, null, ": " + message))
	    	// trace(netStream.time + "\n");
	    }

	    private function onIOError(event:IOErrorEvent):void{
	         // trace((event.toString()) + "\n");
		}

		private var totalTime:Number = 0;
		private var numTimes:uint = 0;
		private var newBA:ByteArray = new ByteArray();
		private var finalVideoDimensions:Rectangle = new Rectangle(0, 0, 0, 0);
		private function onExit(event:NativeProcessExitEvent):void {
			var timeSpent:uint = (flash.utils.getTimer() - startDate);
			if(timeSpent < 1000) {
				timeSpentRenderingSinceLastReset += (flash.utils.getTimer() - startDate);
				framesRenderedSinceLastReset++;
			}
			var averageTimeSpent:Number = timeSpentRenderingSinceLastReset/framesRenderedSinceLastReset;
			// trace("render time = " + timeSpent + "ms. average time = " + averageTimeSpent);
			
			if(framesRenderedSinceLastReset > RESET_INTERVAL) {
				if(averageTimeSpent > 80) {
					shrinkRenderToSpeedUpRenderingRatio = Math.min(10, (uint)((shrinkRenderToSpeedUpRenderingRatio += 0.2) * 10)/10);
					// Main.log("VideoUtil: shrinkRatio increased to " + shrinkRenderToSpeedUpRenderingRatio);
				} else if(averageTimeSpent < 70) {
					shrinkRenderToSpeedUpRenderingRatio = Math.max(1, (uint)((shrinkRenderToSpeedUpRenderingRatio -= 0.2) * 10)/10);
					// Main.log("VideoUtil: shrinkRatio decreased to " + shrinkRenderToSpeedUpRenderingRatio);
				} else {
					// trace("rendering time is good, don't change it");
				}
				timeSpentRenderingSinceLastReset = 0;
				framesRenderedSinceLastReset = 0;
			}
			// trace(flash.utils.getTimer());


			// trace(--VideoUtil.numRunning);
			abc.position = 0;

			newBA.clear();
			newBA.writeBytes(abc, 0, abc.length);
			newBA.position = 0;

			// totalTime += (new Date().time-startDate.time);
			// numTimes++;
			// trace("f = \t" + (new Date().time-startDate.time) + "ms. Average time = " + totalTime/numTimes + " " + numTimes);
			abc.clear();

			// trace("VideoUtil.onExit.dispatchEvent(new VideoUtilEvent");
			finalVideoDimensions.width = outputWidth;
			finalVideoDimensions.height = outputHeight;

//			trace("currentRenderObject.callbackSignal: " + currentRenderObject.callbackSignal);

			if(currentRenderObject.callbackSignal) {
				currentRenderObject.callbackSignal.dispatch(finalVideoDimensions, newBA);
			}

//			dispatchEvent(new VideoUtilEvent(VideoUtilEvent.RENDERED_FRAME,
//											 finalVideoDimensions,
//											 0, null, 0, newBA, null, currentRenderObject.time, currentRenderObject.thumbnailID));

//			trace("RENDERQUEUELENGTH: " + renderQueue.length)
			if(renderQueue.length > 0) {
				currentRenderObject = renderQueue.shift();

//				trace("NEXT: " + currentRenderObject.callbackSignal);

				// trace("finished, next object of " + renderQueue.length);
				renderFrame(currentRenderObject.absolutePath,
							currentRenderObject.dimensions,
							currentRenderObject.keyframes,
							currentRenderObject.time,
							currentRenderObject.outputWidth,
							currentRenderObject.thumbnailID,
							true,
							true,
							1,
							currentRenderObject.callbackSignal);

			}
		}

		private function findKeyframe(time:Number, keyframes:Array):Number {
			// trace("findKeyframe(" + time + ")")
			if(keyframes) {
				var keyframesLength:int = keyframes.length;
				for(var i:int = 1; i<keyframesLength; i++) {
					// trace(keyframes[i])
					if(keyframes[i] > time) {
						// trace("FOUND " + keyframes[i] + " " + time + "\n");
						return keyframes[i-1];
					}
				}
				return keyframes[keyframes.length - 1];
			} else {
				return 0;
			}
		}

		private function resolveFilename(filename:String):String {
            var file:File = File.applicationStorageDirectory;
            file.resolvePath(filename);
            return file.nativePath + "/" + filename;
		}
	}

// ---------------------------------------------------------------------------------------------- //
//  get frame                                                                                     //
// ---------------------------------------------------------------------------------------------- //

	public function getFrame(time:Number, target:*):void {
		queue.append(new ImageLoader("http://159.203.21.240/thumbnail_test/BoA/BoA" + (Math.round(time*5)+1) + ".jpg",
									 {name: time, target: target}));
		
	}

	private function progressHandler(event:LoaderEvent):void {
	    trace("progress: " + event.target.progress);
	}

	private function completeHandler(event:LoaderEvent):void {
		trace("asdf " + event.target.content[0].name);

	    var image:ContentDisplay = (ContentDisplay)(event.target.content[0]);//LoaderMax.getContent("asdf");
	    
	    imageLoadSignal.dispatch(Number(event.target.content[0].name), image.rawContent, null)
	}
	 
	private function errorHandler(event:LoaderEvent):void {
	    trace("error occured with " + event.target + ": " + event.text);
	}

// ---------------------------------------------------------------------------------------------- //
//  legacy                                                                                        //
// ---------------------------------------------------------------------------------------------- //



// ---------------------------------------------------------------------------------------------- //
//  get dimensions                                                                                //
// ---------------------------------------------------------------------------------------------- //

	CONFIG::AIR {

		private var ffprobeDimensions:NativeProcess;
		private var ffprobeDimensionsStartupInfo:NativeProcessStartupInfo;
		private var ffprobeDimensionsArgs:Vector.<String>;
		private var videoDimensions:Point;

		public function getDimensions(videoFilename:String, absolutePath:Boolean = false):void {
			if(!absolutePath)
				videoFilename = resolveFilename(videoFilename);

			ffprobeDimensionsStartupInfo = new NativeProcessStartupInfo();

            var file:File = File.applicationDirectory.resolvePath("ffprobe");
            ffprobeDimensionsStartupInfo.executable = file;

            ffprobeDimensionsArgs = new Vector.<String>();
            ffprobeDimensionsArgs.push(videoFilename,
            				 "-v", "quiet",
            				 "-show_entries", "stream=width,height",
            				 "-select_streams", "v");
            ffprobeDimensionsStartupInfo.arguments = ffprobeDimensionsArgs;

            // trace(file.nativePath);

            // for(var i:int = 0; i<ffmpegArgs.length; i++) {
            	// trace(" \n" + i + ": " + ffmpegArgs[i])
            // }

            // trace("\n")
            var traceString:String = "";
            traceString += (file.nativePath);
            for(var i:int = 0; i<ffprobeDimensionsArgs.length; i++) {
            	traceString += " " + ffprobeDimensionsArgs[i];
            }
            trace(traceString);

        	ffprobeDimensions = new NativeProcess();
            ffprobeDimensions.start(ffprobeDimensionsStartupInfo);

            ffprobeDimensions.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, ffprobeDimensionsOnOutputData);
            ffprobeDimensions.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, ffprobeDimensionsOnErrorData);
            ffprobeDimensions.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ffprobeDimensionsOnIOError);
            ffprobeDimensions.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, ffprobeDimensionsOnIOError);
            ffprobeDimensions.addEventListener(NativeProcessExitEvent.EXIT, ffprobeDimensionsOnExit);
		}

		private function ffprobeDimensionsOnOutputData(e:ProgressEvent):void {
			message = ffprobeDimensions.standardOutput.readUTFBytes(ffprobeDimensions.standardOutput.bytesAvailable)
	        // trace("______Output: "+ message + "______");
			var dimensionRegex:RegExp = /[0-9]{1,}\.[0-9]{1,}|[0-9]{1,}/g;
			var dimensionNumbers:Array = []; // there should only be two.
	        var result:String = dimensionRegex.exec(message);
         
	        while (result != null) {
	            // trace (result + " = " + Number(result) + "\n");
	        	dimensionNumbers.push(Number(result));
	            result = dimensionRegex.exec(message);
	        }

	        // if(dimensionNumbers.length != 2) {
	        // 	throw new Error("ffprobe found more than 2 number dimensions... what? || " + message);
	        // }
	        // videoDimensions = ;
	        // videoDuration = dimensionNumbers[2];
	        dispatchEvent(new VideoUtilEvent(VideoUtilEvent.DIMENSIONS_LOADED,
	        								 new Rectangle(0, 0, dimensionNumbers[0], dimensionNumbers[1])))
		}

		private function ffprobeDimensionsOnErrorData(e:ProgressEvent):void {
			message = ffprobeDimensions.standardError.readUTFBytes(ffprobeDimensions.standardError.bytesAvailable)
	        trace("\n______\nOutput: "+ message + "\n______\n\n");
		}

		private function ffprobeDimensionsOnIOError(e:IOErrorEvent):void {

		}

		private function ffprobeDimensionsOnExit(e:NativeProcessExitEvent):void {
	        dispatchEvent(new VideoUtilEvent(VideoUtilEvent.EXIT));
		}

// ---------------------------------------------------------------------------------------------- //
//  get duration                                                                                  //
// ---------------------------------------------------------------------------------------------- //

		private var ffmpegDuration:NativeProcess;
		private var ffmpegDurationStartupInfo:NativeProcessStartupInfo;
		private var ffmpegDurationArgs:Vector.<String>;

		public function getDuration(videoFilename:String, absolutePath:Boolean = false):void {
			if(!absolutePath)
				videoFilename = resolveFilename(videoFilename);
			
			ffmpegDurationStartupInfo = new NativeProcessStartupInfo();

            var file:File;
			var operatingSystem:String = Capabilities.os;
	        if(operatingSystem.indexOf("Mac") >= 0) {
				file = File.applicationDirectory.resolvePath("ffmpeg");
			} else if(operatingSystem.indexOf("Windows") >= 0) {
				file = File.applicationDirectory.resolvePath("ffmpeg.exe");
			}
            ffmpegDurationStartupInfo.executable = file;

            ffmpegDurationArgs = new Vector.<String>();
            ffmpegDurationArgs.push("-i", videoFilename);
            ffmpegDurationStartupInfo.arguments = ffmpegDurationArgs;

            // trace(file.nativePath);

            // for(var i:int = 0; i<ffmpegArgs.length; i++) {
            	// trace(" \n" + i + ": " + ffmpegArgs[i])
            // }

            // trace("\n")
            var traceString:String = "";
            traceString += (file.nativePath);
            for(var i:int = 0; i<ffmpegDurationArgs.length; i++) {
            	traceString += " " + ffmpegDurationArgs[i];
            }
            trace(traceString);

        	ffmpegDuration = new NativeProcess();
            ffmpegDuration.start(ffmpegDurationStartupInfo);

            ffmpegDuration.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, 	ffmpegDurationOnOutputData);
            ffmpegDuration.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, 		ffmpegDurationOnErrorData);
            ffmpegDuration.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, 	ffmpegDurationOnIOError);
            ffmpegDuration.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, 	ffmpegDurationOnIOError);
            ffmpegDuration.addEventListener(NativeProcessExitEvent.EXIT, 			ffmpegDurationOnExit);
		}

		private function ffmpegDurationOnOutputData(e:ProgressEvent):void {
			message = ffmpegDuration.standardOutput.readUTFBytes(ffmpegDuration.standardOutput.bytesAvailable)
	        // trace("______Output: \n"+ message + "\n______");
		}

		private function ffmpegDurationOnErrorData(e:ProgressEvent):void {
			message = ffmpegDuration.standardError.readUTFBytes(ffmpegDuration.standardError.bytesAvailable)
	        // trace("\n______\nOutput: "+ message + "\n______\n\n");

	        var durationRegex:RegExp = /Duration: \d\d:\d\d:\d\d\.\d\d,/g;
	        var result:String = durationRegex.exec(message);
	        // trace("___ result" + result + "___")

	        if(result != null) {
	         	var firstSpace:int = result.indexOf(" ");
	         	// isolate the time
		        result = result.substring(firstSpace+1, result.length-1);
		        var arr:Array = result.split(/(\:|\.)/);
		        // trace(arr + " " + arr.length);

		        var duration:Number = 0;
		        for(var i:int = 0; i<arr.length; i++) {
		        	if(Number(arr[i])) {
		        		switch(i) {
		        			case 0: // hours
		        				duration += 3600 * Number(arr[i]);
		        				break;
		        			case 2: // minutes
		        				duration += 60 * Number(arr[i]);
		        				break;
		        			case 4: // seconds
		        				duration += Number(arr[i]);
		        				break;
		        			case 6: // tenths of a second
		        				duration += Number(arr[i]) / 100;
		        				break;
		        		}
		        	}
		        }
	        dispatchEvent(new VideoUtilEvent(VideoUtilEvent.DURATION_LOADED,
	        								 null,
	        								 duration))
		    }
		}

		private function ffmpegDurationOnIOError(e:IOErrorEvent):void {

		}

		private function ffmpegDurationOnExit(e:NativeProcessExitEvent):void {
	        dispatchEvent(new VideoUtilEvent(VideoUtilEvent.EXIT));
		}
	}
	}

}
