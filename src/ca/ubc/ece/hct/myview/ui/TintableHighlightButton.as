////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {
import ca.ubc.ece.hct.myview.*;

	import ca.ubc.ece.hct.myview.ui.button.ImageDropdownButton;
	import flash.display.Shape;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	public class TintableHighlightButton extends ImageDropdownButton {

		private var bitmap:Bitmap;
		private var bitmapData:BitmapData;
		private var tryAgainTintTimer:Timer;

		public function TintableHighlightButton(imageFilename:String, altText:String = null) {
			super(50, imageFilename, altText);

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
		}

		override protected function dropdownMenuItemClicked(val:Object):void {
			super.dropdownMenuItemClicked(val);
			tintImage(val as uint);
		}

		public function tintImage(val:uint):void {
			if(bitmap) {
				bitmap.bitmapData.draw(_loader);
				var pixel:uint;
				for(var i:int = 0; i<bitmap.bitmapData.width; i++) {
					for(var j:int = 0; j<bitmap.bitmapData.height; j++) {
						pixel = bitmap.bitmapData.getPixel32(i, j);
						// trace("(" + i + ", " + j + "): #" + pixel.toString(16));

						if(pixel != 0x12345678) {
							bitmap.bitmapData.setPixel(i, j, Util.brighten(Util.changeSaturation(val, 5), 0.75));
						} else {
							bitmap.bitmapData.setPixel32(i, j, 0);
						}
					}
				}
				addChild(bitmap);

                trace(bitmap.x + " " + bitmap.y + " " + bitmap.width + " " + bitmap.height);
                trace(_loader.x + " " + _loader.y + " " + _loader.width + " " + _loader.height);

                bitmap.width = _loader.width;
                bitmap.height = _loader.height;
                bitmap.x = _loader.x - 10;
                bitmap.y = _loader.y - 10;
			} else {
				// image hasn't loaded yet, so start a timer and try again later.
				tryAgainTintTimer = new Timer(500);
				tryAgainTintTimer.addEventListener(TimerEvent.TIMER,
					function tryToTintImageAgain(e:TimerEvent):void {
						tryAgainTintTimer.reset();
						tryAgainTintTimer = null;
						tintImage(val);
					});
				tryAgainTintTimer.start();
			}
		}

		public function untintImage(val:uint):void {
			if(contains(bitmap)) {
				removeChild(bitmap);
			}
		}
	}
}