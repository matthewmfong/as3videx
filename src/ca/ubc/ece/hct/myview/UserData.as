////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

import ca.ubc.ece.hct.Range;

import collections.HashMap;

import mx.charts.AreaChart;

public class UserData {

        public static const PERSONAL:String = "ca.ubc.ece.hct.myview.UserData.PERSONAL";
        public static const CLASS:String = "ca.ubc.ece.hct.myview.UserData.CLASS";
		public static const INSTRUCTOR:String = "ca.ubc.ece.hct.myview.UserData.INSTRUCTOR";
		public static const TEACHING_ASSISTANT:String = "ca.ubc.ece.hct.myview.UserData.TEACHING_ASSISTANT";
		// public static const FRIEND:String = "UserData.FRIEND";

		public var userString:String;
		public var viewCountRecord:Array;
		// TODO: aside from setting VCR via set view_count_record, maxViewCount must be manually specified =\
		public var maxViewCount:Number;
		public var pauseRecord:Array;
		public var playbackRateRecord:Array;
		public var highlights:HashMap;
		public var tags:Vector.<KeywordTag>;
		
		public function UserData() {

			viewCountRecord = [];
			pauseRecord = [];
			playbackRateRecord = [];
			highlights = new HashMap();
			tags = new Vector.<KeywordTag>();
			maxViewCount = 0;

		}

		// TODO: Somehow specify that this is only good for database input (view_count_record is the db field name)
		public function set view_count_record(s:String):void {
			if(s != null) {
				var vcr:Array = s.split(",");
				for(var i:int = 0; i < vcr.length; i++) {
					var viewCount:Number = Number(vcr[i]);
					viewCountRecord.push(viewCount);
					maxViewCount = Math.max(maxViewCount, viewCount);
				}
			}
		}

		public function set pause_record(s:String):void {
			if(s != null) {
				var pr:Array = s.split(",");
				for(var i:int = 0; i < pr.length; i++) {
					pauseRecord.push(Number(pr[i]));
				}
			}
		}

		public function set playback_rate_record(s:String):void {
			if(s != null) {
				var prr:Array = s.split(",");
				for(var i:int = 0; i < prr.length; i++) {
					playbackRateRecord.push(Number(prr[i]));
				}

			}
		}

		public function setViewCountRecord(index:uint, val:Number):void {
			if(index < viewCountRecord.length) {
				viewCountRecord[index] = val;
				maxViewCount = Math.max(maxViewCount, val);
			}
		}

		public function setPlaybackRateRecord(index:uint, val:Number):void {
			if(index < playbackRateRecord.length) {
				var viewCount:uint = viewCountRecord[index];
				playbackRateRecord[index] = val;//(viewCount * playbackRateRecord[index] + val)/(viewCount+1);
			}
		}

//		public function getMaxViewCount():Number {
//			var max:Number = 0;
//			for(var i:int = 0; i<viewCountRecord.length; i++) {
//				if(viewCountRecord[i] > max) {
//					max = viewCountRecord[i];
//				}
//			}
//			return max;
//		}

		public function setHighlights(colourString:String, highlightsString:String):void {

			if(highlightsString.length > 0) {
				var colour:int = parseInt(colourString, 16);
				var colourHighlights:Highlights = new Highlights(colour);
				var intervals:Array = highlightsString.split("|");

				for(var i:int = 0; i<intervals.length; i++) {
					var intervalSplit:Array = intervals[i].split(",");

					var range:Range = new Range(intervalSplit[0], intervalSplit[1]);

					colourHighlights.intervals.push(range);
				}

				// trace("#" + colour.toString(16) + ": " + colourString);

				highlights.put(colour, colourHighlights);
			}
		}

		public function highlight(colour:int, interval:Range):void {

			var colourHighlight:Highlights = highlights.grab(colour);
			
			if(colourHighlight == null) {
				colourHighlight = new Highlights(colour);
				highlights.put(colour, colourHighlight);
			}

			colourHighlight.intervals.push(interval);
			colourHighlight.intervals.sortOn("start", Array.NUMERIC);

			// trace(interval);

			// for(var i:int = 0; i<colourHighlight.intervals.length; i++) {
			// 	trace(colourHighlight.intervals[i]);
			// }
			// trace("____before");

			// Find overlapping highlights and merge them.
			colourHighlight.intervals = IntervalSorter.mergeSortedIntervals(colourHighlight.intervals);


			// for(var i:int = 0; i<colourHighlight.intervals.length; i++) {
			// 	trace(colourHighlight.intervals[i]);
			// }
			// trace("____after");
		}

