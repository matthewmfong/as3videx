////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {
	
	import flash.events.Event;

	public class ThumbnailEvent extends Event {

		public static const LOADED:String = "ThumbnailEvent.LOADED";

		public var thumbnail:Thumbnail;

		public function ThumbnailEvent(type:String, thumbnail:Thumbnail, bubbles:Boolean = false, cancelable:Boolean = false) {

			super(type, bubbles, cancelable);

			this.thumbnail = thumbnail;
		}
	}
}