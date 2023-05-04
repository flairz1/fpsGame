class UTComp_Menu_Voting extends UTComp_Menu_MainMenu;

var automated GUIComboBox co_Skins, co_Hitsounds, co_TeamOverlay, co_NewNet;
var automated GUIButton bu_Skins, bu_Hitsounds, bu_TeamOverlay, bu_NewNet;

var automated GUILabel l_Restart, l_NoRestart;
var automated GUILabel l_Skins, l_HitSounds, l_TeamOverlay, l_NewNet;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	co_Skins.AddItem("Epic Style");
	co_Skins.AddItem("Brighter Epic Style");
	co_Skins.AddItem("UTComp Style");

	co_HitSounds.AddItem("Disabled");
	co_HitSounds.AddItem("Line-Of-Sight");
	co_HitSounds.AddItem("Everywhere");

	co_TeamOverlay.AddItem("Disabled");
	co_TeamOverlay.AddItem("Enabled");

	co_NewNet.AddItem("Disabled");
	co_NewNet.AddItem("Enabled");

	co_Skins.ReadOnly(true);
	co_HitSounds.ReadOnly(true);
	co_TeamOverlay.ReadOnly(true);
	co_NewNet.ReadOnly(true);

	Blehz();
}

function bool InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case bu_Skins:
			BS_xPlayer(PlayerOwner()).CallVote(1, co_Skins.GetIndex(), "");
			PlayerOwner().ClientCloseMenu();
			break;

		case bu_Hitsounds:
			BS_xPlayer(PlayerOwner()).CallVote(2, co_Hitsounds.GetIndex(), "");
			PlayerOwner().ClientCloseMenu();
			break;

		case bu_TeamOverlay:
			BS_xPlayer(PlayerOwner()).CallVote(3, co_TeamOverlay.GetIndex(), "");
			PlayerOwner().ClientCloseMenu();
			break;

		case bu_NewNet:
			BS_xPlayer(PlayerOwner()).CallVote(4, co_NewNet.GetIndex(), "");
			PlayerOwner().ClientCloseMenu();
			break;
	}

	return Super.InternalOnClick(Sender);
}

event Opened(GUIComponent Sender)
{
	Super.Opened(Sender);
	Blehz();
}

