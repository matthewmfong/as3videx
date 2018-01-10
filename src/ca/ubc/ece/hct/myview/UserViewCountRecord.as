/**
 * Created by iDunno on 2017-04-09.
 */
package ca.ubc.ece.hct.myview {

public class UserViewCountRecord {

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
}