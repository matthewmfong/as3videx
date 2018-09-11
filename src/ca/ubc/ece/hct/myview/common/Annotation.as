package ca.ubc.ece.hct.myview.common {
import ca.ubc.ece.hct.Range;

import mx.utils.UIDUtil;

public class Annotation {

    public var id:String;
    public var interval:ca.ubc.ece.hct.Range;
    public var colour:uint;
    public var note:String;
    public var deleteFlag:Boolean = false;

    public function Annotation() {
        id = UIDUtil.createUID();
    }
}
}
