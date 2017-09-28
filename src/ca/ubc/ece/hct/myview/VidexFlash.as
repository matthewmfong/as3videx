////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

import ca.ubc.ece.hct.Range;
import ca.ubc.ece.hct.myview.widgets.VideoPlayerView;
import ca.ubc.ece.hct.myview.setup.Setup;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylistView;

import com.greensock.*;

import fl.controls.Button;

import flash.desktop.NativeApplication;
import flash.display.GradientType;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.NativeWindowBoundsEvent;
import flash.events.TimerEvent;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.net.SharedObject;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.Timer;

import org.osflash.signals.natives.NativeSignal;


public class VidexFlash extends Sprite {

    public var rootPlaylistView:VideoPlaylistView;
    public var playerView:VideoPlayerView;
    public var recordsVisualizer:UserRecordsVisualizer;
    public var course:Course;

    private var consent_so:SharedObject;
    private var survey_so:SharedObject;

    private var selectedVideo:VideoMetadata;
    private var toolbar:Sprite;
    private var backButton:Button;

    public var playerButton:Button;
    public var dashboardButton:Button;

    private var statusText:TextField;
    private var setup:Setup;
    private var surveyPopup:SurveyPopup;

    private var addedToStageSignal:NativeSignal;
    private var delayTimer:Timer;

    public function VidexFlash(courseName:String) {

        consent_so = SharedObject.getLocal("consent");
        survey_so = SharedObject.getLocal("survey");
        course = Courses.getCourse(COURSE::Name);

        addedToStageSignal = new NativeSignal(this, Event.ADDED_TO_STAGE, Event);
        addedToStageSignal.addOnce(setupStage);
    }

    public function setupStage(e:Event = null):void {

        statusText = new TextField();
        statusText.defaultTextFormat = new TextFormat("Arial", 20, 0xcccccc, true, false, false, null, null, "center", null, null, null, 4);
        statusText.text = "Logging in...";
        statusText.autoSize = "left";
//        statusText.mouseEnabled = false;
        statusText.y = stage.stageHeight - statusText.height;
        addChild(statusText);

        if(CONFIG::Instructor) {
            trace("Logging in predefined.");
            UserID.login(course.toString(), COURSE::PredefinedName);
        } else {
            trace("Auto generating login.")
            UserID.login(course.toString());
        }

        trace("Hello " + UserID.id);
        UserID.loggedIn.add(loadCourse);
    }

    public function loadCourse():void {
        VideoMetadataManager.init();
        statusText.text = "Loading course details...";
        VideoMetadataManager.checkingLocalFiles.add(function():void {statusText.text="Checking existing local files...";});
        VideoMetadataManager.downloadingSources.add(function():void {statusText.text="Downloading videos...";})
        VideoMetadataManager.downloadedSources.add(
                function mediaFinishedDownloading():void {
                    statusText.text="Finished loading. Enjoy!";
                    TweenLite.to(statusText, 1, {alpha: 0, delay: 5, onComplete:function():void { removeChild(statusText); }})
                }
        )

        VideoMetadataManager.loadCourse(course.school, course.code, course.section, course.term, course.year, UserID.id).add(loadSetup);
    }

    public function init():void {

        backButton = new Button();
        backButton.label = "<-- Video Library";
        backButton.addEventListener(MouseEvent.CLICK, backToVideoLibrary);

        playerButton = new Button();
        playerButton.label = "Open Video in Player";
        playerButton.addEventListener(MouseEvent.CLICK,
                function(e:MouseEvent):void { launchPlayer(); });
        playerButton.width = 200;
        dashboardButton = new Button();
        dashboardButton.label = "Open Video in Instructor Dashboard";
        dashboardButton.addEventListener(MouseEvent.CLICK,
                function(e:MouseEvent):void { launchDashboard(); });
        dashboardButton.width = 200;

        toolbar = new flash.display.Sprite();
        // toolbar.graphics.beginFill(0x333333, 1);
        var matr:Matrix = new Matrix;
        matr.createGradientBox(stage.stageWidth, backButton.height + 10, Math.PI/2, 0, 0);
        toolbar.graphics.beginGradientFill(GradientType.LINEAR,
                [0x333333, 0x222222], // colour
                [1, 1],  // alpha
                [0, 255], // ratio
                matr);
        toolbar.graphics.drawRect(0, 0, stage.stageWidth, 30);
        toolbar.graphics.endFill();
        addChild(toolbar);
        toolbar.alpha = 0;
        TweenLite.to(toolbar, 1, {alpha: 1});

        backButton.x = 10;
        backButton.y = toolbar.height/2 - backButton.height/2;
    }

