class UTComp_Menu_MainMenu extends PopupPageBase;

var automated array<GUIButton> UTCompMenuButtons;
var automated GUIImage i_UTCompLogo;

var UTComp_Settings Settings;
var UTComp_HudSettings HudS;

simulated function SaveAll()
{
	Log("Saving settings (from UTComp_Menu_MainMenu)");
	BS_xPlayer(PlayerOwner()).SaveSettings();
	class'fpsHud'.static.StaticSaveConfig();
}

function InitComponent(GUIController MyController, GUIComponent MyComponent)
{
	MyController.RegisterStyle(class'STY_BTButtonStyle', true);
	MyController.RegisterStyle(class'STY_BTSliderArrow', true);

	Super.InitComponent(MyController, MyComponent);

	Settings = BS_xPlayer(PlayerOwner()).Settings;
	HudS = BS_xPlayer(PlayerOwner()).HudS;
}

function bool InternalOnClick(GUIComponent C)
{
	if (C == UTCompMenuButtons[0])
		PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_OpenedMenu'));
	else if (C == UTCompMenuButtons[1])
		PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Voting'));
	else if (C == UTCompMenuButtons[2])
		PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_BrightSkins'));
	else if (C == UTCompMenuButtons[3])
		PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_ColorNames'));
	else if (C == UTCompMenuButtons[4])
		PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Hitsounds'));
	else if (C == UTCompMenuButtons[5])
		PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_TeamOverlay'));
	else if (C == UTCompMenuButtons[6])
		PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_RadarInv'));
	else if (C == UTCompMenuButtons[7])
		PlayerOwner().ClientReplaceMenu(string(class'UTComp_Menu_Miscellaneous'));

	return false;
}

function OnClose(optional bool bCancelled)
{
	if (BS_xPlayer(PlayerOwner()) != none)
	{
		BS_xPlayer(PlayerOwner()).ReSkinAll();
		BS_xPlayer(PlayerOwner()).InitializeScoreboard();
		BS_xPlayer(PlayerOwner()).MatchHudColor();
	}

	Super.OnClose(bCancelled);
}

defaultproperties
{
	bRequire640x480=true
	bPersistent=true
	bAllowedAsLast=true
	Begin Object Class=FloatingImage Name=FloatingFrameBackground
		Image=Texture'fpsGame.mats.bg_main'	//mats.bg_test
		DropShadow=None
		ImageColor=(A=200)
		ImageStyle=ISTY_Scaled	//Stretched
		ImageRenderStyle=MSTY_Normal
		WinTop=0.000000		//0.10
		WinLeft=0.000000		//0.075
		WinWidth=1.000000		//0.85
		WinHeight=1.000000	//0.75
		RenderWeight=0.000001	//0.01
		bBoundToParent=true
		bScaleToParent=true
	End Object
	i_FrameBG=FloatingImage'UTComp_Menu_MainMenu.FloatingFrameBackground'

	Begin Object class=GUIImage name=UTCompLogo
		Image=Texture'fpsGame.mats.bg_logo'
		ImageAlign=IMGA_Center
		ImageStyle=ISTY_Justified
		ImageRenderStyle=MSTY_Alpha
		WinTop=0.000000
		WinLeft=-0.062500
		WinWidth=0.325000
		WinHeight=0.175000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	i_UTCompLogo=GUIImage'UTComp_Menu_MainMenu.UTCompLogo'

	Begin Object class=GUIButton name=HomeyButton
		Caption="Home"
		StyleName="BTButtonStyle"
		WinTop=0.200000
		WinLeft=0.010000
		WinWidth=0.180000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=InternalOnClick
	End Object
	UTCompMenuButtons(0)=GUIButton'UTComp_Menu_MainMenu.HomeyButton'

	Begin Object class=GUIButton name=VotingButton
		Caption="Voting"
		StyleName="BTButtonStyle"
		WinTop=0.300000
		WinLeft=0.010000
		WinWidth=0.180000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=InternalOnClick
	End Object
	UTCompMenuButtons(1)=GUIButton'UTComp_Menu_MainMenu.VotingButton'

	Begin Object class=GUIButton name=SkinModelButton
		Caption="Skins/Models"
		StyleName="BTButtonStyle"
		WinTop=0.400000
		WinLeft=0.010000
		WinWidth=0.180000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=InternalOnClick
	End Object
	UTCompMenuButtons(2)=GUIButton'UTComp_Menu_MainMenu.SkinModelButton'

	Begin Object class=GUIButton name=ColoredNameButton
		Caption="Colored Names"
		StyleName="BTButtonStyle"
		WinTop=0.500000
		WinLeft=0.010000
		WinWidth=0.180000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=InternalOnClick
	End Object
	UTCompMenuButtons(3)=GUIButton'UTComp_Menu_MainMenu.ColoredNameButton'

	Begin Object class=GUIButton name=HitsoundButton
		Caption="Hitsounds"
		StyleName="BTButtonStyle"
		WinTop=0.600000
		WinLeft=0.010000
		WinWidth=0.180000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=InternalOnClick
	End Object
	UTCompMenuButtons(4)=GUIButton'UTComp_Menu_MainMenu.HitsoundButton'

	Begin Object class=GUIButton name=OverlayButton
		Caption="Team Overlay"
		StyleName="BTButtonStyle"
		WinTop=0.700000
		WinLeft=0.010000
		WinWidth=0.180000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=InternalOnClick
	End Object
	UTCompMenuButtons(5)=GUIButton'UTComp_Menu_MainMenu.OverlayButton'

	Begin Object class=GUIButton name=AdrenComboButton
		Caption="Radar Inv"
		StyleName="BTButtonStyle"
		WinTop=0.800000
		WinLeft=0.010000
		WinWidth=0.180000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=InternalOnClick
	End Object
	UTCompMenuButtons(6)=GUIButton'UTComp_Menu_MainMenu.AdrenComboButton'

	Begin Object class=GUIButton name=MiscButton
		Caption="Misc"
		StyleName="BTButtonStyle"
		WinTop=0.900000
		WinLeft=0.010000
		WinWidth=0.180000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=InternalOnClick
	End Object
	UTCompMenuButtons(7)=GUIButton'UTComp_Menu_MainMenu.MiscButton'

	bBoundToParent=true
	bScaleToParent=true
	WinHeight=0.700000	//0.804690
	WinLeft=0.100000
	WinTop=0.150000		//0.114990
	WinWidth=0.800000
}