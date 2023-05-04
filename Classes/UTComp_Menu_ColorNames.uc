class UTComp_Menu_ColorNames extends UTComp_Menu_MainMenu;

var automated GUILabel l_ColorNameLetters[20];
var automated GUILabel l_LetterSelection;
var automated moCheckBox ch_ColorChat, ch_ColorScoreboard, ch_ColorQ3, ch_EnemyNames;
var automated GUIComboBox co_SavedNames;
var automated GUIButton bu_SaveName, bu_DeleteName, bu_ResetWhite, bu_Apply;
var automated GUI_Slider sl_RedColor, sl_GreenColor, sl_BlueColor;
var automated GUISlider sl_LetterSelect;
var automated moComboBox co_DeathSelect;

event Opened(GUIComponent Sender)
{
	InitSliderAndLetters();
	Super.Opened(Sender);
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local int i;

	Super.InitComponent(MyController, MyOwner);

	for(i = 0; i < Settings.ColoredName.Length; i++)
	{
		co_SavedNames.AddItem(BS_xPlayer(PlayerOwner()).FindColoredName(i));
	}
	co_SavedNames.ReadOnly(true);

	InitSliderAndLetters();
	SetColorSliders(0);

	ch_ColorChat.Checked(Settings.bEnableColoredNamesInTalk);
	ch_ColorScoreboard.Checked(class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard);
	ch_ColorQ3.Checked(Settings.bAllowColoredMessages);
	ch_EnemyNames.Checked(Settings.bEnableColoredNamesOnEnemies);

	co_DeathSelect.AddItem("Disabled");
	co_DeathSelect.AddItem("Colored Names");
	co_DeathSelect.AddItem("Team Colored Names");
	co_DeathSelect.ReadOnly(true);

	if (class'UTComp_xDeathMessage'.default.bTeamColoredDeaths)
		co_DeathSelect.SetIndex(2);
	else if (class'UTComp_xDeathMessage'.default.bColoredNameDeathMessages)
		co_DeathSelect.SetIndex(1);
}

function InitSliderAndLetters()
{
	local int i;

	for(i = 0; i < Len(PlayerOwner().PlayerReplicationInfo.PlayerName); i++)
	{
		Settings.ColorName[i].A = 255;
		l_ColorNameLetters[i].TextFont = "UT2LargeFont";
		l_ColorNameLetters[i].WinTop = 0.400000;
		l_ColorNameLetters[i].WinWidth = 0.032000;
		l_ColorNameLetters[i].WinLeft = 0.100000 + (0.50 - (0.50 * 0.032 * Len(PlayerOwner().PlayerReplicationInfo.PlayerName)) + (0.032 * i));
		l_ColorNameLetters[i].StyleName = "TextLabel";
		l_ColorNameLetters[i].Caption = Right(Left(PlayerOwner().PlayerReplicationInfo.PlayerName, (i+1)), 1);
		l_ColorNameLetters[i].TextColor = Settings.ColorName[i];
		l_ColorNameLetters[i].TextAlign = TXTA_Center;
	}

	for(i = Len(PlayerOwner().PlayerReplicationInfo.PlayerName); i < 20; i++)
		l_ColorNameLetters[i].Caption = "";

	sl_LetterSelect.MinValue = 1;
	sl_LetterSelect.MaxValue = Min((Len(PlayerOwner().PlayerReplicationInfo.PlayerName)), 20);
	sl_LetterSelect.WinLeft = 0.100000 + (0.50 - (0.50 * 0.032 * sl_LetterSelect.MaxValue));
	sl_LetterSelect.WinWidth = (0.032 * sl_LetterSelect.MaxValue);
	sl_LetterSelect.BarStyle = None;
	sl_LetterSelect.FillImage = None;
}

function SpecialInitSliderAndLetters(int j)
{
	local int i;

	for(i = 0; i < Len(Settings.ColoredName[j].SavedName); i++)
	{
		Settings.ColorName[i].A = 255;	//make sure someone didnt change this
		l_ColorNameLetters[i].TextFont = "UT2LargeFont";
		l_ColorNameLetters[i].WinTop = 0.400000;
		l_ColorNameLetters[i].WinWidth = 0.032000;
		l_ColorNameLetters[i].WinLeft = 0.100000 + (0.50 - (0.50 * 0.032 * Len(Settings.ColoredName[j].SavedName)) + (0.032 * i));
		l_ColorNameLetters[i].StyleName = "TextLabel";
		l_ColorNameLetters[i].Caption = Right(Left(Settings.ColoredName[j].SavedName, (i+1)), 1);
		l_ColorNameLetters[i].TextColor = Settings.ColoredName[j].SavedColor[i];
		l_ColorNameLetters[i].TextAlign = TXTA_Center;
	}

	for(i = Len(Settings.ColoredName[j].SavedName); i < 20; i++)
		l_ColorNameLetters[i].Caption = "";

	sl_LetterSelect.MinValue = 1;
	sl_LetterSelect.MaxValue = Min((Len(PlayerOwner().PlayerReplicationInfo.PlayerName)), 20);
	sl_LetterSelect.WinLeft = 0.100000 + (0.50 - (0.50 * 0.032 * Len(PlayerOwner().PlayerReplicationInfo.PlayerName)));
	sl_LetterSelect.WinWidth = (0.032 * Min((Len(PlayerOwner().PlayerReplicationInfo.PlayerName)), 20));
	sl_LetterSelect.BarStyle = None;
	sl_LetterSelect.FillImage = None;
}

