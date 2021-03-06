////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

import ca.ubc.ece.hct.myview.common.Annotation;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import com.greensock.events.LoaderEvent;
import com.greensock.loading.*;

import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;

import org.osflash.signals.Signal;

public class ServerDataLoader {

	public static const LOGIN_PAGE:String = "login.php";
	public static const HIGHLIGHT_PAGE:String = "addHighlight.php";
	public static const ANNOTATE_PAGE:String = "addAnnotation.php";
	public static const GET_VIDEO_PAGE:String = "getVideo.php";
	public static const GET_COURSE_PAGE:String = "getCourseTest.php";
	public static const LOG_PAGE:String = "addLog.php";
	public static const LOG_PAGE_v2:String = "addLog_v2.php";
	public static const ADD_MEDIA_LOAD_LOG_PAGE:String = "addMediaLoadLog.php";
	public static const SET_VCR_PAGE:String = "setVCR.php";
	public static const UPLOAD_TRACES_PAGE:String = "addTraces.php";

	public static const GET_VCR_PAGE:String = "getCrowdVCRs.php";
	public static const GET_CROWD_HIGHLIGHTS_PAGE:String = "getCrowdHighlights.php";
	public static const QUERY_PAGE:String = "admin/query.php";
	public static const UPDATE_SLIDES_PAGE:String = "admin/updateSlides.php";
	private static var queue:LoaderMax = new LoaderMax( { name: "WebLoaderQueue", auditSize:false, autoLoad:true } );

	public static function login(userID:String):Signal {
		var signal:Signal = new Signal(Object);
		queue.append(
			new DataLoader("http://" + Constants.DOMAIN + "/" + LOGIN_PAGE + "?" +
						   "user=" + userID,
						   {signal: signal,
						onComplete: requestComplete }));
//			queue.load();
		return signal;
	}

	public static function annotate(userID:String, media_alias_id:String, annotation:Annotation):Signal {
		var urlString:String = "http://" + Constants.DOMAIN + "/" + ANNOTATE_PAGE + "?" +
								"user=" + userID + "&" +
								"media_alias_id=" + media_alias_id + "&" +
								"annotation_id=" + annotation.id + "&" +
								"colour=" + annotation.colour.toString(16) + "&" +
								"start_time=" + annotation.interval.start + "&" +
								"end_time=" + annotation.interval.end + "&" +
								"note=" + annotation.note + "&" +
								"delete=" + annotation.deleteFlag;

		trace(urlString);
		var signal:Signal = new Signal(Object);
		queue.append(
				new DataLoader(urlString,
						{signal: signal,
							onComplete: requestComplete }));
		return signal;
	}

	public static function highlight(userID:String, media_alias_id:String, colour:int, highlights:String):Signal {
		trace("http://" + Constants.DOMAIN + "/" + HIGHLIGHT_PAGE + "?" +
						   "user=" + userID + "&" +
						   "media_alias_id=" + media_alias_id + "&" +
						   "colour=" + colour.toString(16) + "&" +
						   "highlights=" + highlights);
		var signal:Signal = new Signal(Object);
		queue.append(
			new DataLoader("http://" + Constants.DOMAIN + "/" + HIGHLIGHT_PAGE + "?" +
						   "user=" + userID + "&" +
						   "media_alias_id=" + media_alias_id + "&" +
						   "colour=" + colour.toString(16) + "&" +
						   "highlights=" + highlights,
						   {signal: signal,
						onComplete: requestComplete }));
//			queue.load();
		return signal;
	}

	public static function getCourse(school:String, courseCode:String, courseSection:String, courseTerm:String, courseYear:String, userID:String = null):Signal {

		var urlString:String = "http://" + Constants.DOMAIN + "/" + GET_COURSE_PAGE + "?" +
			   "school=" + school + "&" +
			   "course_code=" + courseCode + "&" +
			   "course_section=" + courseSection + "&" +
			   "course_term=" + courseTerm + "&" +
			   "course_year=" + courseYear;
		urlString += (userID == null) ? "" : ("&user=" + userID);
		trace(urlString);
		var signal:Signal = new Signal(Object);
		queue.append(
			new DataLoader(urlString,
						   {signal: signal,
						onComplete: requestComplete }));
//			queue.load();
		return signal;
	}

