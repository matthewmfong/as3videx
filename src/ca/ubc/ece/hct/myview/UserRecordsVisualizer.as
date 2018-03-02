////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.ui.UIScrollView;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.filmstrip.Filmstrip;
import ca.ubc.ece.hct.myview.widgets.filmstrip.SimpleFilmstrip;

import collections.HashMap;

import com.deng.fzip.FZip;
import com.doublefx.as3.thread.Thread;
import com.doublefx.as3.thread.api.IThread;
import com.doublefx.as3.thread.event.ThreadFaultEvent;
import com.doublefx.as3.thread.event.ThreadProgressEvent;
import com.doublefx.as3.thread.event.ThreadResultEvent;
import com.doublefx.as3.thread.event.ThreadStateEvent;
import com.greensock.TweenLite;
import com.greensock.events.LoaderEvent;
import com.greensock.loading.BinaryDataLoader;
import com.greensock.loading.LoaderMax;

import fl.controls.ProgressBar;
import fl.controls.ProgressBarMode;
import fl.controls.Slider;
import fl.controls.SliderDirection;
import fl.events.SliderEvent;

import flash.display.GradientType;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.net.registerClassAlias;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import mx.formatters.DateFormatter;

public class UserRecordsVisualizer extends View {

    private var video:VideoMetadata;
    private var loader:LoaderMax;
    private var newTime:Number;
    private var minDate:Date;
    private var maxDate:Date;
        private var statusText:TextField;
        private var orgUserRecordsArray:Array;
        private var hourlyRecordCount:Array;

    private var vcrLoader:ViewCountRecordsHistoryLoader;

    private var usernames:Array;
    private var aggregateVCR:Sprite;
    private var singleVCRs:HashMap;
    private var slider:Slider;
    private var sliderDate:TextField;
    private var sliderLastValue:Number;

    private var progressBar:ProgressBar;

    private var uiscroller:UIScrollView;
    private var container:Sprite;
    private var filmstrip:SimpleFilmstrip;

    private var navViz:UserNavigationVisualizer;
    private var navVizContainer:Sprite;
    private var navVizTitle:TextField;
    private var navVizClose:Sprite;

    public function UserRecordsVisualizer(width:Number = 1, height:Number = 1):void {
        _width = width;
        _height = height;
    }

    public function loadVideo(video:VideoMetadata, range:Range = null):void {
        destroy();
        this.video = video;


        progressBar = new ProgressBar();
        progressBar.mode = ProgressBarMode.MANUAL;
        progressBar.x = 100;
        progressBar.width = _width - 200;
        progressBar.y = _height/2;
        addChild(progressBar);

        statusText = new TextField();
        statusText.defaultTextFormat = new TextFormat("Arial", 20, 0xcccccc, true, false, false, null, null, "center", null, null, null, 4);
        statusText.text = "Downloading logs...";
        statusText.autoSize = "center";
        statusText.mouseEnabled = false;
        statusText.x = _width/2 - statusText.width/2;
        statusText.y = progressBar.y + progressBar.height;
        addChild(statusText);

        vcrLoader = new ViewCountRecordsHistoryLoader();
//        addChild(vcrLoader); // TODO: VERY IMPORTANT. NEEDS TO BE ON THE STAGE FOR THREADS TO WORK...? CHECK LATER.

        vcrLoader.progressSignal.add(
                function progressHandler(current:Number, total:Number):void {
                            progressBar.setProgress(current, total);
                }
        );
        vcrLoader.completeSignal.add(vcrLoaded);
        vcrLoader.loadVideo(video);

    }

    public function destroy():void {
        video = null;
        loader = null;
        minDate = null;
        maxDate = null;
        statusText = null;
        orgUserRecordsArray = null;
        usernames = null;
        aggregateVCR = null;
        singleVCRs = null;
        slider = null;
        sliderDate = null;
        progressBar = null;
        uiscroller = null;
        container = null;
        navViz = null;
        navVizContainer = null;
        navVizTitle = null;
        navVizClose = null;

        while(this.numChildren > 0) {
            removeChildAt(0);
        }
    }


    private function vcrLoaded():void {

        removeChild(progressBar);
        removeChild(statusText);

        hourlyRecordCount = vcrLoader.hourlyRecordCount;
        orgUserRecordsArray = vcrLoader.orgUserRecordsArray;
        minDate = vcrLoader.minDate;
        maxDate = vcrLoader.maxDate;
//        maxDate = new Date();
        maxDate.setTime(vcrLoader.maxDate.getTime() + Constants.DAYS2MILLISECONDS * 2);

        trace("minDate = " + minDate + ", maxDate = " + maxDate)

        // TODO: doing the hour record count thing. records should be passed from the thread. we just need to draw it.
//        graphics.lineStyle(1);
//        graphics.beginFill(0xff0000);
//        graphics.moveTo(20, 20);
        trace("___________________________________ " + hourlyRecordCount.length);

        drawHourlyActivity();

        startUIStuff();
    }

    private function mapArrayOfValuesToPixels(arr:Array, pixels:Number):Array {
        var newArr:Array = [];

        for(var i:int = 0; i<pixels; i++) {

        }

        return newArr;
    }

