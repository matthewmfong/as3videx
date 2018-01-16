////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

import ca.ubc.ece.hct.UUID;

import com.greensock.*;
	import com.greensock.loading.*;
	import com.greensock.events.LoaderEvent;

	import flash.net.SharedObject;
	import org.osflash.signals.Signal;

	public class UserID {

		public static var loggedIn:Signal;
		public static var id:String;

		public static function login(courseString:String, preset_id:String = null):void {

			loggedIn = new Signal();

			var so:SharedObject = SharedObject.getLocal("userid");

            // Shared object doesn't exist.
            if (so.size == 0) {
				id = courseString + "_" + UUID.getUUID();
                so.data.userid = id;
            } else {
                id = so.data.userid;

				if(id.indexOf(courseString) < 0) {
					id = courseString + "_" + id;
                    so.data.userid = id;

				}
            }

            if(preset_id != null) {
                id = preset_id + "_" + UUID.getUUID();
                so.data.userid = id;
            }


			ServerDataLoader.login(id).add(loginComplete);
				
		}

		public static function loginComplete(obj:Object):void {
			loggedIn.dispatch();
		}
	}
}