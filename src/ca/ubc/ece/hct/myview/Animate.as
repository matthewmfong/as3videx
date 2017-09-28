/**
 * Created by iDunno on 2017-07-26.
 */
package ca.ubc.ece.hct.myview {
import com.greensock.TweenLite;
import com.greensock.easing.Power2;

import org.osflash.signals.Signal;

import starling.display.DisplayObject;

public class Animate {

    public static const TWEENTIME:Number = 0.2;

    public static function growAndAppear(target:DisplayObject):void {

        var toX:Number = target.x;
        var toY:Number = target.y;
        target.x = toX + target.width/2;
        target.y = toY + target.height/2;
        target.alpha = 0;
        target.scale = 0;

        TweenLite.to(target, TWEENTIME, {x: toX, y:toY, alpha: 1, scale: 1, ease:Power2.easeInOut});
    }

    public static function shrinkAndDisappear(target:DisplayObject):Signal {
        var toX:Number = target.x;
        var toY:Number = target.y;
        var signal:Signal = new Signal(DisplayObject);
        TweenLite.to(target, TWEENTIME,
                {alpha: 0,
                    x: target.x + target.width/2,
                    y: target.y + target.height/2,
                    scale: 0,
                    ease:Power2.easeInOut,
                onComplete: function animationComplete():void { signal.dispatch(target); }
                }
        );
        return signal;
    }

    public static function fadeOut(target:DisplayObject):Signal {
        var signal:Signal = new Signal(DisplayObject);
        TweenLite.to(target, TWEENTIME,
                {alpha: 0,
                    ease:Power2.easeInOut,
                    onComplete: function animationComplete():void { signal.dispatch(target); }
                }
        );
        return signal;
    }
}
}
