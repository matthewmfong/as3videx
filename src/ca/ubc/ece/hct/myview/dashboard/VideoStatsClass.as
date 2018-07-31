////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.dashboard {
import ca.ubc.ece.hct.myview.Constants;
import ca.ubc.ece.hct.myview.NumberUtil;
import ca.ubc.ece.hct.myview.ServerDataLoader;
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.UserRecordsVisualizer;
import ca.ubc.ece.hct.myview.UserViewCountRecord;
import ca.ubc.ece.hct.myview.ViewCountRecordsHistoryLoader;
import ca.ubc.ece.hct.myview.dashboard.calendar.Calendar;
import ca.ubc.ece.hct.myview.log.UserLogsLoader;
import ca.ubc.ece.hct.myview.thumbnail.ThumbnailNative;
import ca.ubc.ece.hct.myview.video.VideoCaptions;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.subtitleviewer.Cue;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.getTimer;

import flashx.textLayout.conversion.TextConverter;

import mx.controls.ProgressBar;

import spark.components.Group;
import spark.components.Label;
import spark.components.RichText;
import spark.components.Scroller;
import spark.components.SkinnableContainer;
import spark.components.VGroup;
import spark.core.SpriteVisualElement;

public class VideoStatsClass extends SkinnableContainer {

    public var db:UserLogsLoader;

    private var _video:VideoMetadata;
    private var thumb:ThumbnailNative;

    private var cal:Calendar;
    private var selectedDate:Date;
    private var captionView:TextField;

    private var secondsWatched:Number = 0;

    private var viewCountRecordSprite:InstructorViewCountRecordSprite;
    private var individualViewCountRecordSprites:Vector.<ViewCountRecordSprite>;

    private var allTimeAggregateMaxViewCount:Number = 0;
    private var allTimeMaxViewCount:Number = 0;

    private var vcrLoader:ViewCountRecordsHistoryLoader;
    private var usernames:Array;

    public var scroller:Scroller;
    public var progressBar_ProgressBar:ProgressBar;
    public var base_vGroup:VGroup;
    public var calendar_SpriteVisualElement:SpriteVisualElement;
    public var aggregate_vcr_SpriteVisualElement:SpriteVisualElement;
    public var thumbnail_SpriteVisualElement:SpriteVisualElement;
    public var caption_SpriteVisualElement:SpriteVisualElement;
    public var users_watched_Label:RichText;
    public var views_Label:RichText;
    public var minutes_watched_Label:RichText;
    public var avg_minutes_watched_Label:RichText;
    public var number_of_seeks_Label:RichText;
    public var individual_VCRs_spriteVisualElement:SpriteVisualElement;

    public function VideoStatsClass() {
        super();

        scroller = new Scroller();
        progressBar_ProgressBar = new ProgressBar();
        base_vGroup = new VGroup();
        calendar_SpriteVisualElement = new SpriteVisualElement();
        aggregate_vcr_SpriteVisualElement = new SpriteVisualElement();
        thumbnail_SpriteVisualElement = new SpriteVisualElement();
        caption_SpriteVisualElement = new SpriteVisualElement();
        users_watched_Label = new RichText();
        views_Label = new RichText();
        minutes_watched_Label = new RichText();
        avg_minutes_watched_Label = new RichText();
        number_of_seeks_Label = new RichText();
        individual_VCRs_spriteVisualElement = new SpriteVisualElement();


        usernames = [];
        individualViewCountRecordSprites = new Vector.<ViewCountRecordSprite>();


        cal = new Calendar(VideoMetadataManager.COURSE.startDate, VideoMetadataManager.COURSE.endDate);
        selectedDate = new Date();
    }

