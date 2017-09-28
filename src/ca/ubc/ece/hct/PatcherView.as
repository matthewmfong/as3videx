////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct {

import flash.display.Loader;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.system.LoaderContext;
import flash.text.TextField;
import flash.utils.ByteArray;

public class PatcherView extends Sprite {

		public var patcher:Patcher;
		private var stateTextField:TextField;
		private var ffmpegDownloadProgressTextField:TextField;
		private var ffmpegDownloadSpeedTextField:TextField;

		private var loader:Loader;

		public function PatcherView(inputClassID:String) {

			stateTextField = new TextField();
			stateTextField.width = 200;
			addChild(stateTextField);

			ffmpegDownloadProgressTextField = new TextField();
			ffmpegDownloadProgressTextField.x = stateTextField.width;
			addChild(ffmpegDownloadProgressTextField);

			ffmpegDownloadSpeedTextField = new TextField();
			ffmpegDownloadSpeedTextField.x = ffmpegDownloadProgressTextField.x + ffmpegDownloadSpeedTextField.width;
			addChild(ffmpegDownloadSpeedTextField);

			patcher = new Patcher(inputClassID);
			patcher.state.add(stateChange)
			patcher.ffmpegDownloadProgress.add(ffmpegDownloadProgress);
			patcher.ffmpegDownloadSpeed.add(ffmpegDownloadSpeed);
			patcher.patchComplete.add(startApplication);
			patcher.start();
		}

		private function stateChange(state:String):void {
			stateTextField.text = state;
		}

		private function ffmpegDownloadProgress(percentage:Number):void {
			ffmpegDownloadProgressTextField.text = Math.round(percentage * 1000)/10 + "%";
		}

		private function ffmpegDownloadSpeed(speed:Number):void {
			var i:int = 0;

			for(i = 0; speed > 1024; i++) {
				speed = speed / 1024;
			}

			var unit:String = "";
			switch(i) {
				case 0:
					unit = "B/s";
					break;
				case 1:
					unit = "KB/s";
					break;
				case 2:
					unit = "MB/s";
					break;
				case 3:
					unit = "GB/s";
					break;
			}

			ffmpegDownloadSpeedTextField.text = speed + " " + unit;
		}

		private function startApplication():void {
			while(numChildren > 0) {
				removeChildAt(0);
			}

			var swfBytes:ByteArray = new ByteArray();  
			var file:File = File.applicationStorageDirectory;
			file = file.resolvePath("Videx.swf");
												 
			var loadStream:FileStream = new FileStream();  
				 loadStream.open( file, FileMode.READ );  
				 loadStream.readBytes( swfBytes );  
				 loadStream.close();  
													  
			loader = new Loader();  
			var loaderContext:LoaderContext = new LoaderContext();  
				 loaderContext.allowLoadBytesCodeExecution = true;  
				 loader.loadBytes( swfBytes, loaderContext  );  
			addChild(loader);
		}
	}
}