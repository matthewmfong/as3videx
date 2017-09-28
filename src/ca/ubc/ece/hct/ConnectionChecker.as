////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct {

	import org.osflash.signals.Signal;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public class ConnectionChecker {

		public var online:Signal;
		public var offline:Signal;
		private var loader:URLLoader;

		public function ConnectionChecker() {
			online = new Signal();
			offline = new Signal();
			loader = new URLLoader();
		}

		public function checkConnection(urlToConnect:URLRequest):void {
			loader.load(urlToConnect);
			loader.addEventListener(Event.COMPLETE, connected);
			loader.addEventListener(IOErrorEvent.IO_ERROR, notConnected);
		}

		private function connected(e:Event):void {
			online.dispatch();
		}

		private function notConnected(e:IOErrorEvent):void {
			offline.dispatch();
		}
	}
}