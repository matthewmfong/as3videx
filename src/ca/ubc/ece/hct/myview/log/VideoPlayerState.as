/**
 * Created by iDunno on 2018-02-05.
 */
package ca.ubc.ece.hct.myview.log {
public class VideoPlayerState {
    public var videoID:int;
    public var videoFilename:String;
    public var play_state:Boolean;
    public var playback_time:Number;
    public var playback_rate:Number;
    public var selection_start:Number;
    public var selection_end:Number;
    public var active_highlight_colour:Number;
    public var highlight_write_mode:String;
    public var highlight_read_mode:int;
    public var view_count_read_mode:int;
    public var pause_record_read_mode:int;
    public var playback_rate_read_mode:int;
}
}
