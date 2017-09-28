////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.video {

	import ca.ubc.ece.hct.myview.widgets.subtitleviewer.Cue;
	import ca.ubc.ece.hct.myview.widgets.subtitleviewer.Payload;
	import ca.ubc.ece.hct.myview.widgets.subtitleviewer.CaptionsParser;

	import org.osflash.signals.Signal;
	
	public class VideoCaptions {

		public var url:String;
		public var language:String;
		public function get cues():Array { return captionParser.captionsArray; }
		public function get words():Array { return captionParser.individualWords; }
		public function get rawText():String { return captionParser.rawText; }
		public var payloads:Vector.<Payload>;
		private var captionParser:CaptionsParser;

		public var loaded:Signal;
		public var readyToBeQueried:Boolean;

		public function VideoCaptions():void {

			loaded = new Signal();
			readyToBeQueried = false;

		}

		public function load(language:String, url:String):void {
			this.language = language;
			this.url = url;
			
			captionParser = new CaptionsParser();
			captionParser.loadCaptions(this.url);
			captionParser.parsed.add(captionsLoadedAndParsed);
		}

		private function captionsLoadedAndParsed():void {
			readyToBeQueried = true;
			loaded.dispatch();
		}

		public function getCueAtTime(seconds:Number):Cue {

			if(!readyToBeQueried) {
				throw new Error("VideoCaptions are not finished loading yet... Wait for the loaded signal.");
			}

			var time:Number = seconds;

			for(var i:int = 0; i < cues.length; i++) {

				var cue:Cue = cues[i];
	        	if(cue.startTime*0.001 < time && cue.endTime*0.001 > time) {
        	   		return cue;
	        	}
	        }

	        return new Cue();
		}

		public function getWordAtTime(seconds:Number):Payload {

			if(!readyToBeQueried) {
				throw new Error("VideoCaptions are not finished loading yet... Wait for the loaded signal.");
			}

			var time:Number = seconds;

			for(var i:int = 0; i < payloads.length; i++) {

				var payload:Payload = payloads[i];
	        	if(payload.startTime*0.001 < time && payload.endTime*0.001 > time) {
        	   		return payload;
	        	}
	        }

	        return null;

		}

		public function toString():String {
			return url + " " + language + " " + rawText;
		}
	}
}