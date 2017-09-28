////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.widgets.subtitleviewer {
 import ca.ubc.ece.hct.myview.Util;

 import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

    import org.osflash.signals.Signal;

    public class CaptionsParser extends EventDispatcher {
        private var _rawArray:Array;
        private var _rawText:String;
        private var _captionsLoader:URLLoader;
        private var _captionsArray:Array;
        private var _individualWordArray:Array;

        public static const WEBVTT:String = "WebVTT";
        public static const NOTE:String = "Note";
        public static const TIME:String = "Time";

        public var loaded:Signal;
        public var parsed:Signal;
        public var error:Signal;

        //do not mess with this directly - it is instantiated by CaptionsHandler
        public function CaptionsParser() {
            _captionsLoader = new URLLoader();
            _captionsArray = [];
            _rawArray = [];
            _individualWordArray = [];

            loaded = new Signal();
            parsed = new Signal();
            error = new Signal();
        }

        //adds some listeners to the URLLoader and then loads the vtt file
        public function loadCaptions(f:String):void {

            _captionsLoader = new URLLoader();
            _captionsArray = [];
            _rawArray = [];
            _rawText = "";
            
            _captionsLoader.addEventListener(Event.COMPLETE, captionsLoaded);
            _captionsLoader.addEventListener(IOErrorEvent.IO_ERROR, captionsError);
            _captionsLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, captionsError);
            _captionsLoader.load(new URLRequest(f));
        }

        //this is the core of the parser - it attempts to parse the loaded vtt file into cute little objects.
        private function parseCaptions(r:Array):void {
            // trace("PRINT 0" + (new Date()).time);
            // var dd:Date = new Date();
            var length:int = r.length;
            var blankLine:RegExp = /\n\s*\n/;
            // var webVTTLine:RegExp = /WEBVTT/;
            // var noteLine:RegExp = /NOTE/;
            var timeLine:RegExp = /(\d\d:\d\d:\d\d(\.|\,)\d\d\d --> \d\d:\d\d:\d\d(\.|\,)\d\d\d)|(\d\d:\d\d(\.|\,)\d\d\d --> \d\d:\d\d(\.|\,)\d\d\d)/;

            try {
                for(var i:int = 0; i<r.length; i++) {
                    var lineType:String = null;
                    // if(webVTTLine.test(r[i])) {
                    //     lineType = WEBVTT;
                    // } else if(noteLine.test(r[i])) {
                    //     lineType = NOTE;
                    // } else 
                    if(timeLine.test(r[i])) {
                        lineType = TIME;
                    }

                    // trace("__ FOUND __ : --" + lineType + "-- in '" + r[i] + "'");
                    switch(lineType) {
                        // case WEBVTT:
                        // break;
                        // case NOTE:
                        // break;
                        case TIME:
                        // 1. identifier line [optional]
                        // 2. 00:00:02.000 --> 00:00:03.000
                        // 3. line <00:00:02.250> 1
                        // 4. line <00:00:02.750> 2

                        // find startTime and endTime of the caption
                        // find character locations of inline cues

                            // check where the identifier line ends
                            var endOfIdentifierLine:int = -1;
                            if(r[i].indexOf("\n", 0) < r[i].indexOf("-->", 0)) {
                                endOfIdentifierLine = r[i].indexOf("\n", 0);
                            }
                            // check where the time-line ends
                            var endOfTimeLine:int = r[i].indexOf("\n", endOfIdentifierLine+1);

                            var timeRegExp:RegExp = /(\d\d:\d\d(\.|\,)\d\d\d)|(\d\d:\d\d:\d\d(\.|\,)\d\d\d)/g;
                            var timeStart:int = Util.timeStringToMilliseconds(timeRegExp.exec(r[i])[0]);
                            var timeEnd:int = Util.timeStringToMilliseconds(timeRegExp.exec(r[i])[0]);

                            // trace("timeStart = " + timeStart + ", timeEnd = " + timeEnd);

                            // search for inline timestamps
                            var cueTimeStampRegExp:RegExp = /(<\d\d:\d\d(\.|\,)\d\d\d>)|(<\d\d:\d\d:\d\d(\.|\,)\d\d\d>)/g; // g - global
                            var inlineTimeStamps:Array = [];
                            var result:Object = cueTimeStampRegExp.exec(r[i]);

                            while(result != null) {
                                var newTime:Object = {};
                                var cutTime:String = result[0].substring(result[0].indexOf("<")+1, result[0].indexOf(">"));
                                // trace("cutTime = " + cutTime);
                                newTime.time = Util.timeStringToMilliseconds(cutTime);

                                newTime.index = result.index;

                                inlineTimeStamps.push(newTime);
                                // trace("newTime.time = " + newTime.time);
                                result = cueTimeStampRegExp.exec(r[i]);
                            }
                            // for(var ia:int = 0; ia<inlineTimeStamps.length; ia++) {
                                // trace("Timestamps found: index=" + inlineTimeStamps[ia].index + ", " + inlineTimeStamps[ia].time);
                            // }

                            // start creating payload objects
                            var payloads:Array = [];
                            var cursor:int = endOfTimeLine+1;
                            // the +1 so that we do the last one.
                            for(var j:int = 0; j<inlineTimeStamps.length + 1; j++) {
                                var phrase:String;
                                var endTime:int;

                                if(j >= inlineTimeStamps.length) { 
                                    phrase = r[i].substring(cursor, r[i].length);
                                    endTime = timeEnd;
                                } else {
                                    phrase = r[i].substring(cursor, inlineTimeStamps[j].index);
                                    endTime = inlineTimeStamps[j].time-1;
                                }
                                var startTime:int = 0;// = timeStart;


                                if(j == 0) {
                                    startTime = timeStart;
                                } else {
                                    startTime = inlineTimeStamps[j-1].time;
                                }

                                // trace("hah " + j + " " + phrase + " " + startTime + " ");
                                // clean the payload of the timestamps
                                phrase = phrase.replace(cueTimeStampRegExp, "");

                                // clean the payload of the newlines
                                phrase = phrase.replace("\n", " ");

                                // clean the payload of multiple spaces
                                phrase = phrase.replace(/\s{2,}/g, " ");

                                // trace("\"" + phrase +"\"");
                                if(phrase.charAt(phrase.length - 1) == " ") {
                                    // trace("case 1 \""+ phrase  +"\"")
                                    // trace(" to    \"" + phrase.substring(0, phrase.length - 1) +"\"")
                                    phrase = phrase.substring(0, phrase.length - 1);
                                }

                                if(phrase.charAt(0) == " ") {
                                    // trace("case 2 " + phrase)
                                    phrase = phrase.substring(1, phrase.length);
                                }

                                var newPayload:Payload = new Payload(phrase, startTime, endTime);
                                payloads.push(newPayload);
                                if(rawText.length != 0)
                                    rawText += " " + phrase;
                                else
                                    rawText += phrase;

                                if(j < inlineTimeStamps.length) {
                                    // timeStart = cueTimeStamps[j].time;
                                    cursor = inlineTimeStamps[j].index;
                                }
                                // trace("payload[" + j + "] = " +newPayload.toString());
                            }

                            var words:Array;
                            // var word:Payload;
                            var currentSyllable:int = 0, totalSyllables:int = 0, timePerSyllable:Number;
                            for(var k:int = 0; k<payloads.length; k++) {
                                words = payloads[k].phrase.split(" ");
                                for(var l:int = 0; l<words.length; l++) {
                                    // if the word is a single space, get rid of it.
                                    if(words[l] == " ") {
                                        words[l].splice(l, 1);
                                    }
                                    words[l] += " ";
                                }
                                for(l = 0; l<words.length; l++) {
                                    totalSyllables += countSyllables(words[l]);
                                }
                                timePerSyllable = (payloads[k].endTime - payloads[k].startTime)/totalSyllables;
                                for(var m:int = 0; m<words.length; m++) {
                                    _individualWordArray.push(new Payload(words[m], payloads[k].startTime + currentSyllable*timePerSyllable, 
                                                                                payloads[k].startTime + currentSyllable*timePerSyllable + countSyllables(words[m])*timePerSyllable))
                                    currentSyllable += countSyllables(words[m]);
                                }

                            }


                            var cue:Cue = new Cue(i, timeStart, timeEnd, "", payloads);
                            // trace(cue);
                            _captionsArray.push(cue);
                            
                        default:
                        break;
                    }

                }

                for(i = 1; i<_individualWordArray.length; i++) {
                    // trace("[" + _individualWordArray[i] + "]")
                    if(_individualWordArray[i].startTime < _individualWordArray[i-1].endTime) {
                        _individualWordArray[i].startTime = _individualWordArray[i-1].endTime +1;
                    }
                }

                for(i = 1; i<_captionsArray.length; i++) {
                    if(_captionsArray[i].startTime < _captionsArray[i-1].endTime) {
                        _captionsArray[i].startTime = _captionsArray[i-1].endTime +1;
                    }
                }

                // //let the application know that we have parsed the file just fine!
                // trace("_rawText = " + _rawText);
                // trace("parse Captions crud " + ((new Date()).time - dd.time));
                // trace("PRINT 1" + (new Date()).time);

                while(_rawArray.length > 0) {
                    _rawArray.pop();
                }
                _rawArray = null;

                parsed.dispatch();

                dispatchEvent(new CaptionParseEvent(CaptionParseEvent.PARSED, true));
            } catch (e:Error){
                trace(e)
                _captionsLoader.removeEventListener(IOErrorEvent.IO_ERROR, captionsError);
                _captionsLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, captionsError);
                //let the application know something truly horrifying has occurred...
                error.dispatch();
                dispatchEvent(new CaptionParseEvent(CaptionParseEvent.ERROR, true));
            }

        }

        //captions loaded successfully - now this will all get parsed into little neat objects and placed in an array.
        public function captionsLoaded(e:Event):void {
            loaded.dispatch();
            dispatchEvent(new CaptionLoadEvent(CaptionLoadEvent.LOADED, true));
            var captionSignifier:RegExp = /(\r\n\r\n)|(\n\n)/g;

            _rawArray = e.target.data.split(captionSignifier);
            // for(var j:int = 0; j<rawArray.length; j++) {
                // trace(rawArray[j] + "|");
            // }
            parseCaptions(_rawArray);

            // trace("aldksfklsdjfaldjflasj laksjd flajdflasj dlasldfjalsfj")
            // for(var i:int = 0; i<_captionsArray.length; i++) {
                // trace(i);
                // trace("|" + _captionsArray[i].startTime + "| --> |" + _captionsArray[i].endTime + "|\n|" + _captionsArray[i].payloads);
            // }

            // for(var i:int = 0; i<_individualWordArray.length; i++) {
                // trace(_individualWordArray[i]);
            // }
            //let the application know that we have loaded the file just fine!
            _captionsLoader.removeEventListener(Event.COMPLETE, captionsLoaded);
        }

        //tsk tsk tsk... something is wrong... does the file even exist?
        private function captionsError(e:*):void {
            //let the application know something truly horrifying has occurred...
            error.dispatch();
            dispatchEvent(new CaptionLoadEvent(CaptionLoadEvent.ERROR, true));
            _captionsLoader.removeEventListener(IOErrorEvent.IO_ERROR, captionsError);
            _captionsLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, captionsError);
            _captionsArray = [];
        }

        //CaptionsHandler grabs the captions through this.
        public function get captionsArray():Array {
            return _captionsArray;
        }

        public function set captionsArray(val:Array):void {
            _captionsArray = val;
        }

        public function get individualWords():Array {
            return _individualWordArray;
        }

        public function set individualWords(val:Array):void {
            _individualWordArray = val;
        }


        public function get rawText():String { 
            return _rawText; 
        }

        public function set rawText(val:String):void {
            _rawText = val;
        }

        // public function get rawArray():Array { return _rawArray; }
        
        public function get captionsLoader():URLLoader { return captionsLoader; }
        // public function get captionsArray():Array { return _captionsArray; }

        public function countSyllables(word:String):int {
            var vowels:Array = ['a', 'e', 'i', 'o', 'u', 'y'];
            var currentWord:String = word;
            var numVowels:int = 0;
            var lastWasVowel:Boolean = false;
            for(var i:int = 0; i<currentWord.length; i++) {//char wc in currentWord)
            
                var wc:String = currentWord.charAt(i);
                var foundVowel:Boolean = false;
                for (var j:int = 0; j<vowels.length; j++) {// in vowels)
                
                    var v:String = vowels[j];
                    //don't count diphthongs
                    if (v == wc && lastWasVowel)
                    {
                        foundVowel = true;
                        lastWasVowel = true;
                        break;
                    }
                    else if (v == wc && !lastWasVowel)
                    {
                        numVowels++;
                        foundVowel = true;
                        lastWasVowel = true;
                        break;
                    }
                }

                //if full cycle and no vowel found, set lastWasVowel to false;
                if (!foundVowel)
                    lastWasVowel = false;
            }
            //remove es, it's _usually? silent
            if (currentWord.length > 2 && 
                currentWord.substring(currentWord.length - 2, 2) == "es")
                numVowels--;
            // remove silent e
            else if (currentWord.length > 1 &&
                currentWord.substring(currentWord.length - 1, 1) == "e")
                numVowels--;

            return Math.max(1, numVowels);
        }
    }
}
