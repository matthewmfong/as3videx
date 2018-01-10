package ca.ubc.ece.hct.myview {


import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import ca.ubc.ece.hct.myview.UserViewCountRecord;

public class ViewCountRecordProcess implements Runnable {

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    public var dispatcher:CrossThreadDispatcher;

    public var hourlyRecordCount:Array;
    public var hourlyRecordCountBA:ByteArray;

    public var orgUserRecords:Array;
    public var records:ByteArray;

    public function putRecord(user:String, vcr:String, date:Date):void {

        var userIndex:int = -1;
        for(var i:int = 0; i<orgUserRecords.length; i++) {
            if(orgUserRecords[i].username == user) {
                userIndex = i;
                break;
            }
        }
        if(userIndex < 0) {
            orgUserRecords.push(new UserViewCountRecord(user));
            userIndex = orgUserRecords.length - 1;
        }

        orgUserRecords[userIndex].addRecord(vcr, date);
    }

    public function process(obj:ViewCountRecordProcessArguments):int {

        orgUserRecords = [];
        hourlyRecordCount = [];
        var strings:Array = obj.strings;

//        var newttt:Number = getTimer();
//        trace(getTimer());

        var dateCounter:Date = new Date();
        var counter:Number = 0;
        for(var i:int = 0; i<strings.length; i++) {
            var record:Array = strings[i].split("\t");
            var user:String = record[0];
            var vcr:String = record[1];
            var dateString:String = record[2];
            // YYYY-MM-DD hh:mm:ss
            // 0123456789012345678
            var year:Number = Number(dateString.substr(0, 4));
            var month:Number = Number(dateString.substr(5, 2));
            var day:Number = Number(dateString.substr(8, 2));
            var hour:Number = Number(dateString.substr(11, 2));
            var minute:Number = Number(dateString.substr(14, 2));
            var second:Number = Number(dateString.substr(17, 2));
            var date:Date = new Date(year, month - 1, day, hour, minute, second);
//            trace(date);

            if(dateCounter.year     != date.year ||
                dateCounter.month   != date.month ||
                dateCounter.date     != date.date ||
                dateCounter.hours    != date.hours) {
//                trace();
//                trace(date + "_ " + dateCounter + " " + counter);
                dateCounter = date;
                hourlyRecordCount.push({date:date, count:counter});
                counter = 0;
            } else {
                counter++;
            }

            putRecord(user, vcr, date);

            dispatcher.dispatchProgress(i, strings.length);
        }
//        trace("TIME EXECUTION" + (getTimer() - newttt))

//        for(var i:int = 0; i<orgUserRecords.length; i++) {
//            trace(orgUserRecords[i].username);
//        }


        records = new ByteArray();

        records.shareable = true;
        records.writeObject(orgUserRecords);
        records.position = 0;
        dispatcher.setSharedProperty("orgUserRecords", records);


        hourlyRecordCountBA = new ByteArray();

        hourlyRecordCountBA.shareable = true;
        hourlyRecordCountBA.writeObject(hourlyRecordCount);
        hourlyRecordCountBA.position = 0;
        dispatcher.setSharedProperty("hourlyRecordCount", hourlyRecordCountBA);

        return 1;

    }

    // Implements Runnable interface
    public function run(args:Array):void {
        var value:ViewCountRecordProcessArguments = (ViewCountRecordProcessArguments)(args[0]);

        dispatcher.dispatchResult(process(value));
    }

}
}

class UserViewCountRecord {

    public var username:String;
    public var vcrs:Array;
    public var vcrDates:Array;

    public var mapIndices:Array;
    public var mapDates:Array;

    public function UserViewCountRecord(username:String) {
        this.username = username;
        vcrs = [];
        vcrDates = [];
        mapIndices = [];
        mapDates = [];
    }

    // make sure that all you add records sequentially.
    public function addRecord(vcr:String, date:Date):void {
        if(vcrs.length > 0) {
            if (date >= vcrDates[vcrDates.length - 1]) {
                vcrs.push(vcr);
                vcrDates.push(date);

                if(mapDates.length > 0)
                    var oldDate:Date = mapDates[mapDates.length - 1];

                if (mapDates.length == 0 ||
                        (Math.abs(date.time - oldDate.time) > 1000 * 60 * 60)) {
//                    trace(" WE ARE INSERTING LOL ")
                    mapIndices.push(vcrs.length - 1);
                    mapDates.push(new Date(date.fullYear, date.month, date.date, date.hours));
                }
            } else {
                trace(date + " " + vcrDates[vcrDates.length - 1]);
                throw new Error("records not added sequentially");
            }
        } else {

            vcrs.push(vcr);
            vcrDates.push(date);
            mapIndices.push(vcrs.length - 1);
            mapDates.push(new Date(date.fullYear, date.month, date.date, date.hours));
        }
//        trace(mapDates.length);
//        trace(new Date(date.fullYear, date.month, date.date, date.hours).toString())
    }
}