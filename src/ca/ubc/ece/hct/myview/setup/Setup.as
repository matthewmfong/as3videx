////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////

package ca.ubc.ece.hct.myview.setup {

import ca.ubc.ece.hct.myview.ServerDataLoader;
import ca.ubc.ece.hct.myview.UserID;
import ca.ubc.ece.hct.myview.setup.ConsentForm;
import ca.ubc.ece.hct.myview.setup.Questionnaire;
import ca.ubc.ece.hct.myview.View;

import flash.events.Event;

import org.osflash.signals.Signal;
import org.osflash.signals.natives.NativeSignal;

public class Setup extends View {

    private var consentForm:ConsentForm;
    private var questionnaire:Questionnaire;
    public var cancelledConsent:Signal;
    public var finishedSetup:Signal;
    private var addedToStageSignal:NativeSignal;

    public function Setup() {
        cancelledConsent = new Signal();
        finishedSetup = new Signal();

        addedToStageSignal = new NativeSignal(this, Event.ADDED_TO_STAGE, Event);
        addedToStageSignal.addOnce(addedToStage);
    }

    override protected function addedToStage(e:Event = null):void {

        consentForm = new ConsentForm(stage.stageWidth - 50, stage.stageHeight - 50, "consentform.html");
        consentForm.x = 25;
        consentForm.y = 25;
        consentForm.addEventListener(ConsentForm.ConsentFormAccept, acceptConsent);
        consentForm.addEventListener(ConsentForm.ConsentFormCancel, cancelConsent);
        addChild(consentForm);
    }

    private function acceptConsent(e:Event = null):void {
        consentForm.removeEventListener(ConsentForm.ConsentFormAccept, acceptConsent);
        consentForm.removeEventListener(ConsentForm.ConsentFormCancel, cancelConsent);
        removeChild(consentForm);
        consentForm.destroy();
        consentForm = null;
        showQuestionnaire();
    }

    private function cancelConsent(e:Event = null):void {
        consentForm.removeEventListener(ConsentForm.ConsentFormAccept, acceptConsent);
        consentForm.removeEventListener(ConsentForm.ConsentFormCancel, cancelConsent);
        consentForm.destroy();
        consentForm = null;
        cancelledConsent.dispatch();
    }

    private function showQuestionnaire():void {
        questionnaire = new Questionnaire(stage.stageWidth - 50, stage.stageHeight - 50);
        questionnaire.x = 25;
        questionnaire.y = 25;
        questionnaire.addEventListener(Questionnaire.QuestionnaireAccept, questionnaireSubmit);
        addChild(questionnaire);
    }

    private function questionnaireSubmit(e:Event = null):void {
        questionnaire.removeEventListener(Questionnaire.QuestionnaireAccept, questionnaireSubmit);
        ServerDataLoader.addLog(UserID.id,
                "Questionnaire: 1. " + questionnaire.a +
                ", 2. " + questionnaire.b +
                ", 3. " + questionnaire.c +
                ", 4. " + questionnaire.d + ".");
        removeChild(questionnaire);
        questionnaire.destroy();
        questionnaire = null;

        finishedSetup.dispatch();
    }

    public function setSize(width:Number, height:Number):void {
        if(consentForm && contains(consentForm)) {
            consentForm.setSize(width - 50, height - 50);
        }

        if(questionnaire && contains(questionnaire)) {
            questionnaire.setSize(width - 50, height - 50);
        }
    }


}
}