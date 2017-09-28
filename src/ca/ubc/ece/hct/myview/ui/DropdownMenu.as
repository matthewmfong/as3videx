////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {
	
	import org.osflash.signals.Signal;

	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class DropdownMenu extends Sprite {

		private static const cornerDiameter:Number = 8;
		private static const cornerRadius:Number = cornerDiameter/2;

		override public function get width():Number { return __width; }
		override public function get height():Number { return __height; }

		private var __width:Number;
		private var __height:Number = 22;

		private var menuItems:Vector.<DropdownMenuItem>;
		private var itemMaxWidth:Number;
		private var _selectedItem:DropdownMenuItem;;

		public var itemClicked:Signal;
		public var closeMe:Signal;

		public function DropdownMenu():void {

			menuItems = new Vector.<DropdownMenuItem>;
			itemMaxWidth = 0;

			itemClicked = new Signal(Object);
			closeMe = new Signal();
		}

		public function addDropdownMenuItem(val:DropdownMenuItem):void {
			menuItems.push(val);
			addChild(val);

			val.clicked.add(itemClickedDispatch);
			val.animationFinished.add(closeDropdownMenu);

			val.y = (menuItems.length-1) * menuItems[menuItems.length - 1].height + cornerDiameter/2;
			if(val.width < itemMaxWidth) {
				val.width = itemMaxWidth;
			} else if(val.width > itemMaxWidth) {
				itemMaxWidth = val.width;
				for(var i:int = 0; i<menuItems.length; i++) {
					menuItems[i].width = itemMaxWidth;
				}
			}
			drawBackground();
		}

		public function get selectedItem():DropdownMenuItem {
			return _selectedItem;
		}

		public function setSelectedItemIndex(index:uint):void {
			if(index > menuItems.length) {
				throw(new Error("index (" + index + ") is greater than menuItems.length (" + menuItems.length + "."))
			}

			_selectedItem = menuItems[index];
			for(var i:int = 0; i<menuItems.length; i++) {
				if(i != index) {
					menuItems[i].toggleActive = false;
				} else {
					menuItems[i].toggleActive = true;
				}
			}
		}

		private function drawBackground():void {
			graphics.clear();
			graphics.beginFill(0xbfbfbf);
			graphics.drawRoundRect(0, 0, itemMaxWidth, 
										cornerRadius * 2 + 
										menuItems.length * menuItems[menuItems.length - 1].height,
										cornerDiameter);
			graphics.endFill();

			graphics.beginFill(0xf0f0f0);
			graphics.drawRoundRect(1, 1, itemMaxWidth - 2, 
										cornerRadius * 2 + 
										menuItems.length * menuItems[menuItems.length - 1].height - 2,
										cornerDiameter);
			graphics.endFill();
			__height = menuItems.length * menuItems[menuItems.length - 1].height;
		}

		private function itemClickedDispatch(val:Object):void {

			for(var i:int = 0; i<menuItems.length; i++) {
				if(menuItems[i].value != val) {
					menuItems[i].toggleActive = false;	
				} else {
					_selectedItem = menuItems[i];
				}
			}

			itemClicked.dispatch(val);
		}

		private function closeDropdownMenu():void {
			closeMe.dispatch();
		}

	}
}