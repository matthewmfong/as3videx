////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

//package ca.ubc.ece.hct.myview.ui.button {
//
//	import flash.display.Loader;
//	import flash.events.Event;
//	import flash.net.URLRequest;
//
//	public class ImageButton extends BlankButton {
//
//		protected var _loader:Loader;
//		public static var iconMaxHeight:Number = 15;
//		private var enabledImageURI:String, disabledImageURI:String, activeImageURI:String;
//
//		public function ImageButton(width_:Number, initialImage:String, altText:String = null) {
//			super(width_, altText);
//			_loader = new Loader();
//			_loader.mouseEnabled = false;
//			addChild(_loader);
//
//			enabledImageURI = initialImage;
//
//			_loader.load(new URLRequest(enabledImageURI));
//			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderComplete);
//		}
//
//		public function set enabledImage(image:String):void {
//			enabledImageURI = image;
//		}
//
//		public function set disabledImage(image:String):void {
//			disabledImageURI = image;
//		}
//
//		public function set activeImage(image:String):void {
//			activeImageURI = image;
//			_loader.load(new URLRequest(activeImageURI));
//		}
//
//		override public function set toggle(val:Boolean):void {
//			super.toggle = val;
//
//			if(toggleAble && toggleActive) {
//				drawButtonDown();
//				if(disabledImageURI) {
//					_loader.load(new URLRequest(disabledImageURI));
//				}
//			} else if(toggleAble && !toggleActive) {
//				drawButtonUp();
//				if(enabledImageURI) {
//					_loader.load(new URLRequest(enabledImageURI));
//				}
//			}
//		}
//
//		protected function loaderComplete(e:Event):void {
//			var aspectRatio:Number = _loader.width / _loader.height;
//			_loader.height = Math.min(iconMaxHeight, _loader.height);
//			_loader.width = _loader.height * aspectRatio;
//			_loader.x = __width/2 - _loader.width/2;
//			_loader.y = __height/2 - _loader.height/2;
//		}
//
//	}
//}
 package ca.ubc.ece.hct.myview.ui.button {
	
 	import ca.ubc.ece.hct.ImageLoader;
 	import flash.events.Event;

 	public class ImageButton extends BlankButton {

 		protected var _loader:ImageLoader;
 		public static var iconMaxHeight:Number = 15;
 		private var enabledImageURI:String, disabledImageURI:String, activeImageURI:String;

 		public function ImageButton(width_:Number, initialImage:String, altText:String = null) {
 			super(width_, altText);
 			_loader = new ImageLoader();
// 			_loader.mouseEnabled = false;
 			addChild(_loader);

 			enabledImageURI = initialImage;

 			_loader.load(enabledImageURI);
 			_loader.addEventListener(Event.COMPLETE, loaderComplete);
 		}

 		public function set enabledImage(image:String):void {
 			enabledImageURI = image;
 		}

 		public function set disabledImage(image:String):void {
 			disabledImageURI = image;
 		}

 		public function set activeImage(image:String):void {
 			activeImageURI = image;
 			_loader.load(activeImageURI);
 		}

 		override public function set toggle(val:Boolean):void {
 			super.toggle = val;

 			if(toggleAble && toggleActive) {
 				drawButtonDown();
 				if(disabledImageURI) {
 					_loader.load(disabledImageURI);
 				}
 			} else if(toggleAble && !toggleActive) {
 				drawButtonUp();
 				if(enabledImageURI) {
 					_loader.load(enabledImageURI);
 				}
 			}
 		}

 		protected function loaderComplete(e:Event):void {
 			var aspectRatio:Number = _loader.width / _loader.height;
 			_loader.height = Math.min(iconMaxHeight, _loader.height);
 			_loader.width = _loader.height * aspectRatio;
 			_loader.x = __width/2 - _loader.width/2;
 			_loader.y = __height/2 - _loader.height/2;
 		}

 	}
 }