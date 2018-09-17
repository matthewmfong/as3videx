////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview {
	
	public class Courses {

        public static const courses:Object = {'DEMO_COURSE':                        new Course("UBC", "DemonstrationCourse", "0", "demo", "2000"),
                                              'DevTestCourse':                      new Course("UBC", "DevTestCourse", "0", "test", "2000"),
                                              'TokyoTech_DEMO_COURSE':              new Course("TokyoTech", "TokyoTechDemoCourse", "0", "demo", "2000"),


            'BCIT_CHEM0011_1_winter_2018':        new Course("BCIT", "CHEM0011", "1", "winter", "2018"),
            'BCIT_CHEM1103_1_winter_2018':        new Course("BCIT", "CHEM1103", "1", "winter", "2018"),
            'BCIT_CHEM1105_1_winter_2018':        new Course("BCIT", "CHEM1105", "1", "winter", "2018"),
            'BCIT_CHEM1115_1_winter_2018':        new Course("BCIT", "CHEM1115", "1", "winter", "2018"),
            'BCIT_CHEM1121_1_winter_2018':        new Course("BCIT", "CHEM1121", "1", "winter", "2018"),
            'BCIT_CHEM0011_1_winter_2018-INSTRUCTOR':        new Course("BCIT", "CHEM0011", "1", "winter", "2018"),
            'BCIT_CHEM1103_1_winter_2018-INSTRUCTOR':        new Course("BCIT", "CHEM1103", "1", "winter", "2018"),
            'BCIT_CHEM1105_1_winter_2018-INSTRUCTOR':        new Course("BCIT", "CHEM1105", "1", "winter", "2018"),
            'BCIT_CHEM1115_1_winter_2018-INSTRUCTOR':        new Course("BCIT", "CHEM1115", "1", "winter", "2018"),
            'BCIT_CHEM1121_1_winter_2018-INSTRUCTOR':        new Course("BCIT", "CHEM1121", "1", "winter", "2018"),

                                              'BCIT_CHEM0011_1_spring_2018':        new Course("BCIT", "CHEM0011", "1", "spring", "2018"),
                                              'BCIT_CHEM0012_1_spring_2018':        new Course("BCIT", "CHEM0012", "1", "spring", "2018"),
                                              'BCIT_CHEM0011_1_spring_2018-INSTRUCTOR':        new Course("BCIT", "CHEM0011", "1", "spring", "2018"),
                                              'BCIT_CHEM0012_1_spring_2018-INSTRUCTOR':        new Course("BCIT", "CHEM0012", "1", "spring", "2018"),


                                              'BCIT_CHEM0011_1_spring_2017':        new Course("BCIT", "CHEM0011", "1", "spring", "2017"),
                                              'BCIT_CHEM0011_1_winter_2017':        new Course("BCIT", "CHEM0011", "1", "winter", "2017"),
                                              'BCIT_CHEM0011_1_winter_2017_TEST':   new Course("BCIT", "CHEM0011", "test", "winter", "2017"),
                                              'BCIT_CHEM0012_1_spring_2017':        new Course("BCIT", "CHEM0012", "1", "spring", "2017"),
                                              'BCIT_CHEM1121_1_winter_2017':        new Course("BCIT", "CHEM1121", "1", "winter", "2017"),

                                              'UBC_APSC160_101_winter_2016':        new Course("UBC", "APSC160", "101", "winter", "2016"),
                                              'UBC_APSC160_203_204_spring_2017':    new Course("UBC", "APSC160", "203_204", "spring", "2017"),
                                              'UBC_CPEN441_201_spring_2017':        new Course("UBC", "CPEN441", "201", "spring", "2017"),
                                              'UBC_PHIL102_003_spring_2017':        new Course("UBC", "PHIL102", "003", "spring", "2017")};

		public static function getCourse(courseString:String):Course {
            return courses[courseString];
		}
	}
}