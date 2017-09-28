////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui.button {
	
	import org.osflash.signals.DeluxeSignal;	

	import ca.ubc.ece.hct.myview.ui.DropdownMenu;
	import ca.ubc.ece.hct.myview.ui.DropdownMenuItem;
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.events.MouseEvent;

	public class ImageDropdownButton extends ImageButton {

		public static var iconMaxHeight:Number = 15;
		private var enabledImageURI:String, disabledImageURI:String, activeImageURI:String;
		protected var mainButton:Sprite;
		private var dropdownButton:Sprite;
		private var dropdownMenu:DropdownMenu;
		protected static const dropdownButtonWidth:Number = 16;
		private var mouseOriginalDownPoint:Point;
		private static const mouseThresholdMovedAmount:Number = 5; // amount the mouse has to move before it counts as a move
		private var mouseMovedOnDropdownMenu:Boolean = false;


		public var selected:DeluxeSignal;
		private var _selectedValue:Object;

		public function ImageDropdownButton(width_:Number, initialImage:String, altText:String = null) {
			super(width_, initialImage, altText);
			graphics.clear();
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUp);

			mainButton = new Sprite();
			dropdownButton = new Sprite();
			dropdownButton.x = __width - dropdownButtonWidth;
			addChild(mainButton);
			addChild(dropdownButton);
			drawMainButtonUp();
			drawDropdownButtonUp();
			setChildIndex(_loader, numChildren - 1);

			dropdownMenu = new DropdownMenu();
			dropdownMenu.itemClicked.add(dropdownMenuItemClicked);
			dropdownMenu.closeMe.add(dropDownMenuCloseEvent);
			
			selected = new DeluxeSignal(this, Object);

            mainButton.addEventListener(MouseEvent.MOUSE_DOWN, mainButtonMouseDown);
            mainButton.addEventListener(MouseEvent.MOUSE_UP, mainButtonMouseUp);
            mainButton.addEventListener(MouseEvent.ROLL_OUT, mainButtonRollOut);
            _loader.addEventListener(MouseEvent.MOUSE_DOWN, mainButtonMouseDown);
            _loader.addEventListener(MouseEvent.MOUSE_UP, mainButtonMouseUp);
            _loader.addEventListener(MouseEvent.ROLL_OUT, mainButtonRollOut);

			dropdownButton.addEventListener(MouseEvent.MOUSE_DOWN, dropdownButtonMouseDown);
			// dropdownButton.addEventListener(MouseEvent.MOUSE_UP, dropdownButtonMouseUp);
		}

		public function addItem(name:String, itemPicture:DisplayObject, value:*, toggleAble:Boolean, toggleActive:Boolean = false):void {
			var item:DropdownMenuItem = new DropdownMenuItem(name, itemPicture, value);
			item.toggleAble = toggleAble;
			item.toggleActive = toggleActive;
			dropdownMenu.addDropdownMenuItem(item);
		}

		override protected function loaderComplete(e:Event):void {
			super.loaderComplete(e);
			_loader.x = (__width - dropdownButtonWidth)/2 - _loader.width/2;
			_loader.y = __height/2 - _loader.height/2;

		}

		override public function set toggle(val:Boolean):void {
			toggleActive = val;
			if(toggleAble && toggleActive) {
				drawMainButtonDown();
			} else if(toggleAble && !toggleActive) {
				drawMainButtonUp();
			}
		}

		public function get selectedValue():Object {
			return _selectedValue;
		}

		public function setSelectedIndex(index:uint):void {
			dropdownMenu.setSelectedItemIndex(index);
			_selectedValue = dropdownMenu.selectedItem.value;
		}

		private function mainButtonMouseDown(e:MouseEvent):void {
			drawMainButtonDown();
		}

		private function mainButtonMouseUp(e:MouseEvent):void {

			if(toggleAble && !toggleActive) {
				toggleActive = true;
				toggled.dispatch(this, true);
			} else if(toggleAble && toggleActive) {
				toggleActive = false;
				toggled.dispatch(this, false);
				drawMainButtonUp();
			} else if(!toggleAble) {
				drawButtonUp();
				clicked.dispatch();
			}
		}

		private function mainButtonRollOut(e:MouseEvent):void {
			if(!toggleActive) {
				drawMainButtonUp();
			}
		}

		private function dropdownButtonMouseDown(e:MouseEvent):void {
			drawDropdownButtonDown();
			if(!contains(dropdownMenu)) {
				mouseMovedOnDropdownMenu = false;
			} else {
				dropdownButton.addEventListener(MouseEvent.CLICK, dropdownButtonMouseUp);
			}

			addChild(dropdownMenu);
			dropdownMenu.x = dropdownButton.x;
			dropdownMenu.y = __height + 3;
			mouseOriginalDownPoint = new Point(e.localX, e.localX);
			dropdownButton.addEventListener(MouseEvent.MOUSE_MOVE, dropdownButtonMouseMove);
		}

		private function dropdownButtonMouseMove(e:MouseEvent):void {
			var xMove:Number = Math.abs(mouseOriginalDownPoint.x - e.localX);
			var yMove:Number = Math.abs(mouseOriginalDownPoint.y - e.localY);

			if(Math.sqrt(Math.pow(xMove, 2) + Math.pow(yMove, 2)) > mouseThresholdMovedAmount) {
				mouseMovedOnDropdownMenu = true;
				if(!focusManager.form.hasEventListener(MouseEvent.MOUSE_UP))
					focusManager.form.addEventListener(MouseEvent.MOUSE_UP, focusManagerMouseUp);
			}
		}

		private function focusManagerMouseUp(e:MouseEvent):void {
			if((e.target != dropdownMenu) && (e.target.parent != dropdownMenu)) {
				closeDropDownMenu();
				if(dropdownButton.hasEventListener(MouseEvent.MOUSE_MOVE))
					dropdownButton.removeEventListener(MouseEvent.MOUSE_MOVE, dropdownButtonMouseMove);

				if(focusManager.form.hasEventListener(MouseEvent.MOUSE_UP))
					focusManager.form.removeEventListener(MouseEvent.MOUSE_UP, focusManagerMouseUp);
			}
		}

		private function dropdownButtonMouseUp(e:MouseEvent):void {
			closeDropDownMenu();
			if(dropdownButton.hasEventListener(MouseEvent.MOUSE_MOVE))
				dropdownButton.removeEventListener(MouseEvent.MOUSE_MOVE, dropdownButtonMouseMove);
			mouseMovedOnDropdownMenu = false;
			if(dropdownButton.hasEventListener(MouseEvent.CLICK))
				dropdownButton.removeEventListener(MouseEvent.CLICK, dropdownButtonMouseUp);
		}

		protected function dropdownMenuItemClicked(val:Object):void {
			_selectedValue = val;

			if(toggleAble) {
				toggleActive = true;
				drawMainButtonDown();
			}
			selected.dispatch(val);
		}

		private function dropDownMenuCloseEvent():void {
			closeDropDownMenu();
		}

		private function closeDropDownMenu():void {
			drawDropdownButtonUp();
			if(contains(dropdownMenu))
				removeChild(dropdownMenu);
		}

		private function drawMainButtonUp():void {

			// back shadow
			mainButton.graphics.clear();
			mainButton.graphics.beginFill(0xafafaf);
			mainButton.graphics.moveTo(cornerRadius, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, __height);
			mainButton.graphics.lineTo(cornerRadius, __height);
			mainButton.graphics.curveTo(0, __height, 0, __height - cornerRadius);
			mainButton.graphics.lineTo(0, cornerRadius);
			mainButton.graphics.curveTo(0, 0, cornerRadius, 0);
			mainButton.graphics.endFill();

			// front of button
			var matr:Matrix = new Matrix;
			matr.createGradientBox(__width, __height, Math.PI/2, 0, 0);
			mainButton.graphics.beginGradientFill(GradientType.LINEAR, 
			[0xfcfcfc	, 0xfafafa], // colour
			[1, 1],  // alpha
			[0, 255], // ratio
			matr);
			mainButton.graphics.lineStyle(1, 0xffffff);
			mainButton.graphics.moveTo(cornerRadius, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, __height-1);
			mainButton.graphics.lineTo(cornerRadius, __height-1);
			mainButton.graphics.curveTo(0, __height-1, 0, __height-1 - cornerRadius);
			mainButton.graphics.lineTo(0, cornerRadius);
			mainButton.graphics.curveTo(0, 0, cornerRadius, 0);
			mainButton.graphics.endFill();

		}

		private function drawDropdownButtonUp():void {

			var ddbw:Number = dropdownButtonWidth;
			var cR:Number = cornerRadius;

			dropdownButton.graphics.clear();
			dropdownButton.graphics.beginFill(0xafafaf);
			dropdownButton.graphics.moveTo(0, 0);
			dropdownButton.graphics.lineTo(ddbw - cR, 0);
			dropdownButton.graphics.curveTo(ddbw, 0, ddbw, cR);
			dropdownButton.graphics.lineTo(ddbw, __height - cR);
			dropdownButton.graphics.curveTo(ddbw, __height, ddbw-cR, __height);
			dropdownButton.graphics.lineTo(0, __height);
			dropdownButton.graphics.lineTo(0, 0);
			dropdownButton.graphics.endFill();

			var matr:Matrix = new Matrix;
			matr.createGradientBox(__width, __height, Math.PI/2, 0, 0);
			dropdownButton.graphics.beginGradientFill(GradientType.LINEAR, 
			[0xfcfcfc	, 0xfafafa], // colour
			[1, 1],  // alpha
			[0, 255], // ratio
			matr);
			dropdownButton.graphics.lineStyle(1, 0xffffff);
			dropdownButton.graphics.moveTo(0, 0);
			dropdownButton.graphics.lineTo(ddbw - cR, 0);
			dropdownButton.graphics.curveTo(ddbw, 0, ddbw, cR);
			dropdownButton.graphics.lineTo(ddbw, __height-1 - cR);
			dropdownButton.graphics.curveTo(ddbw, __height-1, ddbw-cR, __height-1);
			dropdownButton.graphics.lineTo(0, __height-1);
			dropdownButton.graphics.lineTo(0, 0);
			dropdownButton.graphics.endFill();

			// grey line
			dropdownButton.graphics.lineStyle(1, 0xe2e2e2, 1, false);
			dropdownButton.graphics.moveTo(0, 0);
			dropdownButton.graphics.lineTo(0, __height - 1);

			// arrow
			dropdownButton.graphics.lineStyle(2, 0x737373);
			dropdownButton.graphics.moveTo(ddbw - 5, 10);
			dropdownButton.graphics.lineTo(ddbw - 5 - 3, 13);
			dropdownButton.graphics.lineTo(ddbw - 5 - 3 - 3, 10);
		}

		protected function drawMainButtonDown():void {
			mainButton.graphics.clear();
			mainButton.graphics.lineStyle(NaN);
			// back shadow
			mainButton.graphics.beginFill(0xafafaf);
			mainButton.graphics.moveTo(cornerRadius, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, __height);
			mainButton.graphics.lineTo(cornerRadius, __height);
			mainButton.graphics.curveTo(0, __height, 0, __height - cornerRadius);
			mainButton.graphics.lineTo(0, cornerRadius);
			mainButton.graphics.curveTo(0, 0, cornerRadius, 0);
			// mainButton.graphics.drawRoundRect(0, 1, _width, _height, cornerDiameter);
			mainButton.graphics.endFill();
			mainButton.graphics.beginFill(0xf0f0f0);
			mainButton.graphics.moveTo(cornerRadius, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, __height-1);
			mainButton.graphics.lineTo(cornerRadius, __height-1);
			mainButton.graphics.curveTo(0, __height, 0, __height-1 - cornerRadius);
			mainButton.graphics.lineTo(0, cornerRadius);
			mainButton.graphics.curveTo(0, 0, cornerRadius, 0);
			// mainButton.graphics.drawRoundRect(0, 0, _width, _height, cornerDiameter);
			mainButton.graphics.endFill();

			var matr:Matrix = new Matrix();
			matr.createGradientBox(__width, __height, Math.PI/2, 0, 0);
			mainButton.graphics.beginGradientFill(GradientType.LINEAR, 
				[0xe4e4e4	, 0xe2e2e2], // colour
				[1, 1],  // alpha
				[0, 255], // ratio
				matr);
			//graphics.lineStyle(1, 0xffffff);
			mainButton.graphics.moveTo(cornerRadius, 2);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, 2);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, __height);
			mainButton.graphics.lineTo(cornerRadius, __height);
			mainButton.graphics.curveTo(0, __height, 0, __height - cornerRadius);
			mainButton.graphics.lineTo(0, cornerRadius);
			mainButton.graphics.curveTo(0, 0, cornerRadius, 2);
			// mainButton.graphics.drawRoundRect(0, 2, _width, _height, cornerDiameter);
			mainButton.graphics.endFill();
		}

		private function drawDropdownButtonDown():void {

			var ddbw:Number = dropdownButtonWidth;
			var cR:Number = cornerRadius;

			dropdownButton.graphics.clear();
			dropdownButton.graphics.lineStyle(NaN);
			dropdownButton.graphics.beginFill(0xafafaf);
			dropdownButton.graphics.moveTo(0, 0);
			dropdownButton.graphics.lineTo(ddbw - cR, 0);
			dropdownButton.graphics.curveTo(ddbw, 0, ddbw, cR);
			dropdownButton.graphics.lineTo(ddbw, __height - cR);
			dropdownButton.graphics.curveTo(ddbw, __height, ddbw - cR, __height);
			dropdownButton.graphics.lineTo(0, __height);
			dropdownButton.graphics.lineTo(0, 0);
			dropdownButton.graphics.endFill();

			dropdownButton.graphics.beginFill(0xf0f0f0);
			dropdownButton.graphics.moveTo(0, 0);
			dropdownButton.graphics.lineTo(ddbw - cR, 0);
			dropdownButton.graphics.curveTo(ddbw, 0, ddbw, cR);
			dropdownButton.graphics.lineTo(ddbw, __height-1 - cR);
			dropdownButton.graphics.curveTo(ddbw, __height-1, ddbw - cR, __height-1);
			dropdownButton.graphics.lineTo(0, __height-1);
			dropdownButton.graphics.lineTo(0, 0);
			dropdownButton.graphics.endFill();

			var matr:Matrix = new Matrix();
			matr.createGradientBox(__width, __height, Math.PI/2, 0, 0);
			dropdownButton.graphics.beginGradientFill(GradientType.LINEAR, 
				[0xe4e4e4	, 0xe2e2e2], // colour
				[1, 1],  // alpha
				[0, 255], // ratio
				matr);
			//graphics.lineStyle(1, 0xffffff);
			dropdownButton.graphics.moveTo(0, 2);
			dropdownButton.graphics.lineTo(ddbw - cR, 2);
			dropdownButton.graphics.curveTo(ddbw, 2, ddbw, 2+cR);
			dropdownButton.graphics.lineTo(ddbw, __height - cR);
			dropdownButton.graphics.curveTo(ddbw, __height, ddbw - cR, __height);
			dropdownButton.graphics.lineTo(0, __height);
			dropdownButton.graphics.lineTo(0, 2);
			dropdownButton.graphics.endFill();

			// grey line
			dropdownButton.graphics.lineStyle(1, 0xe2e2e2, 1, false);
			dropdownButton.graphics.moveTo(0, 0);
			dropdownButton.graphics.lineTo(0, __height - 1);

			// arrow
			dropdownButton.graphics.lineStyle(2, 0x737373);
			dropdownButton.graphics.moveTo(ddbw - 5, 10);
			dropdownButton.graphics.lineTo(ddbw - 5 - 3, 13);
			dropdownButton.graphics.lineTo(ddbw - 5 - 3 - 3, 10);
		}

	}
}