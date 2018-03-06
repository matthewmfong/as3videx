/**
 * Created by iDunno on 2017-08-16.
 */
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.myview.VideoATFManager;
import ca.ubc.ece.hct.myview.video.VideoMetadata;
import ca.ubc.ece.hct.myview.video.VideoMetadataManager;

import flash.events.Event;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import mx.controls.Text;

import org.osflash.signals.Signal;

import starling.textures.Texture;
import starling.textures.TextureAtlas;

public class VideoATFManager {

    public static var video:VideoMetadata;
    public static var texture:Texture;
    public static var textureAtlas:TextureAtlas;
    public static var atlas:Array;
    public static var openedSignal:Signal;
    public static var openingInProgress:Boolean = false;

    public function VideoATFManager() {
    }

    public static function loadVideoATF(video:VideoMetadata):Texture {
        VideoATFManager.video = video;
        var file:File = File.applicationStorageDirectory.resolvePath(VideoMetadataManager.thumbnailsFolder + "/" + video.source[video.primarySource].id + "-" + video.filename + ".atf");
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.READ);
        var atfData:ByteArray = new ByteArray();
        fileStream.readBytes(atfData);
        fileStream.close();
        fileStream = null;
        return Texture.fromAtfData(atfData, 1, false);
    }

    public static function loadAsyncVideoATF(video:VideoMetadata, texture:Texture = null, atfData:ByteArray = null, fileStream:FileStream = null):Signal {
        openingInProgress = true;
        VideoATFManager.video = video;
        // TODO: .mp4.atf is hardcoded LOL -.-
        var file:File = File.applicationStorageDirectory.resolvePath(VideoMetadataManager.thumbnailsFolder + "/" + video.filename + ".mp4.atf");
//        trace(file.nativePath);

//        trace(file.nativePath);
        openedSignal = new Signal(VideoMetadata);

        fileStream = new FileStream();
        fileStream.addEventListener(Event.COMPLETE,
                function atfFileOpened(e:Event):void {
                    atfData = new ByteArray();
                    fileStream.readBytes(atfData);
                    fileStream.close();
                    fileStream = null;

                    Texture.fromAtfData(atfData, 1, false,
                            function textureUploaded(t:Texture):void {
                                if(texture) {
                                    texture = t;
                                }
                                VideoATFManager.texture = t;
                                atfData = null;
                                loadATFAtlas(video);
                                openingInProgress = false;
                                openedSignal.dispatch(video);
                                openedSignal = null;

                            });
                });

        fileStream.openAsync(file, FileMode.READ);

        return openedSignal;
    }

    private static function loadATFAtlas(video:VideoMetadata):void {

        var file:File = File.applicationStorageDirectory.resolvePath(VideoMetadataManager.thumbnailsFolder + "/" + video.filename + ".mp4.xml");
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.READ);
        var atlasXML:XML = XML(fileStream.readUTFBytes(fileStream.bytesAvailable));

        textureAtlas = new TextureAtlas(VideoATFManager.texture, atlasXML);
        atlas = [];

        var textureNames:Vector.<String> = textureAtlas.getNames();

        for(var i:int = 0; i<textureNames.length; i++) {
            atlas.push(new FrameBounds(parseFloat(textureNames[i]), textureAtlas.getTexture(textureNames[i])));
        }

        atlas.sortOn("time", Array.NUMERIC);

//        for each (var subTexture:XML in atlasXML.SubTexture) {
//            atlas.push(new FrameBounds(parseFloat(subTexture.@name),
//                       new Rectangle(parseFloat(subTexture.@x),
//                                     parseFloat(subTexture.@y),
//                                     parseFloat(subTexture.@width),
//                                     parseFloat(subTexture.@height))));
//            trace(atlas[atlas.length - 1]);
////            trace(xml.SubTexture[i].@name + " " + xml.SubTexture[i].@x + " " + xml.SubTexture[i].@y + " " + xml.SubTexture[i].@width + " " + xml.SubTexture[i].@height)
//        }
    }

    public static function getTexture(time:Number):Texture {

        var i:int = 0;

        for(i = 0; i<atlas.length; i++) {
            if(atlas[i].time > time) {
                break;
            }
        }

//        trace(i + " " + time + " " + atlas[i].time + " " + atlas[i].texture.region);

        return textureAtlas.getTexture(atlas[i].time.toString());
    }

    public static function unloadVideoATF():void {
        VideoATFManager.video = null;
        if(VideoATFManager.texture) {
            VideoATFManager.texture.dispose();
        }
        VideoATFManager.texture = null;
        if(VideoATFManager.textureAtlas) {
            VideoATFManager.textureAtlas.dispose();
        }
        VideoATFManager.atlas = null;
    }

    public static function loadAsyncVideoATFByFilename(video:String, atfData:ByteArray, fileStream:FileStream, texture:Texture, timing3:Number):Signal {
        var file:File = File.applicationStorageDirectory.resolvePath(video);
        var openedSignal:Signal = new Signal();

        fileStream = new FileStream();
        fileStream.addEventListener(Event.COMPLETE,
                function atfFileOpened(e:Event):void {
                    atfData = new ByteArray();
                    fileStream.readBytes(atfData);
                    fileStream.close();
                    fileStream = null;

                    Texture.fromAtfData(atfData, 1, false,
                            function textureUploaded(t:Texture):void {
                                texture = t;
                                atfData = null;
                                openedSignal.dispatch();

                            });
                });

        fileStream.openAsync(file, FileMode.READ);
        return openedSignal;

    }

}
}

import flash.geom.Rectangle;
import starling.textures.Texture;

class FrameBounds {
    public var time:Number;
    public var texture:Texture;

    public function FrameBounds(time:Number, texture:Texture) {
        this.time = time;
        this.texture = texture;
    }

//    public function toString():String {
//        return "Time: " + time + ", Bounds: " + bounds;
//    }
}