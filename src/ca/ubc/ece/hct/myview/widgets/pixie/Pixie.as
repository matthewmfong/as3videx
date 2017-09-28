////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.pixie {

	import ca.ubc.ece.hct.ImageLoader;
import ca.ubc.ece.hct.myview.Colours;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.widgets.Widget;
import ca.ubc.ece.hct.myview.video.VideoMetadata;

import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flash.utils.Timer;
	import flash.filters.BlurFilter;

	public class Pixie extends Widget {
//		private var _video:VideoMetadata;
        private var balls:Array;
        // private var ballsCatchUpAngle:Array;
        private var ballsCaughtUp:Boolean;
        private var timer:Timer;
        public static var PATH_RADIUS:Number = 27;
        public static const TICK_TIME:Number = 1/30;
        public static const BALL_RPM:Number = 4;
        public static const BALL_SPEED:Number = 2*Math.PI * BALL_RPM/60*TICK_TIME;
        public static const CATCH_UP_POS:Number = 5;
        public static const CATCH_UP_NEG:Number = 0.5;
        public static const NUM_LOCATIONS_TO_KEEP:Number = 10;
        public static var STARTING_RADIUS:Number = 5;
        public static var MAX_RADIUS:Number = 20;
        public static const PI:Number = Math.PI;
        private var angle:Number = 0;
        private var buttonsColours:Array;
        private var referenceBall:Object;
        private var ballGap:Number;

//        private var _width:Number, _height:Number;

        private var ballColourIndex:Number = 0;

        private var highlightButtons:Array;
        private var playButtons:Array;

        private var recordingBall:Sprite;
        public var recordingColour:uint = 0;
        private var recordingPulseNumber:Number = 1;
        private var recordingPulseDirection:Number = 1;
        private var recordingPulseSize:Number = 75;
        private var recordingPulseSizeDirection:Number = 1;

        public function Pixie(width:Number, height:Number) {
            ballGap = 2*PI;
            alpha = 0.4;
            buttonsColours = Colours.colours;//["0xfb9abb", "0xf7e1a0", "0xb3e1a5", "0xa5d5f6", "0xe1baeb"];

            MAX_RADIUS = Math.min(width/2, height/2) / 2.5;
            STARTING_RADIUS = MAX_RADIUS / 4;
            PATH_RADIUS = Math.min(width/2, height/2) - MAX_RADIUS;

            graphics.beginFill(0xCCCCCC);
            graphics.drawCircle(0, 0, PATH_RADIUS - MAX_RADIUS - 4);
            graphics.endFill();

            balls = [];
            timer = new Timer(TICK_TIME);
            addEventListener(Event.ENTER_FRAME, nextFrameX);
            // start();

            graphics.beginFill(0xff00ff, 0.1);
            graphics.drawRect(-width/2, -height/2, width, height);
            graphics.endFill();

            _width = width;
            _height = height;

            highlightButtons = [];
            playButtons = [];

            initButtons();

            addEventListener(MouseEvent.ROLL_OVER, mouseRollOver);
            addEventListener(MouseEvent.ROLL_OUT, mouseRollOut);


            // addEventListener(MouseEvent.RIGHT_CLICK,
            // 	function mouseClick(e:MouseEvent):void {
            // 		// removeBall(balls[balls.length-1].colour);
            // 	});
            recordingBall = new Sprite();
            recordingBall.addEventListener(MouseEvent.CLICK,
                    function mouseClick(e:MouseEvent):void {
                        dispatchEvent(new PixieEvent(PixieEvent.STOP_AUTO_HIGHLIGHT));
                        // ballColourIndex = ballColourIndex >= buttonsColours.length ? 0 : ballColourIndex;
                        // addBall(buttonsColours[ballColourIndex++]);
                    });
        }

        override public function play():void {
            start();
        }

        public function start():void {
            timer.start();
            if(!hasEventListener(Event.ENTER_FRAME))
                addEventListener(Event.ENTER_FRAME, nextFrameX);
        }

        override public function stop():void {
            timer.stop();
            if(hasEventListener(Event.ENTER_FRAME))
                removeEventListener(Event.ENTER_FRAME, nextFrameX);
        }

        private function nextFrameX(e:Event):void {
            if(recordingColour == 0) {

                if(contains(recordingBall))
                    removeChild(recordingBall);

                var ballsLength:int = balls.length;

                for(var i:int = 0; i<ballsLength; i++) {

                    balls[i].shape.graphics.clear();
                    balls[i].shape.graphics.lineStyle(4, Util.changeSaturation(balls[i].colour, 5));
                    balls[i].shape.graphics.beginFill(balls[i].colour);
                    balls[i].shape.graphics.drawCircle(PATH_RADIUS * Math.cos(balls[i].currentAngle),
                            PATH_RADIUS * Math.sin(balls[i].currentAngle), balls[i].currentRadius);
                    balls[i].shape.graphics.endFill();
                    if(balls[i].caughtUp) {

                        balls[i].currentAngle += BALL_SPEED;// angle + 2*Math.PI * i/balls.length;

                        balls[i].lastLocations.shift();
                    } else {


                        balls[i].currentAngle += BALL_SPEED * balls[i].catchUpSpeed;

                        if(balls[i].newlyAdded) {
                            balls[i].lastLocations.push(balls[i].currentAngle);
                            if(balls[i].lastLocations.length > NUM_LOCATIONS_TO_KEEP)
                                balls[i].lastLocations.shift();
                        }

                        var differenceAngleFromReferenceBall:Number = Util.angleDifference(referenceBall.currentAngle, balls[i].currentAngle);
                        var goalDAFRB:Number = ballGap * (i - referenceBall.idx);
                        goalDAFRB = goalDAFRB < 0 ? goalDAFRB + 2*PI : goalDAFRB;

                        if( (differenceAngleFromReferenceBall >= goalDAFRB ) || ballsLength == 1) {

                            // balls[i].currentAngle = -2*Math.PI;
                            balls[i].caughtUp = true;
                            // trace("balls[" + i + "].caughtUp = true")
                            for(var j:int = 0; j<ballsLength; j++) {
                                if(balls[i].caughtUp) {
                                    balls[i].currentAngle = referenceBall.currentAngle + goalDAFRB;
                                    balls[i].newlyAdded = false;
                                    // balls[i].lastLocations.shift();
                                    ballsCaughtUp = true;
                                } else {
                                    ballsCaughtUp = false;
                                    break;
                                }
                            }
                        }
                    }

                    for(var k:int = 0; k<balls[i].lastLocations.length; k++) {
                        balls[i].shape.graphics.beginFill(balls[i].colour, 1 - 1/NUM_LOCATIONS_TO_KEEP*k);
                        balls[i].shape.graphics.drawCircle(PATH_RADIUS * Math.cos(balls[i].lastLocations[k]),
                                PATH_RADIUS * Math.sin(balls[i].lastLocations[k]),
                                (balls[i].currentRadius - STARTING_RADIUS)*(k+5)/NUM_LOCATIONS_TO_KEEP);
                        balls[i].shape.graphics.endFill();
                    }


                    // balls[i].currentRadius = (balls[i].currentRadius >= MAX_RADIUS) ? MAX_RADIUS : balls[i].currentRadius + 0.5;

                    // trace(i + " " + balls[i])
                    if(balls[i].queueRemove && ballsCaughtUp) {
                        balls[i].shape.alpha -= 0.1;
                        if(balls[i].shape.alpha <= 0) {
                            removeChild(balls[i].shape);
                            balls.splice(i, 1);
                            ballsLength = balls.length
                            i--;

                            ballGap = 2*PI/ballsLength;
                            if(ballsLength > 0) {
                                // trace(i + " " + balls.length + ", " + "(" + i + "+1) < (" + balls.length + " - 1)" + ((i + 1) < balls.length-1));
                                if(i >= 0 && (i + 1) <= ballsLength-1) {
                                    // trace("1---____---" + i)
                                    referenceBall = balls[i+1];
                                } else if(i + 1 > ballsLength-1) {
                                    // trace("2---____---" + i)
                                    referenceBall = balls[0];
                                } else if(i < 0) {
                                    // trace("3---____---" + i)
                                    referenceBall = balls[ballsLength-1];
                                } else {
                                    // trace("4---____---" + i)
                                    // trace("error");
                                }

                                for(var k:int = 0; k<ballsLength; k++) {
                                    balls[k].idx = k;
                                }

                                // referenceBall = (i + 1 < balls.length-1) ? balls[i] : balls[0];
                                // trace(balls.length + " " + i + " " + (i + 1 < balls.length-1))
                                // trace("reference = " + referenceBall.idx + ": " + referenceBall.colour.toString(16))
                            }
                            for(var i:int = 0; i<ballsLength; i++) {

                                if(i != referenceBall.idx) {
                                    // trace("i" + i)
                                    balls[i].catchUpSpeed = CATCH_UP_POS;
                                    balls[i].caughtUp = false;
                                } else {
                                    balls[i].caughtUp = false;
                                }
                            }
                        }
                    } else {
                        if(balls[i].shape.alpha < 1) {
                            balls[i].shape.alpha += 0.05;
                        }
                    }

                }
                angle += BALL_SPEED;
            } else {
                for(var i:int = 0; i<balls.length; i++) {
                    balls[i].shape.graphics.clear();
                }

                if(!contains(recordingBall))
                    addChild(recordingBall);

                if(recordingPulseNumber > 2.5) {
                    recordingPulseDirection = -1;
                } else if(recordingPulseNumber < 1) {
                    recordingPulseDirection = 1;
                }

                if(recordingPulseDirection == 1) {
                    recordingPulseNumber += 0.01;
                } else {
                    recordingPulseNumber -= 0.01;
                }

                if(recordingPulseSize > 75) {
                    recordingPulseSizeDirection = -1;
                } else if(recordingPulseSize < 70) {
                    recordingPulseSizeDirection = 1;
                }

                if(recordingPulseSizeDirection == 1) {
                    recordingPulseSize += 0.05;
                } else {
                    recordingPulseSize -= 0.05;
                }

                recordingBall.graphics.clear();
                recordingBall.graphics.lineStyle(4, Util.changeSaturation(recordingColour, recordingPulseNumber + 2));
                recordingBall.graphics.beginFill(Util.changeSaturation(recordingColour, recordingPulseNumber));
                recordingBall.graphics.drawCircle(0, 0, recordingPulseSize);
                recordingBall.graphics.endFill();


                recordingBall.graphics.lineStyle(0, 0);
                recordingBall.graphics.beginFill(0x444444);
                recordingBall.graphics.drawRect(-20, -20, 40, 40);
                recordingBall.graphics.endFill();

            }
        }

        private function addBall(colour:uint):void {
            // trace("add ball");

            for(var i:int = 0; i<balls.length; i++) {
                if(balls[i].colour == colour && !balls[i].queueRemove)
                    return;
            }

            for(var i:int = 0; i<balls.length; i++) {
                // trace(balls[i].idx + ": " + balls[i].colour.toString(16))
                if(balls[i].caughtUp)
                    referenceBall = balls[i];
            }

            // if(referenceBall) {
            // trace("referenceBall")
            // trace(referenceBall.idx + ": " + referenceBall.colour.toString(16))
            // }

            var newAngle:Number = (balls.length > 0) ? balls[balls.length - 1].currentAngle : angle;

            var newBall:Object = {};
            newBall.newlyAdded = true;
            newBall.shape = new Shape();
            newBall.shape.cacheAsBitmap = true;
            newBall.shape.alpha = 0;
            newBall.colour = colour;
            newBall.currentAngle = newAngle;
            newBall.caughtUp = balls.length > 0 ? false : true;
            newBall.catchUpSpeed = CATCH_UP_POS * balls.length;
            newBall.queueRemove = false;
            newBall.currentRadius = MAX_RADIUS;
            newBall.idx = balls.length;
            newBall.lastLocations = [];

            balls.push(newBall);

            newBall.nextBall = balls[0];
            if(balls.length > 1) {
                newBall.prevBall = balls[balls.length - 2];
                balls[balls.length-2].nextBall = newBall;
            }

            balls[0].prevBall = balls[balls.length - 1];


            newBall.shape.graphics.beginFill(colour);
            newBall.shape.graphics.drawCircle(0, 0, STARTING_RADIUS);
            newBall.shape.graphics.endFill();


            addChild(newBall.shape);


            newBall.shape.x = 0;//PATH_RADIUS * Math.cos(newAngle);
            newBall.shape.y = 0;//PATH_RADIUS * Math.sin(newAngle);

            for(var i:int = 0; i<balls.length-1; i++) {
                if(i != referenceBall.idx) {
                    balls[i].catchUpSpeed = CATCH_UP_POS*(i+1);
                    balls[i].caughtUp = false;
                } else {
                    balls[i].caughtUp = false;
                }
                // trace(i + ": " + balls[i].catchUpSpeed)
                // if((Math.abs(Math.abs(balls[i].currentAngle - balls[i].nextBall.currentAngle) - 2*PI/balls.length)*180/PI  > 5 &&
                // 	Math.abs(Math.abs(balls[i].currentAngle - balls[i].prevBall.currentAngle) - 2*PI/balls.length)*180/PI  > 5)) {
                // 	// trace(i);
                // 	if(balls.length > 2 && i != balls.length-2) {
                // 		// trace("a)")
                // 		balls[i].catchUpSpeed = CATCH_UP_POS;
                // 		balls[i].caughtUp = false;
                // 	}
                // }
                // trace(balls[i].idx + ": " + balls[i].nextBall.idx)
            }

            // for(var i:int = 0; i<balls.length; i++) {
            // trace("index: " + balls[i].idx + ": " + balls[i].nextBall.idx)
            // }

            ballGap = 2*PI/balls.length;
            ballsCaughtUp = balls.length > 1 ? false : true;
        }

        private function removeBall(colour:uint):void {
            var index:int = -1;
            for(var i:int = 0; i<balls.length; i++) {
                if(balls[i].colour == colour) {
                    index = i;
                    break;
                }
            }
            if(index == -1) {
                return;
            }

            balls[index].queueRemove = true;
        }

        public function setBalls(colours:Array):void {
            for(var i:int = 0; i<colours.length; i++) {
                addBall(colours[i]);
            }

            var found:Boolean;
            for(var i:int = 0; i<balls.length; i++) {

                found = false
                for(var j:int = 0; j<colours.length; j++) {

                    if(colours[j] == balls[i].colour) {
                        found = true;
                        break;
                    }
                }

                if(!found) {
                    balls[i].queueRemove = true;
                }
            }

        }

        private function initButtons():void {
            var button:PixieClickableBall = new PixieClickableBall();
            button.graphics.clear();
            button.graphics.lineStyle(1, 0x777777);
            button.graphics.beginFill(0xcccccc, 1);
            button.graphics.drawCircle(0, 0, 20);
            button.graphics.endFill();
            highlightButtons.push(button)

            var loader:ImageLoader = new ImageLoader("uiimage/highlight.png");
            // loader.load(new URLRequest("uiimage/highlight.png"));
            loader.x = -15;
            loader.y = -15;
            button.addChild(loader);

            for(var i:int = 0; i<buttonsColours.length; i++) {
                button = new PixieClickableBall();
                button.colour = buttonsColours[i];
                button.graphics.clear();
                button.graphics.lineStyle(1, 0x777777);
                button.graphics.beginFill(buttonsColours[i], 1);
                button.graphics.drawCircle(0, 0, 20);
                button.graphics.endFill();
                highlightButtons.push(button);
                button.addEventListener(MouseEvent.CLICK,
                        function highlightButtonClick(e:MouseEvent):void {
                            // trace(button.colour.toString(16))
                            recordingColour = e.target.colour;
                            dispatchEvent(new PixieEvent(PixieEvent.HIGHLIGHT, e.target.colour));
                        })
            }
            // button = new PixieClickableBall();
            // button.graphics.clear();
            // button.graphics.beginFill(0xffffff, 1);
            // button.graphics.lineStyle(1, 0x777777);
            // button.graphics.drawCircle(0, 0, 20);
            // button.graphics.endFill();
            // highlightButtons.push(button);
            // button.addEventListener(MouseEvent.CLICK,
            // 	function highlightButtonClick(e:MouseEvent):void {
            // 		dispatchEvent(new PixieEvent(PixieEvent.UNHIGHLIGHT));
            // 		})

            for(i = 0; i<highlightButtons.length; i++) {
                // highlightButtons[i].x = _width/2 - highlightButtons[0].width/2;
                highlightButtons[i].y = - highlightButtons[0].height;
                addChild(highlightButtons[i]);
                highlightButtons[i].alpha = 0;
            }

            // --- play highlight buttons

            button = new PixieClickableBall();
            button.graphics.clear();
            button.graphics.lineStyle(1, 0x777777);
            button.graphics.beginFill(0xcccccc, 1);
            button.graphics.drawCircle(0, 0, 20);
            button.graphics.endFill();
            playButtons.push(button)

            var loader2:ImageLoader = new ImageLoader("uiimage/playHighlight.png");
            // loader2.load(new URLRequest("uiimage/playHighlight.png"));
            loader2.x = -15;
            loader2.y = -15;
            button.addChild(loader2);

            for(var i:int = 0; i<buttonsColours.length; i++) {
                button = new PixieClickableBall();
                button.colour = buttonsColours[i];
                button.graphics.clear();
                button.graphics.lineStyle(1, 0x777777);
                button.graphics.beginFill(buttonsColours[i], 1);
                button.graphics.drawCircle(0, 0, 20);
                button.graphics.endFill();
                playButtons.push(button);
                button.addEventListener(MouseEvent.CLICK,
                        function highlightButtonClick(e:MouseEvent):void {
                            dispatchEvent(new PixieEvent(PixieEvent.PLAY, e.target.colour));
                        })
            }

            for(var i:int = 0; i<playButtons.length; i++) {
                // playButtons[i].x = _width/2 - playButtons[0].width/2;
                playButtons[i].y = playButtons[0].height;
                addChild(playButtons[i]);
                playButtons[i].alpha = 0;
            }

        }

        private function mouseRollOver(e:MouseEvent):void {
            alpha = 1;
            // for(var i:int = 0; i<highlightButtons.length; i++) {
            // 	new Tween(highlightButtons[i], "x", Elastic.easeOut,  _width/2 - highlightButtons[0].width/2, _width/2 - highlightButtons[0].width/2 + highlightButtons[i].width * i, 0.5, true);
            // 	new Tween(highlightButtons[i], "alpha", Elastic.easeOut,  highlightButtons[i].alpha, 1, 0.5, true);
            // }
            // for(var i:int = 0; i<playButtons.length; i++) {
            // 	new Tween(playButtons[i], "x", Elastic.easeOut,  _width/2 - playButtons[0].width/2, _width/2  - playButtons[0].width/2 + playButtons[i].width * i, 0.5, true);
            // 	new Tween(playButtons[i], "alpha", Elastic.easeOut,  playButtons[i].alpha, 1, 0.5, true);
            // }

            graphics.clear();
            graphics.beginFill(0xff00ff, 0);
            graphics.drawRect(-_width/2, -_height/2, _width + 400, _height);
            graphics.endFill();
        }

        private function mouseRollOut(e:MouseEvent):void {
            if(recordingColour == 0) {
                alpha = 0.4;
                // for(var i:int = 0; i<highlightButtons.length; i++) {
                // 	new Tween(highlightButtons[i], "x", Elastic.easeOut,  highlightButtons[i].x, _width/2 - highlightButtons[0].width/2, 0.5, true);
                // 	new Tween(highlightButtons[i], "alpha", Elastic.easeOut,  highlightButtons[i].alpha, 0, 0.5, true);
                // }
                // for(var i:int = 0; i<playButtons.length; i++) {
                // 	new Tween(playButtons[i], "x", Elastic.easeOut,  playButtons[i].x, _width/2 - highlightButtons[0].width/2, 0.5, true);
                // 	new Tween(playButtons[i], "alpha", Elastic.easeOut,  playButtons[i].alpha, 0, 0.5, true);
                // }

                graphics.clear();
                graphics.beginFill(0xff00ff, 0);
                graphics.drawRect(-_width/2, -_height/2, _width, _height);
                graphics.endFill();
            }
        }

        override public function set x(val:Number):void {
            super.x = val + _width/2;

        }

        override public function set y(val:Number):void {
            super.y = val + _height/2;
        }


        override public function loadVideo(video:VideoMetadata):void {
			_video = video;
		}

		override public function set playheadTime(time:Number):void { 
			setBalls(_video.userData.getHighlightedColoursForTime(time));
		}
		override public function receiveSeek(time:Number):void { /* do nothing */ }

		override public function select(interval:ca.ubc.ece.hct.Range):void { /* do nothing */ }
		override public function deselect():void { /* do nothing */ }

		override public function setHighlightsWriteMode(mode:String, colour:uint):void { /* do nothing */ }
		override public function highlight(colour:int, interval:ca.ubc.ece.hct.Range):void { /* do nothing */ }
		override public function unhighlight(colour:int, interval:ca.ubc.ece.hct.Range):void { /* do nothing */ }
		override public function playHighlights(colour:int):void { /* do nothing */ }

		override public function updateHighlights():void { /* do nothing */ }

		// bitwise or with UserDataViewMode
		override public function setHighlightReadMode(mode:uint):void { /* do nothing */ }
		override public function setViewCountRecordReadMode(mode:uint):void { /* do nothing */ }
		override public function setPauseRecordReadMode(mode:uint):void { /* do nothing */ }
		override public function setPlaybackRateRecordReadMode(mode:uint):void { /* do nothing */ }
	}
}