package ca.ubc.ece.hct.myview {
public class PauseLocationAndDate {
    public var time:Number = 0;
    public var date:Date;

    public function PauseLocationAndDate(time:Number, date:Date):void {
        this.time = time;
        this.date = date;
    }

    public function toString():String {
        return time.toString();
    }
}
}
