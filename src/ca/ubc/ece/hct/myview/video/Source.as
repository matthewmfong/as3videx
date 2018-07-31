////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.video {

    import org.osflash.signals.Signal;

    public class Source {

        private var _url:String;
        public function get url():String { return _url; }
        public var id:String;
        private var _localPath:String;
        public function get localPath():String { return _localPath; }

        public var bytesDownloaded:Number = 0;
        public var totalBytes:Number = 1;

        public var queuedForDownload:Boolean = false;
        public var downloaded:Boolean = false;

        public function get filename():String {
            var urlSplit:Array = url.split("/");
            var filename:String = urlSplit[urlSplit.length - 1];
            return filename;
        }

        public function get extension():String {
            var urlSplit:Array = url.split("/");
            var filename:String = urlSplit[urlSplit.length - 1];
            var filenameSplit:Array = filename.split(".");
            var extension:String = filenameSplit[filenameSplit.length - 1];
            return extension;
        }

        // may want to rename this in the future, it's actually the extension, not the mimetype string
        private var _mimeType:String;
        public function get mimeType():String { return _mimeType; }
        public var width:Number, height:Number;
        public var framerate:Number;
        public var keyframes:Array;
        private var _language:String;
        public function get language():String { return _language; };
        public var captions:VideoCaptions;
        public var captionsLoaded:Signal;

        public var downloadProgress:Signal;
        public var downloadComplete:Signal;

        public function Source() {
            keyframes = [];
            captions = new VideoCaptions();
            downloadProgress = new Signal(Number, Number); // bytesDownloaded, totalBytes;
            downloadComplete = new Signal(Boolean);
        }

        public function set mimeType(s:String):void {
            _mimeType = s;

            if(_mimeType != "vtt" && _mimeType != "srt") {
                captions = null;
            } else {
                // this will be dispatched by VideoCaption.captionsLoadedAndParsed();
                captionsLoaded = captions.loaded;
            }

            if( checkIfReadyToLoadCaptions() ) {
                loadAndParseCaptions();
            }
        }

        public function set url(s:String):void {
            _url = s;
            if( checkIfReadyToLoadCaptions() ) {
                loadAndParseCaptions();
            }
        }

        public function set language(s:String):void {
            _language = s;
            if( checkIfReadyToLoadCaptions() ) {
                loadAndParseCaptions();
            }
        }

        public function set localPath(s:String):void {
            _localPath = s;
            if( checkIfReadyToLoadCaptions() ) {
                loadAndParseCaptions();
            }
        }

        public function set progress(val:Number):void {


            bytesDownloaded = val;
            downloadProgress.dispatch(val, totalBytes);
        }

        public function set complete(val:Boolean):void {
            downloadComplete.dispatch(val);
        }

        private function checkIfReadyToLoadCaptions():Boolean {
            return ( (_mimeType == "vtt" || _mimeType == "srt") && language != null && localPath != null);
        }

        private function loadAndParseCaptions():void {
            captions.load(language, "file://" + _localPath);
        }
    }
}
