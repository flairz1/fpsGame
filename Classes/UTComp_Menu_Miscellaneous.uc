class UTComp_Menu_Miscellaneous extends UTComp_Menu_MainMenu;

var automated GUILabel l_ScoreboardTitle, l_AdrenTitle, l_GenericTitle, l_NewNet;

var automated moCheckBox ch_UseScoreBoard, ch_WepStats, ch_PickupStats;
var automated moCheckBox ch_speed, ch_booster, ch_invis, ch_berserk;
var automated moCheckBox ch_FootSteps, ch_MatchHudColor, ch_UseEyeHeightAlgo;
var automated moCheckBox ch_UseNewNet;
var automated AemoInt eb_NetUpdateRate, eb_NetSpeed;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	ch_UseScoreboard.Checked(!Settings.bUseDefaultScoreboard);
	ch_WepStats.Checked(class'UTComp_Scoreboard'.default.bDrawStats);
	ch_PickupStats.Checked(class'UTComp_Scoreboard'.default.bDrawPickups);

	ch_speed.Checked(Settings.bDisableSpeed);
	ch_booster.Checked(Settings.bDisableBooster);
	ch_invis.Checked(Settings.bDisableInvis);
	ch_berserk.Checked(Settings.bDisableBerserk);

	ch_FootSteps.Checked(class'UTComp_xPawn'.default.bPlayOwnFootSteps);
	ch_MatchHudColor.Checked(HudS.bMatchHudColor);
	ch_UseEyeHeightAlgo.Checked(Settings.bUseSlopeAlgorithm);

	ch_UseNewNet.Checked(Settings.bClientNetcode);

	eb_NetUpdateRate.Setup(class'MutUTComp'.default.MinNetUpdateRate, class'MutUTComp'.default.MaxNetUpdateRate);
	eb_NetUpdateRate.SetValue(Settings.default.DesiredNetUpdateRate);

	eb_NetSpeed.Setup(class'MutUTComp'.default.MinNetSpeed, class'MutUTComp'.default.MaxNetSpeed);
	eb_NetSpeed.SetValue(Settings.default.DesiredNetSpeed);
}

function InternalOnChange(GUIComponent C)
{
	switch (C)
	{
		case ch_UseScoreboard:
			Settings.bUseDefaultScoreboard = !ch_UseScoreBoard.IsChecked();
			break;

		case ch_WepStats:
			class'UTComp_Scoreboard'.default.bDrawStats = ch_WepStats.IsChecked();
			BS_xPlayer(PlayerOwner()).SetBStats(class'UTComp_Scoreboard'.default.bDrawStats);
			break;

		case ch_PickupStats:
			class'UTComp_Scoreboard'.default.bDrawPickups = ch_PickupStats.IsChecked();
			break;

		case ch_speed:
			Settings.bDisableSpeed = ch_Speed.IsChecked();
			break;

		case ch_booster:
			Settings.bDisableBooster = ch_booster.IsChecked();
			break;

		case ch_invis:
			Settings.bDisableInvis = ch_Invis.IsChecked();
			break;

		case ch_berserk:
			Settings.bDisableberserk = ch_Berserk.IsChecked();
			break;

		case ch_FootSteps:
			class'UTComp_xPawn'.default.bPlayOwnFootSteps = ch_FootSteps.IsChecked();
			break;

		case ch_MatchHudColor:
			HudS.bMatchHudColor = ch_MatchHudColor.IsChecked();
			break;

		case ch_UseEyeHeightAlgo:
			Settings.bUseSlopeAlgorithm = ch_UseEyeHeightAlgo.IsChecked();
			BS_xPlayer(PlayerOwner()).SetEyeHeightAlgorithm(ch_UseEyeHeightAlgo.IsChecked());
			break;

		case ch_UseNewNet:
			Settings.bClientNetcode = ch_UseNewNet.IsChecked();
			BS_xPlayer(PlayerOwner()).TurnOffNetCode();
			break;

		case eb_NetUpdateRate:
			Settings.DesiredNetUpdateRate = eb_NetUpdateRate.GetValue();
			break;
		
		case eb_NetSpeed:
			Settings.DesiredNetSpeed = eb_NetSpeed.GetValue();
			BS_xPlayer(PlayerOwner()).ClientSetNetSpeed(Settings.DesiredNetSpeed);
			break;
	}

	class'UTComp_Overlay'.static.StaticSaveConfig();
	SaveAll();
	class'UTComp_Scoreboard'.static.StaticSaveConfig();
	class'UTComp_xPawn'.static.StaticSaveConfig();
	BS_xPlayer(PlayerOwner()).MatchHudColor();
}