    public function creationCompleteHandler():void {
        ServerDataLoader.getCrowdHighlights(_video.media_alias_id).add(crowdHighlightsLoaded);

        vcrLoader = new ViewCountRecordsHistoryLoader();
        vcrLoader.progressSignal.add(
                function progressHandler(current:Number, total:Number):void {
                    progressBar_ProgressBar.setProgress(current, total);
                }
        );
        vcrLoader.statusSignal.add(
                function statusHandler(string:String):void {
                    progressBar_ProgressBar.label = string;
                }
        );
        vcrLoader.completeSignal.add(vcrHistoryLoaded);
        if(_video) {
            vcrLoader.loadVideo(_video);

            cal.maxCount = vcrLoader.dailyRecordMaxCount;
            cal.updateDailyRecordCount(vcrLoader.dailyRecordCount);
//        vcrHistoryLoaded(); // loaded the file first so we have something to show.

            var aggregateVCR:Array = [];
            for each(var data in _video.crowdUserData.grab(UserData.CLASS)) {

                var viewCountRecord:Array = data.viewCountRecord;

                if(viewCountRecord.length > 0) {

                    for (var i:int = 0; i < viewCountRecord.length; i++) {

                        if(aggregateVCR[i] || aggregateVCR[i] == 0) {
                            aggregateVCR[i] += viewCountRecord[i];
                        } else {
                            aggregateVCR.push(viewCountRecord[i]);
                        }

                        allTimeAggregateMaxViewCount = Math.max(allTimeAggregateMaxViewCount, aggregateVCR[i]);
                        allTimeMaxViewCount = Math.max(allTimeMaxViewCount, viewCountRecord[i]);

                    }

                }

            }
        }


        cal.setSize(calendar_SpriteVisualElement.width * 0.8, calendar_SpriteVisualElement.height * 0.8);
        cal.dateClickSignal.add(dateClicked);
        cal.dateHoverSignal.add(dateHovered);
        cal.dateRollOutSignal.add(dateRollOut);

        calendar_SpriteVisualElement.addChild(cal);

        viewCountRecordSprite = new InstructorViewCountRecordSprite(aggregate_vcr_SpriteVisualElement.width, aggregate_vcr_SpriteVisualElement.height);
        viewCountRecordSprite.video = _video;
        viewCountRecordSprite.addEventListener(MouseEvent.MOUSE_MOVE, vcrMouseMove);
//        viewCountRecordSprite.addEventListener(MouseEvent.CLICK, vcrClick);
        viewCountRecordSprite.drawViewCountRecord(_video.crowdUserData.grab(UserData.CLASS), allTimeMaxViewCount, allTimeAggregateMaxViewCount);


        aggregate_vcr_SpriteVisualElement.addChild(viewCountRecordSprite);

        var crowdUserData:Vector.<UserData> = _video.crowdUserData.grab(UserData.CLASS);
        for(var i:int = 0; i<crowdUserData.length; i++) {
            for(var j:int = 0; j<(UserData)(crowdUserData[i]).viewCountRecord.length; j++) {
                secondsWatched += (UserData)(crowdUserData[i]).viewCountRecord[j];
            }
        }

        thumb = new ThumbnailNative();
        thumb.setSize(thumbnail_SpriteVisualElement.width, thumbnail_SpriteVisualElement.height);
        thumb.loadVideo(_video);
        thumb.showImage();
        thumbnail_SpriteVisualElement.addChild(thumb);

        var userdatas:Vector.<UserData> = _video.crowdUserData.grab(UserData.CLASS);
        users_watched_Label.textFlow = TextConverter.importToFlow("<b>Users watched: </b>" + (userdatas ? userdatas.length : 0), TextConverter.TEXT_FIELD_HTML_FORMAT);
        minutes_watched_Label.textFlow = TextConverter.importToFlow("<b>Minutes watched: </b>" + NumberUtil.roundDecimalToPlace(secondsWatched/60, 1), TextConverter.TEXT_FIELD_HTML_FORMAT);
        avg_minutes_watched_Label.textFlow = TextConverter.importToFlow("<b>Average Minutes watched per user: </b>" + NumberUtil.roundDecimalToPlace((secondsWatched/60/(userdatas ? userdatas.length : 1)), 1), TextConverter.TEXT_FIELD_HTML_FORMAT);

        captionView = new TextField();
        captionView.width = caption_SpriteVisualElement.width;
        captionView.defaultTextFormat = new TextFormat("Arial", 12, 0x000000, true);
        captionView.autoSize = "center";
        captionView.wordWrap = true;
        caption_SpriteVisualElement.addChild(captionView);

        db.select("SELECT count(*) AS count FROM main.logs WHERE action = 'seek' AND video_id = '" + _video.media_alias_id + "'").add(
            function (r:Object):void {
                number_of_seeks_Label.textFlow = TextConverter.importToFlow("<b>Number of seeks: </b>" + r.data[0].count, TextConverter.TEXT_FIELD_HTML_FORMAT);
            }
        );






    }

