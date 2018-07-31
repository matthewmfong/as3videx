////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {
	
	public class Course {

		public var school:String;
		public var code:String;
		public var section:String;
		public var term:String;
		public var year:String;
		public var _startDate:Date;
		public var endDate:Date;

		public function Course(school:String, code:String, section:String, term:String, year:String) {
			this.school = school;
			this.code = code;
			this.section = section;
			this.term = term;
			this.year = year;
		}

		public function toString():String {
			return school + "_" + code + "_" + section + "_" + term + "_" + year;
		}

		public function set startDate(d:Date):void {
//			trace(new Error().getStackTrace());
			_startDate = d;
		}

		public function get startDate():Date {
//			trace(new Error().getStackTrace());
			return _startDate;
		}

	}
}