defaultproperties
{
	Begin Object Class=GUILabel Name=ScoreboardLabel
		Caption="Scoreboard Settings"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.100000
		WinLeft=0.200000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ScoreboardTitle=GUILabel'UTComp_Menu_Miscellaneous.ScoreboardLabel'

	Begin Object Class=GUILabel Name=AdrenLabel
		Caption="Adrenaline Combos"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.100000
		WinLeft=0.600000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_AdrenTitle=GUILabel'UTComp_Menu_Miscellaneous.AdrenLabel'

	Begin Object Class=GUILabel Name=GenericLabel
		Caption="General Settings"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.600000
		WinLeft=0.200000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_GenericTitle=GUILabel'UTComp_Menu_Miscellaneous.GenericLabel'

	Begin Object Class=GUILabel Name=NewNetLabel
		Caption="NewNet Settings"
		TextAlign=TXTA_Center
		TextColor=(B=0,G=200,R=230)
		WinTop=0.600000
		WinLeft=0.600000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_NewNet=GUILabel'UTComp_Menu_Miscellaneous.NewNetLabel'

	Begin Object Class=moCheckBox Name=ScoreboardCheck
		Caption="UTComp Scoreboard"
		OnCreateComponent=ScoreboardCheck.InternalOnCreateComponent
		WinTop=0.200000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_UseScoreBoard=moCheckBox'UTComp_Menu_Miscellaneous.ScoreboardCheck'

	Begin Object Class=moCheckBox Name=StatsCheck
		Caption="UTComp Weapon Stats"
		OnCreateComponent=StatsCheck.InternalOnCreateComponent
		WinTop=0.300000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_WepStats=moCheckBox'UTComp_Menu_Miscellaneous.StatsCheck'

	Begin Object Class=moCheckBox Name=PickupCheck
		Caption="UTComp Pickup Stats"
		OnCreateComponent=PickupCheck.InternalOnCreateComponent
		WinTop=0.400000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_PickupStats=moCheckBox'UTComp_Menu_Miscellaneous.PickupCheck'

	Begin Object Class=moCheckBox Name=SpeedCheck
		Caption="Disable Speed"
		OnCreateComponent=SpeedCheck.InternalOnCreateComponent
		WinTop=0.200000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_speed=moCheckBox'UTComp_Menu_Miscellaneous.SpeedCheck'

	Begin Object Class=moCheckBox Name=BoosterCheck
		Caption="Disable Booster"
		OnCreateComponent=BoosterCheck.InternalOnCreateComponent
		WinTop=0.300000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_booster=moCheckBox'UTComp_Menu_Miscellaneous.BoosterCheck'

	Begin Object Class=moCheckBox Name=InvisCheck
		Caption="Disable Invisibility"
		OnCreateComponent=InvisCheck.InternalOnCreateComponent
		WinTop=0.400000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_invis=moCheckBox'UTComp_Menu_Miscellaneous.InvisCheck'

	Begin Object Class=moCheckBox Name=BerserkCheck
		Caption="Disable Berserk"
		OnCreateComponent=BerserkCheck.InternalOnCreateComponent
		WinTop=0.500000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_berserk=moCheckBox'UTComp_Menu_Miscellaneous.BerserkCheck'

	Begin Object Class=moCheckBox Name=FootCheck
		Caption="Play own footstep sounds"
		OnCreateComponent=FootCheck.InternalOnCreateComponent
		WinTop=0.700000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_FootSteps=moCheckBox'UTComp_Menu_Miscellaneous.FootCheck'

	Begin Object Class=moCheckBox Name=HudColorCheck
		Caption="Match Hud color to skins"
		OnCreateComponent=HudColorCheck.InternalOnCreateComponent
		WinTop=0.800000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_MatchHudColor=moCheckBox'UTComp_Menu_Miscellaneous.HudColorCheck'

	Begin Object Class=moCheckBox Name=UseEyeHeightAlgoCheck
		Caption="New EyeHeight Algorithm"
		OnCreateComponent=HudColorCheck.InternalOnCreateComponent
		WinTop=0.900000
		WinLeft=0.250000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_UseEyeHeightAlgo=moCheckBox'UTComp_Menu_Miscellaneous.UseEyeHeightAlgoCheck'

	Begin Object Class=moCheckBox Name=NewNetCheck
		Caption="Enhanced Netcode"
		OnCreateComponent=NewNetCheck.InternalOnCreateComponent
		WinTop=0.700000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	ch_UseNewNet=moCheckBox'UTComp_Menu_Miscellaneous.NewNetCheck'

	Begin Object Class=AemoInt Name=DesiredNetRate
		Caption="Net Update Rate"
		CaptionWidth=0.700000
		WinTop=0.800000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	eb_NetUpdateRate=AemoInt'UTComp_Menu_Miscellaneous.DesiredNetRate'

	Begin Object Class=AemoInt Name=DesiredNetSpeed
		Caption="Netspeed"
		CaptionWidth=0.700000
		WinTop=0.900000
		WinLeft=0.650000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_Miscellaneous.InternalOnChange
	End Object
	eb_NetSpeed=AemoInt'UTComp_Menu_Miscellaneous.DesiredNetSpeed'
}