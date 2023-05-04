class GUI_moSlider extends GUIMenuOption;

var(Option) float MaxValue, MinValue, Value;
var(Option) bool bIntSlider;
var(Option) string SliderStyleName, SliderCaptionStyleName, SliderBarStyleName;
var(Option) noexport editconst GUISlider MySlider;

function InitComponent(GUIController InController, GUIComponent InOwner)
{
	Super.InitComponent(InController, InOwner);

	SetReadOnly(bValueReadOnly);
}

function InternalOnCreateComponent(GUIComponent NewComp, GUIComponent Sender)
{
	if (GUISlider(NewComp) != none)
	{
		MySlider = GUISlider(NewComp);
		MySlider.MinValue = MinValue;
		MySlider.MaxValue = MaxValue;
		MySlider.bIntSlider = bIntSlider;
		MySlider.StyleName = SliderStyleName;
		MySlider.CaptionStyleName = SliderCaptionStyleName;
		MySlider.BarStyleName = SliderBarStyleName;
	}

	Super.InternalOnCreateComponent(NewComp, Sender);
}

function SetComponentValue(coerce string NewValue, optional bool bNoChange)
{
	if (bNoChange)
		bIgnoreChange = true;

	SetValue(NewValue);

	bIgnoreChange = false;
}

function string GetComponentValue()
{
	return string(GetValue());
}

function Adjust(float Amount)
{
	if (MySlider != none)
		MySlider.Adjust(Amount);
}

function SetValue(coerce float NewV)
{
	if (MySlider != none)
		Value = MySlider.SetValue(NewV);
}

function float GetValue()
{
	if (MySlider != none)
		return MySlider.Value;

	return 0.0;
}

function Setup(coerce float MinV, coerce float MaxV, optional bool bInt)
{
	MinValue = MinV;
	MaxValue = MaxV;
	bIntSlider = bInt;

	if (MySlider != none)
	{
		MySlider.MinValue = MinValue;
		MySlider.MaxValue = MaxValue;
		MySlider.bIntSlider = bIntSlider;
	}
}

function InternalOnChange(GUIComponent Sender)
{
	Value = MySlider.Value;
	Super.InternalOnChange(Sender);
}

function SetReadOnly(bool b)
{
	Super.SetReadOnly(b);
	MySlider.SetReadOnly(b);
}

defaultproperties
{
     SliderStyleName="SliderKnob"
     SliderCaptionStyleName="SliderCaption"
     SliderBarStyleName="SliderBar"
     ComponentClassName="XInterface.GUISlider"
}