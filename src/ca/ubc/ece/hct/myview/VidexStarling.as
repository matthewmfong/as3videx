/////////////////////////////////import ca.ubc.ece.hct.myview.Constants; ///////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

import ca.ubc.ece.hct.main;
import ca.ubc.ece.hct.myview.dashboard.InstructorDashboard2018;
import ca.ubc.ece.hct.myview.dashboard.InstructorDashboard2018Class;
import ca.ubc.ece.hct.myview.setup.Setup;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.StarlingVideoPlayerView;
import ca.ubc.ece.hct.myview.widgets.VideoPlaylistView;

import com.greensock.*;

import feathers.controls.Header;
import feathers.themes.TopcoatLightMobileTheme;

import fl.controls.Button;

import flash.desktop.NativeApplication;
import flash.display3D.Context3DTextureFormat;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.geom.Rectangle;
import flash.net.SharedObject;
import flash.utils.Timer;

import org.osflash.signals.natives.NativeSignal;

import spark.components.Panel;

import starling.core.Starling;
import starling.display.Canvas;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.ResizeEvent;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;
import starling.utils.AssetManager;

public class VidexStarling extends Sprite {


    public var rootPlaylistView:VideoPlaylistView;
    public var playerView:StarlingVideoPlayerView;
    public var recordsVisualizer:UserRecordsVisualizer;
    public var dashboard:InstructorDashboard2018;
    public var course:Course;

    private var consent_so:SharedObject;
    private var survey_so:SharedObject;

    private var selectedVideo:VideoMetadata;
    private var toolbar:Header;
    private var backButton:Button;

    public var playerButton:Button;
    public var dashboardButton:Button;
    public var instructorButton:Button;

    private var statusText:TextField;
    private var setup:Setup;
    private var surveyPopup:SurveyPopup;

    private var addedToStageSignal:NativeSignal;
    private var delayTimer:Timer;

    public static var assets:AssetManager;

    public static var flexLayer:main;

