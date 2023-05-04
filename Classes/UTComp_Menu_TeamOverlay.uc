class UTComp_Menu_TeamOverlay extends UTComp_Menu_MainMenu;

var automated moCheckBox ch_Enable, ch_ShowSelf, ch_Icons;

var automated GUI_Slider sl_Horiz, sl_Vert, sl_Size;
var automated GUI_Slider sl_redBG, sl_blueBG, sl_greenBG, sl_alphaBG;
var automated GUI_Slider sl_redName, sl_greenName, sl_blueName, sl_alphaName;
var automated GUI_Slider sl_redLoc, sl_blueLoc, sl_greenLoc, sl_alphaLoc;

var automated GUILabel l_ScreenPos, l_BGColor, l_NameColor, l_LocColor;

var Interaction TeamInteract;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	ch_Enable.Checked(class'UTComp_Overlay'.default.OverlayEnabled);
	ch_ShowSelf.Checked(Settings.bShowSelfInTeamOverlay);
	ch_Icons.Checked(class'UTComp_Overlay'.default.bDrawIcons);

	sl_redBG.SetValue(class'UTComp_Overlay'.default.BGColor.R);
	sl_greenBG.SetValue(class'UTComp_Overlay'.default.BGColor.G);
	sl_blueBG.SetValue(class'UTComp_Overlay'.default.BGColor.B);
	sl_alphaBG.SetValue(class'UTComp_Overlay'.default.BGColor.A);

	sl_redName.SetValue(class'UTComp_Overlay'.default.InfoTextColor.R);
	sl_greenName.SetValue(class'UTComp_Overlay'.default.InfoTextColor.G);
	sl_blueName.SetValue(class'UTComp_Overlay'.default.InfoTextColor.B);
	sl_alphaName.SetValue(class'UTComp_Overlay'.default.InfoTextColor.A);

	sl_redLoc.SetValue(class'UTComp_Overlay'.default.LocTextColor.R);
	sl_greenLoc.SetValue(class'UTComp_Overlay'.default.LocTextColor.G);
	sl_blueLoc.SetValue(class'UTComp_Overlay'.default.LocTextColor.B);
	sl_alphaLoc.SetValue(class'UTComp_Overlay'.default.LocTextColor.A);

	sl_Horiz.SetValue(class'UTComp_Overlay'.default.HorizPosition);
	sl_Vert.SetValue(class'UTComp_Overlay'.default.VertPosition);
	sl_Size.SetValue(class'UTComp_Overlay'.default.TheFontSize);

	FindCurrentOverlay();
	DisableStuff();
}