    public function loadSetup():void {
//            init();

        if ((consent_so.size == 0 /* so didn't exist */ || consent_so.data.consent == false) &&
                CONFIG::Instructor == false) {

            setup = new Setup();
            setup.finishedSetup.add(function ():void {
                consent_so.data.consent = true;
                loadVideoLibrary();
            });
            setup.cancelledConsent.add(function ():void {
                NativeApplication.nativeApplication.exit();
            });
            addChild(setup);
        } else if((survey_so.size == 0 /* so didn't exist */ || survey_so.data.survey1 == false) &&
                CONFIG::Instructor == false) {
            surveyPopup = new SurveyPopup(UserID.id, "https://survey.ubc.ca/s/videx-2017/", "VIDEXSURVEY2017");
            surveyPopup.closeMeSignal.add(function(surveyCompleted:Boolean):void {
                if(surveyCompleted) {
                    survey_so.data.survey1 = true;
                    ServerDataLoader.addLog(UserID.id, "Completed survey.");
                } else {
                    ServerDataLoader.addLog(UserID.id, "Skipped survey.");
                }
                if(contains(surveyPopup)) {
                    removeChild(surveyPopup);

                }
                loadVideoLibrary();
            });

            surveyPopup.launchedSurveySignal.add(function():void {
                ServerDataLoader.addLog(UserID.id, "Launched survey.");
            })
            addChild(surveyPopup);

        } else {
            loadVideoLibrary();
        }

//			if(CONFIG::DEV && (survey_so.size == 0 /* so didn't exist */ || survey_so.data.survey1 == false)) {
//                surveyPopup = new SurveyPopup(UserID.id, "https://survey.ubc.ca/s/videx-2017/", "VIDEXSURVEY2017");
//				surveyPopup.closeMeSignal.add(function(surveyCompleted:Boolean):void {
//					if(surveyCompleted) {
//						survey_so.data.survey1 = true;
//					}
//                    if(contains(surveyPopup)) {
//						removeChild(surveyPopup);
//					}
//				});
//                addChild(surveyPopup);
//			}
    }

    public function loadVideoLibrary():void {

        delayTimer = new Timer(1000);
        delayTimer.addEventListener(TimerEvent.TIMER,
                function loadCourse(e:TimerEvent):void {
                    init();
                    rootPlaylistView = new VideoPlaylistView(VideoMetadataManager.playlist, stage.stageWidth - 20, stage.stageHeight - toolbar.height - 20, true);
                    rootPlaylistView.x = 10;
                    rootPlaylistView.y = toolbar.height + 10;
                    rootPlaylistView.videoClicked.add(selectVideo);
                    pushView(rootPlaylistView);

                    if (contains(statusText))
                        setChildIndex(statusText, numChildren - 1);

                    playerView = new VideoPlayerView(stage.stageWidth, stage.stageHeight - toolbar.height);
                    if(CONFIG::Instructor) {
                        recordsVisualizer = new UserRecordsVisualizer(stage.stageWidth, stage.stageHeight - toolbar.height);
                    }

                    //			trace(VideoMetadataManager.getVideo("21-Arrays_I_VGA_10fps_keyint10_64kbps.mp4"));
                    //
                    selectVideo(VideoMetadataManager.getVideo("21-Arrays_I_VGA_10fps_keyint10_64kbps.mp4"), 0);
                    delayTimer.stop();
                });
        delayTimer.start();
    }


