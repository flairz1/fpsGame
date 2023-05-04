class UTComp_Menu_BrightSkins extends UTComp_Menu_MainMenu;

var automated moCheckBox ch_EnemySkins;

var automated GUIComboBox co_TeamSelect;
var automated GUIComboBox co_TypeSkinSelect;
var automated GUIComboBox co_ModelSelect;
var automated GUIComboBox co_EpicSkinSelect;
var automated GUIImage SpinnyDudeBounds;

var automated GUI_Slider sl_RedSkin, sl_GreenSkin, sl_BlueSkin;
var automated moCheckBox ch_ForceThisModel, ch_DarkSkins, ch_EnemyModels;

var automated GUILabel l_SkinHeader, lModelHeader;

var bool InitializationComplete;
var bool bUpdatingCrap;

var UTComp_SpinnyWeap SpinnyDude;
var(SpinnyDude) vector SpinnyDudeOffset;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local UTComp_ServerReplicationInfo RepInfo;

	Super.InitComponent(MyController, MyOwner);

	ch_EnemySkins.Checked(Settings.bEnemyBasedSkins);
	ch_EnemyModels.Checked(Settings.bEnemyBasedModels);

	//Team Select Combobox
	if (ch_EnemySkins.IsChecked())
	{
		if (!ch_EnemyModels.IsChecked())
		{
			co_TeamSelect.AddItem("Teammates(Skins), Red(Models)");
			co_TeamSelect.AddItem("Enemies(Skins), Blue(Models)");
		}
		else
		{
			co_TeamSelect.AddItem("Teammates");
			co_TeamSelect.AddItem("Enemies");
		}
	}
	else
	{
		if (ch_EnemyModels.IsChecked())
		{
			co_TeamSelect.AddItem("Red(Skins), Teammates(Models)");
			co_TeamSelect.AddItem("Blue(Skins), Enemies(Models)");
		}
		else
		{
			co_TeamSelect.AddItem("Red Team");
			co_TeamSelect.AddItem("Blue Team");
		}
	}

	if (RepInfo == None)
	{
		foreach PlayerOwner().DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	//Model Select Combobox
	AddComboBoxItems(co_ModelSelect);

	//Type Skin Select Combobox
	if (RepInfo == none || RepInfo.i_Brightskins >= 1)
		co_EpicSkinSelect.AddItem("DM Skin");

	co_EpicSkinSelect.AddItem("Red Skin");
	co_EpicSkinSelect.AddItem("Blue Skin");
	if (RepInfo == none || RepInfo.i_Brightskins > 1)
		co_EpicSkinSelect.AddItem("Purple Skin");
	else
		co_EpicSkinSelect.AddItem("Purple Skin (Server Disabled)");

	co_EpicSkinSelect.AddItem("Brighter DM Skin");
	co_EpicSkinSelect.AddItem("Brighter Red Skin");
	co_EpicSkinSelect.AddItem("Brighter Blue Skin");
	if (RepInfo == none || RepInfo.i_Brightskins > 1)
		co_EpicSkinSelect.AddItem("Brighter Purple Skin");
	else
		co_EpicSkinSelect.AddItem("Brighter Purple Skin (Server Disabled)");

	ch_DarkSkins.Checked(Settings.bEnableDarkSkinning);

	UpdateAllComponents();

	co_EpicSkinSelect.ReadOnly(true);
	co_TypeSkinSelect.ReadOnly(true);
	co_TeamSelect.ReadOnly(true);

	InitializationComplete = true;
}

