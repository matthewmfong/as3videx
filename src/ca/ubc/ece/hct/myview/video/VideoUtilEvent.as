////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.video {

	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class VideoUtilEvent extends Event {
		
	    public static const DIMENSIONS_LOADED:String = "ca.ubc.ece.hct.myview.video.VideoUtilEvent.DIMENSIONS_LOADED";
	    public static const DURATION_LOADED:String = "ca.ubc.ece.hct.myview.video.VideoUtilEvent.DURATION_LOADED";
	    public static const KEYFRAMES_LOADED:String = "ca.ubc.ece.hct.myview.video.VideoUtilEvent.KEYFRAMES_LOADED";
	    public static const KEYFRAMES_PROGRESS:String = "ca.ubc.ece.hct.myview.video.VideoUtilEvent.KEYFRAMES_PROGRESS";
	    public static const RENDERED_FRAME:String = "ca.ubc.ece.hct.myview.video.VideoUtilEvent.RENDERED_FRAME";
	    public static const DATA:String = "ca.ubc.ece.hct.myview.video.VideoUtilEvent.DATA";
	    public static const ERROR:String = "ca.ubc.ece.hct.myview.video.VideoUtilEvent.ERROR";
	    public static const EXIT:String = "ca.ubc.ece.hct.myview.video.VideoUtilEvent.EXIT";

	    public var dimensions:Rectangle;
	    public var duration:Number;
	    public var keyframes:Array;
	    public var keyframesProgress:Number;
	    // used for rendering a single frame
	    public var renderedFrame:ByteArray;
	    // used for rendering a video
	    public var data:ByteArray;
	    public var time:Number;
	    public var thumbnailID:uint;

	    public function VideoUtilEvent(type:String, 
	    	dimensions:Rectangle = null,
	    	duration:Number = 0, 
	    	keyframes:Array = null,
	    	keyframesProgress:Number = 0,
	    	renderedFrame:ByteArray = null,
	    	data:ByteArray = null, 
	    	time:Number = -1,
	    	thumbnailID:uint = -1,
	    	bubbles:Boolean = false, cancelable:Boolean = false) {
	        super(type, bubbles, cancelable);
	        this.dimensions = dimensions;
	        this.duration = duration;
	        this.keyframes = keyframes;
	        this.keyframesProgress = keyframesProgress;
	        this.renderedFrame = renderedFrame;
	        this.data = data;
	        this.time = time;
	        this.thumbnailID = thumbnailID;
	    }
	}
}