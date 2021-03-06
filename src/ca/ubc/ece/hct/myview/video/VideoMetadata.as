////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.video {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.Highlights;
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.Util;

import collections.HashMap;

import org.osflash.signals.Signal;

public class VideoMetadata {

		// variables stored in the database
		public var id:String;
		public var media_alias_id:String;
		public var filename:String;
		public var duration:Number;		
		public var slides:Vector.<Number>;
		public var source:Vector.<Source>;
		public var primarySource:int;
		public var tileSource:Vector.<TileSource>;
		public var title:String, author:String, description:String;

		public var aspectRatio:Number;
		public var view_order:Number;

		public var userData:UserData;
		public var crowdUserData:HashMap;
		private var _crowdLastViewed:Date;
		public function set crowdLastViewed(d:Date):void { _crowdLastViewed = d; crowdLastViewedUpdated.dispatch(); }
		public function get crowdLastViewed():Date { return _crowdLastViewed; }
		public var crowdLastViewedUpdated:Signal;
		public var crowdUserLastViewed:String;
		private var _crowdUserViewCounts:Vector.<Number>;

		public var downloadProgress:Signal;
		public var downloadComplete:Signal;
		public var downloadCompleted:Boolean = false;
		public var _progressDownloaded:Number;
//        public var totalNumberOfSourcesToDownload:Number;
//        public var totalNumberOfSourcesDownloaded:Number;
		public function get progressDownloaded():Number { return _progressDownloaded; }

		public function VideoMetadata() {

			source = new Vector.<Source>();
			tileSource = new Vector.<TileSource>();
			slides = new Vector.<Number>();
			userData = new UserData();
			crowdUserData = new HashMap();
			downloadProgress = new Signal(VideoMetadata, Number, Number); // this, bytesDownloaded, totalBytes
			downloadComplete = new Signal(VideoMetadata);
			_progressDownloaded = 0;
//			totalNumberOfSourcesToDownload = 0;
//            totalNumberOfSourcesDownloaded = 0;

			crowdLastViewedUpdated = new Signal();
		}

		public function addSource(id:String,
								  url:String, 
								  width:Number, height:Number,
								  mimeType:String, 
								  framerate:Number,
								  keyframes:Array,
								  language:String):void {
			var vs:Source = new Source();
			vs.id = id;
			vs.url = url;
			vs.mimeType = mimeType;
			vs.width = width;
			vs.height = height;
			vs.framerate = framerate;
			vs.keyframes = keyframes;
			vs.language = language;

			if(width && height) {
				aspectRatio = width/height;
			}

			source.push(vs);

			vs.downloadProgress.add(progress);
//			vs.downloadComplete.add(complete);
		}

		public function addCrowdUserData(dataType:String, uData:UserData):void {
			if(crowdUserData.grab(dataType) == undefined) {
				crowdUserData.put(dataType, new Vector.<UserData>());
			}

			crowdUserData.grab(dataType).push(uData);
		}

    /**
	 * Grabs the specified type of user data (class, instructor, etc) with a specific username
	 *
     * @param dataType (UserData.CLASS, UserData.INSTRUCTOR, etc)
     * @param userString
     * @return null if not found, or the UserData
     */
	public function grabCrowdUserData(dataType:String, userString:String):UserData {
		var userDataOfType:Vector.<UserData> = crowdUserData.grab(dataType);
		if(userDataOfType == undefined) {
			return null;
		} else {
			for each(var userData:UserData in userDataOfType) {
				if(userData.userString == userString) {
					return userData;
				}
			}
		}

		return null;
	}

    /**
	 * Grab all the Class Data
     * @return Vector of VCRs, or null if there is no data
     */
	public function grabAllClassData():Vector.<UserData> {
		return crowdUserData.grab(UserData.CLASS);
	}

    /**
     * Gets the aggregate viewcounts
     */
    public function get crowdUserViewCounts():Vector.<Number> {
		var returnArray:Vector.<Number>;
		if(_crowdUserViewCounts == null ) {
			var crowdUserData:Vector.<UserData> = crowdUserData.grab(UserData.CLASS);
			if(crowdUserData != null) {
				returnArray = new Vector.<Number>();
				for each(var userData:UserData in crowdUserData) {
					for(var i:int = 0; i<userData.viewCountRecord.length; i++) {
						if(returnArray.length == i) {
							returnArray.push(0);
						}
						returnArray[i] += userData.viewCountRecord[i];
					}
				}
			} else {
				returnArray = new <Number>[0];
			}
		} else {
			returnArray = _crowdUserViewCounts;
		}

		return returnArray;
	}

