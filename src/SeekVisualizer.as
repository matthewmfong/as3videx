package {
import ca.ubc.ece.hct.myview.Util;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;
import ca.ubc.ece.hct.myview.widgets.Widget;
import ca.ubc.ece.hct.myview.widgets.filmstrip.SimpleFilmstrip;
import ca.ubc.ece.hct.myview.widgets.player.Player;
import ca.ubc.ece.hct.Range;

import collections.HashMap;

import com.greensock.TweenLite;
import com.greensock.events.LoaderEvent;
import com.greensock.loading.DataLoader;
import com.greensock.loading.LoaderMax;

import flash.display.Shape;
import flash.display.Sprite;

import flash.display.StageAlign;

import flash.display.StageScaleMode;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.display.MovieClip;

	public class SeekVisualizer extends MovieClip {

        public static const binSize:Number = 10;
//        public static const XML_URL:String = "video.graphml";
        public static const forwardColour:uint = 0x000033;
        public static const backwardColour:uint = 0x003300;

        private var G:XML
		private var loader:LoaderMax;

        private var statusText:TextField;
		private var video:VideoMetadata;
		private var player:Player;
        private var playhead:Shape;
		private var filmstrip:SimpleFilmstrip;
        private var filmstripHeight:Number = 150;

        private var vizContainer:Sprite;
        private var vizDimensions:Rectangle;

        public function SeekVisualizer():void {

            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            stage.nativeWindow.width = 1920;
            stage.nativeWindow.height = 1080;
            loadVideo();

            vizDimensions = new Rectangle(0, filmstripHeight, stage.stageWidth, stage.stageHeight - filmstripHeight)


            G = new XML();
			loader = new LoaderMax( {name: "WebLoaderQueue", auditSize:false});
			loader.append(new DataLoader("http://animatti.ca/myview/20170129_learning_analytics_hackathon/video.graphml", {onComplete: xmlLoaded}));
			loader.load();
		}

		function xmlLoaded(e:LoaderEvent):void {
		    G = XML(e.target.content);
		    trace("Data loaded.");
			
			var nodes:Array = [];
			for(var i:int = 0; i<G.graph.node.length(); i++) {
				var time:Number = Number(G.graph.node[i].@id);
                if(time  < (17 * 60  + 1) && time >= 0)
					nodes.push(new NodeDisplay(Number(G.graph.node[i].@id)));
			}
			
			trace("# of nodes: " + nodes.length);
            nodes.sortOn("time", Array.NUMERIC);
			
			var edgeMap:HashMap = new HashMap();

			var maxSeeksBackward:Number = 0;
			var maxSeeksForward:Number = 0;
			var maxSeeks:Number = 0;
				
			var edges:Array = [];
			for(var i:int = 0; i<G.graph.edge.length(); i+=1) {

				var source:Number = Number(G.graph.edge[i].@source);
				var target:Number = Number(G.graph.edge[i].@target);

                nodes[(uint)(source/binSize)].seekOut += 1;
                nodes[(uint)(target/binSize)].seekIn += 1;

                if(source < target) {
                    nodes[(uint)(source/binSize)].seekOutForward += 1;
                    nodes[(uint)(target/binSize)].seekInForward += 1;
                } else {
                    nodes[(uint)(source/binSize)].seekOutBackward += 1;
                    nodes[(uint)(target/binSize)].seekInBackward += 1;
                }

                if (source  < (17 * 60 + 1) && target  < (17 * 60 + 1)) {

                    var key:String = source.toString() + target.toString();
                    //trace(key)
                    if (source != target) {
                        if (!edgeMap.containsKey(key)) {
                            edgeMap.put(key, new EdgeDisplay({from: source , to: target }, Math.abs(source - target), 1));
                        } else {
                            var newCount:Number;
                            edgeMap.grab(key).cnt += 1;

                            newCount = edgeMap.grab(key).cnt;
                            if (source > target) {
                                maxSeeksBackward = Math.max(maxSeeksBackward, newCount);
                            } else if (source < target) {
                                maxSeeksForward = Math.max(maxSeeksForward, newCount);
                            }
                        }
                    }
                }
			}


            var edgeMapValues:Array = edgeMap.values();
            vizContainer = new Sprite();
            vizContainer.y = vizDimensions.y;
            addChild(vizContainer);


			trace("# of edges: " + edgeMapValues.length);

			maxSeeks = Math.max(maxSeeksBackward, maxSeeksForward);
            trace("max seeks forward: " + maxSeeksForward);
            trace("max seeks backward: " + maxSeeksBackward);
			trace("max seeks: " + maxSeeks);

			for(var i:int = 0; i<nodes.length; i++) {
				var _x:int = 10 + (vizDimensions.width-20) * i / (nodes.length - 1);
				var _yy:int = vizDimensions.height / 2;
                nodes[i].graphics.lineStyle(1, 0xffaaaa);
				nodes[i].graphics.drawCircle(_x, _yy, 5);

//                trace(nodes[i].time + " " + nodes[i].seekIn + " " + nodes[i].seekOut);
				var graphHeightRatio:Number = 10;
                nodes[i].graphics.lineStyle(1, 0, 0.3);

                var totalWidthBetweenNodes:Number = (vizDimensions.width - 20)/nodes.length
                var barWidth:Number = totalWidthBetweenNodes / 2 - 10;

                _yy = vizDimensions.height;

                var barHeight:Number = nodes[i].seekIn * graphHeightRatio;
                nodes[i].graphics.beginFill(0xff0000, 0.5);
                nodes[i].graphics.drawRect(_x - barWidth*2, _yy - barHeight, barWidth * 2, barHeight);
                nodes[i].graphics.endFill();

                barHeight = nodes[i].seekInForward * graphHeightRatio;
                nodes[i].graphics.beginFill(Util.brighten(forwardColour, 10), 0.8);
                nodes[i].graphics.drawRect(_x - barWidth * 2, _yy - barHeight, barWidth, barHeight);
                nodes[i].graphics.endFill();

                barHeight = nodes[i].seekInBackward * graphHeightRatio;
                nodes[i].graphics.beginFill(Util.brighten(backwardColour, 10), 0.8);
                nodes[i].graphics.drawRect(_x - barWidth, _yy - barHeight, barWidth, barHeight);
                nodes[i].graphics.endFill();


                barHeight = nodes[i].seekOut * graphHeightRatio;
                nodes[i].graphics.beginFill(0xcc00ff, 0.5);
                nodes[i].graphics.drawRect(_x + 0, _yy - barHeight, barWidth * 2, barHeight);
                nodes[i].graphics.endFill();


                barHeight = nodes[i].seekOutForward * graphHeightRatio;
                nodes[i].graphics.beginFill(Util.brighten(forwardColour, 10), 0.8);
                nodes[i].graphics.drawRect(_x + 0, _yy - barHeight, barWidth, barHeight);
                nodes[i].graphics.endFill();

                barHeight = nodes[i].seekOutBackward * graphHeightRatio;
                nodes[i].graphics.beginFill(Util.brighten(backwardColour, 10), 0.8);
                nodes[i].graphics.drawRect(_x + barWidth, _yy - barHeight, barWidth, barHeight);
                nodes[i].graphics.endFill();
//				vizContainer.addChild(nodes[i]);

				var text:TextField = new TextField()
				text.defaultTextFormat = new TextFormat("Arial", 10, 0xaaaaaa);
				text.autoSize = "center";
				text.text = (millisecondsToHMS(nodes[i].time * 1000)).toString();
                vizContainer.addChild(text);
				text.mouseEnabled = false;
				text.x = _x;
				var waveAmp:Number  = 2 * text.height
                var yOffset:Number = waveAmp * 2;
				text.y = vizDimensions.height - yOffset - waveAmp * Math.sin(i/Math.PI);

                vizContainer.graphics.lineStyle(1, 0xcccccc, 0.5);
                vizContainer.graphics.moveTo(_x, 0);
                vizContainer.graphics.lineTo(text.x, vizDimensions.height);
			}


			var howManyTop:Number = 5;
			var mostFrequentJumps:Array = [];
            edgeMapValues.sortOn("cnt", Array.DESCENDING | Array.NUMERIC);
			for(var i:int = 0; i<howManyTop; i++) {
				mostFrequentJumps.push(edgeMapValues[i]);
			}

			var longestJumps:Array = [];
			edgeMapValues.sortOn("dist", Array.DESCENDING | Array.NUMERIC);
            for(var i:int = 0; i<howManyTop; i++) {
                longestJumps.push(edgeMapValues[i]);
            }

            var shortestJumps:Array = [];
            edgeMapValues.sortOn("dist", Array.NUMERIC);
            for(var i:int = 0; i<howManyTop; i++) {
                shortestJumps.push(edgeMapValues[i]);
            }

			var statText:TextField = new TextField();
            statText.defaultTextFormat = new TextFormat("Arial", 10, 0);
            statText.autoSize = "left";
            statText.appendText("Most Frequent Jumps:\n");
            for each(var edge:Object in mostFrequentJumps) {
                statText.appendText("\t" + edge.cnt + "x " + millisecondsToHMS(edge.edge.from  * 1000) + "=> " + millisecondsToHMS(edge.edge.to  * 1000) + "\n");
            }
            statText.appendText("Longest Jumps:\n");
            for each(var edge:Object in longestJumps) {
                statText.appendText("\t" + edge.cnt + "x " + millisecondsToHMS(edge.edge.from  * 1000) + "=> " + millisecondsToHMS(edge.edge.to  * 1000) + "\n");
            }
            statText.appendText("Shortest Jumps:\n");
            for each(var edge:Object in shortestJumps) {
                statText.appendText("\t" + edge.cnt + "x " + millisecondsToHMS(edge.edge.from  * 1000) + "=> " + millisecondsToHMS(edge.edge.to  * 1000) + "\n");
            }

			addChild(statText);
//			statText.y = filmstrip.height;



            edgeMapValues.sortOn("cnt", Array.NUMERIC);
			for(var j:int = 0; j<edgeMapValues.length; j++) {
				if(edgeMapValues[j].cnt > 0) {
                    var source:Number = edgeMapValues[j].edge.from;
                    var target:Number = edgeMapValues[j].edge.to;
                    var _y:int = vizDimensions.height / 2;
                    var from_x:int = 10 + (vizDimensions.width - 20) * (source / binSize) / (nodes.length - 1);
                    var to_x:int = 10 + (vizDimensions.width - 20) * (target / binSize) / (nodes.length - 1);

                    var dist:int = Math.abs(from_x - to_x);
                    var midPoint:int = Math.min(from_x, to_x) + dist / 2;

                    edgeMapValues[j].graphics.moveTo(from_x, _y)
                    var ratio:Number = edgeMapValues[j].cnt / maxSeeks;
                    if (from_x < to_x) {

                        edgeMapValues[j].graphics.lineStyle(50 * (ratio / 5),
                                Util.brighten(forwardColour, ratio * 10),
                                Math.pow(ratio,1.5) + 0.0);

//                        edgeMapValues[j].graphics.curveTo(midPoint, _y - dist / 2, to_x, _y);
                        edgeMapValues[j].graphics.curveTo(midPoint, _y - ratio * vizDimensions.height/1.5, to_x, _y);
                    } else {

                        edgeMapValues[j].graphics.lineStyle(50 * (ratio / 5),
                                Util.brighten(backwardColour, ratio * 10),
                                Math.pow(ratio,1.5) + 0.0);

//                        edgeMapValues[j].graphics.curveTo(midPoint, _y + dist / 2, to_x, _y);
                        edgeMapValues[j].graphics.curveTo(midPoint, _y + ratio * vizDimensions.height/1.5, to_x, _y);
                    }

//					edgeMapValues[j].clicked.add(playerPlay);

					if(edgeMapValues[j].cnt < 2) {
						edgeMapValues[j].mouseEnabled = false;
					} else {
						edgeMapValues[j].addEventListener(MouseEvent.CLICK,
							function edgeRollOver(e:MouseEvent):void {
                                var from:Number = e.currentTarget.edge.from;
                                var to:Number = e.currentTarget.edge.to;
                                filmstrip.loadVideo(video, new Range(Math.min(from, to), Math.max(from, to)));
								filmstrip.retimeThumbnails()
							})
					}
                    vizContainer.addChild(edgeMapValues[j]);

                    var text:TextField = new TextField();
					if(from_x < to_x) {
                        text.defaultTextFormat = new TextFormat("Arial", 20, 0);
                    } else {
                        text.defaultTextFormat = new TextFormat("Arial", 20, 0);
					}
                    text.autoSize = "center";
                    text.text = edgeMapValues[j].cnt + "x " + millisecondsToHMS(source  * 1000) + "=>" + millisecondsToHMS(target  * 1000);
                    text.mouseEnabled = false;
					text.alpha = 0.3;
                    text.x = midPoint - text.width;

                    if (from_x < to_x > 0) {
                        text.y = _y - edgeMapValues[j].height - text.height;
                    } else {
                        text.y = _y + edgeMapValues[j].height + text.height;
                    }
					edgeMapValues[j].text = text;
                }
			}

		}

		function loadVideo():void {
            statusText = new TextField();
            statusText.defaultTextFormat = new TextFormat("Arial", 20, 0xcccccc, true, false, false, null, null, "center", null, null, null, 4);
            statusText.text = "Logging in...";
            statusText.autoSize = "left";
            statusText.mouseEnabled = false;
            statusText.y = stage.stageHeight - statusText.height;
            addChild(statusText);

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
			VideoMetadataManager.loadCourse("UBC", "UBC_LA_Hackathon", "0", "demo", "2000").add(DUNDUNDUN);
		}

		function DUNDUNDUN():void {

			var arrowLeftX:Number = vizDimensions.width * 1/8;
			var arrowRightX:Number = vizDimensions.width * 7/8;
			var arrowHeadWidth:Number = vizDimensions.width/10;
			var arrowHeadHeight:Number = vizDimensions.height/15;
			var topArrowY:Number = vizDimensions.y + vizDimensions.height * 5/16;

			// top forward arrow
			graphics.lineStyle(100, Util.brighten(forwardColour, 10), 0.05);
			graphics.moveTo(arrowLeftX, topArrowY);
			graphics.lineTo(arrowRightX, topArrowY);
            graphics.lineTo(arrowRightX - arrowHeadWidth, topArrowY - arrowHeadHeight);
            graphics.lineTo(arrowRightX - arrowHeadWidth, topArrowY + arrowHeadHeight);
            graphics.lineTo(arrowRightX, topArrowY);

            var bottomArrowY:Number = vizDimensions.y + vizDimensions.height * 12/16;
			// bottom backward arrow
            graphics.lineStyle(100, Util.brighten(backwardColour, 10), 0.05);
            graphics.moveTo(arrowRightX, bottomArrowY);
            graphics.lineTo(arrowLeftX, bottomArrowY);
            graphics.lineTo(arrowLeftX + arrowHeadWidth, bottomArrowY - arrowHeadHeight);
            graphics.lineTo(arrowLeftX + arrowHeadWidth, bottomArrowY + arrowHeadHeight);
            graphics.lineTo(arrowLeftX, bottomArrowY);
			video = VideoMetadataManager.getVideos()[0];
//			player = new Player(500, 400);
//			player.x = stage.stageWidth/2 - player.width/2;
//			player.y = stage.stageHeight - player.height;
//            addChild(player);
//			trace(video.source[video.primarySource].localPath)
//			player.loadVideo(video, new Range(0, video.duration));

//            player.addEventListener(MouseEvent.MOUSE_DOWN,
//                    function(e:MouseEvent):void {
////						player.stop();
//                        addEventListener(MouseEvent.MOUSE_MOVE,mouseMovePlayer);
//                    })
//            player.addEventListener(MouseEvent.MOUSE_UP,
//                    function(e:MouseEvent):void {
//                        removeEventListener(MouseEvent.MOUSE_MOVE, mouseMovePlayer);
//                    })
//
//            function mouseMovePlayer(e:MouseEvent):void {
//                player.x = stage.mouseX - player.width/2;
//                player.y = stage.mouseY - player.height/2;
//            }

//            playhead = new Shape();
//            playhead.graphics.lineStyle(2, 0xff0000);
//            playhead.graphics.moveTo(0, 0);
//            playhead.graphics.lineTo(0, stage.stageHeight);
//            addChild(playhead);


//            player.playheadTimeUpdated.add(
//                function updatePlayhead(source:Widget, time:Number):void {
//                    playhead.x = time/video.duration * (stage.stageWidth - 20) + 10;
//                }
//            )

			filmstrip = new SimpleFilmstrip(stage.stageWidth, filmstripHeight);
			filmstrip.loadVideo(video, new Range(0, video.duration));
			addChild(filmstrip);

			loader.load();

        }

//		function playerPlay(from:Number, to:Number):void {
//			player.playRange(new Range(Math.min(from, to), Math.max(from, to)));
//		}

		function millisecondsToHMS(timeNumber:Number):String {
			var hours:int, minutes:int, seconds:int, milliseconds:int;
			milliseconds = timeNumber%1000;
			seconds = (timeNumber/1000)%60;
			minutes = (timeNumber/1000/60)%60;
			hours = (timeNumber/1000/60/60);

			var stringBuild:String = "";
			if(hours != 0) {
				stringBuild = hours.toString() + "h" + minutes.toString() + "m";
			} else {
				if(minutes != 0) {
					stringBuild = stringBuild + minutes.toString() + "m";
				}
			}

			return stringBuild + seconds.toString() + "s";
		}
	}
}

