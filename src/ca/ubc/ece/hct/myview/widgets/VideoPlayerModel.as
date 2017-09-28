////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets {
import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.*;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.Widget;

import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;

public class VideoPlayerModel {
	
		private var _video:VideoMetadata; 
		public function get video():VideoMetadata { return _video; }
		public var playing:Boolean;
		public var playheadTime:Number;
		public var playbackRate:Number;
		public var selection:Range;
		public var activeHighlightColour:int;

		public function get state():String {
			var stateString:String =
					"{" +
					  "\"videoID\":" + _video.media_alias_id + "," +
					  "\"videoFilename\":" + "\"" + _video.filename + "\"," +
					  "\"play_state\":" + "\"" + playing  + "\"," +
                      "\"playback_time\":" + playheadTime + "," +
                      "\"playback_rate\":" + playbackRate + "," +
                      "\"selection\":" + "\"" + selection +"\"," +
                      "\"active_highlight_colour\":" + "\"#" + activeHighlightColour.toString(16) + "\"," +
                      "\"highlight_write_mode\":" + "\"" + highlightWriteMode + "\"," +
                      "\"highlight_read_mode\":" + highlightReadMode + "," +
                      "\"view_count_read_mode\":" + viewCountRecordReadMode + "," +
                      "\"pause_record_read_mode\":" + pauseRecordReadMode + "," +
                      "\"playback_rate_read_mode\":" + playbackRateReadMode +
					"}"
			return stateString;
		}

		public function eventToJSON(source:*, ...args):String {

			if(args.length % 2 != 0) {
             	trace("args needs to be paired");
            }
			var eventString:String =
					"{" +
							"\"source\":\"" + source + "\",";
			for(var i:int = 0; i<args.length; i+=2) {
				eventString += "\"" + args[i] +"\":\"" + args[i+1] + "\",";
			}
			eventString = eventString.substr(0, eventString.length - 1);
			eventString += "}";

			return eventString;
		}

		// personal, class, instructor, hidden
		public var highlightReadMode:uint;
		public var viewCountRecordReadMode:uint;
		public var pauseRecordReadMode:uint;
		public var playbackRateReadMode:uint;
		
		// quick (select = highlight), slow (select first then highlight)
		public var highlightWriteMode:String;

		public var widgets:Array;
		private var _sendVCRTimer:Timer;

		public function VideoPlayerModel() {

			highlightReadMode		= UserDataViewMode.PERSONAL;
			viewCountRecordReadMode	= UserDataViewMode.PERSONAL;
			pauseRecordReadMode		= UserDataViewMode.PERSONAL;
			playbackRateReadMode	= UserDataViewMode.PERSONAL;

			highlightWriteMode = HighlightMode.PRE_SELECT;
			selection = new Range(0, 0);

			widgets = [];

			_sendVCRTimer = new Timer(10000);
			_sendVCRTimer.addEventListener(TimerEvent.TIMER, sendVCR);
		}

		public function loadVideo(video:VideoMetadata, interval:Range):void {
			_sendVCRTimer.start();
			_video = video;
            playheadTime = 0;
			playbackRate = 1;

//			ServerDataLoader.addLog(UserID.id, "loadVideo " + video.filename);
			ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(this, "action", "loadVideo", "video", _video.filename));
            ServerDataLoader.getCrowdHighlights(_video.media_alias_id).add(crowdHighlightsLoaded);
            ServerDataLoader.getCrowdVCRs(_video.media_alias_id).add(crowdVCRsLoaded);

