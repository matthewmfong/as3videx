////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets {

import ca.ubc.ece.hct.myview.Animate;
import ca.ubc.ece.hct.myview.StarlingView;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.ui.UIScrollView;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import com.greensock.TweenLite;
import com.greensock.easing.Power2;

import feathers.controls.Header;

import feathers.controls.ScrollContainer;

import flash.events.MouseEvent;
import flash.geom.Rectangle;

import org.osflash.signals.Signal;

import starling.display.DisplayObject;

import starling.display.Quad;

import starling.display.Shape;
import starling.display.Sprite;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;
import starling.text.TextFormat;

public class VideoPlaylistView extends StarlingView {

		public static const buttonDimensions:Rectangle = new Rectangle(0, 0, 150, 150);
		public static const playlistButtonDimension:Rectangle = new Rectangle(0, 0, 150, 150);
		public static const gap:Number = 5;
		public var mediaButtons:Array;
		public var expandedPlaylistView:VideoPlaylistView;
//		public var _width:Number, _height:Number;
		public var videoClicked:Signal;
		public var container:Sprite;
		private var scrollPane:ScrollContainer;

		private var titleHeader:Header;


    private var hello:Number = 0;
    private var textfielllld:TextField;

		public function VideoPlaylistView(playlist:VideoPlaylist, width:Number, height:Number, rootLevel:Boolean = false) {

			super();
			_width = width;
			_height = height;

			titleHeader = new Header();
			titleHeader.title = rootLevel ? "Home": playlist.listName;
            titleHeader.x = 5
            titleHeader.y = 5;
            titleHeader.width = _width;
			titleHeader.height = 30;

			addChild(titleHeader)

			container = new Sprite();
			scrollPane = new ScrollContainer();
			scrollPane.width = _width;
			scrollPane.height = _height - titleHeader.height - 10;
			scrollPane.x = 0;
			scrollPane.y = titleHeader.height + 10;
			addChild(scrollPane);
			scrollPane.addChild(container);

			videoClicked = new Signal(VideoMetadata, Number); // video, time to start playing

			mediaButtons = [];

			var xOffset:Number = 10;
			var yOffset:Number = 10;

			for(var i:int = 0; i<playlist.mediaList.length; i++) {

				if(playlist.mediaList[i] is VideoPlaylist) {

					var button:VideoPlaylistButton = new VideoPlaylistButton(playlist.mediaList[i], buttonDimensions.width, buttonDimensions.height);

					button.x = xOffset;
					button.y = yOffset;

					xOffset += VideoPlaylistView.playlistButtonDimension.width + gap;
					if(xOffset + button.width > _width) {
						xOffset = 10;
						yOffset += button.height + gap;
					}

					container.addChild(button);
					button.alpha = 0;
					TweenLite.to(button, 1, {alpha: 1, delay: i/10});
                    mediaButtons.push(button);
                    button.addEventListener(TouchEvent.TOUCH, playlistClickedHandler);

				} else if(playlist.mediaList[i] is VideoMetadata) {
					var button2:VideoMetadataButton = new VideoMetadataButton(playlist.mediaList[i], buttonDimensions.width, buttonDimensions.height);

					button2.x = xOffset;
					button2.y = yOffset;

					xOffset += VideoPlaylistView.buttonDimensions.width + gap;
					if(xOffset + button2.width > _width) {
						xOffset = 10;
						yOffset += button2.height + gap;
					}

                    container.addChild(button2);
					button2.alpha = 0;
					TweenLite.to(button2, 1, {alpha: 1, delay: i/10});
                    mediaButtons.push(button2);
                    mediaButtons[mediaButtons.length - 1].addEventListener(TouchEvent.TOUCH, videoClickedHandler);
				}
			}

//			scrollPane.update();

			graphics.beginFill(0xdddddd);
			graphics.drawRectangle(0, 0, _width, _height);
			graphics.endFill();


//            var quad:Quad = new Quad(200, 200);
//            quad.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void { textfielllld.text = ".... " + hello++; });
//            addChild(quad);

//            textfielllld = new TextField(800, 200, "hiii");
//            textfielllld.y = height - textfielllld.height;
//            addChild(textfielllld)
		}


