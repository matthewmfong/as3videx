////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////


// 1
// 00:00:00 --> 01:00:00
// This <00:00:01>whole <00:00:02>thing <00:00:03>here is a cue.

package ca.ubc.ece.hct.myview.widgets.subtitleviewer {
	
	public class Cue {
		public var identifier:int;
		public var startTime:int;
		public var endTime:int;
		public var settings:String;
		public var payloads:Array;

		public function Cue(identifier:int = -1, startTime:int = -1, endTime:int = -1, settings:String = null, payloads:Array = null) {
			this.identifier = identifier;
			this.startTime = startTime;
			this.endTime = endTime;
			this.settings = settings;
			this.payloads = payloads;
		}

		public function toString():String {
			var ret:String = "" + startTime + " -> " + endTime;

			ret += ": " + getText();

			return ret;

		}

		public function getText():String {
			if(payloads) {
				var ret:String = "";

				var asciiWord:RegExp = /[a-zA-Z]+/;
				for(var i:int = 0; i<payloads.length; i++) {
					ret += payloads[i].phrase + (asciiWord.test(payloads[i].phrase) ? " " : "");
				}
				return ret;
			}

			return "";
		}

		public function get duration():Number {
			return endTime - startTime;
		}
		
	}


}