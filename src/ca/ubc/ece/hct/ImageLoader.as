////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct {

import ca.ubc.ece.hct.myview.Constants;

import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;

	public class ImageLoader extends Sprite {

		private var loader:Loader = new Loader();
		private var _path:String;

		public function ImageLoader(path:String = null) {
			loader = new Loader();
			if(path != null)
				load(path);
			addChild(loader);
		}

		public function load(path:String):void {
			_path = path;
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, fallback);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
			loader.load(new URLRequest("app-storage:/" + _path));
		}

		private function loadComplete(e:Event):void {
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, fallback);
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadComplete);
			dispatchEvent(new Event(Event.COMPLETE));
		}

		private function fallback(e:IOErrorEvent):void {
			// trace("fallback 1");
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, fallback);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, fallback2);
			loader.load(new URLRequest("app:/" + _path));
		}

		private function fallback2(e:IOErrorEvent):void {
			// trace("fallback 2");
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, fallback2);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, fallback3);
			loader.load(new URLRequest("http://" + Constants.DOMAIN + "/myview/" + _path));
		}

		private function fallback3(e:IOErrorEvent):void {
			// trace("fallback 3");
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, fallback3);
			loader.load(new URLRequest(_path));
		}

	}
}
