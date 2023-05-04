class GUI_Slider extends GUISlider;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	MyController.RegisterStyle(class'STY_SLBarWhite', false);

	MyController.RegisterStyle(class'STY_SLKnobWhite', false);
	MyController.RegisterStyle(class'STY_SLKnobRed', false);
	MyController.RegisterStyle(class'STY_SLKnobGreen', false);
	MyController.RegisterStyle(class'STY_SLKnobBlue', false);

	Super.InitComponent(MyController, MyOwner);
}

defaultproperties
{
	FillImage=Texture'mats.sl_fill'
	BarStyleName="sl_bar_w"
	Begin Object Class=GUIToolTip Name=GUISliderToolTip
	End Object
	ToolTip=GUIToolTip'GUI_Slider.GUISliderToolTip'

	OnClick=GUI_Slider.InternalOnClick
	OnMousePressed=GUI_Slider.InternalOnMousePressed
	OnMouseRelease=GUI_Slider.InternalOnMouseRelease
	OnKeyEvent=GUI_Slider.InternalOnKeyEvent
	OnCapturedMouseMove=GUI_Slider.InternalCapturedMouseMove
}