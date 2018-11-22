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
import ca.ubc.ece.hct.myview.ui.UIScrollView;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylist;
import ca.ubc.ece.hct.myview.widgets.filmstrip.Filmstrip;

import com.doublefx.as3.thread.Thread;
import com.doublefx.as3.thread.util.ThreadRunnerX;

import flash.display.DisplayObjectContainer;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.Mouse;
import flash.ui.MouseCursor;

import mx.charts.CategoryAxis;
import mx.charts.ColumnChart;
import mx.charts.series.ColumnSeries;
import mx.collections.ArrayCollection;
import mx.controls.ProgressBar;
import mx.core.FlexSprite;
import mx.events.ResizeEvent;
import mx.formatters.DateFormatter;
import mx.managers.PopUpManager;

import spark.components.Group;
import spark.components.HGroup;
import spark.components.Label;
import spark.components.Panel;
import spark.components.Scroller;
import spark.components.SkinnableContainer;
import spark.components.SkinnablePopUpContainer;
import spark.components.TextArea;
import spark.components.TileGroup;
import spark.components.VGroup;
import spark.core.SpriteVisualElement;
import spark.formatters.DateTimeFormatter;
import spark.layouts.HorizontalLayout;
import spark.layouts.VerticalLayout;

public class InstructorDashboard2018Class extends SkinnableContainer {

    private var course:Course;
    private var playlist:VideoPlaylist;
    private var video:VideoMetadata;
//    private var playlistView:PlaylistListView;
//    private var uiscroller:UIScrollView;

    public static var userLogLoader:UserLogsLoader;

    override public function get parent():DisplayObjectContainer { return super.parent };

    [Bindable]
    public var playlistView_container:SpriteVisualElement;
    public var playlist_Panel:Panel;

    [Bindable]
    public var users_Panel:Panel;
    public var activity_Panel:Group;

    private var activeUsersData:ArrayCollection;

    private var recentMediaData:Array;

    [Bindable]
    public var progressBar:ProgressBar;
    private var filmstrip:Filmstrip;

    [Bindable]
    private var recentMediaLayout:RecentMedia;

    [Bindable]
    public var mainTileGroup:TileGroup;

    [Bindable]
    public var summary_Group:Group;

    private var videoStats:VideoStats;

    private var dependentFunctionArray:Array;
    private var dependentFunctionArrayCounter:Number = 0;

    private var dateFormatter:DateTimeFormatter;

    [Bindable]
    public var main_Container:SkinnableContainer;

    [Bindable]
    public var main_HGroup:HGroup;

    [Bindable]
    public var videoStats_Group:Group;

    public function InstructorDashboard2018Class() {

        super();

        playlist_Panel = new Panel();
        playlistView_container = new SpriteVisualElement();
        activity_Panel = new Group();
//        mainContent_panel = new Panel();
//        mainContent_container = new Group();
//        activeUsers_container = new Group();
//        activeUsers_scroller = new Scroller();
        progressBar = new ProgressBar();

//        summary_Panel = new Panel();

        recentMediaLayout = new RecentMedia();

        mainTileGroup = new TileGroup();

        dateFormatter = new DateTimeFormatter();
        dateFormatter.dateTimePattern = "EE MMM d, yyyy";

    }

    public function creationCompleteHandler():void {

        main_Container.removeElement(videoStats_Group);

//        graphics.beginFill(0x00ff00);
//        graphics.drawRect(0, 0, 100, 100);
//        graphics.endFill();


        userLogLoader = new UserLogsLoader();
//        userLogLoader.freezeSignal.add(
//                function userLogFreeze():void {
//                    progressBar.setProgress(0.8, 1);
//                }
//        );
        userLogLoader.progressSignal.add(
                function userLogProgress(current:Number, total:Number):void {
                    progressBar.setProgress(current/total, 1);
                }
        );
        userLogLoader.completeSignal.add(
                function userLogComplete():void {
                    progressBar.setProgress(1, 1);
                }
        );
        userLogLoader.statusSignal.add(
                function userLogStatus(s:String):void {
                    progressBar.label = s;
                }
        )
        userLogLoader.load();

        course = VideoMetadataManager.COURSE;

        dependentFunctionArray = [updateLatestVCRs, getLastViewed, showMostPopularVideos];
        callNextDependentFunction();

        grabActiveUsers();
        getUsers();

//        uiscroller = new UIScrollView(playlist_Panel.width, playlist_Panel.height - 20);
//        uiscroller.source = playlistView;
//
//
//        playlistView_container.addChild(uiscroller);
//        uiscroller.update();
    }

