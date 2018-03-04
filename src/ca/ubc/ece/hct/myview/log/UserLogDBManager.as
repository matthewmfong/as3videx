////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.log {
import flash.data.SQLConnection;
import flash.data.SQLResult;
import flash.data.SQLStatement;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.ProgressEvent;
import flash.events.SQLErrorEvent;
import flash.events.SQLEvent;
import flash.filesystem.File;
import flash.utils.getTimer;

import org.osflash.signals.Signal;

public class UserLogDBManager extends EventDispatcher {

    public var conn:SQLConnection;
    private var dbFile:File;
    private var insertStmt:SQLStatement;

    private var insertBacklog:Array;
    private var insertBacklogMaxLength:Number;

    private var commitTimer:Number;

    private var recordCount:Number = 0;

    private var commitWhenReady:Boolean = false;

    public function UserLogDBManager(path:String) {
        conn = new SQLConnection();

        conn.addEventListener(SQLEvent.OPEN, openHandler);
        conn.addEventListener(SQLErrorEvent.ERROR, errorHandler);

        dbFile = new File().resolvePath(path);//File.File.applicationStorageDirectory.resolvePath("user_logs.db");

        insertBacklog = [];

        prepareInsert();

    }

    public function open():void {
        conn.open(dbFile);
    }

    public function openAsync():void {
        conn.openAsync(dbFile);
    }

    public function beginTransaction():void {
        conn.addEventListener(SQLEvent.BEGIN, beginHandler);
        conn.begin();
    }

    public function commitTransaction():void {
        commitTimer = getTimer();
        if(insertBacklog.length > 0) {
            commitWhenReady = true;
        } else {
            conn.addEventListener(SQLEvent.COMMIT, commitHandler);
            conn.commit();
        }
    }

    public function prepareInsert():void {

        insertStmt = new SQLStatement();
        insertStmt.sqlConnection = conn;
        insertStmt.text = "INSERT INTO main.logs (user, date, video_id, video_filename, play_state, playback_time, " +
                "playback_rate, selection_start, selection_end, active_highlight_colour, highlight_write_mode, " +
                "highlight_read_mode, view_count_record_read_mode, pause_record_read_mode, playback_rate_read_mode, " +
                "source, action, time, tFrom, tTo)" +
                " VALUES " +
                "(:user, :date, :video_id, :video_filename, :play_state, :playback_time, :playback_rate, :selection_start," +
                " :selection_end, :active_highlight_colour, :highlight_write_mode, :highlight_read_mode," +
                " :view_count_record_read_mode, :pause_record_read_mode, :playback_rate_read_mode," +
                " :source, :action, :time, :tFrom, :tTo);";
    }

    public function addRecord(  user:String,
                                date:Number,
                                video_id:int,
                                video_filename:String,
                                play_state:int,
                                playback_time:Number,
                                playback_rate:Number,
                                selection_start:Number,
                                selection_end:Number,
                                active_highlight_colour:int,
                                highlight_write_mode:String,
                                highlight_read_mode:int,
                                view_count_record_read_mode:int,
                                pause_record_read_mode:int,
                                playback_rate_read_mode:int,
                                source:String,
                                action:String,
                                time:Number,
                                tFrom:Number,
                                tTo:Number):void {

        insertBacklog.push(
                {   user:user,
                    date:date,
                    video_id:video_id,
                    video_filename:video_filename,
                    play_state:play_state,
                    playback_time:isNaN(playback_time) ? -1 : playback_time,
                    playback_rate:isNaN(playback_rate) ? -1 : playback_rate,
                    selection_start:isNaN(selection_start) ? -1 : selection_start,
                    selection_end:isNaN(selection_end) ? -1 : selection_end,
                    active_highlight_colour:active_highlight_colour,
                    highlight_write_mode:highlight_write_mode,
                    highlight_read_mode:highlight_read_mode,
                    view_count_record_read_mode:view_count_record_read_mode,
                    pause_record_read_mode:pause_record_read_mode,
                    playback_rate_read_mode:playback_rate_read_mode,
                    source: source,
                    action: action,
                    time: isNaN(time) ? -1 : time,
                    tFrom: isNaN(tFrom) ? -1 : tFrom,
                    tTo: isNaN(tTo) ? -1 : tTo
                });

        insertBacklogMaxLength = insertBacklog.length;

        if(!insertStmt.hasEventListener(SQLEvent.RESULT)) {

            insertStmt.addEventListener(SQLEvent.RESULT, insertResult);
            insertStmt.addEventListener(SQLErrorEvent.ERROR, errorHandler);

            executeNextInsert();
        }

    }

//    private var getLatestRecordDateSignal:Signal;
    public function getLatestRecordDate():Signal {
        var selectStmt:SQLStatement = new SQLStatement();
        selectStmt.sqlConnection = conn;

        selectStmt.text = "SELECT date from main.logs ORDER BY date DESC LIMIT 1";
        var getLatestRecordDateSignal:Signal = new Signal(Date);
        selectStmt.addEventListener(SQLEvent.RESULT,
                function returnGetLatestRecord(e:SQLEvent):void {
                    var result:SQLResult = e.target.getResult();

                    var numResults:int = result.data != null ? result.data.length : 0;

                    var date:Date = new Date();
                    if(numResults > 0) {
                        date.setTime(result.data[0].date);
                    } else {
                        date = new Date(2018, 0, 0);
                    }

                    getLatestRecordDateSignal.dispatch(date);
                });
        selectStmt.execute();


        return getLatestRecordDateSignal;
    }