function SetColorSliders(byte offset)
{
	sl_RedColor.SetValue(Settings.ColorName[offset].R);
	sl_GreenColor.SetValue(Settings.ColorName[offset].G);
	sl_BlueColor.SetValue(Settings.ColorName[offset].B);
}

function InternalOnChange(GUIComponent C)
{
	switch (C)
	{
		case ch_ColorChat:
			Settings.bEnableColoredNamesInTalk = ch_ColorChat.IsChecked();
			break;

		case ch_ColorScoreboard:
			class'UTComp_ScoreBoard'.default.bEnableColoredNamesOnScoreboard = ch_ColorScoreboard.IsChecked();
			break;

		case ch_ColorQ3:
			Settings.bAllowColoredMessages = ch_ColorQ3.IsChecked();
			break;

		case ch_EnemyNames:
			Settings.bEnableColoredNamesOnEnemies = ch_EnemyNames.IsChecked();
			break;

		case co_DeathSelect:
			class'UTComp_xDeathMessage'.default.bTeamColoredDeaths = (co_DeathSelect.GetIndex() == 2);
			class'UTComp_xDeathMessage'.default.bColoredNameDeathMessages = (co_DeathSelect.GetIndex() == 1);
			break;

		case sl_LetterSelect:
			SetColorSliders(sl_LetterSelect.Value-1);
			break;

		case sl_RedColor:
			Settings.ColorName[sl_LetterSelect.Value-1].R = sl_RedColor.Value;
			BS_xPlayer(PlayerOwner()).SetColoredNameOldStyle();
			l_ColorNameLetters[sl_LetterSelect.Value-1].TextColor.R = sl_RedColor.Value;
			break;

		case sl_GreenColor:
			Settings.ColorName[sl_LetterSelect.Value-1].G = sl_GreenColor.Value;
			BS_xPlayer(PlayerOwner()).SetColoredNameOldStyle();
			l_ColorNameLetters[sl_LetterSelect.Value-1].TextColor.G = sl_GreenColor.Value;
			break;

		case sl_BlueColor:
			Settings.ColorName[sl_LetterSelect.Value-1].B = sl_BlueColor.Value;
			BS_xPlayer(PlayerOwner()).SetColoredNameOldStyle();
			l_ColorNameLetters[sl_LetterSelect.Value-1].TextColor.B = sl_BlueColor.Value;
			break;

		case co_SavedNames:
			break;
	}

	class'UTComp_ScoreBoard'.static.StaticSaveConfig();
	class'UTComp_xDeathMessage'.static.StaticSaveConfig();
	SaveAll();
}

function bool InternalOnClick(GUIComponent Sender)
{
	local int i;

	switch(Sender)
	{
		case bu_SaveName:
			BS_xPlayer(PlayerOwner()).SaveNewColoredName();
			co_SavedNames.ReadOnly(false);
			co_SavedNames.AddItem(BS_xPlayer(PlayerOwner()).AddNewColoredName(Settings.ColoredName.Length-1));
			co_SavedNames.ReadOnly(true);
			break;

		case bu_DeleteName:
			if (Settings.ColoredName.Length > co_SavedNames.GetIndex() && co_SavedNames.GetIndex() >= 0)
				Settings.ColoredName.Remove(co_SavedNames.GetIndex(), 1);
			co_SavedNames.ReadOnly(false);
			co_SavedNames.RemoveItem(co_SavedNames.GetIndex());
			co_SavedNames.ReadOnly(true);
			break;

		case bu_ResetWhite:
			for(i = 0; i < 20; i++)
			{
				Settings.ColorName[i].R = 255;
				Settings.ColorName[i].G = 255;
				Settings.ColorName[i].B = 255;
				l_ColorNameLetters[i].TextColor.R = 255;
				l_ColorNameLetters[i].TextColor.G = 255;
				l_ColorNameLetters[i].TextColor.B = 255;
			}
			break;

		case bu_Apply:
			BS_xPlayer(PlayerOwner()).SetColoredNameOldStyleCustom("", co_SavedNames.GetIndex());
			Settings.CurrentSelectedColoredName = co_savedNames.GetIndex();
			SpecialInitSliderAndLetters(co_SavedNames.GetIndex());
			SetColorSliders(sl_LetterSelect.Value-1);
			break;
	}

	SaveAll();

	Super.InternalOnClick(Sender);
	return true;
}

