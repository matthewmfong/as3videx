////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

 package ca.ubc.ece.hct {

	import ca.ubc.ece.hct.PatcherView;
	import flash.display.MovieClip

	public class PatcherMain extends MovieClip {

		public static var CLASS_ID:String = COURSE::Name;
		private var patcherView:PatcherView;

		public function PatcherMain() {
			if(CONFIG::Instructor) {
				CLASS_ID += "-INSTRUCTOR";
			}
			patcherView = new PatcherView(CLASS_ID);
			addChild(patcherView);
		}

	}
}