    private function callNextDependentFunction():void {
        if(dependentFunctionArrayCounter < dependentFunctionArray.length)
            dependentFunctionArray[dependentFunctionArrayCounter++]();
    }

    public function setPlaylist(playlist:VideoPlaylist):void {
//        playlistView = new PlaylistListView();
//        playlistView.drawPlaylist(playlist, 0, 0);
//
//
//        playlistView.mediaClicked.add(loadVideo);
    }

    private function loadVideo(v:VideoMetadata):void {

//        trace("END HERE_________________________");
//        trace(VideoMetadataManager.COURSE.startDate + " --> " + VideoMetadataManager.COURSE.endDate)

//        trace(v.media_alias_id);
        video = v;
        videoStats = new VideoStats();
        videoStats.db = userLogLoader;
        videoStats.video = v;
        videoStats.addEventListener("exit",
                function videoStatsExit(e:Event):void {
                    main_Container.removeElement(videoStats_Group);
                    main_Container.addElementAt(main_HGroup, 0);
                    videoStats = null;
                });

//        mainContent_panel.title = v.title;
//        mainContent_container.removeAllElements();
//        mainContent_container.addElement(videoStats);

        main_Container.removeElement(main_HGroup);
        main_Container.addElementAt(videoStats_Group, 0);
        videoStats_Group.addElement(videoStats);

        VideoATFManager.loadAsyncVideoATF(video).add(thumbnailsLoaded);
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

//        mainContent_container.addEventListener(ResizeEvent.RESIZE, resizeMainContent);
//
//        var spr:SpriteVisualElement = new SpriteVisualElement();
//        spr.width = mainContent_container.width;
//        spr.height = mainContent_container.height;
//        mainContent_container.removeAllElements();
//        mainContent_container.addElement(spr);


//        urv = new UserRecordsVisualizer(spr.width, spr.height);
//
//        spr.addChild(urv);
//        urv.loadVideo(video);

        function resizeMainContent(e:ResizeEvent):void {
//            urv.set
        }

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

//            activeUsers_container.horizontalScrollPosition = 1000;//activeUsers_scroller.width - activeUsersChart.width;
        }

    }

    private function chartActiveUsers():void {

        var textfield:Label = new Label();
//        textfield.height = mainTileGroup.height;
        textfield.text = "Active Users\n";
        for(var i:int = activeUsersData.length-1; i>0; i--) {
            textfield.text += activeUsersData[i].time + ":\t" + activeUsersData[i].numUsers + "\n";
        }

        activity_Panel.addElement(textfield);

    }

//    private function grabRecentMedia():void {
//
//        recentMediaData = [];
//
//        var twoWeeks:Date = new Date();
//        twoWeeks.setTime(twoWeeks.getTime() - 14 * Constants.DAYS2MILLISECONDS);
//        ServerDataLoader.getRecentMedia(twoWeeks, new Date()).add(recentMediaProcess);
//    }


