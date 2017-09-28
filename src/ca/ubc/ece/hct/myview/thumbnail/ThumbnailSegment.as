////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {
import ca.ubc.ece.hct.Range;


import starling.events.TouchEvent;
import starling.events.Touch;
import starling.events.TouchPhase;

public class ThumbnailSegment extends Thumbnail {

		public var interval:Range;

		public function ThumbnailSegment() {
			super();
			this.interval = new Range(0, 1);
		}

		public function setInterval(interval:Range):void {
			this.interval = interval;
			if(!interval.contains(_timestamp)) {
				_timestamp = interval.start;
			}
		}

        override public function seekNormalized(location:Number, exact:Boolean = false, mustLoad:Boolean = false):void {
            seekTimeInSeconds(startTime + location * (video.duration * interval.length));
        }

		override public function showImage():void {
			if(video && !contains(image)) {
				seekNormalized(0);
				addEventListener(TouchEvent.TOUCH, touched);
			}
		}

        public function set startTime(val:Number):void {
            interval.start = val/video.duration;
        }

        public function set endTime(val:Number):void {
            interval.end = val/video.duration;
        }

		public function get startTime():Number {
			return video.duration * interval.start;
		}

		public function get endTime():Number {
			return video.duration * interval.end;
		}

		override protected function touched(e:TouchEvent):void {
			var touch:Touch = e.getTouch(this, TouchPhase.HOVER);
			if(touch) {
                seekNormalized(touch.getLocation(this).x / _width);
            }
		}

	}
}