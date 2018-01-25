////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.thumbnail.ThumbnailNative;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylist;
import ca.ubc.ece.hct.myview.widgets.filmstrip.Filmstrip;

import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import mx.charts.CategoryAxis;
import mx.charts.ColumnChart;
import mx.charts.LineChart;
import mx.charts.LinearAxis;
import mx.charts.chartClasses.IAxis;
import mx.charts.events.ChartItemEvent;
import mx.charts.series.ColumnSeries;
import mx.charts.series.LineSeries;
import mx.collections.ArrayCollection;

import spark.components.Group;

import spark.core.SpriteVisualElement;
import spark.primitives.Line;

import starling.core.Starling;

public class InstructorDashboard2018 extends View {

    private var course:Course;
    private var playlist:VideoPlaylist;
    private var video:VideoMetadata;
    private var playlistView:PlaylistListView;

    private var activeUsersData:ArrayCollection;
    private var activeUsersChart:ColumnChart;
    private var activeUsersSeries:ColumnSeries;

    private var recentMediaData:Array;

    private var flexLayer:Object;
    private var filmstrip:Filmstrip;

    private var dependentFunctionArray:Array;
    private var dependentFunctionArrayCounter:Number = 0;

    public function InstructorDashboard2018(flexLayer:Object) {

        this.flexLayer = flexLayer;

        course = VideoMetadataManager.COURSE;

        dependentFunctionArray = [updateLatestVCRs, grabRecentMedia];
        callNextDependentFunction();

        grabActiveUsers();

    }

    private function callNextDependentFunction():void {
        dependentFunctionArray[dependentFunctionArrayCounter++]();
    }

    public function setPlaylist(playlist:VideoPlaylist):void {
        this.playlist = playlist;
        playlistView = new PlaylistListView();
        playlistView.drawPlaylist(playlist, 0, 0);
        flexLayer.playlist_container.addChild(playlistView);

        playlistView.mediaClicked.add(loadVideo);
    }

    private function loadVideo(v:VideoMetadata):void {
        trace(v.media_alias_id);
        video = v;
//        VideoATFManager.loadAsyncVideoATF(video).add(thumbnailsLoaded);
    }

    private function thumbnailsLoaded(v:VideoMetadata):void {

//        filmstrip = new Filmstrip();
//        filmstrip.loadVideo(v);
//        filmstrip.setSize(stage.stageWidth - 20, 200);
//
//        Starling.current.stage.addChild(filmstrip);
//        filmstrip.showImages();
//
//        ServerDataLoader.getVCRsForMediaAliasID(video.media_alias_id).add(showVCR);
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

//        var vcrb:ViewCountRecordBreakdown = new ViewCountRecordBreakdown();
//        vcrb.width = stage.stageWidth;
//        vcrb.height = 500;
////        http://animatti.ca/myview/admin/query.php?vcr&media_alias_id=221
//        vcrb.draw(entries);//[ [1, 2, 3, 4, 5], [5, 4, 3, 2, 1], [1, 2, 3, 4, 5], [5, 4, 3, 2, 1], [1, 2, 3, 4, 5], [5, 4, 3, 2, 1], [1, 2, 3, 4, 5], [5, 4, 3, 2, 1]]);
//        addChild(vcrb);
//        vcrb.y = stage.stageHeight - 100;

        var urv:UserRecordsVisualizer = new UserRecordsVisualizer(stage.stageWidth - 40, stage.stageHeight - filmstrip.height - 20);
        addChild(urv);
        urv.x = 20;
        urv.y = filmstrip.height;
        urv.loadVideo(video);

    }

    public function setSize(w:Number, h:Number):void {
        _width = w;
        _height = h;
    }

    private function date2daymonthdate(d:Date):String {
        return Util.dayNumber2String(d.day, 3) + "\n" + Util.monthNumber2String(d.month, 3) + "-" + d.date;
    }