		public function unhighlight(colour:int, interval:Range):void {

			var colourHighlight:Highlights = highlights.grab(colour);
			
			var rangeStart:Number = interval.start;
			var rangeEnd:Number = interval.end;

			trace(colourHighlight)

			// trace("|-- " + interval + " --|");
			// trace("colourHighlight.intervals.length = " + colourHighlight.intervals.length)

			for(var j:int = 0; j<colourHighlight.intervals.length; j++) {

				// trace(j);
				// trace("<-- " + colourHighlight.intervals[j] + " -->");

				//     |--------------|
				// rangeStart      rangeEnd

				if(rangeEnd < colourHighlight.intervals[j].start || rangeStart > colourHighlight.intervals[j].end) {
					// trace("case 1");
					// Case 1
					//         |----------|
					//   <--->              <--->
					// do nothing
				} else if(rangeStart <  colourHighlight.intervals[j].start && rangeStart < colourHighlight.intervals[j].end &&
						  rangeEnd   >= colourHighlight.intervals[j].start && rangeEnd   < colourHighlight.intervals[j].end) {
					// trace("case 2");
					// Case 2
					//         |----------|
					//       <--->
					colourHighlight.intervals[j].start = rangeEnd;

				} else if(rangeStart >= colourHighlight.intervals[j].start && rangeStart < colourHighlight.intervals[j].end &&
						  rangeEnd   > colourHighlight.intervals[j].start && rangeEnd   <= colourHighlight.intervals[j].end) {
					// trace("case 3");
					// Case 3
					//         |----------|
					//          <-------->
					colourHighlight.intervals.push(new Range(rangeEnd, colourHighlight.intervals[j].end));
					colourHighlight.intervals[j].end = rangeStart;

				} else if(rangeStart >  colourHighlight.intervals[j].start && rangeStart <  colourHighlight.intervals[j].end &&
						  rangeEnd   >= colourHighlight.intervals[j].start && rangeEnd   >= colourHighlight.intervals[j].end) {
					// trace("case 4");
					// Case 4
					//         |----------|
					//                  <--->
					colourHighlight.intervals[j].end = rangeStart;
					// trace("case 4 "+ highlights[i][j].end + " " + rangeStart);

				} else if(rangeStart <= colourHighlight.intervals[j].start && rangeStart <= colourHighlight.intervals[j].end &&
						  rangeEnd   >= colourHighlight.intervals[j].start && rangeEnd   >= colourHighlight.intervals[j].end) {
					// trace("case 5");
					// Case 5
					//         |----------|
					//       <-------------->
					// trace("Before: " + colourHighlight.intervals);
					colourHighlight.intervals.splice(j, 1);

					// trace("After:  " + colourHighlight.intervals);
					j--;

				}
			}
		}

		public function unhighlightAll(interval:Range):void {
			
			var rangeStart:Number = interval.start;
			var rangeEnd:Number = interval.end;

			var highlights:Array = this.highlights.values();
			
			for(var i:int = 0; i<highlights.length; i++) {

				for(var j:int = 0; j<highlights[i].intervals.length; j++) {

					if(rangeEnd < highlights[i].intervals[j].start || rangeStart > highlights[i].intervals[j].end) {
						// trace("case 1");
						// do nothing

					} else if(rangeStart < highlights[i].intervals[j].start && rangeStart < highlights[i].intervals[j].end &&
							  rangeEnd   >= highlights[i].intervals[j].start && rangeEnd   < highlights[i].intervals[j].end) {

						// trace("case 2");
						highlights[i].intervals[j].start = rangeEnd;

					} else if(rangeStart >= highlights[i].intervals[j].start && rangeStart <= highlights[i].intervals[j].end &&
							  rangeEnd   >= highlights[i].intervals[j].start && rangeEnd   <= highlights[i].intervals[j].end) {

						// trace("case 3");
						highlights[i].intervals.push(new Range(rangeEnd, highlights[i].intervals[j].end));
						highlights[i].intervals[j].end = rangeStart;

					} else if(rangeStart > highlights[i].intervals[j].start && rangeStart < highlights[i].intervals[j].end &&
							  rangeEnd   >= highlights[i].intervals[j].start && rangeEnd   >= highlights[i].intervals[j].end) {

						// trace("case 4 "+ highlights[i][j].end + " " + rangeStart);
						highlights[i].intervals[j].end = rangeStart;
						// trace("case 4 "+ highlights[i][j].end + " " + rangeStart);

					} else if(rangeStart <= highlights[i].intervals[j].start && rangeStart <= highlights[i].intervals[j].end &&
							  rangeEnd   >= highlights[i].intervals[j].start && rangeEnd   >= highlights[i].intervals[j].end) {

						// trace("case 5");
						highlights[i].intervals.splice(j, 1);
						j--;

						
						// highlights[i][j].start = 0;
						// highlights[i][j].end = 0;

					}

				}

			}
		}

