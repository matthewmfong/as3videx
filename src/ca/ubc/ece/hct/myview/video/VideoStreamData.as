////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.video {
import ca.ubc.ece.hct.myview.*;
	
	public class VideoStreamData {

		private var _videoStreams:Vector.<Stream>;
		private var _audioStreams:Vector.<Stream>;
		private var _subtitleStreams:Vector.<Stream>;

		public function get videoStreams():Vector.<Stream> { return _videoStreams; }
		public function get audioStreams():Vector.<Stream> { return _audioStreams; }
		public function get subtitleStreams():Vector.<Stream> { return _subtitleStreams; }

		public function VideoStreamData() {
			_videoStreams = new Vector.<Stream>();
			_audioStreams = new Vector.<Stream>();
			_subtitleStreams = new Vector.<Stream>();
		}

		public function add(stream:Stream):void {
			switch(stream.type) {
				case Stream.VIDEO:
					_videoStreams.push(stream);
					break;
				case Stream.AUDIO:
					_audioStreams.push(stream);
					break;
				case Stream.SUBTITLE:
					_subtitleStreams.push(stream);
					break;
				default:
					trace("What do I do with " + stream.type + " streams?");
					break;
			}
		}

		public function get width():Number {
			if(_videoStreams.length > 0) {
				return _videoStreams[0].width;
			}
			return -1;
		}

		public function get height():Number {
			if(_videoStreams.length > 0) {
				return _videoStreams[0].height;
			}
			return -1;
		}

		public function get duration():Number {
			if(_videoStreams.length > 0 && _audioStreams.length > 0) {
				return Math.max(_videoStreams[0].duration, _audioStreams[0].duration);
			} else if(_videoStreams.length > 0) {
				return _videoStreams[0].duration;
			} else if(_audioStreams.length > 0) {
				return _audioStreams[0].duration;
			} else {
				return -1;
			}
		}

		public function get framerate():Number {
			if(_videoStreams.length > 0) {
				return _videoStreams[0].framerate;
			}
			return -1;
		}
	}
}