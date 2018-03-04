/**
 * Created by matth on 2017-07-09.
 */

import ca.ubc.ece.hct.myview.Constants;
import ca.ubc.ece.hct.myview.VidexStarling;

import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.NativeWindowBoundsEvent;
import flash.geom.Rectangle;
import flash.net.SharedObject;

import mx.core.FlexGlobals;

import starling.core.Starling;

public static var stage:Stage = null;

private var _starling:Starling;

private var application_preferences_so:SharedObject;

public function onCreationComplete():void {
    if (stage) {
        _init();
    } else {
        addEventListener(Event.ADDED_TO_STAGE, _init);
    }


}

private function _init(e:Event = null):void {

    FlexGlobals.topLevelApplication.stage.scaleMode = StageScaleMode.NO_SCALE;
    FlexGlobals.topLevelApplication.stage.align = StageAlign.TOP_LEFT;

    application_preferences_so = SharedObject.getLocal("app_preferences");

    if(application_preferences_so.data.windowDimensions) {
        FlexGlobals.topLevelApplication.stage.nativeWindow.width = application_preferences_so.data.windowDimensions.width;
        FlexGlobals.topLevelApplication.stage.nativeWindow.height = application_preferences_so.data.windowDimensions.height;
//        FlexGlobals.topLevelApplication.stage.nativeWindow.x = application_preferences_so.data.windowDimensions.x;
//        FlexGlobals.topLevelApplication.stage.nativeWindow.y = application_preferences_so.data.windowDimensions.y;
    } else {
        application_preferences_so.data.windowDimensions = new Rectangle(
                FlexGlobals.topLevelApplication.stage.nativeWindow.x,
                FlexGlobals.topLevelApplication.stage.nativeWindow.y,
                FlexGlobals.topLevelApplication.stage.nativeWindow.width,
                FlexGlobals.topLevelApplication.stage.nativeWindow.height);
    }

    FlexGlobals.topLevelApplication.stage.nativeWindow.title = "ViDeX";

    _starling = new Starling(VidexStarling, FlexGlobals.topLevelApplication.stage);
    VidexStarling.flexLayer = this;
//        _starling.showStats = true;
//        _starling.skipUnchangedFrames = true;
//        _starling.antiAliasing = 1;
    _starling.start();

    FlexGlobals.topLevelApplication.stage.frameRate = 30;

    FlexGlobals.topLevelApplication.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, resizeListener);
    FlexGlobals.topLevelApplication.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.MOVE, resizeListener);
}


public function resizeListener(e:NativeWindowBoundsEvent):void {
    application_preferences_so.data.windowDimensions = new Rectangle(
            FlexGlobals.topLevelApplication.stage.nativeWindow.x,
            FlexGlobals.topLevelApplication.stage.nativeWindow.y,
            FlexGlobals.topLevelApplication.stage.nativeWindow.width,
            FlexGlobals.topLevelApplication.stage.nativeWindow.height);
}