		public function getHighlightedColoursForTime(time:Number):Array {
			return getHighlightedColoursforTimeRange(new Range(time, time));
		}

		public function getHighlightedColoursforTimeRange(range:Range):Array {
			var coloursReturn:Array = [];

			var highlightEntries:Array = highlights.values();

			for(var i:int = 0; i<highlightEntries.length; i++) {

				var highlightEntry:Highlights = (Highlights)(highlightEntries[i]);

				for(var j:int = 0; j<highlightEntry.intervals.length; j++) {

					if( range.start < highlightEntry.intervals[j].end && range.end > highlightEntry.intervals[j].start) {

						coloursReturn.push(highlightEntry.colour);
						break;
					}
				}
			}
			return coloursReturn;
		}

		public function getNonHighlightedColoursforTimeRange(range:Range):Array {
			var coloursExist:Array = getHighlightedColoursforTimeRange(range);
			var coloursReturn:Array = [];
			for(var i:int = 0; i<Colours.colours.length; i++) {

				if(!Util.arrayContains(coloursExist, Colours.colours[i])) {
					coloursReturn.push(Colours.colours[i]);
				}

			}
			return coloursReturn;
		}

		public function getHighlightsForTimeRange(range:ca.ubc.ece.hct.Range):Array {
			var coloursReturn:Array = [];

			var highlightEntries:Array = highlights.values();

			for(var i:int = 0; i<highlightEntries.length; i++) {

				var highlightEntry:Highlights = (Highlights)(highlightEntries[i]);

				for(var j:int = 0; j<highlightEntry.intervals.length; j++) {

					if( range.start < highlightEntry.intervals[j].end && range.end > highlightEntry.intervals[j].start) {

						coloursReturn.push(highlightEntry);
						break;
					}
				}
			}

			// reorder if in the rainbow order
			for(i = 0; i<Colours.colours.length; i++) {

				for(j = 0; j<coloursReturn.length; j++) {

					if(coloursReturn[j].colour == Colours.colours[i]) {
						var spliced:Array = coloursReturn.splice(j,1);
						coloursReturn.splice(coloursReturn.length, 0, spliced[0]);
						break;
					}
				}
			}
			return coloursReturn;
		}

		public function getHighlightedTimes(colour:uint):Array {
			var highlight:Highlights = highlights.grab(colour);
			if(highlight)
				return highlight.intervals;
			return null;
		}

		public function getHighlightsString():String {
			var retString:String = "";
			for each(var highlight:Highlights in highlights.values()) {
				retString += highlight.getString() + "\n";
			}
			return retString;
		}

		public function addTag(string:String, range:Range, colour:uint):void {

			tags.push(new KeywordTag(string, range, colour));

		}
	}
}

import ca.ubc.ece.hct.Range;

class IntervalSorter {

	public static function mergeSortedIntervals(intervals:Array):Array {
		var s:Array = new Array();
		s.push(intervals[0]);

	    // Start from the next interval and merge if necessary
	    for(var i:int = 1 ; i < intervals.length; i++) {
	        // get interval from stack top
	        var top:Range = new Range(s[s.length - 1].start, s[s.length - 1].end);
			// trace(intervals.length + ": (" + top.start + ", " + top.end + "), " + 
			//  	 i + ": (" + intervals[i].start + ", " + intervals[i].end + "), " + (top.end == intervals[i].end));
	        // if current interval is not overlapping with stack top,
	        // push it to the stack
	        if(top.end < intervals[i].start) {
	            s.push(intervals[i]);
	        }
	        // Otherwise update the ending time of top if ending of current 
	        // interval is more
	        else if(top.end <= intervals[i].end) {
	            top.end = intervals[i].end;
	            s.pop();
	            s.push(top);
	        }
	    }

	    // for(var j:int = 0; j<s.length; j++) {
	    // 	if(s[j].length < 0.1) {
	    // 		s = s.splice(j, 1);
	    // 	}
	    // }

	    return s;

	}
}