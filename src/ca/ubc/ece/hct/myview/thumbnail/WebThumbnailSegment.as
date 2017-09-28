////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.video.VideoMetadata;


public class WebThumbnailSegment extends WebThumbnail {

		private var _startTime:Number;
		public var _endTime:Number;

		public var identifier:uint;

		public function WebThumbnailSegment(video:VideoMetadata, width:Number, height:Number, startTime:Number, endTime:Number, resizingStatus:Boolean = false) {
			super(video.filename, width, height, startTime);
			this._startTime = startTime;
			this.endTime = endTime;
		}

		override public function seekNormalized(location:Number):void {
			var time:Number = location * (endTime - startTime) + startTime;
			seekTimeInSeconds(time);
		}

		public function set interval(range:ca.ubc.ece.hct.Range):void {
			startTime = range.start;
			endTime = range.end;
		}

		public function set startTime(val:Number):void {
			_startTime = val;
			seekTimeInSeconds(val);
		}

		public function get startTime():Number {
			return _startTime;
		}

		public function set endTime(val:Number):void {
			_endTime = val;
		}

		public function get endTime():Number {
			return _endTime;
		}

		public function get intervalString():String {
			return "[" + startTime + ", " + endTime + "]";
		}
	}
}