////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.common {
import ca.ubc.ece.hct.myview.*;

import ca.ubc.ece.hct.Range;

import org.osflash.signals.Signal;
	
	public class Highlightable extends Selectable {

		public var highlighted:Signal;
		public var unhighlighted:Signal;

		public function Highlightable() {

			highlighted = new Signal(String, int, Range); // video filename, colour, interval
			unhighlighted = new Signal(String, int, Range); // video filename, colour, interval
			
		}

		public function highlight(colour:int, interval:Range):void { throw new Error("not implemented"); }

		public function unhighlight(colour:int, interval:ca.ubc.ece.hct.Range):void { throw new Error("not implemented"); }

		public function updateHighlights():void { throw new Error("not implemented"); }
	}
}