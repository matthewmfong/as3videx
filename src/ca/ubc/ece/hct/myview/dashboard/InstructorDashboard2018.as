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

import flash.display.Shape;

import flash.utils.getTimer;

import mx.charts.ColumnChart;
import mx.charts.series.ColumnSeries;

import mx.collections.ArrayCollection;
import mx.charts.BarChart;
import mx.charts.series.BarSeries;
import mx.charts.CategoryAxis;
import mx.charts.Legend;
import mx.core.FlexGlobals;
import mx.events.ResizeEvent;

import starling.core.Starling;

public class InstructorDashboard2018 extends View {

    private var course:Course;
    private var playlist:VideoPlaylist;
    private var video:VideoMetadata;
    private var playlistView:PlaylistListView;
    private var data:ArrayCollection;

    private var flexLayer:Object;

    private var filmstrip:Filmstrip;

    public function InstructorDashboard2018(flexLayer:Object) {

        this.flexLayer = flexLayer;

    }

    public function setPlaylist(playlist:VideoPlaylist):void {
        this.playlist = playlist;
        playlistView = new PlaylistListView();
        playlistView.drawPlaylist(playlist, 0, 0);
        flexLayer.playlist_container.addChild(playlistView);

        course = VideoMetadataManager.COURSE;

        grabActiveUsers();

        playlistView.mediaClicked.add(loadVideo);
    }

    private function loadVideo(v:VideoMetadata):void {
        trace(v.media_alias_id);
        video = v;
        VideoATFManager.loadAsyncVideoATF(video).add(thumbnailsLoaded);
    }

    private function thumbnailsLoaded(v:VideoMetadata):void {

        filmstrip = new Filmstrip();
        filmstrip.loadVideo(v);
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
        return Util.dayNumber2String(d.day, 3) + " " + Util.monthNumber2String(d.month, 3) + "-" + d.date;
    }

    private function grabActiveUsers():void {

        data = new ArrayCollection();

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
                    trace(activeDates[i] + " " + activeUsers[i].length);
                    data.addItem({time: activeDates[i], numUsers: activeUsers[i].length });
                }

                chart();
            }
        )

    }

    public var myChart:ColumnChart;
    public var series1:ColumnSeries;
    public var series2:BarSeries;
    public var legend1:Legend;

    private function chart():void {

        myChart = new ColumnChart();
        myChart.showDataTips = true;
        myChart.dataProvider = data;

        /* Define the category axis. */
        var vAxis:CategoryAxis = new CategoryAxis();
        vAxis.categoryField = "time" ;
        vAxis.dataProvider =  data;
        myChart.horizontalAxis = vAxis;

        /* Add the series. */
        var mySeries:Array = new Array();
        series1 = new ColumnSeries();
        series1.xField="time";
        series1.yField="numUsers";
        series1.displayName = "Active Users";
        mySeries.push(series1);

//        series2 = new BarSeries();
//        series2.xField="Expenses";
//        series2.yField="Month";
//        series2.displayName = "Expenses";
//        mySeries.push(series2);

        myChart.series = mySeries;

        /* Create a legend. */
//        legend1 = new Legend();
//        legend1.dataProvider = myChart;

        /* Attach chart and legend to the display list. */
        flexLayer.activeUsers_container.addElement(myChart);
//        flexLayer.activeUsers_container.addElement(legend1);

        trace(flexLayer.activeUsers_scroller.width + "x" + flexLayer.activeUsers_scroller.height);

        myChart.width = data.length * 50;
        myChart.height = 200;

        flexLayer.activeUsers_scroller

//        flexLayer.activeUsers_container.addEventListener(mx.events.ResizeEvent.RESIZE,
//            function activeUsersResize(e:mx.events.ResizeEvent):void {
//
//
//                trace(flexLayer.activeUsers_scroller.width + "x" + flexLayer.activeUsers_scroller.height);
//
//                myChart.width = flexLayer.activeUsers_container.width;
//                myChart.height = flexLayer.activeUsers_container.height;
//            })

    }

}
}
