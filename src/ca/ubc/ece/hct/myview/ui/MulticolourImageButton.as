////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {

import ca.ubc.ece.hct.myview.Colours;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.ui.button.ImageDropdownButton;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Shape;
import flash.events.Event;
import flash.utils.Timer;

public class MulticolourImageButton extends ImageDropdownButton {

		private var bitmap:Bitmap;
		private var bitmapData:BitmapData;
		private var tryAgainTintTimer:Timer;
		private var imagePrefix:String;
		private var addUnhighlight:Boolean;

		public function MulticolourImageButton(imagePrefix:String, initialColourString:String = "f7e1a0", altText:String = null, unhighlight:Boolean = true) {
			super(50, imagePrefix + "_" + initialColourString + ".png", altText);

			this.imagePrefix = imagePrefix;
			addUnhighlight = unhighlight;
            // trace("addunhighlight = " + addUnhighlight);

			_loader.addEventListener(Event.COMPLETE,
				function newBitmapData(e:Event):void {
					bitmap = new Bitmap();
					bitmapData = new BitmapData(_loader.width, _loader.height, true, 0x12345678);
					bitmap.bitmapData = bitmapData;
					bitmap.x = _loader.x;
					bitmap.y = _loader.y;
				});

			toggleAble = true;
			drawMe();
		}

		override public function setSelectedIndex(index:uint):void {
			super.setSelectedIndex(index);
			tintImage(selectedValue as uint);
		}

		private function drawMe():void {
			var colours:Array = Colours.colours;
			var colourNames:Array = Colours.colourNames;

			var circle:Shape;

			for(var i:int = 0; i<colours.length; i++) {
				circle = new Shape();
				circle.graphics.lineStyle(1, Util.changeSaturation(colours[i], 2));
				circle.graphics.beginFill(Util.changeSaturation(colours[i], 1), 1);
				circle.graphics.drawCircle(5, 5, 5);
				circle.graphics.endFill();
				addItem(colourNames[i], circle, colours[i], true);
			}

			if(addUnhighlight) {
                circle = new Shape();
                circle.graphics.lineStyle(1, 0xcccccc, 2);
                circle.graphics.beginFill(0xffffff, 1);
                circle.graphics.drawCircle(5, 5, 5);
                circle.graphics.endFill();
                circle.graphics.lineStyle(1, 0xff0000, 2);
                circle.graphics.moveTo(0, 0);
                circle.graphics.lineTo(10, 10);
                addItem("Unhighlight", circle, 0xffffff, true);
            }
		}

		override protected function dropdownMenuItemClicked(val:Object):void {
			super.dropdownMenuItemClicked(val);
			tintImage(val as uint);
		}

		override protected function drawMainButtonDown():void {

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
			mainButton.graphics.endFill();

			mainButton.graphics.beginFill(0xe0e0e0);
			mainButton.graphics.moveTo(cornerRadius, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, 0);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, __height-1);
			mainButton.graphics.lineTo(cornerRadius, __height-1);
			mainButton.graphics.curveTo(0, __height, 0, __height-1 - cornerRadius);
			mainButton.graphics.lineTo(0, cornerRadius);
			mainButton.graphics.curveTo(0, 0, cornerRadius, 0);
			mainButton.graphics.endFill();

			mainButton.graphics.beginFill(0xeaeaea);
			mainButton.graphics.moveTo(cornerRadius, 2);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, 2);
			mainButton.graphics.lineTo(__width - dropdownButtonWidth, __height);
			mainButton.graphics.lineTo(cornerRadius, __height);
			mainButton.graphics.curveTo(0, __height, 0, __height - cornerRadius);
			mainButton.graphics.lineTo(0, cornerRadius);
			mainButton.graphics.curveTo(0, 0, cornerRadius, 2);
			mainButton.graphics.endFill();
		}

		private function tintImage(colour:uint):void {
			var foundColour:Boolean = false;
			for(var i:int = 0; i<Colours.colours.length; i++) {
				if(colour == Colours.colours[i]) {
					foundColour = true;
					break;
				}
			} 
			if(foundColour || colour == 0xffffff) {
				activeImage = imagePrefix + "_" + colour.toString(16) + ".png";
			}
		}

		private function untintImage(val:uint):void {
			if(contains(bitmap)) {
				removeChild(bitmap);
			}
		}
	}
}