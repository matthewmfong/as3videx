/**
 * Created by iDunno on 2018-01-24.
 */
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.myview.video.VideoMetadata;

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

import mx.formatters.DateFormatter;

import org.osflash.signals.Signal;

public class ViewCountRecordsHistoryLoader extends View {

//    public var minDate:Date;
//    public var maxDate:Date;

    private var video:VideoMetadata;

    public var loader:LoaderMax;

    public var orgUserRecordsArray:Array;
    public var hourlyRecordCount:Array;

    public var minDate:Date;
    public var maxDate:Date;

    public var vcr_so:SharedObject;

    public var completeSignal:Signal;
    public var errorSignal:Signal;
    public var progressSignal:Signal;

    public var statusSignal:Signal;

    public function ViewCountRecordsHistoryLoader() {

        completeSignal = new Signal();
        errorSignal = new Signal();
        progressSignal = new Signal(Number, Number); // current progress, total progress
        statusSignal = new Signal(String); // status string
    }

    public function loadVideo(video:VideoMetadata):void {

        this.video = video;

        vcr_so = SharedObject.getLocal("vcr_" + video.id);
        var getDataFromDate:Date;

        trace("vcr_so.size = " + vcr_so.size);

        if(vcr_so.size > 0) {


            getDataFromDate = vcr_so.data.dataUpToDate;


        } else {

            getDataFromDate = new Date(2000, 0, 0, 0, 0, 0, 0);

        }

        trace(getDataFromDate);

        loader = new LoaderMax( { name: "WebLoaderQueue", auditSize:false });
        var url:String ="http://" + Constants.DOMAIN + "/admin/getUserRecordsHistoryByMediaAliasID.php?" +
                "media_alias_id=" + video.media_alias_id +
                "&user_string=" + COURSE::Name +
                "&fromDate=" + Util.dateToISO8601(getDataFromDate);
        trace(url);


        statusSignal.dispatch("Downloading logs (1/2)");
        loader.append(new BinaryDataLoader(url,
                {
                    onProgress: function(e:LoaderEvent):void { trace("Download Progress: " + e.target.progress)},
                    onComplete: function(e:LoaderEvent):void {

//                        trace("Extracting logs");
                        statusSignal.dispatch("Extracting logs");
                        var zip:FZip = new FZip();
                        zip.addEventListener(Event.COMPLETE,
                                function loaded(e:Event):void {
//                                    trace("Processing Logs");
                                    statusSignal.dispatch("Processing logs (2/2)");
                                    userRecordsHistoryLoaded(e.target.getFileByName(video.media_alias_id + ".txt").content);
                                });

                        zip.loadBytes(e.target.content);
                    }
                }));
        loader.load();
    }

    private var _thread:IThread;
    public const extraDependencies:Vector.<String> = Vector.<String>(["flash.utils.ByteArray"]);

    public function userRecordsHistoryLoaded(content:String):void {

        trace("userRecordsHistoryLoaded " + content.length);

        var strings:Array = content.split("\n");
        strings.pop(); // remove the last line, which is just a \n

        trace("strings.length = " + strings.length);

        if(vcr_so.size > 0) {

            minDate = vcr_so.data.minDate;

        } else if(strings.length > 0) {

            minDate = DateFormatter.parseDateString(strings[0].split("\t")[2]);
        }
        if(strings.length > 0) {
//            minDate = DateFormatter.parseDateString(strings[0].split("\t")[2]);
            maxDate = DateFormatter.parseDateString(strings[strings.length - 1].split("\t")[2]);

        } else {
            maxDate = vcr_so.data.maxDate;
        }
//        var newTime = getTimer();

        Thread.DEFAULT_LOADER_INFO = this.loaderInfo;
        _thread = new Thread(ViewCountRecordProcess, "complexRunnable", false, extraDependencies, this.loaderInfo);
        _thread.addEventListener(ThreadStateEvent.THREAD_STATE, onThreadState);
        _thread.addEventListener(ThreadProgressEvent.PROGRESS, thread_progressHandler);
        _thread.addEventListener(ThreadResultEvent.RESULT, thread_resultHandler);
        _thread.addEventListener(ThreadFaultEvent.FAULT, thread_faultHandler);

        _thread.start(new ViewCountRecordProcessArguments(strings));

//        trace("ViewCountRecordProcess should be running now.");
//        trace(_thread.state);


    }

    private function onThreadState(event:ThreadStateEvent):void {
        trace("Thread State: " + _thread.state);
    }

    private function thread_resultHandler(event:ThreadResultEvent):void {

        registerClassAlias("ca.ubc.ece.hct.myview.UserViewCountRecord", UserViewCountRecord);
        var records:ByteArray = _thread.getSharedProperty("orgUserRecords") as ByteArray;
        var newOrgUserRecordsArray:Array = records.readObject() as Array;

        var records2:ByteArray = _thread.getSharedProperty("hourlyRecordCount") as ByteArray;
        var newHourlyRecordCount:Array = records2.readObject() as Array;


        // read from old files
        var oldRecords:ByteArray = new ByteArray();
        var oldHourly:ByteArray = new ByteArray();

        if(vcr_so.size > 0) {
//            trace("Loader: Reading old files in array");
            Util.readFileIntoByteArray("vcr_records_" + video.id, oldRecords);
            Util.readFileIntoByteArray("vcr_hourly_" + video.id, oldHourly);
            orgUserRecordsArray = oldRecords.readObject() as Array;
            hourlyRecordCount = oldHourly.readObject() as Array;
        } else {
//            trace("Loader: Old files don't exist");
            orgUserRecordsArray = [];
            hourlyRecordCount = [];
        }

//        trace("Loader: Concatentating old arrays with new ones");
        orgUserRecordsArray = orgUserRecordsArray.concat(newOrgUserRecordsArray);
        hourlyRecordCount = hourlyRecordCount.concat(newHourlyRecordCount);

//        trace("Loader: orgUserRecordsArray.length = " + orgUserRecordsArray.length);
//        trace("Loader: hourlyRecordCount.length = " + hourlyRecordCount.length);


        vcr_so.data.minDate = minDate;
        vcr_so.data.maxDate = maxDate;
        vcr_so.data.dataUpToDate = new Date();


        // write new records to filesl
        records = new ByteArray();
        records2 = new ByteArray();
        records.writeObject(orgUserRecordsArray);
        records2.writeObject(hourlyRecordCount);

        Util.writeBytesToFile("vcr_records_" + video.id, records);
        Util.writeBytesToFile("vcr_hourly_" + video.id, records2);


        _thread.terminate();

        trace("all done.");
        completeSignal.dispatch();
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
        progressSignal.dispatch(event.current, event.total);
    }
}
}
