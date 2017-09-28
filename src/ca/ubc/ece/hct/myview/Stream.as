////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

	import collections.HashMap;

	/**
	A representation of a video stream, as returned by ffprobe. 
	Everything is (supposed to be) immutable.
	**/

	public class Stream {

		public static const VIDEO:String = "video";
		public static const AUDIO:String = "audio";
		public static const SUBTITLE:String = "subtitle";

		private var _map:HashMap;
		public function get map():HashMap { return _map.clone(); };
		private var _type:String; 
		public function get type():String { return _type; }
		private var _width:Number = undefined, _height:Number = undefined, _duration:Number = undefined, _framerate:Number = undefined;
		public function get width():Number { return _width; }
		public function get height():Number { return _height; }
		public function get duration():Number { return _duration; }
		public function get framerate():Number { return _framerate; }

		public function Stream(codec_type:String = null) {
			_map = new HashMap();
			_type = codec_type;
		}

		public function put(key:*, obj:*):void {
			_map.put(key, obj);
			switch(key) {
				case "width":
					_width = Number(obj);
					break;
				case "height":
					_height = Number(obj);
					break;
				case "duration":
					_duration = Number(obj);
					break;
				case "avg_frame_rate":
					var numbers:Array = obj.split("/");
					_framerate = uint(numbers[0]/numbers[1] * 100)/100;
					break;
			}
		}
	}
}