class AeFloatBox extends GUIMultiComponent;

var automated GUIEditBox MyEditBox;

var() string Value;
var() bool bReadOnly, bLeftJustified;
var() float MinValue, MaxValue;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	if (MinValue < 0)
		MyEditBox.bIncludeSign = true;

	Super.InitComponent(MyController, MyOwner);

	MyEditBox.OnChange = EditOnChange;
	MyEditBox.SetText(Value);
	MyEditBox.OnKeyEvent = MyEditBox.InternalOnKeyEvent;
	MyEditBox.OnDeActivate = CheckValue;

	MyEditBox.INIOption  = INIOption;
	MyEditBox.INIDefault = INIDefault;

	CalcMaxLen();

	SetReadOnly(bReadOnly);
	SetHint(Hint);
}

function CalcMaxLen()
{
	local int x, DigitCount;

	DigitCount = 1;
	x = 10;
	while(x < MaxValue)
	{
		DigitCount++;
		x *= 10;
	}

	MyEditBox.MaxWidth = DigitCount + 4;
}

function SetValue(float V)
{
	MyEditBox.SetText(string(FClamp(V, MinValue, MaxValue)));
}

function EditOnChange(GUIComponent Sender)
{
	Value = string(FClamp(float(MyEditBox.TextStr), MinValue, MaxValue));
	OnChange(self);
}

function SetReadOnly(bool b)
{
	bReadOnly = b;
	MyEditBox.bReadOnly = b;
}

function CheckValue()
{
	SetValue(float(Value));
}

function SetFriendlyLabel(GUILabel NewLabel)
{
	Super.SetFriendlyLabel(NewLabel);

	if (MyEditBox != none)
		MyEditBox.SetFriendlyLabel(NewLabel);
}

function ValidateValue()
{
	local float f;

	f = float(MyEditBox.TextStr);
	MyEditBox.TextStr = string(FClamp(f, MinValue, MaxValue));
	MyEditBox.bHasFocus = false;
}

defaultproperties
{
	Begin Object Class=GUIEditBox Name=cMyEditBox
		bFloatOnly=true
		//StyleName="AeEditBox"
		WinHeight=1.000000
		OnActivate=cMyEditBox.InternalActivate
		OnDeActivate=cMyEditBox.InternalDeactivate
		OnKeyType=cMyEditBox.InternalOnKeyType
		OnKeyEvent=cMyEditBox.InternalOnKeyEvent
		bBoundToParent=true
		bScaleToParent=true
	End Object
	MyEditBox=GUIEditBox'fpsGame.AeFloatBox.cMyEditBox'

	Value="0.000000"
	MinValue=-9999.000000
	MaxValue=9999.000000
	PropagateVisibility=true
	WinHeight=0.060000
	bAcceptsInput=true

	OnDeActivate=AeFloatBox.ValidateValue
}