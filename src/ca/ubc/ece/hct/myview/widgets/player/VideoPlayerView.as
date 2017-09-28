////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.player {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.filmstrip.MultiFilmstrip;
import ca.ubc.ece.hct.myview.widgets.pixie.Pixie;
import ca.ubc.ece.hct.myview.widgets.pixie.PixieV2;
import ca.ubc.ece.hct.myview.widgets.subtitleviewer.SubtitleViewer;

import flash.display.GradientType;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import org.osflash.signals.natives.NativeSignal;

public class VideoPlayerView extends View {

		private var _player:Player;
		private var _playerToolbar:PlayerToolbar;
		private var _filmstrip:MultiFilmstrip;
		public function get filmstrip():MultiFilmstrip { return _filmstrip; }
		private var _captionViewer:SubtitleViewer;
		private var _pix:Pixie;

		CONFIG::DEV {
			private var _pix2:PixieV2;
		}

		private var subtitleViewerSeparator:Sprite;
		private var filmstripSeparator:Sprite;
		private var separatorThickness:Number = 15;
		protected var temporaryPoint:Point;
		protected var mouseDownPoint:Point;
		protected var clickTimerThreshold:Number = 250;
		protected var clickStart:Date;

		private var filmstripWidth:Number;
		private var filmstripHeight:Number;
		private var subtitleViewerWidth:Number;
		private var subtitleViewerHeight:Number;
		protected var nonMaximizedPlayerDimensions:Rectangle;
		protected var nonMaximizedSubtitleViewerDimensions:Rectangle;
		protected var nonMaximizedFilmstripDimensions:Rectangle;

		private var model:VideoPlayerModel;

		private var removedFromStageSignal:NativeSignal;

		public function VideoPlayerView(width:Number, height:Number) {
			_width = width;
			_height = height;
			filmstripWidth = _width * 3/4 - separatorThickness;
			filmstripHeight = _height/5;
			subtitleViewerWidth = _width/4;
			subtitleViewerHeight = _height;
			nonMaximizedPlayerDimensions = new Rectangle(0, 0, 0, 0);
			nonMaximizedSubtitleViewerDimensions = new Rectangle(0, 0, 0, 0);
			nonMaximizedFilmstripDimensions = new Rectangle(0, 0, 0, 0);

			model = new VideoPlayerModel();
			_player = new Player(filmstripWidth, _height - filmstripHeight - PlayerToolbar.HEIGHT);
			_playerToolbar = new PlayerToolbar(filmstripWidth);
			_filmstrip = new MultiFilmstrip(filmstripWidth, filmstripHeight - separatorThickness);
			_captionViewer = new SubtitleViewer(subtitleViewerWidth, subtitleViewerHeight);
			_pix = new Pixie(100, 100);
			CONFIG::DEV {
                _pix2 = new PixieV2(500, 500);
            }

            _pix.width = 100;
            _pix.height = 100;

			_player.x = _captionViewer.x + _captionViewer.width + separatorThickness;
			_player.y = PlayerToolbar.HEIGHT;
			_playerToolbar.x = _player.x;
			_filmstrip.x = _captionViewer.x + _captionViewer.width + separatorThickness;
			_filmstrip.y = _player.y + _player.height + separatorThickness;
			_pix.x = _player.x;
			_pix.y = _player.y + _player.height - _pix.height - PlayerBar.TOOLBAR_HEIGHT;
			CONFIG::DEV {
                _pix2.x = _player.x + 20;
                _pix2.y = PlayerBar.TOOLBAR_HEIGHT + 10;
            }

			model.linkWidget(_player);
			model.linkWidget(_playerToolbar);
			model.linkWidget(_filmstrip);
			model.linkWidget(_captionViewer);
			model.linkWidget(_pix);
			CONFIG::DEV {
                model.linkWidget(_pix2);
            }


			subtitleViewerSeparator = new Sprite();
			subtitleViewerSeparator.x = _captionViewer.width;
			subtitleViewerSeparator.addEventListener(MouseEvent.MOUSE_DOWN, subtitleViewerSeparatorMouseDown);
			subtitleViewerSeparator.addEventListener(MouseEvent.ROLL_OVER,
				function subtitleViewerSeparatorRollOver(e:MouseEvent):void {
					Util.mouseCursorHand();
					});
			subtitleViewerSeparator.addEventListener(MouseEvent.ROLL_OUT,
				function subtitleViewerSeparatorRollOver(e:MouseEvent):void {
					Util.mouseCursorArrow();
					});
			drawSubtitleViewerSeparator()
			addChild(subtitleViewerSeparator);

			filmstripSeparator = new Sprite();
			filmstripSeparator.x = subtitleViewerSeparator.x + separatorThickness;
			filmstripSeparator.y = _player.y + _player.height;
			filmstripSeparator.addEventListener(MouseEvent.MOUSE_DOWN, filmstripSeparatorMouseDown);
			filmstripSeparator.addEventListener(MouseEvent.ROLL_OVER,
				function filmstripSeparatorRollOver(e:MouseEvent):void {
					Util.mouseCursorHand();
					});
			filmstripSeparator.addEventListener(MouseEvent.ROLL_OUT,
				function filmstripSeparatorRollOver(e:MouseEvent):void {
					Util.mouseCursorArrow();
					});
			drawFilmstripSeparator();
			addChild(filmstripSeparator);

            addChild(_player);
            addChild(_playerToolbar);
            addChild(_filmstrip);
            addChild(_captionViewer);
            addChild(_pix);
			CONFIG::DEV {
                addChild(_pix2);
            }

			removedFromStageSignal = new NativeSignal(this, Event.REMOVED_FROM_STAGE, Event);
			removedFromStageSignal.add(removedFromStage);
		}

