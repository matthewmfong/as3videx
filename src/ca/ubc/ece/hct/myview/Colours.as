////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {
	
	public class Colours {

		public static const colours:Array = [0xfb9abb, 0xf7e1a0, 0xb3e1a5, 0xa5d5f6, 0xe1baeb];
		public static const colourNames:Array = ["Red", "Yellow", "Green", "Blue", "Purple"];
		public static const RED:uint = colours[0];
		public static const YELLOW:uint = colours[1];
		public static const GREEN:uint = colours[2];
		public static const BLUE:uint = colours[3];
		public static const PURPLE:uint = colours[4];

		public function Colours() {}

		public static function sortColours(colours:Array):Array {
			var newColours:Array = [];
			for(var i:int = 0; i<Colours.colours.length; i++) {
				for(var j:int = 0; j<colours.length; j++) {
					if(colours[j] == Colours.colours[i]) {
						newColours.push(colours[j]);
					}
				}
			}

			return newColours;
		}
	}
}