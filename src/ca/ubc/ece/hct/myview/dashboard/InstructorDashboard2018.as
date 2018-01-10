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
        flexLayer.playlistShit.addChild(playlistView);

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

    private function grabActiveUsers():void {
        var asdf:Number = getTimer();

        var now:Date = new Date();
        var thisMonth:Date = new Date();
        thisMonth.date = 1;
        thisMonth.hours = 0;
        thisMonth.minutes = 0;
        thisMonth.seconds = 0;
        var lastWeek:Date = new Date();
        lastWeek.date -= 7;
        lastWeek.hours = 0;
        lastWeek.minutes = 0;
        lastWeek.seconds = 0;
        var yesterday:Date = new Date();
        yesterday.date -= 1;
        yesterday.hours = 0;
        yesterday.minutes = 0;
        yesterday.seconds = 0;
        var today:Date = new Date();
        today.hours = 0;
        today.minutes = 0;
        today.seconds = 0;

        data = new ArrayCollection();


        ServerDataLoader.getActiveUsers(today, now).add(
                function (o:*, from:Date, to:Date):void {
                    var obj:* = JSON.parse((String)(o));
                    trace("Today: " + obj.length + " " + (getTimer() - asdf));

                    data.addItem({time: "Today", numUsers: obj.length});


                    ServerDataLoader.getActiveUsers(yesterday, today).add(
                            function (o:*, from:Date, to:Date):void {
                                var obj:* = JSON.parse((String)(o));
                                trace("Yesterday: " + obj.length + " " + (getTimer() - asdf));

                                data.addItem({time: "Yesterday", numUsers: obj.length});

                                ServerDataLoader.getActiveUsers(lastWeek, now).add(
                                        function (o:*, from:Date, to:Date):void {
                                            var obj:* = JSON.parse((String)(o));
                                            trace("Last Week: " + obj.length + " " + (getTimer() - asdf));

                                            data.addItem({time: "Last Week", numUsers: obj.length});

                                            ServerDataLoader.getActiveUsers(thisMonth, now).add(
                                                    function (o:*, from:Date, to:Date):void {
                                                        var obj:* = JSON.parse((String)(o));
                                                        trace("This Month: " + obj.length + " " + (getTimer() - asdf));

                                                        data.addItem({time: "This Month", numUsers: obj.length});

                                                        for(var month:Number = now.month - 1; month >= course.startDate.month; month--) {

                                                            var monthStart:Date = new Date(course.startDate.fullYear, month, 1);
                                                            var monthEnd:Date = new Date(course.startDate.fullYear, month+1, 1);

                                                            ServerDataLoader.getActiveUsers(monthStart, monthEnd).add(
                                                                    function (o:*, from:Date, to:Date):void {
                                                                        var obj:* = JSON.parse((String)(o));
                                                                        trace(Util.monthNumber2String(from.month+1) + ": " + obj.length + " " + (getTimer() - asdf));

                                                                        data.addItem({time: Util.monthNumber2String(from.month+1), numUsers: obj.length});

                                                                    }
                                                            );
                                                        }

                                                        chart();
                                                    }
                                            );
                                        }
                                );
                            }
                    );
                }
        );

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
        legend1 = new Legend();
        legend1.dataProvider = myChart;

        /* Attach chart and legend to the display list. */
        flexLayer.bingbong.addElement(myChart);
        flexLayer.bingbong.addElement(legend1);
    }

}
}
