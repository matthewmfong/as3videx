////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.dashboard.calendar {
import ca.ubc.ece.hct.myview.ColorUtil;
import ca.ubc.ece.hct.myview.Constants;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.View;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import org.osflash.signals.Signal;

public class Calendar extends View {

    public var dayTextWidth:Number;
    public var boxWidth:Number = 20;
    public var boxHeight:Number = 15;
    public var padding:Number = 2;

    public var startDate:Date, endDate:Date;

    public var dailyRecordCount:Array;
    public var maxCount:Number;

    public var dayBoxes:Vector.<DayBox>;
    public var dayTexts:Array;
    public var monthTexts:Array;

    public var calendar:Sprite;

    public var dateHoverSignal:Signal;
    public var dateClickSignal:Signal;
    public var dateRollOutSignal:Signal;

    public function Calendar(startDate:Date, endDate:Date) {

        dateHoverSignal = new Signal(Date);
        dateClickSignal = new Signal(Date);
        dateRollOutSignal = new Signal();

        this.startDate = startDate;
        this.endDate = endDate;

        calendar = new Sprite();

        dayBoxes = new Vector.<DayBox>();

        dayTextWidth = 0;

        dayTexts = [];
        var text:TextField;
        for(var i:int = 0; i<Constants.DAY_SHORT.length; i++) {
            text = new TextField();
            text.autoSize = TextFieldAutoSize.LEFT;
            text.defaultTextFormat = new TextFormat("Arial", boxHeight/2);
            text.text = Constants.DAY_SHORT[i];
            addChild(text);
            dayTexts.push(text);
            text.mouseEnabled = false;

            dayTextWidth = Math.max(dayTextWidth, text.width);
        }


        var date:Date;
        monthTexts = [];


        for(i = startDate.month; i <= endDate.month; i++) {
            var monthText:TextField = new TextField();
            monthText.defaultTextFormat = new TextFormat("Arial", boxHeight/2);
            monthText.autoSize = TextFieldAutoSize.LEFT;
            monthText.text = Constants.MONTH[i];
            addChild(monthText);
            monthTexts.push(monthText);
            monthText.mouseEnabled = false;
        }


        var startTime:Number = startDate.getTime();
        var endTime:Number = endDate.getTime();
        var runningTime:Number;
        var today:Date = new Date();


        for(runningTime = startTime + Constants.HOURS2MILLISECONDS * 2;
                // stupid DST will do this
                // Sun Nov 4 00:00:00 GMT-0700 2018, Sun Nov 4 23:00:00 GMT-0800 2018
            runningTime <= endTime;
            runningTime += Constants.DAYS2MILLISECONDS) {

            date = new Date(runningTime);

            var db:DayBox = new DayBox(date, 0xffffff, boxWidth, boxHeight);

            dayBoxes.push(db);

            calendar.addChild(db);

            db.addEventListener(MouseEvent.ROLL_OVER, dayBoxRollOver);
            db.addEventListener(MouseEvent.CLICK, dayBoxClick);

            if(today.fullYear == date.fullYear && today.month == date.month && today.date == date.date) {
                db.selected = true;
            }

        }


        addEventListener(MouseEvent.ROLL_OUT, rollOut);
        calendar.x = dayTextWidth;
        calendar.y = monthText.height + padding;
        addChild(calendar);
    }

    private function dayBoxRollOver(e:MouseEvent):void {
        dateHoverSignal.dispatch(e.currentTarget.date);
        calendar.setChildIndex((DayBox)(e.currentTarget), calendar.numChildren - 1);
    }

    private function dayBoxClick(e:MouseEvent):void {
        dateClickSignal.dispatch(e.currentTarget.date);
        for(var i:int = 0; i<dayBoxes.length; i++) {
            dayBoxes[i].selected = false;
        }
        (DayBox)(e.currentTarget).selected = true;
    }

    public function setSize(w:Number, h:Number):void {

        _width = w;
        _height = h;


        var numVisibleDays:Number = (endDate.getTime() - startDate.getTime()) / Constants.DAYS2MILLISECONDS;

        var numVisibleWeeks:Number = Math.ceil(numVisibleDays / 7);

        if(endDate.day <= startDate.day) {
            numVisibleWeeks += 1;
        }

        var calendarWidth:Number = _width - dayTextWidth;


        boxWidth = calendarWidth / numVisibleWeeks;

        var testMonthText:TextField = new TextField();
        testMonthText.defaultTextFormat = new TextFormat("Arial", boxHeight/2);
        testMonthText.autoSize = TextFieldAutoSize.LEFT;
        testMonthText.text = Constants.MONTH[0];

        boxHeight = (_height - testMonthText.height) / 7;


        var startWeek:Date = new Date(startDate.getTime() - startDate.day * Constants.DAYS2MILLISECONDS);

        var currentMonth:Number = -1;
        var monthTextCounter:Number = 0;

        for each(var db:DayBox in dayBoxes) {
            db.setSize(boxWidth, boxHeight);

            db.x = Math.floor((db.date.getTime() - startWeek.getTime()) / Constants.WEEKS2MILLISECONDS) * (boxWidth + padding);
            db.y = db.date.day * (boxHeight + padding);

            if(db.date.getMonth() != currentMonth) {

                currentMonth = db.date.getMonth();
                monthTexts[monthTextCounter].text = Constants.MONTH[currentMonth];
                monthTexts[monthTextCounter].x = db.x + calendar.x;
                monthTextCounter++;

            }

        }

        // the last day or so may not be displayed as a DayBox, so it doesn't make sense to have a month there (this is a time zone issue)
        for(var i:int = monthTextCounter; i<monthTexts.length; i++) {
            monthTexts[i].alpha = 0;
        }


        for(i = 0; i<dayTexts.length; i++) {
            dayTexts[i].y = calendar.y + (boxHeight + padding) * i;
        }

        calendar.graphics.clear();
        calendar.graphics.beginFill(0xdddddd);
        calendar.graphics.drawRect(0, 0, calendar.width, calendar.height);
        calendar.graphics.endFill();
    }

    public function updateDailyRecordCount(records:Array):void {

        dailyRecordCount = records;

        var startTime:Number = startDate.getTime();
        var endTime:Number = endDate.getTime();

        var runningTime:Number;

        var colours:Array = [ [0,0,255], [0,255,0], [255,255,0], [255,0,0] ];

        for(runningTime = startTime; runningTime < endTime; runningTime += Constants.DAYS2MILLISECONDS) {

            var date:Date = new Date(runningTime);
            var colour:Number = 0xffffff;
            for each(var o:Object in dailyRecordCount) {

                if(     date.fullYear   ==    o.date.fullYear   &&
                        date.month      ==    o.date.month      &&
                        date.date       ==    o.date.date) {

                    colour = (o.count == 0) ? 0xffffff : ColorUtil.getHeatMapColor(o.count/maxCount, colours);

                    var index:int = (runningTime - startTime) / Constants.DAYS2MILLISECONDS;
                    if(index > 0 && index < dayBoxes.length-1) {
                        dayBoxes[index].setColour(Util.brighten(colour, 2));
                        dayBoxes[index].rollOverString = Math.round(o.count/60*10)/10 + " minutes viewed";
                    }

                    break;
                }
            }
        }
    }

    private function rollOut(e:MouseEvent):void {
        dateRollOutSignal.dispatch();
    }
}
}
