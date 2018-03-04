/**
 * Created by iDunno on 2018-02-04.
 */
/**
 * Created by iDunno on 2018-01-24.
 */
package ca.ubc.ece.hct.myview.log {
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import ca.ubc.ece.hct.myview.log.Log;
import ca.ubc.ece.hct.myview.log.UserLogCollection;
import ca.ubc.ece.hct.myview.log.VideoLogCollection;
import ca.ubc.ece.hct.myview.log.VideoPlayerEvent;
import ca.ubc.ece.hct.myview.log.VideoPlayerState;

import com.deng.fzip.FZip;
import com.deng.fzip.FZipFile;
import com.doublefx.as3.thread.Thread;
import com.doublefx.as3.thread.api.IThread;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.event.ThreadStateEvent;
import com.greensock.events.LoaderEvent;
import com.greensock.loading.BinaryDataLoader;
import com.greensock.loading.LoaderMax;

import flash.display.DisplayObject;

import flash.events.Event;
import flash.events.SQLEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.SharedObject;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import mx.core.FlexGlobals;

import mx.formatters.DateFormatter;

import org.osflash.signals.Signal;

public class UserLogsLoader extends View {

    public var getDataFromDate:Date;
    public var todayDate:Date

    public var finishedLoading:Boolean = false;

    public var loader:LoaderMax;

    public var orgUserRecordsArray:Array;
    public var orgVideoRecordsArray:Array;

    public var db:UserLogDBManager;

    public var freezeSignal:Signal;
    public var completeSignal:Signal;
    public var errorSignal:Signal;
    public var progressSignal:Signal;

    public var statusSignal:Signal;

    public function UserLogsLoader() {

        freezeSignal = new Signal(); // alert the user that the ui will freeze (we're loading a huge ByteArray)
        completeSignal = new Signal();
        errorSignal = new Signal();
        progressSignal = new Signal(Number, Number); // current progress, total progress
        statusSignal = new Signal(String); // status string
    }

    public function load():void {

        db = new UserLogDBManager(File.applicationStorageDirectory.resolvePath("user_logs.db").nativePath);
        db.addEventListener(SQLEvent.OPEN, dbOpened);
        db.openAsync();

    }

    public function select(text:String):Signal {
        return db.select(text);
    }

    private function dbOpened(e:Event):void {

        db.getLatestRecordDate().add(gotLatestRecordDate);
    }

    private function gotLatestRecordDate(date:Date):void {

        todayDate = new Date();
        getDataFromDate = date;

        getDataFromDate.setTime(getDataFromDate.getTime() - Constants.SERVER_TO_LOCAL_TIME_DIFF * Constants.HOURS2MILLISECONDS);

//        trace(getDataFromDate);

        loader = new LoaderMax( { name: "WebLoaderQueue", auditSize:false });
        var url:String ="http://" + Constants.DOMAIN + "/admin/getLogsForClass.php?" +
                "fromDate=" + Util.dateToISO8601(getDataFromDate) +
                "&toDate=" + Util.dateToISO8601(new Date(getDataFromDate.getTime() + Constants.DAYS2MILLISECONDS)) +
                "&user_string=" + COURSE::Name;
        trace(url);


        statusSignal.dispatch("Downloading " + getDataFromDate);
        loader.append(new BinaryDataLoader(url,
                {
                    onProgress: function(e:LoaderEvent):void { /*trace("Download Progress: " + e.target.progress) */},
                    onComplete: function(e:LoaderEvent):void {

//                        trace("Extracting logs");
                        statusSignal.dispatch("Extracting " + getDataFromDate);
                        var zip:FZip = new FZip();
                        zip.addEventListener(Event.COMPLETE,
                                function loaded(e:Event):void {
//                                    trace("Processing Logs");
                                    statusSignal.dispatch("Processing " + getDataFromDate);
                                    var zip:FZip = (FZip)(e.target);

                                    userLogsLoaded(zip.getFileByName(COURSE::Name + ".txt"));
                                });

                        try {
                            zip.loadBytes(e.target.content);
                        } catch (e:Error) {
                            thread_resultHandler(null);
                        }
                    }
                }));
        loader.load();
    }

    private var _thread:IThread;
    public const extraDependencies:Vector.<String> = Vector.<String>([
            "flash.net.SharedObject",
            "flash.utils.ByteArray",

            "flash.utils.getTimer",
            "ca.ubc.ece.hct.myview.Util",
            "ca.ubc.ece.hct.myview.log.Log",

            "ca.ubc.ece.hct.myview.log.UserLogsLoader",
            "ca.ubc.ece.hct.myview.log.VideoPlayerEvent",
            "ca.ubc.ece.hct.myview.log.VideoPlayerState",
            "ca.ubc.ece.hct.myview.Constants",
            "ca.ubc.ece.hct.myview.log.UserLogDBManager",
            "flash.data.SQLConnection",
            "flash.data.SQLStatement",
            "flash.events.EventDispatcher",
            "flash.events.SQLErrorEvent",
            "flash.events.SQLEvent",
            "flash.filesystem.File"]);

    public function userLogsLoaded(file:FZipFile):void {

        var byteArray:ByteArray = file.content;
        byteArray.shareable = true;

        var dbPath:String = File.applicationStorageDirectory.resolvePath("user_logs.db").nativePath;


        Thread.DEFAULT_LOADER_INFO = FlexGlobals.topLevelApplication.loaderInfo;
        _thread = new Thread(UserLogsProcess, "complexRunnable", true, extraDependencies, Thread.DEFAULT_LOADER_INFO);
        _thread.addEventListener(ThreadStateEvent.THREAD_STATE, onThreadState);
        _thread.addEventListener(ThreadProgressEvent.PROGRESS, thread_progressHandler);
        _thread.addEventListener(ThreadResultEvent.RESULT, thread_resultHandler);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);

        _thread.start(new UserLogsProcessArguments(dbPath, byteArray));

    }

    private function onThreadState(event:ThreadStateEvent):void {
//        trace("Thread State: " + _thread.state);
    }

    private function thread_resultHandler(event:ThreadResultEvent):void {

//        trace("IT'S DEEPFREEZE TIME")
//        freezeSignal.dispatch();

        registerClassAlias("ca.ubc.ece.hct.myview.Log", Log);

        if(_thread) {
            _thread.terminate();
        }

//        trace("Logs loading all done. " + (getTimer() - asdf));
        finishedLoading = true;

        getDataFromDate = new Date(getDataFromDate.getTime() + Constants.DAYS2MILLISECONDS);

        if(getDataFromDate.getTime() < todayDate.getTime()) {

            var url:String = "http://" + Constants.DOMAIN + "/admin/getLogsForClass.php?" +
                    "fromDate=" + Util.dateToISO8601(getDataFromDate) +
                    "&toDate=" + Util.dateToISO8601(new Date(getDataFromDate.getTime() + Constants.DAYS2MILLISECONDS)) +
                    "&user_string=" + COURSE::Name;
            trace(url);


            statusSignal.dispatch("Downloading " + getDataFromDate);
            loader.append(new BinaryDataLoader(url,
                    {
                        onProgress: function (e:LoaderEvent):void { /*trace("Download Progress: " + e.target.progress) */
                        },
                        onComplete: function (e:LoaderEvent):void {

                            //                        trace("Extracting logs");
                            statusSignal.dispatch("Extracting " + getDataFromDate);
                            var zip:FZip = new FZip();
                            zip.addEventListener(Event.COMPLETE,
                                    function loaded(e:Event):void {
                                        //                                    trace("Processing Logs");
                                        statusSignal.dispatch("Processing " + getDataFromDate);
                                        var zip:FZip = (FZip)(e.target);
                                        userLogsLoaded(zip.getFileByName(COURSE::Name + ".txt"));
                                    });

                            try {
                                zip.loadBytes(e.target.content);
                            } catch (e:Error) {
                                thread_resultHandler(null);
                            }
                        }
                    }));
            loader.load();
        } else {
            completeSignal.dispatch();
        }
    }

    private function thread_faultHandler(event:ThreadFaultEvent):void {
//        result.text += event.fault.message;
//        trace("THREAD FAULT: " + event.fault.message);
//        trace(event.fault);
//        trace(event.fault.getStackTrace());
        _thread.terminate();

        errorSignal.dispatch();
    }

    private function thread_progressHandler(event:ThreadProgressEvent):void {
//        trace("LOG THREAD PROGRESS: " + event.current + "/" + event.total + "=" + event.current/event.total);
//        progressBar.setProgress(event.current, event.total);
        progressSignal.dispatch(event.current, event.total);
    }
}
}
