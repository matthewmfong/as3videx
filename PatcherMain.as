package {

	import ca.ubc.ece.hct.PatcherView;
	import flash.display.MovieClip

	public class PatcherMain extends MovieClip {

		public static const CLASS_ID:String = "UBC_PHIL_003_spring_2017-INSTRUCTOR";
		private var patcherView:PatcherView;

		public function PatcherMain() {
			patcherView = new PatcherView(CLASS_ID);
			addChild(patcherView);
		}

	}
}