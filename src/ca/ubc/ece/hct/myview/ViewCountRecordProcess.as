////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {


import com.doublefx.as3.thread.api.CrossThreadDispatcher;
import com.doublefx.as3.thread.api.Runnable;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import ca.ubc.ece.hct.myview.UserViewCountRecord;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.Constants;

public class ViewCountRecordProcess implements Runnable {

    /**
     * Mandatory declaration if you want your Worker be able to communicate.
     * This CrossThreadDispatcher is injected at runtime.
     */
    public var dispatcher:CrossThreadDispatcher;

    // number of records per hour
    public var hourlyRecordCount:Array;
    public var hourlyRecordCountBA:ByteArray;
    public var dailyRecordCountBA:ByteArray;
    public var dailyRecordMaxCountBA:ByteArray;

    public var orgUserRecords:Array;
    public var records:ByteArray;

    private var usernames:Array;

    public static const SECONDS2MILLISECONDS:Number = 1000;
    public static const MINUTES2MILLISECONDS:Number = 60 * SECONDS2MILLISECONDS;
    public static const HOURS2MILLISECONDS:Number = 60 * MINUTES2MILLISECONDS;
    public static const DAYS2MILLISECONDS:Number = 24 * HOURS2MILLISECONDS;
    public static const WEEKS2MILLISECONDS:Number = 7 * DAYS2MILLISECONDS;

    public function putRecord(user:String, vcr:String, date:Date):void {

        var userIndex:int = -1;
        for(var i:int = 0; i<orgUserRecords.length; i++) {
            if(orgUserRecords[i].username == user) {
                userIndex = i;
                break;
            }
        }
        if(userIndex < 0) {
            usernames.push(user);
            orgUserRecords.push(new UserViewCountRecord(user));
            userIndex = orgUserRecords.length - 1;
        }

        orgUserRecords[userIndex].addRecord(vcr, date);
    }

    public function process(obj:ViewCountRecordProcessArguments):int {

        usernames = [];
        orgUserRecords = [];
        hourlyRecordCount = [];
        var strings:Array = obj.strings;

        var minDate:Date;
        var maxDate:Date;
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
            var date:Date = Util.serverTime2LocalTime(new Date(year, month - 1, day, hour, minute, second));
            if(i == 0) {
                minDate = date;
            }
            maxDate = date;

            if(dateCounter.fullYear     != date.fullYear ||
                dateCounter.month   != date.month ||
                dateCounter.date     != date.date ||
                dateCounter.hours    != date.hours) {

                dateCounter = date;
                hourlyRecordCount.push({date:date, count:counter});
                counter = 0;
            } else {
                counter++;
            }

            putRecord(user, vcr, date);

            dispatcher.dispatchProgress(i, strings.length);
        }

        var runningTime:Number;
        var oldSum:Number = 0;
        var newVCR:Array = [];
        var newSum:Number = 0;

        var dailyRecordMaxCount:Number = 0;
        var dailyRecordCount:Array = [];

        if(minDate && maxDate) {

            var startDate:Date = new Date(minDate.fullYear, minDate.month, minDate.date);
            for (runningTime = startDate.getTime(); runningTime <= maxDate.getTime(); runningTime += DAYS2MILLISECONDS) {

                // get the vcr at the END of the day, and store it as the beginning of the day.
                var date:Date = new Date(runningTime + DAYS2MILLISECONDS);
                newVCR = getAggregateVCRAtDate(date);

                newSum = 0;
                for (i = 0; i < newVCR.length; i++) {
                    newSum += newVCR[i];
                }

//                trace("x" + date + " " + (newSum - oldSum));

                dailyRecordCount.push({date: new Date(runningTime), count: (newSum - oldSum)});

//                trace("proc: " + new Date(runningTime) + ": " + (newSum - oldSum));

                dailyRecordMaxCount = Math.max(dailyRecordMaxCount, (newSum - oldSum));

                oldSum = newSum;
            }
        }

//        trace("dailyRecordMaxCount = " + dailyRecordMaxCount);


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


        dailyRecordCountBA = new ByteArray();

        dailyRecordCountBA.shareable = true;
        dailyRecordCountBA.writeObject(dailyRecordCount);
        dailyRecordCountBA.position = 0;
        dispatcher.setSharedProperty("dailyRecordCount", dailyRecordCountBA);


        dailyRecordMaxCountBA = new ByteArray();

        dailyRecordMaxCountBA.shareable = true;
        dailyRecordMaxCountBA.writeObject(dailyRecordMaxCount);
        dailyRecordMaxCountBA.position = 0;
        dispatcher.setSharedProperty("dailyRecordMaxCount", dailyRecordMaxCountBA);

        return 1;

    }

    // Implements Runnable interface
    public function run(args:Array):void {
        trace(args[0]);
        var value:ViewCountRecordProcessArguments = (ViewCountRecordProcessArguments)(args[0]);

        dispatcher.dispatchResult(process(value));
    }

    public function getAggregateVCRAtDate(date:Date):Array {

        var aggregateVCR:Array = [];

        for each(var user:String in usernames) {

            var vcr:Array = [];
            var vcrString:Array = getVCRForUserAtDate(user, date);

            for (var j:int = 0; j < vcrString.length; j++) {
                vcr.push(Number(vcrString[j]));
            }

            while (aggregateVCR.length < vcr.length) {
                aggregateVCR.push(0);
            }
            for (var i:int = 0; i < vcr.length; i++) {
                aggregateVCR[i] += vcr[i];
            }

        }

        return aggregateVCR;
    }

    public function getRecordsForUser(user:String):UserViewCountRecord {

        var records:UserViewCountRecord = null;
        for(var i:int = 0; i<orgUserRecords.length; i++) {
            if(orgUserRecords[i].username == user) {
                records = new UserViewCountRecord(user);
                records.username = orgUserRecords[i].username;
                records.vcrs = orgUserRecords[i].vcrs;
                records.vcrDates = orgUserRecords[i].vcrDates;
                records.mapIndices = orgUserRecords[i].mapIndices;
                records.mapDates = orgUserRecords[i].mapDates;
                break;
            }
        }

        return records;
    }

    public function getVCRForUserAtDate(user:String, date:Date):Array {

        var records:UserViewCountRecord = getRecordsForUser(user);

        // find index of records to jump to and start searching
        var mapIndex:int;
        for(mapIndex = 0; mapIndex < records.mapDates.length-1; mapIndex++) {
            if(records.mapDates[mapIndex] >= date) {
                break;
            }
        }

        var entry:int = records.mapIndices[mapIndex];
        for(var i:int = records.mapIndices[mapIndex]; i < records.vcrDates.length; i++) {

            if(records.vcrDates[i] > date) {
                break;
            }

            entry = i;
        }

        if(entry >= 0) {
            var arr:Array = records.vcrs[entry].split(",");

            for(var j:int = 0; j<arr.length; j++) {
                arr[j] = Number(arr[j]);
            }

            return arr;
        }

        return [];

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

                if(mapDates.length > 0) {
                    var oldDate:Date = mapDates[mapDates.length - 1];
                }

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