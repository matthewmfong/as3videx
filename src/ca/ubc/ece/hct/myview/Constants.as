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
	public static const DAY:Vector.<String> = new <String>["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

	public static const SECONDS2MILLISECONDS = 1000;
	public static const MINUTES2MILLISECONDS = 60 * SECONDS2MILLISECONDS;
	public static const HOURS2MILLISECONDS = 60 * MINUTES2MILLISECONDS;
	public static const DAYS2MILLISECONDS = 24 * HOURS2MILLISECONDS;
	public static const WEEKS2MILLISECONDS = 7 * DAYS2MILLISECONDS;

}
}