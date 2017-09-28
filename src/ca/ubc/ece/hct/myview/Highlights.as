/**
 * Created by iDunno on 2017-01-25.
 */
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.Range;

public class Highlights {

    public var colour:uint;
    public var intervals:Array;

    public function Highlights(colour:uint) {

        this.colour = colour;
        intervals = [];
    }

    public function toString():String {

        var retString:String = "";

        for (var i:int = 0; i < intervals.length; i++) {
            if (i != 0) {
                retString += "|";
            }
            retString += intervals[i].start + "," + intervals[i].end;
        }
        return retString;
    }

    public function getString():String {
        var retString:String = "#" + colour.toString(16) + ": ";

        retString += intervals;

        return retString;
    }
}
}
