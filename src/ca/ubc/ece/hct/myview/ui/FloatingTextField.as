////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.ui {

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

public class FloatingTextField extends Sprite {

    private var textField:TextField;

    public function FloatingTextField(str:String = null, textFormat:TextFormat = null):void {
        mouseEnabled = false;

        textField = new TextField();
        textField.mouseEnabled = false;
        textField.defaultTextFormat = (textFormat != null) ? textFormat : //new TextFormat("Arial", 10, 0xFFFFE8, "center");
					new TextFormat("Arial", // font
							10, // size
							0xFFFFE8, // color
							true, // bold
							false, // italic
							false, // underline
							null, // url
							null, // target
							"center", // align
							null, // left margin
							null, // right margin
							null, // indent
							4); // leading
        textField.autoSize = TextFieldAutoSize.LEFT;
        textField.text = (str != null) ? str : "";


        draw();

        addChild(textField);
    }

    public function set text(str:String):void {
        textField.text = str;
        textField.x = 0;
        draw();
    }

    public function set defaultTextFormat(val:TextFormat):void {
        textField.defaultTextFormat = val;
    }

    private function draw():void {
        graphics.clear();
        graphics.beginFill(0x333333, 0.5);
        graphics.drawRoundRect(textField.x - 2, textField.y - 1, textField.width + 2, textField.height + 2, 4);
        graphics.endFill();
    }
}
}