	public static function getVideo(userID:String, mediaFilename:String):Signal {
		trace("http://" + Constants.DOMAIN + "/" + GET_VIDEO_PAGE + "?" +
			   "filename=" + mediaFilename + "&" +
			   "user=" + userID);
		var signal:Signal = new Signal(Object);
		queue.append(
			new DataLoader("http://" + Constants.DOMAIN + "/" + GET_VIDEO_PAGE + "?" +
						   "filename=" + mediaFilename + "&" +
						   "user=" + userID,
						   {signal: signal,
						onComplete: requestComplete }));
//			queue.load();
		return signal;
	}

	public static function setVCR(userID:String, media_alias_id:String, vcr:Vector.<Number>):Signal {
		// trace("http://" + Constants.DOMAIN + "/" + SET_VCR_PAGE + "?" +
		// 	   "media_alias_id=" + media_alias_id + "&" +
		// 	   "user=" + userID + "&vcr=");
		// trace(vcr.toString())

		var urlVar:URLVariables = new URLVariables();
		urlVar.vcr = vcr.toString();
		var request:URLRequest = new URLRequest(
								 "http://" + Constants.DOMAIN + "/" +
								 SET_VCR_PAGE + "?" +
								 "media_alias_id=" + media_alias_id + "&" +
								 "user=" + userID);
		request.data = urlVar;
		request.method = URLRequestMethod.POST;


		var signal:Signal = new Signal(Object);
		queue.append(
			new DataLoader(request,
						   {signal: signal,
						onComplete: requestComplete }));
//			queue.load();
		return signal;
	}

	public static function getCrowdVCRs(media_alias_id:String):Signal {
		trace("http://" + Constants.DOMAIN + "/" + GET_VCR_PAGE + "?" +
				"media_alias_id=" + media_alias_id);
		var signal:Signal = new Signal(Object);
		queue.append(
				new DataLoader("http://" + Constants.DOMAIN + "/" + GET_VCR_PAGE + "?" +
						"media_alias_id=" + media_alias_id,
						{signal: signal,
							onComplete: requestComplete }));
//            queue.load();
		return signal;
	}

	public static function getCrowdHighlights(media_alias_id:String):Signal {
		trace("http://" + Constants.DOMAIN + "/" + GET_CROWD_HIGHLIGHTS_PAGE + "?" +
				"media_alias_id=" + media_alias_id);
		var signal:Signal = new Signal(Object);
		queue.append(
				new DataLoader("http://" + Constants.DOMAIN + "/" + GET_CROWD_HIGHLIGHTS_PAGE + "?" +
						"media_alias_id=" + media_alias_id,
						{signal: signal,
							onComplete: requestComplete }));
//            queue.load();
		return signal;
	}

	public static function addLog(userID:String, message:String):Signal {
		trace("http://" + Constants.DOMAIN + "/" + LOG_PAGE + "?" +
			   "message=" + message + "&" +
			   "user=" + userID);
		var signal:Signal = new Signal(Object);
		queue.append(
			new DataLoader("http://" + Constants.DOMAIN + "/" + LOG_PAGE + "?" +
						   "message=" + message + "&" +
						   "user=" + userID,
						   {signal: signal,
						onComplete: requestComplete }));
//			queue.load();
		return signal;
	}


	public static var sessionSequence:Number = 0;

	public static function addLog_v2(userID:String, state:String, event:String):Signal {
		var urlVar:URLVariables = new URLVariables();
		urlVar.user = userID;
		urlVar.state = state;
		urlVar.event = event;
		urlVar.sessionSequence = sessionSequence++;

		var myDate:Date = new Date();
		urlVar.clientDateTime = myDate.fullYear + "-" + (myDate.month+1) + "-" + myDate.date + " " +
								myDate.hours + ":" + myDate.minutes + ":" + myDate.seconds;
		var request:URLRequest = new URLRequest("http://" + Constants.DOMAIN + "/" + LOG_PAGE_v2);
		request.data = urlVar;
		request.method = URLRequestMethod.POST;

		var signal:Signal = new Signal(Object);
		queue.append( new DataLoader(request, {signal: signal, onComplete: requestComplete }) );
//            queue.load();
		return signal;
	}

	public static function addLoadMediaLog(userID:String, mediaAliasID:String):Signal {
		var urlVar:URLVariables = new URLVariables();
		urlVar.user = userID;
		urlVar.media_alias_id = mediaAliasID;

		var myDate:Date = new Date();
		urlVar.clientDateTime = myDate.fullYear + "-" + (myDate.month+1) + "-" + myDate.date + " " +
				myDate.hours + ":" + myDate.minutes + ":" + myDate.seconds;
		var request:URLRequest = new URLRequest("http://" + Constants.DOMAIN + "/" + ADD_MEDIA_LOAD_LOG_PAGE);
		request.data = urlVar;
		request.method = URLRequestMethod.GET;

		var signal:Signal = new Signal(Object);
		queue.append( new DataLoader(request, {signal: signal, onComplete: requestComplete }) );
//            queue.load();
		return signal;
	}

