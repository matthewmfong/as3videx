////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.StarlingNativeSignal;

	import starling.display.Sprite;
	import starling.events.Event;

	import flash.geom.Point;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;

	public class IVideoPlayer extends Sprite {

		public var state:String;
		protected var _aspectRatio:Number;
		public var reachedEndOfVideoSignal:Signal;
		public var playheadUpdateSignal:StarlingNativeSignal;
		public var playbackRateChanged:Signal;

		public function IVideoPlayer():void { 

			if(getQualifiedClassName(this) == getQualifiedClassName(IVideoPlayer)) {
				throw new Error("this class must be implemented");
			}
			
			reachedEndOfVideoSignal = new Signal();
			playbackRateChanged = new Signal(Number);
			playheadUpdateSignal = new StarlingNativeSignal(this, Event.ENTER_FRAME, Event);
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}

		protected function addedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		}

		protected function removedFromStage(e:Event):void {
			removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}

		override public function dispose():void {
			super.dispose();
            removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
            removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
			reachedEndOfVideoSignal = null;
			playheadUpdateSignal = null;
			playbackRateChanged = null;
		}

		public function load(url:String, 
							 dimensions:Point, 
							 duration:Number, 
							 keyframes:Array = null):void { throw new Error("not implemented"); }

		public function play():void { throw new Error("not implemented"); }

		public function pause():void { throw new Error("not implemented"); }

		public function stop():void { throw new Error("not implemented"); }

		public function seek(time:Number):void { throw new Error("not implemented"); }

		public function get playheadTime():Number { throw new Error("not implemented"); }

		public function get playbackRate():Number { throw new Error("not implemented"); }

		// public function playheadUpdate(e:Event):void { throw new Error("not implemented"); }

		public function setPlaybackRate(rate:Number):void { trace("not implemented"); }

		public function setPredefinedPlaybackRate(val:Array):void { trace("not implemented"); }

		public var _width:Number = 1, _height:Number = 1, _x:Number = 0, _y:Number = 0;
		override public function set width(val:Number):void { _width = val; }
		override public function set height(val:Number):void { _height = val; }
		override public function get width():Number { return _width; }
		override public function get height():Number { return _height; }
		override public function set x(val:Number):void { _x = val; }
		override public function set y(val:Number):void { _y = val; }
		override public function get x():Number { return _x; }
		override public function get y():Number { return _y; }
		public function setSize(width:Number, height:Number):void { }
		public function move(x:Number, y:Number):void { }
		public function get aspectRatio():Number { return _aspectRatio; }
		public function set aspectRatio(val:Number):void { _aspectRatio = val; }
	}
}