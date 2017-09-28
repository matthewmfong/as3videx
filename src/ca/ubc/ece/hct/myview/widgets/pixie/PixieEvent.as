////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.pixie {

	import flash.events.Event;
	public class PixieEvent extends Event {

		public var colour:uint;
		public static const HIGHLIGHT:String = "PixieEvent.HIGHLIGHT";
		public static const UNHIGHLIGHT:String = "PixieEvent.UNHIGHLIGHT";
		public static const PLAY:String = "PixieEvent.PLAY"
		public static const STOP_AUTO_HIGHLIGHT:String = "PixieEvent.STOP_AUTO_HIGHLIGHT";

		public function PixieEvent(type:String, colour:uint = 0, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
			this.colour = colour;
		}
	}
}