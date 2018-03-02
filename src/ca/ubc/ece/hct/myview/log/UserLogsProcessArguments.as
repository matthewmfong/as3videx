/**
 * Created by iDunno on 2018-02-04.
 */
/**
 * Created by iDunno on 2017-04-09.
 */
package ca.ubc.ece.hct.myview {
import flash.utils.ByteArray;

[RemoteClass(alias="ca.ubc.ece.hct.myview.UserLogsProcessArguments")]

public class UserLogsProcessArguments {

    public var byteArray:ByteArray;

    public function UserLogsProcessArguments(byteArray:ByteArray = null):void {

        this.byteArray = byteArray;
    }
}
}

