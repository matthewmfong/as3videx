////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.myview.widgets.filmstrip.*;
import ca.ubc.ece.hct.myview.*;

import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;

import fl.controls.Button;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.navigateToURL;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	import ca.ubc.ece.hct.myview.widgets.player.WebPlayer;
	import ca.ubc.ece.hct.myview.ui.button.ImageButton;
	import ca.ubc.ece.hct.ImageLoader;

	import flash.utils.Timer;
	import flash.events.TimerEvent;

	import ca.ubc.ece.hct.myview.ui.FloatingTextField;


	public class WebSlideFilmstripTest extends MovieClip {

		private var video:VideoMetadata;
		private var videoPlayer:WebPlayer;
		private var sf:WebSlideFilmstrip;
		private var sf2:WebSimpleFilmstrip;
		// assign random enum to strips
		private var SLIDESTRIP:uint;
		private var FILMSTRIP:uint
		private var highlightButtons:Array;

		public static var highlightMode:Boolean = false;
		public static var highlightColour:uint = 0;
		public static var selectionRange:ca.ubc.ece.hct.Range;

		private static var _videoFilename:Array = [//"testMovie2.mp4",
													 // "Supply and Demand - CAPTIONED-WdPI3hKUJYo.mp4",
													 "10_CharacterStringsReview.mp4",
													 "The Trolley Problem (with a Twist)-kKHOpw6tpd4.mp4"
													 ];
		private static var _studyStage:int = -1;
		// private static var _searchLocation:Array = [ [40, 80, 120],
		// 											   [40, 80, 120] ];
	   	private static var _searchLocation:Array = [ [new Range(16, 34), 		// Definition of Supply
	   												  new Range(96, 112), 		// Example about 1000 umbrellas @ $100 constituting to surplus and $1 umbrellas constituting to shortage
	   												  new Range(112, 125)], 	// Where would we expect to see prices in our supply and demand model?
	 												 [new Range(19, 26), 		// What's the catch of the classic trolley problem?
	   												  new Range(49, 66), 		// Explanation of the twist
	   												  new Range(103, 111)]]; 	// how many animals
		private static const _filmstripInstructions:String = "https://research.hct.ece.ubc.ca/myview/study/201705_CHI/filmstrip.png";
		private static const _slidestripInstructions:String = "https://research.hct.ece.ubc.ca/myview/study/201705_CHI/slidestrip.png";
		private static var _searchInstructions:Array = [ ["Find the definition of Supply.",
														  "Find the example about 1000 umbrellas @ $100 constituting to surplus and $1 umbrellas constituting to shortage.",
														  "Find the explanation of where would we expect to see prices in our supply and demand model."],
														 ["Find the catch of the classic trolley problem.",
														  "Find the introduction of the twist of the trolley problem. (animals)",
														  "Find how many animals you can save if you went on a vegan diet for a year."] ];

		private static var searchInstructionsText:FloatingTextField;
		private static var studySearch:ca.ubc.ece.hct.Range;
		private var nextStageTimer:Timer;
		private var timeForNextStage:Number;
		private var timeOfNextStage:Number;

		private var instructionOverlay:Sprite;
		private var instructionImage:ImageLoader;
		private var dismissInstructionsButton:Button;
		private var timerStart:Number;

		private var nextStageButton:Button;

		public function WebSlideFilmstripTest() {

			UserID.login();
			UserID.loggedIn.add(
				function load():void {
					// loadVideo(_videoFilename[0]);
					nextStage();
				});

			init();

		}

		public function init():void {
			stage.addEventListener(KeyboardEvent.KEY_DOWN,
				function keyDown(e:KeyboardEvent):void {
					switch(e.charCode) {
						case 13: // enter
							nextStage();
							break;
					}
				});

			// randomize strips
			var rand:Number = Math.random();
			if(rand > 0.5) {
				SLIDESTRIP = 0;
				FILMSTRIP = 1;
			} else {
				SLIDESTRIP = 1;
				FILMSTRIP = 0;
			}

			trace("Filmstrip = " + FILMSTRIP + ", Slidestrip = " + SLIDESTRIP);

			// randomize video order
			var videoFilename:Array = [];
			var searchInstructions:Array = [];
			var searchLocation:Array = [];
			rand = Math.random();
			if(rand > 0.5) {
				videoFilename.push(_videoFilename[0]);
				videoFilename.push(_videoFilename[1]);
				searchInstructions.push(_searchInstructions[0]);
				searchInstructions.push(_searchInstructions[1]);
				searchLocation.push(_searchLocation[0]);
				searchLocation.push(_searchLocation[1]);
			} else {
				videoFilename.push(_videoFilename[1]);
				videoFilename.push(_videoFilename[0]);
				searchInstructions.push(_searchInstructions[1]);
				searchInstructions.push(_searchInstructions[0]);
				searchLocation.push(_searchLocation[1]);
				searchLocation.push(_searchLocation[0]);
			}
			_videoFilename = videoFilename;
			_searchInstructions = searchInstructions;
			_searchLocation = searchLocation;

			trace(_videoFilename[0] + ", " + _videoFilename[1]);
			trace(_searchInstructions[0] + ", " + _searchInstructions[1]);

			// randomize video search area/instructions
			for(var i:int = 0; i<_searchLocation.length; i++) {
				var searchLocation:Array = [];
				var searchInstructions:Array = [];
				while(_searchLocation[i].length > 0) {
					rand = Math.floor(Math.random() * _searchLocation[i].length);
					
					searchLocation.push(_searchLocation[i].splice(rand, 1)[0]);
					searchInstructions.push(_searchInstructions[i].splice(rand, 1));
				}
				_searchLocation[i] = searchLocation;
				_searchInstructions[i] = searchInstructions;
			}

			trace(_searchLocation[0]);
			trace(_searchInstructions[0]);
			trace(_searchLocation[1]);
			trace(_searchInstructions[1]);

			VideoLoader.init();

			instructionImage = new ImageLoader();
			instructionOverlay = new Sprite();
			instructionOverlay.graphics.beginFill(0, 0.9);
			instructionOverlay.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			instructionOverlay.graphics.endFill();
			dismissInstructionsButton = new Button();
			dismissInstructionsButton.label = "Dismiss";
			dismissInstructionsButton.addEventListener(MouseEvent.CLICK, dismissInstructions);
			dismissInstructionsButton.x = stage.stageWidth/2 - dismissInstructionsButton.width/2;
			dismissInstructionsButton.y = stage.stageHeight - 50;

			nextStageButton = new Button();
			nextStageButton.label = "Next -->";
			nextStageButton.x = stage.stageWidth - nextStageButton.width;
			nextStageButton.y = stage.stageHeight - nextStageButton.height;
			nextStageButton.addEventListener(MouseEvent.CLICK, 
				function nextStageButtonClick(e:MouseEvent):void {
					nextStage();
				});
			addChild(nextStageButton);

			nextStageTimer = new Timer(60000);
			nextStageTimer.addEventListener(TimerEvent.TIMER,
				function nextStageTimerUp(e:TimerEvent):void {
					nextStageButton.enabled = true;
					nextStageButton.label = "Next -->";
					nextStageTimer.reset();
				});

			stage.addEventListener(Event.ENTER_FRAME,
				function enterFrame(e:Event):void {
					if(nextStageButton.enabled == false) {
						nextStageButton.label = Math.floor((timeOfNextStage - getTimer())/1000).toString();
					}
				});

			searchInstructionsText = new FloatingTextField("", new TextFormat("Arial", 20, 0x66ff66, true, false, false, null, null, "center", null, null, null, 4));

			// VideoLoader.metadataDownloaded.add(
			// 	function metadataDownloaded():void {
			// 		trace("downloaded metadata");
			// 	})
			// VideoLoader.thumbnailsProgress.add(
			// 	function thumbnailsProgress(progress:Number):void {
			// 		// trace("Thumbnail download progress: " + Math.round(progress * 10000)/100 + "%");
			// 	});
			
		}

		public function nextStage():void {
			_studyStage++;
			if(_studyStage > 0 && _studyStage <= 2) {
				ServerDataLoader.setVCR(UserID.id, video.filename, video.userData.viewCountRecord);
			}

			// showInstructions(_studyStage);
			switch(_studyStage) {
				case 0:
					// watch video
					trace("study stage = " + _studyStage);
					timeForNextStage = 60000;
					loadVideo(_videoFilename[0], 0);
					break;
				case 1:
					// watch video
					trace("study stage = " + _studyStage + " " + (getTimer() - timerStart))
					timeForNextStage = 60000;
					loadVideo(_videoFilename[1], 1);
					break;
				case 2:
					trace("study stage = " + _studyStage + " " + (getTimer() - timerStart))
					timeForNextStage = 60000;
					studySearch = (ca.ubc.ece.hct.Range)(_searchLocation[0][0]);
					loadVideo(_videoFilename[0], 0);
					break;
				case 3:
					trace("study stage = " + _studyStage + " " + (getTimer() - timerStart))
					timeForNextStage = 60000;
					studySearch = (ca.ubc.ece.hct.Range)(_searchLocation[0][1]);
					loadVideo(_videoFilename[0], 0);
					break;
				case 4:
					trace("study stage = " + _studyStage + " " + (getTimer() - timerStart))
					timeForNextStage = 60000;
					studySearch = (ca.ubc.ece.hct.Range)(_searchLocation[0][2]);
					loadVideo(_videoFilename[0], 0);
					break;
				case 5:
					trace("study stage = " + _studyStage + " " + (getTimer() - timerStart))
					timeForNextStage = 60000;
					studySearch = (ca.ubc.ece.hct.Range)(_searchLocation[1][0]);
					loadVideo(_videoFilename[1], 1);
					break;
				case 6:
					trace("study stage = " + _studyStage + " " + (getTimer() - timerStart))
					timeForNextStage = 60000;
					studySearch = (ca.ubc.ece.hct.Range)(_searchLocation[1][1]);
					loadVideo(_videoFilename[1], 1);
					break;
				case 7:
					trace("study stage = " + _studyStage + " " + (getTimer() - timerStart))
					timeForNextStage = 60000;
					studySearch = (ca.ubc.ece.hct.Range)(_searchLocation[1][2]);
					loadVideo(_videoFilename[1], 1);
					break;
				case 8:
					removeStrips();
					// removeChild(instructionImage);
					if(videoPlayer && contains(videoPlayer)) {
						removeChild(videoPlayer);
					}

					break;
			}

			nextStageButton.enabled = false;
			showInstructions(_studyStage);
		}

		public function showInstructions(studyStage:uint):void {
			if(searchInstructionsText &&  contains(searchInstructionsText)) 
				removeChild(searchInstructionsText);
			addChild(instructionOverlay);
			addChild(instructionImage);
			switch(studyStage) {
				case 0:
					// watch video
					if(FILMSTRIP == 0) {
						instructionImage.load(_filmstripInstructions);
					} else {
						instructionImage.load(_slidestripInstructions);
					}
					break;
				case 1:
					// watch video
					if(FILMSTRIP == 1) {
						instructionImage.load(_filmstripInstructions);
					} else {
						instructionImage.load(_slidestripInstructions);
					}
					break;
				case 2:
					// search 1 video 1
					instructionImage.load("https://placeholdit.imgix.net/~text?txtsize=25&txt=" + _searchInstructions[0][0] + "&w=500&h=400");
					searchInstructionsText.text = _searchInstructions[0][0];
					searchInstructionsText.x = stage.stageWidth/2 - searchInstructionsText.width/2;
					break;
				case 3:
					// search 2 video 1
					instructionImage.load("https://placeholdit.imgix.net/~text?txtsize=25&txt=" + _searchInstructions[0][1] + "&w=500&h=400");
					searchInstructionsText.text = _searchInstructions[0][1];
					searchInstructionsText.x = stage.stageWidth/2 - searchInstructionsText.width/2;
					break;
				case 4:
					// search 3 video 1
					instructionImage.load("https://placeholdit.imgix.net/~text?txtsize=25&txt=" + _searchInstructions[0][2] + "&w=500&h=400");
					searchInstructionsText.text = _searchInstructions[0][2];
					searchInstructionsText.x = stage.stageWidth/2 - searchInstructionsText.width/2;
					break;
				case 5:
					// search 1 video 2
					instructionImage.load("https://placeholdit.imgix.net/~text?txtsize=25&txt=" + _searchInstructions[1][0] + "&w=500&h=400");
					searchInstructionsText.text = _searchInstructions[1][0];
					searchInstructionsText.x = stage.stageWidth/2 - searchInstructionsText.width/2;
					break;
				case 6:
					// search 2 video 2
					instructionImage.load("https://placeholdit.imgix.net/~text?txtsize=25&txt=" + _searchInstructions[1][1] + "&w=500&h=400");
					searchInstructionsText.text = _searchInstructions[1][1];
					searchInstructionsText.x = stage.stageWidth/2 - searchInstructionsText.width/2;
					break;
				case 7:
					// search 3 video 2
					instructionImage.load("https://placeholdit.imgix.net/~text?txtsize=25&txt=" + _searchInstructions[1][2] + "&w=500&h=400");
					searchInstructionsText.text = _searchInstructions[1][2];
					searchInstructionsText.x = stage.stageWidth/2 - searchInstructionsText.width/2;
					break;
				case 8:
					// exit
					instructionImage.load("https://placeholdit.imgix.net/~text?txtsize=25&txt=Thank you for completing this stage of the study. Copy this ID and continue to the survey.&w=400&h=200");
					searchInstructionsText.text = UserID.id;
					searchInstructionsText.y = stage.stageHeight/2;
					searchInstructionsText.mouseEnabled = true;
					searchInstructionsText.defaultTextFormat = new TextFormat("Arial", 20, 0xffffff, true, false, false, null, null, "center", null, null, null, 4)
					addChild(searchInstructionsText);


					var surveyButton:Button = new Button();
					surveyButton.width = 200;
					surveyButton.label = "Click here to continue to the survey.";
					surveyButton.x = stage.stageWidth/2 - surveyButton.width/2;
					surveyButton.y = stage.stageHeight/2 + 30;
					addChild(surveyButton);
					surveyButton.addEventListener(MouseEvent.CLICK, 
						function surveyButtonClicked(e:MouseEvent):void {
							navigateToURL(new URLRequest("https://survey.ubc.ca/s/slide-filmstrip/"), "_blank");
							})
					break;

			}

			instructionImage.addEventListener(Event.COMPLETE,
				function reposition(e:Event):void {
					instructionImage.x = stage.stageWidth/2 - instructionImage.width/2;
					instructionImage.y = 25;
					instructionImage.removeEventListener(Event.COMPLETE, reposition);
				})

			if(VideoLoader.loadComplete) {
				addChild(dismissInstructionsButton);
			} else {
				VideoLoader.thumbnailsDownloaded.addOnce(
					function addDismissInstructionsButton():void {	
						addChild(dismissInstructionsButton);
					})
			}

			if(VideoLoader.loaderBar != null && contains(VideoLoader.loaderBar)) {
				setChildIndex(VideoLoader.loaderBar, numChildren - 1);
			}
		}

		public function dismissInstructions(e:MouseEvent):void {

			if(_studyStage != 0 && !_studyStage != 1) {
				if(!contains(searchInstructionsText)) {
					addChild(searchInstructionsText);
				}
			}

			timeOfNextStage = getTimer() + timeForNextStage;
			nextStageTimer.delay = timeForNextStage;
			nextStageTimer.start();

			videoPlayer.play();

			timerStart = getTimer();
			if(contains(instructionOverlay)) 		removeChild(instructionOverlay);
			if(contains(instructionImage)) 			removeChild(instructionImage);
			if(contains(dismissInstructionsButton)) removeChild(dismissInstructionsButton);
		}

		public function loadVideo(videoFilename:String, withUI:uint = 0):void {

			VideoLoader.initLoaderBar(stage.stageWidth * 0.95, 5);
			VideoLoader.loaderBar.colour = 0xff0000;
			// VideoLoader.loaderBar.backgroundColour = 0x;
			VideoLoader.loaderBar.cornerRadius = 0;
			addChild(VideoLoader.loaderBar);
			VideoLoader.loaderBar.x = stage.stageWidth/2 - VideoLoader.loaderBar.width/2;
			VideoLoader.loaderBar.y = stage.stageHeight - VideoLoader.loaderBar.height;
			VideoLoader.loaderBar.addEventListener(Event.COMPLETE,
				function removeVideoLoader(e:Event):void {
					VideoLoader.loaderBar.removeEventListener(Event.COMPLETE, removeVideoLoader);
					if(contains(VideoLoader.loaderBar))
						removeChild(VideoLoader.loaderBar);
				});
			VideoLoader.thumbnailsDownloaded.add(
				function thumbnailDownloadsComplete():void {
					// trace("downloaded thumbnails");
					VideoLoader.thumbnailsDownloaded.remove(thumbnailDownloadsComplete);
					loadUI(videoFilename, withUI);

					if(contains(instructionOverlay)) {
						setChildIndex(instructionOverlay, numChildren - 1);
					}
					if(contains(dismissInstructionsButton)) {
						setChildIndex(instructionImage, numChildren - 1);
					}
					if(contains(dismissInstructionsButton)) {
						setChildIndex(dismissInstructionsButton, numChildren - 1);
					}

					if(contains(VideoLoader.loaderBar)) {
						setChildIndex(VideoLoader.loaderBar, numChildren -1);
					}
				});

			VideoLoader.loadVideo(videoFilename, UserID.id)
		}

		public function loadUI(videoFilename:String, withUI:uint = 0):void {

			UItoVideoMetadataLink.init();
			video = VideoMetadataManager.getVideo(videoFilename);
			selectionRange = new Range(0, 0);

			insertVideoPlayer();
			
			switch(withUI) {
				case SLIDESTRIP:
					insertWebSlideFilmstrip(videoFilename);
					break;
				case FILMSTRIP:
					insertWebSimpleFilmstrip(videoFilename);
					break;
			}


			UItoVideoMetadataLink.sendOnline = true;
			UItoVideoMetadataLink.sendOnlineUserID = UserID.id;
			if(sf != null)
				UItoVideoMetadataLink.linkHighlightable(sf);
			if(sf2 != null)
				UItoVideoMetadataLink.linkHighlightable(sf2);
		}

		public function insertVideoPlayer():void {

			if(videoPlayer == null) {
				videoPlayer = new WebPlayer(video, stage.stageWidth, stage.stageHeight - 220, 0);
				addChild(videoPlayer);
				videoPlayer.playerUpdateSignal.add(playerUpdate);

				setChildIndex(videoPlayer, 0);
			} else {
				videoPlayer.video = video;
			}

		}

		public function removeStrips():void {
			if(sf != null) {
				removeChild(sf);
				sf = null;
			}

			if(sf2 != null) {
				removeChild(sf2);
				sf2 = null;
			}

			if(highlightButtons != null) {
				for each(var button:ImageButton in highlightButtons) {
					if(contains(button))
						removeChild(button);
				}
			}
		}

		public function insertWebSlideFilmstrip(videoFilename:String):void {

			removeStrips();

			sf = new WebSlideFilmstrip(stage.stageWidth, 200);
			addChild(sf);
			sf.y = stage.stageHeight - sf.height - 20;

			sf.render(VideoMetadataManager.getVideo(videoFilename), video.slides);
			sf.seeked.add(
				function sfSeeked(time:Number):void {
					videoPlayer.seek(time);
				})
			sf.selected.add(
				function sfSelected(interval:ca.ubc.ece.hct.Range):void {
					selectionRange = interval;
					if(highlightMode && highlightColour != 0) {
						UItoVideoMetadataLink.highlighted(video.filename, highlightColour, interval);
						selectionRange = new Range(0, 0);
					}
				})

			sf.actionLogSignal.add(processActionLog);

		}

		public function insertWebSimpleFilmstrip(videoFilename:String):void {
			
			removeStrips();
			
			sf2 = new WebSimpleFilmstrip(video, stage.stageWidth, 200 - 60);
			sf2.captionsEnabled = true;
			addChild(sf2);
			sf2.y = stage.stageHeight - sf2.height - 20 - 30;

			sf2.filmstripClickSignal.add(
				function sfSeeked(currentTime:Number, newTime:Number):void {
					videoPlayer.seek(newTime);
				})
			sf2.selectedSignal.add(
				function sfSelected(interval:ca.ubc.ece.hct.Range):void {
					selectionRange = interval;
					if(highlightMode && highlightColour != 0) {
						UItoVideoMetadataLink.highlighted(video.filename, highlightColour, interval);
						selectionRange = new Range(0, 0);
					}
				})
			sf2.actionLogSignal.add(processActionLog);

			insertHighlightButtons();
		}

		public function insertHighlightButtons():void {
			if(highlightButtons == null) {
				highlightButtons = [];
				for(var i:int = 0; i<Colours.colours.length; i++) {
					var highlightButton:ImageButton = 
							new ImageButton(20, "http://animatti.ca/myview/uiimage/highlight_" + Colours.colours[i].toString(16) + ".png");
					highlightButton.toggleAble = true;
					highlightButton.value = Colours.colours[i];
					highlightButton.toggled.add(
						function redToggled(target:ImageButton, toggled:Boolean):void {
							highlightMode = toggled;
							highlightColour = (uint)(target.value);
							if(highlightMode && highlightColour != 0 && selectionRange.length > 0.1) {
								UItoVideoMetadataLink.highlighted(video.filename, highlightColour, selectionRange);
								selectionRange = new Range(0, 0);
								target.toggle = false;
								highlightMode = false;
								highlightColour = 0;
							}

							for each(var button:ImageButton in highlightButtons) {
								if(button != target && button.toggleActive != false) {
									button.toggle = false;
								}
							}
						})
					addChild(highlightButton);
					highlightButtons.push(highlightButton);
					highlightButton.x = stage.stageWidth/2  - 250/2 + i * 50;
					highlightButton.y = stage.stageHeight - 20;
				}
			} else {
				for each(var button:ImageButton in highlightButtons) {
					addChild(button);
				}
			}
		}

		public function processActionLog(message:String):void {
			trace(message);
			ServerDataLoader.addLog(UserID.id, message);
		}

		public function playerUpdate(time:Number):void {

			if(_studyStage != 0 && _studyStage != 1) {
				if(studySearch && time > studySearch.start && time < studySearch.end) {
					nextStageButton.label = "Next -->";
					nextStageButton.enabled = true;
					nextStageTimer.reset();

					processActionLog("Trial # " + (_studyStage - 1) + ": Video " + video.filename + " " + studySearch + ": " + ((getTimer() - timerStart)/1000) + "s");
					searchInstructionsText.text = "Found it! Click next to continue!";
					studySearch = new Range(-100, -99);
				}
			}

			if(sf != null)
				sf.playheadTime = time;
			if(sf2 != null)
				sf2.playheadTime = time;
		}
	}
}