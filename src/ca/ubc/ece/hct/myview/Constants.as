////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {
import flash.text.TextFormat;

public class Constants {

	public static const DOMAIN:String = "animatti.ca/myview";
	public static const SERVER_TO_LOCAL_TIME_DIFF:Number = -3;
	public static const DEFAULT_TEXT_FORMAT:TextFormat = new TextFormat("Arial", 12, 0x333333);


    public static const MONTH:Vector.<String> = new <String>["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    public static const MONTH_SHORT:Vector.<String> = new <String>["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"];
    public static const DAY:Vector.<String> = new <String>["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    public static const DAY_SHORT:Vector.<String> = new <String>["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

	public static const SECONDS2MILLISECONDS:Number = 1000;
	public static const MINUTES2MILLISECONDS:Number = 60 * SECONDS2MILLISECONDS;
	public static const HOURS2MILLISECONDS:Number = 60 * MINUTES2MILLISECONDS;
	public static const DAYS2MILLISECONDS:Number = 24 * HOURS2MILLISECONDS;
	public static const WEEKS2MILLISECONDS:Number = 7 * DAYS2MILLISECONDS;

    public static const TITLEBAR_HEIGHT:Number = 30;

	public static const INSTALLER_TYPE:Object = {WINDOWS: "exe", MAC: "dmg"};
}
}