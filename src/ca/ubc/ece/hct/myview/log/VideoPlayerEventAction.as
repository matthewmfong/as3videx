/**
 * Created by iDunno on 2018-02-08.
 */
package ca.ubc.ece.hct.myview.log {
public class VideoPlayerEventAction {

    public static const STOP:uint = 1;
    public static const PLAY:uint = 2;
    public static const SEEK:uint = 3;
    public static const REACHED_END_OF_VIDEO:uint = 4;
    public static const RESIZE_PAUSE_VIDEO:uint = 5;
    public static const RESIZE_RESUME_VIDEO:uint = 6;
    public static const HIGHLIGHT:uint = 7;
    public static const DESELECT:uint = 8;
    public static const SET_PLAYBACK_RATE:uint = 8;
    public static const SET_FULLSCREEN:uint = 10;
    public static const SET_CC:uint = 11;
    public static const SET_HIGHLIGHT_WRITE_MODE:uint = 12;
    public static const UNHIGHLIGHT:uint = 13;
    public static const PLAY_HIGHLIGHTS:uint = 14;
    public static const STOP_PLAYING_HIGHLIGHTS:uint = 15;
    public static const SET_HIGHLIGHT_READ_MODE:uint = 16;
    public static const SET_VIEW_COUNT_RECORD_READ_MODE:uint = 17;
    public static const SET_PAUSE_RECORD_READ_MODE = 18;
    public static const SET_PLAYBACK_RATE_RECORD_READ_MODE = 19;
    public static const SEARCHTEXT:uint = 20;
    public static const SELECT:uint = 21;

    public static function string2uint(action:String):int {
        var id:int = -1;
        switch(action) {
            case "stop":
                id = STOP;
                break;
            case "play":
                id = PLAY;
                break;
            case "seek":
                id = SEEK;
                break;
            case "reachedEndOfVideo":
                id = REACHED_END_OF_VIDEO;
                break;
            case "resize_pause_video":
                id = RESIZE_PAUSE_VIDEO;
                break;
            case "resize_resume_video":
                id = RESIZE_RESUME_VIDEO;
                break;
            case "highlight":
                id = HIGHLIGHT;
                break;
            case "deselect":
                id = DESELECT;
                break;
            case "set_playback_rate":
                id = SET_PLAYBACK_RATE;
                break;
            case "set_fullscreen":
                id = SET_FULLSCREEN;
                break;
            case "set_cc":
                id = SET_CC;
                break;
            case "set_highlight_write_mode":
                id = SET_HIGHLIGHT_WRITE_MODE;
                break;
            case "unhighlight":
                id = UNHIGHLIGHT;
                break;
            case "play_highlights":
                id = PLAY_HIGHLIGHTS;
                break;
            case "stop_playing_highlights":
                id = STOP_PLAYING_HIGHLIGHTS;
                break;
            case "set_highlight_read_mode":
                id = SET_HIGHLIGHT_READ_MODE;
                break;
            case "set_view_count_record_read_mode":
                id = SET_VIEW_COUNT_RECORD_READ_MODE;
                break;
            case "set_pause_record_read_mode":
                id = SET_PAUSE_RECORD_READ_MODE;
                break;
            case "set_playback_rate_record_read_mode":
                id = SET_PLAYBACK_RATE_RECORD_READ_MODE;
                break;
            case "searchText":
                id = SEARCHTEXT;
                break;
            case "select":
                id = SELECT;
                break;

        }

        return id;
    }
}
}
