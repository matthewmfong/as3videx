////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;

public class View extends Sprite implements IView {

		protected var _width:Number;
		protected var _height:Number;


		public function bringChildToFront(displayObject:DisplayObject):void {
			if(displayObject && contains(displayObject)) {
				setChildIndex(displayObject, numChildren - 1);
			}
		}

        protected function addedToStage(e:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
        }

        public function move(x:Number, y:Number):void {
            this.x = x;
            this.y = y;
        }

        override public function get width():Number {
            return _width;
        }

        override  public function set width(value:Number):void {
            _width = value;
        }

        override public function get height():Number {
            return _height;
        }

        override public function set height(value:Number):void {
            _height = value;
        }
    }
}