//    private function recentMediaProcess(o:*):void {
//        var entries:* = JSON.parse((String)(o));
//
//        for (var id:* in entries){
//            var entry:* = entries[id];
//
//            recentMediaData.push(
//                    {
//                        video: VideoMetadataManager.getVideo(entry['media_id'] + "-" + entry['filename']),
//                        count: entry['count']
//                    });
//
//        }
//
//        recentMediaLayout = new RecentMedia();
////        recentMediaLayout.addEventListener(FlexEvent.INITIALIZE,
////            function recentMediaLayoutInit(e:FlexEvent):void {
////
////                var rml:RecentMedia = (RecentMedia)(e.target);
////
//////                rml.width = mainContent_container.width;
//////                rml.height = mainContent_container.height;
////
//////                trace(rml.scroller.width + " " + rml.scroller.height);
////
////            });
//
//        var textField:TextArea = new TextArea();
//        textField.text = "Recently Viewed Videos\n";
//        recentMediaLayout.main.addElement(textField);
//        for each(var o:Object in recentMediaData) {
//            textField.text += (VideoMetadata)(o.video).title + " - " + o.count + " views\n";
//
////            var recentMediaItem:RecentMediaItem = new RecentMediaItem();
////            recentMediaItem.content = o;
//
////            recentMediaLayout.main.addElement(recentMediaItem);
//
//        }
//        mainTileGroup.addElement(recentMediaLayout);
////        mainContent_panel.title = "Recently viewed videos";
//
//
//        callNextDependentFunction();
//
//    }

    private function getUsers():void {

        ServerDataLoader.getUsers().add(
            function gotUsers(o:*):void {

                var vgroup:VGroup = new VGroup();
                var hgroup:HGroup = new HGroup();

                vgroup.addElement(hgroup);

                var users:Label = new Label();
                var lastLogin:Label = new Label();
                var dateRegistered:Label = new Label();

                hgroup.addElement(users);
                hgroup.addElement(lastLogin);
                hgroup.addElement(dateRegistered);

                var entries:* = JSON.parse((String)(o));

//                    var usersArray:Array = [];

                users.text = "Users\n";
                lastLogin.text = "Last Login\n";
                dateRegistered.text = "Date Registered\n";

                for (var id:* in entries){
                    var entry:* = entries[id];

//                        usersArray.push(entry['userstring']);

                    var lastLoginString:String = entry['lastlogin'] == null ?
                            dateFormatter.format(Util.dateParser(entry['dateregistered'])) :
                            dateFormatter.format(Util.dateParser(entry['lastlogin']));

                    users.text += entry['userstring'].substr(28, 5) + "...\n";
                    lastLogin.text += lastLoginString + "\n";
                    dateRegistered.text += dateFormatter.format(Util.dateParser(entry['dateregistered'])) + "\n";
                }

                var numUsers:Label = new Label();
                numUsers.text = "Total: " + entries.length + " users";

                vgroup.addElement(numUsers);

                users_Panel.addElement(vgroup);
            }
        );
    }


    const titlesWidth:Number = 400, totalsWidth:Number = 100, durationsWidth:Number = 100, usersViewedWidth:Number = 50, lastViewedWidth:Number = 100;
    private function showMostPopularVideos():void {

        var blobs:Array = [];

        var videos:Array = VideoMetadataManager.getVideos();
        for each(var video:VideoMetadata in videos) {
            var crowdvcr:Array = video.crowdUserViewCounts;
            var totalMinutesViewed:Number = 0;
            for(var i:int = 0; i<crowdvcr.length; i++) {
                totalMinutesViewed += crowdvcr[i];
            }


            var o:* =
                    {
                        video:video,
                        title:video.title,
                        total:totalMinutesViewed,
                        duration:video.duration,
                        ratio:totalMinutesViewed/video.duration,
                        usersViewed: video.grabAllClassData() != null ? video.grabAllClassData().length : 0,
                        lastLoad: video.crowdLastViewed
                    };
            blobs.push(o);

        }

        blobs.sortOn("ratio", Array.DESCENDING | Array.NUMERIC);

        var o:*;
        var today:Date = new Date();

        var vgroup:VGroup = new VGroup();
//        var titlesGroup:VGroup = new VGroup();      hgroup.addElement(titlesGroup);
//        var totalsGroup:VGroup = new VGroup();      hgroup.addElement(totalsGroup);
//        var durationGroup:VGroup = new VGroup();    hgroup.addElement(durationGroup);
//        var usersViewedGroup:VGroup = new VGroup(); hgroup.addElement(usersViewedGroup);
//        var lastViewedGroup:VGroup = new VGroup();  hgroup.addElement(lastViewedGroup);

        var titles:Label = new Label();             titles.text = "Titles";                 titles.width = titlesWidth;
        var totals:Label = new Label();             totals.text = "Total time viewed";      totals.width = totalsWidth;
        var durations:Label = new Label();          durations.text = "Duration";            durations.width = durationsWidth;
        var usersViewed:Label = new Label();        usersViewed.text = "Users viewed";      usersViewed.width = usersViewedWidth;
        var lastViewed:Label = new Label();         lastViewed.text = "Last Viewed";        lastViewed.width = lastViewedWidth;

        var headingsGroup:HGroup = new HGroup();
        headingsGroup.addElement(titles);
        headingsGroup.addElement(totals);
        headingsGroup.addElement(durations);
        headingsGroup.addElement(usersViewed);
        headingsGroup.addElement(lastViewed);

        vgroup.addElement(headingsGroup);


//        titlesGroup.addElement(titles);
//        durationGroup.addElement(durations);
//        totalsGroup.addElement(totals);
//        usersViewedGroup.addElement(usersViewed);
//        lastViewedGroup.addElement(lastViewed);

        var titlesMaxWidth:Number = 0,
                totalsMaxWidth:Number = 0,
                durationsMaxWidth:Number = 0,
                usersViewedMaxWidth:Number = 0,
                lastViewedMaxWidth:Number = 0;
        var titlesArr:Array = [],
                totalsArr:Array = [],
                durationsArr:Array = [],
                usersViewedArr:Array = [],
                lastViewedArr:Array = [];

        for(var i:int = 0; i<blobs.length; i++) {

            var wholeGroup:SkinnableContainer = new SkinnableContainer();
            wholeGroup.setStyle("backgroundColor", 0xeeeeee);
            wholeGroup.layout = new VerticalLayout();
            var pergroup:HGroup = new HGroup();

            o = blobs[i];

            var titles1:Media = new Media();
            var totals1:Label = new Label();
            var durations1:Label = new Label();
            var usersViewed1:Label = new Label();
            var lastViewed1:Label = new Label();

            titlesArr.push(titles1);
            totalsArr.push(totals1);
            durationsArr.push(durations1);
            usersViewedArr.push(usersViewed1);
            lastViewedArr.push(lastViewed1);

            titles1.setStyle("color", 0x0000ff);

            titles1.text += o.title;
            totals1.text += Util.millisecondsToHMS(o.total * 1000) + "";
            durations1.text += Util.millisecondsToHMS(o.duration * 1000) + "";
            usersViewed1.text += o.usersViewed + "";

            titles1.video = o.video;


            if(o.lastLoad == null) {
                lastViewed1.text += "Never";
            } else if(o.lastLoad.getDate() == today.getDate() &&
                    o.lastLoad.getMonth() == today.getMonth() &&
                    o.lastLoad.getFullYear() == today.getFullYear()) {
                lastViewed1.text += "Today";
            } else if(o.lastLoad.getDate() == today.getDate()-1 &&
                    o.lastLoad.getMonth() == today.getMonth() &&
                    o.lastLoad.getFullYear() == today.getFullYear()) {
                lastViewed1.text += "Yesterday"; // too lazy to add logic for yesterday of last month :P
            } else {
                lastViewed1.text += o.lastLoad == null ? "Never" : dateFormatter.format(o.lastLoad) + "";
            }


//            titles.invalidateSize();
//            titles.validateNow();
//            titlesMaxWidth = Number.max(titles1.getExplicitOrMeasuredWidth(), titlesMaxWidth);
//            totalsMaxWidth = Number.max(totals1.width, totalsMaxWidth);
//            durationsMaxWidth= Number.max(durations1.width, durationsMaxWidth);
//            usersViewedMaxWidth = Number.max(usersViewed1.width, usersViewedMaxWidth);
//            lastViewedMaxWidth = Number.max(lastViewed1.width, lastViewedMaxWidth);

            titles1.addEventListener(MouseEvent.CLICK,
                    function titleclick(e:MouseEvent):void {
                        trace(e.target.video.filename);
                        loadVideo(e.target.video);
                    });
            titles1.addEventListener(MouseEvent.ROLL_OVER,
                    function mouseOver(e:MouseEvent):void {
                        Mouse.cursor = MouseCursor.BUTTON;
                    });
            titles1.addEventListener(MouseEvent.ROLL_OUT,
                    function mouseOut(e:MouseEvent):void {
                        Mouse.cursor = MouseCursor.ARROW;
                    });

            pergroup.addElement(titles1);
            pergroup.addElement(totals1);
            pergroup.addElement(durations1);
            pergroup.addElement(usersViewed1);
            pergroup.addElement(lastViewed1);

            wholeGroup.addElement(pergroup);

            var vcr:VCRSprite = new VCRSprite(o.video.crowdUserViewCounts, 400 + 100 + 100 + 50 + 100, 50);
            wholeGroup.addElement(vcr);

//            vcr.graphics.beginFill(0x00ff00);
//            vcr.graphics.drawCircle(0, 0, 5);
//            vcr.graphics.endFill();
            vcr.width = 400 + 100 + 100 + 50 + 100;
            vcr.height = 50;
//
////            trace(o.video.crowdUserViewCounts)
//            var vcrSprite:VCRSprite = new VCRSprite(o.video.crowdUserViewCounts, 200, 50);
//            vcr.addChild(vcrSprite);
//
//            stage.addChild(vcrSprite);

//            var shape:Shape = new Shape();
//
//            shape.graphics.beginFill(0x00ff00);
//            shape.graphics.drawCircle(0, 0, 5);
//            shape.graphics.endFill();
//
//            vcr.addChild(shape);


            vgroup.addElement(wholeGroup);

        }

        summary_Group.addElement(vgroup);

        trace("titlesmaxWidth" + titlesMaxWidth)
        for(var i:int = 0; i<titlesArr.length; i++) {
            titlesArr[i].width = titlesWidth;
            totalsArr[i].width = totalsWidth;
            durationsArr[i].width = durationsWidth;
            usersViewedArr[i].width = usersViewedWidth;
            lastViewedArr[i].width = lastViewedWidth;
        }



        callNextDependentFunction();



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

    private function getLastViewed():void {

        ServerDataLoader.getMediaLastLoads(VideoMetadataManager.getAllMediaAliasIDs().toString()).add(
                function lastLoadsLoaded(o:*):void {
                    var obj:* = JSON.parse((String)(o));

                    for(var record:String in obj) {

                        if(obj.hasOwnProperty(record)) {
                            var videoFilenameString:String = obj[record]['media_id'] + "-" + obj[record]['filename'];
                            var video:VideoMetadata = VideoMetadataManager.getVideo(videoFilenameString);

                            video.crowdLastViewed = Util.dateParser(obj[record]['last_load']);
                            video.crowdUserLastViewed = obj[record]['user'];

//                            trace(video.title + " " + video.crowdLastViewed);
                        }

                    }

                    callNextDependentFunction();
                }
        )

    }

    private function date2daymonthdate(d:Date):String {
        return Util.dayNumber2String(d.day, 3) + "\t" + Util.monthNumber2String(d.month, 3) + " " + d.date;
    }

}
}