        public function setSize(width:Number, height:Number):void {
            _width = width;
            _height = height;

            graphics.clear();
            graphics.beginFill(0xdddddd);
            graphics.drawRectangle(0, 0, _width, _height);
            graphics.endFill();

			titleHeader.width = _width;

            scrollPane.setSize(_width, _height - titleHeader.height - 10);

            var xOffset:Number = 10;
            var yOffset:Number = 10;

            for(var i:int = 0; i<mediaButtons.length; i++) {
                var button:Sprite = mediaButtons[i];

                button.x = xOffset;
                button.y = yOffset;
                xOffset += button.width + gap;
                if(xOffset + button.width > _width) {
                    xOffset = 10;
                    yOffset += button.height + gap;
                }
            }

            if(expandedPlaylistView) {
                expandedPlaylistView.setSize(_width, _height);
            }
//            scrollPane.update();
        }
//
		private function playlistClickedHandler(e:TouchEvent):void {
            var touch:Touch = e.getTouch((VideoPlaylistButton)(e.currentTarget));
//            textfielllld.text += ".... " + hello++ + "\n";
//			textfielllld.text += touch ? touch.toString() : null;
//			trace(touch);
			if (touch && touch.phase == TouchPhase.ENDED) {
//				trace("what")
				if (expandedPlaylistView && container.contains(expandedPlaylistView)) {
					container.removeChild(expandedPlaylistView);
					expandedPlaylistView = null;
				}
				var targetPlaylist:VideoPlaylist = (VideoPlaylistButton)(e.currentTarget).playlist;

//				textfielllld.text = "W: " + _width + ", H: " + (_height - (titleHeader.y + titleHeader.height + 5 + 1));
//				try {
                    expandedPlaylistView = new VideoPlaylistView(targetPlaylist, _width, _height - (titleHeader.y + titleHeader.height + 5 + 1));
//                } catch(e:Error) {
//					textfielllld.text += e.getStackTrace();
//				}
//                textfielllld.text += "'" + expandedPlaylistView.toString() + "' " + targetPlaylist.toString() + " " + _width + " " + _height + " " + titleHeader.y + " " + titleHeader.height;
				expandedPlaylistView.y = _height;
				TweenLite.to(expandedPlaylistView, 0.4, {y: titleHeader.y + titleHeader.height + 5 + 1, ease: Power2.easeInOut });
//				expandedPlaylistView.y = titleHeader.y + titleHeader.height + 5 + 1;
				addChild(expandedPlaylistView);

//				addChild(new Quad(500, 500, 0xff0000));

				expandedPlaylistView.videoClicked.add(videoClickedBubbler);

//				titleHeader.addEventListener(MouseEvent.ROLL_OVER, titleTextRollOver);
//				titleHeader.addEventListener(MouseEvent.ROLL_OUT, titleTextRollOut);
				titleHeader.addEventListener(TouchEvent.TOUCH, titleTextClicked);

				//			scrollPane.update();
			}
		}

        private function titleTextClicked(e:TouchEvent):void {
			var touch:Touch = e.getTouch(titleHeader);

			if(touch) {

				switch(touch.phase) {
                    case TouchPhase.ENDED:
                        Animate.fadeOut(expandedPlaylistView).add(function (t:DisplayObject):void { removeChild(expandedPlaylistView) });
                        titleHeader.removeEventListener(TouchEvent.TOUCH, titleTextClicked);
                        Util.mouseCursorArrow();
						break;
					case TouchPhase.HOVER:
							titleTextRollOver();
						break;
                }
            } else {
				titleTextRollOut();
			}
		}

		private function titleTextRollOver():void { Util.mouseCursorButton(); }
		private function titleTextRollOut():void { Util.mouseCursorArrow(); }