			for each(var widget:Widget in widgets) {
				widget.loadVideo(video);//, interval);
			}
		}

		public function linkWidget(widget:Widget):void {
			widget.played.add(play);
			widget.stopped.add(stop);
			widget.seeked.add(seek);
			widget.selected.add(select);
			widget.selecting.add(selecting);
			widget.deselected.add(deselect);
			widget.playbackRateSet.add(setPlaybackRate);
			widget.playheadTimeUpdated.add(updatePlayhead);
			widget.highlightsViewModeSet.add(setHighlightReadMode);
			widget.viewCountRecordViewModeSet.add(setViewCountRecordReadMode);
			widget.highlightsWriteModeSet.add(highlightWriteModeSelected);
//			widget.startedPlayingIntervals.add();
//			widget.stoppedPlayingIntervals.add();
			widget.startedPlayingHighlights.add(startPlayingHighlights);
			widget.stoppedPlayingHighlights.add(stopPlayingHighlights);

			widgets.push(widget);
		}

		public function exit():void {
    		ServerDataLoader.setVCR(UserID.id, _video.media_alias_id, _video.userData.viewCountRecord);
			_video = null;
		}

		public function play(source:Widget):void {
			playing = true;
//			trace(state);
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "play", "time", playheadTime))
//            ServerDataLoader.addLog(UserID.id, source + " start playback from " + playheadTime);
			for each(var widget:Widget in widgets) {
				if(widget != source) 
					widget.play();
			}
		}

		public function stop(source:Widget):void {
			playing = false;
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "stop", "time", playheadTime))
//            ServerDataLoader.addLog(UserID.id, source + " stop playback at " + playheadTime);
			for each(var widget:Widget in widgets) {
				if(widget != source)
					widget.stop();
			}
		}

		private function updatePlayhead(source:Widget, time:Number):void {
			playheadTime = time;
			for each(var widget:Widget in widgets) {
				if(widget != source) 
					widget.playheadTime = time;
			}
		}

		private function seek(source:Widget, time:Number):void {
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "seek", "from", playheadTime, "to", time))
//            ServerDataLoader.addLog(UserID.id, source + " seek to " + time + " from " + playheadTime);
			for each(var widget:Widget in widgets) {
				if(widget != source)
					widget.receiveSeek(time);
			}
		}

		private function select(source:Widget, interval:Range):void {

			if(highlightWriteMode == HighlightMode.POST_SELECT) {
                ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "highlight", "interval", interval, "colour", "#" + activeHighlightColour.toString(16)));
//                ServerDataLoader.addLog(UserID.id, source + " highlight " + interval + " in #" + activeHighlightColour.toString(16));
                if (activeHighlightColour != 0xffffff) {
                    highlight(source, activeHighlightColour, interval);
            	} else if(activeHighlightColour == 0xffffff) {
					unhighlight(source, activeHighlightColour, interval);
				}

			} else if(highlightWriteMode == HighlightMode.PRE_SELECT) {
				selection = interval;
                ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "select", "selection", selection))
