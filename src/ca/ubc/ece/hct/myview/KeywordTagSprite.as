/**
 * Created by iDunno on 2018-01-04.
 */
package ca.ubc.ece.hct.myview {
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.text.TextField;
import starling.text.TextFieldAutoSize;
import starling.text.TextFormat;

public class KeywordTagSprite extends Sprite{

    public var tag:KeywordTag;

    public function KeywordTagSprite(tag:KeywordTag) {
        this.tag = tag;

        var PADDING:uint = 2;

        var iconImage:Image;

        if(tag.colour != Colours.YELLOW) {
            iconImage  = new Image(VidexStarling.assets.getTexture(tag.icon + "_light"));
        } else {

            iconImage = new Image(VidexStarling.assets.getTexture(tag.icon + "_dark"));
        }

        iconImage.x = PADDING;
        iconImage.y = PADDING;
        iconImage.width = 15;
        iconImage.height = 15;
        var textfield:TextField = new TextField(NaN, NaN);
        textfield.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
        textfield.format = new TextFormat("Arial", 12, (tag.colour == Colours.YELLOW ? 0x666666 : 0xffffff));
        textfield.text = tag.string;
        textfield.x = iconImage.x + iconImage.width;
        textfield.y = (iconImage.y + iconImage.height + PADDING) / 2 - textfield.height/2;

        var quad:Quad = new Quad(textfield.x + textfield.width + PADDING,
                Math.max(iconImage.y + iconImage.height + PADDING,
                        textfield.y + textfield.height + PADDING),
                tag.colour);

        addChild(quad);
        addChild(iconImage);
        addChild(textfield);
    }
}
}
