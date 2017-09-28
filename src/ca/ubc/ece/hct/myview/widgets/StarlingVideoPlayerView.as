////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.thumbnail.Thumbnail;
import ca.ubc.ece.hct.myview.thumbnail.ThumbnailSegment;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoUtil;
import ca.ubc.ece.hct.myview.widgets.filmstrip.Filmstrip;
import ca.ubc.ece.hct.myview.widgets.filmstrip.MultiFilmstrip;
import ca.ubc.ece.hct.myview.widgets.filmstrip.SimpleFilmstrip;
import ca.ubc.ece.hct.myview.widgets.pixie.Pixie;
import ca.ubc.ece.hct.myview.widgets.pixie.PixieV2;
import ca.ubc.ece.hct.myview.widgets.player.*;
import ca.ubc.ece.hct.myview.widgets.subtitleviewer.StarlingCaptionViewer;
import ca.ubc.ece.hct.myview.widgets.subtitleviewer.SubtitleViewer;

import feathers.controls.Button;
import feathers.controls.Callout;

import feathers.controls.ScrollContainer;

import flash.display.StageDisplayState;

import flash.filesystem.FileStream;
import flash.geom.Rectangle;

import flash.net.SharedObject;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import org.osflash.signals.Signal;

import org.osflash.signals.natives.NativeSignal;
import org.osflash.signals.natives.StarlingNativeSignal;

import starling.core.Starling;

import starling.display.Image;

import starling.display.Quad;

import starling.events.Event;
import starling.events.KeyboardEvent;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.events.TouchPhase;
import starling.textures.Texture;

public class StarlingVideoPlayerView extends StarlingView {

    private var layout_so:SharedObject;
    public static const TOOLBAR_SIZE:uint = 30;

    private var _player:Player;
    private var _playerToolbar:PlayerToolbar;
    private var _filmstrip:MultiFilmstrip;
//    public function get filmstrip():MultiFilmstrip { return _filmstrip; }
    private var _captionViewer:StarlingCaptionViewer;
    private var _toolbar:StarlingPlayerViewToolbar;
    private var _pix:Pixie;

    CONFIG::DEV {
        private var _pix2:PixieV2;
    }

    private var model:StarlingVideoPlayerModel;

    private var centre:WidgetRegion;
    private var left:WidgetRegion;
    private var right:WidgetRegion;
    private var top:WidgetRegion;
    private var bottom:WidgetRegion;
    private var topToolbar:WidgetRegion;
    private var leftToolbar:WidgetRegion;
    private var rightToolbar:WidgetRegion;
    private var bottomToolbar:WidgetRegion;
    private var widgetRegions:Vector.<WidgetRegion>;

    private var savedWidgetDimensions:Array;

    public function StarlingVideoPlayerView() {

        model = new StarlingVideoPlayerModel();

        _player = new Player();
        _filmstrip = new MultiFilmstrip();
        _captionViewer = new StarlingCaptionViewer();

        _toolbar = new StarlingPlayerViewToolbar();
//        _pix = new Pixie(100, 100);
//        CONFIG::DEV {
//            _pix2 = new PixieV2(500, 500);
//        }
//
        model.linkWidget(_player);
        model.linkWidget(_filmstrip);
        model.linkWidget(_captionViewer);
        model.linkWidget(_toolbar);

        model.fullscreenSignal.add(setFullscreen);

//        _pix.width = 100;
//        _pix.height = 100;
//        CONFIG::DEV {
//            _pix2.x = _player.x + 20;
//            _pix2.y = PlayerBar.TOOLBAR_HEIGHT + 10;
//        }
//        CONFIG::DEV {
//            model.linkWidget(_pix2);
//        }
//
//        CONFIG::DEV {
//            addChild(_pix2);
//        }
    }

    override protected function addedToStage(e:Event = null):void {
        super.addedToStage(e);
    }