event Opened(GUIComponent Sender)
{
	local UTComp_ServerReplicationInfo RepInfo;
	local int Temp;

	Super.Opened(Sender);

	if (RepInfo == None)
	{
		foreach PlayerOwner().DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	InitializationComplete = false;
	co_TeamSelect.SetIndex(0);
	Temp = Settings.ClientSkinModeRedTeammate;

	co_TypeSkinSelect.Clear();
	co_TypeSkinSelect.AddItem("Epic Style");
	if (RepInfo == None || RepInfo.i_Brightskins > 1)
		co_TypeSkinSelect.AddItem("Brighter Epic Style");
	else
		co_TypeSkinSelect.AddItem("Brighter Epic Style (Server Disabled)");

	if (RepInfo == None || RepInfo.i_Brightskins > 2)
		co_TypeSkinSelect.AddItem("UTComp Style");
	else
		co_TypeSkinSelect.AddItem("UTComp Style (Server Disabled)");

	co_TypeSkinSelect.SetIndex(Temp-1);

	InitializeSpinnyDude();
	UpdateAllComponents();
	InitializationComplete = true;
}

function InitializeSpinnyDude()
{
	local vector V, X, Y, Z;
	local vector X2, Y2;
	local rotator R, R2;

	// Spawn spinning character actor
	if (SpinnyDude == None)
		SpinnyDude = PlayerOwner().Spawn(class'UTComp_SpinnyWeap');

	if (SpinnyDude != None)
	{
		SpinnyDude.SetDrawType(DT_Mesh);
		SpinnyDude.SetDrawScale(0.9);
		SpinnyDude.SpinRate = 4000;
		SpinnyDude.AmbientGlow = 45;

		R = PlayerOwner().Rotation;

		GetAxes(R, X, Y, Z);
		R2.Yaw = 32768;   //32768 = pi in uRotational
		V = vector(R2);
		X2 = V.X*X + V.Y*Y;
		Y2 = V.X*Y - V.Y*X;

		R2 = OrthoRotation(X2, Y2, Z);

		SpinnyDude.SetRotation(R2);
	}
}

function InternalOnChange(GUIComponent C)
{
	local byte Team;

	Team = co_TeamSelect.GetIndex();

	if (!InitializationComplete)
		return;

	Switch(C)
	{
		case ch_EnemySkins:
			Settings.bEnemyBasedSkins = ch_EnemySkins.IsChecked();
			ChangeComboBoxCaption();
			if (!bUpdatingCrap)
				UpdateAllComponents();
			break;

		case ch_EnemyModels:
			Settings.bEnemyBasedModels = ch_EnemyModels.IsChecked();
			ChangeComboBoxCaption();
			if (!bUpdatingCrap)
				UpdateAllComponents();
			break;

		case co_TeamSelect:
			if (!bUpdatingCrap)
				UpdateAllComponents();
			break;

		case sl_RedSkin:
			if (Team == 0)
				Settings.RedTeammateUTCompSkinColor.R = sl_RedSkin.Value;
			else if (Team == 1)
				Settings.BlueEnemyUTCompSkinColor.R = sl_RedSkin.Value;

			if (!bUpdatingCrap)
				UpdateSpinnyDude();
			break;

		case sl_GreenSkin:
			if (Team == 0)
				Settings.RedTeammateUTCompSkinColor.G = sl_GreenSkin.Value;
			else if (Team == 1)
				Settings.BlueEnemyUTCompSkinColor.G = sl_GreenSkin.Value;

			if (!bUpdatingCrap)
				UpdateSpinnyDude();
			break;

		case sl_BlueSkin:
			if (Team == 0)
				Settings.RedTeammateUTCompSkinColor.B = sl_BlueSkin.Value;
			else if (Team == 1)
				Settings.BlueEnemyUTCompSkinColor.B = sl_BlueSkin.Value;

			if (!bUpdatingCrap)
				UpdateSpinnyDude();
			break;

		case co_EpicSkinSelect:
			if (Team == 0 && co_EpicSkinSelect.GetIndex() >= 0)
				Settings.PreferredSkinColorRedTeammate = co_EpicSkinSelect.GetIndex();
			else if (Team == 1 && co_EpicSkinSelect.GetIndex() >= 0)
				Settings.PreferredSkinColorBlueEnemy = co_EpicSkinSelect.GetIndex();

			if (!bUpdatingCrap)
			{
				UpdateAllComponents();
				UpdateSpinnyDude();
			}
			break;

		case co_TypeSkinSelect:
			if (Team == 0)
				Settings.ClientSkinModeRedTeammate = co_TypeSkinSelect.GetIndex()+1;
			else if (Team == 1)
				Settings.ClientSkinModeBlueEnemy = co_TypeSkinSelect.GetIndex()+1;

			if (!bUpdatingCrap)
				UpdateAllComponents();
			break;

		case ch_ForceThisModel:
			if (Team == 0)
				Settings.bRedTeammateModelsForced = ch_ForceThisModel.IsChecked();
			else if (Team == 1)
				Settings.bBlueEnemyModelsForced = ch_ForceThisModel.IsChecked();

			if (Ch_ForceThisModel.IsChecked())
				co_ModelSelect.EnableMe();
			else
				co_ModelSelect.DisableMe();
			break;

		case ch_DarkSkins:
			Settings.bEnableDarkSkinning = ch_DarkSkins.IsChecked();
			break;

		case co_ModelSelect:
			if (bUpdatingCrap)
				break;

			if (co_TeamSelect.GetIndex() == 0)
				Settings.RedTeammateModelName = co_ModelSelect.GetText();
			else if (co_TeamSelect.GetIndex() == 1)
				Settings.BlueEnemyModelName = co_ModelSelect.GetText();

			if (!bUpdatingCrap)
				UpdateSpinnyDude();
			break;
	}

	BS_xPlayer(PlayerOwner()).ReSkinAll();
	BS_xPlayer(PlayerOwner()).MatchHudColor();
	class'UTComp_xPawn'.static.StaticSaveConfig();
	SaveAll();
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
	if (Key == 0x1B)
		return false;

	if (co_TeamSelect.GetIndex() == 0)
		Settings.RedTeammateModelName = co_ModelSelect.GetText();
	else if (co_TeamSelect.GetIndex() == 1)
		Settings.BlueEnemyModelName = co_ModelSelect.GetText();

	ChangeComboBoxCaption();
	class'UTComp_xPawn'.static.StaticSaveConfig();
	SaveAll();
	UpdateSpinnyDude();

	return true;
}

function bool InternalOnClick(GUIComponent Sender)
{
	UpdateAllComponents();
	return Super.InternalOnClick(Sender);
}

function ChangeComboBoxCaption()
{
	local byte Team;

	InitializationComplete = false;

	Team = co_TeamSelect.GetIndex();

	co_TeamSelect.Clear();
	//Team Select Combobox
	if (ch_EnemySkins.IsChecked())
	{
		if (!ch_EnemyModels.IsChecked())
		{
			co_TeamSelect.AddItem("Teammates(Skins), Red(Models)");
			co_TeamSelect.AddItem("Enemies(Skins), Blue(Models)");
		}
		else
		{
			co_TeamSelect.AddItem("Teammates");
			co_TeamSelect.AddItem("Enemies");
		}
	}
	else
	{
		if (ch_EnemyModels.IsChecked())
		{
			co_TeamSelect.AddItem("Red(Skins), Teammates(Models)");
			co_TeamSelect.AddItem("Blue(Skins), Enemies(Models)");
		}
		else
		{
			co_TeamSelect.AddItem("Red Team");
			co_TeamSelect.AddItem("Blue Team");
		}
	}

	co_TeamSelect.SetIndex(Team);
	InitializationComplete = true;
}

function ResetComboBox()
{
}

function UpdateAllComponents()
{
	local byte Team;
	local byte SkinStyle;
	local UTComp_ServerReplicationInfo RepInfo;

	if (RepInfo == None)
	{
		foreach PlayerOwner().DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	Team = co_TeamSelect.GetIndex();
	bUpdatingCrap = true;

	if (Team == 0)
	{
		co_TypeSkinSelect.EnableMe();
		co_ModelSelect.EnableMe();

		co_TypeSkinSelect.SetIndex(Settings.ClientSkinModeRedTeammate-1);

		SkinStyle = co_TypeSkinSelect.GetIndex();

		if (SkinStyle < 2)
		{
			co_EpicSkinSelect.SetIndex(Settings.PreferredSkinColorRedTeammate);
			co_EpicSkinSelect.EnableMe();
			sl_RedSkin.DisableMe();
			sl_GreenSkin.DisableMe();
			sl_BlueSkin.DisableMe();
		}
		else
		{
			co_EpicSkinSelect.DisableMe();
			sl_RedSkin.EnableMe();
			sl_GreenSkin.EnableMe();
			sl_BlueSkin.EnableMe();
			co_EpicSkinSelect.SetIndex(-1);

			sl_RedSkin.SetValue(Settings.RedTeammateUTCompSkinColor.R);
			sl_GreenSkin.SetValue(Settings.RedTeammateUTCompSkinColor.G);
			sl_BlueSkin.SetValue(Settings.RedTeammateUTCompSkinColor.B);
		}
		co_ModelSelect.SetIndex(co_ModelSelect.FindIndex(Settings.RedTeammateModelName));
		ch_ForceThisModel.EnableMe();
		if (ch_EnemyModels.IsChecked())
			ch_ForceThismodel.mylabel.Caption = "Force Teammate Models";
		else
			ch_ForceThismodel.mylabel.Caption = "Force Red Models";
		ch_ForceThisModel.Checked(Settings.bRedTeammateModelsForced);
	}
	else if (Team == 1)
	{
		co_TypeSkinSelect.EnableMe();
		co_ModelSelect.EnableMe();

		co_TypeSkinSelect.SetIndex(Settings.ClientSkinModeBlueEnemy-1);

		SkinStyle = co_TypeSkinSelect.GetIndex();

		if (SkinStyle < 2)
		{
			co_EpicSkinSelect.SetIndex(Settings.PreferredSkinColorBlueEnemy);
			co_EpicSkinSelect.EnableMe();
			sl_RedSkin.DisableMe();
			sl_GreenSkin.DisableMe();
			sl_BlueSkin.DisableMe();
		}
		else
		{
			co_EpicSkinSelect.DisableMe();
			sl_RedSkin.EnableMe();
			sl_GreenSkin.EnableMe();
			sl_BlueSkin.EnableMe();

			sl_RedSkin.SetValue(Settings.BlueEnemyUTCompSkinColor.R);
			sl_GreenSkin.SetValue(Settings.BlueEnemyUTCompSkinColor.G);
			sl_BlueSkin.SetValue(Settings.BlueEnemyUTCompSkinColor.B);
		}
		co_ModelSelect.SetIndex(co_ModelSelect.FindIndex(Settings.BlueEnemyModelName));
		ch_ForceThisModel.EnableMe();
		if (ch_EnemyModels.IsChecked())
			ch_ForceThismodel.mylabel.Caption = "Force Enemy Models";
		else
			ch_ForceThismodel.mylabel.Caption = "Force Blue Models";
		ch_ForceThisModel.Checked(Settings.bBlueEnemyModelsForced);
	}
	else
	{
		sl_RedSkin.DisableMe();
		sl_GreenSkin.DisableMe();
		sl_BlueSkin.DisableMe();
		co_EpicSkinSelect.DisableMe();
		ch_ForceThisModel.DisableMe();
		co_ModelSelect.DisableMe();
		co_TypeSkinSelect.DisableMe();
	}

	if (ch_ForceThisModel.IsChecked())
		co_ModelSelect.EnableMe();
	else
		co_ModelSelect.DisableMe();

	UpdateSpinnyDude();
	bUpdatingCrap = false;
}

function AddComboBoxItems(GUIComboBox Combo)
{
	Combo.AddItem("Abaddon");
	Combo.AddItem("Ambrosia");
	Combo.AddItem("Annika");
	Combo.AddItem("Arclite");
	Combo.AddItem("Aryss");
	Combo.AddItem("Asp");
	Combo.AddItem("Axon");
	Combo.AddItem("Azure");
	Combo.AddItem("Baird");
	Combo.AddItem("Barktooth");
	Combo.AddItem("BlackJack");
	Combo.AddItem("Brock");
	Combo.AddItem("Brutalis");
	Combo.AddItem("Cannonball");
	Combo.AddItem("Cathode");
	Combo.AddItem("ClanLord");
	Combo.AddItem("Cleopatra");
	Combo.AddItem("Cobalt");
	Combo.AddItem("Corrosion");
	Combo.AddItem("Cyclops");
	Combo.AddItem("Damarus");
	Combo.AddItem("Diva");
	Combo.AddItem("Divisor");
	Combo.AddItem("Domina");
	Combo.AddItem("Dominator");
	Combo.AddItem("Drekorig");
	Combo.AddItem("Enigma");
	Combo.AddItem("Faraleth");
	Combo.AddItem("Fate");
	Combo.AddItem("Frostbite");
	Combo.AddItem("Gaargod");
	Combo.AddItem("Garrett");
	Combo.AddItem("Gkublok");
	Combo.AddItem("Gorge");
	Combo.AddItem("Greith");
	Combo.AddItem("Guardian");
	Combo.AddItem("Harlequin");
	Combo.AddItem("Horus");
	Combo.AddItem("Hyena");
	Combo.AddItem("Jakob");
	Combo.AddItem("Kaela");
	Combo.AddItem("Karag");
	Combo.AddItem("Kane");
	Combo.AddItem("Komek");
	Combo.AddItem("Kraagesh");
	Combo.AddItem("Kragoth");
	Combo.AddItem("Lauren");
	Combo.AddItem("Lilith");
	Combo.AddItem("Makreth");
	Combo.AddItem("Malcolm");
	Combo.AddItem("Mandible");
	Combo.AddItem("Matrix");
	Combo.AddItem("Memphis");
	Combo.AddItem("Mekkor");
	Combo.AddItem("Mokara");
	Combo.AddItem("Motig");
	Combo.AddItem("Mr.Crow");
	Combo.AddItem("Nebri");
	Combo.AddItem("Ophelia");
	Combo.AddItem("Othello");
	Combo.AddItem("Outlaw");
	Combo.AddItem("Prism");
	Combo.AddItem("Rae");
	Combo.AddItem("Rapier");
	Combo.AddItem("Ravage");
	Combo.AddItem("Reinha");
	Combo.AddItem("Remus");
	Combo.AddItem("Renegade");
	Combo.AddItem("Riker");
	Combo.AddItem("Roc");
	Combo.AddItem("Romulus");
	Combo.AddItem("Rylisa");
	Combo.AddItem("Sapphire");
	Combo.AddItem("Satin");
	Combo.AddItem("Scarab");
	Combo.AddItem("Selig");
	Combo.AddItem("Siren");
	Combo.AddItem("Skakruk");
	Combo.AddItem("Skrilax");
	Combo.AddItem("Subversa");
	Combo.AddItem("Syzygy");
	Combo.AddItem("Tamika");
	Combo.AddItem("Torch");
	Combo.AddItem("Thannis");
	Combo.AddItem("Thorax");
	Combo.AddItem("Virus");
	Combo.AddItem("Widowmaker");
	Combo.AddItem("Wraith");
	Combo.AddItem("Xan");
	Combo.AddItem("Zarina");
}

// begin spinny dude extra crap
function Free()
{
	Super.Free();

	if (SpinnyDude != None)
		SpinnyDude.Destroy();
	SpinnyDude = None;
}

function bool InternalOnDraw(canvas Canvas)
{
	local vector CamPos, X, Y, Z;
	local rotator CamRot;
	local float oOrgX, oOrgY;
	local float oClipX, oClipY;

   	oOrgX = Canvas.OrgX;
	oOrgY = Canvas.OrgY;
	oClipX = Canvas.ClipX;
	oClipY = Canvas.ClipY;

	Canvas.OrgX =SpinnyDudeBounds.ActualLeft();
	Canvas.OrgY =SpinnyDudeBounds.ActualTop();
	Canvas.ClipX =SpinnyDudeBounds.ActualWidth();
	Canvas.ClipY =SpinnyDudeBounds.ActualHeight();

	canvas.GetCameraLocation(CamPos, CamRot);
	GetAxes(CamRot, X, Y, Z);

	SpinnyDude.SetLocation(CamPos + (SpinnyDudeOffset.X * X) + (SpinnyDudeOffset.Y * Y) + (SpinnyDudeOffset.Z * Z));
	canvas.DrawActorClipped(SpinnyDude, false,  SpinnyDudeBounds.ActualLeft(), SpinnyDudeBounds.ActualTop(), SpinnyDudeBounds.ActualWidth(), SpinnyDudeBounds.ActualHeight(), true, 15);
	Canvas.OrgX = oOrgX;
	Canvas.OrgY = oOrgY;
	Canvas.ClipX = oClipX;
	Canvas.ClipY = oClipY;

	return true;
}

function UpdateSpinnyDude()
{
	local xUtil.PlayerRecord Rec;
	local Mesh PlayerMesh;
	local Material BodySkin, HeadSkin;
	local string BodySkinName, HeadSkinName, TeamSuffix;

	// Choose the model
	if (ch_ForceThisModel.IsChecked())
	{
		Rec = class'xutil'.static.FindPlayerRecord(class'UTComp_xPawn'.static.IsAcceptable(co_ModelSelect.GetText()));
	}
	else
	{
		if (PlayerOwner().PlayerReplicationInfo!=None)
			Rec = class'xutil'.static.FindPlayerRecord(PlayerOwner().PlayerReplicationInfo.CharacterName);
		else
			Rec =  class'xutil'.static.FindPlayerRecord("Gorge");
	}

	if (Rec.Race ~= "Juggernaut" || Rec.DefaultName ~= "Axon" || Rec.DefaultName ~= "Cyclops" || Rec.DefaultName ~= "Virus")
		SpinnyDudeOffset = vect(250.0, 1.00, -2.00);	// Z = -14.00
	else
		SpinnyDudeOffset = vect(250.0, 1.00, -1.00); // Z = -24.00

	PlayerMesh = Mesh(DynamicLoadObject(Rec.MeshName, class'Mesh'));
	if (PlayerMesh == None)
	{
		Log("Could not load mesh: "$Rec.MeshName$" for player: "$Rec.DefaultName);
		return;
	}

	// Get the body skin
	BodySkinName = Rec.BodySkinName;

	// Get the head skin
	HeadSkinName = Rec.FaceSkinName;
	if (Rec.TeamFace )
		HeadSkinName $= TeamSuffix;

	BodySkin = ChangeColorOfSkin(Material(DynamicLoadObject(BodySkinName, class'Material')), 0);
	if (BodySkin == None)
	{
		Log("Could not load body material: "$Rec.BodySkinName$" for player: "$Rec.DefaultName);
		return;
	}

	HeadSkin = ChangeColorOfSkin(Material(DynamicLoadObject(HeadSkinName, class'Material')), 1);
	if (HeadSkin == None)
	{
		Log("Could not load head material: "$HeadSkinName$" for player: "$Rec.DefaultName);
		return;
	}

	if (SpinnyDude != None)
	{
		SpinnyDude.LinkMesh(PlayerMesh);
		SpinnyDude.Skins[0] = BodySkin;
		SpinnyDude.Skins[1] = HeadSkin;
		SpinnyDude.LoopAnim('Idle_Rest', 1.0/SpinnyDude.Level.TimeDilation);
	}
}

simulated function Material ChangeColorOfSkin(Material SkinToChange, byte SkinNum)
{
	local byte SkinMode;

	SkinMode = co_TypeSkinSelect.GetIndex();
	switch(SkinMode)
	{
		case 0:
			SpinnyDude.bUnlit = false;
			return ChangeOnlyColor(SkinToChange);
		case 1:
			SpinnyDude.bUnlit = true;
			return ChangeColorAndBrightness(SkinToChange, SkinNum);
		case 2:
			SpinnyDude.bUnlit = true;
			return ChangeToUTCompSkin(SkinToChange, SkinNum);
	}
	return SkinToChange;
}

simulated function Material ChangeOnlyColor(Material SkinToChange)
{
	local byte ColorMode;
	local byte OtherColorMode;

	if (co_TeamSelect.GetIndex() == 1)
	{
		ColorMode = Settings.PreferredSkinColorBlueEnemy;
		OtherColorMode = Settings.PreferredSkinColorRedTeammate;
	}
	else if (co_TeamSelect.GetIndex() == 0)
	{
		ColorMode = Settings.PreferredSkinColorRedTeammate;
		OtherColorMode = Settings.PreferredSkinColorBlueEnemy;
	}
	else
	{
		return SkinToChange;
	}

	if (ColorMode > 3)
		ColorMode -= 4;
	if (OtherColorMode > 3)
		OtherColorMode -= 4;

	switch(ColorMode)
	{
		case 0:
			return class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);
		case 1:
			return class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
		case 2:
			return class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
		case 3:
			if (OtherColorMode < 2)
				return class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
			else
				return class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
	}
	return SkinToChange;
}

simulated function Material ChangeColorAndBrightness(Material SkinToChange, int SkinNum)
{
	local byte ColorMode;

	if (co_TeamSelect.GetIndex() == 1)
		ColorMode = Settings.PreferredSkinColorBlueEnemy;
	else if (co_TeamSelect.GetIndex() == 0)
		ColorMode = Settings.PreferredSkinColorRedTeammate;

	switch(ColorMode)
	{
		case 0:
			return class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);
			break;
		case 1:
			return class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
			break;
		case 2:
			return class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
			break;
		case 3:
			return MakePurpleSkin(SkinToChange);
			break;
		case 4:
			if (SkinNum == 1)
				return class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);
			return class'UTComp_xPawn'.static.MakeBrightDMSkin(SkinToChange);
			break;
		case 5:
			if (SkinNum == 1)
				return class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
			return class'UTComp_xPawn'.static.MakeBrightRedSkin(SkinToChange);
			break;
		case 6:
			if (SkinNum == 1)
				return class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
			return class'UTComp_xPawn'.static.MakeBrightBlueSkin(SkinToChange);
			break;
		case 7:
			if (SkinNum == 1)
				return SkinToChange;
			return MakeBrightPurpleSkin(SkinToChange);
			break;
	}
}

