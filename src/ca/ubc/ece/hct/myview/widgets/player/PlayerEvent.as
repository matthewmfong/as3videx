////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {
	import flash.events.Event;
	public class PlayerEvent extends Event {

		public var time:Number;
		public var newTime:Number;
		public var pause:Boolean;
		public static const PLAY:String = "PlayerEvent.PLAY";
		public static const PAUSE:String = "PlayerEvent.PAUSE";
		public static const SEEK:String = "PlayerEvent.SEEK";
		public static const PLAYHEAD_UPDATE:String = "PlayerEvent.PLAYHEAD_UPDATE";
		public static const ENLARGE:String = "PlayerEvent.ENLARGE";

		public function PlayerEvent(type:String, time:Number, newTime:Number = -1, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
			this.time = time;
			this.newTime = newTime;
		}
	}
}