    public function set video(v:VideoMetadata):void {
        _video = v;
        if(vcrLoader && vcrLoader.video && vcrLoader.video != _video) {
            vcrLoader.loadVideo(_video)
        }

    }

    private function crowdHighlightsLoaded(object:Object):void {
        var obj:* = JSON.parse((String)(object));
        for(var n:String in obj) {
            if (obj.hasOwnProperty(n)) {

                var user_string:String;
                var colour_string:String;
                var intervals_string:String;

                for (var m:String in obj[n]) {
                    if(obj[n].hasOwnProperty(m)) {
                        switch (m) {
                            case "user_id":
                                user_string = obj[n][m];
                                break;
                            case "colour":
                                colour_string = obj[n][m];
                                break;
                            case "intervals":
                                intervals_string = obj[n][m];
                                break;
                        }
                    }
                }

                var userData:UserData = _video.grabCrowdUserData(UserData.CLASS, user_string);

                if (userData && colour_string && intervals_string) {
                    userData.setHighlights(colour_string, intervals_string);
                } else {
                    userData = new UserData();
                    userData.userString = user_string;
                    userData.setHighlights(colour_string, intervals_string);
                    _video.addCrowdUserData(UserData.CLASS, userData);
                }
            }
        }

        drawHighlights();
    }

    private function drawHighlights():void {
        viewCountRecordSprite.drawHighlights();

        for each(var vcr:ViewCountRecordSprite in individualViewCountRecordSprites) {
            vcr.drawHighlights(_video.grabCrowdUserData(UserData.CLASS, vcr.username).highlights, _video);
        }

    }

    private function captionSeek(time:Number):void {

        if(_video.getSources("vtt")[0]) {

            var captions:VideoCaptions = _video.getSources("vtt")[0].captions;
            var cue:Cue = captions.getCueAtTime(time);
            var text:String = cue.getText();

            if(captionView.text != text) {
                captionView.text = text;
            }

        }
    }

    private function vcrMouseMove(e:MouseEvent):void {
        thumb.seekNormalized(e.localX/viewCountRecordSprite.width, true, true);
        captionSeek(e.localX/viewCountRecordSprite.width * _video.duration);

        for each(var vcr:ViewCountRecordSprite in individualViewCountRecordSprites) {
            vcr.seek(e.localX/viewCountRecordSprite.width);
        }
    }

    private function vcrClick(e:MouseEvent):void {

        var spr:SpriteVisualElement = new SpriteVisualElement();
        spr.width = scroller.width;
        spr.height = scroller.height;

        var group:Group = new Group();
        group.percentWidth = 100;
        group.percentHeight = 100;

        group.addElement(spr);

        scroller.viewport = group;


        var urv:UserRecordsVisualizer = new UserRecordsVisualizer(spr.width, spr.height);

        spr.addChild(urv);
        urv.loadVideo(_video);
    }

    private function vcrHistoryLoaded():void {
        trace("vcrhistoryloaded");

//        var dailyRecordCount:Array = [];
        progressBar_ProgressBar.setProgress(1, 1);

        var maxCount:Number = 0;
        var counter:Number = 0;
        var i:int;

        usernames = [];
        if(vcrLoader.orgUserRecordsArray) {
            for (i = 0; i < vcrLoader.orgUserRecordsArray.length; i++) {
                usernames.push(vcrLoader.orgUserRecordsArray[i].username);
            }
        }


        cal.maxCount = vcrLoader.dailyRecordMaxCount;
        cal.updateDailyRecordCount(vcrLoader.dailyRecordCount);

        for(i = 0; i<usernames.length; i++) {
            var vcrSprite:ViewCountRecordSprite = new ViewCountRecordSprite(usernames[i]);
            vcrSprite.y = i * (100 + 5);

            var usernameTextField:TextField = new TextField();
            usernameTextField.width = 500;
            usernameTextField.defaultTextFormat = Constants.DEFAULT_TEXT_FORMAT;
            usernameTextField.text = usernames[i];
            vcrSprite.addChild(usernameTextField);

            individualViewCountRecordSprites.push(vcrSprite);
            individual_VCRs_spriteVisualElement.addChild(vcrSprite);
            vcrSprite.drawViewCountRecord(getVCRForUserAtDate(usernames[i], new Date()), _video, individual_VCRs_spriteVisualElement.width);

        }

        if(individualViewCountRecordSprites.length > 0) {
            individual_VCRs_spriteVisualElement.height = individualViewCountRecordSprites[individualViewCountRecordSprites.length - 1].y +
                    individualViewCountRecordSprites[individualViewCountRecordSprites.length - 1].height;
        }


    }