simulated function Material ChangeToUTCompSkin(Material SkinToChange, byte SkinNum)
{
	local Combiner C;
	local ConstantColor CC;

	if (SkinNum > 0)
		return class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);

	C = New(None) Class'Combiner';
	CC = New(None) Class'ConstantColor';

	C.CombineOperation = CO_Add;
	C.Material1 = class'UTComp_xPawn'.static.MakeDMSkin(SkinToChange);
	CC.Color.R = sl_RedSkin.Value;
	CC.Color.G = sl_GreenSkin.Value;
	CC.Color.B = sl_BlueSkin.Value;
	C.Material2 = CC;

	if (C != None)
		return C;
}

simulated function Material MakePurpleSkin(Material SkinToChange)
{
	local Combiner C;
	local Combiner C2;

	C = New(None) class'Combiner';
	C2 = New(None) class'Combiner';
	C.CombineOperation = CO_Subtract;
	C.Material1 = class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
	C.Material2 = class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
	C2.CombineOperation = CO_Add;
	C2.Material1 = C;
	C2.Material2 = C.Material1;

	if (Texture(C.Material1) != None)
		return C2;
	else
		return ChangeOnlyColor(SkinToChange);
}

simulated function Material MakeBrightPurpleSkin(Material SkinToChange)
{
	local Combiner C;

	C = New(None) class'Combiner';
	C.CombineOperation = CO_Add;
	C.Material1 = class'UTComp_xPawn'.static.MakeRedSkin(SkinToChange);
	C.Material2 = class'UTComp_xPawn'.static.MakeBlueSkin(SkinToChange);
	if (Texture(C.Material1) != None)
		return C;
	else
		return ChangeOnlyColor(SkinToChange);
}