    public function selectVideo(video:VideoMetadata, time:Number):void {
        selectedVideo = video;
        if(CONFIG::Instructor) {
            popRootPlaylist();
            addChild(dashboardButton);
            dashboardButton.x = stage.stageWidth/2 - dashboardButton.width/2;
            dashboardButton.y = stage.stageHeight/2;
            addChild(playerButton);
            playerButton.x = stage.stageWidth/2 - dashboardButton.width/2;
            playerButton.y = dashboardButton.y + dashboardButton.height;

        } else {
            launchPlayer();
        }
    }

    public function launchPlayer():void {

        if(contains(dashboardButton)) {
            removeChild(dashboardButton);
        }
        if(contains(playerButton)) {
            removeChild(playerButton);
        }
        playerView.y = toolbar.height;
        addChild(playerView);
        popRootPlaylist();

        addChild(backButton);
        playerView.loadVideo(selectedVideo, new Range(0, selectedVideo.duration));
        playerView.setSize(stage.stageWidth, stage.stageHeight - toolbar.height);

    }

    public function launchDashboard():void {
        recordsVisualizer.y = toolbar.height;
        addChild(recordsVisualizer);
        popRootPlaylist();

        addChild(backButton);
        recordsVisualizer.loadVideo(selectedVideo);

        if(contains(dashboardButton)) {
            removeChild(dashboardButton);
        }

        if(contains(playerButton)) {
            removeChild(playerButton);
        }

    }

    public function backToVideoLibrary(e:MouseEvent):void {
        popPlayer();
        popDashboard();
        addChild(rootPlaylistView);
        removeChild(backButton);
        rootPlaylistView.setSize(stage.stageWidth - 20, stage.stageHeight - toolbar.height - 20);
    }

    public function popRootPlaylist():void {
        if(rootPlaylistView && contains(rootPlaylistView)) {
            removeChild(rootPlaylistView);
        }
    }

    public function popPlayer():void {
        if(playerView && contains(playerView)) {
            removeChild(playerView);
        }
    }

    public function popDashboard():void {
        if(recordsVisualizer && contains(recordsVisualizer)) {
            removeChild(recordsVisualizer);
        }
    }

    public function pushView(view:View):void {
        view.alpha = 0;
        addChild(view);
        TweenLite.to(view, 1, {alpha: 1});
    }

//    public function resizeListener(e:NativeWindowBoundsEvent):void {
//        application_preferences_so.data.windowDimensions = new Rectangle(stage.nativeWindow.x, stage.nativeWindow.y, stage.nativeWindow.width, stage.nativeWindow.height);
//
//        if(rootPlaylistView && contains(rootPlaylistView))
//            rootPlaylistView.setSize(stage.stageWidth - 20, stage.stageHeight - toolbar.height - 20);
//
//        if(toolbar) {
//            toolbar.graphics.clear();
//            var matr:Matrix = new Matrix;
//            matr.createGradientBox(stage.stageWidth, backButton.height + 10, Math.PI/2, 0, 0);
//            toolbar.graphics.beginGradientFill(GradientType.LINEAR,
//                    [0x333333, 0x222222], // colour
//                    [1, 1],  // alpha
//                    [0, 255], // ratio
//                    matr);
//            toolbar.graphics.drawRect(0, 0, stage.stageWidth, 30);
//            toolbar.graphics.endFill();
//        }
//
//        if(playerView && contains(playerView)) {
//            playerView.setSize(stage.stageWidth, stage.stageHeight - toolbar.height);
//        }
//
//        if(setup && contains(setup)) {
//            setup.setSize(stage.stageWidth, stage.stageHeight);
//        }
//
//        if(statusText && contains(statusText)) {
//            statusText.y = stage.stageHeight - statusText.height;
//        }
//    }
}
}