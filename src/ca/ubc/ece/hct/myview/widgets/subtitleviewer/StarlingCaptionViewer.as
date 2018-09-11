/**
 * Created by iDunno on 2017-07-24.
 */
package ca.ubc.ece.hct.myview.widgets.subtitleviewer {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.Colours;
import ca.ubc.ece.hct.myview.AnnotationCallout;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.StarlingWidget;
import ca.ubc.ece.hct.myview.widgets.Widget;

import feathers.controls.Callout;

import flash.display.BitmapData;
import flash.display.StageQuality;
import flash.geom.Point;
import flash.geom.Rectangle;

import starling.core.Starling;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchProcessor;
import starling.textures.Texture;

public class StarlingCaptionViewer extends StarlingWidget {

    public var nativeSubtitleViewer:SubtitleViewer;
    private var bmpD:BitmapData;
    private var cacheView:Image;
    private var background:Quad;
    private var mouseLocation:Sprite;
    private var touch:Touch;
    private var highlightCallout:Callout;
    private var _captionViewer:StarlingCaptionViewer;

    public function StarlingCaptionViewer() {
        super();

        _captionViewer = this;
        nativeSubtitleViewer = new SubtitleViewer();
        background = new Quad(1, 1, 0xff0000);
        background.alpha = 1;

        nativeSubtitleViewer.deselected.add(
                function nativeDeselected(w:Widget):void {
                    deselected.dispatch(_captionViewer);
                });
        nativeSubtitleViewer.selected.add(
                function nativeSelected(w:Widget, r:Range):void {
                    showHighlightCallout(r);
                    selected.dispatch(_captionViewer, r);
                });
        nativeSubtitleViewer.selecting.add(
                function nativeSelecting(w:Widget, r:Range):void {
                    selecting.dispatch(_captionViewer, r);
                });
        nativeSubtitleViewer.seeked.add(
                function nativeSeeked(w:Widget, t:Number):void {
                    seeked.dispatch(_captionViewer, t);
                });

//        deselected = nativeSubtitleViewer.deselected;
//        selected = nativeSubtitleViewer.selected;
//        selecting = nativeSubtitleViewer.selecting;
//        seeked = nativeSubtitleViewer.seeked;

//        selected.add(function nativeSelected(source:Widget, range:Range):void { showHighlightCallout(range); });
        mouseLocation = new Sprite();

    }

    override protected function addedToStage(e:Event = null):void {

        super.addedToStage(e);
        addChild(background);

        Starling.current.nativeOverlay.addChild(nativeSubtitleViewer);
        moveNativeWidget();
        StarlingWidget.mixedWidgets.push(this);

        addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);

        addChild(mouseLocation);
        addEventListener(TouchEvent.TOUCH, touched);
    }

    override protected function removedFromStage(e:Event = null):void {
        super.removedFromStage(e);
        StarlingWidget.mixedWidgets.removeAt(StarlingWidget.mixedWidgets.indexOf(this));
        if(Starling.current.nativeOverlay.contains(nativeSubtitleViewer)) {
            Starling.current.nativeOverlay.removeChild(nativeSubtitleViewer);
        }
    }

    override public function dispose():void {
        if(nativeSubtitleViewer) {
            nativeSubtitleViewer.dispose();
        }
        nativeSubtitleViewer = null;
    }

    private function touched(e:TouchEvent):void {
        touch = e.getTouch(this);
        if(touch) {
            var zero:Point = localToGlobal(new Point(0, 0));
            mouseLocation.x = touch.globalX - zero.x;
            mouseLocation.y = touch.globalY - zero.y;
        }
    }

    override public function loadVideo(video:VideoMetadata):void {
        nativeSubtitleViewer.loadVideo(video);
    }

    override public function searchText(string:String):void {
        nativeSubtitleViewer.searchText(string);
    }

    override public function move(x:Number, y:Number):void {
        super.move(x, y);
        moveNativeWidget()
    }

    private function moveNativeWidget():void {
        var zero:Point = localToGlobal(new Point(0, 0));
        nativeSubtitleViewer.move(zero.x, zero.y);
    }

    override public function setSize(width:Number, height:Number):void {
        _width = width;
        _height = height;
        nativeSubtitleViewer.setSize(_width, _height);

        background.readjustSize(_width, _height);
        if(cacheView) {
            cacheView.readjustSize(_width, _height);
        }
    }

    override public function select(range:Range):void {
        nativeSubtitleViewer.select(range);
    }

    override public function deselect():void {
        nativeSubtitleViewer.deselect();
    }

    override public function set playheadTime(val:Number):void {
        nativeSubtitleViewer.playheadTime = val;

        if(!Starling.current.nativeOverlay.contains(nativeSubtitleViewer)) {
            drawCacheView();
        }
    }

    override public function updateHighlights():void {
        nativeSubtitleViewer.updateHighlights();
        drawCacheView();
    }

    override public function setHighlightReadMode(mode:uint):void {
        nativeSubtitleViewer.setHighlightReadMode(mode);
    }

    private function showHighlightCallout(selectionRange:Range):void {

        TouchProcessor.PROCESS_TARGETS_WHILE_MOVING = false;

        highlightCallout = AnnotationCallout.showCallout(
                mouseLocation,
                Colours.colours,
                nativeSubtitleViewer.svm.video.userData.getHighlightedColoursforTimeRange(selectionRange),
                this);

        (AnnotationCallout)(highlightCallout.content).highlightSignal.add(
                function highlightme(colour:uint, mode:String):void {
                    if(mode == AnnotationCallout.ADD_HIGHLIGHT_MODE) {
                        highlighted.dispatch(AnnotationCallout.caller, colour, selectionRange);
                        highlightCallout.close(true);
                    } else if(mode == AnnotationCallout.DEL_HIGHLIGHT_MODE) {
                        unhighlighted.dispatch(AnnotationCallout.caller, colour, selectionRange);
                    }
                    drawCacheView();
                }
        );

        (AnnotationCallout)(highlightCallout.content).keywordTagSignal.add(
                function tagme(colour:uint, mode:String):void {
                    if(mode == AnnotationCallout.ADD_HIGHLIGHT_MODE) {
                        highlighted.dispatch(AnnotationCallout.caller, colour, selectionRange);
                        highlightCallout.close(true);
                    } else if(mode == AnnotationCallout.DEL_HIGHLIGHT_MODE) {
                        unhighlighted.dispatch(AnnotationCallout.caller, colour, selectionRange);
                    }
                    drawCacheView();
                }
        );

        highlightCallout.addEventListener(Event.CLOSE,
            function calloutClosed(e:Event):void {
                nativeSubtitleViewer.deselect();
                deselected.dispatch(AnnotationCallout.caller);
                highlightCallout.removeEventListener(Event.CLOSE, calloutClosed);
            }
        );

    }

    override public function swapStarlingNative():void {
        if(Starling.current.nativeOverlay.contains(nativeSubtitleViewer)) {

            drawCacheView();
            addChild(cacheView);

            Starling.current.nativeOverlay.removeChild(nativeSubtitleViewer);

        } else {
            bmpD.dispose();
            bmpD = null;
            removeChild(cacheView);
            cacheView.texture.dispose();
            cacheView.dispose();

            Starling.current.nativeOverlay.addChild(nativeSubtitleViewer);
        }


    }

    private function drawCacheView():void {
        if(nativeSubtitleViewer.viewChanged) {

            bmpD = new BitmapData(nativeSubtitleViewer.width, nativeSubtitleViewer.height);
            bmpD.draw(nativeSubtitleViewer);

            if (cacheView) {
                cacheView.texture.dispose();
                cacheView.texture = Texture.fromBitmapData(bmpD);
            } else {
                cacheView = new Image(Texture.fromBitmapData(bmpD));
                cacheView.readjustSize(_width, _height);
//                cacheView.width + cacheView.width + 1;
//                cacheView.height + cacheView.width + 1;
                cacheView.pixelSnapping = true;
            }
            nativeSubtitleViewer.viewChanged = false;
        }

    }

}
}
