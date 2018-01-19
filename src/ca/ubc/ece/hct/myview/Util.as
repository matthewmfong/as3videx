////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {
	
	CONFIG::AIR {
		import flash.desktop.NativeProcess;
		import flash.desktop.NativeProcessStartupInfo;
        import flash.events.NativeProcessExitEvent;
        import flash.filesystem.File;
        import flash.filesystem.FileMode;
        import flash.filesystem.FileStream;
        import flash.net.NetworkInterface;
        import flash.net.NetworkInfo;
	}
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;

	import flash.system.Capabilities;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.ByteArray;

	public class Util {

	CONFIG::AIR {
		public static function getMachineID():String {
			var networkInfo:NetworkInfo = NetworkInfo.networkInfo; 
			var interfaces:Vector.<NetworkInterface> = networkInfo.findInterfaces(); 
			 
			if( interfaces != null ) { 
				for each ( var interfaceObj:NetworkInterface in interfaces) {
					if(interfaceObj.hardwareAddress != "") {
						return interfaceObj.hardwareAddress;
					}
				}             
			}
			return "";
		}
	}


		public static function timeStringToMilliseconds(timeString:String):Number {
			var splitter:RegExp = /\:|\.|\,/;
			var times:Array = timeString.split(splitter);
			var ret:Number = -1; 
			switch(times.length) {
				case 3:
					ret = Number(times[0])*60*1000 + Number(times[1])*1000 + Number(times[2]);
					break;
				case 4:
					ret = Number(times[0])*3600*1000 + Number(times[1])*60*1000 + Number(times[2])*1000 + Number(times[3]);
					break;
			}
			return ret;
		}

		public static function millisecondsToTimeString(timeNumber:Number):String {
			var hours:int, minutes:int, seconds:int, milliseconds:int;
			var hoursString:String, minutesString:String, secondsString:String, millisecondsString:String;
			milliseconds = timeNumber%1000;
			seconds = (timeNumber/1000)%60;
			minutes = (timeNumber/1000/60)%60;
			hours = (timeNumber/1000/60/60);
			hoursString = hours.toString().length == 2 ? hours.toString() : "0" + hours.toString();
			minutesString = minutes.toString().length == 2 ? minutes.toString() : "0" + minutes.toString();
			secondsString = seconds.toString().length == 2 ? seconds.toString() : "0" + seconds.toString();
			if(milliseconds.toString().length == 3) {
				millisecondsString = milliseconds.toString();
			} else if(milliseconds.toString().length == 2) {
				millisecondsString = "0" + milliseconds.toString();
			} else if(milliseconds.toString().length == 1) {
				millisecondsString = "00" + milliseconds.toString();
			}
			// millisecondsString = milliseconds.toString().length == 3 ? milliseconds.toString() : "0" + milliseconds.toString();
			var stringBuild:String = "";
			if(hoursString != "00") {
				stringBuild = hoursString + ":" + minutesString + ":";
			} else {
				if(minutesString != "00") {
					stringBuild = stringBuild + minutesString + ":";
				}
			}
			return stringBuild + secondsString + "." + millisecondsString;
		}

		public static function millisecondsToHMS(timeNumber:Number):String {
			var hours:int, minutes:int, seconds:int, milliseconds:int;
			milliseconds = timeNumber%1000;
			seconds = (timeNumber/1000)%60;
			minutes = (timeNumber/1000/60)%60;
			hours = (timeNumber/1000/60/60);

			var stringBuild:String = "";
			if(hours != 0) {
				stringBuild = hours.toString() + "h" + minutes.toString() + "m";
			} else {
				if(minutes != 0) {
					stringBuild = stringBuild + minutes.toString() + "m";
				}
			}

			return stringBuild + seconds.toString() + "s";
		}

		public static function escape(input:String):String {
			var newString:String = input;
			// newString.replace(" ", "_SPACE_");
			return newString;
		}

		public static function angleDifference(a:Number, b:Number):Number {
			while(a > 2*Math.PI) {
				a -= 2*Math.PI;
			}
			while(b > 2*Math.PI) {
				b -= 2*Math.PI;
			}

			var result:Number = b - a;
			if(result < 0)
				result += 2*Math.PI;
			
			return result;
		}

		public static function RGBtoHSB(colour:uint):Array {

			var r:int = (colour & 0xff0000) >> 16;
			var g:int = (colour & 0xff00) >> 8;
			var b:int = colour & 0xff;

            var hue:Number, saturation:Number, brightness:Number;
            var hsbvals:Array = new Array();

            var cmax:int = (r > g) ? r : g;
            if (b > cmax) cmax = b;
            var cmin:int = (r < g) ? r : g;
            if (b < cmin) cmin = b;
     
            brightness = cmax/255;
            if (cmax != 0)
                saturation = (cmax - cmin)/cmax;
            else
                saturation = 0;
            if (saturation == 0)
                hue = 0;
            else {
                var redc:Number = (cmax - r) / (cmax - cmin);
                var greenc:Number = (cmax - g) / (cmax - cmin);
                var bluec:Number = (cmax - b) / (cmax - cmin);
                if (r == cmax)
                    hue = bluec - greenc;
                else if (g == cmax)
                    hue = 2 + redc - bluec;
                else
                    hue = 4 + greenc - redc;
                hue = hue / 6;
                if (hue < 0)
                    hue = hue + 1;
            }
            hsbvals.push(hue);
            hsbvals.push(saturation);
            hsbvals.push(brightness);
            return hsbvals;
        }

        public static function changeSaturation(colour:uint, change:Number):uint {

			var Pr:Number = 0.299;
			var Pg:Number = 0.587;
			var Pb:Number = 0.114;

			var R:int = (colour & 0xff0000) >> 16;
			var G:int = (colour & 0xff00) >> 8;
			var B:int = colour & 0xff;

        	var P:Number = Math.sqrt(R * R * Pr +
        							 G * G * Pg +
									 B * B * Pb);

			R = Math.min(0xff, P + (R - P) * change);
			G = Math.min(0xff, P + (G - P) * change);
			B = Math.min(0xff, P + (B - P) * change);

			return (R << 16) + (G << 8) + B;
        }

        public static function brighten(colour:uint, change:Number):uint {

			var R:int = Math.min(0xff, ((colour & 0xff0000) >> 16)*change);
			var G:int = Math.min(0xff, ((colour & 0xff00) >> 8)*change);
			var B:int = Math.min(0xff, (colour & 0xff)*change);

			return (R << 16) + (G << 8) + B;
        }

     CONFIG::AIR {

        public static function writeBytesToFile(filename:String, data:ByteArray, makeExecutable:Boolean = false):void { 
		    var outFile:File = File.applicationStorageDirectory; 
		    outFile = outFile.resolvePath(filename);  			 // name of file to write
		    var outStream:FileStream = new FileStream(); 
		    // open output file stream in WRITE mode 
		    outStream.open(outFile, FileMode.WRITE); 
		    // write out the file 
		    outStream.writeBytes(data, 0, data.length); 
		    // close it 
		    outStream.close(); 

		    if(makeExecutable) {
		    	chmod("", "+x", outFile.nativePath);
		    }
		} 
	}


	CONFIG::AIR {

		public static var chmodProcess:NativeProcess;
		public static var chmodStartupInfo:NativeProcessStartupInfo;
		public static var chmodArgs:Vector.<String>;
		public static function chmod(options:String, mode:String, absolutePath:String):void {
			var operatingSystem:String = Capabilities.os;
	        if(operatingSystem.indexOf("Mac") >= 0) {
			

				chmodStartupInfo = new NativeProcessStartupInfo();

				var file:File = new File("/bin/chmod");
				chmodStartupInfo.executable = file;

				chmodArgs = new Vector.<String>();
				if(options.length > 0)
					chmodArgs.push(options)
				chmodArgs.push(mode, absolutePath);
				chmodStartupInfo.arguments = chmodArgs;

				var traceString:String = "";
	            traceString += (file.nativePath);
	            for(var i:int = 0; i<chmodArgs.length; i++) {
	            	traceString += " " + chmodArgs[i];
	            }
	            trace(traceString);

				chmodProcess = new NativeProcess();
				chmodProcess.start(chmodStartupInfo);
	            chmodProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, ffprobeOnOutputData);
	            chmodProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, ffprobeOnErrorData);
	            chmodProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, ffprobeOnIOError);
	            chmodProcess.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, ffprobeOnIOError);
	            // chmodProcess.addEventListener(NativeProcessExitEvent.EXIT, ffprobeOnExit);
			}
		}
		public static function ffprobeOnOutputData(e:ProgressEvent):void {
			// var message:String = chmodProcess.standardOutput.readUTFBytes(chmodProcess.standardOutput.bytesAvailable)
	        // trace("______Output: \n"+ message + "______");
		}
		public static function ffprobeOnErrorData(e:ProgressEvent):void {
			// var message:String = chmodProcess.standardError.readUTFBytes(chmodProcess.standardError.bytesAvailable)
	        // trace("\n______\nOutput: "+ message + "\n______\n\n");
		}
		public static function ffprobeOnIOError(e:IOErrorEvent):void {
			// trace(e);
		}
		// public static function ffprobeOnExit(e:NativeProcessExitEvent):void {
	 //        // trace("EXIT");
		// }

	}


	CONFIG::AIR {
		public static function readFileIntoByteArray(filename:String, data:ByteArray):Boolean { 
	    	try {
		        var inFile:File = File.applicationStorageDirectory; 
		        inFile = inFile.resolvePath(filename);  // name of file to read 
		        var inStream:FileStream = new FileStream(); 
		        inStream.open(inFile, FileMode.READ); 
		        inStream.readBytes(data); 
		        inStream.close(); 
	        } catch(e:Error) {
	        	trace("Error reading " + inFile.nativePath);
	        	return false;
	        }
	        return true;
	    }

	    public static function readFileAbsolutePathIntoByteArray(path:String, data:ByteArray):Boolean {
	    	try {
		        var inFile:File = new File(path); 
		        var inStream:FileStream = new FileStream(); 
		        inStream.open(inFile, FileMode.READ); 
		        inStream.readBytes(data); 
		        inStream.close(); 
	        } catch(e:Error) {
	        	trace("Error reading " + path + e);
	        	return false;
	        }
	        return true;
	    }

	    public static function deleteFile(absolutePath:String):void {
	    	try {
	    		var file:File = new File(absolutePath);
		    	file.deleteFileAsync();
	    	} catch(e:Error) {}
	    }

	}

	    public static function dateParser(s:String):Date{
		    var regexp:RegExp = /(\d{4})\-(\d{1,2})\-(\d{1,2}) (\d{2})\:(\d{2})\:(\d{2})/;
		    var _result:Object = regexp.exec(s);

		    return new Date(
		        parseInt(_result[1]),
		        parseInt(_result[2])-1,
		        parseInt(_result[3]),
		        parseInt(_result[4]),
		        parseInt(_result[5]),
		        parseInt(_result[6])
		    );
		}

		public static function date2string(d:Date):String {
			return d.fullYear + "-" + (d.month+1) + "-" + d.date + " " + d.hours + ":" + d.minutes + ":" + d.seconds;
		}


        /**
		 *
         * @param m
         * @param length January? or Jan?
         * @return
         */
		public static function monthNumber2String(m:Number, length:uint = 255):String {
			if(m < 0 || m > 11) {
				return m + " is not a valid MONTH";
			}

			return Constants.MONTH[m].substr(0, length);
		}


        /**
		 *
         * @param d
         * @param length Monday? or Mon?
         * @return
         */
        public static function dayNumber2String(d:Number, length:uint = 255):String {
			if(d < 0 || d > 6) {
				return d + " is not a valid DAY of the week.";
			}

			return Constants.DAY[d].substr(0, length);
        }

        public static function timeInSecondsToTimeString(timeX:Number):String {
            var newMinutes:String = uint(timeX/60).toString();
            newMinutes = newMinutes.length == 1 ? "0" + newMinutes : newMinutes;
            var newSeconds:String = uint(timeX%60).toString();
            newSeconds = newSeconds.length == 1 ? "0" + newSeconds : newSeconds;
            return newMinutes + ":" + newSeconds;
        }

	    public static function roundNumber(num:Number, numDecimalPlaces:int):Number {
	    	var exponent:int = Math.pow(10, numDecimalPlaces);

	    	return Math.round(num * exponent)/exponent;
	    }

        public static function mouseCursorButton(e:Event = null):void {
        	if(Mouse.cursor != MouseCursor.BUTTON)
	        	Mouse.cursor = MouseCursor.BUTTON;
        }

        public static function mouseCursorArrow(e:Event = null):void {
        	if(Mouse.cursor != MouseCursor.ARROW)
	        	Mouse.cursor = MouseCursor.ARROW;
        }

        public static function mouseCursorHand(e:Event = null):void {
        	if(Mouse.cursor != MouseCursor.HAND)
        	Mouse.cursor = MouseCursor.HAND;
        }

        public static function mouseCursorIBeam(e:Event = null):void {
        	if(Mouse.cursor != MouseCursor.IBEAM)
        	Mouse.cursor = MouseCursor.IBEAM;
        }

		public static function intersects(array1:Array, array2:Array):Boolean {
			for(var i:int = 0; i<array1.length; i++) {
				for(var j:int = 0; j<array2.length; j++) {
					if(i == j) {
						return true;
					}
				}
			}
			return false;
		}

        public static function arrayContains(array:Array, obj:*):Boolean {
            for(var i:int = 0; i<array.length; i++) {
                if(array[i] == obj) {
                    return true;
                }
            }

            return false;
        }

        /**
		 * Same as Array.indexOf() except it uses == rather than the strict equality ===
         * @param array Array to search
         * @param obj Object to search for
         * @return index of the array object if it exists, and -1 if it doesn't
         */
        public static function looseIndexOf(array:Array, obj:*):int {

			if(array && array.length > 0) {
                for (var i:int = 0; i < array.length; i++) {
                    if (array[i] == obj) {
                        return i;
                    }
                }
            }

            return -1;
        }
	}
}