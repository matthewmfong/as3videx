////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct {

import ca.ubc.ece.hct.myview.Util;

import com.deng.fzip.*;
	import org.osflash.signals.Signal;
	import ca.ubc.ece.hct.ConnectionChecker;
	import ca.ubc.ece.hct.URLLoaderPlus;
//	import ca.ubc.ece.hct.ProgressiveDownloader;

	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;

	public class Patcher {

		public static var CLASS_ID:String;
		public static var VERSION_FILENAME:String = "version.json";
		public static var CONNECTION_CHECK_URL:String = "http://animatti.ca/";
		public static var VERSION_CHECK_URL:String = "http://animatti.ca/myview/tlef/version/version.json";

		public static const STATE_CHECK_VERSION:String = "Checking version";
		public static const STATE_DOWNLOADING_APP:String = "Downloading app";
		public static const STATE_DOWNLOADING_FFMPEG:String = "Downloading ffmpeg";
		public static const STATE_UNZIPPING_APP:String = "Unzipping app";
		public static const STATE_UNZIPPING_FFMPEG:String = "Unzipping ffmpeg";
		public static const UPDATE_COMPLETE:String = "Update Complete";

		private var cc:ConnectionChecker;

		public var patchComplete:Signal;
		public var patchFailed:Signal;
		public var offline:Signal;
		public var appDownloadProgress:Signal;
		public var ffmpegDownloadProgress:Signal;
		public var ffmpegDownloadSpeed:Signal;
		public var state:Signal;

		private var versionFile:File;
		private var versionURLLoader:URLLoaderPlus;
		private var appURLLoader:URLLoaderPlus;
//		private var ffmpegURLLoader:ProgressiveDownloader;

		private var _bytesTotal:uint;
		private var _bytesLoaded:uint;

		private var appURL:String;
		private var ffmpegURL:String;

		private var appZip:FZip;
		private var ffmpegZip:FZip;
		private var appUpdated:Boolean;
		private var ffmpegUpdated:Boolean;

		public function Patcher(inputClassID:String) {
			CLASS_ID = inputClassID;
			patchComplete = new Signal();
			patchFailed = new Signal();
			offline = new Signal();
			appDownloadProgress = new Signal(Number); // percentage
			ffmpegDownloadProgress = new Signal(Number); // percentage
			ffmpegDownloadSpeed = new Signal(Number);
			state = new Signal(String);

			appUpdated = false;
			ffmpegUpdated = false;

			cc = new ConnectionChecker();
			cc.online.add(checkVersion);
			cc.offline.add(connectionFailed);

		}

		public function start():void {
			// Check if we have a connection with the server. If so, proceed. Otherwise, report that we are offline.
			cc.checkConnection(new URLRequest(CONNECTION_CHECK_URL));
		}

		private function connectionFailed():void { offline.dispatch(); }

		private function checkVersion():void {

			// Load a json file from the server. Should look something like this:
			// {
			//   "app": {
			//       "apsc160_201609": {
			//         "version": "16.08.31.00.00.00",
			//         "url": "http://animatti.ca/myview/tlef/version/app/20160831_000000.zip"
			//       }
			//     }
			//   ,
			//   "ffmpeg": [
			//   	{
			//   	  "version": "3.0.2",
			//   	  "url": "http://animatti.ca/myview/tlef/version/ffmpeg/ffmpeg_302_$.zip"
			//   	}
			//   ]
			// }
			versionURLLoader = new URLLoaderPlus(new URLRequest(VERSION_CHECK_URL));
			state.dispatch(STATE_CHECK_VERSION);

			versionURLLoader.addEventListener(Event.COMPLETE,
				function compareVersion(e:Event):void {

					var offlineVersionBA:ByteArray = new ByteArray;
					Util.readFileIntoByteArray(VERSION_FILENAME, offlineVersionBA);
					
					var localVersion:* = null;
					var cloudVersion:* = JSON.parse(versionURLLoader.data.toString());


					var cloudVersionString:String = "";
					var localVersionString:String = "";

					var typeid:String;
					var classid:String;

					for(typeid in cloudVersion) {
						if(typeid=="app") {
							for(classid in cloudVersion[typeid]) {
								if(classid == CLASS_ID) {
									appURL = cloudVersion[typeid][classid].url;
									cloudVersionString = cloudVersion[typeid][classid].version;
								}
							}
						}
					}

					if(offlineVersionBA.length > 0) {
						localVersion = JSON.parse(offlineVersionBA.toString());

						for(typeid in localVersion) {
							if(typeid=="app") {
								for(classid in localVersion[typeid]) {
									if(classid == CLASS_ID) {
										// appURL = localVersion[typeid][classid].url;
										localVersionString = localVersion[typeid][classid].version;
									}
								}
							}
						}
					}

					// trace(appURL + " " + cloudVersionString);
					// trace("--- \t\t\t" + localVersion)
					
					// appURL = cloudVersion.app[0].url;
					ffmpegURL = cloudVersion.ffmpeg[0].url;


					// replace the '$' with mac or win, depending on the platform.
					var operatingSystem:String = Capabilities.os;
			        if(operatingSystem.indexOf("Mac") >= 0) {
						ffmpegURL = ffmpegURL.replace("$", "mac");
					} else if(operatingSystem.indexOf("Windows") >= 0) {
						ffmpegURL = ffmpegURL.replace("$", "win");
					}

					var downloadApp:Boolean =    (localVersion == null) || (cloudVersionString != localVersionString);
					var downloadFfmpeg:Boolean = (localVersion == null) || (cloudVersion.ffmpeg[0].version != localVersion.ffmpeg[0].version);

					trace("downloadApp" + downloadApp);
					// if the version numbers don't match, download them.
					startDownload(downloadApp, downloadFfmpeg);

				});
		}

		private function startDownload(downloadApp:Boolean, downloadFfmpeg:Boolean):void {
			
			trace(appURL);
			trace(ffmpegURL);
			if(downloadApp) {
				state.dispatch(STATE_DOWNLOADING_APP);
				appURLLoader = new URLLoaderPlus(new URLRequest(appURL));
				appURLLoader.addEventListener(Event.COMPLETE, 
					function appDownloaded(e:Event):void {

						Util.writeBytesToFile(appURLLoader.filename, appURLLoader.data)
						appZip = new FZip();
						appZip.load(new URLRequest("file://" + File.applicationStorageDirectory.nativePath + "/" + appURLLoader.filename));
						appUpdated = true;
						appZip.addEventListener(Event.COMPLETE, zipLoaded);

					});
				appURLLoader.addEventListener(ProgressEvent.PROGRESS,
					function progressUpdate(e:ProgressEvent):void {
						appDownloadProgress.dispatch(e.bytesLoaded/e.bytesTotal);
//						 trace(e.bytesLoaded + "/" + e.bytesTotal + " = " + Math.round(e.bytesLoaded/e.bytesTotal*1000)/10 + "%");
					});
			} else {
				appUpdated = true;
			}

			// if(downloadFfmpeg) {
			// 	state.dispatch(STATE_DOWNLOADING_FFMPEG);
			// 	ffmpegURLLoader = new ProgressiveDownloader(new URLRequest(ffmpegURL));
			// 	ffmpegURLLoader.addEventListener(Event.COMPLETE, 
			// 		function ffmpegDownloaded(e:Event):void {

			// 			ffmpegZip = new FZip();
			// 			ffmpegZip.load(new URLRequest("file://" + File.applicationStorageDirectory.nativePath + "/" + ffmpegURLLoader.filename));
			// 			ffmpegUpdated = true;
			// 			ffmpegZip.addEventListener(Event.COMPLETE, zipLoaded);

			// 			state.dispatch(STATE_UNZIPPING_FFMPEG);
			// 		})
			// 	ffmpegURLLoader.addEventListener(ProgressEvent.PROGRESS,
			// 		function printasdf(e:ProgressEvent):void {
			// 			ffmpegDownloadProgress.dispatch(e.bytesLoaded/e.bytesTotal);
			// 			ffmpegDownloadSpeed.dispatch(ffmpegURLLoader.downloadSpeed);
			// 			// trace(e.bytesLoaded + "/" + e.bytesTotal + " = " + Math.round(e.bytesLoaded/e.bytesTotal*1000)/10 + "%");
			// 			})
			// } else {
				ffmpegUpdated = true;
			// }

			// Nothing needs to be updated
			if(appUpdated && ffmpegUpdated) {
				patchComplete.dispatch();
			}

		}


		private function zipLoaded(e:Event):void {

			for(var i:int = 0; i<e.target.getFileCount(); i++) {
				// trace(e.target.getFileAt(i));
				var file:FZipFile = e.target.getFileAt(i);
				if(file.sizeUncompressed > 0 && file.filename.indexOf("__MACOSX") < 0)
					Util.writeBytesToFile(e.target.getFileAt(i).filename, e.target.getFileAt(i).content, true);
			}

			if(appUpdated && ffmpegUpdated) {

				if(appURLLoader)
					Util.deleteFile(File.applicationStorageDirectory.nativePath + "/" + appURLLoader.filename);

//				if(ffmpegURLLoader)
//					Util.deleteFile(File.applicationStorageDirectory.nativePath + "/" + ffmpegURLLoader.filename);

				Util.writeBytesToFile(VERSION_FILENAME, versionURLLoader.data);

				state.dispatch(UPDATE_COMPLETE);
				patchComplete.dispatch();
			}

		}
	}
}