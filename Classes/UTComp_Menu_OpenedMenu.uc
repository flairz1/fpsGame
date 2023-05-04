class UTComp_Menu_OpenedMenu extends UTComp_Menu_MainMenu;

var automated array<GUILabel> l_Mode;

var Color GoldColor;
var UTComp_ServerReplicationInfo RepInfo;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	l_Mode[0].Caption = "UTComp" $ class'GameInfo'.static.MakeColorCode(GoldColor) @ "Black (18c)";

	Super.InitComponent(MyController, MyOwner);
}

function RandomCrap()
{
	if (RepInfo == None)
	{
		foreach PlayerOwner().ViewTarget.DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	if (RepInfo.i_Brightskins == 1)
		l_Mode[2].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Brightskins Mode:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Brightskins Disabled";
	else if (RepInfo.i_Brightskins == 2)
		l_Mode[2].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Brightskins Mode:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Bright Epic Style Skins";
	else if (RepInfo.i_Brightskins == 3)
		l_Mode[2].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Brightskins Mode:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  UTComp Style Skins";

	if (RepInfo.i_Hitsounds == 0)
		l_Mode[3].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Hitsounds Mode:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Disabled";
	else if (RepInfo.i_Hitsounds == 1)
		l_Mode[3].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Hitsounds Mode:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Line Of Sight";
	else if (RepInfo.i_Hitsounds == 2)
		l_Mode[3].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Hitsounds Mode:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Everywhere";

	if (RepInfo.b_TeamOverlay)
		l_Mode[4].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Team Overlay:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Enabled";
	else
		l_Mode[4].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Team Overlay:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Disabled";

	if (RepInfo.b_Netcode)
		l_Mode[5].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Enhanced Netcode:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Enabled";
	else
		l_Mode[5].Caption = class'GameInfo'.static.MakeColorCode(GoldColor)$"Enhanced Netcode:"$class'GameInfo'.static.MakeColorCode(WhiteColor)$"  Disabled";
}

event opened(GUIComponent Sender)
{
	Super.Opened(Sender);
	RandomCrap();
}

defaultproperties
{
	Begin Object Class=GUILabel Name=VersionLabel
		TextColor=(B=255,G=255,R=255)
		TextAlign=TXTA_Center
		WinTop=0.880000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Mode(0)=GUILabel'VersionLabel'

	Begin Object Class=GUILabel Name=ServerSetLabel
		Caption="Server Settings"
		TextColor=(B=0,G=200,R=230)
		TextFont="UT2LargeFont"
		TextAlign=TXTA_Center
		VertAlign=TXTA_Center
		WinTop=0.100000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Mode(1)=GUILabel'ServerSetLabel'

	Begin Object Class=GUILabel Name=BrightSkinsModeLabel
		TextColor=(B=255,G=255,R=255)
		TextAlign=TXTA_Center
		WinTop=0.300000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.100000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Mode(2)=GUILabel'BrightSkinsModeLabel'

	Begin Object Class=GUILabel Name=HitSoundsModeLabel
		TextColor=(B=255,G=255,R=255)
		TextAlign=TXTA_Center
		WinTop=0.400000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.100000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Mode(3)=GUILabel'HitSoundsModeLabel'

	Begin Object Class=GUILabel Name=TOModeLabel
		TextColor=(B=255,G=255,R=255)
		TextAlign=TXTA_Center
		WinTop=0.500000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.100000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Mode(4)=GUILabel'TOModeLabel'

	Begin Object Class=GUILabel Name=NetCodeModeLabel
		TextColor=(B=255,G=255,R=255)
		TextAlign=TXTA_Center
		WinTop=0.600000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.100000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Mode(5)=GUILabel'NetCodeModeLabel'

/*
	Begin Object Class=GUILabel Name=NewVersions
		Caption="visit https://Github.com/Deaod/UTComp for other versions."
		TextColor=(B=255,G=255,R=255)
		TextAlign=TXTA_Center
		WinTop=0.940000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Mode(6)=GUILabel'NewVersions'
*/

	GoldColor=(R=230,G=200,B=0,A=255)
	bBoundToParent=true
	bScaleToParent=true
}