import ca.ubc.ece.hct.myview.video.VideoMetadata;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;

import org.osflash.signals.Signal;

class EdgeDisplay extends Sprite {

	public var edge:Object;
	public var dist:Number;
	public var cnt:Number;
	public var text:TextField;

	public var clicked:Signal;

	public function EdgeDisplay(edge:Object, dist:Number, cnt:Number) {
		super();
		this.edge = edge;
		this.dist = dist;
		this.cnt = cnt;

		clicked = new Signal(Number, Number);


		addEventListener(MouseEvent.ROLL_OVER, rollOver);
		addEventListener(MouseEvent.ROLL_OUT, rollOut);
		addEventListener(MouseEvent.CLICK, click);

	}

	public function click(e:MouseEvent):void {
		clicked.dispatch(edge.from, edge.to);
	}

	public function rollOver(e:MouseEvent):void {
		if(text && !contains(text)) {
			addChild(text);
		}
	}

	public function rollOut(e:MouseEvent):void {
        if(text && contains(text)) {
            removeChild(text);
        }

	}
}

class NodeDisplay extends Sprite {

	public var time:Number;
    public var seekIn:Number;
    public var seekOut:Number;

    public var seekInForward:Number;
    public var seekInBackward:Number;
    public var seekOutForward:Number;
    public var seekOutBackward:Number;

	public function NodeDisplay(time:Number):void {
		super();
		this.time = time;
		seekIn = 0;
		seekOut = 0;
        seekInForward = 0;
        seekInBackward = 0;
        seekOutForward = 0;
        seekOutBackward = 0;
	}
}