//                ServerDataLoader.addLog(UserID.id, source + " select " + interval);
				for each(var widget:Widget in widgets) {
					if(widget != source)
						widget.select(interval);
				}
			}
	    }

	    private function selecting(source:Widget, interval:Range):void {
	    	selection = interval;
			for each(var widget:Widget in widgets) {
				if(widget != source)
					widget.select(interval);
			}
	    }

	    private function deselect(source:Widget):void {
	    	selection = new Range(0, 0);
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "deselect", "selection", selection))
//            ServerDataLoader.addLog(UserID.id, source + " deselect");
			for each(var widget:Widget in widgets) {
				// if(widget != source)
				widget.deselect();
			}
	    }

		private function setPlaybackRate(source:Widget, rate:Number):void {
			playbackRate = rate;
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_playback_rate", "rate", rate))
//            ServerDataLoader.addLog(UserID.id, source + " changed playbackRate to " + rate);
            for each(var widget:Widget in widgets) {
                if(widget != source)
                    widget.setPlaybackRate(rate);
            }
		}

	    private function highlightWriteModeSelected(source:Widget, mode:String, colour:uint):void {

			trace("did this happen?");
			activeHighlightColour = colour;
			switch(selection.length > 0) {

				case false:
					highlightWriteMode = mode;
                    ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_highlight_write_mode", "mode", mode))
//                    ServerDataLoader.addLog(UserID.id, source + " set highlight write mode " + mode);
                    for each(var widget:Widget in widgets) {
						if(widget != source)
							widget.setHighlightsWriteMode(mode, colour);
					}
					break;

				case true:
					if(mode == HighlightMode.POST_SELECT) {
                        if (activeHighlightColour != 0xffffff) {
                            highlight(source, colour, selection);
                        } else if(activeHighlightColour == 0xffffff) {
                            unhighlight(source, colour, selection);
                        }

						highlightWriteMode = HighlightMode.PRE_SELECT;
						for each(var widget2:Widget in widgets) {
							widget2.setHighlightsWriteMode(highlightWriteMode, colour);
						}

					} else if(mode == HighlightMode.POST_SELECT) {
						// ??? You cannot select anything in POST_SELECT mode.
					}
					break;
			}
	    }

		private function highlight(source:Widget, colour:int, interval:Range):void {
	    	_video.userData.highlight(colour, interval);

	    	updateHighlights();
	    	deselect(source);

            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "highlight", "interval", interval, "colour", "#" + activeHighlightColour.toString(16)));
	    	ServerDataLoader.highlight(UserID.id, _video.media_alias_id, colour, _video.userData.highlights.grab(colour).toString());
	    }

	    private function unhighlight(source:Widget, colour:int, interval:Range):void {
	    	_video.userData.unhighlightAll(interval);

	    	updateHighlights();
	    	deselect(source);

            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "unhighlight", "interval", interval));
			var colours:Array = _video.userData.highlights.keys();
			for(var i:int = 0; i<colours.length; i++) {
		    	ServerDataLoader.highlight(UserID.id, _video.media_alias_id, colours[i], _video.userData.highlights.grab(colours[i]).toString());
			}
//	    	ServerDataLoader.highlight(UserID.id, _video.media_alias_id, colour, _video.userData.highlights.grab(colour).toString());
	    }

	    private function startPlayingHighlights(source:Widget, colour:int):void {

            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "play_highlights", "colour", colour.toString(16)))
//            ServerDataLoader.addLog(UserID.id, source + " startPlayingHighlights " + colour.toString(16))
	    	for each(var widget:Widget in widgets) {
	    		if(widget != source)
		    		widget.startPlayingHighlights(colour);
	    	}
	    }

		private function stopPlayingHighlights(source:Widget):void {
            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "stop_playing_highlights"))
//			ServerDataLoader.addLog(UserID.id, "stopPlayingHighlights");
			for each(var widget:Widget in widgets) {
				if(widget != source)
						widget.stopPlayingHighlights();
			}
		}

	    private function updateHighlights():void {
	    	for each(var widget:Widget in widgets) {
	    		widget.updateHighlights();
	    	}
	    }

		// bitwise or with UserDataViewMode
		private function setHighlightReadMode(source:Widget, mode:uint):void {
			var modeString:String = "";
            if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
				modeString += " HIDE ";
			}
            if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
				modeString += " CLASS ";
			}
			if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
				modeString += " PERSONAL ";
			}
			if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
				modeString += " INSTRUCTOR ";
			}

            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_highlight_read_mode", "mode", modeString))
//            ServerDataLoader.addLog(UserID.id, source + " highlightReadMode " + modeString);
			for each(var widget:Widget in widgets) {
	    		widget.setHighlightReadMode(mode);
	    	}
	    }
		private function setViewCountRecordReadMode(source:Widget, mode:uint):void {
            var modeString:String = "";
            if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
                modeString += " HIDE ";
            }
            if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
                modeString += " CLASS ";
            }
            if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
                modeString += " PERSONAL ";
            }
            if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
                modeString += " INSTRUCTOR ";
            }

            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_view_count_record_read_mode", "mode", modeString))
