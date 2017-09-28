////////////////////////////////////////////////////////////////////////
//                                                                    //
//  Author: Matthew Fong                                              //
//          Human Communication Laboratories - http://hct.ece.ubc.ca  //
//          The University of British Columbia                        //
//                                                                    //
////////////////////////////////////////////////////////////////////////
package ca.ubc.ece.hct.myview {
import ca.ubc.ece.hct.myview.widgets.StarlingVideoPlayerView;
import ca.ubc.ece.hct.myview.widgets.StarlingWidget;

import feathers.controls.Button;
import feathers.controls.ButtonState;

import feathers.controls.Header;
import feathers.controls.PickerList;
import feathers.controls.TextInput;
import feathers.controls.ToggleButton;
import feathers.controls.renderers.DefaultListItemRenderer;
import feathers.controls.renderers.IListItemRenderer;
import feathers.data.ArrayCollection;
import feathers.events.FeathersEventType;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Quad;
import starling.events.Event;
import starling.text.TextFormat;

public class StarlingPlayerViewToolbar extends StarlingWidget {

    public static const searchDefaultText:String = "Search...";
    public static var _this:StarlingPlayerViewToolbar;

    private var header:Header;
    private var hideButton:ToggleButton;
    private var personalButton:ToggleButton;
    private var classButton:ToggleButton;
    private var searchInput:TextInput;
    private var playHighlightsPicker:PickerList;
    private var playingHighlightsIcon:Quad;

    public function get hideButtonIsSelected():Boolean { return hideButton.isSelected; }
    public function get personalButtonIsSelected():Boolean { return personalButton.isSelected; }
    public function get classButtonIsSelected():Boolean { return classButton.isSelected; }

    public function set hideButtonIsSelected(val:Boolean):void { hideButton.isSelected = val; }
    public function set personalButtonIsSelected(val:Boolean):void { personalButton.isSelected = val; }
    public function set classButtonIsSelected(val:Boolean):void { classButton.isSelected = val; }

    private var buttons:Vector.<Button>;
//    private var q:Quad;

    public function StarlingPlayerViewToolbar() {
        _this = this;

//        q = new Quad(_width, _height, 0xff0000);
        header = new Header();

        buttons = new Vector.<Button>();
        hideButton = new ToggleButton();
        personalButton = new ToggleButton();
        classButton = new ToggleButton();

        searchInput = new TextInput();

        playHighlightsPicker = new PickerList();

        buttons.push(hideButton, personalButton, classButton);


    }

    override protected function addedToStage(e:Event = null):void {
        super.addedToStage(e);

        trace("addedToStage _width=" + _width);

//        addChild(q);

        header.width = _width;
        header.height = StarlingVideoPlayerView.TOOLBAR_SIZE;
        header.padding = 2;
        header.validate();
        addChild(header);

        var textFormat:TextFormat = new TextFormat("Arial", 12, 0x000000);
        var textFormatSelected:TextFormat = new TextFormat("Arial", 12, 0x007aff);
        for each(var button:Button in buttons) {
            button.height = header.height - header.padding * 2;
            if(button is ToggleButton) {
                (ToggleButton)(button).isToggle = true;
                (ToggleButton)(button).setFontStylesForState(ButtonState.DOWN, textFormat);
                (ToggleButton)(button).setFontStylesForState(ButtonState.DOWN_AND_SELECTED, textFormatSelected);
                (ToggleButton)(button).setFontStylesForState(ButtonState.UP, textFormat);
                (ToggleButton)(button).setFontStylesForState(ButtonState.UP_AND_SELECTED, textFormatSelected);
                (ToggleButton)(button).setFontStylesForState(ButtonState.HOVER, textFormat);
                (ToggleButton)(button).setFontStylesForState(ButtonState.HOVER_AND_SELECTED, textFormatSelected);
            }
            button.fontStyles = textFormat;
            button.paddingTop = 2;
            button.paddingBottom = 2;
            button.paddingLeft = 5;
            button.paddingRight = 5;
            button.gap = 5;
            button.validate();
        }

        searchInput.text = searchDefaultText;
        searchInput.paddingTop = 2;
        searchInput.paddingBottom = 2;
        searchInput.paddingLeft = 5;
        searchInput.paddingRight = 5;
        searchInput.height = header.height - header.padding * 2;
        searchInput.addEventListener(FeathersEventType.FOCUS_IN,
            function searchFocusIn(e:Event):void {
                if(searchInput.text == searchDefaultText) {
                    searchInput.text = "";
                }
            });
        searchInput.addEventListener(Event.CHANGE,
            function searchChange(e:Event):void {
                searchedText.dispatch(_this, searchInput.text);
            });
        searchInput.addEventListener(FeathersEventType.FOCUS_OUT,
            function searchFocusIn(e:Event):void {
                if(searchInput.text == "") {
                    searchInput.text = searchDefaultText;
                }
            });
        addChild(searchInput);
//        header.leftItems = new <DisplayObject> [searchInput];

        playHighlightsPicker.dataProvider = new ArrayCollection();

        for(var i:int = 0; i<Colours.colourNames.length; i++) {

            var icon:Quad = new Quad(20, 20, Colours.colours[i]);
            icon.setVertexPosition(1, 20, 10);
            icon.setVertexPosition(3, 20, 10);
            playHighlightsPicker.dataProvider.push(
                    { colour: Colours.colours[i],
                        text: Colours.colourNames[i],
                        icon: icon});
        }

        playHighlightsPicker.itemRendererFactory = function():IListItemRenderer {
            var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
            itemRenderer.labelField = "text";
            itemRenderer.iconField = "icon";
            itemRenderer.fontStyles = textFormat;
            itemRenderer.paddingTop = 2;
            itemRenderer.paddingBottom = 2;
            itemRenderer.paddingLeft = 5;
            itemRenderer.paddingRight = 5;
            return itemRenderer;
        };

        playHighlightsPicker.buttonFactory = function():Button {
            var button:Button = new Button();

            button.fontStyles = textFormat;
            button.paddingTop = 2;
            button.paddingBottom = 2;
            button.paddingLeft = 5;
            button.paddingRight = 5;
            button.gap = 5;

            return button;
        };

        playHighlightsPicker.labelFunction = function(item:Object):String {
            return "Playing " + item.text + " highlights";
        };

        playHighlightsPicker.prompt = "Play Highlights";
        playHighlightsPicker.height = header.height - header.padding * 2;

        playHighlightsPicker.addEventListener(Event.CHANGE, playHighlightsPickerChanged);

        playingHighlightsIcon = new Quad(header.height - header.padding * 2,
                                         header.height - header.padding * 2,
                                         0x000000);
        playingHighlightsIcon.alpha = 0;

        addChild(playHighlightsPicker);

        playHighlightsPicker.validate();
        playHighlightsPicker.x = _width - playHighlightsPicker.width;



        hideButton.defaultSelectedIcon = new Image(VidexStarling.assets.getTexture("no_eye"));
        hideButton.defaultSelectedIcon.scale = 0.65;
        hideButton.defaultIcon = new Image(VidexStarling.assets.getTexture("eye"));
        hideButton.defaultIcon.scale = 0.65;

        personalButton.label = "Personal";
        personalButton.defaultSelectedIcon = new Image(VidexStarling.assets.getTexture("viewcount_active"));
        personalButton.defaultSelectedIcon.scale = 0.65;
        personalButton.defaultIcon = new Image(VidexStarling.assets.getTexture("viewcount"));
        personalButton.defaultIcon.scale = 0.65;

        classButton.label = "Class";
        classButton.defaultSelectedIcon = new Image(VidexStarling.assets.getTexture("globalviewcount_active"));
        classButton.defaultSelectedIcon.scale = 0.65;
        classButton.defaultIcon = new Image(VidexStarling.assets.getTexture("globalviewcount"));
        classButton.defaultIcon.scale = 0.65;


        hideButton.addEventListener(Event.CHANGE, hideButtonChange);
        personalButton.addEventListener(Event.CHANGE, personalButtonChange);
        classButton.addEventListener(Event.CHANGE, classButtonChange);

        addChild(hideButton);
        addChild(personalButton);
        addChild(classButton);


        hideButton.validate();
        personalButton.validate();
        classButton.validate();

        personalButton.x = _width/2 - personalButton.width / 2;
        hideButton.x = personalButton.x - hideButton.width;
        classButton.x = personalButton.x + personalButton.width;

//        header.rightItems = new <DisplayObject> [playingHighlightsIcon, playHighlightsPicker];
    }

    private function hideButtonChange(e:Event):void {

//        hideButton.label = hideButton.isSelected ? "Show" : "Hide";

        var hideValue:uint = hideButton.isSelected ? 1 : 0;
        // set HIDE bit to val
        highlightReadMode ^= (-hideValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.HIDE)/Math.log(2));
        highlightsViewModeSet.dispatch(this, highlightReadMode);
        // highlightReadMode ^= (-hideValue ^ highlightReadMode) & (1 << UserDataViewMode.HIDE);

        viewCountRecordReadMode ^= (-hideValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.HIDE)/Math.log(2));
        viewCountRecordViewModeSet.dispatch(this, viewCountRecordReadMode);
//        actionLogSignal.dispatch("PlayerToolbar: Hide highlights button - " + (val ? "HIDE" : "UNHIDE"));
        // hideHighlights.dispatch(val);
    }

    private function personalButtonChange(e:Event):void {
        var personalValue:uint = personalButton.isSelected ? 1 : 0;

        // set PERSONAL bit to personalButton.isSelected
        highlightReadMode ^= (-personalValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.PERSONAL)/Math.log(2));
        highlightsViewModeSet.dispatch(this, highlightReadMode);

        viewCountRecordReadMode ^= (-personalValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.PERSONAL)/Math.log(2));
        viewCountRecordViewModeSet.dispatch(this, viewCountRecordReadMode)

    }

    private function classButtonChange(e:Event):void {

        var classValue:uint = classButton.isSelected ? 1 : 0;

        // set CLASS bit to classButton.isSelected
        highlightReadMode ^= (-classValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.CLASS)/Math.log(2));
        highlightsViewModeSet.dispatch(this, highlightReadMode);

        viewCountRecordReadMode ^= (-classValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.CLASS)/Math.log(2));
        viewCountRecordViewModeSet.dispatch(this, viewCountRecordReadMode)
    }

    private function playHighlightsPickerChanged(e:Event):void {
        if(playHighlightsPicker.selectedItem) {
            playingHighlightsIcon.alpha = 1;
            playingHighlightsIcon.setVertexPosition(1, (header.height - header.padding * 2) / 1.5, (header.height - header.padding * 2) / 2);
            playingHighlightsIcon.setVertexPosition(3, (header.height - header.padding * 2) / 1.5, (header.height - header.padding * 2) / 2);
            var colour:uint = Util.changeSaturation(playHighlightsPicker.selectedItem.colour, 2);
            playingHighlightsIcon.setVertexColor(0, colour);
            playingHighlightsIcon.setVertexColor(1, colour);
            playingHighlightsIcon.setVertexColor(2, colour);
            playingHighlightsIcon.setVertexColor(3, colour);

            startedPlayingHighlights.dispatch(_this, playHighlightsPicker.selectedItem.colour);
        }
    }

    override public function stopPlayingHighlights():void {
        playingHighlightsIcon.alpha = 0;
        playHighlightsPicker.removeEventListener(Event.CHANGE, playHighlightsPickerChanged);
        playHighlightsPicker.selectedIndex = -1;
        playHighlightsPicker.addEventListener(Event.CHANGE, playHighlightsPickerChanged);
    }

    override public function setSize(width:Number, height:Number):void {
        super.setSize(width, height);

//        q.readjustSize(_width, _height);

        trace("setSize _width=" + _width);
        trace(personalButton.isInvalid())

        header.setSize(_width, _height);

        for each(var button:Button in buttons) {
            button.height = header.height - header.padding * 2;
        }


        playHighlightsPicker.x = _width - playHighlightsPicker.width;

        personalButton.x = _width/2 - personalButton.width / 2;
        hideButton.x = personalButton.x - hideButton.width;
        classButton.x = personalButton.x + personalButton.width;

    }
}
}

