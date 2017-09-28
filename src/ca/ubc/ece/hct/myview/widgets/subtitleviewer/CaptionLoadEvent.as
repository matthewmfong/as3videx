/**
 * Created by Joseph Labrecque on 12/10/2014.
 */
package ca.ubc.ece.hct.myview.widgets.subtitleviewer {
import flash.events.Event;

public class CaptionLoadEvent extends Event {
    public static const LOADED:String = "onLoaded";
    public static const ERROR:String = "onError";
    public function CaptionLoadEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
        super(type, bubbles, cancelable);
    }
}
}
