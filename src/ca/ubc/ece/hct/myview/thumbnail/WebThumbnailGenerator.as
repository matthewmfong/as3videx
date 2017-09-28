////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.thumbnail {
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import com.greensock.events.LoaderEvent;
import com.greensock.loading.*;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

import org.osflash.signals.Signal;

public class WebThumbnailGenerator {

		private var tiles:Vector.<BitmapData>;
		private var tileLoaded:Vector.<Signal>;
		private var thumbnailGetQueue:Array;
		private var subQueueLoadProgress:Vector.<Number>;
		private var tileSourceIndex:uint;

		public var video:VideoMetadata;

		public var thumbnailLoaded:Signal;
		public var downloadProgress:Signal;
		public var downloadComplete:Signal;

		public function WebThumbnailGenerator() {
			tiles = new Vector.<BitmapData>();
			tileLoaded = new Vector.<Signal>();
			thumbnailGetQueue = [];

			thumbnailLoaded = new Signal(BitmapData, Object); // image data, who called getThumbnail
			downloadProgress = new Signal(Number); // 0 -> 1 progress
			downloadComplete = new Signal();

			tileSourceIndex = 0;
		}

		public function destroy():void {
			while(tiles.length > 0) {
				(BitmapData)(tiles.pop()).dispose();
			}
		}

		public function loadVideo(video:VideoMetadata):void {
			this.video = video;

			for(var i:int = 0; i<video.tileSource[tileSourceIndex].numTiles; i++) {
				tileLoaded.push(new Signal(Number));
				thumbnailGetQueue.push([]);
				tiles.push(null);
			}

			startLoadingImages(video.tileSource[tileSourceIndex].folderURL, video.tileSource[tileSourceIndex].numTiles);
		}
		
		private function startLoadingImages(url:String, numTiles:uint):void {
			
			
			var queue:LoaderMax = new LoaderMax({name:"mainQueue", maxConnections:1, onProgress:mainProgressHandler, onComplete:mainCompleteHandler});
			
			// queue.autoLoad = true;
			
			for(var i:int = 1; i<=numTiles; i++) {
				
				var subQueue:LoaderMax = new LoaderMax({name:"individualTileQueue", onProgress:tileProgressHandler, onComplete:tileCompleteHandler});
				subQueue.append(new ImageLoader(url + i + ".jpg",
											{name: i - 1, estimatedBytes: 5000 * video.tileSource[tileSourceIndex].numFramesPerTile}) );
				queue.append(subQueue);
				trace(url + i + ".jpg");

			}

			queue.load();
		}

		public function getThumbnailInSeconds(time:Number, caller:Object):void {
			// trace(time + "*" + video.tileSource[tileSourceIndex].framerate)
			getThumbnail(Math.floor(time * video.tileSource[tileSourceIndex].framerate), caller);
		}

		public function getThumbnail(i:Number, target:Object):void {
			
			var index:uint = Math.min(i/video.tileSource[tileSourceIndex].numFramesPerTile, tiles.length - 1);
			
			// trace("getting frame " + i + " for " + target);

			if(tiles[index] != null) {	
			

				var tile:BitmapData = tiles[index];
				//var startY:uint = (i - index * video.numFramesPerTile) * video.tileHeight;
				sendBitmapFromTile(index, i, target);
				
			} else {
				
				// trace("tile " + index + " not loaded yet. Queueing.");
				//var startY:uint = (i - index * video.numFramesPerTile) * video.tileHeight;
				
				thumbnailGetQueue[index].push({target: target, absframe: i});
				//trace(startY);
				
				// trace("this is now the queue");
				// for(var b:int = 0; b<thumbnailGetQueue.length; b++) {
				// 	var traceString:String = b + ": ";
				// 	for(var j:int = 0; j<thumbnailGetQueue[b].length; j++) {
				// 		traceString += "{" + thumbnailGetQueue[b][j].absframe + "}, ";
				// 	}
				// 	trace(traceString);
				// }

				tileLoaded[index].addOnce(tileBitmapLoaded);
				thumbnailGetQueue.push({tileWaitingFor: index, absframe: i, requester:target});
				
			}
			
		}

		private function sendBitmapFromTile(tileIndex:Number, absframe:Number, target:Object):void {
			
			// var imageHeight:uint = video.tileSource[tileSourceIndex].frameHeight;
			// var imageWidth:uint = video.tileWidth;
			var bmpData:BitmapData = new BitmapData(video.tileSource[tileSourceIndex].frameWidth, video.tileSource[tileSourceIndex].frameHeight);
			
			var startY:uint = (absframe - tileIndex * video.tileSource[tileSourceIndex].numFramesPerTile) * video.tileSource[tileSourceIndex].frameHeight;
			
			// trace("tiles.length = " + tiles.length + " tileIndex = " + tileIndex);;
			// trace("Private Memory: " + System.privateMemory/1024/1024 + "MB, Total Memory: " + System.totalMemoryNumber/1024/1024 + "MB.");
			
			bmpData.lock();
			bmpData.copyPixels(tiles[tileIndex], new Rectangle(0, startY, video.tileSource[tileSourceIndex].frameWidth, video.tileSource[tileSourceIndex].frameHeight), new Point(0, 0));
			bmpData.unlock();

			// trace("target.lastTime = " +  target._lastTime);
			
			thumbnailLoaded.dispatch(bmpData, target);	
		}

		private function tileBitmapLoaded(tileName:String):void {
			
			// trace("tile " + tileName + " loaded. getting.");
			
			for(var i:int = 0; i<thumbnailGetQueue[Number(tileName)].length; i++) {

				var tileRequest:Object = thumbnailGetQueue[Number(tileName)][i]
				
				sendBitmapFromTile(Number(tileName), tileRequest.absframe, tileRequest.target);
				
			}
		}

		private function mainProgressHandler(e:LoaderEvent):void {
		   // trace("progress: " + e.target.progress);
		   // trace(e.target.name);
		   downloadProgress.dispatch(e.target.progress);
		}

		private function tileProgressHandler(e:LoaderEvent):void {
		   // trace("tileprogress: " + e.target.progress);
		   // trace(e.target.name);
		   // downloadProgress.dispatch(e.target.progress);
		}


		private function tileCompleteHandler(e:LoaderEvent):void {

			var index:Number = Number(e.target.content[0].name);

			tiles[index] = e.target.content[0].rawContent.bitmapData;

			tileLoaded[index].dispatch(index);
			
		}

		private function mainCompleteHandler(event:LoaderEvent):void {

			for(var j:int = 0; j<tileLoaded.length; j++) {
				tileLoaded[j] = null;
			}

			while(tileLoaded.length > 0) {
				tileLoaded.pop();
			}

			downloadComplete.dispatch();
		}
	}
}