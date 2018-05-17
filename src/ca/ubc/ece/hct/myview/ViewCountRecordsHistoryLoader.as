/**
 * Created by iDunno on 2018-01-24.
 */
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;

import com.deng.fzip.FZip;
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
import flash.net.SharedObject;
import flash.net.registerClassAlias;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import mx.core.ByteArrayAsset;

import mx.core.FlexGlobals;

import mx.formatters.DateFormatter;

import org.osflash.signals.Signal;

public class ViewCountRecordsHistoryLoader extends View {

//    public var minDate:Date;
//    public var maxDate:Date;

    public var video:VideoMetadata;

    public var loader:LoaderMax;

    public var orgUserRecordsArray:Array;
    public var hourlyRecordCount:Array;
    public var dailyRecordCount:Array;
    public var dailyRecordMaxCount:Number;

    public var minDate:Date;
    public var maxDate:Date;
    public var todayDate:Date;

    public var vcr_so:SharedObject;

    public var localComplete:Signal;
    public var completeSignal:Signal;
    public var errorSignal:Signal;
    public var progressSignal:Signal;

    public var statusSignal:Signal;

    public var getDataFromDate:Date;

    private var logStrings:Array = [];

    public function ViewCountRecordsHistoryLoader() {

        completeSignal = new Signal();
        errorSignal = new Signal();
        progressSignal = new Signal(Number, Number); // current progress, total progress
        statusSignal = new Signal(String); // status string
    }

    public function loadVideo(video:VideoMetadata):void {

        this.video = video;

        todayDate = new Date();

        vcr_so = SharedObject.getLocal("vcr_" + video.id);

        if(vcr_so.size > 0) {
            getDataFromDate = vcr_so.data.dataUpToDate;
            dailyRecordCount = vcr_so.data.dailyRecordCount;
//            dailyRecordMaxCount = vcr_so.data.dailyRecordMaxCount;

            dailyRecordMaxCount = 0;
            for(var i:int = 0; i<dailyRecordCount.length; i++) {
                dailyRecordMaxCount = Math.max(dailyRecordMaxCount, dailyRecordCount[i].count);
            }
        } else {
            getDataFromDate = VideoMetadataManager.COURSE.startDate;
            dailyRecordCount = [];
            dailyRecordMaxCount = 0;
        }

        loader = new LoaderMax( { name: "WebLoaderQueue", autoLoad:true, auditSize:true, maxConnections:1 });

        var newTime:Number = Math.min(Util.localTime2ServerTime(getDataFromDate).getTime() + 7 * Constants.DAYS2MILLISECONDS,
                new Date().getTime());

        var getDataToDate:Date;

        var i:int = 0;

        for(var time:Number = newTime; time < todayDate.getTime(); time += 7 * Constants.DAYS2MILLISECONDS) {

            getDataFromDate = new Date(time);
            getDataToDate = new Date(time + 7 * Constants.DAYS2MILLISECONDS);

            var url:String ="http://" + Constants.DOMAIN + "/admin/getUserRecordsHistoryByMediaAliasID.php?" +
                    "media_alias_id=" + video.media_alias_id +
                    "&user_string=" + COURSE::Name +
                    "&fromDate=" + Util.dateToISO8601(getDataFromDate) +
                    "&toDate=" + Util.dateToISO8601(getDataToDate);
            trace(url);

            loader.append(new BinaryDataLoader(url,
                    {
                        name: i++,
                        onProgress: loaderProgress,
                        onComplete: loaderComplete
                    }
            ));

            statusSignal.dispatch("Downloading logs...");

        }

        loader.load();


        var oldHourlyBA:ByteArray = new ByteArray();
        if(Util.readFileIntoByteArray("vcr_hourly_" + video.id, oldHourlyBA)) {
            hourlyRecordCount = oldHourlyBA.readObject() as Array;
        } else {
            hourlyRecordCount = [];
        }

        var oldRecordsBA:ByteArray = new ByteArray();
        if(Util.readFileIntoByteArray("vcr_records_" + video.id, oldRecordsBA)) {
            orgUserRecordsArray = oldRecordsBA.readObject() as Array;
        } else {
            orgUserRecordsArray = [];
        }


        if(loader.numChildren == 0) {
            trace("progressSignal dispatch 1, 1");
            progressSignal.dispatch(1, 1);
            completeSignal.dispatch();
//            thread_resultHandler(null);
        }

    }