    override protected function removedFromStage(e:Event = null):void {
        for each(var region:WidgetRegion in widgetRegions) {
            region.removeFromParent(true);
        }

        stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyboardListener);
    }

    override public function dispose():void {

        model.exit();

        super.dispose();

        top.dispose();
        left.dispose();
        right.dispose();
        bottom.dispose();
        centre.dispose();
        topToolbar.dispose();
        leftToolbar.dispose();
        rightToolbar.dispose();
        bottomToolbar.dispose();

        VideoATFManager.unloadVideoATF();

        if(stage) {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyboardListener);
        }
    }

    private function keyboardListener(e:KeyboardEvent):void {
        switch(e.keyCode) {
            case 32: // spacebar
                    model.keyboardPlayPauseToggle();
                break;
            case 37: // right arrow
                    model.keyboardSeek(model.playheadTime - 5);
                break;
            case 39: // left arrow
                    model.keyboardSeek(model.playheadTime + 5);
                break;
        }
    }

    private function layout():void {

        layout_so = SharedObject.getLocal("player_layout_so");

        widgetRegions = new Vector.<WidgetRegion>();
        top = new WidgetRegion();               widgetRegions.push(top);
        left = new WidgetRegion();              widgetRegions.push(left);
        right = new WidgetRegion();             widgetRegions.push(right);
        bottom = new WidgetRegion();            widgetRegions.push(bottom);
        centre = new WidgetRegion();            widgetRegions.push(centre);
        topToolbar = new WidgetRegion();        widgetRegions.push(topToolbar);
        leftToolbar = new WidgetRegion();       widgetRegions.push(leftToolbar);
        rightToolbar = new WidgetRegion();      widgetRegions.push(rightToolbar);
        bottomToolbar = new WidgetRegion();     widgetRegions.push(bottomToolbar);

        top.setResizeable(false, true, true, true);
        left.setResizeable(false, false, false, true);
        right.setResizeable(false, true, false, false);
        bottom.setResizeable(true, true, false, true);
        centre.setResizeable(true, true, true, true);

        topToolbar.setSize(_width, TOOLBAR_SIZE);
        bottomToolbar.setSize(_width, TOOLBAR_SIZE);
        bottomToolbar.y = _height - bottomToolbar.height;
        rightToolbar.setSize(TOOLBAR_SIZE, _height - topToolbar.height - bottomToolbar.height);
        rightToolbar.x = _width - rightToolbar.width;
        rightToolbar.y = topToolbar.height;
        leftToolbar.setSize(TOOLBAR_SIZE, _height - topToolbar.height - bottomToolbar.height);
        leftToolbar.y = topToolbar.height;

        left.x = leftToolbar.width;
        left.y = topToolbar.height;
        left.setSize(_width * 0.2 - TOOLBAR_SIZE, _height - 2 * TOOLBAR_SIZE);
        left.handleSelfResize = false;
        left.setName("LEFT");
        left.rightResizeSignal.add(centreLeftResize);
        left.resizingSignal.add(resizingWidget);

        top.x = left.x + left.width;
        top.y = topToolbar.height;
        top.setSize(_width * 0.6, _height * 0.2 - 2 * TOOLBAR_SIZE);
        top.setName("TOP");
        top.handleSelfResize = false;
        top.bottomResizeSignal.add(centreTopResize);
        top.leftResizeSignal.add(centreLeftResize);
        top.rightResizeSignal.add(centreRightResize);
        top.resizingSignal.add(resizingWidget);

        centre.x = left.x + left.width;
        centre.y = top.y + top.height;
        centre.setSize(_width * 0.6, _height * 0.6);
        centre.setName("CENTRE");
        centre.handleSelfResize = false;
        centre.topResizeSignal.add(centreTopResize);
        centre.leftResizeSignal.add(centreLeftResize);
        centre.rightResizeSignal.add(centreRightResize);
        centre.bottomResizeSignal.add(centreBottomResize);
        centre.resizingSignal.add(resizingWidget);

        bottom.x = left.x + left.width;
        bottom.y = centre.y + centre.height;
        bottom.setSize(_width * 0.6, _height * 0.2 - 2 * TOOLBAR_SIZE);
        bottom.handleSelfResize = false;
        bottom.setName("BOTTOM");
        bottom.topResizeSignal.add(centreBottomResize);
        bottom.leftResizeSignal.add(centreLeftResize);
        bottom.rightResizeSignal.add(centreRightResize);
        bottom.resizingSignal.add(resizingWidget);

        right.x = centre.x + centre.width;
        right.y = topToolbar.height;
        right.setSize(_width * 0.2 - 30, _height - 2 * TOOLBAR_SIZE);
        right.handleSelfResize = false;
        right.setName("RIGHT");
        right.leftResizeSignal.add(centreRightResize);
        right.resizingSignal.add(resizingWidget);


        if(layout_so.data.widgetSaved) {
            left.x = layout_so.data.leftWidget.x;
            left.y = layout_so.data.leftWidget.y;
            left.width = layout_so.data.leftWidget.width;
            left.height = layout_so.data.leftWidget.height;

            right.x = layout_so.data.rightWidget.x;
            right.y = layout_so.data.rightWidget.y;
            right.width = layout_so.data.rightWidget.width;
            right.height = layout_so.data.rightWidget.height;

            top.x = layout_so.data.topWidget.x;
            top.y = layout_so.data.topWidget.y;
            top.width = layout_so.data.topWidget.width;
            top.height = layout_so.data.topWidget.height;

            bottom.x = layout_so.data.bottomWidget.x;
            bottom.y = layout_so.data.bottomWidget.y;
            bottom.width = layout_so.data.bottomWidget.width;
            bottom.height = layout_so.data.bottomWidget.height;

            centre.x = layout_so.data.centreWidget.x;
            centre.y = layout_so.data.centreWidget.y;
            centre.width = layout_so.data.centreWidget.width;
            centre.height = layout_so.data.centreWidget.height;
        }

        addChild(centre);
        addChild(left);
        addChild(right);
        addChild(top);
        addChild(bottom);
        addChild(topToolbar);
        addChild(leftToolbar);
        addChild(rightToolbar);
        addChild(bottomToolbar);
    }

    private function setWidgets():void {
        centre.setWidget(_player);
        bottom.setWidget(_filmstrip);
        left.setWidget(_captionViewer);
        topToolbar.setWidget(_toolbar);
    }

    private function unsetWidgets(exceptions:Array):void {
        for each(var region:WidgetRegion in widgetRegions) {
            region.unsetWidget();
        }
    }

    private function collapseLayout():void {

        var padding:Number = WidgetRegion.PADDING * 2;
        var toolbarPadding:Number = 2;
        if(topToolbar.isEmpty) {
            topToolbar.setSize(_width, 0);
        }

        if(bottomToolbar.isEmpty) {
            bottomToolbar.setSize(_width, 0);
            bottomToolbar.y = _height - bottomToolbar.height;
        }

        if(leftToolbar.isEmpty) {
            leftToolbar.setSize(0, _height - topToolbar.height - bottomToolbar.height);
        }
        leftToolbar.y = topToolbar.height;

        if(rightToolbar.isEmpty) {
            rightToolbar.setSize(0, _height - leftToolbar.height);
        }
        rightToolbar.x = _width - rightToolbar.width;
        rightToolbar.y = topToolbar.height;

        if(left.isEmpty) {
            left.setSize(0, leftToolbar.height);
            left.setResizeable(false, false, false, false);
            centre.setResizeable(centre.topResizable, false, centre.bottomResizable, centre.rightResizable);
            bottom.setResizeable(bottom.topResizable, false, bottom.bottomResizable, bottom.rightResizable);
        } else {
            left.setResizeable(false, false, false, true);
            left.setSize(left.width, _height - topToolbar.height - bottomToolbar.height);
        }
        left.x = leftToolbar.width;
        left.y = topToolbar.height;

        if(right.isEmpty) {
            right.setSize(0, leftToolbar.height);
            right.setResizeable(false, false, false, false);
            centre.setResizeable(centre.topResizable, centre.leftResizable, centre.bottomResizable, false);
            bottom.setResizeable(bottom.topResizable, bottom.leftResizable, bottom.bottomResizable, false);
        } else {
            right.setResizeable(false, true, false, false);
            right.setSize(right.width, _height - topToolbar.height - bottomToolbar.height);
        }
        right.x = rightToolbar.x - right.width;
        right.y = topToolbar.height;

        if(top.isEmpty) {
            top.setSize(right.x - (left.x + left.width), 0);
            top.setResizeable(false, false, false, false);
            centre.setResizeable(false, centre.leftResizable, centre.bottomResizable, centre.rightResizable);
        } else {
            top.setResizeable(false, left.rightResizable, true, right.leftResizable);
            top.setSize(right.x - (left.x + left.width), top.height);
        }
        top.x = left.x + left.width;
        top.y = topToolbar.height;

        if(bottom.isEmpty) {
            bottom.setSize(right.x - (left.x + left.width), 0);
            bottom.setResizeable(false, false, false, false);
            centre.setResizeable(centre.topResizable, centre.leftResizable, false, centre.rightResizable);
        } else {
            bottom.setResizeable(true, left.rightResizable, false, right.leftResizable);
            bottom.setSize(right.x - (left.x + left.width), bottom.height);
        }
        bottom.x = left.x + left.width;
        bottom.y = bottomToolbar.y - bottom.height;

        centre.setResizeable(top.bottomResizable, left.rightResizable, bottom.topResizable, right.leftResizable);
        centre.setSize(right.x - (left.x + left.width), bottom.y - (top.y + top.height));
        centre.x = left.x + left.width;
        centre.y = top.y + top.height;

//        trace(top.y + " " + top.height);
//        trace(bottom.y + " " + bottomToolbar.y + " " + bottom.height + " " + _height);

    }

    public function loadVideo(video:VideoMetadata):void {
        VideoATFManager.loadAsyncVideoATF(video).add(
                function widgetsLoadVideo():void {
                    model.loadVideo(video);

                    layout();
                    setWidgets();
                    collapseLayout();

                    for each(var widgetRegion:WidgetRegion in widgetRegions) {
                        widgetRegion.renderWidget();
                    }

                    _filmstrip.showImages();

                    // simplification () ? true : false = !!() ==>
                    // _toolbar.hideButtonIsSelected = (model.highlightReadMode & UserDataViewMode.HIDE) ? true : false;
                    _toolbar.hideButtonIsSelected = !!(model.highlightReadMode & UserDataViewMode.HIDE);
                    _toolbar.personalButtonIsSelected = !!(model.highlightReadMode & UserDataViewMode.PERSONAL);
                    _toolbar.classButtonIsSelected = !!(model.highlightReadMode & UserDataViewMode.CLASS);

                    stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardListener);
                }
        )
    }

    private function centreTopResize(diff:Number):void {
        if(centre.height - diff > 50 && top.height + diff > 50) {
            top.setSize(top.width, top.height + diff);
            centre.y = centre.y + diff;
            centre.setSize(centre.width, centre.height - diff);
        }
        updateModelRegionDimensions();
    }
    private function centreLeftResize(diff:Number):void {
        if(centre.width - diff > 50 && left.width + diff> 50) {
            top.x = top.x + diff;
            top.setSize(top.width - diff, top.height);
            bottom.x = bottom.x + diff;
            bottom.setSize(bottom.width - diff, bottom.height);
            left.setSize(left.width + diff, left.height);
            centre.x = centre.x + diff;
            centre.setSize(centre.width - diff, centre.height);
        }
        updateModelRegionDimensions();
    }
    private function centreRightResize(diff:Number):void {
        if(centre.width + diff > 50 && right.width - diff > 50) {
            top.setSize(top.width + diff, top.height);
            bottom.setSize(bottom.width + diff, bottom.height);
            right.x = right.x + diff;
            right.setSize(right.width - diff, right.height);
            centre.setSize(centre.width + diff, centre.height);
        }
        updateModelRegionDimensions();
    }
    private function centreBottomResize(diff:Number):void {
        if(centre.height + diff > 50 && bottom.height - diff > 50) {
            bottom.y = bottom.y + diff;
            bottom.setSize(bottom.width, bottom.height - diff);
            centre.setSize(centre.width, centre.height + diff);
        }
        updateModelRegionDimensions();
    }

    private function updateModelRegionDimensions():void {
        model.topDimensions = new flash.geom.Rectangle(top.x, top.y, top.width, top.height);
        model.rightDimensions = new flash.geom.Rectangle(right.x, right.y, right.width, right.height);
        model.leftDimensions = new flash.geom.Rectangle(left.x, left.y, left.width, left.height);
        model.bottomDimensions = new flash.geom.Rectangle(bottom.x, bottom.y, bottom.width, bottom.height);
        model.centreDimensions = new flash.geom.Rectangle(centre.x, centre.y, centre.width, centre.height);

        layout_so.data.topWidget = model.topDimensions;
        layout_so.data.leftWidget = model.leftDimensions;
        layout_so.data.rightWidget = model.rightDimensions;
        layout_so.data.bottomWidget = model.bottomDimensions;
        layout_so.data.centreWidget = model.centreDimensions;
    }

    private function resizingWidget(bool:Boolean):void {
        model.resizing = bool;
    }

    private function setFullscreen(fullscreen:Boolean):void {

        var i:int = 0;

        if(fullscreen) {

            savedWidgetDimensions = [];
            for(i = 0; i<widgetRegions.length; i++) {
                savedWidgetDimensions.push(new Rectangle(widgetRegions[i].x,
                        widgetRegions[i].y,
                        widgetRegions[i].width,
                        widgetRegions[i].height));
            }

            top.unsetWidget();
            left.unsetWidget();
            right.unsetWidget();
            bottom.unsetWidget();
            topToolbar.unsetWidget();
            leftToolbar.unsetWidget();
            rightToolbar.unsetWidget();
            bottomToolbar.unsetWidget();

            collapseLayout();

            Starling.current.nativeStage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
        } else {

            bottom.setWidget(_filmstrip);
            left.setWidget(_captionViewer);
            topToolbar.setWidget(_toolbar);

            collapseLayout();

            for(i = 0; i<widgetRegions.length; i++) {
                widgetRegions[i].x = savedWidgetDimensions[i].x;
                widgetRegions[i].y = savedWidgetDimensions[i].y;
                widgetRegions[i].setSize(savedWidgetDimensions[i].width, savedWidgetDimensions[i].height);
                widgetRegions[i].renderWidget();

            }

            Starling.current.nativeStage.displayState = StageDisplayState.NORMAL;

        }

        updateModelRegionDimensions();

    }
