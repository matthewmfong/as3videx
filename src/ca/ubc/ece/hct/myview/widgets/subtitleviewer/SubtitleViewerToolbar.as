////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.subtitleviewer {

	import ca.ubc.ece.hct.myview.ui.SearchBar;

	import org.osflash.signals.Signal;

	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.geom.Matrix;

	public class SubtitleViewerToolbar extends Sprite {

		override public function get width():Number { return _width; }
		public static function get height():Number { return _height; }
		private var _width:Number;
		private static const _height:Number = 38;

		private var searchInput:SearchBar;
		public function get text():String { return searchInput.text; }

		public var search:Signal;

		public static const SEARCH_INPUT_FOCUS_IN:String = "SearchInputFocusIn";
		public static const SEARCH_INPUT_FOCUS_OUT:String = "SearchInputFocusOut";
		public var searchFocus:Signal;

		public function SubtitleViewerToolbar(width_:Number) {
			_width = width_;

			searchInput = new SearchBar(_width/2);

			search = new Signal(String);
			searchFocus = new Signal(String);

			drawMe();
		}

		private function drawMe():void {

			var backMatrix:Matrix = new Matrix();
			backMatrix.createGradientBox(_width, _height, Math.PI/2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, 
				[0xe1e1e1, 0xc4c4c4], // colour
				[1, 1],  // alpha
				[0, 255], // ratio
				backMatrix);
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();

			searchInput.width = _width - 20;
			searchInput.x = 10;
			searchInput.y = _height/2 - searchInput.height/2;
			addChild(searchInput);
			searchInput.addEventListener(Event.CHANGE, searchInputChanged);
			searchInput.addEventListener(FocusEvent.FOCUS_IN, searchFocusIn);
			searchInput.addEventListener(FocusEvent.FOCUS_OUT, searchFocusOut);
		}

		private function searchInputChanged(e:Event):void {
			search.dispatch(searchInput.text);
		}

		private function searchFocusIn(e:FocusEvent):void {
			searchFocus.dispatch(SEARCH_INPUT_FOCUS_IN);
		}

		private function searchFocusOut(e:FocusEvent):void {
			searchFocus.dispatch(SEARCH_INPUT_FOCUS_OUT);
		}

		override public function set width(val:Number):void {
			_width = val;

			var backMatrix:Matrix = new Matrix();
			backMatrix.createGradientBox(_width, _height, Math.PI/2, 0, 0);
			graphics.clear();
			graphics.beginGradientFill(GradientType.LINEAR, 
				[0xe1e1e1, 0xc4c4c4], // colour
				[1, 1],  // alpha
				[0, 255], // ratio
				backMatrix);
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();

			searchInput.width = _width - 20;
		}
	}
}