    private var _thread:IThread;
    public const extraDependencies:Vector.<String> = Vector.<String>(["flash.utils.ByteArray", "ca.ubc.ece.hct.myview.Util", "ca.ubc.ece.hct.myview.Constants", "com.doublefx.as3.thread.util.ThreadRunnerX"]);

    public function userRecordsHistoryLoaded():void {

        statusSignal.dispatch("Processing logs...");

        var strings:Array = logStrings;

        if(vcr_so.size > 0) {
            minDate = vcr_so.data.minDate;
        } else if(strings.length > 0) {
            minDate = DateFormatter.parseDateString(strings[0].split("\t")[2]);
        }

        if(strings.length > 0) {
            maxDate = DateFormatter.parseDateString(strings[strings.length - 1].split("\t")[2]);
        } else {
            maxDate = vcr_so.data.maxDate;
        }

        Thread.DEFAULT_LOADER_INFO = FlexGlobals.topLevelApplication.loaderInfo;//this.loaderInfo;
        _thread = new Thread(ViewCountRecordProcess, "complexRunnable", false, extraDependencies, this.loaderInfo);
        _thread.addEventListener(ThreadStateEvent.THREAD_STATE, onThreadState);
        _thread.addEventListener(ThreadProgressEvent.PROGRESS, thread_progressHandler);
        _thread.addEventListener(ThreadResultEvent.RESULT, thread_resultHandler);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);

