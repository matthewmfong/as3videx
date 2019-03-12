package ca.ubc.ece.hct.myview.dashboard {
import flash.utils.Dictionary;

public class UsersDictionary {

    private static var numberToString:Dictionary = new Dictionary();
    private static var stringToNumber:Dictionary = new Dictionary();
    private static var incrementingNumber:int = 1;

    public static function newUser(string:String):void {
        getUserNumber(string);
    }

    public static function getUserNumber(string:String):int {
        if(stringToNumber[string] == null) {
            stringToNumber[string] = incrementingNumber++;
        }
        return stringToNumber[string];
    }

    public static function getUserID(number:int):String {
        return numberToString[number];
    }
}
}