    public function select(sql:String):Signal {

        var selectStmt:SQLStatement = new SQLStatement();
        selectStmt.sqlConnection = conn;

        selectStmt.text = sql;
        var signal:Signal = new Signal(Object);
        selectStmt.addEventListener(SQLEvent.RESULT,
                function returnGetLatestRecord(e:SQLEvent):void {

                    signal.dispatch(e.target.getResult());

                });
        selectStmt.execute();


        return signal;
    }

    private function executeNextInsert():void {
//        trace("insertBacklog.length" + insertBacklog.length)
        if(insertBacklog.length > 0) {

//            if(recordCount%100 == 0)
//                trace("executing: " + recordCount);

            recordCount++;


            var record:Object = insertBacklog.shift();

            insertStmt.parameters[":user"] = record.user;
            insertStmt.parameters[":date"] = record.date;
            insertStmt.parameters[":video_id"] = record.video_id;
            insertStmt.parameters[":video_filename"] = record.video_filename;
            insertStmt.parameters[":play_state"] = record.play_state;
            insertStmt.parameters[":playback_time"] = record.playback_time;
            insertStmt.parameters[":playback_rate"] = record.playback_rate;
            insertStmt.parameters[":selection_start"] = record.selection_start;
            insertStmt.parameters[":selection_end"] = record.selection_end;
            insertStmt.parameters[":active_highlight_colour"] = record.active_highlight_colour;
            insertStmt.parameters[":highlight_write_mode"] = record.highlight_write_mode;
            insertStmt.parameters[":highlight_read_mode"] = record.highlight_read_mode;
            insertStmt.parameters[":view_count_record_read_mode"] = record.view_count_record_read_mode;
            insertStmt.parameters[":pause_record_read_mode"] = record.pause_record_read_mode;
            insertStmt.parameters[":playback_rate_read_mode"] = record.playback_rate_read_mode;
            insertStmt.parameters[":source"] = record.source;
            insertStmt.parameters[":action"] = record.action;
            insertStmt.parameters[":time"] = record.time;
            insertStmt.parameters[":tFrom"] = record.tFrom;
            insertStmt.parameters[":tTo"] = record.tTo;

            insertStmt.execute();

            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, recordCount, insertBacklogMaxLength));

//        }
        } else {
            insertStmt.removeEventListener(SQLEvent.RESULT, insertResult);
            insertStmt.removeEventListener(SQLErrorEvent.ERROR, errorHandler);

            conn.addEventListener(SQLEvent.COMMIT, commitHandler);
            conn.commit();

        }
    }

    private function openHandler(event:SQLEvent):void {
//        trace("the database was created successfully");
        createTable();
    }

    private function beginHandler(event:SQLEvent):void {
        conn.removeEventListener(SQLEvent.BEGIN, beginHandler);
        dispatchEvent(event);
    }

    private function commitHandler(event:SQLEvent):void {
        trace("Commit time: " + (getTimer() - commitTimer) + ", record count: " + recordCount);
        conn.removeEventListener(SQLEvent.COMMIT, commitHandler);
        dispatchEvent(event);
    }

    public function createTable():void {

        var createStmt:SQLStatement = new SQLStatement();
        createStmt.sqlConnection = conn;

        var sql:String =
                "CREATE TABLE IF NOT EXISTS logs (" +
                "id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,"+
                "user TEXT NULL," +
                "date INT NULL,"+
                "video_id INTEGER NULL,"+
                "video_filename TEXT NULL,"+
                "play_state INTEGER NULL,"+
                "playback_time REAL NULL,"+
                "playback_rate REAL NULL,"+
                "selection_start REAL NULL,"+
                "selection_end REAL NULL,"+
                "active_highlight_colour INTEGER NULL,"+
                "highlight_write_mode TEXT NULL,"+
                "highlight_read_mode INTEGER NULL,"+
                "view_count_record_read_mode INT NULL,"+
                "pause_record_read_mode INTEGER NULL,"+
                "playback_rate_read_mode INTEGER NULL,"+
                "source TEXT NULL,"+
                "action TEXT NULL,"+
                "time REAL NULL,"+
                "tFrom REAL NULL,"+
                "tTo REAL NULL" +
                ")";
        createStmt.text = sql;

        createStmt.addEventListener(SQLEvent.RESULT, createResult);
        createStmt.addEventListener(SQLErrorEvent.ERROR, errorHandler);

        createStmt.execute();
    }


    private function errorHandler(event:SQLErrorEvent):void {
        trace("Error message:", event.error.message);
        trace("Details:", event.error.details);
    }


    private function createResult(event:SQLEvent):void {
//        trace("Table created");
//        dispatchEvent(new Event(Event.COMPLETE));

        dispatchEvent(new SQLEvent(SQLEvent.OPEN));
    }

    private function insertResult(e:SQLEvent):void {

        executeNextInsert();

    }

//    public function toString():String {
//        return "[Object UserLogDBManager]";
//    }

}
}