    private function grabActiveUsers():void {

        activeUsersData = new ArrayCollection();

        var activeDates:Array = [];
        var activeUsers:Array = [];

        var insertDate:Date = course.startDate;
        var todayDate:Date = new Date();
        while(insertDate.getTime() < todayDate.getTime() + Constants.DAYS2MILLISECONDS) {

            activeDates.push(date2daymonthdate(insertDate));
            activeUsers.push([]);

            insertDate.setTime(insertDate.getTime() + Constants.DAYS2MILLISECONDS);
        }

        ServerDataLoader.getActiveUsers().add(
            function consolidateActiveUsers(o:*):void {
                var entries:* = JSON.parse((String)(o));

                for (var id:* in entries){
                    var entry:* = entries[id];

                    // see if that date already exists
                    var date:Date = Util.dateParser((String)(entry["date"]));
                    date.setTime(date.getTime() + Constants.SERVER_TO_LOCAL_TIME_DIFF * Constants.HOURS2MILLISECONDS);

                    // split "2018-01-01 00:00:00" into "2018-01-01" and "00:00:00" ~ get the date only.
                    var dateString:String = date2daymonthdate(date);

                    var user:Number = Number((String)(entry["user"]));

                    var indexOfDate:int = Util.looseIndexOf(activeDates, dateString);

                    if(indexOfDate == -1) {
                        // date does not yet exist
                        activeDates.push(dateString);
                        activeUsers.push([user]);

                    } else {
                        // date found, let's add users.

                        if(Util.looseIndexOf(activeUsers[indexOfDate], user) == -1) {
                            // did not find user
                            activeUsers[indexOfDate].push(user);
                        }

                        // otherwise the user has already been added. do nothing :D
                    }

                }

                for(var i:int = 0; i<activeDates.length; i++) {
//                    trace(activeDates[i] + " " + activeUsers[i].length);
                    activeUsersData.addItem({time: activeDates[i], numUsers: activeUsers[i].length });
                }

                chartActiveUsers();
            }
        )

    }

    private function chartActiveUsers():void {

        activeUsersChart = new ColumnChart();
        activeUsersChart.showDataTips = true;
        activeUsersChart.dataProvider = activeUsersData;

        /* Define the category axis. */
        var vAxis:CategoryAxis = new CategoryAxis();
        vAxis.categoryField = "time" ;
        vAxis.dataProvider =  activeUsersData;
        activeUsersChart.horizontalAxis = vAxis;

        /* Add the series. */
        var mySeries:Array = new Array();
        activeUsersSeries = new ColumnSeries();
        activeUsersSeries.xField="time";
        activeUsersSeries.yField="numUsers";
        activeUsersSeries.displayName = "Active Users";
        mySeries.push(activeUsersSeries);

        activeUsersChart.series = mySeries;

        /* Create a legend. */
//        legend1 = new Legend();
//        legend1.dataProvider = activeUsersChart;

        /* Attach chart and legend to the display list. */
        flexLayer.activeUsers_container.addElement(activeUsersChart);
//        flexLayer.activeUsers_container.addElement(legend1);

        activeUsersChart.width = activeUsersData.length * 50;
        activeUsersChart.height = flexLayer.activeUsers_container.height;

//        flexLayer.activeUsers_scroller

    }

    private function grabRecentMedia():void {

        recentMediaData = [];

        var fiveDaysAgo:Date = new Date();
        fiveDaysAgo.setTime(fiveDaysAgo.getTime() - 5 * Constants.DAYS2MILLISECONDS);
        ServerDataLoader.getRecentMedia(fiveDaysAgo ,new Date()).add(
                function recentMediaProcess(o:*):void {
                    var entries:* = JSON.parse((String)(o));

                    for (var id:* in entries){
                        var entry:* = entries[id];

                        recentMediaData.push(
                                {
                                    video: VideoMetadataManager.getVideo(entry['media_id'] + "-" + entry['filename']),
                                    count: entry['count']
                                });

                    }

                    var recentMediaLayout:RecentMedia = new RecentMedia();
                    recentMediaLayout.width = flexLayer.mainContent.width;
                    recentMediaLayout.height = flexLayer.mainContent.height;
                    flexLayer.mainContent.addElement(recentMediaLayout);

                    for each(var o:Object in recentMediaData) {

//                        trace(o.video.id + " " + o.video.media_alias_id + " " + o.video.title);

                        var recentMediaItem:RecentMediaItem = new RecentMediaItem();
                        recentMediaItem.init(o);

                        recentMediaLayout.main.addElement(recentMediaItem);
                        recentMediaItem.width = recentMediaLayout.width;

                    }

                }
        );
    }

    private function updateLatestVCRs():void {

        ServerDataLoader.getVCRsForMediaAliasIDs(VideoMetadataManager.getAllMediaAliasIDs().toString()).add(
                function vcrsLoaded(o:*):void {
                    var obj:* = JSON.parse((String)(o));

                    for(var record:String in obj) {

                        if(obj.hasOwnProperty(record)) {
                            var videoFilenameString:String = obj[record]['media_id'] + "-" + obj[record]['filename'];
                            var video:VideoMetadata = VideoMetadataManager.getVideo(videoFilenameString);

                            var userData:UserData = new UserData();
                            userData.view_count_record = obj[record]['vcr'];
                            userData.userString = obj[record]['user'];

                            video.addCrowdUserData(UserData.CLASS, userData);
                        }

                    }

                    callNextDependentFunction();
                }
        )

    }

}
}