        _thread.start(new ViewCountRecordProcessArguments(strings));

    }

    private function onThreadState(event:ThreadStateEvent):void {
        trace("Thread State: " + _thread.state);
    }

    private function thread_resultHandler(event:ThreadResultEvent):void {

        if(_thread) {

            registerClassAlias("ca.ubc.ece.hct.myview.UserViewCountRecord", UserViewCountRecord);
            var records:ByteArray = _thread.getSharedProperty("orgUserRecords") as ByteArray;
            var newOrgUserRecordsArray:Array = records.readObject() as Array;

            var records2:ByteArray = _thread.getSharedProperty("hourlyRecordCount") as ByteArray;
            var newHourlyRecordCount:Array = records2.readObject() as Array;

            var records3:ByteArray = _thread.getSharedProperty("dailyRecordCount") as ByteArray;
            var newDailyRecordCount:Array = records3.readObject() as Array;

            var records4:ByteArray = _thread.getSharedProperty("dailyRecordMaxCount") as ByteArray;
            var newDailyRecordMaxCount:Number = records4.readObject() as Number;

            _thread.terminate();

            // read from old files
            var oldRecords:ByteArray = new ByteArray();
            var oldHourly:ByteArray = new ByteArray();
            var oldDailyRecordCount:Array = [];

            if (vcr_so.size > 0) {
//            trace("Loader: Reading old files in array");
                Util.readFileIntoByteArray("vcr_records_" + video.id, oldRecords);
                Util.readFileIntoByteArray("vcr_hourly_" + video.id, oldHourly);
                orgUserRecordsArray = oldRecords.readObject() as Array;
                hourlyRecordCount = oldHourly.readObject() as Array;
                oldDailyRecordCount = vcr_so.data.dailyRecordCount;
            } else {
                // Loader: Old files don't exist
                orgUserRecordsArray = [];
                hourlyRecordCount = [];
//            dailyRecordMaxCount = 0;
                dailyRecordCount = [];
            }


//        trace("Loader: Concatentating old arrays with new ones");
            orgUserRecordsArray = orgUserRecordsArray.concat(newOrgUserRecordsArray);
            hourlyRecordCount = hourlyRecordCount.concat(newHourlyRecordCount);
            if (newDailyRecordCount) {
                dailyRecordCount = oldDailyRecordCount.concat(newDailyRecordCount);
            } else {
                dailyRecordCount = oldDailyRecordCount;
            }

            dailyRecordMaxCount = 0;
            for (var i:int = 0; i < dailyRecordCount.length; i++) {

                dailyRecordMaxCount = Math.max(dailyRecordMaxCount, dailyRecordCount[i].count);

//                trace(dailyRecordCount[i].date + " - " + dailyRecordCount[i].count)
            }

//        trace("Loader: orgUserRecordsArray.length = " + orgUserRecordsArray.length);
//        trace("Loader: hourlyRecordCount.length = " + hourlyRecordCount.length);


            vcr_so.data.minDate = minDate;
            vcr_so.data.maxDate = maxDate;
            vcr_so.data.dataUpToDate = new Date();
            vcr_so.data.dailyRecordCount = dailyRecordCount;

//        vcr_so.data.dailyRecordMaxCount = dailyRecordMaxCount;
            vcr_so.flush();

            // write new records to files
            records = new ByteArray();
            records2 = new ByteArray();
            records3 = new ByteArray();
            records.writeObject(orgUserRecordsArray);
            records2.writeObject(hourlyRecordCount);

            Util.writeBytesToFile("vcr_records_" + video.id, records);
            Util.writeBytesToFile("vcr_hourly_" + video.id, records2);
        }

        completeSignal.dispatch();
        statusSignal.dispatch("Finished - 100%");


    }

    private function thread_faultHandler(event:ThreadFaultEvent):void {
//        result.text += event.fault.message;
        trace("THREAD FAULT: " + event.fault.message);
        trace(new Error().getStackTrace());
        _thread.terminate();

        errorSignal.dispatch();
    }

    private function thread_progressHandler(event:ThreadProgressEvent):void {
        trace("THREAD PROGRESS: " + event.current + "/" + event.total)
//        progressBar.setProgress(event.current, event.total);
        progressSignal.dispatch(event.current/event.total/2 + 0.5, 1);
        statusSignal.dispatch("Processing logs - " + Math.round((event.current/event.total/2 + 0.5) * 100) + "%")
    }

    private function loaderProgress(e:LoaderEvent):void {
//        trace("Download Progress: " + e.target.progress);
        trace("Download Progress: " + loader.progress + " - " + e.target.name + ": " + e.target.progress);
        progressSignal.dispatch(loader.progress/2, 1);
        statusSignal.dispatch("Downloading logs - " + Math.round(loader.progress/2 * 100) + "%")
    }

    var zipContents:Array = [];
    var zipContentsCounter:Number = 0;
    private function loaderComplete(e:LoaderEvent):void {

//                        trace("Extracting logs");
//        statusSignal.dispatch("Extracting logs...");

        zipContents[Number(e.target.name)] = e.target.content;

        if(loader.bytesLoaded == loader.bytesTotal) {

            unzipContents();
        }
    }

    private function unzipContents():void {

        var zip:FZip = new FZip();
        zip.addEventListener(Event.COMPLETE, zipLoaded);

        try {
            zip.loadBytes(zipContents[zipContentsCounter++]);
        } catch (e:Error) {}
    }

    private function zipLoaded(e:Event):void {

//        statusSignal.dispatch("Processing logs (2/2)");
        var newStrings:Array = (String)(e.target.getFileByName(video.media_alias_id + ".txt").content).split("\n");
        newStrings.pop();
        for(var i:int = 0; i<newStrings.length; i++) {
            logStrings.push(newStrings[i]);
        }

        if(zipContentsCounter < zipContents.length) {
            unzipContents();
        } else {
            userRecordsHistoryLoaded();
        }
//        userRecordsHistoryLoaded(e.target.getFileByName(video.media_alias_id + ".txt").content);

    }
}
}
