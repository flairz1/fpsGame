class AeIntBox extends GUIMultiComponent;

var automated GUIEditBox MyBox;

var() string Value;
var() bool bReadOnly, bLeftJustified;
var() int MinValue, MaxValue;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	if (MinValue < 0)
		MyBox.bIncludeSign = true;

	Super.InitComponent(MyController, MyOwner);

	MyBox.OnChange = EditOnChange;
	MyBox.SetText(Value);
	MyBox.OnKeyEvent = MyBox.InternalOnKeyEvent;
	MyBox.OnDeActivate = CheckValue;

	CalcMaxLen();

	MyBox.INIOption  = INIOption;
	MyBox.INIDefault = INIDefault;

	SetReadOnly(bReadOnly);
	SetHint(Hint);
}

function CalcMaxLen()
{
	local int x, DigitCount;

	DigitCount = 1;
	x = 10;
	while(x <= MaxValue)
	{
		DigitCount++;
		x *= 10;
	}

	MyBox.MaxWidth = DigitCount;
}

function SetValue(int V)
{
	if (V < MinValue)
		V = MinValue;

	if (V > MaxValue)
		V = MaxValue;

	MyBox.SetText(string(Clamp(V, MinValue, MaxValue)));
}

function EditOnChange(GUIComponent Sender)
{
	Value = string(Clamp(int(MyBox.TextStr), MinValue, MaxValue));
	OnChange(self);
}

function SetReadOnly(bool b)
{
	bReadOnly = b;
	MyBox.bReadOnly = b;
}

function CheckValue()
{
	SetValue(int(Value));
}

function SetFriendlyLabel(GUILabel NewLabel)
{
	Super.SetFriendlyLabel(NewLabel);

	if (MyBox != none)
		MyBox.SetFriendlyLabel(NewLabel);
}

function ValidateValue()
{
	local int i;

	i = int(MyBox.TextStr);
	MyBox.TextStr = string(Clamp(i, MinValue, MaxValue));
	MyBox.bHasFocus = false;
}

defaultproperties
{
	Begin Object Class=GUIEditBox Name=cMyBox
		bIntOnly=true
		//StyleName="AeEditBox"
		WinHeight=1.000000
		OnActivate=cMyBox.InternalActivate
		OnDeActivate=cMyBox.InternalDeactivate
		OnKeyType=cMyBox.InternalOnKeyType
		OnKeyEvent=cMyBox.InternalOnKeyEvent
		bBoundToParent=true
		bScaleToParent=true
	End Object
	MyBox=GUIEditBox'fpsGame.AeIntBox.cMyBox'

	Value="0"
	MinValue=0
	MaxValue=99999
	PropagateVisibility=true
	WinHeight=0.060000
	bAcceptsInput=true

	OnDeActivate=AeIntBox.ValidateValue
}