import ca.ubc.ece.hct.myview.video.VideoMetadata;

import flash.display.GradientType;

import flash.display.Shape;

import flash.display.Sprite;
import flash.geom.Matrix;

import spark.components.Label;
import spark.core.SpriteVisualElement;


class Media extends Label {

    public var video:VideoMetadata;
}

class VCRSprite extends SpriteVisualElement {

    public var _width:Number;
    public var _height:Number;

    public function VCRSprite(viewCountRecord:Array, width:Number, height:Number) {

        _width = width;
        _height = height;

        var startTime:Number = 0;
        var endTime:Number = viewCountRecord.length-1;

        var maxViewCount:Number = 1;
        for (var i:int = 0; i < viewCountRecord.length; i++) {
            if (viewCountRecord[i] > maxViewCount) {
                maxViewCount = viewCountRecord[i];
            }
        }

//        maxViewCount += 5;

        var graphMaxHeight:int = _height;

        var viewCountRecordSprite:Shape = new Shape();
        viewCountRecordSprite.graphics.clear();
        viewCountRecordSprite.graphics.beginFill(0xff0000, 0);
        viewCountRecordSprite.graphics.drawRect(0, 0, _width, graphMaxHeight);
        viewCountRecordSprite.graphics.endFill();

        var graphHeight:Number;

        var colours:Array = [0xffff00, 0xffff00, 0xffa500, 0xff0000, 0xff0000];
        var alphas:Array = [1, 1, 1, 1, 1];
        var ratios:Array = [0, 50, 180, 230, 255];
        var matr:Matrix = new Matrix;
        matr.createGradientBox(_width, graphMaxHeight, Math.PI / 2, 0, 0);
        viewCountRecordSprite.graphics.beginGradientFill(GradientType.LINEAR,
                colours, // colour
                alphas,  // alpha
                ratios, // ratio
                matr);

//        viewCountRecordSprite.graphics.lineStyle(0.1, 0x777777);
        viewCountRecordSprite.graphics.moveTo(0, graphMaxHeight);
        var forStart:uint = startTime;
        forStart = Math.max(0, Math.min(viewCountRecord.length - 1, forStart));
        var forEnd:uint = endTime;
        forEnd = Math.max(0, Math.min(viewCountRecord.length - 1, forEnd));

        viewCountRecordSprite.graphics.lineTo((-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
                graphMaxHeight - graphHeight)

        var calc:Number;
        for (var i:int = forStart; i < forEnd; i++) {

//            calc = (Math.log(viewCountRecord[i] / maxViewCount + Math.pow(Math.E, -1.5)) + 1.5) /
//                    (Math.log(1 + Math.pow(Math.E, -1.5)) + 1.5) *
//                    graphMaxHeight;
            calc = viewCountRecord[i]/maxViewCount * graphMaxHeight;

            graphHeight = Math.min(graphMaxHeight, calc);

            viewCountRecordSprite.graphics.lineTo((i + 0.5 - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
                    graphMaxHeight - graphHeight)
        }
        viewCountRecordSprite.graphics.lineTo((forEnd - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
                graphMaxHeight - graphHeight)
        viewCountRecordSprite.graphics.lineTo(_width, graphMaxHeight);
        viewCountRecordSprite.graphics.lineTo(calc, graphMaxHeight);

        addChild(viewCountRecordSprite);

//        trace("ASLDOADJ A");
//        var shape:Shape = new Shape();
//
//        graphics.beginFill(0x00ffff);
//        graphics.drawCircle(0, 0, 5);
//        graphics.endFill();
//
//        addChild(shape);
    }
}