//    public function removedFromStage(e:Event = null):void {
//        model.stop(null);
//        _player.stop();
//    }
//
//    protected function subtitleViewerSeparatorMouseDown(e:MouseEvent):void {
//        _filmstrip.setResizingStatus(true);
//        clickStart = new Date();
//        mouseDownPoint = new Point(mouseX, mouseY);
//        temporaryPoint = new Point(subtitleViewerSeparator.x, subtitleViewerSeparator.y);
//
//        addEventListener(MouseEvent.MOUSE_MOVE, resizeSubtitleViewerSeparator);
//        _player.allowAnimation = false;
//        addEventListener(MouseEvent.MOUSE_UP, subtitleViewerSeparatorMouseUp);
//    }
//
//    protected function subtitleViewerSeparatorMouseUp(e:MouseEvent):void {
//        //actionLogSignal.dispatch("Resized SubtitleViewer to " + this.mouseX);
//        if(new Date().time - clickStart.time < clickTimerThreshold) {
//            if(subtitleViewerSeparator.x != 0) {
//                subtitleViewerWidth = mouseX;
//                // new Tween(this, "subtitleViewerSeparatorX", Strong.easeInOut, mouseDownPoint.x, 0, 0.5, true);
//                hideSubtitleViewer(mouseX);
//                drawSubtitleViewerSeparator(false);
//            } else {
//                // new Tween(this, "subtitleViewerSeparatorX", Strong.easeInOut, 0, subtitleViewerWidth, 0.5, true);
//                showSubtitleViewer();
//                drawSubtitleViewerSeparator(true);
//            }
//        }
//        _player.allowAnimation = true;
//        _filmstrip.setResizingStatus(false);
//        removeEventListener(MouseEvent.MOUSE_MOVE, resizeSubtitleViewerSeparator);
//        removeEventListener(MouseEvent.MOUSE_UP, subtitleViewerSeparatorMouseUp);
//    }
//
//    protected function resizeSubtitleViewerSeparator(e:MouseEvent):void {
//        var change:Number = temporaryPoint.x - (mouseDownPoint.x - mouseX);
//        subtitleViewerSeparatorX = change;
//
//    }
//
//    public function hideSubtitleViewer(showPosition:Number):void {
//
//        /*subtitleViewerWidth = showPosition;
//
//         subtitleShowHideTween = new Tween(this, "subtitleViewerShowHide", Strong.easeInOut, subtitleViewer.width, 0, 0.5, true);
//         filmstrip.setResizingStatus(true);
//         subtitleShowHideTween.addEventListener(TweenEvent.MOTION_FINISH,
//         function subtitleShowHideTweenFinish(e:Event):void {
//         filmstrip.setResizingStatus(false);
//         subtitleShowHideTween.removeEventListener(TweenEvent.MOTION_FINISH, subtitleShowHideTweenFinish);
//         });*/
//        // new Tween(this, "subtitleViewerShowHide", Strong.easeInOut, sideTabController.width, 0, 0.5, true);
//    }
//
//    public function showSubtitleViewer():void {
//
//        /*	subtitleShowHideTween = new Tween(this, "subtitleViewerShowHide", Strong.easeInOut, 0, subtitleViewer.width, 0.5, true);
//         filmstrip.setResizingStatus(true);
//         subtitleShowHideTween.addEventListener(TweenEvent.MOTION_FINISH,
//         function subtitleShowHideTweenFinish(e:Event):void {
//         filmstrip.setResizingStatus(false);
//         subtitleShowHideTween.removeEventListener(TweenEvent.MOTION_FINISH, subtitleShowHideTweenFinish);
//         });*/
//        // new Tween(this, "subtitleViewerShowHide", Strong.easeInOut, 0, sideTabController.width, 0.5, true);
//    }
//
//    public function set subtitleViewerShowHide(val:Number):void {
//
//        //_captionViewer.x = val - _captionViewer.width;
//        //// sideTabController.x = val - sideTabController.width;
//
//        //subtitleViewerSeparator.x = _captionViewer.x + subtitleViewer.width;
//        //// subtitleViewerSeparator.x = sideTabController.x + sideTabController.width;
//        //filmstripSeparator.x = val;
//        //drawFilmstripSeparator();
//
//
//        //filmstrip.width = _width - val - separatorThickness;
//        //filmstrip.x = val + separatorThickness;
//
//
//        //_player.width = _width - val - separatorThickness;
//        //_player.x = val + separatorThickness;
//    }


    public function setSize(width:Number, height:Number):void {
        _width = width;
        _height = height;

        if(topToolbar) {
            topToolbar.setSize(_width, topToolbar.height);
        }
        if(bottomToolbar) {
            bottomToolbar.setSize(_width, bottomToolbar.height);
            bottomToolbar.y = _height - bottomToolbar.height;
        }
        if(rightToolbar) {
            rightToolbar.setSize(rightToolbar.width, _height - topToolbar.height - bottomToolbar.height);
            rightToolbar.x = _width - rightToolbar.width;
        }
        if(leftToolbar) {
            leftToolbar.setSize(leftToolbar.width, _height - topToolbar.height - bottomToolbar.height);
        }

        if(left) {
            left.setSize(left.width, _height - topToolbar.height - bottomToolbar.height);
        }
        if(right) {
            right.x = _width - rightToolbar.width - right.width;
            right.setSize(right.width, _height - topToolbar.height - bottomToolbar.height);
        }
        if(top) {
            top.setSize(right.x - (left.x + left.width), top.height);
        }
        if(bottom) {
            bottom.y = _height - bottomToolbar.height - bottom.height;
            bottom.setSize(right.x - (left.x + left.width), bottom.height);
        }
        if(centre) {
            centre.setSize(right.x - (left.x + left.width), bottom.y - (top.y + top.height));
        }


        if(centre && top && bottom && left && right)
            updateModelRegionDimensions();
//
//        _captionViewer.height = _height;
//        _player.width = _width - _captionViewer.width - separatorThickness
//        _player.height = _height - PlayerToolbar.HEIGHT - _filmstrip.height - separatorThickness;
//        _filmstrip.width = _width - _captionViewer.width - separatorThickness;
//        _filmstrip.y = _player.y + _player.height + separatorThickness;
//        _playerToolbar.setSize(_player.width, PlayerToolbar.HEIGHT);
//        filmstripSeparator.y = _player.y + _player.height;
//
//        _pix.x = _player.x;
//        _pix.y = _player.y + _player.height - _pix.height - PlayerBar.TOOLBAR_HEIGHT;
//
//        drawFilmstripSeparator();
//        drawSubtitleViewerSeparator();
//
//
    }
}
}