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
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;

import com.deng.fzip.FZip;
import com.deng.fzip.FZipFile;
import com.doublefx.as3.thread.Thread;
import com.doublefx.as3.thread.api.IThread;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.event.ThreadStateEvent;
import com.doublefx.as3.thread.util.ThreadRunnerX;
import com.greensock.events.LoaderEvent;
import com.greensock.loading.BinaryDataLoader;
import com.greensock.loading.LoaderMax;

import flash.display.DisplayObject;
import flash.display.NativeMenu;

import flash.events.Event;
import flash.events.SQLEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.SharedObject;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.getTimer;

import mx.core.FlexGlobals;

import mx.formatters.DateFormatter;

import org.osflash.signals.Signal;

public class UserLogsLoader extends View {

    public var getDataFromDate:Date;
    public var todayDate:Date;

    public var finishedLoading:Boolean = false;

    public var loader:LoaderMax;

    public var orgUserRecordsArray:Array;
    public var orgVideoRecordsArray:Array;

    public var db:UserLogDBManager;

    private var totalURLS:Number;
    private var urlsToDownload:Array = [];
    private var currentURL:String;
    private var progress:Number;
//    private var URLDOWNLOADINGINDEX:Number = 0;

//    public var freezeSignal:Signal;
    public var completeSignal:Signal;
    public var errorSignal:Signal;
    public var progressSignal:Signal;
    private var processProgressSignal:Signal;

    public var statusSignal:Signal;

    public function UserLogsLoader() {

//        freezeSignalgnal = new Signal(); // alert the user that the ui will freeze (we're loading a huge ByteArray)
        completeSignal = new Signal();
        errorSignal = new Signal();
        progressSignal = new Signal(Number, Number); // current progress, total progress
        statusSignal = new Signal(String); // status string

        processProgressSignal = new Signal(Number);
        processProgressSignal.add(processProgressListener);
    }

    public function load():void {

//        var file:File = File.applicationStorageDirectory.resolvePath("user_logs.db-journal");
//        if(file.exists)
//            file.deleteFile();

        db = new UserLogDBManager(File.applicationStorageDirectory.resolvePath("user_logs.db").nativePath);
        db.addEventListener(SQLEvent.OPEN, dbOpened);
        db.openAsync();

    }

    public function select(text:String):Signal {
        return db.select(text);
    }

    private function dbOpened(e:Event):void {

//        trace("Log DB opened")
        db.getLatestRecordDate().add(gotLatestRecordDate);
    }



    private function gotLatestRecordDate(date:Date):void {



        todayDate = new Date();
        getDataFromDate = date;

        getDataFromDate.setTime(getDataFromDate.getTime() - Constants.SERVER_TO_LOCAL_TIME_DIFF * Constants.HOURS2MILLISECONDS);

        trace("---------");
        trace("User Logs latest record: " + getDataFromDate);

        loader = new LoaderMax( { name: "WebLoaderQueue", autoLoad:true, auditSize:true, maxConnections:1 });

        var newTime:Number = Math.min(Util.localTime2ServerTime(getDataFromDate).getTime() + 7 * Constants.DAYS2MILLISECONDS,
                new Date().getTime());

        var getDataToDate:Date;

        var i:int = 0;

        urlsToDownload = [];
        var newFromDate:Date;
        var toTime:Number = new Date().getTime() > VideoMetadataManager.COURSE.endDate.getTime() ?
                                                VideoMetadataManager.COURSE.endDate.getTime() : new Date().getTime();
        for(var time:Number = newTime; time < toTime; time += 7 * Constants.DAYS2MILLISECONDS) {

            newFromDate = new Date(time);
            getDataToDate = new Date(time + 7 * Constants.DAYS2MILLISECONDS);

            var url:String ="http://" + Constants.DOMAIN + "/admin/getLogsForClass.php?" +
                    "&user_string=" + COURSE::Name +
                    "&fromDate=" + Util.dateToISO8601(newFromDate) +
                    "&toDate=" + Util.dateToISO8601(getDataToDate);
            urlsToDownload.push(url);

        }

        trace("Logs to download: " + urlsToDownload.length)
        for(var i:int = 0; i<urlsToDownload.length; i++) {
            trace(i + ": " + urlsToDownload[i]);
        }
        trace("---------");

        totalURLS = urlsToDownload.length;

        if(urlsToDownload.length > 0) {
            currentURL = urlsToDownload.shift();
            trace(url);
            loader.append(new BinaryDataLoader(currentURL,
                    {
                        name: currentURL,
                        onComplete: loaderComplete
                    }
            ));

            trace("Downloading " + currentURL);
            loader.load();
        } else {

            completeSignal.dispatch();
        }
    }


    private var _thread:IThread;
    public const extraDependencies:Vector.<String> = Vector.<String>([
            "com.doublefx.as3.thread.util.ThreadRunnerX"
        ,
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
            "flash.filesystem.File"
    ]);


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


    private var timer:Timer;

    private function thread_resultHandler(event:ThreadResultEvent):void {

//        trace("IT'S DEEPFREEZE TIME")
//        freezeSignal.dispatch();

        registerClassAlias("ca.ubc.ece.hct.myview.Log", Log);

        if(_thread) {
            _thread.terminate();
        }

        if(urlsToDownload.length > 0) {

            currentURL = urlsToDownload.shift();

            loader.append(new BinaryDataLoader(currentURL,
                    {
                        name: currentURL,
//                        onProgress: loaderProgress,
                        onComplete: loaderComplete
                    }
            ));


            if(_thread.isRunning) {

                timer = new Timer(500);
                timer.addEventListener(TimerEvent.TIMER, startThread);
                timer.start();
                function startThread(e:TimerEvent):void {
                    if(!_thread.isRunning) {
                        timer.stop();
                        timer.removeEventListener(TimerEvent.TIMER, startThread);
                        statusSignal.dispatch(datesFromURL(currentURL) + " - Downloading - " + Util.roundNumber(progress * 100, 1));
                        loader.load();
                    }
                }
            }

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
         processProgressSignal.dispatch(event.current/event.total);
    }

    var zipContents:Array = [];
    var zipContentsCounter:Number = 0;
    private function loaderComplete(e:LoaderEvent):void {

//        trace("loader complete");

        statusSignal.dispatch("Extracting " + getDataFromDate);

        var zip:FZip = new FZip();
        zip.addEventListener(Event.COMPLETE, zipLoaded);

        try {
            zip.loadBytes(e.target.content);
        } catch (e:Error) { }
    }


//    private var logStrings:Array = [];
    private function zipLoaded(e:Event):void {

//        statusSignal.dispatch("Processing " + getDataFromDate);
        var zip:FZip = (FZip)(e.target);

        userLogsLoaded(zip.getFileByName(COURSE::Name + ".txt"));


    }

    private function processProgressListener(n:Number):void {
        progress = (totalURLS - (urlsToDownload.length + 1)) / totalURLS + (1/totalURLS * n);

        var statusString:String = n < 0.5 ? "Processing" : "Saving"

        statusSignal.dispatch(datesFromURL(currentURL) + " - " + statusString + " - " + Util.roundNumber(progress * 100, 1));

        progressSignal.dispatch(progress, 1);
    }

    private function datesFromURL(s:String):String {
        var split:Array = s.split("/");
        var splitAgain:Array = split[split.length - 1].split("&");

        return splitAgain[splitAgain.length - 2] + " to " + splitAgain[splitAgain.length - 1];
    }
}
}
