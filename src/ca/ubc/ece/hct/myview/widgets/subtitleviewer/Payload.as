////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////


// 1
// 00:00:00 --> 01:00:00
// {This} {<00:00:01>whole} {<00:00:02>thing} {<00:00:03>here is a cue.}

// each of the {} is a payload.

package ca.ubc.ece.hct.myview.widgets.subtitleviewer {
	import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.Util;

public class Payload {
		public var phrase:String;
		public var startTime:Number;
		public var endTime:Number;

		public function Payload(phrase:String = null, startTime:Number = -1, endTime:Number = -1) {
			this.phrase = phrase;
			this.startTime = startTime;
			this.endTime = endTime;
		}

		public function toString():String {
			return Util.millisecondsToTimeString(startTime) + " --> " + Util.millisecondsToTimeString(endTime) + ": " + phrase;
		}

		public function displayWithStartTime():String {
			return "<" + Util.millisecondsToTimeString(startTime) + ">: " + phrase
		}

		public function display():String {
			return phrase;
		}
	}
}