    public function VidexStarling() {

        assets = new AssetManager();
        assets.verbose = false;

        assets.textureFormat = Context3DTextureFormat.BGRA;
        assets.enqueue(File.applicationDirectory.resolvePath("ui/ms_Icon_Delete.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/ms_Icon_Delete_active.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/ms_Icon_Delete_disabled.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/ms_Icon_Search.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("uiimage/eye.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("uiimage/no_eye.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("uiimage/viewcount_active.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("uiimage/viewcount.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("uiimage/globalviewcount_active.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("uiimage/globalviewcount.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("uiimage/instructor_view_mode_active.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("uiimage/instructor_view_mode.png"));

        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/caution_dark.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/caution_light.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/puzzle_dark.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/puzzle_light.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/question_mark_dark.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/question_mark_light.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/star_dark.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/star_light.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/tag_dark.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/tag_light.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/thumbs_up_dark.png"));
        assets.enqueue(File.applicationDirectory.resolvePath("ui/tags/thumbs_up_light.png"));

        assets.enqueueWithName(File.applicationDirectory.resolvePath("uiimage/playerbar/cc_off.png"), "playerBarCCOff");
        assets.enqueueWithName(File.applicationDirectory.resolvePath("uiimage/playerbar/cc_on.png"), "playerBarCCOn");
        assets.enqueueWithName(File.applicationDirectory.resolvePath("uiimage/playerbar/fullscreen.png"), "playerBarFullscreenOn");
        assets.enqueueWithName(File.applicationDirectory.resolvePath("uiimage/playerbar/pause.png"), "playerBarPause");
        assets.enqueueWithName(File.applicationDirectory.resolvePath("uiimage/playerbar/play.png"), "playerBarPlay");
        assets.enqueueWithName(File.applicationDirectory.resolvePath("uiimage/playerbar/unfullscreen.png"), "playerBarFullscreenOff");

//        assets.loadQueue(function onProgress(val:Number):void { trace("Asset Load Progress: " + val); });
        assets.loadQueue(function onProgress(val:Number):void {});

        new TopcoatLightMobileTheme();

        consent_so = SharedObject.getLocal("consent");
        survey_so = SharedObject.getLocal("survey");
        course = Courses.getCourse(COURSE::Name);


        if(CONFIG::Instructor) {
            trace("Logging in predefined.");
            UserID.login(course.toString(), COURSE::PredefinedName);
        } else {
            trace("Auto generating login.");
            UserID.login(course.toString());
        }

        trace("Hello " + UserID.id);

        addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);

    }

    private function addedToStage(e:starling.events.Event):void {

        statusText = new TextField(width, 100);
        statusText.format = new TextFormat("Arial", 20, 0xcccccc);//, true, false, false, null, null, "center", null, null, null, 4);
        statusText.autoSize = TextFieldAutoSize.HORIZONTAL;
        statusText.text = "Logging in...";
        statusText.touchable = false;
        statusText.y = stage.stageHeight - statusText.height;
        addChild(statusText);


        UserID.loggedIn.add(loadCourse);

    }

    public function loadCourse():void {
        init();
        VideoMetadataManager.init();
        statusText.text = "Loading course details...";
        VideoMetadataManager.checkingLocalFiles.add(function():void {statusText.text="Checking existing local files...";});
        VideoMetadataManager.downloadingSources.add(function():void {statusText.text="Downloading videos...";})
        VideoMetadataManager.downloadedSources.add(
                function mediaFinishedDownloading():void {
                    statusText.text="Finished loading. Enjoy!";
                    TweenLite.to(statusText, 1,
                            {alpha: 0,
                                delay: 5,
                                onComplete:
                                        function():void {
                                            removeChild(statusText);
                                            statusText.dispose();
                                        }
                            });
                }
        );

        VideoMetadataManager.loadCourse(course.school, course.code, course.section, course.term, course.year, UserID.id).add(loadSetup);
    }

    public function init():void {

        TraceLogger.startDetailedLogging();

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

        toolbar = new Header();
        toolbar.title = course.code;
        toolbar.width = stage.stageWidth;
        toolbar.height = Constants.TITLEBAR_HEIGHT;
        addChild(toolbar);
        toolbar.alpha = 0;
        TweenLite.to(toolbar, 1, {alpha: 1});

//        var backButtonx:feathers.controls.Button = new feathers.controls.Button();
//        backButtonx.label = "Back";
//        backButton.addEventListener( Event.TRIGGERED, backButton_triggeredHandler );

//        addChild(backButtonx)
//        toolbar.leftItems = new <DisplayObject>[ backButtonx ];

        backButton.x = 10;
        backButton.y = toolbar.height/2 - backButton.height/2;

        stage.addEventListener(ResizeEvent.RESIZE, resizeListener);
        NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, windowActivate);
        NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, windowDeactivate);
        NativeApplication.nativeApplication.addEventListener(Event.USER_IDLE, userIdle);
        NativeApplication.nativeApplication.addEventListener(Event.USER_PRESENT, userPresent);
        NativeApplication.nativeApplication.addEventListener(Event.EXITING, exiting);
    }

    public function loadSetup():void {

        course = VideoMetadataManager.COURSE; // after loading the course from the server, it will get start and end dates too.

        if ((consent_so.size == 0 /* s.o. didn't exist */ || consent_so.data.consent == false) &&
                CONFIG::Instructor == false) {

            setup = new Setup();
            setup.finishedSetup.add(function ():void {
                consent_so.data.consent = true;
                loadVideoLibrary();
            });
            setup.cancelledConsent.add(function ():void {
                NativeApplication.nativeApplication.exit();
            });
            Starling.current.nativeOverlay.addChild(setup);
//        } else if((survey_so.size == 0 /* so didn't exist */ || survey_so.data.survey1 == false) &&
//                CONFIG::Instructor == false) {
//            surveyPopup = new SurveyPopup(UserID.id, "https://survey.ubc.ca/s/videxbcit2017w/", "VIDEXSURVEY2017");
//            surveyPopup.closeMeSignal.add(function(surveyCompleted:Boolean):void {
//                if(surveyCompleted) {
//                    survey_so.data.survey1 = true;
//                    ServerDataLoader.addLog(UserID.id, "Completed survey.");
//                } else {
//                    ServerDataLoader.addLog(UserID.id, "Skipped survey.");
//                }
//                if(Starling.current.nativeOverlay.contains(surveyPopup)) {
//                    Starling.current.nativeOverlay.removeChild(surveyPopup);
//
//                }
//                loadVideoLibrary();
//            });
//
//            surveyPopup.launchedSurveySignal.add(function():void {
//                ServerDataLoader.addLog(UserID.id, "Launched survey.");
//            });
//            Starling.current.nativeOverlay.addChild(surveyPopup);

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

//        delayTimer = new Timer(1000);
//        delayTimer.addEventListener(TimerEvent.TIMER,
//            function loadCourse(e:TimerEvent):void {
                rootPlaylistView = new VideoPlaylistView(VideoMetadataManager.playlist, stage.stageWidth - 20, stage.stageHeight - toolbar.height - 20, true);
                rootPlaylistView.x = 10;
                rootPlaylistView.y = toolbar.height + 10;
                rootPlaylistView.videoClicked.add(selectVideo);
                pushView(rootPlaylistView);
//
//                if (Starling.current.nativeOverlay.contains(statusText))
//                    Starling.current.nativeOverlay.setChildIndex(statusText, Starling.current.nativeOverlay.numChildren - 1);
//
//                playerView = new StarlingVideoPlayerView();
                if(CONFIG::Instructor) {
//                    recordsVisualizer = new UserRecordsVisualizer(stage.stageWidth, stage.stageHeight - toolbar.height);
                    instructorButton = new Button();
                    instructorButton.label = "Instructor Mode";
                    instructorButton.addEventListener(MouseEvent.CLICK, instructorMode);
                    instructorButton.x = stage.stageWidth - instructorButton.width - 10;
                    Starling.current.nativeOverlay.addChild(instructorButton);

                    instructorMode();
                }

                //			trace(VideoMetadataManager.getVideo("21-Arrays_I_VGA_10fps_keyint10_64kbps.mp4"));
                //
//                    selectVideo(VideoMetadataManager.getVideo("21-Arrays_I_VGA_10fps_keyint10_64kbps.mp4"), 0);
//                    launchPlayer();
//                delayTimer.stop();
//            });
//        delayTimer.start();

        var asdf:Quad = new Quad(1, 1);

        addChild(asdf);
        asdf.x = this.width/2;
        asdf.y = this.height/2;

        AnnotationCallout.showCallout(
                asdf,
                Colours.colours,
                [],
                asdf);

    }

    public function instructorMode(e:MouseEvent = null):void {
        popRootPlaylist();
        dashboard = new InstructorDashboard2018();
        dashboard.setPlaylist(VideoMetadataManager.playlist);
        flexLayer.rootContainer.addElement(dashboard);
        dashboard.setActualSize(flexLayer.rootContainer.width, flexLayer.rootContainer.height);
    }



    public function selectVideo(video:VideoMetadata, time:Number):void {
        selectedVideo = video;
        toolbar.title = video.title;
//        if(CONFIG::Instructor) {
//            popRootPlaylist();
//            Starling.current.nativeOverlay.addChild(dashboardButton);
//            dashboardButton.x = stage.stageWidth/2 - dashboardButton.width/2;
//            dashboardButton.y = stage.stageHeight/2;
//            Starling.current.nativeOverlay.addChild(playerButton);
//            playerButton.x = stage.stageWidth/2 - dashboardButton.width/2;
//            playerButton.y = dashboardButton.y + dashboardButton.height;
//
//        } else {
            launchPlayer();
//        }
    }

    public function launchPlayer():void {

        if(Starling.current.nativeOverlay.contains(dashboardButton)) {
            Starling.current.nativeOverlay.removeChild(dashboardButton);
        }
        if(Starling.current.nativeOverlay.contains(playerButton)) {
            Starling.current.nativeOverlay.removeChild(playerButton);
        }

        playerView = new StarlingVideoPlayerView();
        playerView.move(5, toolbar.height + 5);
        playerView.setSize(stage.stageWidth - 10, stage.stageHeight - toolbar.height - 10);
        playerView.loadVideo(selectedVideo);
        pushView(playerView);
        popRootPlaylist();

        Starling.current.nativeOverlay.addChild(backButton);

    }

    public function launchDashboard():void {
        recordsVisualizer.y = toolbar.height;
        Starling.current.nativeOverlay.addChild(recordsVisualizer);
        popRootPlaylist();

        Starling.current.nativeOverlay.addChild(backButton);
        recordsVisualizer.loadVideo(selectedVideo);

        if(Starling.current.nativeOverlay.contains(dashboardButton)) {
            Starling.current.nativeOverlay.removeChild(dashboardButton);
        }

        if(Starling.current.nativeOverlay.contains(playerButton)) {
            Starling.current.nativeOverlay.removeChild(playerButton);
        }

    }

    public function backToVideoLibrary(e:MouseEvent):void {
        popPlayer();
        popDashboard();
//        addChild(rootPlaylistView);
        rootPlaylistView.touchable = true;
        rootPlaylistView.alpha = 1;
        pushView(rootPlaylistView);
        Starling.current.nativeOverlay.removeChild(backButton);
        rootPlaylistView.setSize(stage.stageWidth - 20, stage.stageHeight - toolbar.height - 20);

        toolbar.title = course.code;
    }

    public function popRootPlaylist():void {
        if(rootPlaylistView.touchable) {
            rootPlaylistView.touchable = false;
            rootPlaylistView.alpha = 0;

            removeChild(rootPlaylistView);
        }
//        if(rootPlaylistView && contains(rootPlaylistView)) {
//            removeChild(rootPlaylistView);
//        }
    }

    public function popPlayer():void {
        if(playerView && contains(playerView)) {
            removeChild(playerView);
            playerView.dispose();
            playerView = null;
        }
    }

    public function popDashboard():void {
        if(recordsVisualizer && Starling.current.nativeOverlay.contains(recordsVisualizer)) {
            Starling.current.nativeOverlay.removeChild(recordsVisualizer);
        }
    }

    public function pushView(view:StarlingView):void {
        view.alpha = 0;
        addChild(view);
        TweenLite.to(view, 1, {alpha: 1});
    }


    private var resizeTimer:Timer;
    private function resizeListener(e:ResizeEvent):void {

        Starling.current.viewPort.width = e.width;
        Starling.current.viewPort.height = e.height;
        stage.stageWidth = e.width + 5;
        stage.stageHeight = e.height + 5;

        if(instructorButton) {
            instructorButton.x = stage.stageWidth - instructorButton.width - 10;
        }

//        trace("event: " + e.width + "x" + e.height);
//        trace("stage: " + stage.stageWidth + "x" + stage.stageHeight);

        toolbar.width = e.width;
        if(rootPlaylistView && contains(rootPlaylistView)) {
            rootPlaylistView.setSize(stage.stageWidth - 20, stage.stageHeight - toolbar.height - 20);
        }

        if(playerView && contains(playerView)) {
            playerView.setSize(stage.stageWidth - 10, stage.stageHeight - toolbar.height - 10);
        }

//        if(!resizeTimer) {
//            resizeTimer = new Timer(1000);
//        }
//        resizeTimer.addEventListener(TimerEvent.TIMER, uploadResizeEvent);
//        resizeTimer.reset();
//        resizeTimer.start();
    }

    private function uploadResizeEvent(e:TimerEvent = null):void {
        // TODO : check if window is closed
//        ServerDataLoader.addLog_v2(UserID.id, "{}", eventToJSON(null, "action", "resize", "size", new flash.geom.Rectangle(Starling.current.nativeStage.nativeWindow.x,
//                Starling.current.nativeStage.nativeWindow.y,
//                Starling.current.nativeStage.nativeWindow.width,
//                Starling.current.nativeStage.nativeWindow.height)));
    }

    private function windowActivate(e:Event):void {
        ServerDataLoader.addLog_v2(UserID.id, "{}", eventToJSON(null, "action", "windowActivate"));
    }

    private function windowDeactivate(e:Event):void {
        TraceLogger.uploadTraces();
        ServerDataLoader.addLog_v2(UserID.id, "{}", eventToJSON(null, "action", "windowDeactivate"));
    }

    private function userIdle(e:Event):void {
        ServerDataLoader.addLog_v2(UserID.id, "{}", eventToJSON(null, "action", "userIdle"));
    }

    private function userPresent(e:Event):void {
        ServerDataLoader.addLog_v2(UserID.id, "{}", eventToJSON(null, "action", "userPresent"));
    }

    private function exiting(e:Event):void {
        ServerDataLoader.addLog_v2(UserID.id, "{}", eventToJSON(null, "action", "exiting"));
        trace("exiting");
        if(playerView && contains(playerView)) {
            popPlayer();
        }
    }

    public static function eventToJSON(source:*, ...args):String {

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

