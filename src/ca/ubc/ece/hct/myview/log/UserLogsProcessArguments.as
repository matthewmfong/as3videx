/**
 * Created by iDunno on 2018-02-04.
 */
/**
 * Created by iDunno on 2017-04-09.
 */
package ca.ubc.ece.hct.myview.log {
import flash.filesystem.File;
import flash.utils.ByteArray;

[RemoteClass(alias="ca.ubc.ece.hct.myview.UserLogsProcessArguments")]

public class UserLogsProcessArguments {

    public var byteArray:ByteArray;
    public var dbPath:String;

    public function UserLogsProcessArguments(dbPath:String = null, byteArray:ByteArray=null):void {

        this.byteArray = byteArray;
        this.dbPath = dbPath;

//        trace("____________________________________________")
//        trace("new UserLogsProcessArguments()" + " " + dbPath);
//        trace(new Error().getStackTrace());
//        trace("____________________________________________")

    }
}
}

