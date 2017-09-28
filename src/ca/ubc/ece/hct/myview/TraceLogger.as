////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////
package ca.ubc.ece.hct.myview {
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.utils.Timer;

import starling.core.Starling;
import starling.events.TouchEvent;
import starling.events.Touch;
import starling.events.TouchPhase;

public class TraceLogger {
    public function TraceLogger() {
    }

    public static var traces:Array;
    public static var uploadTimer:Timer;

    public static function startDetailedLogging():void {

        traces = [];
        uploadTimer = new Timer(10000);
        uploadTimer.addEventListener(TimerEvent.TIMER, uploadTraces);
        uploadTimer.start();

        Starling.current.nativeOverlay.addEventListener(MouseEvent.MOUSE_MOVE,
                function mouse_move(e:MouseEvent):void {
                    if (e.buttonDown) {
                        traces.push(new Trace(new Date(), new Point(Starling.current.nativeOverlay.mouseX, Starling.current.nativeOverlay.mouseY), "MOVED"));
                    } else {
                        traces.push(new Trace(new Date(), new Point(Starling.current.nativeOverlay.mouseX, Starling.current.nativeOverlay.mouseY), "HOVER"));
                    }
                });

        Starling.current.nativeOverlay.addEventListener(MouseEvent.MOUSE_DOWN,
                function mouse_down(e:MouseEvent):void {
                    traces.push(new Trace(new Date(), new Point(Starling.current.nativeOverlay.mouseX, Starling.current.nativeOverlay.mouseY), "MOUSE_DOWN"));
                });
        Starling.current.nativeOverlay.addEventListener(MouseEvent.MOUSE_UP,
                function mouse_up(e:MouseEvent):void {
                    traces.push(new Trace(new Date(), new Point(Starling.current.nativeOverlay.mouseX, Starling.current.nativeOverlay.mouseY), "MOUSE_UP"));
                });

        Starling.current.stage.addEventListener(TouchEvent.TOUCH,
                function tt(e:TouchEvent):void {
                    var touch:Touch = e.getTouch(Starling.current.stage);
                    if (touch) {
                        switch (touch.phase) {

                            case TouchPhase.BEGAN:
                                traces.push(new Trace(new Date(), new Point(touch.globalX, touch.globalY), "MOUSE_DOWN"));
//                                trace("TouchPhase.BEGAN");
                                break;
                            case TouchPhase.HOVER:
                                traces.push(new Trace(new Date(), new Point(touch.globalX, touch.globalY), "HOVER"));
//                                trace("TouchPhase.HOVER");
                                break;
                            case TouchPhase.ENDED:
                                traces.push(new Trace(new Date(), new Point(touch.globalX, touch.globalY), "MOUSE_UP"));
//                                trace("TouchPhase.ENDED");
                                break;
                            case TouchPhase.MOVED:
                                traces.push(new Trace(new Date(), new Point(touch.globalX, touch.globalY), "MOVED"));
//                                trace("TouchPhase.MOVED");
                                break;
                        }
//                        trace(i++ + " " + e.getTouch(Starling.current.stage).globalX + " " + e.getTouch(Starling.current.stage).globalY);
                    }
                });
    }

    public static function uploadTraces(e:TimerEvent = null):void {

        if(traces.length > 0) {
            var traceString:String = "";
            for (var i:int = 0; i < traces.length; i++) {
                traceString += traces[i].toString() + "\n";
            }

            ServerDataLoader.uploadTraces(UserID.id, traceString);
            traces = [];
        }
    }
    }
}

import flash.geom.Point;

class Trace {
    public var dateTime:Date;
    public var mouseLocation:Point;
    public var touchPhase:String;

    public function Trace(dateTime:Date, mouseLocation:Point, touchPhase:String) {
        this.dateTime = dateTime;
        this.mouseLocation = mouseLocation;
        this.touchPhase = touchPhase;
    }

    public function toString():String {
        return dateTime.time + "," + mouseLocation.x + "," + mouseLocation.y + "," + touchPhase;
    }
}
