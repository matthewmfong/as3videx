////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct {

    import flash.events.EventDispatcher;
    import flash.net.URLRequest;
    import flash.net.URLStream;
	import flash.net.URLVariables;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.ByteArray;

    public class URLLoaderPlus extends EventDispatcher {
        private var _urlRequest:URLRequest; //the built-in URLLoader doesn't give you any access to the requested URL...
        private var _stream:URLStream;
        // private var _dataFormat:String;// = "text"
        private var _data:ByteArray;
        private var _bytesLoaded:uint;// = 0
        private var _bytesTotal:uint;// = 0

        public function get request():URLRequest { return _urlRequest;}     
        public function get filename():String { return (request.url == "") ? "null" : request.url.match(/(?:\\|\/)([^\\\/]*)$/)[1];}
        // public function get dataFormat():String { return _dataFormat;}
        public function get data():ByteArray { return _data; }
        public function get bytesLoaded():uint { return _bytesLoaded; }
        public function get bytesTotal():uint { return _bytesTotal; }

        public function URLLoaderPlus(request:URLRequest = null){
            super();
            _stream = new URLStream();
            _stream.addEventListener(Event.OPEN, openHandler);
            _stream.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            _stream.addEventListener(Event.COMPLETE, completeHandler);
            _stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            _stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            _stream.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
            if (request != null){
                load(request);
            };
        }
        public function load(request:URLRequest):void {
            _urlRequest = request;
            _stream.load(_urlRequest);
        }
        public function close():void{
            _stream.close();
        }

        private function progressHandler(event:ProgressEvent):void {
            _bytesLoaded = event.bytesLoaded;
            _bytesTotal = event.bytesTotal;
            dispatchEvent(event);
        }
        private function completeHandler(event:Event):void{
            // trace("request.url = " + request.url);
            // trace("_stream.bytesAvailable = " + _stream.bytesAvailable)
            var bytes:ByteArray = new ByteArray();
            _stream.readBytes(bytes);

            _data = bytes;

            // trace("bytes.length = " + bytes.length);
            // trace("_data = " + _data);

            // trace("URLLoader: (" + fileName + "): " + event.type);
            dispatchEvent(event);
        }
        private function openHandler(event:Event):void {
            // trace("URLLoader: ("+filename+"): " + event.type +" "+_urlRequest.url);
             dispatchEvent(event);
        }
        private function securityErrorHandler(event:SecurityErrorEvent):void {
            // trace("URLLoader ("+filename+"): " + event.type + " - " + event.text);
            dispatchEvent(event);
        }
        private function httpStatusHandler(event:HTTPStatusEvent):void {          
            dispatchEvent(event);
        }   
        private function ioErrorHandler(event:IOErrorEvent):void {
            // trace("URLLoader ("+filename+"): " + event.type + " - " + event.text);
            dispatchEvent(event);
        }       
    }
}