//            ServerDataLoader.addLog(UserID.id, source + " viewCountRecordReadMode " + modeString);
			for each(var widget:Widget in widgets) {
	    		widget.setViewCountRecordReadMode(mode);
	    	}
	    }
		private function setPauseRecordReadMode(source:Widget, mode:uint):void {
            var modeString:String = "";
            if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
                modeString += " HIDE ";
            }
            if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
                modeString += " CLASS ";
            }
            if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
                modeString += " PERSONAL ";
            }
            if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
                modeString += " INSTRUCTOR ";
            }

            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_pause_record_read_mode", "mode", modeString))
//            ServerDataLoader.addLog(UserID.id, source + " pauseRecordReadMode " + modeString);
			for each(var widget:Widget in widgets) {
	    		widget.setPauseRecordReadMode(mode);
	    	}
	    }
		private function setPlaybackRateRecordReadMode(source:Widget, mode:uint):void {
            var modeString:String = "";
            if((mode & UserDataViewMode.HIDE) == UserDataViewMode.HIDE) {
                modeString += " HIDE ";
            }
            if((mode & UserDataViewMode.CLASS) == UserDataViewMode.CLASS) {
                modeString += " CLASS ";
            }
            if((mode & UserDataViewMode.PERSONAL) == UserDataViewMode.PERSONAL) {
                modeString += " PERSONAL ";
            }
            if((mode & UserDataViewMode.INSTRUCTOR) == UserDataViewMode.INSTRUCTOR) {
                modeString += " INSTRUCTOR ";
            }

            ServerDataLoader.addLog_v2(UserID.id, state, eventToJSON(source, "action", "set_playback_rate_record_read_mode", "mode", modeString))
//            ServerDataLoader.addLog(UserID.id, source + " playbackRateRecordReadMode " + modeString);
			for each(var widget:Widget in widgets) {
	    		widget.setPlaybackRateRecordReadMode(mode);
	    	}
	    }

	    private function sendVCR(e:Event = null):void {
	    	if(_video != null) {
	    		ServerDataLoader.setVCR(UserID.id, _video.media_alias_id, _video.userData.viewCountRecord);
	    	}
	    }

        private function crowdVCRsLoaded(object:Object):void {
            var obj:* = JSON.parse((String)(object));

            for(var n:String in obj) {
				var user_string:String;
				var view_count_record_string:String;

                for(var m:String in obj[n]) {
					switch(m) {
						case "user_id":
                            user_string = obj[n][m];
							break;
						case "view_count_record":
                            view_count_record_string = obj[n][m];
							break;
					}
                }

				var userData:UserData = _video.grabCrowdUserData(UserData.CLASS, user_string);

				if(userData && view_count_record_string) {
					userData.view_count_record = view_count_record_string;
				} else if(view_count_record_string && user_string) {
					userData = new UserData();
					userData.userString = user_string;
					userData.view_count_record = view_count_record_string;
                    _video.addCrowdUserData(UserData.CLASS, userData);
                }
            }
        }

        private function crowdHighlightsLoaded(object:Object):void {
            var obj:* = JSON.parse((String)(object));
            for(var n:String in obj) {

				var user_string:String;
				var colour_string:String;
				var intervals_string:String;

                for(var m:String in obj[n]) {
					switch(m) {
						case "user_id":
							user_string = obj[n][m];
							break;
						case "colour":
							colour_string = obj[n][m];
							break;
						case "intervals":
							intervals_string = obj[n][m];;
							break;
					}
                }

                var userData:UserData = _video.grabCrowdUserData(UserData.CLASS, user_string);

                if(userData && colour_string && intervals_string) {
                    userData.setHighlights(colour_string, intervals_string);
                } else {
                    userData = new UserData();
                    userData.setHighlights(colour_string, intervals_string);
                    _video.addCrowdUserData(UserData.CLASS, userData);
                }
            }
        }
	}
}