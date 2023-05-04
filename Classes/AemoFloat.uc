class AemoFloat extends GUIMenuOption;

var(Option) float MinValue, MaxValue;
var(Option) noexport editconst AeFloatBox MyFloat;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	MyFloat = AeFloatBox(MyComponent);
	MyFloat.MinValue = MinValue;
	MyFloat.MaxValue = MaxValue;

	MyFloat.CalcMaxLen();
	MyFloat.OnChange = InternalOnChange;
	MyFloat.SetReadOnly(bValueReadOnly);
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

function SetValue(coerce float V)
{
	MyFloat.SetValue(V);
}

function float GetValue()
{
	return float(MyFloat.Value);
}

function Setup(coerce float NewMin, coerce float NewMax)
{
	MinValue = NewMin;
	MaxValue = NewMax;

	MyFloat.MinValue = MinValue;
	MyFloat.MaxValue = MaxValue;

	MyFloat.MyEditBox.bIncludeSign = NewMin < 0;
	MyFloat.CalcMaxLen();

	SetValue(FClamp(GetValue(), MinValue, MaxValue));
}

function SetReadOnly(bool b)
{
	Super.SetReadOnly(b);
	MyFloat.SetReadOnly(b);
}

defaultproperties
{
	MinValue=-9999.000000
	MaxValue=9999.000000
	CaptionWidth=0.750000
	ComponentClassName="fpsGame.AeFloatBox"
	LabelStyleName="MyLabel"
	LabelColor=(R=255,G=255,B=255,A=255)
}