    public function getAggregateVCRAtDate(date:Date):Array {

        var aggregateVCR:Array = [];

        for each(var user:String in usernames) {

            var vcr:Array = [];
            var vcrString:Array = getVCRForUserAtDate(user, date);

            for (var j:int = 0; j < vcrString.length; j++) {
                vcr.push(Number(vcrString[j]));
            }

            while (aggregateVCR.length < vcr.length) {
                aggregateVCR.push(0);
            }
            for (var i:int = 0; i < vcr.length; i++) {
                aggregateVCR[i] += vcr[i];
            }

        }

        return aggregateVCR;
    }

    public function getRecordsForUser(user:String):UserViewCountRecord {

        var records:UserViewCountRecord = null;
        for(var i:int = 0; i<vcrLoader.orgUserRecordsArray.length; i++) {
            if(vcrLoader.orgUserRecordsArray[i].username == user) {
                records = new UserViewCountRecord(user);
                records.username = vcrLoader.orgUserRecordsArray[i].username;
                records.vcrs = vcrLoader.orgUserRecordsArray[i].vcrs;
                records.vcrDates = vcrLoader.orgUserRecordsArray[i].vcrDates;
                records.mapIndices = vcrLoader.orgUserRecordsArray[i].mapIndices;
                records.mapDates = vcrLoader.orgUserRecordsArray[i].mapDates;
                break;
            }
        }

        return records;
    }

    public function getVCRForUserAtDate(user:String, date:Date):Array {

        var records:UserViewCountRecord = getRecordsForUser(user);

        if(records.mapDates.length > 0 && records.mapDates[0] < date) {
            // find index of records to jump to and start searching
            var mapIndex:int;
            for (mapIndex = 0; mapIndex < records.mapDates.length - 1; mapIndex++) {
                if (records.mapDates[mapIndex] >= date) {
                    break;
                }
            }

            var entry:int = records.mapIndices[mapIndex];
            for (var i:int = records.mapIndices[mapIndex]; i < records.vcrDates.length; i++) {

                if (records.vcrDates[i] > date) {
                    break;
                }

                entry = i;
            }

            if (entry >= 0) {
                var arr:Array = records.vcrs[entry].split(",");

                for (var j:int = 0; j < arr.length; j++) {
                    arr[j] = Number(arr[j]);
                }

                return arr;
            }
        }

        return [];

    }

    private function dateHovered(date:Date):void {

        gotoDate(date);

    }

    private function dateClicked(date:Date):void {

        selectedDate = date;
        gotoDate(date);
    }

    private function dateRollOut():void {
        gotoDate(selectedDate);
    }