//////////////////////////////////////////////////////////////////////////
////                                                                    //
////  Author: Matthew Fong                                              //
////          Human Communication Laboratories - http://hct.ece.ubc.ca  //
////          The University of British Columbia                        //
////                                                                    //
//////////////////////////////////////////////////////////////////////////
//
//package ca.ubc.ece.hct.myview.widgets.player {
//
//
//public class PlayerToolbar extends Widget {
//
//    public static const HEIGHT:Number = 38;
//
//    public var hideButton:ImageButton;
//    public var playButton:MulticolourImageButton;
//    public var highlightButton:MulticolourImageButton;
//    public var personalButton:ImageButton;
//    public var instructorButton:ImageButton;
//    public var classButton:ImageButton;
//
//    public var hideHighlights:Signal;
//
//    public var actionLogSignal:Signal;
//
//    public function PlayerToolbar(width_:Number) {
//        _width = width_;
//        _height = HEIGHT;
//
//        hideButton = new ImageButton(30, "uiimage/eye.png", "Toggle Highlights");
//        hideButton.disabledImage = "uiimage/no_eye.png";
//        playButton = new MulticolourImageButton("uiimage/playHighlight", "f7e1a0", "Play Highlights", false);
//        highlightButton = new MulticolourImageButton("uiimage/highlight", "f7e1a0", "Highlight");
//
//        personalButton = new ImageButton(30, "uiimage/viewcount.png", "Toggle Personal Mode");
//        personalButton.disabledImage = "uiimage/viewcount_active.png";
//
//        instructorButton = new ImageButton(30, "uiimage/instructor_view_mode.png", "Toggle Instructor Mode");
//        instructorButton.disabledImage = "uiimage/instructor_view_mode_active.png";
//
//        classButton = new ImageButton(30, "uiimage/globalviewcount.png", "Toggle Class Mode");
//        classButton.disabledImage = "uiimage/globalviewcount_active.png";
//
//        hideHighlights = new Signal(Boolean);		// Signal(hideBoolean);
//        // playHighlights = new Signal(Boolean, uint);	// Signal(playAll, colour);
//        highlighted = new Signal(Boolean, uint);		// Signal(toggle, colour);
//
//        actionLogSignal = new Signal(String);
//
//        drawMe();
//    }
//
//    private function drawMe():void {
//        drawBackground();
//
//        hideButton.toggleAble = true;
//        hideButton.x = 10;
//        hideButton.y = _height/2 - hideButton.height/2;
//        addChild(hideButton);
//        hideButton.toggled.add(hideButtonToggled);
//
//        playButton.setSelectedIndex(1);
//        playButton.toggleAble = true;
//        playButton.x = hideButton.x + hideButton.width + 5;
//        playButton.y = _height/2 - playButton.height/2;
//        addChild(playButton)
//        playButton.toggled.add(playButtonToggled);
//        playButton.selected.add(playHighlightButtonSelected);
//
//        highlightButton.setSelectedIndex(1);
//        highlightButton.toggleAble = true;
//        highlightButton.x = playButton.x + playButton.width + 5;
//        highlightButton.y = _height/2 - highlightButton.height/2;
//        addChild(highlightButton);
//        highlightButton.toggled.add(highlightButtonToggled);
//        highlightButton.selected.add(highlightColourSelected);
//
//        instructorButton.toggleAble = true;
//        instructorButton.x = _width - instructorButton.width - 5;
//        instructorButton.y = _height/2 - instructorButton.height/2;
//        addChild(instructorButton);
//        instructorButton.toggled.add(instructorButtonToggled);
//
//        classButton.toggleAble = true;
//        classButton.x = instructorButton.x - classButton.width - 5;
//        classButton.y = _height/2 - classButton.height/2;
//        addChild(classButton);
//        classButton.toggled.add(classButtonToggled);
//
//        personalButton.toggleAble = true;
//        personalButton.toggle = true;
//        personalButton.x = classButton.x - personalButton.width - 5;
//        personalButton.y = _height/2 - personalButton.height/2;
//        addChild(personalButton);
//        personalButton.toggled.add(personalButtonToggled);
//
//
//
//    }
//
//    override public function setSize(width:Number, height:Number):void {
//        _width = width;
//        _height = height;
//        drawBackground();
//        instructorButton.x = _width - instructorButton.width - 5;
//        classButton.x = instructorButton.x - classButton.width - 5;
//        personalButton.x = classButton.x - personalButton.width - 5;
//    }
//
//    override public function set width(val:Number):void {
//        _width = val;
//        drawBackground();
//        instructorButton.x = _width - instructorButton.width - 5;
//        personalButton.x = instructorButton.x - personalButton.width - 5;
//    }
//
//    public function get selectedHighlightColour():uint {
//        return highlightButton.selectedValue as uint;
//    }
//
//    private function drawBackground():void {
//        var backMatrix:Matrix = new Matrix();
//        backMatrix.createGradientBox(_width, _height, Math.PI/2, 0, 0);
//        graphics.clear();
//        graphics.beginGradientFill(GradientType.LINEAR,
//                [0xe1e1e1, 0xc4c4c4], // colour
//                [1, 1],  // alpha
//                [0, 255], // ratio
//                backMatrix);
//        graphics.drawRect(0, 0, _width, _height);
//        graphics.endFill();
//    }
//
//    private function hideButtonToggled(target:Object, val:Object):void {
//        // trace("Hide Toggle " + val);
//        var hideValue:uint = val ? 1 : 0;
//        // set HIDE bit to val
//        highlightReadMode ^= (-hideValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.HIDE)/Math.log(2));
//        // highlightReadMode ^= (-hideValue ^ highlightReadMode) & (1 << UserDataViewMode.HIDE);
//
//        highlightsViewModeSet.dispatch(this, highlightReadMode);
//        actionLogSignal.dispatch("PlayerToolbar: Hide highlights button - " + (val ? "HIDE" : "UNHIDE"));
//        // hideHighlights.dispatch(val);
//    }
//
//    private function playButtonToggled(target:Object, val:Object):void {
//        // trace("Play Toggle " + val);
//        actionLogSignal.dispatch("PlayerToolbar: Play highlights button - " + (playButton.toggled ? "ON" : "OFF") + ") - #" + (playButton.selectedValue as uint).toString(16));
//
//        if(playButton.toggled)
//            startedPlayingHighlights.dispatch(this, playButton.selectedValue as uint);
//        else
//            stoppedPlayingHighlights.dispatch(this);
//    }
//
//    private function playHighlightButtonSelected(val:Object):void {
//        actionLogSignal.dispatch("PlayerToolbar: Play highlights dropdown selected colour - #" + (playButton.selectedValue as uint).toString(16));
//        startedPlayingHighlights.dispatch(this, (playButton.selectedValue as uint));
//    }
//
//    private function highlightButtonToggled(target:Object, val:Object):void {
//        // trace("Highlight Toggle " + val);
//        actionLogSignal.dispatch("PlayerToolbar: Highlights button - " + (val ? "ON" : "OFF") + " - #" + (highlightButton.selectedValue as uint).toString(16));
//        var newMode:String = val ? HighlightMode.POST_SELECT : HighlightMode.PRE_SELECT;
//        highlightsWriteModeSet.dispatch(this, newMode, highlightButton.selectedValue as uint);
//    }
//
//    private function highlightColourSelected(val:Object):void {
//        // trace("Highlight Colour Select " + val)
//        actionLogSignal.dispatch("PlayerToolbar: Highlights dropdown selected colour - #" + (highlightButton.selectedValue as uint).toString(16));
//        var newMode:String = highlightButton.toggleActive ? HighlightMode.POST_SELECT : HighlightMode.PRE_SELECT;
//        highlightsWriteModeSet.dispatch(this, newMode, highlightButton.selectedValue as uint);
////			highlighted.dispatch(highlightButton.toggleActive, val as uint);
//    }
//
//    private function personalButtonToggled(target:Object, val:Object):void {
//
//        var personalValue:uint = val ? 1 : 0;
//        // set HIDE bit to val
//        highlightReadMode ^= (-personalValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.PERSONAL)/Math.log(2));
//        highlightsViewModeSet.dispatch(this, highlightReadMode)
//        highlightsViewModeSet.dispatch(this, highlightReadMode);
//
//        viewCountRecordReadMode ^= (-personalValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.PERSONAL)/Math.log(2));
//        highlightsViewModeSet.dispatch(this, viewCountRecordReadMode)
//        viewCountRecordViewModeSet.dispatch(this, highlightReadMode)
//
//    }
//
//    private function instructorButtonToggled(target:Object, val:Object):void {
//
//        var instructorValue:uint = val ? 1 : 0;
//        // set HIDE bit to val
//        highlightReadMode ^= (-instructorValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.INSTRUCTOR)/Math.log(2));
//        highlightsViewModeSet.dispatch(this, highlightReadMode)
//
//        viewCountRecordReadMode ^= (-instructorValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.INSTRUCTOR)/Math.log(2));
//        viewCountRecordViewModeSet.dispatch(this, highlightReadMode)
//    }
//
//    private function classButtonToggled(target:Object, val:Object):void {
//
//        var instructorValue:uint = val ? 1 : 0;
//        // set HIDE bit to val
//        highlightReadMode ^= (-instructorValue ^ highlightReadMode) & (1 << Math.log(UserDataViewMode.CLASS)/Math.log(2));
//        highlightsViewModeSet.dispatch(this, highlightReadMode)
//
//        viewCountRecordReadMode ^= (-instructorValue ^ viewCountRecordReadMode) & (1 << Math.log(UserDataViewMode.CLASS)/Math.log(2));
//        viewCountRecordViewModeSet.dispatch(this, highlightReadMode)
//    }
//
//    public function setHighlightButtonToggle(val:Boolean):void {
//        highlightButton.toggle = val;
//    }
//
//    public function setPlayButtonToggle(val:Boolean):void {
//        playButton.toggle = val;
//    }
//
//    override public function stopPlayingHighlights():void {
//        playButton.toggle = false;
//    }
//
//    public function set highlightEnabled(val:Boolean):void {
//        highlightButton.mouseEnabled = val;
//        playButton.mouseEnabled = val;
//    }
//
//    override public function setHighlightsWriteMode(mode:String, colour:uint):void {
//        switch(mode) {
//            case HighlightMode.POST_SELECT:
//                highlightButton.toggle = true;
//                break;
//            case HighlightMode.PRE_SELECT:
//                highlightButton.toggle = false;
//                break;
//            default:
//                trace("PlayerToolbar.setHighlightMode(" + mode + ") - ???");
//                trace(new Error().getStackTrace());
//                break;
//        }
//    }
//    override public function loadVideo(video:VideoMetadata):void { /* do nothing */ }
//    override public function set playheadTime(time:Number):void { /* do nothing */ }
//    override public function receiveSeek(time:Number):void { /* do nothing */ }
//    override public function select(interval:Range):void { /* do nothing */ }
//    override public function deselect():void { /* do nothing */ }
//    override public function highlight(colour:int, interval:Range):void { /* do nothing */ }
//    override public function unhighlight(colour:int, interval:Range):void { /* do nothing */ }
//    override public function updateHighlights():void { /* do nothing */ }
//    override public function setHighlightReadMode(mode:uint):void { /* do nothing */ }
//    override public function setViewCountRecordReadMode(mode:uint):void { /* do nothing */ }
//    override public function setPauseRecordReadMode(mode:uint):void { /* do nothing */ }
//    override public function setPlaybackRateRecordReadMode(mode:uint):void { /* do nothing */ }
//}
//}
