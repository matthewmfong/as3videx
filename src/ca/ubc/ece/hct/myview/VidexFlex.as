/**
 * Created by matth on 2017-07-09.
 */

import air.update.events.StatusUpdateEvent;
import air.update.events.UpdateEvent;

import ca.ubc.ece.hct.myview.Constants;
import ca.ubc.ece.hct.myview.VidexStarling;

import com.riaspace.nativeApplicationUpdater.NativeApplicationUpdater;

import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.NativeWindowBoundsEvent;
import flash.geom.Rectangle;
import flash.net.SharedObject;
import flash.system.Capabilities;

import mx.controls.ProgressBar;

import mx.core.FlexGlobals;

import spark.components.Button;

import spark.components.Label;

import starling.core.Starling;

public static var stage:Stage = null;

private var _starling:Starling;

private var application_preferences_so:SharedObject;
private var nativeApplicationUpdater:com.riaspace.nativeApplicationUpdater.NativeApplicationUpdater;

public function onCreationComplete():void {

    var installerType:String = "";
    if(Capabilities.os.indexOf("Mac") >= 0) {
        installerType = "dmg";
    } else if(Capabilities.os.indexOf("Windows") >= 0) {
        installerType = "exe";
    }

    nativeApplicationUpdater = new NativeApplicationUpdater();
    nativeApplicationUpdater.updateURL =
            "http://" + Constants.DOMAIN + "/tlef/version/update.php?" +
            "course_string=" + COURSE::Name + "&" +
            "installer_type=" + installerType + "&" +
            "instructor=" + (CONFIG::Instructor == true ? 1 : 0);
    trace("Checking update: " + nativeApplicationUpdater.updateURL);
    nativeApplicationUpdater.addEventListener(UpdateEvent.INITIALIZED, update);
    nativeApplicationUpdater.initialize();
}

public function update(e:UpdateEvent):void {

    nativeApplicationUpdater.addEventListener(StatusUpdateEvent.UPDATE_STATUS, updateStatus);
    nativeApplicationUpdater.checkNow();
}

public function updateStatus(e:StatusUpdateEvent):void {

    if(!e.available) {
        if (stage) {
            _init();
        } else {
            addEventListener(Event.ADDED_TO_STAGE, _init);
        }
    } else if(nativeApplicationUpdater.currentState == NativeApplicationUpdater.WAITING_CONFIRMATION) {
        var label:Label = new Label();
        var okay:Button = new Button();
        var cancel:Button = new Button()
        addChild(label);
        addChild(okay);
        addChild(cancel);
        label.invalidateSize();
        label.text = "Update available. Download now?";
        label.validateNow();
        okay.invalidateSize()
        okay.label = "OK";
        cancel.invalidateSize()
        cancel.label = "Update later";
        okay.validateNow();
        cancel.validateNow();
        label.x = stage.width / 2 - label.getExplicitOrMeasuredWidth()/2;
        label.y = stage.height / 2;
        okay.x = stage.width/2 - okay.getExplicitOrMeasuredWidth();
        cancel.x = stage.width/2;
        okay.y = label.y + label.getExplicitOrMeasuredHeight();
        cancel.y = label.y + label.getExplicitOrMeasuredHeight();

        var progressBar:ProgressBar = new ProgressBar();


        okay.addEventListener(MouseEvent.CLICK,
                function(e:MouseEvent):void {
                    okay.enabled = false;
                    cancel.enabled = false;
                    progressBar.source = nativeApplicationUpdater;
                    addChild(progressBar);
                    progressBar.invalidateSize();
                    progressBar.validateNow();

                    progressBar.x = stage.width/2 - progressBar.getExplicitOrMeasuredWidth()/2;
                    progressBar.y = okay.y + okay.height;
                    
                    nativeApplicationUpdater.currentState = NativeApplicationUpdater.AVAILABLE;
                    nativeApplicationUpdater.downloadUpdate();

        });

        cancel.addEventListener(MouseEvent.CLICK,
        function(e:MouseEvent):void {
            removeChild(label);
            removeChild(okay);
            removeChild(cancel);
            _init();
        });

//        nativeApplicationUpdater.addEventListener(ProgressEvent.PROGRESS,
//                function downloadProgress(e:flash.events.ProgressEvent):void {
//                    progressBar.setProgress(e.bytesLoaded, e.bytesTotal);
//                });
    }
}

private function _init(e:Event = null):void {

    stage.scaleMode = StageScaleMode.NO_SCALE;
    stage.align = StageAlign.TOP_LEFT;

    application_preferences_so = SharedObject.getLocal("app_preferences");

    if(application_preferences_so.data.windowDimensions) {
        stage.nativeWindow.width = application_preferences_so.data.windowDimensions.width;
        stage.nativeWindow.height = application_preferences_so.data.windowDimensions.height;
        stage.nativeWindow.x = 0;//application_preferences_so.data.windowDimensions.x;
        stage.nativeWindow.y = 0;//application_preferences_so.data.windowDimensions.y;
        this.width = stage.nativeWindow.width;
        this.height = stage.nativeWindow.height;
    } else {
        application_preferences_so.data.windowDimensions = new Rectangle(
                stage.nativeWindow.x,
                stage.nativeWindow.y,
                stage.nativeWindow.width,
                stage.nativeWindow.height);
    }

    _starling = new Starling(VidexStarling, stage);
    VidexStarling.flexLayer = this;
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
            FlexGlobals.topLevelApplication.stage.nativeWindow.x,
            FlexGlobals.topLevelApplication.stage.nativeWindow.y,
            FlexGlobals.topLevelApplication.stage.nativeWindow.width,
            FlexGlobals.topLevelApplication.stage.nativeWindow.height);
}