    private function gotoDate(inputDate:Date):void {
        var numUsers:Number = 0;
        var date:Date = new Date(inputDate.getTime() + Constants.DAYS2MILLISECONDS - 1);
        var userdatas:Vector.<UserData> = new Vector.<UserData>();
        for(var i:int = 0; i<usernames.length; i++) {
            var user:UserData = new UserData();
            user.userString = usernames[i];
            user.viewCountRecord = getVCRForUserAtDate(user.userString, date);
            for(var j:int = 0; j < user.viewCountRecord.length; j++) {
                user.maxViewCount = Math.max(user.maxViewCount, user.viewCountRecord[j]);
            }
            if(user.maxViewCount > 0) {
                numUsers++;
            }
            userdatas.push(user);
        }

        viewCountRecordSprite.drawViewCountRecord(userdatas, allTimeMaxViewCount, allTimeAggregateMaxViewCount);

        secondsWatched = 0;

        for(var i:int = 0; i<userdatas.length; i++) {
            for(var j:int = 0; j<(UserData)(userdatas[i]).viewCountRecord.length; j++) {
                secondsWatched += (UserData)(userdatas[i]).viewCountRecord[j];
            }
        }

        users_watched_Label.textFlow = TextConverter.importToFlow("<b>Users watched (" + date + "): </b>" + numUsers, TextConverter.TEXT_FIELD_HTML_FORMAT);
        minutes_watched_Label.textFlow = TextConverter.importToFlow("<b>Minutes watched (" + date + "): </b>" + NumberUtil.roundDecimalToPlace(secondsWatched/60, 1), TextConverter.TEXT_FIELD_HTML_FORMAT);
        avg_minutes_watched_Label.textFlow = TextConverter.importToFlow("<b>Average Minutes watched per user (" + date + "): </b>" + NumberUtil.roundDecimalToPlace((secondsWatched/60/numUsers), 1), TextConverter.TEXT_FIELD_HTML_FORMAT);

        db.select("SELECT count(*) AS count FROM main.logs WHERE action = 'seek' AND video_id = '" + _video.media_alias_id + "' AND date < '" + inputDate.time + "'").add(
                function (r:Object):void {
                    number_of_seeks_Label.textFlow = TextConverter.importToFlow("<b>Number of seeks </b>" + r.data[0].count, TextConverter.TEXT_FIELD_HTML_FORMAT);
                }
        )

        for each(var vcrSprite:ViewCountRecordSprite in individualViewCountRecordSprites) {
            vcrSprite.drawViewCountRecord(getVCRForUserAtDate(vcrSprite.username, inputDate), _video, individual_VCRs_spriteVisualElement.width);

        }
    }
}
}

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.Colours;
import ca.ubc.ece.hct.myview.UserData;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.filmstrip.FilmstripHighlight;

import collections.HashMap;

import flash.display.GradientType;
import flash.display.Shape;

import flash.display.Sprite;
import flash.geom.Matrix;

class ViewCountRecordSprite extends Sprite {

    public var _width:Number;
    public var _height:Number;
    public var username:String;
    private var highlightSprite:Sprite;
    private var seekLine:Shape;

    public function ViewCountRecordSprite(username:String) {
        this.username = username;
        highlightSprite = new Sprite();
        addChild(highlightSprite);

    }

    public function seek(percentage:Number):void {

        seekLine.x = _width * percentage;
    }

