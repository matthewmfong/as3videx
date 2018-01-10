////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.video {
import ca.ubc.ece.hct.myview.*;

import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylist;

import com.greensock.*;
	import com.greensock.loading.*;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.display.*;
	import flash.filesystem.File;
import flash.net.SharedObject;
import flash.utils.ByteArray;
	import flash.utils.getTimer;

	import org.osflash.signals.Signal;
	
	import collections.HashMap;

	public class VideoMetadataManager {

		public static var COURSE:Course;
		public static var videos:HashMap = new HashMap();
		public static var playlist:VideoPlaylist;
		public static const videosFolder:String = "videos";
		public static const captionsFolder:String = "captions";
		public static const thumbnailsFolder:String = "thumbnails";
		public static const preferredWidth:Number = 1280;
		public static const preferredHeight:Number = 720;
		public static var videoMetadataLoaded:Signal;
		public static var checkingLocalFiles:Signal;
		public static var downloadingSources:Signal;
		public static var downloadedSources:Signal;

		public static var courseLoaded:Signal;
		public static var lastRefreshedCaptions:SharedObject;
		public static var refreshCaptions:Boolean;

	    public static function init():void {
			videoMetadataLoaded = new Signal(); // filename loaded
			checkingLocalFiles = new Signal();
			downloadingSources = new Signal();
			downloadedSources = new Signal();

			lastRefreshedCaptions = SharedObject.getLocal("last_refreshed_captions");

			if(lastRefreshedCaptions.size == 0 /* so didn't exist */ ||
                    new Date().time - lastRefreshedCaptions.data.unixTime > (24 * 60 * 60 * 1000)) {

				refreshCaptions = true;
				lastRefreshedCaptions.data.unixTime = new Date().time;
			} else {
				refreshCaptions = false;
			}


			var dir:File = File.applicationStorageDirectory;
			dir.nativePath += "/" + videosFolder;
			dir.createDirectory();
			dir = File.applicationStorageDirectory;
			dir.nativePath += "/" + captionsFolder;
			dir.createDirectory();

			videos = new HashMap();
			playlist = new VideoPlaylist();

			courseLoaded = new Signal();
	    }

	    public static function loadCourse(school:String,
	                                      courseCode:String,
	                                      courseSection:String,
	                                      courseTerm:String,
	                                      courseYear:String,
	                                      userID:String = null):Signal {
			COURSE = new Course(school, courseCode, courseCode, courseTerm, courseYear);
	    	ServerDataLoader.getCourse(school, courseCode, courseSection, courseTerm, courseYear, userID).add(courseJSONLoaded);
	    	return courseLoaded;
	    }

	    public static function getVideo(videoFilename:String):VideoMetadata {
	    	return videos.grab(videoFilename);
	    }

		public static function getVideos():Array {
			return videos.values();
		}

		private static function courseJSONLoaded(object:Object):void {
			var obj:* = JSON.parse((String)(object));

            COURSE.startDate = Util.dateParser(obj['start_date']);
            COURSE.endDate = Util.dateParser(obj['end_date']);

			playlist = parsePlaylist(obj, "\t");
			playlist.listName = "root";

			// trace("_______________________");
			// trace("Final playlist:");
			// trace(playlist.stringAsRootPlaylist());
			checkingLocalFiles.dispatch();
			var sourcesToDownload:Array = [];
			var vs:Array = videos.values();
			for(var i:int = 0; i<vs.length; i++) {

				// if(vs[i].completedDownload)
				
				var sources:Array = vs[i].getSources();
				for(var j:int = 0; j<sources.length; j++) {
					sources[j].localPath = checkIfFileExistsLocally(sources[j].url, sources[j].id);
				}

				var newSources:Array = pickSourcesToDownload(vs[i]);
				for(var k:int = 0; k<newSources.length; k++) {
					if(newSources[k].extension == "vtt" || newSources[k].extension == "srt") {
                        sourcesToDownload.insertAt(0, newSources[k]);
                    } else {
                        sourcesToDownload.push(newSources[k]);
                    }
				}
			}

			courseLoaded.dispatch();

//			for each(var source:Source in sourcesToDownload) {
//				trace(source.url);
//			}
			downloadSources(sourcesToDownload);

			function checkIfFileExistsLocally(url:String, mediaID:String):String {

				var urlSplit:Array = url.split("/");
				var filename:String = urlSplit[urlSplit.length - 1];
				var filenameSplit:Array = filename.split(".");
				var extension:String = filenameSplit[filenameSplit.length - 1];

				var localFile:File = File.applicationStorageDirectory;

				switch(extension) {
					case "mkv":
					case "mp4":
					case "flv":
						localFile.nativePath += ("/" + videosFolder + "/" + mediaID + "-" + filename);
						break;
					case "vtt":
					case "srt":
						// for now, refresh captions every 24 hours.
						if(refreshCaptions)
							return null;
						else
							localFile.nativePath += ("/" + captionsFolder + "/" + mediaID + "-" + filename);
						break;
                    case "atf":
                    case "xml":
                        localFile.nativePath += ("/" + thumbnailsFolder + "/" + filename);
                        break;
				}

				return localFile.exists ? localFile.nativePath : null;
			}

			function pickSourcesToDownload(video:VideoMetadata):Array {

				var urlsToDownload:Array = [];
				var priorities:Array = [];
				for(var i:int = 0; i<video.source.length; i++) {
					priorities.push(int.MAX_VALUE);
				}

				for(i = 0; i<video.source.length; i++) {
					switch(video.source[i].mimeType) {
						case "mkv":
						case "mp4":
						case "flv":
							var priority:Number = 1;
							priority *= Math.abs(sources[i].width - preferredWidth);
							priority *= Math.abs(sources[i].height - preferredHeight);
							priority += (sources[i].mimeType == "mp4" ? 1 : 0);
							priority += (sources[i].mimeType == "mkv" ? 2 : 0);
							priority += (sources[i].mimeType == "flv" ? 3 : 0);
							priorities[i] = priority;
							// trace(sources[i].url + ": " + priority);
							break;

						case "vtt":
                        case "srt":
                            if(sources[i].localPath == null) {
                                video.totalNumberOfSourcesToDownload++;
                                urlsToDownload.push(sources[i]);
                            }
							break;
                        case "atf":
                        case "xml":
                            if(sources[i].localPath == null) {
                                video.totalNumberOfSourcesToDownload++;
                                urlsToDownload.push(sources[i]);
                            }
                            break;
					}
				}

				var maxPriority:Number = int.MAX_VALUE;
				var maxPriorityIndex:Number = 0;
				for(i = 0; i<priorities.length; i++) {
					if(priorities[i] < maxPriority) {
						maxPriority = priorities[i];
						maxPriorityIndex = i;
					}
				}

				video.primarySource = maxPriorityIndex;

				if(sources[maxPriorityIndex] && sources[maxPriorityIndex].localPath == null) {
					video.totalNumberOfSourcesToDownload++;
					urlsToDownload.push(sources[maxPriorityIndex]);
				}
				else if(video.totalNumberOfSourcesToDownload == video.totalNumberOfSourcesDownloaded) {
					video.progressDownloaded = 1;
				}

//                trace("\t\txxx" + video.filename + " " + video.totalNumberOfSourcesToDownload);
				return urlsToDownload;
			}
		}

		private static function parsePlaylist(obj:*, tabs:String = "", verbose:Boolean = false):VideoPlaylist {
			var playlist:VideoPlaylist = new VideoPlaylist();
			playlist.listName = "root";

			for(var playlistObjectName:* in obj["playlist"]) {

				switch(typeof(playlistObjectName)) {
					case "number":
						if(verbose)
							trace(tabs + obj["playlist"][playlistObjectName]["filename"]);

						var video:VideoMetadata = parseMedia(obj["playlist"][playlistObjectName]);

						if(!videos.containsKey(video.toString()))
							videos.put(video.toString(), video);

						playlist = insertIntoPlaylist(playlist, videos.grab(video.toString()));
						break;
					case "string":
						if(verbose)
							trace(tabs + "Name: " + playlistObjectName);
						
						var subPlaylist:VideoPlaylist = new VideoPlaylist();
						subPlaylist.listName = playlistObjectName;

						for(var playlistProperty:String in obj["playlist"][playlistObjectName]) {
							switch(playlistProperty) {
								case "release_date":
									subPlaylist.release_date = obj["playlist"][playlistObjectName][playlistProperty];
									if(verbose)
										trace(tabs + "\trelease_date = " + subPlaylist.release_date);
									break;
								case "view_order":
									subPlaylist.view_order = obj["playlist"][playlistObjectName][playlistProperty];

									if(verbose)
										trace(tabs + "\tview_order = " + subPlaylist.view_order);
									break;
								case "playlist":
									if(verbose)
										trace(tabs + "\tplaylist: ");
									var listName:String = playlistObjectName;
									var release_date:String = subPlaylist.release_date;
									var view_order:Number = subPlaylist.view_order;

									subPlaylist = parsePlaylist(obj["playlist"][playlistObjectName], tabs + "\t\t");
									subPlaylist.listName = listName;
									subPlaylist.release_date = release_date;
									subPlaylist.view_order = view_order;

									break;
							}
						}
						playlist = insertIntoPlaylist(playlist, subPlaylist);
						break;
					default:
						trace("something broke...");
						break;
				}
				
			}
			if(verbose)
				trace(tabs + "playlist.mediaList.length = " + playlist.mediaList.length);

			return playlist;
		}

		private static function insertIntoPlaylist(insertee:VideoPlaylist, insert:*):VideoPlaylist {
			if(insertee.mediaList.length > 0) {
				var inserted:Boolean = false;
				for(var i:int = 0; i<insertee.mediaList.length; i++) {

					if(insertee.mediaList[i].view_order >= insert.view_order) {
						insertee.insertAt(i, insert);
						inserted = true;
						break;
					}
				}
				if(!inserted) {
					insertee.insertAt(insertee.mediaList.length, insert);
				}
			} else {
				insertee.insertAt(insertee.mediaList.length, insert);
			}

			return insertee;
		}

		public static function parseMedia(obj:Object):VideoMetadata {
			var video:VideoMetadata = new VideoMetadata();
			for(var id:String in obj) {
				switch(id) {
					case "source":
						for(var typeid:String in obj[id]) {
							switch(typeid) {
								case "texture":
								case "texture_atlas":
								case "video":
								case "subtitle":
									for(var mimetypeid:String in obj[id][typeid]) {
										// trace("\t" + mimetypeid);
										for(var sourceid:String in obj[id][typeid][mimetypeid]) {

											var vso:Object = obj[id][typeid][mimetypeid][sourceid];

											var keyframes:Array = [];
											if(vso.keyframes != null) {
												var keyframesString:String = vso.keyframes;
												var keyframesArray:Array = keyframesString.split(",");

												for(var i:int = 0; i<keyframesArray.length; i++) {
													keyframes.push( Number(keyframesArray[i]));
												}
											}

											video.addSource(vso.id,
															vso.url,
															Number(vso.width), Number(vso.height),
															mimetypeid,
															Number(vso.framerate),
															keyframes,
															vso.language);
										}
									}
									break;
								default:
									break;
							}
						}
						break;
					case "slides":
						var slides:Vector.<Number> = new Vector.<Number>();
						if(obj[id] != null) {
							var slidesString:String = obj[id];
							var slidesArray:Array = slidesString.split(",");

							for(var slideArrayIndex:int = 0; slideArrayIndex<slidesArray.length; slideArrayIndex++) {
								slides.push(Number(slidesArray[slideArrayIndex]));
							}
						}

						video.slides = slides;
						break;

					case "tiles":
						for(var tileid:String in obj[id]) {

							// trace(tileid + " " + obj[id][tileid].frame_width)
							var tso:Object = obj[id][tileid];

							video.addTileSource(tso.folder_url, 
												tso.frame_width, tso.frame_height,
												tso.framerate,
												tso.num_tiles,
												tso.num_frames_per_tile);
						}
						break;
					case "user_data":
						for(var userdataid:String in obj[id]) {

							var userData:UserData = video.userData;
							switch(userdataid) {

								case "view_count_record":
								case "pause_record":
								case "playback_rate_record":
									userData[userdataid] = (obj[id][userdataid] == null) ? null : obj[id][userdataid];
									break;
								case "highlights":
									for(var highlightid:String in obj[id][userdataid]) {

										var ho:Object = obj[id][userdataid][highlightid]

										userData.setHighlights(ho.colour, ho.highlights);
									}
									break;
							}
						}
						break;
					case "course_admin":
						for(var adminID:String in obj[id]) {
							var adminUserData:UserData = new UserData();
							adminUserData.userString = adminID;
							for(var adminuserdataid:String in obj[id][adminID]) {

								switch(adminuserdataid) {

									case "view_count_record":
									case "pause_record":
									case "playback_rate_record":
										adminUserData[adminuserdataid] = (obj[id][adminID][adminuserdataid] == null) ? null : obj[id][adminID][userdataid];
										break;
									case "highlights":
										for(var adminhighlightid:String in obj[id][adminID][adminuserdataid]) {
											var aho:Object = obj[id][adminID][adminuserdataid][adminhighlightid];

											adminUserData.setHighlights(aho.colour, aho.highlights);
										}
										break;
								}
							}
							video.addCrowdUserData(UserData.INSTRUCTOR, adminUserData);
						}

						break;
					case "id":
					case "filename":
					case "duration":
					case "title":
					case "author":
					case "description":
					case "view_order":
					case "media_alias_id":
						video[id] = (obj[id] == null) ? null : obj[id];
						break;
				}
			}

			while(video.userData.viewCountRecord.length < video.duration + 1) {
				video.userData.viewCountRecord.push(0);
			}

			while(video.userData.pauseRecord.length < video.duration + 1) {
				video.userData.pauseRecord.push(0);
			}

			while(video.userData.playbackRateRecord.length < video.duration + 1) {
				video.userData.playbackRateRecord.push(0);
			}

			return video;
		}

		private static var sourcesDownloaded:int;
		private static function downloadSources(sourcesToDownload:Array, verbose:Boolean = false):void {
			downloadingSources.dispatch();
			sourcesDownloaded = 0;
			// create a LoaderMax named "mainQueue" and set up onProgress, onComplete and onError listeners
			var queue:LoaderMax = new LoaderMax({name:"mainQueue", autoLoad:true, onChildProgress:progressHandler, onChildComplete:completeHandler, onChildError:errorHandler});

			if(verbose)
				trace("Download Queue:");
			for(var i:int = 0; i<sourcesToDownload.length; i++) {
				if(verbose)
					trace(sourcesToDownload[i].url);
				sourcesToDownload[i].localPath = File.applicationStorageDirectory + "/" + videosFolder + "/" + sourcesToDownload[i].id + "-" + sourcesToDownload[i].filename;
				queue.append( new DataLoader(sourcesToDownload[i].url, {name:i, format:"binary"}) );
			}

			if(sourcesDownloaded == sourcesToDownload.length) {
				downloadedSources.dispatch();
			}

			function progressHandler(event:LoaderEvent):void {
				sourcesToDownload[event.target.name].progress = event.target.progress;
//			     trace("progress: " + event.target.progress + " " + sourcesToDownload[event.target.name].url);
			}
			function completeHandler(event:LoaderEvent):void {
				var filename:String = sourcesToDownload[event.target.name].filename;
				var filenameSplit:Array = filename.split(".");
				var extension:String = filenameSplit[filenameSplit.length - 1];

				var localFile:File = File.applicationStorageDirectory;

				switch(extension) {
					case "mp4":
					case "mkv":
					case "flv":
						Util.writeBytesToFile(videosFolder + "/" + sourcesToDownload[event.target.name].id + "-" + sourcesToDownload[event.target.name].filename, event.target.content);
						localFile.nativePath += ("/" + videosFolder + "/" + sourcesToDownload[event.target.name].id + "-" + sourcesToDownload[event.target.name].filename);
						break;
                    case "vtt":
                    case "srt":
                        Util.writeBytesToFile(captionsFolder + "/" + sourcesToDownload[event.target.name].id + "-" + sourcesToDownload[event.target.name].filename, event.target.content);
                        localFile.nativePath += ("/" + captionsFolder + "/" + sourcesToDownload[event.target.name].id + "-" + sourcesToDownload[event.target.name].filename);
                        break;
                    case "atf":
                    case "xml":
                        Util.writeBytesToFile(thumbnailsFolder + "/" + sourcesToDownload[event.target.name].filename, event.target.content);
                        localFile.nativePath += ("/" + thumbnailsFolder + "/" + sourcesToDownload[event.target.name].filename);
                        break;
				}
				sourcesToDownload[event.target.name].localPath = localFile.nativePath;
                sourcesToDownload[event.target.name].progress = 1;
				sourcesToDownload[event.target.name].complete = true;

				sourcesDownloaded++;
				if(sourcesDownloaded == sourcesToDownload.length) {
					downloadedSources.dispatch();
				}
			}
			 
			function errorHandler(event:LoaderEvent):void {
			    trace("error occurred with " + event.target + ": " + event.text);
			}
		}
	}
}