		private function videoClickedBubbler(video:VideoMetadata, time:Number):void {
			videoClicked.dispatch(video, time);
		}

		private function videoClickedHandler(e:TouchEvent):void {
            var touch:Touch = e.getTouch(this, TouchPhase.ENDED);
//            trace(touch);;
            if (touch) {
                var video:VideoMetadata = (VideoMetadataButton)(e.currentTarget).video;

//                if (video.totalNumberOfSourcesDownloaded == video.totalNumberOfSourcesToDownload)
                    videoClicked.dispatch(video, 0);
            }
		}

		public function toString():String {
			return titleHeader.title + " [VideoPlaylistView]";
		}
	}
}

import ca.ubc.ece.hct.myview.StarlingView;
import ca.ubc.ece.hct.myview.View;
import ca.ubc.ece.hct.myview.thumbnail.Thumbnail;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylist;

import com.greensock.*;

import starling.display.Canvas;

import starling.display.Shape;
import flash.events.MouseEvent;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;

class VideoPlaylistButton extends StarlingView {

	public var playlist:VideoPlaylist;
	public var title:TextField;
	public var titleBG:Canvas;

	public function VideoPlaylistButton(playlist:VideoPlaylist, width:Number, height:Number) {
		super();
		this.playlist = playlist;
		this.playlist.downloadProgress.add(progress);
		this.playlist.downloadComplete.add(complete);

		_width = width;
		_height = height;

		graphics.touchable = true;

		if(this.playlist.progressDownloaded == 1) {
			graphics.beginFill(0x9999ff);
		} else {
			graphics.beginFill(0xff9999);
		}
		graphics.drawRectangle(0, 0, _width, _height);
		graphics.endFill();

		title = new TextField(_width, _height);
		title.format = new TextFormat("Arial", 12, 0x167ac6, "center")//("Arial", 12, 0x167ac6, true, null, null, null, null, "center");
		title.text = playlist.listName;
		title.wordWrap = true;
		title.autoSize = TextFieldAutoSize.VERTICAL;
//		title.touchable = false;
		title.x = _width/2 - title.width/2;
		title.y = _height/2 - title.height/2;

		titleBG = new Canvas();
		titleBG.beginFill(0xffffff, 0.3);
		titleBG.drawRectangle(0, 0, title.width, title.height);
		titleBG.endFill();
		titleBG.x = title.x;
		titleBG.y = title.y;
//		titleBG.touchable = false;

		addChild(titleBG);
		addChild(title);
	}

	public function progress(obj:*, val:Number):void {

		graphics.clear();
		graphics.beginFill(0xff9999);
		graphics.drawRectangle(0, 0, _width, _height);
		graphics.endFill();
		graphics.beginFill(0x99ff99);
		graphics.drawRectangle(0, 0, val*_width, _height);
		graphics.endFill();
		title.text = playlist.listName + "\n Downloading \n" + (Math.round(val*100) + "%");

		titleBG.clear();
        titleBG.beginFill(0xffffff, 0.3);
        titleBG.drawRectangle(0, 0, title.width, title.height);
        titleBG.endFill();
	}

	public function complete(obj:*, val:Boolean):void {
		graphics.clear();
		graphics.beginFill(0x9999ff);
		graphics.drawRectangle(0, 0, _width, _height);
		graphics.endFill();

        title.text = playlist.listName;
		titleBG.clear();
        titleBG.beginFill(0xffffff, 0.3);
        titleBG.drawRectangle(0, 0, title.width, title.height);
        titleBG.endFill();
	}

	public function toString():String {
		return playlist.listName + "[VideoPlaylistButton]";
	}
}


class VideoMetadataButton extends StarlingView {

	public var video:VideoMetadata;
	public var title:TextField;
	public var titleBG:Shape;
	public var thumbnail:Thumbnail;

