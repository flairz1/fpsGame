class UTComp_Menu_RadarInv extends UTComp_Menu_MainMenu;

var automated GUIButton b_DefAll;
var automated moCheckBox ch_Cardinal;
var automated AemoFloat s_RadarX, s_RadarY, s_RadarS;
var automated AemoInt c_RadarR, c_RadarG, c_RadarB, c_RadarA;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

//	Radar Cardinal Points
	ch_Cardinal.Checked(HudS.bDrawCardinalPoints);

//	Radar Location and Scale
	s_RadarX.Setup(0.000000, 100.000000);
	s_RadarX.SetValue(HudS.RadarPosX);
	s_RadarY.Setup(0.000000, 90.000000);
	s_RadarY.SetValue(HudS.RadarPosY);
	s_RadarS.Setup(0.000000, 500.000000);
	s_RadarS.SetValue(HudS.RadarScale);

//	Radar RGBA
	c_RadarR.Setup(0, 255);
	c_RadarR.SetValue(HudS.RadarColour.R);

	c_RadarG.Setup(0, 255);
	c_RadarG.SetValue(HudS.RadarColour.G);

	c_RadarB.Setup(0, 255);
	c_RadarB.SetValue(HudS.RadarColour.B);

	c_RadarA.Setup(0, 255);
	c_RadarA.SetValue(HudS.RadarColour.A);
}

function bool DefaultAll(GUIComponent Sender)
{
	ch_Cardinal.SetComponentValue(HudS.default.bDrawCardinalPoints);

	s_RadarX.SetComponentValue(HudS.default.RadarPosX);
	s_RadarY.SetComponentValue(HudS.default.RadarPosY);
	s_RadarS.SetComponentValue(HudS.default.RadarScale);

	c_RadarR.SetComponentValue(HudS.default.RadarColour.R);
	c_RadarG.SetComponentValue(HudS.default.RadarColour.G);
	c_RadarB.SetComponentValue(HudS.default.RadarColour.B);
	c_RadarA.SetComponentValue(HudS.default.RadarColour.A);

	SaveAll();
	class'UTComp_xPawn'.static.StaticSaveConfig();

	return true;
}

function InternalOnChange(GUIComponent C)
{
	switch (C)
	{
		case ch_Cardinal:
			HudS.bDrawCardinalPoints = ch_Cardinal.IsChecked();
			break;

		case s_RadarX:
			HudS.RadarPosX = s_RadarX.GetValue();
			break;

		case s_RadarY:
			HudS.RadarPosY = s_RadarY.GetValue();
			break;

		case s_RadarS:
			HudS.RadarScale = s_RadarS.GetValue();
			break;

		case c_RadarR:
			HudS.RadarColour.R = c_RadarR.GetValue();
			break;

		case c_RadarG:
			HudS.RadarColour.G = c_RadarG.GetValue();
			break;

		case c_RadarB:
			HudS.RadarColour.B = c_RadarB.GetValue();
			break;

		case c_RadarA:
			HudS.RadarColour.A = c_RadarA.GetValue();
			break;
	}

	SaveAll();
	class'UTComp_xPawn'.static.StaticSaveConfig();
}

defaultproperties
{
	Begin Object Class=moCheckBox Name=CardinalPoints
		Caption="Show Cardinal Points"
		OnCreateComponent=CardinalPoints.InternalOnCreateComponent
		WinTop=0.200000
		WinLeft=0.450000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_RadarInv.InternalOnChange
	End Object
	ch_Cardinal=moCheckBox'UTComp_Menu_RadarInv.CardinalPoints'

	Begin Object Class=AemoFloat Name=RadarX
		Caption="Radar Position X"
		WinTop=0.350000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_RadarInv.InternalOnChange
	End Object
	s_RadarX=AemoFloat'UTComp_Menu_RadarInv.RadarX'

	Begin Object Class=AemoFloat Name=RadarY
		Caption="Radar Position Y"
		WinTop=0.450000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_RadarInv.InternalOnChange
	End Object
	s_RadarY=AemoFloat'UTComp_Menu_RadarInv.RadarY'

	Begin Object Class=AemoFloat Name=RadarS
		Caption="Radar Scale"
		WinTop=0.550000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_RadarInv.InternalOnChange
	End Object
	s_RadarS=AemoFloat'UTComp_Menu_RadarInv.RadarS'

	Begin Object Class=AemoInt Name=RadarRed
		Caption="Red"
		WinTop=0.350000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_RadarInv.InternalOnChange
	End Object
	c_RadarR=AemoInt'UTComp_Menu_RadarInv.RadarRed'

	Begin Object Class=AemoInt Name=RadarGreen
		Caption="Green"
		WinTop=0.450000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_RadarInv.InternalOnChange
	End Object
	c_RadarG=AemoInt'UTComp_Menu_RadarInv.RadarGreen'

	Begin Object Class=AemoInt Name=RadarBlue
		Caption="Blue"
		WinTop=0.550000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_RadarInv.InternalOnChange
	End Object
	c_RadarB=AemoInt'UTComp_Menu_RadarInv.RadarBlue'

	Begin Object Class=AemoInt Name=RadarAlpha
		Caption="Alpha"
		WinTop=0.650000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_RadarInv.InternalOnChange
	End Object
	c_RadarA=AemoInt'UTComp_Menu_RadarInv.RadarAlpha'

	Begin Object Class=GUIButton Name=DefaultButton
		Caption="Default All"
		Hint="Reset to Defaults"
		WinTop=0.800000
		WinLeft=0.500000
		WinWidth=0.200000
		WinHeight=0.080000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_RadarInv.DefaultAll
	End Object
	b_DefAll=GUIButton'UTComp_Menu_RadarInv.DefaultButton'
}