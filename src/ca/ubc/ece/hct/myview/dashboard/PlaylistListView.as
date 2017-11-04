/**
 * Created by iDunno on 2017-11-01.
 */
package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.myview.View;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylist;

import flash.events.MouseEvent;

import flash.text.TextField;

import org.osflash.signals.Signal;

public class PlaylistListView extends View {

    private var textFields:Vector.<TextField>;
    public var mediaClicked:Signal;

    public function PlaylistListView() {
        mediaClicked = new Signal(VideoMetadata);
    }

    public function drawPlaylist(playlist:VideoPlaylist, xOffset:Number, yOffset:Number):void {

        textFields = new Vector.<TextField>();

        var playlistText:TextField = new TextField();
        playlistText.autoSize = "center";
        playlistText.text = playlist.listName;
        addChild(playlistText);
        playlistText.x = xOffset * 10;
        playlistText.y = yOffset += playlistText.height;
        textFields.push(playlistText);

        for(var i:int = 0; i<playlist.mediaList.length; i++) {

            if(playlist.mediaList[i] is VideoPlaylist) {

                drawPlaylist(playlist.mediaList[i], xOffset + 1, yOffset);
                yOffset = textFields[textFields.length - 1].y + textFields[textFields.length - 1].height;

            } else if(playlist.mediaList[i] is VideoMetadata) {

                var mediaText:Media = new Media();
                mediaText.autoSize = "center";
                mediaText.text = (VideoMetadata)(playlist.mediaList[i]).title;
                addChild(mediaText);
                mediaText.x = xOffset * 10 + 5;
                mediaText.y = yOffset += mediaText.height;
                mediaText.video = playlist.mediaList[i];
                textFields.push(mediaText);
            }
        }

        addEventListener(MouseEvent.CLICK, clickedMedia, true);
    }

    private function clickedMedia(e:MouseEvent):void {
        if(e.target is Media) {
            e.stopPropagation();
            mediaClicked.dispatch(e.target.video);
        }
    }
}
}

import ca.ubc.ece.hct.myview.video.VideoMetadata;
import flash.text.TextField;

class Media extends TextField {

    public var video:VideoMetadata;
}