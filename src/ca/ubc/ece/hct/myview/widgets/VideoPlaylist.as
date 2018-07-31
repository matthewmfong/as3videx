////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets {
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import flash.utils.getQualifiedClassName;
	import org.osflash.signals.Signal;

	public class VideoPlaylist {
	
		public function get filename():String { return listName; }
		public var listName:String;
		public var mediaList:Array;
		public var release_date:String;
		public var view_order:Number;

		public var progressDownloaded:Number;
		public var downloadProgress:Signal;
		public var downloadComplete:Signal;
		
		public function VideoPlaylist() {
			listName = "";
			mediaList = [];
			release_date = ""
			view_order = -1;
			progressDownloaded = 0;
			downloadProgress = new Signal(VideoPlaylist, Number);
			downloadComplete = new Signal(VideoPlaylist, Boolean);
		}

		public function insertAt(index:Number, obj:*):void {
			if(obj is VideoPlaylist || obj is VideoMetadata) {
				
				obj.downloadProgress.add(progress);
				// obj.downloadComplete.add(complete);

				mediaList.insertAt(index, obj);

				// completedDownload = obj.completedDownload;

				progressDownloaded = addProgress() / mediaList.length;

			} else {
				trace("umm. can't insert this....")
			}
		}

		public function addProgress():Number {
			var total:Number = 0;
			for(var i:int = 0; i<mediaList.length; i++) {
				total += mediaList[i].progressDownloaded;
			}
			return total;
		}

		public function progress(obj:*, bytesDownloaded:Number, totalBytes:Number):void {
			
			progressDownloaded = addProgress()/mediaList.length;

			downloadProgress.dispatch(this, progressDownloaded, totalBytes);

			if(progressDownloaded == 1) {
				downloadComplete.dispatch(this, true)
			}
		}

		// public function complete(obj:*, val:Boolean):void {
		// 	trace("VideoPlaylist '" + filename + "' - '" + obj.filename + "' - " + obj.progressDownloaded);

		// 	// trace("VideoPlaylist " + filename + " " + obj.filename);
		// 	// trace(progressDownloaded + " " +  mediaList.length + " haha")
		// 	// completedDownload = true;//(progressDownloaded == mediaList.length);
		// 	downloadComplete.dispatch(this, val);
		// }

		public function toString():String {
			return "\"" + listName + "\": release_date = " + release_date + ", view_order: " + view_order + ", size: " + mediaList.length;
		}

		public function asString(tabs:String = ""):String {
			var buildString:String = "";
			buildString += tabs + "\"" 						+ listName 		+ "\": {\n";
			buildString += tabs + "\t\"release_date\": \"" 	+ release_date 	+ "\",\n";
			buildString += tabs + "\t\"view_order\": \"" 	+ view_order 	+ "\",\n";
			buildString += tabs + "\t\"playlist\": {\n";
			for(var i:int = 0; i<mediaList.length; i++) {
				switch(getQualifiedClassName(mediaList[i])) {
					case "ca.ubc.ece.hct.myview.widgets.VideoPlaylist":
						buildString += mediaList[i].asString(tabs + "\t");
						break;
					case "ca.ubc.ece.hct.myview.video.VideoMetadata":
						buildString += tabs + "\t\t\"" + mediaList[i].filename + "\""
						if(i < mediaList.length - 1) {
							buildString += ",";
						}
						buildString += "\n";
						break;
				}
			}
			buildString += tabs + "\t}\n"
			buildString += tabs + "}\n";
			return buildString;
		}

		public function stringAsRootPlaylist():String {
			var buildString:String = "{\n\t\"playlist\": {\n";
			for(var i:int = 0; i<mediaList.length; i++) {
				switch(getQualifiedClassName(mediaList[i])) {
					case "ca.ubc.ece.hct.myview.widgets.VideoPlaylist":
						// buildString += "\t\t\"" + mediaList[i].listName + "\": {\n";
						// buildString += "\t\t\t\"release_date\": \"" + mediaList[i].release_date + "\",\n";
						// buildString += "\t\t\t\"view_order\": "  + mediaList[i].view_order + ",\n";
						// buildString += "\t\t\t\"playlist\": ";
						if(mediaList[i].mediaList[0]) {
							// buildString += "[\n";
							buildString += mediaList[i].asString("\t\t");
							// buildString += "\t\t\t]\n";
						}
						// buildString += "\t\t}\n"
						break;
					case "ca.ubc.ece.hct.myview.video.VideoMetadata":
						buildString += "\t\t\"" + mediaList[i].filename;
						break;
				}
			}

			return buildString;	
		}
	}
}