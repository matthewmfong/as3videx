/**
 * Created by matth on 2017-07-09.
 */
package ca.ubc.ece.hct.myview {

import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.events.NativeWindowBoundsEvent;
import flash.net.SharedObject;

import starling.core.Starling;

public class Videx extends Sprite {

    private var _starling:Starling;

    private var application_preferences_so:SharedObject;


//    [SWF(width="1280", height="720", frameRate="30", backgroundColor="#FFFFFF")]

    public function Videx() {

        addEventListener(Event.ADDED_TO_STAGE, addedToStage);

    }

    private function addedToStage(e:Event):void {


        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        application_preferences_so = SharedObject.getLocal("app_preferences");

        if(application_preferences_so.data.windowDimensions) {
            stage.nativeWindow.width = application_preferences_so.data.windowDimensions.width;
            stage.nativeWindow.height = application_preferences_so.data.windowDimensions.height;
            stage.nativeWindow.x = 0;//application_preferences_so.data.windowDimensions.x;
            stage.nativeWindow.y = 0;//application_preferences_so.data.windowDimensions.y;
        } else {
            application_preferences_so.data.windowDimensions = new Rectangle(
                    stage.nativeWindow.x, stage.nativeWindow.y, stage.nativeWindow.width, stage.nativeWindow.height);
        }

//        stage.nativeWindow.title = "ViDeX";

        _starling = new Starling(VidexStarling, stage);
//        _starling.showStats = true;
//        _starling.skipUnchangedFrames = true;
//        _starling.antiAliasing = 1;
        _starling.start();

        stage.frameRate = 30;

        stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, resizeListener);
        stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.MOVE, resizeListener);
    }


    public function resizeListener(e:NativeWindowBoundsEvent):void {
        application_preferences_so.data.windowDimensions = new Rectangle(
                stage.nativeWindow.x, stage.nativeWindow.y, stage.nativeWindow.width, stage.nativeWindow.height);
    }

}
}
