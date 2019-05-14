////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.dashboard.VideoSummary.VideoSummary;
import ca.ubc.ece.hct.myview.dashboard.VideoSummary.VideoSummaryComponent;
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
import flash.utils.getTimer;

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
    public var users_Panel:Group;
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

    [Bindable]
    public var videoSummaryComponent:VideoSummaryComponent;

    public function InstructorDashboard2018Class() {

        super();

        playlist_Panel = new Panel();
        playlistView_container = new SpriteVisualElement();
        activity_Panel = new Group();
        progressBar = new ProgressBar();

        recentMediaLayout = new RecentMedia();

        mainTileGroup = new TileGroup();

        dateFormatter = new DateTimeFormatter();
        dateFormatter.dateTimePattern = "EE MMM d, yyyy";

        videoSummaryComponent = new VideoSummaryComponent();

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

    }


    private function grabActiveUsers():void {

        activeUsersData = new ArrayCollection();

        var activeDates:Array = [];
        var activeUsers:Array = [];

        var insertDate:Date = new Date(course.startDate.getTime());
        var todayDate:Date = new Date() < course.endDate ? course.endDate : new Date();
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

                    UsersDictionary.newUser(entry['userstring']);

                    users.text += "S" + UsersDictionary.getUserNumber(entry['userstring']) + "\n";
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

    private var videoSummaryComponents:Array;
    private function showMostPopularVideos():void {

        videoSummaryComponent.videos = VideoMetadataManager.getVideos();
        videoSummaryComponent.videoSelected.add(loadVideo);
//        var titles:Label = new Label();             titles.text = "Titles";                 titles.width = VideoSummary.titlesWidth;
//        var totals:Label = new Label();             totals.text = "Total time viewed";      totals.width = VideoSummary.totalsWidth;
//        var durations:Label = new Label();          durations.text = "Duration";            durations.width = VideoSummary.durationsWidth;
//        var usersViewed:Label = new Label();        usersViewed.text = "Users viewed";      usersViewed.width = VideoSummary.usersViewedWidth;
//        var lastViewed:Label = new Label();         lastViewed.text = "Last Viewed";        lastViewed.width = VideoSummary.lastViewedWidth;
//
//        var headingsGroup:HGroup = new HGroup();
//        headingsGroup.addElement(titles);
//        headingsGroup.addElement(totals);
//        headingsGroup.addElement(durations);
//        headingsGroup.addElement(usersViewed);
//        headingsGroup.addElement(lastViewed);
//        summary_Group.addElement(headingsGroup);
//
//        titles.addEventListener(MouseEvent.CLICK, function sortByTitles(e:MouseEvent):void { sortVideoSummaryComponents("videoTitle"); });
//        totals.addEventListener(MouseEvent.CLICK, function sortByTitles(e:MouseEvent):void { sortVideoSummaryComponents("totalSecondsViewed"); });
//        durations.addEventListener(MouseEvent.CLICK, function sortByTitles(e:MouseEvent):void { sortVideoSummaryComponents("videoDuration"); });
//        usersViewed.addEventListener(MouseEvent.CLICK, function sortByTitles(e:MouseEvent):void { sortVideoSummaryComponents("usersViewed"); });
//        lastViewed.addEventListener(MouseEvent.CLICK, function sortByTitles(e:MouseEvent):void { sortVideoSummaryComponents("crowdLastViewed"); });
//
//        /// ----------------------------------------------------------------------
//
//        videoSummaryComponents = [];
//        var videos:Array = VideoMetadataManager.getVideos();
//
//        for each(var video:VideoMetadata in videos) {
//
//            var videoSummary:VideoSummary = new VideoSummary();
//            videoSummary.video = video;
//            videoSummary.videoClicked.add(loadVideo);
//
//            videoSummaryComponents.push(videoSummary);
//        }
//
//        sortVideoSummaryComponents("videoTitle");

        callNextDependentFunction();
    }

    private function sortVideoSummaryComponents(sortBy:String):void {
        videoSummaryComponents.sortOn(sortBy, Array.NUMERIC);

        while(summary_Group.numElements > 1) {
            summary_Group.removeElementAt(1);
        }

        for(var i:int = 0; i<videoSummaryComponents.length; i++) {
            summary_Group.addElement(videoSummaryComponents[i]);
        }
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

    private var timing:Number;
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

                        }

                    }
                }
        );

        callNextDependentFunction();

    }

    private function date2daymonthdate(d:Date):String {
        return Util.dayNumber2String(d.day, 3) + "\t" + Util.monthNumber2String(d.month, 3) + " " + d.date;
    }
}
}

import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import flash.display.GradientType;

import flash.display.Shape;

import flash.display.Sprite;
import flash.geom.Matrix;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

import spark.components.Label;
import spark.core.SpriteVisualElement;
import spark.formatters.DateTimeFormatter;


class Media extends Label {

    public var video:VideoMetadata;
}

