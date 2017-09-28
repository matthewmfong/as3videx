////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {
	
	import fl.controls.Button;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;

	public class TabController extends Sprite {

		public var sources:Array;
		public var sourceTabButtons:Array;
		// public var tabNames:Array;
		public var buttonContainer:Sprite;
		public var sourceContainer:Sprite;
		private var _width:Number, _height:Number;

		public function TabController(widthX:Number, heightX:Number) {
			sources = new Array();
			// tabNames = new Array();
			sourceTabButtons = new Array();

			buttonContainer = new Sprite();
			addChild(buttonContainer);

			sourceContainer = new Sprite();
			addChild(sourceContainer);

			_width = widthX;
			_height = heightX;
		}

		public function addTab(tabName:String, source:DisplayObject):void {
			// tabNames.push(tabName);
			sources.push(source);
			var button:TabControllerButton = new TabControllerButton(sourceTabButtons.length);
			button.label = tabName;
			button.addEventListener(MouseEvent.CLICK, tabButtonClicked);
			sourceTabButtons.push(button);
			buttonContainer.addChild(button);

			for(var i:int = 0; i<sourceTabButtons.length; i++) {
				sourceTabButtons[i].width = width / sourceTabButtons.length;
				sourceTabButtons[i].x = i * width / sourceTabButtons.length;
			}

			if(sourceTabButtons.length == 1) {
				activateSource(0);
			}
		}

		private function tabButtonClicked(e:MouseEvent):void {
			activateSource(e.currentTarget.id);
		}

		public function activateSource(id:int):void {
			sourceContainer.removeChildren();
			sourceContainer.addChild(sources[id]);
			sourceContainer.x = 0;
			sourceContainer.y = sourceTabButtons[0].height;
			
		}

		override public function get width():Number { return _width; }
		override public function get height():Number { return _height; }

		override public function set width(val:Number):void {
			_width = val;
			for(var i:int = 0; i<sources.length; i++) {
				sources[i].width = val;
			}

			for(var i:int = 0; i<sourceTabButtons.length; i++) {
				sourceTabButtons[i].width = val / sourceTabButtons.length;
				sourceTabButtons[i].x = i * val / sourceTabButtons.length;
			}
		}

		override public function set height(val:Number):void {
			_height = val;
			// for(var i:int = 0; i<sources.length; i++) {
			// 	sources[i].height = val - sourceTabButtons.height;
			// }
		}
	}
}