		public function loadVideo(video:VideoMetadata, interval:Range):void {
			model.loadVideo(video, interval);
		}

		public function removedFromStage(e:Event = null):void {
			model.stop(null);
			_player.stop();
		}

		protected function subtitleViewerSeparatorMouseDown(e:MouseEvent):void {
			_filmstrip.setResizingStatus(true);
			clickStart = new Date();
			mouseDownPoint = new Point(mouseX, mouseY);
			temporaryPoint = new Point(subtitleViewerSeparator.x, subtitleViewerSeparator.y);

			addEventListener(MouseEvent.MOUSE_MOVE, resizeSubtitleViewerSeparator);
			_player.allowAnimation = false;
			addEventListener(MouseEvent.MOUSE_UP, subtitleViewerSeparatorMouseUp);
		}

		protected function subtitleViewerSeparatorMouseUp(e:MouseEvent):void {
			//actionLogSignal.dispatch("Resized SubtitleViewer to " + this.mouseX);
			if(new Date().time - clickStart.time < clickTimerThreshold) {
				if(subtitleViewerSeparator.x != 0) {
					subtitleViewerWidth = mouseX;
					// new Tween(this, "subtitleViewerSeparatorX", Strong.easeInOut, mouseDownPoint.x, 0, 0.5, true);
					hideSubtitleViewer(mouseX);
					drawSubtitleViewerSeparator(false);
				} else {
					// new Tween(this, "subtitleViewerSeparatorX", Strong.easeInOut, 0, subtitleViewerWidth, 0.5, true);
					showSubtitleViewer();
					drawSubtitleViewerSeparator(true);
				}
			}
			_player.allowAnimation = true;
			_filmstrip.setResizingStatus(false);
			removeEventListener(MouseEvent.MOUSE_MOVE, resizeSubtitleViewerSeparator);
			removeEventListener(MouseEvent.MOUSE_UP, subtitleViewerSeparatorMouseUp);
		}

		protected function resizeSubtitleViewerSeparator(e:MouseEvent):void {
			var change:Number = temporaryPoint.x - (mouseDownPoint.x - mouseX);
			subtitleViewerSeparatorX = change;

		}

