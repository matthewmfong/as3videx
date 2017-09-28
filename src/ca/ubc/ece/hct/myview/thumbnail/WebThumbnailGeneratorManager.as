////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {

import ca.ubc.ece.hct.myview.video.VideoMetadata;

import collections.HashMap;
	import org.osflash.signals.Signal;

	public class WebThumbnailGeneratorManager {

		private static var _instance:WebThumbnailGeneratorManager;
		public static var videos:HashMap = new HashMap();
		public static var generatorReady:Signal;
		public static var downloadProgress:Signal;
		public static var downloadComplete:Signal;

	    public function WebThumbnailGeneratorManager() {
	        if(_instance){
	            throw new Error("WebThumbnailGeneratorManager is a Singleton. Use getInstance()!");
	        } 
	        _instance = this;
	    }

	    public static function getInstance():WebThumbnailGeneratorManager {
	        if(!_instance){
	            _instance = new WebThumbnailGeneratorManager();
	            generatorReady = new Signal(String);
	            downloadProgress = new Signal(Number);
	            downloadComplete = new Signal();
	        } 
	        return _instance;
	    }

	    public static function init():void {
	    	getInstance();
	    }

	    public static function loadVideo(video:VideoMetadata):void {
	    	if(!videos.containsKey(video.filename)) {

	    		var wtg:WebThumbnailGenerator = new WebThumbnailGenerator();

	    		wtg.downloadProgress.add(progressHandler);
	    		wtg.downloadComplete.add(downloadCompleteHandler);

	    		wtg.loadVideo(video);

				videos.put(video.filename, wtg);
				generatorReady.dispatch(video.filename);
			} else {
				generatorReady.dispatch(video.filename);
				downloadCompleteHandler();
			}
	    }

	    public static function progressHandler(progress:Number):void {
	    	downloadProgress.dispatch(progress);
	    }

	    public static function downloadCompleteHandler():void {

	    	downloadComplete.dispatch();
	    }

	    public static function getGenerator(videoFilename:String):WebThumbnailGenerator {
	    	return videos.grab(videoFilename);
	    }
	}
}