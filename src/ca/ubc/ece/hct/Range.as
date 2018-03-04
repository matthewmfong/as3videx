////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct {
	
	public class Range {
		private var _start:Number;
		private var _end:Number;

		public function Range(start:Number = -1, end:Number = -1) {
			_start = start;
			_end = end;
		}

		public function contains(val:Number):Boolean {
			return (val >= _start && val <= _end);
		}

		public function get start():Number {
			return _start;
		}

		public function set start(val:Number):void {
			_start = val;
		}

		public function get length():Number {
			return Math.abs(_end - _start);
		}

		public function get end():Number {
			return _end;
		}

		public function set end(val:Number):void {
			_end = val;
		}

		public function toString():String {
			return "[ " + start + ", " + end + " ]";
		}

		public static function fromString(s:String):Range {
			var r:Range = new Range();

            var numberRegExp:RegExp = /\d*\.?\d+/g;

			var regTest:Object = numberRegExp.exec(s);
			if(regTest == null) {
				return null;
			} else {
                r.start = Number(regTest);
            }

			regTest = numberRegExp.exec(s);
            if(regTest == null) {
                return r;
            } else {
                r.end = Number(regTest);
            }

			return r;
		}
	}
}