		public function hideSubtitleViewer(showPosition:Number):void {

			/*subtitleViewerWidth = showPosition;
			
			subtitleShowHideTween = new Tween(this, "subtitleViewerShowHide", Strong.easeInOut, subtitleViewer.width, 0, 0.5, true);
			filmstrip.setResizingStatus(true);
			subtitleShowHideTween.addEventListener(TweenEvent.MOTION_FINISH,
				function subtitleShowHideTweenFinish(e:Event):void {
					filmstrip.setResizingStatus(false);
					subtitleShowHideTween.removeEventListener(TweenEvent.MOTION_FINISH, subtitleShowHideTweenFinish);
					});*/
			// new Tween(this, "subtitleViewerShowHide", Strong.easeInOut, sideTabController.width, 0, 0.5, true);
		}

		public function showSubtitleViewer():void {

		/*	subtitleShowHideTween = new Tween(this, "subtitleViewerShowHide", Strong.easeInOut, 0, subtitleViewer.width, 0.5, true);
			filmstrip.setResizingStatus(true);
			subtitleShowHideTween.addEventListener(TweenEvent.MOTION_FINISH,
				function subtitleShowHideTweenFinish(e:Event):void {
					filmstrip.setResizingStatus(false);
					subtitleShowHideTween.removeEventListener(TweenEvent.MOTION_FINISH, subtitleShowHideTweenFinish);
					});*/
			// new Tween(this, "subtitleViewerShowHide", Strong.easeInOut, 0, sideTabController.width, 0.5, true);			
		}

		public function set subtitleViewerShowHide(val:Number):void {

			//_captionViewer.x = val - _captionViewer.width;
			//// sideTabController.x = val - sideTabController.width;

			//subtitleViewerSeparator.x = _captionViewer.x + subtitleViewer.width;
			//// subtitleViewerSeparator.x = sideTabController.x + sideTabController.width;
			//filmstripSeparator.x = val;
			//drawFilmstripSeparator();


			//filmstrip.width = _width - val - separatorThickness;
			//filmstrip.x = val + separatorThickness;


			//_player.width = _width - val - separatorThickness;
			//_player.x = val + separatorThickness;
		}

		public function set subtitleViewerSeparatorX(x_:Number):void {
			// trace("before " + filmstrip.width + ", " + _width + ", " + subtitleViewerSeparator.x + ", " + separatorThickness);
			// trace("before " + (_width - (subtitleViewerSeparator.x + separatorThickness)));
			subtitleViewerSeparator.x = x_;
			filmstripSeparator.x = x_ + separatorThickness;
			// filmstripSeparator.width = _width - x_;
			drawFilmstripSeparator();

			_captionViewer.width = x_ ;
			nonMaximizedSubtitleViewerDimensions.width = _captionViewer.width;
			// sideTabController.width = x_ ;

			filmstrip.width = _width - (subtitleViewerSeparator.x + separatorThickness);
			filmstrip.x = subtitleViewerSeparator.x + separatorThickness;

			nonMaximizedFilmstripDimensions.width = filmstrip.width;
			nonMaximizedFilmstripDimensions.x = filmstrip.x;


			_player.width = _width - x_ - separatorThickness;
			_player.x = x_ + separatorThickness;

			_playerToolbar.width = _width - x_ - separatorThickness;

			_playerToolbar.x = x_ + separatorThickness;

			nonMaximizedPlayerDimensions.width = _player.width;
			nonMaximizedPlayerDimensions.x = _player.x;


            _pix.x = _player.x;
            _pix.y = _player.y + _player.height - _pix.height - PlayerBar.TOOLBAR_HEIGHT;


			// trace("after " + filmstrip.width + ", " + _width + ", " + subtitleViewerSeparator.x + ", " + separatorThickness);
			// buttonsContainer.x = subtitleViewerSeparator.x - buttonsContainerWidth;
		}

		protected function resizeFilmstripSeparator(e:MouseEvent):void {
			var change:Number = temporaryPoint.y - (mouseDownPoint.y - mouseY);

			filmstripSeparatorY = change;
		}

