/**
 * Created by iDunno on 2018-01-01.
 */
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.Range;

import starling.display.Image;
import starling.display.Quad;

import starling.display.Sprite;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;

public class KeywordTag {

    public static const THUMBS_UP:String = "thumbs_up";
    public static const CAUTION:String = "caution";
    public static const PUZZLE:String = "puzzle";
    public static const QUESTION_MARK:String = "question_mark";
    public static const STAR:String = "star";
    public static const TAG:String = "tag";

    public var string:String;
    public var interval:Range;
    public var colour:uint;
    public var icon:String;

    private var _sprite:KeywordTagSprite;

    public function KeywordTag(string:String, interval:Range, colour:uint, icon:String = TAG) {
        this.string = string;
        this.interval = interval;
        this.colour = colour;
        this.icon = icon;

    }

    public function get sprite():KeywordTagSprite {

        if(_sprite == null) {
            _sprite = new KeywordTagSprite(this);
        }
        return _sprite;

    }
}
}