defaultproperties
{
	Begin Object Class=moCheckBox Name=EnemyBasedSkinCheck
		Caption="Enemy Based Skins"
		OnCreateComponent=EnemyBasedSkinCheck.InternalOnCreateComponent
		WinTop=0.125000
		WinLeft=0.225000
		WinWidth=0.200000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
	End Object
	ch_EnemySkins=moCheckBox'UTComp_Menu_BrightSkins.EnemyBasedSkinCheck'

	Begin Object Class=GUIComboBox Name=TeamSelectCombo
		WinTop=0.250000
		WinLeft=0.250000
		WinWidth=0.450000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
		OnKeyEvent=TeamSelectCombo.InternalOnKeyEvent
	End Object
	co_TeamSelect=GUIComboBox'UTComp_Menu_BrightSkins.TeamSelectCombo'

	Begin Object Class=GUIComboBox Name=TypeSkinSelectCombo
		WinTop=0.400000
		WinLeft=0.250000
		WinWidth=0.220000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
		OnKeyEvent=TypeSkinSelectCombo.InternalOnKeyEvent
	End Object
	co_TypeSkinSelect=GUIComboBox'UTComp_Menu_BrightSkins.TypeSkinSelectCombo'

	Begin Object Class=GUIComboBox Name=ModelSelectCombo
		WinTop=0.800000
		WinLeft=0.250000
		WinWidth=0.450000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
		OnKeyEvent=UTComp_Menu_BrightSkins.InternalOnKeyEvent
	End Object
	co_ModelSelect=GUIComboBox'UTComp_Menu_BrightSkins.ModelSelectCombo'

	Begin Object Class=GUIComboBox Name=EpicSkinSelectCombo
		WinTop=0.400000
		WinLeft=0.480000
		WinWidth=0.220000
		WinHeight=0.050000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
		OnKeyEvent=EpicSkinSelectCombo.InternalOnKeyEvent
	End Object
	co_EpicSkinSelect=GUIComboBox'UTComp_Menu_BrightSkins.EpicSkinSelectCombo'

	Begin Object Class=GUIImage Name=spinnydudeboundsimage
		Image=Texture'2K4Menus.Controls.buttonSquare_b'
		DropShadow=Texture'2K4Menus.Controls.Shadow'
		ImageColor=(A=128)
		ImageStyle=ISTY_Stretched
		DropShadowX=4
		DropShadowY=4
		WinTop=0.199000
		WinLeft=0.750000
		WinWidth=0.250000
		WinHeight=0.800000
		RenderWeight=0.520000
		bBoundToParent=true
		bScaleToParent=true
		OnDraw=UTComp_Menu_BrightSkins.InternalOnDraw
	End Object
	SpinnyDudeBounds=GUIImage'UTComp_Menu_BrightSkins.spinnydudeboundsimage'

	Begin Object Class=GUI_Slider Name=RedSkinSlider
		MaxValue=128.000000
		bIntSlider=True
		StyleName="sl_knob_r"
		WinTop=0.530000
		WinLeft=0.275000
		WinWidth=0.400000
		WinHeight=0.035000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=RedSkinSlider.InternalOnClick
		OnMousePressed=RedSkinSlider.InternalOnMousePressed
		OnMouseRelease=RedSkinSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
		OnKeyEvent=RedSkinSlider.InternalOnKeyEvent
		OnCapturedMouseMove=RedSkinSlider.InternalCapturedMouseMove
	End Object
	sl_RedSkin=GUI_Slider'UTComp_Menu_BrightSkins.RedSkinSlider'

	Begin Object Class=GUI_Slider Name=GreenSkinSlider
		MaxValue=128.000000
		bIntSlider=True
		StyleName="sl_knob_g"
		WinTop=0.600000
		WinLeft=0.275000
		WinWidth=0.400000
		WinHeight=0.035000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=GreenSkinSlider.InternalOnClick
		OnMousePressed=GreenSkinSlider.InternalOnMousePressed
		OnMouseRelease=GreenSkinSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
		OnKeyEvent=GreenSkinSlider.InternalOnKeyEvent
		OnCapturedMouseMove=GreenSkinSlider.InternalCapturedMouseMove
	End Object
	sl_GreenSkin=GUI_Slider'UTComp_Menu_BrightSkins.GreenSkinSlider'

	Begin Object Class=GUI_Slider Name=BlueSkinSlider
		MaxValue=128.000000
		bIntSlider=True
		StyleName="sl_knob_b"
		WinTop=0.670000
		WinLeft=0.275000
		WinWidth=0.400000
		WinHeight=0.035000
		bBoundToParent=true
		bScaleToParent=true
		OnClick=BlueSkinSlider.InternalOnClick
		OnMousePressed=BlueSkinSlider.InternalOnMousePressed
		OnMouseRelease=BlueSkinSlider.InternalOnMouseRelease
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
		OnKeyEvent=BlueSkinSlider.InternalOnKeyEvent
		OnCapturedMouseMove=BlueSkinSlider.InternalCapturedMouseMove
	End Object
	sl_BlueSkin=GUI_Slider'UTComp_Menu_BrightSkins.BlueSkinSlider'

	Begin Object Class=moCheckBox Name=ForceThisModelCheck
		Caption="Force This Model"
		OnCreateComponent=ForceThisModelCheck.InternalOnCreateComponent
		WinTop=0.750000
		WinLeft=0.350000
		WinWidth=0.250000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
	End Object
	ch_ForceThisModel=moCheckBox'UTComp_Menu_BrightSkins.ForceThisModelCheck'

	Begin Object Class=moCheckBox Name=DarkSkinCheck
		Caption="Darken Dead Bodies"
		OnCreateComponent=DarkSkinCheck.InternalOnCreateComponent
		WinTop=0.125000
		WinLeft=0.775000
		WinWidth=0.200000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
	End Object
	ch_DarkSkins=moCheckBox'UTComp_Menu_BrightSkins.DarkSkinCheck'

	Begin Object Class=moCheckBox Name=EnemyBasedModelCheck
		Caption="Enemy Based Models"
		OnCreateComponent=EnemyBasedSkinCheck.InternalOnCreateComponent
		WinTop=0.125000
		WinLeft=0.500000
		WinWidth=0.200000
		bBoundToParent=true
		bScaleToParent=true
		OnChange=UTComp_Menu_BrightSkins.InternalOnChange
	End Object
	ch_EnemyModels=moCheckBox'UTComp_Menu_BrightSkins.EnemyBasedModelCheck'
}