	public static function uploadTraces(userID:String, traces:String):Signal {

		var urlVar:URLVariables = new URLVariables();
		urlVar.user = userID;
		urlVar.traces = traces;
		var request:URLRequest = new URLRequest("http://" + Constants.DOMAIN + "/" + UPLOAD_TRACES_PAGE);
		request.data = urlVar;
		request.method = URLRequestMethod.POST;

		var signal:Signal = new Signal(Object);
		queue.append( new DataLoader(request, {signal: signal, onComplete: requestComplete }) );
//            queue.load();
		return signal;
	}

	public static function getVCRsForMediaAliasID(media_alias_id:String):Signal {

		trace("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?vcr&" +
				"media_alias_id=" + media_alias_id + "&user_string=" + COURSE::Name);
		var signal:Signal = new Signal(Object);
		queue.append(
				new DataLoader("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?vcr&" +
						"media_alias_id=" + media_alias_id + "&user_string=" + COURSE::Name,
						{signal: signal,
							onComplete: requestComplete }));
		queue.load();
		return signal;
	}

	public static function getVCRsForMediaAliasIDs(media_alias_ids:String):Signal {

		trace("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?vcr&" +
				"media_alias_ids=" + media_alias_ids + "&user_string=" + COURSE::Name);
		var signal:Signal = new Signal(Object);
		queue.append(
				new DataLoader("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?vcr&" +
						"media_alias_ids=" + media_alias_ids + "&user_string=" + COURSE::Name,
						{signal: signal,
							onComplete: requestComplete }));
		queue.load();
		return signal;
	}

	public static function getActiveUsers():Signal {

		trace("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?active_users&user_string=" + COURSE::Name);
		var signal:Signal = new Signal(Object);
		queue.append(
				new DataLoader("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?active_users&user_string=" + COURSE::Name,
						{signal: signal,
							onComplete:requestComplete }));
		queue.load();
		return signal;
	}

	public static function getRecentMedia(from:Date, to:Date):Signal {
        trace("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?media_loads&user_string=" + COURSE::Name +
                "&from=" + Util.dateToISO8601(from) +
                "&to=" + Util.dateToISO8601(to));

        var signal:Signal = new Signal(Object);
        queue.append(
                new DataLoader("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?media_loads&user_string=" + COURSE::Name +
                        "&from=" + Util.dateToISO8601(from) +
                        "&to=" + Util.dateToISO8601(to),
                        {signal: signal,
                            onComplete: requestComplete }));
        queue.load();
        return signal;
    }

	public static function getUsers():Signal {
		trace("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?get_users&user_string=" + COURSE::Name);

		var signal:Signal = new Signal(Object);
		queue.append(
				new DataLoader("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?get_users&user_string=" + COURSE::Name,
						{signal: signal,
							onComplete: requestComplete }));
		queue.load();
		return signal;
	}

	public static function getMediaLastLoads(media_alias_ids:String):Signal {

		trace("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?last_viewed&" +
				"media_alias_ids=" + media_alias_ids + "&user_string=" + COURSE::Name);
		var signal:Signal = new Signal(Object);
		queue.append(
				new DataLoader("http://" + Constants.DOMAIN + "/" + QUERY_PAGE + "?last_viewed&" +
						"media_alias_ids=" + media_alias_ids + "&user_string=" + COURSE::Name,
						{
							signal: signal,
							onComplete: requestComplete
						}));
		queue.load();
		return signal;
	}

	public static function updateSlidesOnline(video:VideoMetadata):Signal {

		var url:String = "http://" + Constants.DOMAIN + "/" + UPDATE_SLIDES_PAGE + "?slides=" +  video.slides.toString() + "&media_id=" + video.id;

        trace(url);
        var signal:Signal = new Signal(Object);
        queue.append(
                new DataLoader(url,
                        {
                            signal: signal,
                            onComplete: requestComplete
                        }));
        queue.load();
        return signal;
	}

		public static function requestComplete(e:LoaderEvent):void {
//			trace("Target content: " + e.target.content);
			(Signal)(e.target.vars.signal).dispatch(e.target.content);
		}
	}
}