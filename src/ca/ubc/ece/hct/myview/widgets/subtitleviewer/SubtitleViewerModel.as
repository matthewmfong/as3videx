////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.subtitleviewer {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

public class SubtitleViewerModel {

		public static const HIGHLIGHT_MODE_ON:String = "HighlightModeOn";
		public static const HIGHLIGHT_MODE_OFF:String = "HighlightModeOff";

		private var _video:VideoMetadata;
		public function get video():VideoMetadata { return _video; }
		public function set video(val:VideoMetadata):void { _video = val; }
		private var _highlightMode:String;
		public function get highlightMode():String { return _highlightMode; }
		public function set highlightMode(val:String):void { _highlightMode = val; }
		private var _highlightColour:uint;
		public function get highlightColour():uint { return _highlightColour; }
		public function set highlightColour(val:uint):void { _highlightColour = val; }
		private var _searchString:String = "";
		public function get searchString():String { return _searchString; }
		public function set searchString(val:String):void { _searchString = val; }
		private var _selection:ca.ubc.ece.hct.Range; // seconds
		public function get selection():ca.ubc.ece.hct.Range { return _selection; }
		public function set selection(val:ca.ubc.ece.hct.Range):void { _selection = val; }

		public function SubtitleViewerModel() {
			_selection = new Range(0, 0);

			_highlightColour = 0xffffff;
		}
	}
}