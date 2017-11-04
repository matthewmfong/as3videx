////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylist;
import ca.ubc.ece.hct.myview.widgets.filmstrip.Filmstrip;
import ca.ubc.ece.hct.myview.widgets.filmstrip.MultiFilmstrip;
import ca.ubc.ece.hct.myview.widgets.filmstrip.SimpleFilmstrip;
import ca.ubc.ece.hct.myview.dashboard.ViewCountRecordBreakdown;

import flash.events.MouseEvent;

import flash.text.TextField;

import starling.core.Starling;

public class InstructorDashboard2018 extends View {

    private var playlist:VideoPlaylist;
    private var video:VideoMetadata;
    private var playlistView:PlaylistListView;

    public function InstructorDashboard2018() {

    }

    public function setPlaylist(playlist:VideoPlaylist):void {
        this.playlist = playlist;
        playlistView = new PlaylistListView();
        playlistView.drawPlaylist(playlist, 0, 0);
        addChild(playlistView);
        playlistView.mediaClicked.add(loadVideo);
    }

    private function loadVideo(v:VideoMetadata):void {
        trace(v.media_alias_id);
        video = v;
        VideoATFManager.loadAsyncVideoATF(video).add(thumbnailsLoaded);
    }

    private function thumbnailsLoaded(v:VideoMetadata):void {

        var filmstrip:Filmstrip = new Filmstrip();
        filmstrip.loadVideo(video);
        filmstrip.setSize(stage.stageWidth - 20, 200);

        Starling.current.stage.addChild(filmstrip);
        filmstrip.showImages();

        ServerDataLoader.getVCRsForMediaAliasID(video.media_alias_id).add(showVCR);
    }

    private function showVCR(json:Object):void {

        var obj:* = JSON.parse((String)(json));
        var entries:Array = [];

        for(var record:* in obj) {
//            trace("___" + obj[record]);
            for(var entry:* in obj[record]) {
//                trace("\t___" + entry + " " + obj[record][entry]);

                if(obj[record]["vcr"] && obj[record]["userLevel"] == "0") {
                    var stringNumbers:Array = (String)(obj[record]["vcr"]).split(",");
                    for(var i:int = 0; i<stringNumbers.length; i++) {
                        stringNumbers[i] = Number(stringNumbers[i]);
                    }
                    entries.push(stringNumbers);
                }

            }
        }

        var vcrb:ViewCountRecordBreakdown = new ViewCountRecordBreakdown();
        vcrb.width = stage.stageWidth;
        vcrb.height = 500;
//        http://animatti.ca/myview/admin/query.php?vcr&media_alias_id=221
        vcrb.draw(entries);//[ [1, 2, 3, 4, 5], [5, 4, 3, 2, 1], [1, 2, 3, 4, 5], [5, 4, 3, 2, 1], [1, 2, 3, 4, 5], [5, 4, 3, 2, 1], [1, 2, 3, 4, 5], [5, 4, 3, 2, 1]]);
        addChild(vcrb);
        vcrb.y = stage.stageHeight - 100;
    }

    public function setSize(w:Number, h:Number):void {
        _width = w;
        _height = h;

//        graphics.clear();
//        graphics.beginFill(0xcccccc);
//        graphics.drawRect(0, 0, _width, _height);
//        graphics.endFill();
    }

}
}