		public function set filmstripSeparatorY(y_:Number):void {
			filmstripSeparator.y = y_;
			_player.height = y_ - PlayerToolbar.HEIGHT;
			filmstrip.y = filmstripSeparator.y + separatorThickness;
			filmstrip.height = _height - y_ - separatorThickness;

            _pix.x = _player.x;
            _pix.y = _player.y + _player.height - _pix.height - PlayerBar.TOOLBAR_HEIGHT;

			nonMaximizedFilmstripDimensions.y = filmstrip.y;
			nonMaximizedFilmstripDimensions.height = filmstrip.height;
		}

		protected function filmstripSeparatorMouseDown(e:MouseEvent):void {
			filmstrip.setResizingStatus(true);
			temporaryPoint = new Point(filmstripSeparator.x, filmstripSeparator.y);
			mouseDownPoint = new Point(mouseX, mouseY);
			clickStart = new Date();
			addEventListener(MouseEvent.MOUSE_MOVE, resizeFilmstripSeparator);
			_player.allowAnimation = false;
			addEventListener(MouseEvent.MOUSE_UP, filmstripSeparatorMouseUp)
		}

		protected function filmstripSeparatorMouseUp(e:MouseEvent):void {
			// actionLogSignal.dispatch("Resized Filmstrip to " + (_height - this.mouseY));

			var filmstripSeparatorYFinalPosition:Number = filmstripSeparator.y;

			if(new Date().time - clickStart.time < clickTimerThreshold) {
				if(filmstripSeparator.y != 0) {
					/*filmstripSeparatorYFinalPosition = mouseDownPoint.y;
					filmstripHeight = _height - mouseY;
					filmstrip.setResizingStatus(true);
					filmstripSeparatorTween = new Tween(this, "filmstripSeparatorY", Strong.easeInOut, mouseDownPoint.y, 0, 0.5, true);
					filmstripSeparatorTween.addEventListener(TweenEvent.MOTION_FINISH,
						function filmstripShowHideTweenFinish(e:Event):void {
							filmstrip.setResizingStatus(false);
							filmstripSeparatorTween.removeEventListener(TweenEvent.MOTION_FINISH, filmstripShowHideTweenFinish);
							});
					drawFilmstripSeparator(true);*/
				} else {
				/*	filmstripSeparatorYFinalPosition = _height - separatorThickness - filmstripHeight
					filmstrip.setResizingStatus(true);
					filmstripSeparatorTween = new Tween(this, "filmstripSeparatorY", Strong.easeInOut, 0, _height - separatorThickness - filmstripHeight, 0.5, true);
					filmstripSeparatorTween.addEventListener(TweenEvent.MOTION_FINISH,
						function filmstripShowHideTweenFinish(e:Event):void {
							filmstrip.setResizingStatus(false);
							filmstripSeparatorTween.removeEventListener(TweenEvent.MOTION_FINISH, filmstripShowHideTweenFinish);
							});
					drawFilmstripSeparator(false);*/
				}
			}
			
			filmstrip.height = _height - filmstripSeparatorYFinalPosition - separatorThickness;

			filmstrip.setResizingStatus(false);
			
			_player.allowAnimation = true;

			removeEventListener(MouseEvent.MOUSE_MOVE, resizeFilmstripSeparator);
			removeEventListener(MouseEvent.MOUSE_UP, filmstripSeparatorMouseUp);
		}

		public function setSize(width:Number, height:Number):void {
			_width = width;
			_height = height;

			_captionViewer.height = _height;
			_player.width = _width - _captionViewer.width - separatorThickness
            _player.height = _height - PlayerToolbar.HEIGHT - _filmstrip.height - separatorThickness;
            _filmstrip.width = _width - _captionViewer.width - separatorThickness;
            _filmstrip.y = _player.y + _player.height + separatorThickness;
			_playerToolbar.setSize(_player.width, PlayerToolbar.HEIGHT);
			filmstripSeparator.y = _player.y + _player.height;

            _pix.x = _player.x;
            _pix.y = _player.y + _player.height - _pix.height - PlayerBar.TOOLBAR_HEIGHT;

			drawFilmstripSeparator();
			drawSubtitleViewerSeparator();


		}