		public function get crowdHighlights():Array {
            var returnArray:Array;
//            if(_crowdUserViewCounts == null ) {
                var crowdUserData:Vector.<UserData> = crowdUserData.grab(UserData.CLASS);
                if(crowdUserData != null) {
                    returnArray = [];
                    for each(var userData:UserData in crowdUserData) {

						var highlightColours:Array = userData.highlights.values();

						for each(var highlights:Highlights in highlightColours) {

							for each(var interval:Range in highlights.intervals) {

								for (var i:int = interval.start; i < interval.end + 1; i++) {

									if (isNaN(returnArray[i])) {
										returnArray[i] = 0;
									}
									returnArray[i]++;
								}

								for (var j:int = 0; j < returnArray.length; j++) {
									if (isNaN(returnArray[j])) {
										returnArray[j] = 0;
									}
								}
							}
                        }
                    }
                } else {
                    returnArray = [0];
                }
//            } else {
//                returnArray = _crowdUserViewCounts;
//            }

            return returnArray;
		}


		public function get currentClassCrowdHighlights():Vector.<Number> {
			var returnArray:Vector.<Number>;
			if(_crowdUserViewCounts == null ) {
				var crowdUserData:Vector.<UserData> = crowdUserData.grab(UserData.CLASS);
				if(crowdUserData != null) {
					returnArray = new Vector.<Number>();
					for each(var userData:UserData in crowdUserData) {

						if(userData.userString.indexOf(COURSE::Name) > -1) {
	//                            trace("user string: " + userData.userString);

							var highlightColours:Array = userData.highlights.values();

							for each(var highlights:Highlights in highlightColours) {

								for each(var interval:Range in highlights.intervals) {

									for (var i:int = interval.start; i < interval.end + 1; i++) {

										if (isNaN(returnArray[i])) {
											returnArray[i] = 0;
										}
										returnArray[i]++;
									}

									for (var j:int = 0; j < returnArray.length; j++) {
										if (isNaN(returnArray[j])) {
											returnArray[j] = 0;
										}
									}
								}
							}
						}
					}
				} else {
					returnArray = new <Number>[0];
				}
			} else {
				returnArray = _crowdUserViewCounts;
			}

			return returnArray;
		}

//		public function traceCrowdUserData(type:String):void {
//            var userDataOfType:Vector.<UserData> = crowdUserData.grab(type);
//			for each(var userData:UserData in userDataOfType) {
//				trace("highlights: " + userData.getHighlightsString());
//			}
//		}

		public function progress(bytesDownloaded:Number, totalBytes:Number):void {
			var sources:Array = getSources();
			var allSourceBytesDownloaded:Number = 0;
			var allSourceTotalBytes:Number = 0;

			for each(var source:Source in sources) {
				if(source.downloaded || source.queuedForDownload) {
                    allSourceBytesDownloaded += source.bytesDownloaded;
                    allSourceTotalBytes += source.totalBytes;

//                trace(source.url + ": " + source.bytesDownloaded + "/" + source.totalBytes + ": " + Math.round(source.bytesDownloaded/source.totalBytes * 10000)/100 + "%");
                }
			}

			_progressDownloaded = allSourceBytesDownloaded / allSourceTotalBytes;

//            trace(filename + ": " + allSourceBytesDownloaded + "/" + allSourceTotalBytes + ": " + Math.round(allSourceBytesDownloaded/allSourceTotalBytes * 10000)/100 + "%");

			this.downloadProgress.dispatch(this, allSourceBytesDownloaded, allSourceTotalBytes);

			if(allSourceBytesDownloaded == allSourceTotalBytes) {

				downloadComplete.dispatch(this);
			}
		}

//		public function complete(val:Boolean):void {
//			 _completedDownload = val;
//			downloadComplete.dispatch(this, val);
//		}

		public function getSources(mimeType:String = null):Array {

			var sourcesOfType:Array = [];
			for(var i:int = 0; i<source.length; i++) {

				if(source[i].mimeType == mimeType || mimeType == null) {
					sourcesOfType.push(source[i]);
				}
			}

			return sourcesOfType;
		}

		public function getCaptions(language:String):VideoCaptions {
			var sources:Array = getSources("vtt");
			for(var i:int = 0; i<sources.length; i++) {
				// trace(sources[i].captions)
				if(sources[i].captions.language == language) {
					return sources[i].captions;
				}
			}

			return null;
		}

		public function addTileSource(folderURL:String,
									  frameWidth:Number, frameHeight:Number,
									  framerate:Number,
									  numTiles:uint,
									  numFramesPerTile:uint):void {
			var ts:TileSource = new TileSource();
			ts.folderURL = folderURL;
			ts.frameWidth = frameWidth;
			ts.frameHeight = frameHeight;
			ts.framerate = framerate;
			ts.numTiles = numTiles;
			ts.numFramesPerTile = numFramesPerTile;

			tileSource.push(ts);
		}

		public function toString():String {
			return id + "-" +filename;
		}

	}

}
