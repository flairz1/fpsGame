class AemoInt extends GUIMenuOption;

var(Option) int MinValue, MaxValue;
var(Option) editconst noexport AeIntBox MyInt;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	MyInt = AeIntBox(MyComponent);
	MyInt.MinValue = MinValue;
	MyInt.MaxValue = MaxValue;

	MyInt.CalcMaxLen();
	MyInt.OnChange = InternalOnChange;
	MyInt.SetReadOnly(bValueReadOnly);
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

function SetValue(coerce int V)
{
	MyInt.SetValue(V);
}

function int GetValue()
{
	return int(MyInt.Value);
}

function Setup(coerce int NewMin, coerce int NewMax)
{
	MinValue = NewMin;
	MaxValue = NewMax;

	MyInt.MinValue = MinValue;
	MyInt.MaxValue = MaxValue;

	MyInt.MyBox.bIncludeSign = NewMin < 0;
	MyInt.CalcMaxLen();

	SetValue(Clamp(GetValue(), NewMin, NewMax));
}

function SetReadOnly(bool b)
{
	Super.SetReadOnly(b);
	MyInt.SetReadOnly(b);
}

defaultproperties
{
	MinValue=0
	MaxValue=999
	CaptionWidth=0.750000
	ComponentClassName="fpsGame.AeIntBox"
	LabelStyleName="MyLabel"
	LabelColor=(R=255,G=255,B=255,A=255)
}