		public function drawSubtitleViewerSeparator(left:Boolean = true):void {
			subtitleViewerSeparator.graphics.clear();
			subtitleViewerSeparator.graphics.lineStyle(1, 0x555555);
			var matr:Matrix = new Matrix;
			matr.createGradientBox(separatorThickness, _height - PlayerToolbar.HEIGHT, 0, 0, 0);
			subtitleViewerSeparator.graphics.beginGradientFill(GradientType.LINEAR,
				[0x444444, 0x333333, 0x333333, 0x222222], // colour
				[1, 1, 1, 1],  // alpha
				[0, 63, 192, 255], // ratio
				matr);
			// subtitleViewerSeparator.graphics.beginFill(0x444444, 1);
			subtitleViewerSeparator.graphics.drawRect(0, PlayerToolbar.HEIGHT, separatorThickness, _height - PlayerToolbar.HEIGHT);
			subtitleViewerSeparator.graphics.endFill();
			subtitleViewerSeparator.graphics.beginFill(0x666666, 1);
			if(left) {
				subtitleViewerSeparator.graphics.moveTo(separatorThickness/2 - 5, _height/2 - 50);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 + 3, _height/2 - 55);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 + 3, _height/2 - 45);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 - 5, _height/2 - 50);
				subtitleViewerSeparator.graphics.moveTo(separatorThickness/2 - 5, _height/2 + 50);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 + 3, _height/2 + 55);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 + 3, _height/2 + 45);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 - 5, _height/2 + 50);
			} else {
				subtitleViewerSeparator.graphics.moveTo(separatorThickness/2 + 5, _height/2 - 50);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 - 3, _height/2 - 55);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 - 3, _height/2 - 45);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 + 5, _height/2 - 50);
				subtitleViewerSeparator.graphics.moveTo(separatorThickness/2 + 5, _height/2 + 50);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 - 3, _height/2 + 55);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 - 3, _height/2 + 45);
				subtitleViewerSeparator.graphics.lineTo(separatorThickness/2 + 5, _height/2 + 50);
			}
			subtitleViewerSeparator.graphics.drawCircle(separatorThickness/2, _height/2 - 37, 3);
			subtitleViewerSeparator.graphics.drawCircle(separatorThickness/2, _height/2 - 25, 3);
			subtitleViewerSeparator.graphics.drawCircle(separatorThickness/2, _height/2 - 12, 3);
			subtitleViewerSeparator.graphics.drawCircle(separatorThickness/2, _height/2, 	  3);
			subtitleViewerSeparator.graphics.drawCircle(separatorThickness/2, _height/2 + 12, 3);
			subtitleViewerSeparator.graphics.drawCircle(separatorThickness/2, _height/2 + 25, 3);
			subtitleViewerSeparator.graphics.drawCircle(separatorThickness/2, _height/2 + 37, 3);
			subtitleViewerSeparator.graphics.endFill();


			// make it blend in with the player toolbar :P
			subtitleViewerSeparator.graphics.lineStyle(NaN);
			var backMatrix:Matrix = new Matrix();
			backMatrix.createGradientBox(separatorThickness, PlayerToolbar.HEIGHT, Math.PI/2, 0, 0);
			subtitleViewerSeparator.graphics.beginGradientFill(GradientType.LINEAR, 
				[0xe1e1e1, 0xc4c4c4], // colour
				[1, 1],  // alpha
				[0, 255], // ratio
				backMatrix);
			subtitleViewerSeparator.graphics.drawRect(0, 0, separatorThickness, PlayerToolbar.HEIGHT);
			subtitleViewerSeparator.graphics.endFill();
			subtitleViewerSeparator.graphics.lineStyle(0, 0x777777);
			subtitleViewerSeparator.graphics.moveTo(separatorThickness/2, 8);
			subtitleViewerSeparator.graphics.lineTo(separatorThickness/2, PlayerToolbar.HEIGHT - 8);
			subtitleViewerSeparator.graphics.lineStyle(0, 0x666666);
			subtitleViewerSeparator.graphics.moveTo(separatorThickness/2-1, 8);
			subtitleViewerSeparator.graphics.lineTo(separatorThickness/2-1, PlayerToolbar.HEIGHT - 8);
			subtitleViewerSeparator.graphics.lineStyle(0, 0x666666);
			subtitleViewerSeparator.graphics.moveTo(separatorThickness/2+1, 8);
			subtitleViewerSeparator.graphics.lineTo(separatorThickness/2+1, PlayerToolbar.HEIGHT - 8);
		}

		public function drawFilmstripSeparator(down:Boolean = true):void {
			filmstripSeparator.graphics.clear();
			filmstripSeparator.graphics.lineStyle(1, 0x555555);
			var matr:Matrix = new Matrix;
			matr.createGradientBox(_width - separatorThickness - subtitleViewerSeparator.x, separatorThickness, Math.PI/2, 0, 0);
			filmstripSeparator.graphics.beginGradientFill(GradientType.LINEAR,
				[0x444444, 0x333333, 0x333333, 0x222222], // colour
				[1, 1, 1, 1],  // alpha
				[0, 63, 192, 255], // ratio
				matr);
			// filmstripSeparator.graphics.beginFill(0x444444, 1);
			filmstripSeparator.graphics.drawRect(0, 0, _width - separatorThickness - subtitleViewerSeparator.x, separatorThickness);
			filmstripSeparator.graphics.endFill();

			filmstripSeparator.graphics.beginFill(0x666666, 1);
			if(!down) {
				filmstripSeparator.graphics.moveTo(_player.width/2 - 50, separatorThickness/2 - 5);
				filmstripSeparator.graphics.lineTo(_player.width/2 - 55, separatorThickness/2 + 3);
				filmstripSeparator.graphics.lineTo(_player.width/2 - 45, separatorThickness/2 + 3);
				filmstripSeparator.graphics.lineTo(_player.width/2 - 50, separatorThickness/2 - 5);
				filmstripSeparator.graphics.moveTo(_player.width/2 + 50, separatorThickness/2 - 5);
				filmstripSeparator.graphics.lineTo(_player.width/2 + 55, separatorThickness/2 + 3);
				filmstripSeparator.graphics.lineTo(_player.width/2 + 45, separatorThickness/2 + 3);
				filmstripSeparator.graphics.lineTo(_player.width/2 + 50, separatorThickness/2 - 5);
			} else {
				filmstripSeparator.graphics.moveTo(_player.width/2 - 50, separatorThickness/2 + 5);
				filmstripSeparator.graphics.lineTo(_player.width/2 - 55, separatorThickness/2 - 3);
				filmstripSeparator.graphics.lineTo(_player.width/2 - 45, separatorThickness/2 - 3);
				filmstripSeparator.graphics.lineTo(_player.width/2 - 50, separatorThickness/2 + 5);
				filmstripSeparator.graphics.moveTo(_player.width/2 + 50, separatorThickness/2 + 5);
				filmstripSeparator.graphics.lineTo(_player.width/2 + 55, separatorThickness/2 - 3);
				filmstripSeparator.graphics.lineTo(_player.width/2 + 45, separatorThickness/2 - 3);
				filmstripSeparator.graphics.lineTo(_player.width/2 + 50, separatorThickness/2 + 5);
			}
			filmstripSeparator.graphics.drawCircle(_player.width/2 - 37, separatorThickness/2, 3);
			filmstripSeparator.graphics.drawCircle(_player.width/2 - 25, separatorThickness/2, 3);
			filmstripSeparator.graphics.drawCircle(_player.width/2 - 12, separatorThickness/2, 3);
			filmstripSeparator.graphics.drawCircle(_player.width/2, separatorThickness/2, 	   3);
			filmstripSeparator.graphics.drawCircle(_player.width/2 + 12, separatorThickness/2, 3);
			filmstripSeparator.graphics.drawCircle(_player.width/2 + 25, separatorThickness/2, 3);
			filmstripSeparator.graphics.drawCircle(_player.width/2 + 37, separatorThickness/2, 3);
			filmstripSeparator.graphics.endFill();
		}
	}
}