    public function drawHourlyActivity():void {

        var maxCount:Number = 0;
        var i:int;
        for(i = 0; i<hourlyRecordCount.length; i++) {
            maxCount = maxCount < hourlyRecordCount[i].count ?  hourlyRecordCount[i].count : maxCount;
        }

        var dateRange:Number = maxDate.time - minDate.time;

        graphics.clear();
        for(i = 0; i<hourlyRecordCount.length; i++) {
//            trace(hourlyRecordCount[i].count + " " + hourlyRecordCount[i].date);
            var color:uint = ColorUtil.getHeatMapColor(hourlyRecordCount[i].count/maxCount);
            graphics.beginFill(color);
//            trace("#" + color.toString(16) + " " + (hourlyRecordCount[i].count/maxCount));
            graphics.drawRect(20,
                    20 + (hourlyRecordCount[i].date.time - minDate.time) / dateRange * (_height - 40),
                    50,//hourlyRecordCount[i].count,
                    4);
//            graphics.lineTo(0, 20 + (hourlyRecordCount[i].date.time - minDate.time) / dateRange * (_height - 40));
//            graphics.lineTo(20 + hourlyRecordCount[i].count, 20 + (hourlyRecordCount[i].date.time - minDate.time) / dateRange * (_height - 40));
//            graphics.lineTo(20 + hourlyRecordCount[i].count, 20 + (hourlyRecordCount[i].date.time - minDate.time) / dateRange * (_height - 40) + 2);
//            graphics.lineTo(0, 20 + (hourlyRecordCount[i].date.time - minDate.time) / dateRange * (_height - 40) + 2);
            graphics.endFill();
        }
//        graphics.lineTo(20, 20);
        graphics.endFill();
    }

    public function startUIStuff():void {

        slider = new Slider();
        slider.direction = SliderDirection.VERTICAL;
        slider.height = _height - 40;
        slider.x = 20;
        slider.y = 20;
        slider.minimum = 1;
        slider.maximum = _height - 20;
        slider.liveDragging = true;
        slider.value = slider.maximum;
        slider.addEventListener(SliderEvent.CHANGE,
                function sliderChange(e:SliderEvent):void {
                    if(slider.value != sliderLastValue) {
                        var dateRange:Number = maxDate.time - minDate.time;
                        var interval:Number = dateRange / (slider.maximum - slider.minimum);
                        var newDate:Date = new Date(minDate.time + interval * (slider.maximum - slider.value));

                        sliderLastValue = slider.value;

                        setDate(newDate);
                    }
                });
        sliderDate = new TextField();
        sliderDate.defaultTextFormat = Constants.DEFAULT_TEXT_FORMAT;
        sliderDate.width = slider.width;
        sliderDate.x = slider.x + 10;
        sliderDate.y = 5;
        addChild(sliderDate);
        addChild(slider);

        aggregateVCR = new Sprite();
        aggregateVCR.x = slider.x + 40;
//        aggregateVCR.y = filmstrip.y + filmstrip.height + 20;
        addChild(aggregateVCR);

        uiscroller = new UIScrollView(_width - slider.x - 10, _height - (aggregateVCR.y + VIEW_COUNT_RECORD_HEIGHT));
        container = new Sprite();
        uiscroller.source = container;
        uiscroller.x = slider.x + 40;
        uiscroller.y = aggregateVCR.y + VIEW_COUNT_RECORD_HEIGHT;
        addChild(uiscroller);

        singleVCRs = new HashMap();
        usernames = [];

        var i:int;
        for(i = 0; i<orgUserRecordsArray.length; i++) {
            usernames.push(orgUserRecordsArray[i].username);
        }

        for(i = 0; i<usernames.length; i++) {
            var vcrSprite:Sprite = new ViewCountRecordSprite(usernames[i]);
            vcrSprite.y = i * (VIEW_COUNT_RECORD_HEIGHT + 5);
//            vcrSprite.addEventListener(MouseEvent.CLICK,
//                function vcrClick(e:MouseEvent):void {
//                    navViz.loadVideo(video, e.currentTarget.username);
//                    navVizTitle.text = e.currentTarget.username;
//                    addChild(navVizContainer);
//                    navVizContainer.alpha = 1;
//                });
            var usernameTextField:TextField = new TextField();
            usernameTextField.width = _width;
            usernameTextField.defaultTextFormat = Constants.DEFAULT_TEXT_FORMAT;
            usernameTextField.text = usernames[i];
            vcrSprite.addChild(usernameTextField);

            singleVCRs.put(usernames[i], vcrSprite);
            container.addChild(vcrSprite);
        }

//        navViz = new UserNavigationVisualizer(_width - 150, _height - 170);
//        navViz.x = 25;
//        navViz.y = 45;
//        navVizContainer = new Sprite();
//        navVizContainer.graphics.beginFill(0xaaaaaa);
//        navVizContainer.graphics.drawRect(3, 3, _width - 100, _height - 100);
//        navVizContainer.graphics.beginFill(0xeeeeee);
//        navVizContainer.graphics.drawRect(0, 0, _width - 100, _height - 100);
//        navVizContainer.addChild(navViz);
//        navVizContainer.x = 50;
//        navVizContainer.y = 50;
//
//        navVizTitle = new TextField();
//        navVizTitle.defaultTextFormat = Constants.DEFAULT_TEXT_FORMAT;
//        navVizTitle.width = navVizContainer.width;
//        navVizTitle.x = 10;
//        navVizTitle.y = 5;
//        navVizContainer.addChild(navVizTitle);
//
//        navVizClose = new Sprite();
//        navVizClose.graphics.beginFill(0, 0);
//        navVizClose.graphics.drawRect(0, 0, 20, 20);
//        navVizClose.graphics.endFill();
//        navVizClose.graphics.lineStyle(8, 0x333333);
//        navVizClose.graphics.lineTo(15, 15);
//        navVizClose.graphics.moveTo(15, 0);
//        navVizClose.graphics.lineTo(0, 15);
//        navVizClose.x = navVizContainer.width - navVizClose.width;
//        navVizClose.y = 5;
//        navVizClose.addEventListener(MouseEvent.CLICK,
//            function closeNavViz(e:MouseEvent):void {
//                TweenLite.to(navVizContainer, 0.24,
//                           {alpha: 0,
//                       onComplete: function navVizDisappeared():void {
//                                        removeChild(navVizContainer);
//
//                }});
//            });
//        navVizContainer.addChild(navVizClose);
        setDate(minDate);
    }