function Blehz()
{
	local UTComp_ServerReplicationInfo RepInfo;

	if (RepInfo == None)
	{
		foreach PlayerOwner().DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	if (RepInfo != None && (RepInfo.b_NoVoting || !RepInfo.b_BrightskinsVoting))
		co_Skins.DisableMe();
	else
		co_Skins.EnableMe();

	if (RepInfo != None && (RepInfo.b_NoVoting || !RepInfo.b_HitsoundsVoting))
		co_Hitsounds.DisableMe();
	else
		co_HitSounds.EnableMe();

	if (RepInfo != None && (RepInfo.b_NoVoting || !RepInfo.b_TeamOverlayVoting))
		co_TeamOverlay.DisableMe();
	else
		co_TeamOverlay.EnableMe();

	if (RepInfo != None && (RepInfo.b_NoVoting || !RepInfo.b_NetcodeVoting))
		co_NewNet.DisableMe();
	else
		co_NewNet.EnableMe();

	if (RepInfo != None)
	{
		co_Skins.SetIndex(RepInfo.i_Brightskins-1);
		co_HitSounds.SetIndex(RepInfo.i_Hitsounds);
		if (RepInfo.b_TeamOverlay)
			co_TeamOverlay.SetIndex(1);

		if (RepInfo.b_Netcode)
			co_NewNet.SetIndex(1);
	}
}

defaultproperties
{
	Begin Object Class=GUIComboBox Name=SkinsComboBox
		WinTop=0.200000
		WinLeft=0.500000
		WinWidth=0.200000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnKeyEvent=SkinsComboBox.InternalOnKeyEvent
	End Object
	co_Skins=GUIComboBox'UTComp_Menu_Voting.SkinsComboBox'

	Begin Object Class=GUIComboBox Name=HitsoundsComboBox
		WinTop=0.300000
		WinLeft=0.500000
		WinWidth=0.200000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnKeyEvent=HitsoundsComboBox.InternalOnKeyEvent
	End Object
	co_Hitsounds=GUIComboBox'UTComp_Menu_Voting.HitsoundsComboBox'

	Begin Object Class=GUIComboBox Name=TeamOverlayComboBox
		WinTop=0.400000
		WinLeft=0.500000
		WinWidth=0.200000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnKeyEvent=TeamOverlayComboBox.InternalOnKeyEvent
	End Object
	co_TeamOverlay=GUIComboBox'UTComp_Menu_Voting.TeamOverlayComboBox'

	Begin Object Class=GUIComboBox Name=NewNetComboBox
		WinTop=0.700000
		WinLeft=0.500000
		WinWidth=0.200000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnKeyEvent=NewNetComboBox.InternalOnKeyEvent
	End Object
	co_NewNet=GUIComboBox'UTComp_Menu_Voting.NewNetComboBox'

	Begin Object Class=GUIButton Name=SkinsButton
		Caption="Call Vote"
		WinTop=0.200000
		WinLeft=0.750000
		WinWidth=0.100000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_Voting.InternalOnClick
		OnKeyEvent=SkinsButton.InternalOnKeyEvent
	End Object
	bu_Skins=GUIButton'UTComp_Menu_Voting.SkinsButton'

	Begin Object Class=GUIButton Name=HitsoundsButton
		Caption="Call Vote"
		WinTop=0.300000
		WinLeft=0.750000
		WinWidth=0.100000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_Voting.InternalOnClick
		OnKeyEvent=HitsoundsButton.InternalOnKeyEvent
	End Object
	bu_Hitsounds=GUIButton'UTComp_Menu_Voting.HitsoundsButton'

	Begin Object Class=GUIButton Name=TeamOverlayButton
		Caption="Call Vote"
		WinTop=0.400000
		WinLeft=0.750000
		WinWidth=0.100000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_Voting.InternalOnClick
		OnKeyEvent=TeamOverlayButton.InternalOnKeyEvent
	End Object
	bu_TeamOverlay=GUIButton'UTComp_Menu_Voting.TeamOverlayButton'

	Begin Object Class=GUIButton Name=NewNetButton
		Caption="Call Vote"
		WinTop=0.700000
		WinLeft=0.750000
		WinWidth=0.100000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_Voting.InternalOnClick
		OnKeyEvent=NewNetButton.InternalOnKeyEvent
	End Object
	bu_NewNet=GUIButton'UTComp_Menu_Voting.NewNetButton'

	Begin Object Class=GUILabel Name=SkinsLabel
		Caption="Brightskins"
		TextAlign=TXTA_Right
		TextColor=(B=255,G=255,R=255)
		WinTop=0.200000
		WinLeft=0.250000
		WinWidth=0.200000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Skins=GUILabel'UTComp_Menu_Voting.SkinsLabel'

	Begin Object Class=GUILabel Name=HitsoundsLabel
		Caption="Hitsounds"
		TextAlign=TXTA_Right
		TextColor=(B=255,G=255,R=255)
		WinTop=0.300000
		WinLeft=0.250000
		WinWidth=0.200000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_HitSounds=GUILabel'UTComp_Menu_Voting.HitsoundsLabel'

	Begin Object Class=GUILabel Name=TeamOverlayLabel
		Caption="Team Overlay"
		TextAlign=TXTA_Right
		TextColor=(B=255,G=255,R=255)
		WinTop=0.400000
		WinLeft=0.250000
		WinWidth=0.200000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_TeamOverlay=GUILabel'UTComp_Menu_Voting.TeamOverlayLabel'

	Begin Object Class=GUILabel Name=DemnoHeadingLabel
		Caption="Vote Settings (map change)"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		VertAlign=TXTA_Center
		WinTop=0.600000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_Restart=GUILabel'UTComp_Menu_Voting.DemnoHeadingLabel'

	Begin Object Class=GUILabel Name=RestartLabel
		Caption="Vote Settings (instant effect)"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		VertAlign=TXTA_Center
		WinTop=0.100000
		WinLeft=0.200000
		WinWidth=0.800000
		WinHeight=0.075000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_NoRestart=GUILabel'UTComp_Menu_Voting.RestartLabel'

	Begin Object Class=GUILabel Name=NewNetLabel
		Caption="Enhanced Netcode"
		TextAlign=TXTA_Right
		TextColor=(B=255,G=255,R=255)
		WinTop=0.700000
		WinLeft=0.250000
		WinWidth=0.200000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_NewNet=GUILabel'UTComp_Menu_Voting.NewNetLabel'
}