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
	
	public class Selectable extends PlaybackTimeReflectable {

		public var selected:Signal;
		public var deselected:Signal;

		public function Selectable() {

			selected = new Signal(Range);
			deselected = new Signal();
			
		}

		public function select(interval:ca.ubc.ece.hct.Range):void { throw new Error("not implemented"); }

		public function deselect():void { throw new Error("not implemented"); }
	}
}