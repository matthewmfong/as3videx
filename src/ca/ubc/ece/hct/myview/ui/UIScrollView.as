////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {
	
	import fl.core.UIComponent;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import fl.managers.IFocusManagerComponent;
	import fl.transitions.Tween;
	import fl.transitions.easing.*
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	public class UIScrollView extends UIComponent implements IFocusManagerComponent {

		public static const scrollerWidth:Number = 10;

		private var _source:DisplayObject;

		private var _sourceWidth:Number;
		private var _sourceHeight:Number;

		private var _scroller:Sprite;
		private var _container:Sprite;
		private var _searchHighlight:Sprite;
		private var _containerMask:Sprite;
		private var _widthX:Number, _heightX:Number;

		private var _mouseDownPoint:Point;
		private var _scrollerOriginalPoint:Point;
		private var _scrollerTween:Tween;
		private var _scrollerTweenTimer:Timer;

		private var bgColor:uint = 0xffffff;
		private var bgAlpha:Number = 1;

		public function UIScrollView(width:Number, height:Number) {
			super();
			_widthX = width;
			_heightX = height;
			_container = new Sprite();
			_container.graphics.beginFill(0xffffff);
			_container.graphics.drawRect(0, 0, _widthX, _heightX);
			_container.graphics.endFill();
			addChild(_container);

			_containerMask = new Sprite();
			_containerMask.graphics.beginFill(0, 0);
			_containerMask.graphics.drawRect(0, 0, _widthX, _heightX);
			_containerMask.graphics.endFill();
			_container.mask = _containerMask;
			addChild(_containerMask)

			_searchHighlight = new Sprite();
			_searchHighlight.x = width - scrollerWidth;
			addChild(_searchHighlight);

			_scroller = new Sprite();
			_scroller.x = width - scrollerWidth;
			_scrollerTweenTimer = new Timer(3000, 1);
			_scrollerTweenTimer.addEventListener(TimerEvent.TIMER, timerHideScroller);
			_scrollerTweenTimer.start();
			addChild(_scroller);

			addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
			_scroller.addEventListener(MouseEvent.MOUSE_DOWN, scrollerMouseDown);
		}

		private function showScroller():void {
			_scrollerTween = new Tween(_scroller, "alpha", Strong.easeInOut, _scroller.alpha, 1, 0.25, true);
		}

		private function hideScroller():void {
			_scrollerTween = new Tween(_scroller, "alpha", Strong.easeInOut, _scroller.alpha, 0, 0.25, true);
		}

		private function timerHideScroller(e:TimerEvent):void {
			hideScroller();
		}

		private function mouseWheel(e:MouseEvent):void {
			_source.y += e.delta*5;
			_source.y = Math.max(_heightX - _sourceHeight, _source.y);
			_source.y = Math.min(0, _source.y);

			var containerLocation:Number = -_source.y;
			_scroller.y = containerLocation/_sourceHeight * height;
		}

		private function scrollerMouseDown(e:MouseEvent):void {
			_mouseDownPoint = new Point(mouseX, mouseY);
			_scrollerOriginalPoint = new Point(_scroller.x, _scroller.y);
			focusManager.form.addEventListener(MouseEvent.MOUSE_MOVE, scrollerMouseMove);
			focusManager.form.addEventListener(MouseEvent.MOUSE_UP, scrollerMouseUp);
		}

		private function scrollerMouseMove(e:MouseEvent):void {
			e.stopImmediatePropagation();
			var change:Number = _scrollerOriginalPoint.y - (_mouseDownPoint.y - mouseY);
			_scroller.y = change;
			_scroller.y = Math.max(0, _scroller.y);
			_scroller.y = Math.min(height - _scroller.height, _scroller.y);

			_source.y = -_scroller.y/height * _sourceHeight;
		}

		private function scrollerMouseUp(e:MouseEvent):void {
			focusManager.form.removeEventListener(MouseEvent.MOUSE_MOVE, scrollerMouseMove);
			focusManager.form.removeEventListener(MouseEvent.MOUSE_UP, scrollerMouseUp);
		}

		private function rollOver(e:MouseEvent = null):void {
			_scrollerTweenTimer.stop();
			showScroller();
		}

		private function rollOut(e:MouseEvent = null):void {
			_scrollerTweenTimer.start();
		}

		public function searchHighlight(y_:Number, height_:Number):void {
			_searchHighlight.graphics.lineStyle(1, 0xccaa00);
			_searchHighlight.graphics.beginFill(0xffdd00, 1);
			_searchHighlight.graphics.drawRect(0, y_/_sourceHeight * height, scrollerWidth, height_/_sourceHeight * height);
			_searchHighlight.graphics.endFill();
		}

		public function searchHighlights(rects:Vector.<Rectangle>):void {
			if(rects.length > 0) {

				_searchHighlight.graphics.lineStyle(1, 0xccaa00);
				_searchHighlight.graphics.beginFill(0xffdd00, 1);

				var sourceHeightTimesHeight:Number = Math.min(1, height/_sourceHeight);
				var height_:uint = Math.min(rects[0].height, rects[0].height * sourceHeightTimesHeight);

				for(var i:int = 0; i<rects.length; i++) {
					var y_:uint = rects[i].y * sourceHeightTimesHeight;
					_searchHighlight.graphics.drawRect(0, y_, scrollerWidth, height_);
				}
				_searchHighlight.graphics.endFill();
			}
		}

		public function searchUnhighlight():void {
			_searchHighlight.graphics.clear();
		}

		public function set source(val:DisplayObject):void {
			_source = val;
			_container.addChild(_source);
			_sourceWidth = _source.width;
			_sourceHeight = _source.height;
			drawScroller();
			_scroller.y = 0;
		}

		public function get source():DisplayObject {
			return _source;
		}

		private function drawScroller():void {
			_scroller.graphics.clear();
			if(_sourceHeight != height) {
				var scrollerHeight:Number = Math.max(100, Math.min(height, height/_sourceHeight * height));

				_scroller.graphics.beginFill(0x444444, 0.7);
				_scroller.graphics.drawRoundRect(2, 0, scrollerWidth-4, scrollerHeight, 10);
				_scroller.graphics.endFill();
			}
		}

		public function setBackgroundColor(colour:uint, alpha:Number):void {
			bgColor = colour;
			bgAlpha = alpha;
			if(_container != null) {
				_container.graphics.clear();
				_container.graphics.beginFill(bgColor, bgAlpha);
				_container.graphics.drawRect(0, 0, width, height);
				_container.graphics.endFill();
			}
		}

		override public function setSize(width:Number, height:Number):void {
			super.setSize(width, height);

			_widthX = width;
			_heightX = height;

			if(_container != null) {
				_container.graphics.clear();
				_container.graphics.beginFill(bgColor, bgAlpha);
//				_container.graphics.lineStyle(2, 0xff0000);
//				_container.graphics.beginFill(0xff00ff, 1);
				_container.graphics.drawRect(0, 0, _widthX, _heightX);
				_container.graphics.endFill();
			}

			if(_containerMask != null) {
				_containerMask.graphics.clear();
				_containerMask.graphics.beginFill(0, 0);
				_containerMask.graphics.drawRect(0, 0, _widthX, _heightX);
				_containerMask.graphics.endFill();
			}

			if(_container != null) {
				_container.mask = _containerMask;
			}

			if(_scroller != null && _source != null) {
				_scroller.graphics.clear();
				_scroller.x = _widthX - scrollerWidth;
				var containerLocation:Number = -_source.y;
				_scroller.y = containerLocation/_sourceHeight * _heightX;

				_searchHighlight.x = _widthX - scrollerWidth;
				drawScroller();
			}

		}

		public function update():void {
			_scroller.graphics.clear();
			_scroller.x = width - scrollerWidth;

			_sourceWidth = _source.width;
			_sourceHeight = _source.height;
			
			drawScroller();
		}

		override public function get width():Number { return _widthX; }
		override public function get height():Number { return _heightX; }

	}
}