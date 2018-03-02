package ca.ubc.ece.hct.myview.log {

public class VideoLogCollection {

    public var videoID:Number;
    public var logs:Array;

    public function VideoLogCollection(videoID:Number) {
        this.videoID = videoID;
        logs = [];
    }

    public function addRecord(log:Log):void {
        logs.push(log);
    }

}
}