    public function drawViewCountRecord(viewCountRecord:Array,
                                        video:VideoMetadata,
                                        width:Number = 100,
                                        height:Number = 100,
                                        colours:Array = null,
                                        alphas:Array = null,
                                        ratios:Array = null):void {

        _width = width;
        _height = height;

        seekLine = new Shape();
        seekLine.graphics.lineStyle(1, 0xff0000);
        seekLine.graphics.lineTo(0, _height);
        addChild(seekLine);


        var startTime:Number = 0;
        var endTime:Number = video.duration;
        var viewCountRecordSprite:ViewCountRecordSprite = this;

        if(viewCountRecord.length > 0) {
            var maxViewCount:Number = 1;
            var i:int;
            for (i = 0; i < viewCountRecord.length; i++) {
                if (viewCountRecord[i] > maxViewCount) {
                    maxViewCount = viewCountRecord[i];
                }
            }

            maxViewCount += 5;

            var graphMaxHeight:int = height;

            viewCountRecordSprite.graphics.clear();
            viewCountRecordSprite.graphics.beginFill(0x666666, 0.1);
            viewCountRecordSprite.graphics.drawRect(0, 0, width, graphMaxHeight);
            viewCountRecordSprite.graphics.endFill();

            var graphHeight:Number;

            if (colours == null) colours = [0xffff00, 0xffff00, 0xffa500, 0xff0000, 0xff0000];
            if (alphas == null) alphas = [1, 1, 1, 1, 1];
            if (ratios == null) ratios = [0, 50, 180, 230, 255];
            var matr:Matrix = new Matrix;
            matr.createGradientBox(width, graphMaxHeight, Math.PI / 2, 0, 0);
            viewCountRecordSprite.graphics.beginGradientFill(GradientType.LINEAR,
                    colours, // colour
                    alphas,  // alpha
                    ratios, // ratio
                    matr);

            viewCountRecordSprite.graphics.lineStyle(0.1, 0x777777);
            viewCountRecordSprite.graphics.moveTo(0, graphMaxHeight);
            var forStart:uint = startTime;
            forStart = Math.max(0, Math.min(viewCountRecord.length - 1, forStart));
            var forEnd:uint = endTime;
            forEnd = Math.max(0, Math.min(viewCountRecord.length - 1, forEnd));

            viewCountRecordSprite.graphics.lineTo((-uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * width,
                    graphMaxHeight - graphHeight)

            var calc:Number;
            for (i = forStart; i < forEnd; i++) {

//                calc = (Math.log(viewCountRecord[i] / maxViewCount + Math.pow(Math.E, -1.5)) + 1.5) /
//                        (Math.log(1 + Math.pow(Math.E, -1.5)) + 1.5) *
//                        graphMaxHeight;

                calc = viewCountRecord[i] / maxViewCount * graphMaxHeight;

                graphHeight = Math.min(graphMaxHeight, calc);

                viewCountRecordSprite.graphics.lineTo((i + 0.5 - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * width,
                        graphMaxHeight - graphHeight)
            }
            viewCountRecordSprite.graphics.lineTo((forEnd - uint(startTime)) / (uint(endTime + 1) - uint(startTime)) * width,
                    graphMaxHeight - graphHeight)
            viewCountRecordSprite.graphics.lineTo(width, graphMaxHeight);
            viewCountRecordSprite.graphics.lineTo(calc, graphMaxHeight);
        } else {
            viewCountRecordSprite.graphics.clear();
        }
    }

    public function drawHighlights(highlightData:HashMap, video:VideoMetadata):void {

        var highlightLineThickness:uint = 10;
        var highlightSpriteThickness:uint = 10;

        if(highlightSprite) {
            highlightSprite.graphics.clear();
            while (highlightSprite.numChildren > 0) {
                highlightSprite.removeChildAt(0);
            }
//			var totalTime:Number = (endTime - startTime);
//			var highlightWidth:Number = _width / totalTime;

            highlightSprite.graphics.beginFill(0, 0.3);
            highlightSprite.graphics.drawRect(0, 0, _width, highlightData.values().length * highlightLineThickness);
            highlightSprite.graphics.endFill();

            // draw an invisible mouse_over area
            highlightSprite.graphics.beginFill(0xff0000, 0);
            highlightSprite.graphics.drawRect(0, 0, _width, highlightSpriteThickness);
            highlightSprite.graphics.endFill();

            var colours:Array = Colours.sortColours(highlightData.keys());

            var i:int = 0;
            for each(var colour:int in colours) {

                for each(var highlightInterval:Range in highlightData.grab(colour).intervals) {

//                    if (0 <= highlightInterval.end && video.duration >= highlightInterval.start) {

                        var timeRange:Range = highlightInterval;
                        var xDimension:Number = Math.max(0, (highlightInterval.start) / video.duration * _width);
                        var widthDimension:Number = Math.min(_width, (highlightInterval.end) / video.duration * _width) - xDimension;
                        var dimensions:flash.geom.Rectangle = new flash.geom.Rectangle(xDimension, (i) * highlightLineThickness,
                                widthDimension, highlightLineThickness);

                        highlightSprite.graphics.beginFill(colour);
                        highlightSprite.graphics.drawRect(dimensions.x, dimensions.y, dimensions.width, dimensions.height);
                        highlightSprite.graphics.endFill();

//                        var highlight:FilmstripHighlight = new FilmstripHighlight(timeRange, dimensions, colour);
//                        highlight.x = dimensions.x;
//                        highlight.y = dimensions.y;
//
//                        highlightSprite.addChild(highlight);

//                    }

                }
                i++;
            }
        }

    }
}

class ViewCountRecord {
    public var user:String;
    public var vcr:String;
    public var date:Date;

    public function ViewCountRecord(user:String, vcr:String, date:Date) {
        this.user = user;
        this.vcr = vcr;
        this.date = date;
    }
}

class RecordMap {
    public var index:uint;
    public var date:Date;

    public function RecordMap(index:uint, date:Date) {
        this.index = index;
        this.date = date;
    }
}