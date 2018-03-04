////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.log.UserLogsLoader;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylist;
import ca.ubc.ece.hct.myview.widgets.filmstrip.Filmstrip;

import flash.display.DisplayObjectContainer;

import mx.charts.CategoryAxis;
import mx.charts.ColumnChart;
import mx.charts.series.ColumnSeries;
import mx.collections.ArrayCollection;
import mx.controls.ProgressBar;
import mx.events.ResizeEvent;

import spark.components.Group;
import spark.components.Panel;
import spark.components.Scroller;
import spark.components.SkinnableContainer;
import spark.core.SpriteVisualElement;

public class InstructorDashboard2018Class extends SkinnableContainer {

    private var course:Course;
    private var playlist:VideoPlaylist;
    private var video:VideoMetadata;
    private var playlistView:PlaylistListView;

    public static var userLogLoader:UserLogsLoader;

    override public function get parent():DisplayObjectContainer { return super.parent };

    [Bindable]
    public var playlistView_container:SpriteVisualElement;

    [Bindable]
    public var activeUsers_container:Group;
    private var activeUsersData:ArrayCollection;

    [Bindable]
    public var activeUsersChart:ColumnChart;
    private var activeUsersSeries:ColumnSeries

    [Bindable]
    public var activeUsers_scroller:Scroller;

    private var recentMediaData:Array;

    [Bindable]
    public var mainContent_container:Group;
    [Bindable]
    public var mainContent_panel:Panel;

    [Bindable]
    public var progressBar:ProgressBar;
    private var filmstrip:Filmstrip;

    private var videoStats:VideoStats;

    private var dependentFunctionArray:Array;
    private var dependentFunctionArrayCounter:Number = 0;

    public function InstructorDashboard2018Class() {

        super();

        playlistView_container = new SpriteVisualElement();
        mainContent_panel = new Panel();
        mainContent_container = new Group();
        activeUsers_container = new Group();
        activeUsers_scroller = new Scroller();
        progressBar = new ProgressBar();

    }

    public function creationCompleteHandler():void {

        graphics.beginFill(0x00ff00);
        graphics.drawRect(0, 0, 100, 100);
        graphics.endFill();


        userLogLoader = new UserLogsLoader();
        userLogLoader.freezeSignal.add(
                function userLogFreeze():void {
//                    trace("FREEZE");
                    progressBar.setProgress(0.8, 1);
//                    trace("FREEZE2?")
                }
        );
        userLogLoader.progressSignal.add(
                function userLogProgress(current:Number, total:Number):void {
//                    trace("PROGRESS");
                    progressBar.setProgress(current*0.8/total, 1);
                }
        );
        userLogLoader.completeSignal.add(
                function userLogComplete():void {
//                    trace("COMPLETE");
                    progressBar.setProgress(1, 1);
//                    startLogQueries();


//                    removeElement(progressBar);
                }
        );
        userLogLoader.load();


        course = VideoMetadataManager.COURSE;

        dependentFunctionArray = [updateLatestVCRs, grabRecentMedia];
        callNextDependentFunction();

        grabActiveUsers();

        playlistView_container.addChild(playlistView);
    }

    private function callNextDependentFunction():void {
        dependentFunctionArray[dependentFunctionArrayCounter++]();
    }

    public function setPlaylist(playlist:VideoPlaylist):void {
        playlistView = new PlaylistListView();
        playlistView.drawPlaylist(playlist, 0, 0);

        playlistView.mediaClicked.add(loadVideo);
    }

    private function loadVideo(v:VideoMetadata):void {

//        trace("END HERE_________________________");
//        trace(VideoMetadataManager.COURSE.startDate + " --> " + VideoMetadataManager.COURSE.endDate)

//        trace(v.media_alias_id);
        video = v;
        videoStats = new VideoStats();
        videoStats.db = userLogLoader;
        videoStats.video = v;

        mainContent_panel.title = v.title;
        mainContent_container.removeAllElements();
        mainContent_container.addElement(videoStats);

//        VideoATFManager.loadAsyncVideoATF(video).add(thumbnailsLoaded);
    }

    private function thumbnailsLoaded(v:VideoMetadata):void {

//        filmstrip = new Filmstrip();
//        filmstrip.loadVideo(v);
//        filmstrip.setSize(stage.stageWidth - 20, 200);
//
//        Starling.current.stage.addChild(filmstrip);
//        filmstrip.showImages();
////
//        ServerDataLoader.getVCRsForMediaAliasID(video.media_alias_id).add(showVCR);
    }

//    private var urv:UserRecordsVisualizer;

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

//        addChild(urv);
//        urv.x = 20;
//        urv.y = filmstrip.height;

        mainContent_container.addEventListener(ResizeEvent.RESIZE, resizeMainContent);

        var spr:SpriteVisualElement = new SpriteVisualElement();
        spr.width = mainContent_container.width;
        spr.height = mainContent_container.height;
        mainContent_container.removeAllElements();
        mainContent_container.addElement(spr);


//        urv = new UserRecordsVisualizer(spr.width, spr.height);
//
//        spr.addChild(urv);
//        urv.loadVideo(video);

        function resizeMainContent(e:ResizeEvent):void {
//            urv.set
        }

    }

    private function date2daymonthdate(d:Date):String {
        return Util.dayNumber2String(d.day, 3) + "\n" + Util.monthNumber2String(d.month, 3) + "-" + d.date;
    }

    private function grabActiveUsers():void {

        activeUsersData = new ArrayCollection();

        var activeDates:Array = [];
        var activeUsers:Array = [];

        var insertDate:Date = new Date(course.startDate.getTime());
        var todayDate:Date = new Date();
        while(insertDate.getTime() < todayDate.getTime() + Constants.DAYS2MILLISECONDS) {

            activeDates.push(date2daymonthdate(insertDate));
            activeUsers.push([]);

            insertDate.setTime(insertDate.getTime() + Constants.DAYS2MILLISECONDS);
        }

        ServerDataLoader.getActiveUsers().add(consolidateActiveUsers);

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

            activeUsers_container.horizontalScrollPosition = 1000;//activeUsers_scroller.width - activeUsersChart.width;
        }

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
        var mySeries:Array = [];
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
        activeUsers_container.addElement(activeUsersChart);
//        flexLayer.activeUsers_container.addElement(legend1);

        activeUsersChart.width = activeUsersData.length * 50;
        activeUsersChart.height = activeUsers_container.height;

    }

    private function grabRecentMedia():void {

        recentMediaData = [];

        var fiveDaysAgo:Date = new Date();
        fiveDaysAgo.setTime(fiveDaysAgo.getTime() - 5 * Constants.DAYS2MILLISECONDS);
        ServerDataLoader.getRecentMedia(fiveDaysAgo ,new Date()).add(recentMediaProcess);
    }

    private function recentMediaProcess(o:*):void {
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
//        recentMediaLayout.addEventListener(FlexEvent.INITIALIZE,
//            function recentMediaLayoutInit(e:FlexEvent):void {
//
//                var rml:RecentMedia = (RecentMedia)(e.target);
//
////                rml.width = mainContent_container.width;
////                rml.height = mainContent_container.height;
//
////                trace(rml.scroller.width + " " + rml.scroller.height);
//
//            });
        for each(var o:Object in recentMediaData) {

            var recentMediaItem:RecentMediaItem = new RecentMediaItem();
//            trace(recentMediaItem.percentWidth);
            recentMediaItem.content = o;

            recentMediaLayout.main.addElement(recentMediaItem);

        }
        mainContent_container.addElement(recentMediaLayout);
        mainContent_panel.title = "Recently viewed videos";



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