    public function setDate(newDate:Date):void {
        sliderDate.text = newDate.toString();
//        newTime = getTimer();
        drawViewCountRecord(aggregateVCR, getAggregateVCRAtDate(newDate), uiscroller.width, [0x00cc00, 0x008800], [1, 1], [0, 255]);

        for(var i:int = 0; i<usernames.length; i++) {
            drawViewCountRecord(singleVCRs.grab(usernames[i]), getVCRForUserAtDate(usernames[i], newDate), uiscroller.width);
        }
//        trace((getTimer() - newTime) / 1000 + "s");
    }

    public function getRecordsForUser(user:String):UserViewCountRecord {

        var records:UserViewCountRecord = null;
        for(var i:int = 0; i<orgUserRecordsArray.length; i++) {
            if(orgUserRecordsArray[i].username == user) {
                records = new UserViewCountRecord(user);
                records.username = orgUserRecordsArray[i].username;
                records.vcrs = orgUserRecordsArray[i].vcrs;
                records.vcrDates = orgUserRecordsArray[i].vcrDates;
                records.mapIndices = orgUserRecordsArray[i].mapIndices;
                records.mapDates = orgUserRecordsArray[i].mapDates;
                break;
            }
        }

        return records;
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

    public function getVCRForUserAtDate(user:String, date:Date):Array {

        var records:UserViewCountRecord = getRecordsForUser(user);

//        var dS:String = date.toString();

        // find index of records to jump to and start searching
        var mapIndex:int;
        for(mapIndex = 0; mapIndex < records.mapDates.length-1; mapIndex++) {
            if(records.mapDates[mapIndex] >= date) {
                break;
            }
        }

//        var mapdateslength = records.mapDates.length;
//        var mapidxstring = records.mapDates[mapIndex].toString();

        var entry:int = records.mapIndices[mapIndex];
        for(var i:int = records.mapIndices[mapIndex]; i < records.vcrDates.length; i++) {

            if(records.vcrDates[i] > date) {
                break;
            }

            entry = i;
        }
//        for(var i:int = records.mapIndices[mapIndex]; i >= 0; i--) {
//            if(records.vcrDates[i] < date) {
//                entry = i;
//                break;
//            }
//        }

        if(entry >= 0) {
            return records.vcrs[entry].split(",");
        }

        return [];

    }

    public static const VIEW_COUNT_RECORD_HEIGHT:uint = 100;

    public function drawViewCountRecord(viewCountRecordSprite:Sprite, viewCountRecord:Array, width:Number = 100,
                                        colours:Array = null,
                                        alphas:Array = null,
                                        ratios:Array = null):void {
        var startTime:Number = 0;
        var endTime:Number = video.duration;

        if(viewCountRecord.length > 0) {
            var maxViewCount:Number = 1;
            var i:int;
            for (i = 0; i < viewCountRecord.length; i++) {
                if (viewCountRecord[i] > maxViewCount) {
                    maxViewCount = viewCountRecord[i];
                }
            }

            maxViewCount += 5;

            var graphMaxHeight:int = VIEW_COUNT_RECORD_HEIGHT;

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

    public function setSize(w:Number, h:Number):void {
        _width = w;
        _height = h;

        progressBar.width = _width - 200;
        progressBar.y = _height/2;
        statusText.x = _width/2 - statusText.width/2;
        statusText.y = progressBar.y + progressBar.height;

        drawHourlyActivity();

        slider.height = _height - 40;
        slider.x = 20;
        slider.y = 20;

    }
}
}

import flash.display.Sprite;

class ViewCountRecordSprite extends Sprite {
    public var username:String;
    public function ViewCountRecordSprite(username:String) {
        this.username = username;
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