defaultproperties
{
	Begin Object Class=GUILabel Name=Label0
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(0)=GUILabel'UTComp_Menu_ColorNames.Label0'

	Begin Object Class=GUILabel Name=Label1
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(1)=GUILabel'UTComp_Menu_ColorNames.Label1'

	Begin Object Class=GUILabel Name=Label2
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(2)=GUILabel'UTComp_Menu_ColorNames.Label2'

	Begin Object Class=GUILabel Name=Label3
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(3)=GUILabel'UTComp_Menu_ColorNames.Label3'

	Begin Object Class=GUILabel Name=Label4
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(4)=GUILabel'UTComp_Menu_ColorNames.Label4'

	Begin Object Class=GUILabel Name=Label5
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(5)=GUILabel'UTComp_Menu_ColorNames.Label5'

	Begin Object Class=GUILabel Name=Label6
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(6)=GUILabel'UTComp_Menu_ColorNames.Label6'

	Begin Object Class=GUILabel Name=Label7
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(7)=GUILabel'UTComp_Menu_ColorNames.Label7'

	Begin Object Class=GUILabel Name=Label8
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(8)=GUILabel'UTComp_Menu_ColorNames.Label8'

	Begin Object Class=GUILabel Name=Label9
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(9)=GUILabel'UTComp_Menu_ColorNames.Label9'

	Begin Object Class=GUILabel Name=Label10
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(10)=GUILabel'UTComp_Menu_ColorNames.Label10'

	Begin Object Class=GUILabel Name=Label11
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(11)=GUILabel'UTComp_Menu_ColorNames.Label11'

	Begin Object Class=GUILabel Name=Label12
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(12)=GUILabel'UTComp_Menu_ColorNames.Label12'

	Begin Object Class=GUILabel Name=Label13
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(13)=GUILabel'UTComp_Menu_ColorNames.Label13'

	Begin Object Class=GUILabel Name=Label14
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(14)=GUILabel'UTComp_Menu_ColorNames.Label14'

	Begin Object Class=GUILabel Name=Label15
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(15)=GUILabel'UTComp_Menu_ColorNames.Label15'

	Begin Object Class=GUILabel Name=Label16
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(16)=GUILabel'UTComp_Menu_ColorNames.Label16'

	Begin Object Class=GUILabel Name=Label17
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(17)=GUILabel'UTComp_Menu_ColorNames.Label17'

	Begin Object Class=GUILabel Name=Label18
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(18)=GUILabel'UTComp_Menu_ColorNames.Label18'

	Begin Object Class=GUILabel Name=Label19
		bBoundToParent=true
		bScaleToParent=true
	End Object
	l_ColorNameLetters(19)=GUILabel'UTComp_Menu_ColorNames.Label19'

	Begin Object Class=moCheckBox Name=ColorChatCheck
		Caption="Colored Names in Chat"
		OnCreateComponent=ColorChatCheck.InternalOnCreateComponent
		WinTop=0.125000
		WinLeft=0.275000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
	End Object
	ch_ColorChat=moCheckBox'UTComp_Menu_ColorNames.ColorChatCheck'

	Begin Object Class=moCheckBox Name=ColorScoreboardCheck
		Caption="Colored Names on Scoreboard"
		OnCreateComponent=ColorScoreboardCheck.InternalOnCreateComponent
		WinTop=0.200000
		WinLeft=0.275000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
	End Object
	ch_ColorScoreboard=moCheckBox'UTComp_Menu_ColorNames.ColorScoreboardCheck'

	Begin Object Class=moCheckBox Name=Colorq3Check
		Caption="Colored Messages (Q3 style)"
		OnCreateComponent=Colorq3Check.InternalOnCreateComponent
		WinTop=0.200000
		WinLeft=0.625000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
	End Object
	ch_ColorQ3=moCheckBox'UTComp_Menu_ColorNames.Colorq3Check'

	Begin Object Class=moCheckBox Name=EnemyNamesCheck
		Caption="Colored Names on targeting"
		OnCreateComponent=EnemyNamesCheck.InternalOnCreateComponent
		WinTop=0.125000
		WinLeft=0.625000
		WinWidth=0.300000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
	End Object
	ch_EnemyNames=moCheckBox'UTComp_Menu_ColorNames.EnemyNamesCheck'

	Begin Object Class=GUIComboBox Name=ComboNameSaved
		WinTop=0.750000
		WinLeft=0.450000
		WinWidth=0.300000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
		OnKeyEvent=ComboNameSaved.InternalOnKeyEvent
	End Object
	co_SavedNames=GUIComboBox'UTComp_Menu_ColorNames.ComboNameSaved'

	Begin Object Class=GUIButton Name=ButtonSave
		Caption="Save"
		WinTop=0.850000
		WinLeft=0.450000
		WinWidth=0.150000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_ColorNames.InternalOnClick
		OnKeyEvent=ButtonSave.InternalOnKeyEvent
	End Object
	bu_SaveName=GUIButton'UTComp_Menu_ColorNames.ButtonSave'

	Begin Object Class=GUIButton Name=ButtonDelete
		Caption="Delete"
		WinTop=0.850000
		WinLeft=0.600000
		WinWidth=0.150000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_ColorNames.InternalOnClick
		OnKeyEvent=ButtonDelete.InternalOnKeyEvent
	End Object
	bu_DeleteName=GUIButton'UTComp_Menu_ColorNames.ButtonDelete'

	Begin Object Class=GUIButton Name=ButtonWhite
		Caption="Reset Colors"
		WinTop=0.650000
		WinLeft=0.450000
		WinWidth=0.300000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_ColorNames.InternalOnClick
		OnKeyEvent=ButtonWhite.InternalOnKeyEvent
	End Object
	bu_ResetWhite=GUIButton'UTComp_Menu_ColorNames.ButtonWhite'

	Begin Object Class=GUIButton Name=ButtonApply
		Caption="Set Name"
		WinTop=0.900000
		WinLeft=0.450000
		WinWidth=0.300000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=UTComp_Menu_ColorNames.InternalOnClick
		OnKeyEvent=ButtonApply.InternalOnKeyEvent
	End Object
	bu_Apply=GUIButton'UTComp_Menu_ColorNames.ButtonApply'

	Begin Object Class=GUI_Slider Name=RedSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_r"
		WinTop=0.500000
		WinLeft=0.400000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=RedSlider.InternalOnClick
		OnMousePressed=RedSlider.InternalOnMousePressed
		OnMouseRelease=RedSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
		OnKeyEvent=RedSlider.InternalOnKeyEvent
		OnCapturedMouseMove=RedSlider.InternalCapturedMouseMove
	End Object
	sl_RedColor=GUI_Slider'UTComp_Menu_ColorNames.RedSlider'

	Begin Object Class=GUI_Slider Name=GreenSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_g"
		WinTop=0.550000
		WinLeft=0.400000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=GreenSlider.InternalOnClick
		OnMousePressed=GreenSlider.InternalOnMousePressed
		OnMouseRelease=GreenSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
		OnKeyEvent=GreenSlider.InternalOnKeyEvent
		OnCapturedMouseMove=GreenSlider.InternalCapturedMouseMove
	End Object
	sl_GreenColor=GUI_Slider'UTComp_Menu_ColorNames.GreenSlider'

	Begin Object Class=GUI_Slider Name=BlueSlider
		MaxValue=255.000000
		bIntSlider=True
		StyleName="sl_knob_b"
		WinTop=0.600000
		WinLeft=0.400000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=BlueSlider.InternalOnClick
		OnMousePressed=BlueSlider.InternalOnMousePressed
		OnMouseRelease=BlueSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
		OnKeyEvent=BlueSlider.InternalOnKeyEvent
		OnCapturedMouseMove=BlueSlider.InternalCapturedMouseMove
	End Object
	sl_BlueColor=GUI_Slider'UTComp_Menu_ColorNames.BlueSlider'

	Begin Object Class=GUISlider Name=LetterSlider
		Value=1.000000
		bIntSlider=True
		StyleName="BTSliderArrow"
		WinTop=0.400000
		WinHeight=0.080000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=LetterSlider.InternalOnClick
		OnMousePressed=LetterSlider.InternalOnMousePressed
		OnMouseRelease=LetterSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
		OnKeyEvent=LetterSlider.InternalOnKeyEvent
		OnCapturedMouseMove=LetterSlider.InternalCapturedMouseMove
	End Object
	sl_LetterSelect=GUISlider'UTComp_Menu_ColorNames.LetterSlider'

	Begin Object Class=moComboBox Name=ColorDeathCombo
		Caption="Death Message Color"
		OnCreateComponent=ColorDeathCombo.InternalOnCreateComponent
		WinTop=0.300000
		WinLeft=0.400000
		WinWidth=0.400000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_ColorNames.InternalOnChange
	End Object
	co_DeathSelect=moComboBox'UTComp_Menu_ColorNames.ColorDeathCombo'
}