function DisableStuff()
{
	local UTComp_ServerReplicationInfo RepInfo;

	if (RepInfo == None)
	{
		foreach PlayerOwner().DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	if (ch_Enable.IsChecked() && (RepInfo == None || RepInfo.b_TeamOverlay))
	{
		sl_Horiz.EnableMe();
		sl_Vert.EnableMe();
		sl_Size.EnableMe();

		sl_RedLoc.EnableMe();
		sl_GreenLoc.EnableMe();
		sl_BlueLoc.EnableMe();
		sl_AlphaLoc.EnableMe();

		sl_RedName.EnableMe();
		sl_GreenName.EnableMe();
		sl_BlueName.EnableMe();
		sl_AlphaName.EnableMe();

		sl_RedBG.EnableMe();
		sl_GreenBG.EnableMe();
		sl_BlueBG.EnableMe();
		sl_AlphaBG.EnableMe();

		ch_ShowSelf.EnableMe();
		ch_Icons.EnableMe();
	}
	else
	{
		sl_Horiz.DisableMe();
		sl_Vert.DisableMe();
		sl_Size.DisableMe();

		sl_RedLoc.DisableMe();
		sl_GreenLoc.DisableMe();
		sl_BlueLoc.DisableMe();
		sl_AlphaLoc.DisableMe();

		sl_RedName.DisableMe();
		sl_GreenName.DisableMe();
		sl_BlueName.DisableMe();
		sl_AlphaName.DisableMe();

		sl_RedBG.DisableMe();
		sl_GreenBG.DisableMe();
		sl_BlueBG.DisableMe();
		sl_AlphaBG.DisableMe();

		ch_ShowSelf.DisableMe();
		ch_Icons.DisableMe();
	}
}

function FindCurrentOverlay()
{
	local int i;
	local PlayerController PC;
	local bool bFindInteraction;

	bFindInteraction = false;
	foreach AllObjects(class'PlayerController', PC)
	{
		if (Viewport(PC.Player) != None)
		{
			While (!bFindInteraction)
			{
				TeamInteract = PC.Player.LocalInteractions[i];
				if (TeamInteract == none)
				{
					break;
				}
				else
				{
					if (UTComp_Overlay(TeamInteract) != None)
						bFindInteraction = true;
				}
				i++;
			}

			if (!bFindInteraction)
				TeamInteract = None;
		}
	}
}

function UpdateOverlay()
{
	if (TeamInteract == None)
	{
		FindCurrentOverlay();
		return;
	}

	UTComp_Overlay(TeamInteract).VertPosition = class'UTComp_Overlay'.default.VertPosition;
	UTComp_Overlay(TeamInteract).Horizposition = class'UTComp_Overlay'.default.HorizPosition;
	UTComp_Overlay(TeamInteract).BGColor = class'UTComp_Overlay'.default.BGColor;
	UTComp_Overlay(TeamInteract).InfoTextColor = class'UTComp_Overlay'.default.InfoTextColor;
	UTComp_Overlay(TeamInteract).LocTextColor = class'UTComp_Overlay'.default.LocTextColor;
	UTComp_Overlay(TeamInteract).OverlayEnabled = class'UTComp_Overlay'.default.OverlayEnabled;
	UTComp_Overlay(TeamInteract).bDrawIcons = class'UTComp_Overlay'.default.bDrawIcons;
	UTComp_Overlay(TeamInteract).TheFontSize = class'UTComp_Overlay'.default.TheFontSize;
}

function InternalOnChange(GUIComponent C)
{
	switch(C)
	{
		case ch_Enable:
			class'UTComp_Overlay'.default.OverlayEnabled = ch_Enable.IsChecked();
			break;

		case ch_ShowSelf:
			BS_xPlayer(PlayerOwner()).SetShowSelf(ch_ShowSelf.IsChecked());
			break;

		case ch_Icons:
			class'UTComp_Overlay'.default.bDrawIcons = ch_Icons.IsChecked();
			break;

		case sl_redBG:
			class'UTComp_Overlay'.default.BGColor.R = sl_redBG.Value;
			break;

		case sl_greenBG:
			class'UTComp_Overlay'.default.BGColor.G = sl_GreenBG.Value;
			break;

		case sl_blueBG:
			class'UTComp_Overlay'.default.BGColor.B = sl_BlueBG.Value;
			break;
		
		case sl_alphaBG:
			class'UTComp_Overlay'.default.BGColor.A = sl_AlphaBG.Value;
			break;

		case sl_redName:
			class'UTComp_Overlay'.default.InfoTextColor.R = sl_RedName.Value;
			break;

		case sl_greenName:
			class'UTComp_Overlay'.default.InfoTextColor.G = sl_GreenName.Value;
			break;

		case sl_blueName:
			class'UTComp_Overlay'.default.InfoTextColor.B = sl_BlueName.Value;
			break;
		
		case sl_alphaName:
			class'UTComp_Overlay'.default.InfoTextColor.A = sl_AlphaName.Value;
			break;

		case sl_redLoc:
			class'UTComp_Overlay'.default.LocTextColor.R = sl_RedLoc.Value;
			break;

		case sl_greenLoc:
			class'UTComp_Overlay'.default.LocTextColor.G = sl_GreenLoc.Value;
			break;

		case sl_blueLoc:
			class'UTComp_Overlay'.default.LocTextColor.B = sl_BlueLoc.Value;
			break;
		
		case sl_alphaLoc:
			class'UTComp_Overlay'.default.LocTextColor.A = sl_AlphaLoc.Value;
			break;

		case sl_Horiz:
			class'UTComp_Overlay'.default.HorizPosition = sl_Horiz.Value;
			break;

		case sl_Vert:
			class'UTComp_Overlay'.default.VertPosition = sl_Vert.Value;
			break;

		case sl_Size:
			class'UTComp_Overlay'.default.TheFontSize = sl_Size.Value;
			break;
	}

	class'UTComp_Overlay'.static.StaticSaveConfig();
	SaveAll();
	UpdateOverlay();
	DisableStuff();
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
	if (Key == 0x1B)
		return false;

	return true;
}

defaultproperties
{
	Begin Object Class=moCheckBox Name=CheckEnable
		Caption="Team Overlay"
		OnCreateComponent=CheckEnable.InternalOnCreateComponent
		WinTop=0.125000
		WinLeft=0.450000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
	End Object
	ch_Enable=moCheckBox'UTComp_Menu_TeamOverlay.CheckEnable'

	Begin Object Class=moCheckBox Name=CheckShowSelf
		Caption="Show Self"
		OnCreateComponent=CheckShowSelf.InternalOnCreateComponent
		WinTop=0.200000
		WinLeft=0.450000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
	End Object
	ch_ShowSelf=moCheckBox'UTComp_Menu_TeamOverlay.CheckShowSelf'

	Begin Object Class=moCheckBox Name=CheckIcons
		Caption="Show Icons"
		OnCreateComponent=CheckIcons.InternalOnCreateComponent
		WinTop=0.275000
		WinLeft=0.450000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
	End Object
	ch_Icons=moCheckBox'UTComp_Menu_TeamOverlay.CheckIcons'

	Begin Object Class=GUI_Slider Name=SliderHoriz
		MaxValue=0.750000
		StyleName="sl_knob_w"
		WinTop=0.425000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=SliderHoriz.InternalOnClick
		OnMousePressed=SliderHoriz.InternalOnMousePressed
		OnMouseRelease=SliderHoriz.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=SliderHoriz.InternalOnKeyEvent
		OnCapturedMouseMove=SliderHoriz.InternalCapturedMouseMove
	End Object
	sl_Horiz=GUI_Slider'UTComp_Menu_TeamOverlay.SliderHoriz'

	Begin Object Class=GUI_Slider Name=SliderVert
		MaxValue=1.000000
		StyleName="sl_knob_w"
		WinTop=0.475000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=SliderVert.InternalOnClick
		OnMousePressed=SliderVert.InternalOnMousePressed
		OnMouseRelease=SliderVert.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=SliderVert.InternalOnKeyEvent
		OnCapturedMouseMove=SliderVert.InternalCapturedMouseMove
	End Object
	sl_Vert=GUI_Slider'UTComp_Menu_TeamOverlay.SliderVert'

	Begin Object Class=GUI_Slider Name=SliderSize
		MinValue=-8.000000
		MaxValue=0.000000
		bIntSlider=True
		StyleName="sl_knob_w"
		WinTop=0.525000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=SliderSize.InternalOnClick
		OnMousePressed=SliderSize.InternalOnMousePressed
		OnMouseRelease=SliderSize.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=SliderSize.InternalOnKeyEvent
		OnCapturedMouseMove=SliderSize.InternalCapturedMouseMove
	End Object
	sl_Size=GUI_Slider'UTComp_Menu_TeamOverlay.SliderSize'

	Begin Object Class=GUI_Slider Name=RedNameSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_r"
		WinTop=0.425000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=RedNameSlider.InternalOnClick
		OnMousePressed=RedNameSlider.InternalOnMousePressed
		OnMouseRelease=RedNameSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=RedNameSlider.InternalOnKeyEvent
		OnCapturedMouseMove=RedNameSlider.InternalCapturedMouseMove
	End Object
	sl_redName=GUI_Slider'UTComp_Menu_TeamOverlay.RedNameSlider'

	Begin Object Class=GUI_Slider Name=GreenNameSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_g"
		WinTop=0.475000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=GreenNameSlider.InternalOnClick
		OnMousePressed=GreenNameSlider.InternalOnMousePressed
		OnMouseRelease=GreenNameSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=GreenNameSlider.InternalOnKeyEvent
		OnCapturedMouseMove=GreenNameSlider.InternalCapturedMouseMove
	End Object
	sl_greenName=GUI_Slider'UTComp_Menu_TeamOverlay.GreenNameSlider'

	Begin Object Class=GUI_Slider Name=BlueNameSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_b"
		WinTop=0.525000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=BlueNameSlider.InternalOnClick
		OnMousePressed=BlueNameSlider.InternalOnMousePressed
		OnMouseRelease=BlueNameSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=BlueNameSlider.InternalOnKeyEvent
		OnCapturedMouseMove=BlueNameSlider.InternalCapturedMouseMove
	End Object
	sl_blueName=GUI_Slider'UTComp_Menu_TeamOverlay.BlueNameSlider'

	Begin Object Class=GUI_Slider Name=AlphaNameSlider
		MaxValue=255.000000
		bIntSlider=true
		StyleName="sl_knob_w"
		WinTop=0.575000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=AlphaNameSlider.InternalOnClick
		OnMousePressed=AlphaNameSlider.InternalOnMousePressed
		OnMouseRelease=AlphaNameSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=AlphaNameSlider.InternalOnKeyEvent
		OnCapturedMouseMove=AlphaNameSlider.InternalCapturedMouseMove
	End Object
	sl_alphaName=GUI_Slider'UTComp_Menu_TeamOverlay.AlphaNameSlider'

	Begin Object Class=GUI_Slider Name=RedBGSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_r"
		WinTop=0.725000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=RedBGSlider.InternalOnClick
		OnMousePressed=RedBGSlider.InternalOnMousePressed
		OnMouseRelease=RedBGSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=RedBGSlider.InternalOnKeyEvent
		OnCapturedMouseMove=RedBGSlider.InternalCapturedMouseMove
	End Object
	sl_redBG=GUI_Slider'UTComp_Menu_TeamOverlay.RedBGSlider'

	Begin Object Class=GUI_Slider Name=GreenBGSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_g"
		WinTop=0.775000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=GreenBGSlider.InternalOnClick
		OnMousePressed=GreenBGSlider.InternalOnMousePressed
		OnMouseRelease=GreenBGSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=GreenBGSlider.InternalOnKeyEvent
		OnCapturedMouseMove=GreenBGSlider.InternalCapturedMouseMove
	End Object
	sl_greenBG=GUI_Slider'UTComp_Menu_TeamOverlay.GreenBGSlider'

	Begin Object Class=GUI_Slider Name=BlueBGSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_b"
		WinTop=0.825000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=BlueBGSlider.InternalOnClick
		OnMousePressed=BlueBGSlider.InternalOnMousePressed
		OnMouseRelease=BlueBGSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=BlueBGSlider.InternalOnKeyEvent
		OnCapturedMouseMove=BlueBGSlider.InternalCapturedMouseMove
	End Object
	sl_blueBG=GUI_Slider'UTComp_Menu_TeamOverlay.BlueBGSlider'

	Begin Object Class=GUI_Slider Name=AlphaBGSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_w"
		WinTop=0.875000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=AlphaBGSlider.InternalOnClick
		OnMousePressed=AlphaBGSlider.InternalOnMousePressed
		OnMouseRelease=AlphaBGSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=AlphaBGSlider.InternalOnKeyEvent
		OnCapturedMouseMove=AlphaBGSlider.InternalCapturedMouseMove
	End Object
	sl_alphaBG=GUI_Slider'UTComp_Menu_TeamOverlay.AlphaBGSlider'

	Begin Object Class=GUI_Slider Name=RedLocSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_r"
		WinTop=0.725000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=RedLocSlider.InternalOnClick
		OnMousePressed=RedLocSlider.InternalOnMousePressed
		OnMouseRelease=RedLocSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=RedLocSlider.InternalOnKeyEvent
		OnCapturedMouseMove=RedLocSlider.InternalCapturedMouseMove
	End Object
	sl_redLoc=GUI_Slider'UTComp_Menu_TeamOverlay.RedLocSlider'

	Begin Object Class=GUI_Slider Name=GreenLocSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_g"
		WinTop=0.775000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=GreenLocSlider.InternalOnClick
		OnMousePressed=GreenLocSlider.InternalOnMousePressed
		OnMouseRelease=GreenLocSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=GreenLocSlider.InternalOnKeyEvent
		OnCapturedMouseMove=GreenLocSlider.InternalCapturedMouseMove
	End Object
	sl_greenLoc=GUI_Slider'UTComp_Menu_TeamOverlay.GreenLocSlider'

	Begin Object Class=GUI_Slider Name=BlueLocSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_b"
		WinTop=0.825000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=BlueLocSlider.InternalOnClick
		OnMousePressed=BlueLocSlider.InternalOnMousePressed
		OnMouseRelease=BlueLocSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=BlueLocSlider.InternalOnKeyEvent
		OnCapturedMouseMove=BlueLocSlider.InternalCapturedMouseMove
	End Object
	sl_blueLoc=GUI_Slider'UTComp_Menu_TeamOverlay.BlueLocSlider'

	Begin Object Class=GUI_Slider Name=AlphaLocSlider
		MaxValue=255.000000
		bIntSlider=true
		StyleName="sl_knob_w"
		WinTop=0.875000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=AlphaLocSlider.InternalOnClick
		OnMousePressed=AlphaLocSlider.InternalOnMousePressed
		OnMouseRelease=AlphaLocSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_TeamOverlay.InternalOnChange
		OnKeyEvent=AlphaLocSlider.InternalOnKeyEvent
		OnCapturedMouseMove=AlphaLocSlider.InternalCapturedMouseMove
	End Object
	sl_alphaLoc=GUI_Slider'UTComp_Menu_TeamOverlay.AlphaLocSlider'

	Begin Object Class=GUILabel Name=PosLabel
		Caption="Position (X Y S)"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.350000
		WinLeft=0.200000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ScreenPos=GUILabel'UTComp_Menu_TeamOverlay.PosLabel'

	Begin Object Class=GUILabel Name=BGColorLabel
		Caption="Background (R G B A)"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.650000
		WinLeft=0.200000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_BGColor=GUILabel'UTComp_Menu_TeamOverlay.BGColorLabel'

	Begin Object Class=GUILabel Name=NameColorLabel
		Caption="Name (R G B A)"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.350000
		WinLeft=0.600000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_NameColor=GUILabel'UTComp_Menu_TeamOverlay.NameColorLabel'

	Begin Object Class=GUILabel Name=LocColorLabel
		Caption="Location (R G B A)"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.650000
		WinLeft=0.600000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_LocColor=GUILabel'UTComp_Menu_TeamOverlay.LocColorLabel'
}