	public function VideoMetadataButton(video:VideoMetadata, width:Number, height:Number) {
		this.video = video;
		_width = width;
		_height = height;

		if(video.progressDownloaded == 1) {
			graphics.beginFill(0x9999ff);
			thumbnail = new Thumbnail();
			thumbnail.setSize(_width, _height);
			thumbnail.loadVideo(video);
			addChild(thumbnail);
			thumbnail.showImage();
		} else {
			graphics.beginFill(0xff9999);
		}
		graphics.drawRectangle(0, 0, _width, _height);
		graphics.endFill();
		graphics.touchable = true;

//        title = new TextField(width, height);
//        title.format = new TextFormat("Arial", 12, 0x167ac6, "center")//("Arial", 12, 0x167ac6, true, null, null, null, null, "center");
//		title.text = video.title;
//		title.width = _width;
//		title.wordWrap = true;
//		title.autoSize = "center";
        title = new TextField(_width, _height);
        title.format = new TextFormat("Arial", 12, 0x167ac6, "center")//("Arial", 12, 0x167ac6, true, null, null, null, null, "center");
        title.text = video.title;
        title.wordWrap = true;
        title.autoSize = TextFieldAutoSize.VERTICAL;
//		title.touchable = false;
		title.x = _width/2 - title.width/2;
		title.y = _height/2 - title.height/2;

		titleBG = new Shape();
		titleBG.graphics.beginFill(0xffffff, 0.7);
		titleBG.graphics.drawRect(0, 0, title.width, title.height);
		titleBG.graphics.endFill();
		titleBG.x = title.x;
		titleBG.y = title.y;

		addChild(titleBG);
		addChild(title);

		video.downloadProgress.add(downloadProgress);
		video.downloadComplete.add(downloadComplete);

		addEventListener(MouseEvent.ROLL_OVER, rollOver);
		addEventListener(MouseEvent.ROLL_OUT, rollOut);
        addEventListener(MouseEvent.CLICK, click);

	}

	public function downloadProgress(video:VideoMetadata, val:Number):void {
		graphics.clear();
		graphics.beginFill(0xff9999);
		graphics.drawRectangle(0, 0, _width, _height);
		graphics.endFill();
		graphics.beginFill(0x99ff99);
		graphics.drawRectangle(0, 0, val*_width, _height);
		graphics.endFill();

		title.text = video.title + "\n Downloading \n" + (Math.round(val*100) + "%");

		titleBG.graphics.clear();
		titleBG.graphics.beginFill(0xffffff, 0.7);
		titleBG.graphics.drawRect(0, 0, title.width, title.height);
		titleBG.graphics.endFill();
	}

	public function downloadComplete(video:VideoMetadata, val:Boolean):void {

		if(!thumbnail) {
            thumbnail = new Thumbnail();
		}
        thumbnail.setSize(_width, _height);
        thumbnail.loadVideo(video);
        addChild(thumbnail);
        thumbnail.showImage();

		setChildIndex(title, numChildren - 1);
		graphics.clear();
		graphics.beginFill(0x9999ff);
		graphics.drawRectangle(0, 0, _width, _height);
		graphics.endFill();


        title.text = video.title;
		titleBG.graphics.clear();
		titleBG.graphics.beginFill(0xffffff, 0.7);
		titleBG.graphics.drawRect(0, 0, title.width, title.height);
		titleBG.graphics.endFill();
	}

	private function reset():void {
		TweenLite.to(title, 0.3, {y: _height/2 - title.height/2});
		TweenLite.to(titleBG, 0.3, {y: _height/2 - titleBG.height/2});
		if(thumbnail)
			thumbnail.seekTimeInSeconds(5, false, true);
	}

	private function rollOver(e:MouseEvent):void {
		TweenLite.to(title, 0.3, {y: _height - title.height});
		TweenLite.to(titleBG, 0.3, {y: _height - titleBG.height});
	}

	private function rollOut(e:MouseEvent):void {
		reset();
	}

	private function click(e:MouseEvent):void {
		reset();
	}
}