class LastViewedLabel extends Label {

    private var _video:VideoMetadata;
    public function set video(v:VideoMetadata):void {

        var dateFormatter:DateTimeFormatter = new DateTimeFormatter();
        dateFormatter.dateTimePattern = "EE MMM d, yyyy";

        _video = v;
        _video.crowdLastViewedUpdated.add(
            function updateText():void {
                var today:Date = new Date();
                if(_video.crowdLastViewed == null) {
                    text = "Never";
                } else if(_video.crowdLastViewed.getDate() == today.getDate() &&
                        _video.crowdLastViewed.getMonth() == today.getMonth() &&
                        _video.crowdLastViewed.getFullYear() == today.getFullYear()) {
                    text = "Today";
                } else if(_video.crowdLastViewed.getDate() == today.getDate()-1 &&
                        _video.crowdLastViewed.getMonth() == today.getMonth() &&
                        _video.crowdLastViewed.getFullYear() == today.getFullYear()) {
                    text = "Yesterday"; // too lazy to add logic for yesterday of last month :P
                } else {
                    text = _video.crowdLastViewed == null ? "Never" : dateFormatter.format(_video.crowdLastViewed) + "";
                }
            }
        )
    }

}

class VCRSprite extends SpriteVisualElement {

    public var video:VideoMetadata;

    public var _width:Number;
    public var _height:Number;

    public var vcr:Vector.<Number>;

    public var maxViewCount:Number;

    public static const HORIZONTAL_TICK_INTERVAL:int = 30;

    public function VCRSprite(video:VideoMetadata, viewCountRecord:Vector.<Number>, width:Number, height:Number, slides:Vector.<Number> = null) {

        this.video = video;

        _width = width;
        _height = height;

        vcr = viewCountRecord;

        var startTime:Number = 0;
        var endTime:Number = viewCountRecord.length-1;

        maxViewCount = 1;
        for (var i:int = 0; i < viewCountRecord.length; i++) {
            if (viewCountRecord[i] > maxViewCount) {
                maxViewCount = viewCountRecord[i];
            }
        }

        var graphMaxHeight:int = _height;

        var viewCountRecordSprite:Shape = new Shape();
        viewCountRecordSprite.graphics.clear();
        viewCountRecordSprite.graphics.beginFill(0xff0000, 0);
        viewCountRecordSprite.graphics.drawRect(0, 0, _width, graphMaxHeight);
        viewCountRecordSprite.graphics.endFill();

        var graphHeight:Number = 0;

        var colours:Array = [0x009900];
        var alphas:Array = [1];
        var ratios:Array = [0];
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

//        viewCountRecordSprite.graphics.lineTo((-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width,
//                graphMaxHeight - graphHeight)

        var calc:Number = 0;
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

        if(slides) {
            for(var i:int = 0; i<slides.length; i++) {
                viewCountRecordSprite.graphics.lineStyle(1, 0);
                viewCountRecordSprite.graphics.moveTo((slides[i] + 0.5 - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width, graphMaxHeight);
                viewCountRecordSprite.graphics.lineTo((slides[i] + 0.5 - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * _width, 0);
            }
        }

        addChild(viewCountRecordSprite);

        drawAxes();

    }

    public function drawAxes():void {
        var axes:Sprite = new Sprite();
        axes.graphics.lineStyle(1, 0);
        axes.graphics.lineTo(0,         _height);
        axes.graphics.lineTo(_width,  _height);

        var numberofHorizontalTicks:int = vcr.length/HORIZONTAL_TICK_INTERVAL;
        var numberOfVerticalTicks:int = _height/25;

        for(var i:int = 0; i<numberOfVerticalTicks; i++) {
            axes.graphics.moveTo(0, _height - (i+1) * _height/numberOfVerticalTicks);
            axes.graphics.lineTo(5, _height - (i+1) * _height/numberOfVerticalTicks);
        }

        var lastTimePosition:Number = 0;
        for(var i:int = 0; i<numberofHorizontalTicks; i++) {
            axes.graphics.moveTo((i+1) * _width/numberofHorizontalTicks, _height);
            axes.graphics.lineTo((i+1) * _width/numberofHorizontalTicks, _height - 5);

            if((i * _width/numberofHorizontalTicks) - lastTimePosition  > 20) {
                var time:TextField = new TextField();
                time.autoSize = TextFieldAutoSize.CENTER;
                time.text = Util.timeInSecondsToTimeString(HORIZONTAL_TICK_INTERVAL * i);
                time.x = (i) * _width / numberofHorizontalTicks;
                time.y = _height - time.height;
                axes.addChild(time);

                lastTimePosition = time.x + time.width;
            }
        }

        addChild(axes);

        var maxViews:TextField = new TextField();
        maxViews.autoSize = TextFieldAutoSize.CENTER;
        maxViews.text = maxViewCount.toString() + " total views";
        maxViews.x = 7;
        axes.addChild(maxViews);


    }
}