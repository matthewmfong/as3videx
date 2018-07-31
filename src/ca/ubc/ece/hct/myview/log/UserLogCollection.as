/**
 * Created by iDunno on 2018-02-05.
 */
package ca.ubc.ece.hct.myview.log {
public class UserLogCollection {

    public var username:String;
    public var logs:Array;

    public function UserLogCollection(username:String) {
        this.username = username;
        logs = [];
    }

    public function addRecord(log:Log):void {
        logs.push(log);
    }
}
}
