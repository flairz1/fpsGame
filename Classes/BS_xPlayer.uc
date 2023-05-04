class BS_xPlayer extends xPlayer
	Config(fpsGameClient);

var float LastHitSoundTime;

var bool bInitiated;	// PlayerTick
var bool ClientChangedScoreboard;
var bool bWantsStats;
var bool bShowOldScoreboard;

var Sound LoadedEnemySound, LoadedFriendlySound;

var UTComp_ServerReplicationInfo RepInfo;
var UTComp_PRI UTCompPRI;

var xWeaponBase OldFoundWep;
var Controller LastViewedController;

// for Coloured Names
var Color MessageRed, MessageGreen, MessageBlue, MessageYellow, MessageGray;

var float LastBroadcastVoteTime;

// stats Variables
struct WepStats
{
	var string WepName;
	var class<DamageType> DamageType;
	var int Hits;
	var int Percent;
	var int Damage;
};
var array<WepStats> CustomWepStats;
var array<WepStats> NormalWepStatsPrim;	//14
var array<WepStats> NormalWepStatsAlt;	//14
var localized string WepStatNames[15];
var int DamG;

var class<DamageType> WepStatDamTypesAlt[15];
var class<DamageType> WepStatDamTypesPrim[15];

struct DamTypeGrouping
{
	var string WepName;
	var string DamType[6];
};
var array<DamTypeGrouping> CustomWepTypes;

const HITSOUNDTWEENTIME = 0.05;

var bool bWaitingOnGrouping;
var bool bWaitingEnemy;
var int DelayedDamageTotal;
var float WaitingOnGroupingTime;

var float errorsamples, totalerror;
var bool bDisableSpeed, bDisableBooster, bDisableInvis, bDisableBerserk;
var bool bSpecingViewGoal;

var vector PlayerMouse;
var float LastHUDSizeX, LastHUDSizeY;
var UTComp_Overlay Overlay;
var UTComp_PRI currentStatDraw;

var bool bUseSlopeAlgorithm;

// Fractional parts of Pitch/Yaw Input
var transient float PitchFraction, YawFraction;

var transient PlayerInput NewInput;
var float TimeBetweenUpdates;

var UTComp_Settings Settings;
var UTComp_HudSettings HudS;

var float LastWeaponEffectSent;

replication
{
	unreliable if (Role == ROLE_Authority)
		ReceiveHit, ReceiveStats, ReceiveHitSound;

	reliable if (Role == ROLE_Authority)
		TimeBetweenUpdates;

	reliable if (Role < ROLE_Authority)
		SetBStats, TurnOffNetCode, ServerSetEyeHeightAlgorithm, ServerSetNetUpdateRate;

	unreliable if (Role < ROLE_Authority)
		ServerNextPlayer, ServerGoToPlayer, ServerGoToWepBase, ServerGoToTarget, CallVote;

	reliable if (Role < ROLE_Authority)
		BroadCastVote;

	unreliable if (Role < ROLE_Authority)
		RequestStats;

	unreliable if (Role == ROLE_Authority)
		SendHitPrim, SendHitAlt, SendFiredPrim, SendFiredAlt, SendDamagePrim, SendDamageAlt, SendDamageGR, SendPickups;

	unreliable if (Role < ROLE_Authority)
		UTComp_ServerMove, UTComp_DualServerMove, UTComp_ShortServerMove;

	reliable if (RemoteRole == ROLE_AutonomousProxy)
		ReceiveWeaponEffect;
}

simulated function SaveSettings()
{
	Log("Saving settings (from BS_xPlayer)");
	Settings.SaveConfig();
	HudS.SaveConfig();
	StaticSaveConfig();
}

exec function SetEnemySkinColor(string S)
{
	local array<string> Parts;

	Split(S, " ", Parts);

	if (Parts.Length >= 3)
	{
		Settings.BlueEnemyUTCompSkinColor.R = byte(Parts[0]);
		Settings.BlueEnemyUTCompSkinColor.G = byte(Parts[1]);
		Settings.BlueEnemyUTCompSkinColor.B = byte(Parts[2]);
		SaveSettings();
	}
	else
	{
		echo("Invalid command, need 3 colours");
	}
}

exec function SetFriendSkinColor(string S)
{
	local array<string> Parts;

	Split(S, " ", Parts);
	if (Parts.Length >= 3)
	{
		Settings.RedTeammateUTCompSkinColor.R = byte(Parts[0]);
		Settings.RedTeammateUTCompSkinColor.G = byte(Parts[1]);
		Settings.RedTeammateUTCompSkinColor.B = byte(Parts[2]);
		SaveSettings();
	}
	else
	{
		echo("Invalid command, need 3 colours");
	}
}

exec function SetBlueSkinColor(string S)
{
	SetEnemySkinColor(S);
}

exec function SetRedSkinColor(string S)
{
	SetFriendSkinColor(S);
}

exec function SetStats(int i)
{}

function ClientSetNetSpeed(int NewInt)
{
	local int MinVal, MaxVal;

	MinVal = class'MutUTComp'.default.MinNetSpeed;
	MaxVal = class'MutUTComp'.default.MaxNetSpeed;
	if (Role < ROLE_Authority)
	{
		Settings.DesiredNetSpeed = NewInt;
		SaveSettings();
		SetNetSpeed(Clamp(NewInt, MinVal, MaxVal));
	}
}

function ServerSetNetUpdateRate(float Rate, int NetSpeed)
{
	local float MinRate, MaxRate;

	MaxRate = class'MutUTComp'.default.MaxNetUpdateRate;
	if (NetSpeed != 0)
		MaxRate = FMin(MaxRate, NetSpeed/100.0);

	MinRate = class'MutUTComp'.default.MinNetUpdateRate;

	TimeBetweenUpdates = 1.0 / FClamp(Rate, MinRate, MaxRate);
}

exec function SetNetUpdateRate(float Rate)
{
	Settings.DesiredNetUpdateRate = Rate;
	SaveSettings();
	ServerSetNetUpdateRate(Rate, Player.CurrentNetSpeed);
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	AssignStatNames();
	ChangeDeathMessageOrder();

	foreach AllObjects(class'UTComp_Settings', Settings)
		break;

	if (Settings == none)
	{
		Settings = new(none, "ClientSettings") class'UTComp_Settings';
		Settings.CheckSettings();
	}

	foreach AllObjects(class'UTComp_HudSettings', HudS)
		break;

	if (HudS == none)
		HudS = new(none, "ClientHudSettings") class'UTComp_HudSettings';
}

event InitInputSystem()
{
	Super.InitInputSystem();

	FindPlayerInput();
}

function FindPlayerInput()
{
	local PlayerInput PIn;
	local PlayerInput PInAlt;

	foreach AllObjects(class'PlayerInput', PIn)
	{
		if (PIn.Outer == self)
		{
			PInAlt = PIn;
			if (InStr(PIn, ".PlayerInput") < 0)
				NewInput = PIn;
		}
	}

	if (NewInput == none)
		NewInput = PInAlt;
}

simulated function ChangeDeathMessageOrder()
{
	if (class'Crushed'.default.DeathString ~="%o was crushed by %k.")
	{
		class'DamTypeHoverBikeHeadshot'.default.DeathString = "%o was run over by %k";
		class'DamRanOver'.default.DeathString = "%o was run over by %k";
		class'DamTypeHoverBikePlasma'.default.DeathString = "%o was killed by %k with a Manta's Plasma.";
		class'DamTypeONSAvriLRocket'.default.DeathString = "%o was blown away by %k with an Avril.";
		class'DamTypeONSVehicleExplosion'.default.DeathString = "%o was taken out by %k with a vehicle explosion.";
		class'DamTypePRVLaser'.default.DeathString = "%o was laser shocked by %k";
		class'DamTypeRoadkill'.default.DeathString = "%o was run over by %k";
		class'DamTypeTankShell'.default.DeathString = "%o was blown into flaming bits by %k's tank shell.";
		class'DamTypeTurretBeam'.default.DeathString = "%o was turret electrivied by %k.";
		class'DamTypeMASPlasma'.default.DeathString = "%o was plasmanted by %k's Leviathan turret.";
		class'DamTypeClassicHeadshot'.default.DeathString = "%o's skull was blown apart by %k's Sniper Rifle.";
		class'DamTypeClassicSniper'.default.DeathString = "%o was killed by %k with a Sniper Rifle";
	}
}

event PlayerTick(float deltaTime)
{
	if (RepInfo == none)
	{
		foreach DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	if (UTCompPRI == none)
		UTCompPRI = class'UTComp_Util'.static.GetUTCompPRIFor(self);

	if (
		Level.NetMode != NM_DedicatedServer
		&& !bInitiated
		&& PlayerReplicationInfo != none
		&& PlayerReplicationInfo.CustomReplicationInfo != none
		&& myHud != none
		&& RepInfo != none
		&& UTCompPRI != none
	)
	{
		InitializeStuff();
		bInitiated = true;
	}

	if (bWaitingOnGrouping)
	{
		if (Level.TimeSeconds > WaitingOnGroupingTime)
		{
			DelayedHitSound(DelayedDamageTotal, bWaitingEnemy);
			bWaitingOnGrouping = false;
		}
	}

	if (DoubleClickDir == DCLICK_Active && UTComp_xPawn(Pawn) != none && UTComp_xPawn(Pawn).MultiDodgesRemaining > 0)
	{
		UTComp_xPawn(Pawn).MultiDodgesRemaining -= 1;
		DoubleClickDir = DCLICK_None;
	}

	if (Level.NetMode == NM_Client && RepInfo != none)
	{
		if (Player.CurrentNetSpeed > RepInfo.MaxNetSpeed)
			SetNetSpeed(RepInfo.MaxNetSpeed);
		else if (Player.CurrentNetSpeed < RepInfo.MinNetSpeed)
			SetNetSpeed(RepInfo.MinNetSpeed);
	}

	if (myHud != none && myHud.bShowScoreBoard && !bShowOldScoreboard)
	{
		StatMine();
	}
	bShowOldScoreboard = myHud.bShowScoreBoard;

	Super.PlayerTick(deltaTime);
}

function SetBStats(bool b)
{
	bWantsStats = b;
	if (UTCompPRI == None)
		UTCompPRI = class'UTComp_Util'.static.GetUTCompPRIFor(self);

	if (UTCompPRI != None)
		UTCompPRI.bSendWepStats = b;
}

simulated function InitializeStuff()
{
	InitializeScoreboard();
	SetInitialColoredName();
	SetShowSelf(Settings.bShowSelfInTeamOverlay);
	SetBStats(class'UTComp_Scoreboard'.default.bDrawStats || class'UTComp_ScoreBoard'.default.bOverrideDisplayStats);
	SetEyeHeightAlgorithm(Settings.bUseSlopeAlgorithm);
	ServerSetNetUpdateRate(Settings.DesiredNetUpdateRate, Player.CurrentNetSpeed);
	ClientSetNetSpeed(Settings.DesiredNetSpeed);

	if (Settings.bFirstRun)
	{
		Settings.bFirstRun = false;
		ConsoleCommand("set input f5 myMenu");
		if (!class'DeathMatch'.default.bForceDefaultCharacter)
		{
			Settings.bRedTeammateModelsForced = false;
			Settings.bBlueEnemyModelsForced = false;
			class'UTComp_xPawn'.static.StaticSaveConfig();
		}
		else
		{
			Settings.BlueEnemyModelName = class'xGame.xPawn'.default.PlacedCharacterName;
			Settings.RedTeammateModelName = class'xGame.xPawn'.default.PlacedCharacterName;
			class'UTComp_xPawn'.static.StaticSaveConfig();
		}
		SaveSettings();
	}
	MatchHudColor();
}

simulated function InitializeScoreboard()
{
	local class<Scoreboard> NewScoreboardClass;

	if (myHud != None && UTComp_ScoreBoard(myHud.ScoreBoard) != None && GameReplicationInfo != None)
	{
		if (Settings.bUseDefaultScoreboard)
		{
			if (Invasion(Level.Game) != none)
				NewScoreboardClass = class'UTComp_ScoreBoardDM';

			ClientChangedScoreboard = true;
		}
	}
	else if (ClientChangedScoreboard && !Settings.bUseDefaultScoreboard)
	{
			NewScoreboardClass = class'UTComp_ScoreBoard';
	}

	if (myHud != None && NewScoreBoardClass != None)
		myHud.SetScoreBoardClass(NewScoreboardClass);
}

simulated function SetInitialColoredName()
{
	SetColoredNameOldStyle();
}

state GameEnded
{
	function BeginState()
	{
		Super.BeginState();

		if (Level.NetMode == NM_DedicatedServer)
			return;

		SetTimer(0.5, false);

		if (myHud != none)
			myHud.bShowScoreBoard = true;
	}

	function Timer()
	{
		Super.Timer();
	}
}

// stats and hitsounds
simulated function ReceiveHit(class<DamageType> DamageType, int Damage, Pawn Injured)
{
	if (Level.NetMode == NM_DedicatedServer)
		return;

	if (Injured != None && Injured.Controller != None && Injured.Controller == Self)
	{
		RegisterSelfHit(DamageType, Damage);
	}
	else if (Injured.GetTeamNum() == 255 || (Injured.GetTeamNum() != GetTeamNum()))
	{
		RegisterEnemyHit(DamageType, Damage);
		if (Settings.bCPMAStyleHitsounds && (DamageType == class'DamTypeFlakChunk' || DamageType == class'DamTypeFlakShell') && (RepInfo == None || RepInfo.i_Hitsounds == 2 || LineOfSightTo(Injured)))
			GroupDamageSound(DamageType, Damage, true);
		else if (RepInfo == None || RepInfo.i_Hitsounds == 2 || LineOfSightTo(Injured) || IsHitScan(DamageType))
			PlayEnemyHitSound(Damage);
	}
	else
	{
		RegisterTeammateHit(DamageType, Damage);
		if (Settings.bCPMAStyleHitsounds && (DamageType == class'DamTypeFlakChunk' || DamageType == class'DamTypeFlakShell') && (RepInfo == None || RepInfo.i_Hitsounds == 2 || LineOfSightTo(Injured)))
			GroupDamageSound(DamageType, Damage, false);
		else if (RepInfo == None || RepInfo.i_Hitsounds == 2 || LineOfSightTo(Injured) || IsHitScan(DamageType))
			PlayTeammateHitSound(Damage);
	}
}

simulated function ServerReceiveHit(class<DamageType> DamageType, int Damage, Pawn Injured)
{
	if (Injured != None && Injured.Controller != None && Injured.Controller == Self)
		ServerRegisterSelfHit(DamageType, Damage);
	else if (Injured.GetTeamNum() == 255 || (Injured.GetTeamNum() != GetTeamNum()))
		ServerRegisterEnemyHit(DamageType, Damage);
	else
		ServerRegisterTeammateHit(DamageType, Damage);
}

simulated function bool IsHitScan(class<DamageType> DamageType)
{
	return (
		DamageType == class'XWeapons.DamTypeSuperShockBeam' ||
		DamageType == class'XWeapons.DamTypeLinkShaft' ||
		DamageType == class'XWeapons.DamTypeSuperShockBeam' ||
		DamageType == Class'XWeapons.DamTypeSniperShot' ||
		DamageType == class'XWeapons.DamTypeMinigunBullet' ||
		DamageType == class'XWeapons.DamTypeShockBeam' ||
		DamageType == class'XWeapons.DamTypeAssaultBullet' ||
		DamageType == class'XWeapons.DamTypeShieldImpact' ||
		DamageType == class'XWeapons.DamTypeMinigunAlt' ||
		DamageType == class'DamTypeSniperHeadShot' ||
		DamageType == class'DamTypeClassicHeadshot' ||
		DamageType == class'DamTypeClassicSniper'
	);
}

simulated function ReceiveStats(class<DamageType> DamageType, int Damage, Pawn Injured)
{
	if (Level.NetMode == NM_DedicatedServer)
		return;

	if (Injured.Controller != None && Injured.Controller == Self)
		RegisterSelfHit(DamageType, Damage);
	else if (Injured.GetTeamNum() == 255 || (Injured.GetTeamNum() != GetTeamNum()))
		RegisterEnemyHit(DamageType, Damage);
	else
		RegisterTeammateHit(DamageType, Damage);
}

simulated function GroupDamageSound(class<DamageType> DamageType, int Damage, bool bEnemy)
{
	bWaitingOnGrouping = true;
	bWaitingEnemy = bEnemy;
	DelayedDamageTotal += Damage;
	WaitingOnGroupingTime = Level.TimeSeconds + 0.030;
}

simulated function DelayedHitSound(int Damage, bool bEnemy)
{
	if (bEnemy)
		PlayEnemyHitSound(Damage);
	else
		PlayTeammateHitSound(Damage);
	DelayedDamageTotal = 0;
}

// only hitsound, LOS check done in gamerules
simulated function ReceiveHitSound(int Damage, byte iTeam)
{
	if (Level.NetMode == NM_DedicatedServer)
		return;

	if (bBehindView)
		return;

	if (iTeam == 1)
		PlayEnemyHitSound(Damage);
	else if (iTeam == 2)
		PlayTeammateHitSound(Damage);
}

simulated function RegisterSelfHit(class<DamageType> DamageType, int Damage)
{}

simulated function ServerRegisterSelfHit(class<DamageType> DamageType, int Damage)
{}

simulated function RegisterEnemyHit(class<DamageType> DamageType, int Damage)
{
	local int i, j, k;

	if (DamageType == None)
		return;

	DamG += Damage;
	for(i = 0; i <= 14; i++)
	{
		if (DamageType == WepStatDamTypesPrim[i])
		{
			NormalWepStatsPrim[i].Hits += 1;
			NormalWepStatsPrim[i].Damage += Damage;
			return;
		}
		else if (DamageType == WepStatDamTypesAlt[i])
		{
			NormalWepStatsAlt[i].Hits += 1;
			NormalWepStatsAlt[i].Damage += Damage;
			return;
		}
		else if (DamageType == class'DamTypeSniperHeadShot' || DamageType == class'DamTypeClassicHeadshot' || DamageType == class'DamTypeClassicSniper')
		{
			NormalWepStatsPrim[5].Hits += 1;
			NormalWepStatsPrim[5].Damage += Damage;

			if (DamageType != class'DamTypeClassicSniper')
			{
				NormalWepStatsAlt[5].Hits += 1;
			}
			return;
		}
	}
	// custom weapon stats
	for(i = 0; i < CustomWepStats.Length; i++)
	{
		if (CustomWepStats[i].WepName != "")
		{
			for(j = 0; j < CustomWepTypes.Length; j++)
			{
				for(k = 0; k < ArrayCount(CustomWepTypes[j].DamType); k++)
				{
					if ((CustomWepTypes[j].DamType[k] != "" && InstrNonCaseSensitive(string(DamageType), CustomWepTypes[j].DamType[k])) && CustomWepTypes[j].WepName ~= CustomWepStats[i].WepName)
					{
						CustomWepStats[i].Hits += 1;
						CustomWepStats[i].Damage += Damage;
						return;
					}
				}
			}
		}
	
		if (DamageType == CustomWepStats[i].DamageType)
		{
			CustomWepStats[i].Hits += 1;
			CustomWepStats[i].Damage += Damage;
			return;
		}
	}

	i = CustomWepStats.Length+1;
	CustomWepStats.Length = i;
	for(j = 0; j < CustomWepTypes.Length; j++)
	{
		for(k = 0; k < ArrayCount(CustomWepTypes[j].DamType); k++)
		{
			if ((CustomWepTypes[j].DamType[k] != "" && InstrNonCaseSensitive(string(DamageType), CustomWepTypes[j].DamType[k])))
				CustomWepStats[i-1].WepName = CustomWepTypes[j].WepName;
		}
	}
	CustomWepStats[i-1].DamageType = DamageType;
	CustomWepStats[i-1].Damage = Damage;
	CustomWepStats[i-1].Hits = 1;
}

simulated function ServerRegisterEnemyHit(class<DamageType> DamageType, int Damage)
{
	local int i;

	if (DamageType == None || UTCompPRI == None)
		return;

	UTCompPRI.DamG += Damage;
	for(i = 0; i <= 14; i++)
	{
		if (DamageType == WepStatDamTypesPrim[i])
		{
			UTCompPRI.NormalWepStatsPrimHit[i] += 1;
			UTCompPRI.NormalWepStatsPrimDamage[i] += Damage;
			return;
		}
		else if (DamageType == WepStatDamTypesAlt[i])
		{
			UTCompPRI.NormalWepStatsAltHit[i] += 1;
			UTCompPRI.NormalWepStatsAltDamage[i] += Damage;
			return;
		}
		else if (DamageType == class'DamTypeSniperHeadShot' || DamageType == class'DamTypeClassicHeadshot' || DamageType == class'DamTypeClassicSniper')
		{
			UTCompPRI.NormalWepStatsPrimHit[5] += 1;
			UTCompPRI.NormalWepStatsPrimDamage[5] += Damage;

			if (DamageType != class'DamTypeClassicSniper')
			{
				UTCompPRI.NormalWepStatsAltHit[5] += 1;
			}
			return;
		}
	}
}

exec function StatMine()
{
	if (PlayerReplicationInfo == None || !PlayerReplicationInfo.bOnlySpectator)
		currentStatDraw = UTCompPRI;
	else
		StatSpec();
}

exec function StatSpec()
{
	if (ViewTarget == none)
	{
		StatNext();
		return;
	}

	if (Pawn(ViewTarget) != None && Pawn(ViewTarget).PlayerReplicationInfo != None && !Pawn(ViewTarget).PlayerReplicationInfo.bBot)
		currentStatDraw =  class'UTComp_Util'.static.GetUTCompPRI(Pawn(ViewTarget).PlayerReplicationInfo);

	if (currentStatDraw == None)
		StatNext();
	else
		RequestStats(currentStatDraw);
}

exec function StatNext()
{
	local UTComp_PRI uPRI, sPRI;
	local PlayerReplicationInfo PRI;
	local bool bUseNext;
	local int i;

	if (GameReplicationInfo == None)
		return;

	sPRI = currentStatDraw;
	if (currentStatDraw == None)
	{
		for(i = 0; i < GameReplicationInfo.PRIArray.length; i++)
		{
			PRI = GameReplicationInfo.PRIArray[i];
			uPRI = class'UTComp_Util'.static.GetUTCompPRI(GameReplicationInfo.PRIArray[i]);
			if (uPRI != None && uPRI != UTCompPRI && !PRI.bBot && !PRI.bOnlySpectator)
			{
				currentStatDraw = uPRI;
				break;
			}
		}
	}
	else
	{
		for(i = 0; i < GameReplicationInfo.PRIArray.length; i++)
		{
			uPRI = class'UTComp_Util'.static.GetUTCompPRI(GameReplicationInfo.PRIArray[i]);
			PRI = GameReplicationInfo.PRIArray[i];
			if (bUseNext && !PRI.bBot && !PRI.bOnlySpectator)
			{
				currentStatDraw = uPRI;
				bUseNext = false;
				break;
			}

			if (currentStatDraw == uPRI)
				bUseNext = true;
		}

		if (bUseNext)
		{
			for(i = 0; i < GameReplicationInfo.PRIArray.length; i++)
			{
				uPRI = class'UTComp_Util'.static.GetUTCompPRI(GameReplicationInfo.PRIArray[i]);
				PRI = GameReplicationInfo.PRIArray[i];
				if (!PRI.bBot && !PRI.bOnlySpectator)
					currentStatDraw = uPRI;
				break;
			}
		}
	}

	if (sPRI != None && currentStatDraw == sPRI)
	{
		currentStatDraw = none;
		StatNext();
		return;
	}

	if (UTCompPRI != currentStatDraw && currentStatDraw != None)
		RequestStats(currentStatDraw);
}

simulated function RequestStats(UTComp_PRI uPRI)
{
	local string S;
	local int i;

	if (uPRI == None)
		return;

	S = "";
	for(i = 0; i < ArrayCount(uPRI.NormalWepStatsPrimHit); i++)
	{
		if (i == 0)
			S = S$uPRI.NormalWepStatsPrimHit[i];
		else
			S = S@uPRI.NormalWepStatsPrimHit[i];
	}
	SendHitPrim(S, uPRI);

	S = "";
	for(i = 0; i < ArrayCount(uPRI.NormalWepStatsAltHit); i++)
	{
		if (i == 0)
			S = S$uPRI.NormalWepStatsAltHit[i];
		else
			S = S@uPRI.NormalWepStatsAltHit[i];
	}
	SendHitAlt(S, uPRI);

	S = "";
	for(i = 0; i < ArrayCount(uPRI.NormalWepStatsPrim); i++)
	{
		if (i == 0)
			S = S$uPRI.NormalWepStatsPrim[i];
		else
			S = S@uPRI.NormalWepStatsPrim[i];
	}
	SendFiredPrim(S, uPRI);

	S = "";
	for(i = 0; i < ArrayCount(uPRI.NormalWepStatsAlt); i++)
	{
		if (i == 0)
			S = S$uPRI.NormalWepStatsAlt[i];
		else
			S = S@uPRI.NormalWepStatsAlt[i];
	}
	SendFiredAlt(S, uPRI);

	S = "";
	for(i = 0; i < ArrayCount(uPRI.NormalWepStatsPrimDamage); i++)
	{
		if (i == 0)
			S = S$uPRI.NormalWepStatsPrimDamage[i];
		else
			S = S@uPRI.NormalWepStatsPrimDamage[i];
	}
	SendDamagePrim(S, uPRI);

	S = "";
	for(i = 0; i < ArrayCount(uPRI.NormalWepStatsAltDamage); i++)
	{
		if (i == 0)
			S = S$uPRI.NormalWepStatsAltDamage[i];
		else
			S = S@uPRI.NormalWepStatsAltDamage[i];
	}
	SendDamageAlt(S, uPRI);

	SendDamageGR(uPRI.DamG, uPRI.DamR, uPRI);

	S = uPRI.PickedUpFifty @ uPRI.PickedUpHundred @ uPRI.PickedUpAmp @ uPRI.PickedUpVial @ uPRI.PickedUpHealth @ uPRI.PickedUpKeg @ uPRI.PickedUpAdren;
	SendPickups(S, uPRI);
}

simulated function SendPickups(string S, UTComp_PRI uPRI)
{
	local array<string> Parts;

	Split(S, " ", Parts);

	uPRI.PickedUpFifty = int(Parts[0]);
	uPRI.PickedUpHundred = int(Parts[1]);
	uPRI.PickedUpAmp = int(Parts[2]);
	uPRI.PickedUpVial = int(Parts[3]);
	uPRI.PickedUpHealth = int(Parts[4]);
	uPRI.PickedUpKeg = int(Parts[5]);
	uPRI.PickedUpAdren = int(Parts[6]);
}

simulated function SendDamageGR(int damageG, int damageR, UTComp_PRI uPRI)
{
	uPRI.DamG = damageG;
	uPRI.DamR = damageR;
}

simulated function SendHitPrim(string S, UTComp_PRI uPRI)
{
	local int i;
	local array<string> Parts;

	Split(S," ", Parts);
	for(i = 0; i < Parts.length; i++)
		uPRI.NormalWepStatsPrimHit[i] = int(Parts[i]);
}

simulated function SendHitAlt(string S, UTComp_PRI uPRI)
{
	local int i;
	local array<string> Parts;

	Split(S," ", Parts);
	for(i = 0; i < Parts.length; i++)
		uPRI.NormalWepStatsAltHit[i] = int(Parts[i]);
}

simulated function SendFiredPrim(string S, UTComp_PRI uPRI)
{
	local int i;
	local array<string> Parts;

	Split(S," ", Parts);
	for(i = 0; i < Parts.length; i++)
		uPRI.NormalWepStatsPrim[i] = int(Parts[i]);
}

simulated function SendFiredAlt(string S, UTComp_PRI uPRI)
{
	local int i;
	local array<string> Parts;

	Split(S," ", Parts);
	for(i = 0; i < Parts.length; i++)
		uPRI.NormalWepStatsAlt[i] = int(Parts[i]);
}

simulated function SendDamagePrim(string S, UTComp_PRI uPRI)
{
	local int i;
	local array<string> Parts;

	Split(S," ", Parts);
	for(i = 0; i < Parts.length; i++)
		uPRI.NormalWepStatsPrimDamage[i] = int(Parts[i]);
}

simulated function SendDamageAlt(string S, UTComp_PRI uPRI)
{
	local int i;
	local array<string> Parts;

	Split(S," ", Parts);
	for(i = 0; i < Parts.length; i++)
		uPRI.NormalWepStatsAltDamage[i] = int(Parts[i]);
}

exec function StatPrev()
{}

simulated function bool InstrNonCaseSensitive(String S, string S2)
{
	local int i;

	for(i = 0; i <= (Len(S)-Len(S2)); i++)
	{
		if (Mid(S, i, Len(S2)) ~= S2)
			return true;
	}
	return false;
}

simulated function AssignStatNames()
{
	local int i;

	NormalWepStatsPrim.Length = 15;
	NormalWepStatsAlt.Length = 15;
	for(i = 0; i < 15; i++)
	{
		NormalWepStatsPrim[i].WepName = WepStatNames[i];
		NormalWepStatsAlt[i].WepName = WepStatNames[i];
	}
}

simulated function UpdatePercentages()
{
	local int i;

	if (UTCompPRI == None)
		return;

	for(i = 0; i < NormalWepStatsPrim.Length; i++)
	{
		if (UTCompPRI.NormalWepStatsPrim[i] > 0)
			NormalWepStatsPrim[i].Percent = float(NormalWepStatsPrim[i].Hits)/float(UTCompPRI.NormalWepStatsPrim[i])*100.0;
	}

	for(i = 0; i < NormalWepStatsAlt.Length; i++)
	{
		if (UTCompPRI.NormalWepStatsAlt[i] > 0)
			NormalWepStatsAlt[i].Percent = float(NormalWepStatsAlt[i].Hits)/float(UTCompPRI.NormalWepStatsAlt[i])*100.0;
	}
}

simulated function SyncPRI()
{
	local int i;

	if (UTCompPRI == None)
		return;

	for(i = 0; i < 15; i++)
	{
		UTCompPRI.NormalWepStatsPrimHit[i] = NormalWepStatsPrim[i].Hits;
		UTCompPRI.NormalWepStatsPrimPercent[i] = NormalWepStatsPrim[i].Percent;
		UTCompPRI.NormalWepStatsAltHit[i] = NormalWepStatsAlt[i].Hits;
		UTCompPRI.NormalWepStatsAltPercent[i] = NormalWepStatsAlt[i].Percent;
	}
}

simulated function RegisterTeammateHit(class<DamageType> DamageType, int Damage)
{}

simulated function ServerRegisterTeammateHit(class<DamageType> DamageType, int Damage)
{}

simulated function PlayEnemyHitSound(int Damage)
{
	local float HitSoundPitch;

	if (!Settings.bEnableHitSounds || LastHitSoundTime > Level.TimeSeconds)
		return;

	LastHitSoundTime = Level.TimeSeconds + HITSOUNDTWEENTIME;

	HitSoundPitch = 1.0;
	if (Settings.bCPMAStyleHitSounds)
		HitSoundPitch = Settings.CPMAPitchModifier * 30.0 / Damage;

	if (LoadedEnemySound == none)
		LoadedEnemySound = Sound(DynamicLoadObject(Settings.EnemySound, class'Sound', true));

	if (ViewTarget != None)
		ViewTarget.PlaySound(LoadedEnemySound,,Settings.HitSoundVolume,,,HitSoundPitch);
}

simulated function PlayTeammateHitSound(int Damage)
{
	local float HitSoundPitch;

	if (!Settings.bEnableHitSounds || LastHitSoundTime > Level.TimeSeconds)
		return;

	LastHitSoundTime = Level.TimeSeconds + HITSOUNDTWEENTIME;

	HitSoundPitch = 1.0;
	if (Settings.bCPMAStyleHitSounds)
		HitSoundPitch = Settings.CPMAPitchModifier * 30.0 / Damage;

	if (LoadedFriendlySound == none)
		LoadedFriendlySound = Sound(DynamicLoadObject(Settings.FriendlySound, class'Sound', true));

	if (ViewTarget != None)
		ViewTarget.PlaySound(LoadedFriendlySound,,Settings.HitSoundVolume,,,HitSoundPitch);
}

exec function myMenu()
{
	if (UTCompPRI.CurrentVoteID == 255 ||( PlayerReplicationInfo.bonlyspectator && !IsInState('GameEnded')))
		ClientOpenMenu(string(class'UTComp_Menu_OpenedMenu'));
	else
		ClientOpenMenu(string(class'UTComp_Menu_VoteInProgress'));
}

exec function OpenVoteMenu()
{
	ClientOpenMenu(string(class'UTComp_Menu_VoteInProgress'));
}

exec function SetVolume(float f)
{
	ConsoleCommand("set alaudio.alaudiosubsystem soundvolume "$f);
}

exec function echo(string S)
{
	ClientMessage(""$S);
}

function ServerSpecViewGoal()
{
	bSpecingViewGoal = true;
	Super.ServerSpecViewGoal();
}

function ServerViewSelf()
{
	bSpecingViewGoal = false;
	Super.ServerViewSelf();
}

exec function VoteYes()
{
	if (UTCompPRI != None && UTCompPRI.CurrentVoteID != 255)
	{
		UTCompPRI.Vote = 1;
		UTCompPRI.SetVoteMode(1);
		if (PlayerReplicationInfo != None && (!PlayerReplicationInfo.bOnlySpectator || PlayerReplicationInfo.bAdmin) && Level.TimeSeconds > LastBroadcastVoteTime)
		{
			BroadcastVote(true);
			LastBroadcastVoteTime = Level.TimeSeconds + 5.0;
		}
	}
}

exec function VoteNo()
{
	if (UTCompPRI != None && UTCompPRI.CurrentVoteID != 255)
	{
		UTCompPRI.Vote = 2;
		UTCompPRI.SetVoteMode(2);
		if (PlayerReplicationInfo != None && (!PlayerReplicationInfo.bOnlySpectator || PlayerReplicationInfo.bAdmin) && Level.TimeSeconds > LastBroadcastVoteTime)
		{
			BroadcastVote(false);
			LastBroadcastVoteTime = Level.TimeSeconds + 5.0;
		}
	}
}

exec function GoToPlayer(int k)
{
	ServerGoToPlayer(k-1);
}

function ServerGoToTarget(Actor a)
{
	local rotator R;

	bSpecingViewGoal = false;

	if (PlayerReplicationInfo(a) != None)
	{
		ServerSetViewTarget(a.Owner);
	}
	else
	{
		bBehindView = true;
		ServerSetViewTarget(a);
		ClientSetBehindView(true);
		if (Pickup(a) != None)
		{
			R = Pickup(a).PickUpBase.rotation;
			R.Yaw += 90*182.0444;
			R.Pitch -= 15*182.0444;
		}
		else
		{
			R = CalcViewRotation;
		}
		ClientSetLocation(CalcViewLocation, R);
	}
}

function bool ServerNextPlayer(int teamindex)
{
	local int k;
	local Controller C;
	local Array<Controller> RedPlayers;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.Team != None && C.PlayerReplicationInfo.Team.TeamIndex == teamindex)
			RedPlayers[RedPlayers.Length] = C;
	}

	for(k = 0; k < RedPlayers.Length; k++)
	{
		if (RedPlayers[k] == LastViewedController)
		{
			if (k == RedPlayers.Length-1)
			{
				ServerSetViewTarget(RedPlayers[0]);
				LastViewedController = RedPlayers[0];
				return true;
			}
			else
			{
				ServerSetViewTarget(RedPlayers[k+1]);
				LastViewedController = RedPlayers[k+1];
				return true;
			}
		}
	}

	if (RedPlayers.Length > 0)
	{
		ServerSetViewTarget(RedPlayers[0]);
		LastViewedController = RedPlayers[0];
		return true;
	}
	else
	{
		return false;
	}
}

exec function GoToItem(string CmdLine)
{
	local string pickup, team;
	local class<Pickup> pickupClass;
	local int teamNum;

	teamNum = -1;

	if (!Divide(CmdLine," ", pickup, team))
		pickup = CmdLine;

	if (pickup ~= "50" || pickup ~= "Small" || pickup ~= "50a")
		pickupClass = class'XPickups.ShieldPack';
	else if (pickup ~= "100" || pickup ~= "100a" || pickup ~= "Large" || pickup ~="Big")
		pickupClass = class'XPickups.SuperShieldPack';
	else if (pickup ~= "DD" || pickup ~= "Amp" || pickup ~= "Double-Damage" || pickup ~= "DoubleDamage")
		pickupClass = class'XPickups.UDamagePack';
	else if (pickup ~= "keg")
		pickupClass = class'XPickups.SuperHealthPack';

	if (pickupClass == None)
		return;

	if (team ~= "0" || team ~= "red")
		teamNum = 0;
	else if (team ~= "1" || team ~= "blue")
		teamNum = 1;

	ServerGoToWepBase(pickupClass, teamNum);
}

function bool IsInZone(Actor a, int team)
{
	local string loc;

	loc = a.Region.Zone.LocationName;

	if (team == 0)
		return (Instr(Caps(loc), "RED") != -1);
	else
		return (Instr(Caps(loc), "BLUE") != -1);

	return false;
}

function ServerGoToWepBase(class<Pickup> theClass, int team)
{
	local xPickupBase xPBase;

	foreach AllActors(class'xPickupBase', xPBase)
	{
		if (xPBase.PowerUp == theClass)
		{
			ServerSetViewTarget(xPBase);
			break;
		}
	}
}

function ServerGoToPlayer(int k)
{
	local int j;
	local Controller C;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (j == k)
		{
			ServerSetViewTarget(C);
			return;
		}
		j++;
	}
}

function ServerSetViewTarget(actor A)
{
	if (PlayerReplicationInfo.bOnlySpectator == false)
		return;

	SetViewTarget(A);
	ClientSetViewTarget(A);
}

exec function SetSavedSpectateSpeed(float F)
{
	Settings.SavedSpectateSpeed = F;
	SetSpectateSpeed(F);
	SaveSettings();
}

exec function NextSuperWeapon()
{
	ServerGoToNextSuperWeapon();
}

function ServerGoToNextSuperWeapon()
{
	local xWeaponBase xWep;
	local xWeaponBase FoundWep;
	local xweaponBase FirstWep;
	local bool bFirstActor;

	if (PlayerReplicationInfo.bOnlySpectator == false)
		return;

	foreach AllActors(class'xWeaponBase', xWep)
	{
		if (!bFirstActor && (xWep.WeaponType == class'Redeemer' || xWep.WeaponType == class'Painter'))
		{
			FirstWep = xWep;
			bFirstActor = true;
		}

		if (FoundWep != None && (xWep.WeaponType == class'Redeemer' || xWep.WeaponType == class'Painter'))
		{
			SetViewTarget(xWep);
			ClientSetViewTarget(xWep);
			bBehindView = true;
			OldFoundWep = xWep;
			ClientSetBehindView(true);
			break;
		}

		if (xWep == OldFoundWep)
			FoundWep = xWep;
	}

	if (FoundWep == None && FirstWep != None)
	{
		SetViewTarget(FirstWep);
		ClientSetViewTarget(FirstWep);
		bBehindView = true;
		OldFoundWep = FirstWep;
		ClientSetBehindView(true);
	}
	else if (OldFoundWep != None)
	{
		SetViewTarget(OldFoundWep);
		ClientSetViewTarget(OldFoundWep);
		bBehindView = true;
		ClientSetBehindView(true);
	}
}

exec function BehindView( bool B )
{
	if (Level.NetMode == NM_Standalone || Level.Game.bAllowBehindView || Vehicle(Pawn) != None || PlayerReplicationInfo.bOnlySpectator || PlayerReplicationInfo.bOutOfLives || PlayerReplicationInfo.bAdmin)
	{
		if ((Vehicle(Pawn) == None) || (Vehicle(Pawn).bAllowViewChange))
		{
			ClientSetBehindView(B);
			bBehindView = B;
		}
	}
}

exec function ToggleBehindView()
{
	ServerToggleBehindview();
}

function ServerToggleBehindView()
{
	local bool B;

	if (Level.NetMode == NM_Standalone || Level.Game.bAllowBehindView || Vehicle(Pawn) != None || PlayerReplicationInfo.bOnlySpectator || PlayerReplicationInfo.bOutOfLives || PlayerReplicationInfo.bAdmin)
	{
		if ((Vehicle(Pawn) == None) || (Vehicle(Pawn).bAllowViewChange))
		{
			B = !bBehindView;
			ClientSetBehindView(B);
			bBehindView = B;
		}
	}
}

state Spectating
{
	event PlayerTick(float deltaTime)
	{
		Super.PlayerTick(deltaTime);
		if (bRun == 1)
			GoToState('PlayerMousing');
	}

	function BeginState()
	{
		if (Pawn != None)
		{
			SetLocation(Pawn.Location);
			UnPossess();
		}
		bCollideWorld = true;
		SetTimer(1.0, true);
	}

	exec function Fire(optional float F)
	{
		if (bFrozen)
		{
			if ((TimerRate <= 0.0) || (TimerRate > 1.0))
				bFrozen = false;
			return;
		}

		ServerViewNextPlayer();
	}

	function Timer()
	{
		Super.Timer();
	}

	exec function AltFire(optional float F)
	{
		Super.AltFire(F);
	}
}

simulated function CallVote(byte b, optional byte p, optional string Options, optional int p2, optional string Options2)
{
	if (!IsValidVote(b, p, Options, options2))
		return;

	if (UTCompPRI == None)
		UTCompPRI = class'UTComp_Util'.static.GetUTCompPRI(PlayerReplicationInfo);

	if (PlayerReplicationInfo != None && UTCompPRI != None && PlayerReplicationInfo.bAdmin)
		UTCompPRI.PassVote(b, p, Options, GetPlayerName(), p2, Options2);

	if (UTCompPRI != None)
		UTCompPRI.CallVote(b, p, Options, GetPlayerName(), p2, Options2);
}

simulated function string GetPlayerName()
{
	if (PlayerReplicationInfo != None)
		return PlayerReplicationInfo.PlayerName;

	return "";
}

function bool IsValidVote(byte b, byte p, out string S, string S2)
{
	if (UTCompPRI == None)
		UTCompPRI = class'UTComp_Util'.static.GetUTCompPRI(PlayerReplicationInfo);

	if (PlayerReplicationInfo == None || (PlayerReplicationInfo.bOnlySpectator && !PlayerReplicationInfo.bAdmin))
	{
		ClientMessage("Sorry, only non-spectating players may call votes.");
		return false;
	}

	if (UTCompPRI == None || UTcompPRI.CurrentVoteID != 255)
	{
		ClientMessage("Sorry, a vote is already in progress.");
		return false;
	}

	if (b > 5 || b < 0)
	{
		ClientMessage("An Error occured, this is an invalid vote");
		return false;
	}

	return true;
}

simulated function ResetUTCompStats()
{
	local int i;

	for(i = 0; i < NormalWepStatsPrim.Length; i++)
	{
		NormalWepStatsPrim[i].Damage = 0;
		NormalWepStatsPrim[i].Hits = 0;
		NormalWepStatsPrim[i].Percent = 0;
	}

	for(i = 0; i < NormalWepStatsAlt.Length; i++)
	{
		NormalWepStatsAlt[i].Damage = 0;
		NormalWepStatsAlt[i].Hits = 0;
		NormalWepStatsAlt[i].Percent = 0;
	}

	CustomWepStats.Length = 0;
	DamG = 0;
}

simulated function ResetEpicStats()
{
	local TeamPlayerReplicationInfo tPRI;
	local int i;

	if (PlayerReplicationInfo != None && TeamPlayerReplicationInfo(PlayerReplicationInfo) != None)
	{
		tPRI = TeamPlayerReplicationInfo(PlayerReplicationInfo);
		tPRI.bFirstBlood = false;
		tPRI.FlagTouches = 0;
		tPRI.FlagReturns = 0;
		for(i = 0; i <= 5; i++)
		{
			tPRI.Spree[i] = 0;
			tPRI.MultiKills[i] = 0;
		}
		tPRI.MultiKills[6] = 0;
		tPRI.flakcount = 0;
		tPRI.combocount = 0;
		tPRI.headcount = 0;
		tPRI.ranovercount = 0;
		tPRI.DaredevilPoints = 0;
		for(i = 0; i <= 4; i++)
			tPRI.Combos[i] = 0;
	
		for(i = tPRI.VehicleStatsArray.Length-1; i >= 0; i--)
			tPRI.VehicleStatsArray.Remove(i, 1);

		for(i = tPRI.WeaponStatsArray.Length-1; i >= 0; i--)
			tPRI.WeaponStatsArray.Remove(i, 1);
	}
}

function BroadcastVote(bool b)
{
	if (b)
		Level.Game.Broadcast(self, PlayerReplicationInfo.PlayerName @ "voted yes.");
	else
		Level.Game.Broadcast(self, PlayerReplicationInfo.PlayerName @ "voted no.");
}

exec function SetName(coerce string S)
{
	S = StripColorCodes(S);
	Super.SetName(S);

	ReplaceText(S, " ", "_");
	ReplaceText(S, "\"", "");
	SetColoredNameOldStyle(Left(S, 20));
	Settings.CurrentSelectedColoredName = 255;

	SaveSettings();
	StaticSaveConfig();
}

exec function SetNameNoReset(coerce string S)
{
	S = StripColorCodes(S);
	Super.SetName(S);

	ReplaceText(S, " ", "_");
	ReplaceText(S, "\"", "");
	SetColoredNameOldStyle(S);
}

simulated function SetColoredNameOldStyle(optional string S2, optional bool bShouldSave)
{
	local string S;
	local byte k;
	local byte numdoatonce;
	local byte m;

	if (Level.NetMode == NM_DedicatedServer || PlayerReplicationInfo == None)
		return;

	if (S2 == "")
		S2 = PlayerReplicationInfo.PlayerName;

	for(k = 1; k <= Len(S2); k++)
	{
		numdoatonce = 1;
		for(m = k; m < Len(S2) && Settings.ColorName[k-1] == Settings.ColorName[m]; m++)
		{
			numdoatonce++;
			k++;
		}
		S = S$class'UTComp_Util'.static.MakeColorCode(Settings.ColorName[k-1])$Right(Left(S2, k), numdoatonce);
	}

	if (UTCompPRI != None)
		UTCompPRI.SetColoredName(S);
}

simulated function string FindColoredName(int CustomColors)
{
	local string S, S2;
	local int i;

	if (Level.NetMode == NM_DedicatedServer || PlayerReplicationInfo == None)
		return "";

	if (S2 == "")
		S2 = Settings.ColoredName[CustomColors].SavedName;

	for(i = 0; i < Len(S2); i++)
		S $= class'UTComp_Util'.static.MakeColorCode(Settings.ColoredName[CustomColors].SavedColor[i]) $ Mid(Settings.ColoredName[CustomColors].SavedName, i, 1);

	return S;
}

simulated function string AddNewColoredName(int CustomColors)
{
	local string S, S2;
	local byte k;
	local byte numdoatonce;
	local byte m;

	if (Level.NetMode == NM_DedicatedServer || PlayerReplicationInfo == None)
		return "";

	if (S2 == "")
		S2 = Settings.ColoredName[CustomColors].SavedName;

	SetNameNoReset(S2);
	for(k = 0; k < 20; k++)
		Settings.ColorName[k] = Settings.ColoredName[CustomColors].SavedColor[k];

	for(k = 1; k <= Len(S2); k++)
	{
		numdoatonce = 1;
		for(m = k; m < Len(S2) && Settings.ColoredName[CustomColors].SavedColor[k-1] == Settings.ColoredName[CustomColors].SavedColor[m]; m++)
		{
			numdoatonce++;
			k++;
		}
		S = S$class'UTComp_Util'.static.MakeColorCode(Settings.ColoredName[CustomColors].SavedColor[k-1])$Right(Left(S2, k), numdoatonce);
	}

	return S;
}

simulated function SaveNewColoredName()
{
	local int l, n;

	n = Settings.ColoredName.Length+1;
	Settings.ColoredName.Length = n;

	Settings.ColoredName[n-1].SavedName = PlayerReplicationInfo.PlayerName;
	for(l = 0; l < 20; l++)
		Settings.ColoredName[n-1].SavedColor[l] = Settings.ColorName[l];
}

exec function ShowColoredNames()
{
	local int i, j;
	local string S;

	for(i = 0; i < Settings.ColoredName.Length; i++)
	{
		Log(Settings.ColoredName[i].SavedName);
		for(j = 0; j < 20; j++)
			S = S $ Settings.ColoredName[i].SavedColor[j].R @ Settings.ColoredName[i].SavedColor[j].G @ Settings.ColoredName[i].SavedColor[j].B;

		Log(S);
	}
}

simulated function SetColoredNameOldStyleCustom(optional string S2, optional int CustomColors)
{
	local string S;
	local byte k;
	local byte numdoatonce;
	local byte m;

	if (Level.NetMode == NM_DedicatedServer || PlayerReplicationInfo == None)
		return;

	if (S2 == "")
		S2 = Settings.ColoredName[CustomColors].SavedName;

	SetNameNoReset(S2);
	for(k = 0; k < 20; k++)
		Settings.ColorName[k] = Settings.ColoredName[CustomColors].SavedColor[k];

	SaveSettings();
	for(k = 1; k <= Len(S2); k++)
	{
		numdoatonce = 1;
		for(m = k; m < Len(S2) && Settings.ColoredName[CustomColors].SavedColor[k-1] == Settings.ColoredName[CustomColors].SavedColor[m]; m++)
		{
			numdoatonce++;
			k++;
		}
		S = S$class'UTComp_Util'.static.MakeColorCode(Settings.ColoredName[CustomColors].SavedColor[k-1])$Right(Left(S2, k), numdoatonce);
	}

	if (UTCompPRI != None)
		UTCompPRI.SetColoredName(S);
}

exec function ListColoredNames()
{
	local int i;

	for(i = 0; i < Settings.ColoredName.Length; i++)
		echo(Settings.ColoredName[i].SavedName);
}

simulated function SetShowSelf(bool b)
{
	Settings.bShowSelfInTeamOverlay = b;
	SaveSettings();
	StaticSaveConfig();

	if (UTCompPRI != none)
		UTCompPRI.SetShowSelf(b);
}

simulated function string StripColorCodes(String S)
{
	local array<string> StringParts;
	local int i;
	local string S2;

	Split(S, Chr(27), StringParts);
	if (StringParts.Length >= 1)
		S2 = StringParts[0];

	for(i = 1; i < StringParts.Length; i++)
	{
		StringParts[i] = Right(StringParts[i], Len(StringParts[i])-3);
		S2 = S2$StringParts[i];
	}

	if (Right(S2, 1) == Chr(27))
		S2 = Left(S2, Len(S2)-1);

	return S2;
}

simulated function ReSkinAll()
{
	local UTComp_xPawn P;

	if (Level.NetMode == NM_DedicatedServer)
		return;

	foreach DynamicActors(class'UTComp_xPawn', P)
	{
		if (!P.bInvis)
			P.ColorSkins();
	}
}

function bool AllowTextMessage(string Msg)
{
	local int k;

	if ((Level.NetMode == NM_Standalone) || PlayerReplicationInfo.bAdmin)
		return true;

	if ((Level.Pauser == none) && (Level.TimeSeconds - LastBroadcastTime < 0.66))
		return false;

	// lower frequency if same text
	if (Level.TimeSeconds - LastBroadcastTime < 5)
	{
		Msg = Left(Msg, Clamp(Len(Msg) - 4, 8, 64));
		for(k = 0; k < 4; k++)
		{
			if (LastBroadcastString[k] ~= Msg)
				return false;
		}
	}

	for(k = 3; k > 0; k--)
		LastBroadcastString[k] = LastBroadcastString[k-1];

	LastBroadcastTime = Level.TimeSeconds;
	return true;
}

event TeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type)
{
	local string c;
	local int k;

	if (Level.NetMode == NM_DedicatedServer || GameReplicationInfo == None)
		return;

	if (AllowTextToSpeech(PRI, Type))
		TextToSpeech(S, TextToSpeechVoiceVolume);

	if (Type == 'TeamSayQuiet')
		Type = 'TeamSay';

	if (Settings.bAllowColoredMessages)
	{
		for(k = 7; k >= 0; k--)
			S = repl(S, "^"$k, ColorReplace(k));
	}
	else
	{
		for(k = 7; k >= 0; k--)
			S = repl(S, "^"$k, "");
	}

	if (myHud != None)
	{
		if (Settings.bEnableColoredNamesInTalk)
			Message(PRI, c$S, Type);
		else
			myHud.Message(PRI, c$S, Type);
	}

	if ((Player != None) && (Player.Console != None))
	{
		if (PRI != None)
		{
			if (PRI.Team != None && GameReplicationInfo.bTeamGame)
			{
				if (PRI.Team.TeamIndex == 0)
					c = Chr(27) $ Chr(200) $ Chr(1) $ Chr(1);
				else if (PRI.Team.TeamIndex == 1)
					c = Chr(27) $ Chr(125) $ Chr(200) $ Chr(253);
			}
			S = PRI.PlayerName $ ":" @ S;
		}
		Player.Console.Chat(c$s, 6.0, PRI);
	}
}

function ServerSay( string Msg )
{
	local Controller C;

	// center print admin messages which start with #
	if (PlayerReplicationInfo.bAdmin && Left(Msg, 1) == "#")
	{
		Msg = Right(Msg, Len(Msg)-1);
		for(C = Level.ControllerList; C != None; C = C.NextController)
		{
			if (PlayerController(C) != None)
			{
				PlayerController(C).ClearProgressMessages();
				PlayerController(C).SetProgressTime(6);
				PlayerController(C).SetProgressMessage(0, Msg, class'Canvas'.static.MakeColor(255,255,255));
			}
		}
		return;
	}

	Level.Game.Broadcast(self, Msg, 'Say');
}

function ServerTeamSay( string Msg )
{
	LastActiveTime = Level.TimeSeconds;

	if (!GameReplicationInfo.bTeamGame)
	{
		if (!PlayerReplicationInfo.bOnlySpectator)
		{
			Say(Msg);
			return;
		}
		else
		{
			SpecDMSay(Msg);
			return;
		}
	}

	Level.Game.BroadcastTeam(self, Level.Game.ParseMessageString(Level.Game.BaseMutator, self, Msg), 'TeamSay');
}

function SpecDMSay(string msg)
{
	local PlayerController P;
	local Controller C;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		P = PlayerController(C);
		if (P != None && P.PlayerReplicationInfo != None && P.PlayerReplicationInfo.bOnlySpectator)
			Level.Game.BroadcastHandler.BroadcastText(PlayerReplicationInfo, P, msg, 'TeamSay');
	}
}

simulated function Message( PlayerReplicationInfo PRI, coerce string Msg, name MsgType )
{
	local class<LocalMessage> LocalMsgClass;

	switch (MsgType)
	{
		case 'Say':
			if (PRI == None)
				return;

			if (class'UTComp_Util'.static.GetUTCompPRI(PRI) == None || class'UTComp_Util'.static.GetUTCompPRI(PRI).ColoredName == "")
				Msg = PRI.PlayerName $ ":" @ Msg;
			else if (PRI.Team != none && PRI.Team.TeamIndex == 0)
				Msg = class'UTComp_Util'.static.GetUTCompPRI(PRI).ColoredName $ class'UTComp_Util'.static.MakeColorCode(MessageRed) $ ":" @ Msg;
			else if (PRI.Team != none && PRI.Team.TeamIndex == 1)
				Msg = class'UTComp_Util'.static.GetUTCompPRI(PRI).ColoredName $ class'UTComp_Util'.static.MakeColorCode(MessageBlue) $ ":" @ Msg;
			else
				Msg = class'UTComp_Util'.static.GetUTCompPRI(PRI).ColoredName $ class'UTComp_Util'.static.MakeColorCode(MessageYellow) $ ":" @ Msg;
			LocalMsgClass = class'SayMessagePlus';
			break;

		case 'TeamSay':
			if (PRI == None)
				return;

			if (class'UTComp_Util'.static.GetUTCompPRI(PRI) == None || class'UTComp_Util'.static.GetUTCompPRI(PRI).ColoredName == "")
				Msg = PRI.PlayerName $ "(" $ PRI.GetLocationName() $ "):" @ Msg;
			else
				Msg = class'UTComp_Util'.static.GetUTCompPRI(PRI).ColoredName $ class'UTComp_Util'.static.MakeColorCode(MessageGreen) $ "(" $ PRI.GetLocationName() $ "):" @ Msg;
			LocalMsgClass = class'TeamSayMessagePlus';
			break;

		case 'CriticalEvent':
			LocalMsgClass = class'CriticalEventPlus';
			myHud.LocalizedMessage(LocalMsgClass, 0, None, None, None, Msg);
			return;

		case 'DeathMessage':
			LocalMsgClass = class'xDeathMessage';
			break;

		default:
			LocalMsgClass = class'StringMessagePlus';
			break;
	}

	if (myHud != None)
		myHud.AddTextMessage(Msg, LocalMsgClass, PRI);
}

function string RandomColor()
{
	local Color theColor;

	theColor.R = Rand(250);
	theColor.G = Rand(250);
	theColor.B = Rand(250);
	return class'UTComp_Util'.static.MakeColorCode(theColor);
}

function string ColorReplace(int k)   //makes the 8 primary colors
{
	local Color theColor;

	theColor.R = GetBit(k,0)*250;
	theColor.G = GetBit(k,1)*250;
	theColor.B = GetBit(k,2)*250;  //cant be 255 because of the chat window
	return class'UTComp_Util'.static.MakeColorCode(theColor);
}

simulated function int GetBit(int theInt, int bitNum)
{
	return ((theInt & 1<<bitNum));
}

simulated function bool GetBitBool(int theInt, int bitNum)
{
	return ((theInt & 1<<bitNum) != 0);
}

simulated function MatchHudColor()
{
	local HudCDeathMatch DMHud;

	if (myHud == None || HudCDeathMatch(myHud) == None)
		return;

	DMHud = HudCDeathMatch(myHud);
	if (!HudS.bMatchHudColor)
	{
		DMHud.HudColorRed = class'HudCDeathMatch'.default.HudColorRed;
		DMHud.HudColorBlue = class'HudCDeathMatch'.default.HudColorBlue;
		return;
	}

	if (!Settings.bEnemyBasedSkins)
	{
		if (Settings.ClientSkinModeRedTeammate == 3)
			DMHud.HudColorRed = Settings.RedTeammateUTCompSkinColor;
		else if (Settings.ClientSkinModeRedTeammate == 2 || Settings.ClientSkinModeRedTeammate == 1)
			DMHud.HudColorRed = class'UTComp_xPawn'.default.BrightSkinColors[Settings.PreferredSkinColorRedTeammate];

		if (Settings.ClientSkinModeBlueEnemy == 3)
			DMHud.HudColorBlue = Settings.BlueEnemyUTCompSkinColor;
		else if (Settings.ClientSkinModeBlueEnemy == 2 || Settings.ClientSkinModeBlueEnemy == 1)
			DMHud.HudColorBlue = class'UTComp_xPawn'.default.BrightSkinColors[Settings.PreferredSkinColorBlueEnemy];
	}
	else
	{
		if (Settings.ClientSkinModeRedTeammate == 3)
		{
			DMHud.HudColorBlue = Settings.RedTeammateUTCompSkinColor;
			DMHud.HudColorRed = Settings.RedTeammateUTCompSkinColor;
		}
		else if (Settings.ClientSkinModeRedTeammate == 2 || Settings.ClientSkinModeRedTeammate == 1)
		{
			DMHud.HudColorBlue = class'UTComp_xPawn'.default.BrightSkinColors[Settings.PreferredSkinColorRedTeammate];
			DMHud.HudColorRed = class'UTComp_xPawn'.default.BrightSkinColors[Settings.PreferredSkinColorRedTeammate];
		}
	}
}

function BecomeSpectator()
{
	Super.BecomeSpectator();
	ResetUTCompStats();
	ResetNet();
}

function ResetNet()
{
	if (UTCompPRI != None)
		UTCompPRI.RealKills = 0;
}

state PlayerWalking
{
	function bool NotifyLanded(vector HitNormal)
	{
		if (DoubleClickDir == DCLICK_Active)
		{
			DoubleClickDir = DCLICK_Done;
			ClearDoubleClick();
			Pawn.Velocity *= Vect(0.8,0.8,1.0);
		}
		else
		{
			DoubleClickDir = DCLICK_None;
		}

		if (Global.NotifyLanded(HitNormal))
			return true;

		return false;
	}

	function PlayerMove(float deltaTime)
	{
		local vector X,Y,Z, NewAccel;
		local eDoubleClickDir DoubleClickMove;
		local rotator OldRotation, ViewRotation;
		local bool bSaveJump;

		if (Pawn == None)
		{
			GotoState('Dead');
			return;
		}

		GetAxes(Pawn.Rotation,X,Y,Z);

		// Update acceleration.
		NewAccel = aForward*X + aStrafe*Y;
		NewAccel.Z = 0;
		if (VSize(NewAccel) < 1.0)
			NewAccel = vect(0,0,0);

		if (NewInput == none || NewInput.Outer != self)
		{
			FindPlayerInput();
		}
		DoubleClickMove = NewInput.CheckForDoubleClickMove(1.1*deltaTime/Level.TimeDilation);

		GroundPitch = 0;
		ViewRotation = Rotation;
		if (Pawn.Physics == PHYS_Walking)
		{
			// tell pawn about any direction changes to give it a chance to play appropriate animation
			// if walking, look up/down stairs - unless player is rotating view
			if ((bLook == 0) && (((Pawn.Acceleration != Vect(0,0,0)) && bSnapToLevel) || !bKeyboardLook))
			{
				if (bLookUpStairs || bSnapToLevel)
				{
					GroundPitch = FindStairRotation(deltaTime);
					ViewRotation.Pitch = GroundPitch;
				}
				else if (bCenterView)
				{
					ViewRotation.Pitch = ViewRotation.Pitch & 65535;
					if (ViewRotation.Pitch > 32768)
						ViewRotation.Pitch -= 65536;

					ViewRotation.Pitch = ViewRotation.Pitch * (1 - 12 * FMin(0.0833, deltaTime));
					if ((Abs(ViewRotation.Pitch) < 250) && (ViewRotation.Pitch < 100))
						ViewRotation.Pitch = -249;
				}
			}
		}
		else
		{
			if (!bKeyboardLook && (bLook == 0) && bCenterView)
			{
				ViewRotation.Pitch = ViewRotation.Pitch & 65535;
				if (ViewRotation.Pitch > 32768)
					ViewRotation.Pitch -= 65536;

				ViewRotation.Pitch = ViewRotation.Pitch * (1 - 12 * FMin(0.0833, deltaTime));
				if ((Abs(ViewRotation.Pitch) < 250) && (ViewRotation.Pitch < 100))
					ViewRotation.Pitch = -249;
			}
		}
		Pawn.CheckBob(deltaTime, Y);

		// Update rotation.
		SetRotation(ViewRotation);
		OldRotation = Rotation;
		UpdateRotation(deltaTime, 1);
		bDoubleJump = false;

		if (bPressedJump && Pawn.CannotJumpNow())
		{
			bSaveJump = true;
			bPressedJump = false;
		}
		else
		{
			bSaveJump = false;
		}

		if (Role < ROLE_Authority)
			UTComp_ReplicateMove(deltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
		else
			ProcessMove(deltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);

		bPressedJump = bSaveJump;
	}
}

function ServerSetEyeHeightAlgorithm(bool B)
{
	bUseSlopeAlgorithm = B;
}

function SetEyeHeightAlgorithm(bool B)
{
	bUseSlopeAlgorithm = B;
	ServerSetEyeHeightAlgorithm(B);
}

function TurnOffNetCode()
{
	local Inventory inv;

	if (Pawn == none)
		return;

	for(inv = Pawn.Inventory; inv != None; inv = inv.Inventory)
	{
		if (Weapon(inv) != None)
		{
			if (NewNet_AssaultRifle(Inv) != None)
				NewNet_AssaultRifle(Inv).DisableNet();
			else if (NewNet_BioRifle(Inv) != None)
				NewNet_BioRifle(Inv).DisableNet();
			else if (NewNet_ShockRifle(Inv) != None)
				NewNet_ShockRifle(Inv).DisableNet();
			else if (NewNet_MiniGun(Inv) != None)
				NewNet_MiniGun(Inv).DisableNet();
			else if (NewNet_LinkGun(Inv) != None)
				NewNet_LinkGun(Inv).DisableNet();
			else if (NewNet_RocketLauncher(Inv) != None)
				NewNet_RocketLauncher(inv).DisableNet();
			else if (NewNet_FlakCannon(inv) != None)
				NewNet_FlakCannon(inv).DisableNet();
			else if (NewNet_SniperRifle(inv) != None)
				NewNet_SniperRifle(inv).DisableNet();
			else if (NewNet_ClassicSniperRifle(inv) != None)
				NewNet_ClassicSniperRifle(inv).DisableNet();
		}
	}
}

exec function GetSensitivity()
{
	Player.Console.Message("Sensitivity" @ class'PlayerInput'.default.MouseSensitivity, 6.0);
}

// Add in a check for ping here eventually so we shut off if its outside the max
simulated function bool UseNewNet()
{
	return Settings.bClientNetcode;
}

// replace calls for old weapons if newnet is on
exec function GetWeapon(class<Weapon> NewWeaponClass)
{
	if (RepInfo == None)
	{
		foreach DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
			break;
	}

	if (RepInfo.b_Netcode)
	{
		if (NewWeaponClass == class'AssaultRifle')
			NewWeaponClass = class'NewNet_AssaultRifle';
		else if (NewWeaponClass == class'BioRifle')
			NewWeaponClass = class'NewNet_BioRifle';
		else if (NewWeaponClass == class'ClassicSniperRifle')
			NewWeaponClass = class'NewNet_ClassicSniperRifle';
		else if (NewWeaponClass == class'FlakCannon')
			NewWeaponClass = class'NewNet_FlakCannon';
		else if (NewWeaponClass == class'LinkGun')
			NewWeaponClass = class'NewNet_LinkGun';
		else if (NewWeaponClass == class'MiniGun')
			NewWeaponClass = class'NewNet_MiniGun';
		else if (NewWeaponClass == class'ONSAvril')
			NewWeaponClass = class'NewNet_ONSAvril';
		else if (NewWeaponClass == class'ONSGrenadeLauncher')
			NewWeaponClass = class'NewNet_ONSGrenadeLauncher';
		else if (NewWeaponClass == class'ONSMineLayer')
			NewWeaponClass = class'NewNet_ONSMineLayer';
		else if (NewWeaponClass == class'RocketLauncher')
			NewWeaponClass = class'NewNet_RocketLauncher';
		else if (NewWeaponClass == class'ShockRifle')
			NewWeaponClass = class'NewNet_ShockRifle';
		else if (NewWeaponClass == class'SniperRifle')
			NewWeaponClass = class'NewNet_SniperRifle';
	}
	else
	{
		if (NewWeaponClass == class'ShieldGun')
			NewWeaponClass = class'UTComp_ShieldGun';
		else if (NewWeaponClass == class'AssaultRifle')
			NewWeaponClass = class'UTComp_AssaultRifle';
		else if (NewWeaponClass == class'BioRifle')
			NewWeaponClass = class'UTComp_BioRifle';
		else if (NewWeaponClass == class'FlakCannon')
			NewWeaponClass = class'UTComp_FlakCannon';
		else if (NewWeaponClass == class'LinkGun')
			NewWeaponClass = class'UTComp_LinkGun';
		else if (NewWeaponClass == class'MiniGun')
			NewWeaponClass = class'UTComp_MiniGun';
		else if (NewWeaponClass == class'RocketLauncher')
			NewWeaponClass = class'UTComp_RocketLauncher';
		else if (NewWeaponClass == class'ShockRifle')
			NewWeaponClass = class'UTComp_ShockRifle';
		else if (NewWeaponClass == class'SniperRifle')
			NewWeaponClass = class'UTComp_SniperRifle';
	}
	Super.GetWeapon(NewWeaponClass);
}

function DoCombo( class<Combo> ComboClass )
{
	if (Adrenaline >= ComboClass.default.AdrenalineCost && !Pawn.InCurrentCombo() && !ComboDisabled(ComboClass))
		ServerDoCombo(ComboClass);
}

function bool ComboDisabled(class<Combo> ComboClass)
{
	if (Settings.bDisableSpeed && ComboClass == class'xGame.ComboSpeed')
		return true;

	if (Settings.bDisableBooster && ComboClass == class'xGame.ComboDefensive')
		return true;

	if (Settings.bDisableInvis && ComboClass == class'xGame.ComboInvis')
		return true;

	if (Settings.bDisableBerserk && ComboClass == class'xGame.ComboBerserk')
		return true;

	return false;
}

event ClientTravel( string URL, ETravelType TravelType, bool bItems )
{
	Super.ClientTravel(URL, TravelType, bItems);
	NewInput = none;
}

state PlayerMousing extends Spectating
{
	event PlayerTick(float deltaTime)
	{
		Super.PlayerTick(deltaTime);
		if (bRun == 0)
			GoToState('Spectating');
	}

	exec function Fire(float f)
	{
		Overlay.Click();
		return;
	}

	simulated function PlayerMove(float deltaTime)
	{
		local vector MouseV, ScreenV;

		// get the new mouse position offset
		MouseV.X = deltaTime * aMouseX / (InputClass.default.MouseSensitivity * DesiredFOV * 0.01111) * (class'GUIController'.default.MenuMouseSens * 2);
		MouseV.Y = deltaTime * aMouseY / (InputClass.default.MouseSensitivity * DesiredFOV * -0.01111) * (class'GUIController'.default.MenuMouseSens * 2);

		// update mouse position
		PlayerMouse += MouseV;

		// convert mouse position to screen coords, but only if we have good screen sizes
		if ((LastHUDSizeX > 0) && (LastHUDSizeY > 0))
		{
			ScreenV.X = PlayerMouse.X + LastHUDSizeX * 0.5;
			ScreenV.Y = PlayerMouse.Y + LastHUDSizeY * 0.5;
			// here is where you would use the screen coords to do a trace or check HUD elements
		}

		//Super.PlayerMove(deltaTime);
		return;
	}
}

function int FractionCorrection(float in, out float fraction)
{
	local int result;
	local float tmp;

	tmp = in + fraction;
	result = int(tmp);
	fraction = tmp - result;

	return result;
}

function UpdateRotation(float deltaTime, float maxPitch)
{
	local rotator newRotation, ViewRotation;

	if (bInterpolating || ((Pawn != None) && Pawn.bInterpolating))
	{
		ViewShake(deltaTime);
		return;
	}

	// Added FreeCam control for better view control
	if (bFreeCam == true)
	{
		if (bFreeCamZoom == true)
		{
			CameraDeltaRad += FractionCorrection(deltaTime * 0.25 * aLookUp, PitchFraction);
		}
		else if (bFreeCamSwivel == true)
		{
			CameraSwivel.Yaw += FractionCorrection(16.0 * deltaTime * aTurn, YawFraction);
			CameraSwivel.Pitch += FractionCorrection(16.0 * deltaTime * aLookUp, PitchFraction);
		}
		else
		{
			CameraDeltaRotation.Yaw += FractionCorrection(32.0 * deltaTime * aTurn, YawFraction);
			CameraDeltaRotation.Pitch += FractionCorrection(32.0 * deltaTime * aLookUp, PitchFraction);
		}
	}
	else
	{
		ViewRotation = Rotation;

		if (Pawn != None && Pawn.Physics != PHYS_Flying)
		{
			// Ensure we are not setting the pawn to a rotation beyond its desired
			if (Pawn.DesiredRotation.Roll < 65535 && (ViewRotation.Roll < Pawn.DesiredRotation.Roll || ViewRotation.Roll > 0))
				ViewRotation.Roll = 0;
			else if (Pawn.DesiredRotation.Roll > 0 && (ViewRotation.Roll > Pawn.DesiredRotation.Roll || ViewRotation.Roll < 65535))
				ViewRotation.Roll = 0;
		}
		DesiredRotation = ViewRotation; //save old rotation

		if (bTurnToNearest != 0)
		{
			TurnTowardNearestEnemy();
		}
		else if (bTurn180 != 0)
		{
			TurnAround();
		}
		else
		{
			TurnTarget = None;
			bRotateToDesired = false;
			bSetTurnRot = false;
			ViewRotation.Yaw += FractionCorrection(32.0 * deltaTime * aTurn, YawFraction);
			ViewRotation.Pitch += FractionCorrection(32.0 * deltaTime * aLookUp, PitchFraction);
		}

		if (Pawn != None)
			ViewRotation.Pitch = Pawn.LimitPitch(ViewRotation.Pitch);

		SetRotation(ViewRotation);

		ViewShake(deltaTime);
		ViewFlash(deltaTime);

		NewRotation = ViewRotation;
		//NewRotation.Roll = Rotation.Roll;

		if (!bRotateToDesired && (Pawn != None) && (!bFreeCamera || !bBehindView))
			Pawn.FaceRotation(NewRotation, deltaTime);
	}
}

function bool WantsSmoothedView()
{
	if (Pawn == none)
		return false;

	return (
		((Pawn.Physics == PHYS_Walking || Pawn.Physics == PHYS_Spider) && Pawn.bJustLanded == false) ||
		(Pawn.Physics == PHYS_Falling && UTComp_xPawn(Pawn).OldPhysics2 == PHYS_Walking)
	);
}

state PlayerSwimming
{
ignores SeePlayer, HearNoise, Bump;

	function bool WantsSmoothedView()
	{
		return (!Pawn.bJustLanded);
	}
}

function UTComp_ReplicateMove(float deltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
{
	local SavedMove NewMove, OldMove, AlmostLastMove, LastMove;
	local byte ClientRoll;
	local float OldTimeDelta;
	local int OldAccel;
	local vector BuildAccel, AccelNorm, MoveLoc, CompareAccel;
	local bool bPendingJumpStatus;

	MaxResponseTime = default.MaxResponseTime * Level.TimeDilation;
	deltaTime = FMin(deltaTime, MaxResponseTime);

	// find the most recent move, and the most recent interesting move
	if (SavedMoves != None)
	{
		LastMove = SavedMoves;
		AlmostLastMove = LastMove;
		AccelNorm = Normal(NewAccel);
		while(LastMove.NextMove != None)
		{
			// find most recent interesting move to send redundantly
			if (LastMove.IsJumpMove())
			{
				OldMove = LastMove;
			}
			else if ((Pawn != None) && ((OldMove == None) || !OldMove.IsJumpMove()))
			{
				// see if acceleration direction changed
				if (OldMove != None)
					CompareAccel = Normal(OldMove.Acceleration);
				else
					CompareAccel = AccelNorm;

				if ((LastMove.Acceleration != CompareAccel) && ((Normal(LastMove.Acceleration) Dot CompareAccel) < 0.95))
					OldMove = LastMove;
			}

			AlmostLastMove = LastMove;
			LastMove = LastMove.NextMove;
		}

		if (LastMove.IsJumpMove())
		{
			OldMove = LastMove;
		}
		else if ((Pawn != None) && ((OldMove == None) || !OldMove.IsJumpMove()))
		{
			// see if acceleration direction changed
			if (OldMove != None )
				CompareAccel = Normal(OldMove.Acceleration);
			else
				CompareAccel = AccelNorm;

			if ((LastMove.Acceleration != CompareAccel) && ((Normal(LastMove.Acceleration) Dot CompareAccel) < 0.95))
				OldMove = LastMove;
		}
	}

	// Get a SavedMove actor to store the movement in.
	NewMove = GetFreeMove();
	if (NewMove == None)
		return;
	NewMove.SetMoveFor(self, deltaTime, NewAccel, DoubleClickMove);
	NewMove.RemoteRole = ROLE_None;

	// Simulate the movement locally.
	bDoubleJump = false;
	ProcessMove(NewMove.Delta, NewMove.Acceleration, NewMove.DoubleClickMove, DeltaRot);

	// see if the two moves could be combined
	if (
		(PendingMove != None) &&
		(Pawn != None) &&
		(Pawn.Physics == PHYS_Walking) &&
		(NewMove.Delta + PendingMove.Delta < MaxResponseTime) &&
		(NewAccel != vect(0,0,0)) &&
		(PendingMove.SavedPhysics == PHYS_Walking) &&
		!PendingMove.bPressedJump &&
		!NewMove.bPressedJump &&
		(PendingMove.bRun == NewMove.bRun) &&
		(PendingMove.bDuck == NewMove.bDuck) &&
		(PendingMove.bDoubleJump == NewMove.bDoubleJump) &&
		(PendingMove.DoubleClickMove == DCLICK_None) &&
		(NewMove.DoubleClickMove == DCLICK_None) &&
		((Normal(PendingMove.Acceleration) Dot Normal(NewAccel)) > 0.99) &&
		(Level.TimeDilation >= 0.9)
	)
	{
		Pawn.SetLocation(PendingMove.GetStartLocation());
		Pawn.Velocity = PendingMove.StartVelocity;
		if (PendingMove.StartBase != Pawn.Base);
			Pawn.SetBase(PendingMove.StartBase);
		Pawn.Floor = PendingMove.StartFloor;
		NewMove.Delta += PendingMove.Delta;
		NewMove.SetInitialPosition(Pawn);

		// remove pending move from move list
		if (LastMove == PendingMove)
		{
			if (SavedMoves == PendingMove)
			{
				SavedMoves.NextMove = FreeMoves;
				FreeMoves = SavedMoves;
				SavedMoves = None;
			}
			else
			{
				PendingMove.NextMove = FreeMoves;
				FreeMoves = PendingMove;
				if (AlmostLastMove != None)
				{
					AlmostLastMove.NextMove = None;
					LastMove = AlmostLastMove;
				}
			}
			FreeMoves.Clear();
		}
		PendingMove = None;
	}

	if (Pawn != None)
		Pawn.AutonomousPhysics(NewMove.Delta);
	else
		AutonomousPhysics(deltaTime);
	NewMove.PostUpdate(self);

	if (SavedMoves == None)
		SavedMoves = NewMove;
	else
		LastMove.NextMove = NewMove;

	if (PendingMove == None)
	{
		// Decide whether to hold off on move
		if ((Level.TimeSeconds - ClientUpdateTime) * Level.TimeDilation * 0.91 < TimeBetweenUpdates)
		{
			PendingMove = NewMove;
			return;
		}
	}

	ClientUpdateTime = Level.TimeSeconds;

	// check if need to redundantly send previous move
	if (OldMove != None)
	{
		// old move important to replicate redundantly
		OldTimeDelta = FMin(255, (Level.TimeSeconds - OldMove.TimeStamp) * 500);
		BuildAccel = 0.05 * OldMove.Acceleration + vect(0.5, 0.5, 0.5);
		OldAccel = (CompressAccel(BuildAccel.X) << 23) + (CompressAccel(BuildAccel.Y) << 15) + (CompressAccel(BuildAccel.Z) << 7);
		if (OldMove.bRun)
			OldAccel += 64;
		if (OldMove.bDoubleJump)
			OldAccel += 32;
		if (OldMove.bPressedJump)
			OldAccel += 16;
		OldAccel += OldMove.DoubleClickMove;
	}

	// Send to the server
	ClientRoll = (Rotation.Roll >> 8) & 255;
	if (PendingMove != None)
	{
		if (PendingMove.bPressedJump)
			bJumpStatus = !bJumpStatus;
		bPendingJumpStatus = bJumpStatus;
	}

	if (NewMove.bPressedJump)
		bJumpStatus = !bJumpStatus;

	if (Pawn == None)
		MoveLoc = Location;
	else
		MoveLoc = Pawn.Location;

	UTComp_CallServerMove(
		NewMove.TimeStamp,
		NewMove.Acceleration * 10,
		MoveLoc,
		NewMove.bRun,
		NewMove.bDuck,
		bPendingJumpStatus,
		bJumpStatus,
		NewMove.bDoubleJump,
		NewMove.DoubleClickMove,
		ClientRoll,
		((0xFFFF & Rotation.Pitch) << 16) | (0xFFFF & Rotation.Yaw),
		OldTimeDelta,
		OldAccel
	);
	PendingMove = None;
}

function UTComp_CallServerMove(
	float TimeStamp, vector InAccel, vector ClientLoc, bool NewbRun, bool NewbDuck,
	bool NewbPendingJumpStatus, bool NewbJumpStatus, bool NewbDoubleJump, eDoubleClickDir DoubleClickMove,
	byte ClientRoll, int View, optional byte OldTimeDelta, optional int OldAccel
)
{
	local byte PendingCompress;
	local bool bCombine;

	if (PendingMove != None)
	{
		PendingCompress = PendingCompress | int(PendingMove.bRun);
		PendingCompress = PendingCompress | int(PendingMove.bDuck) << 1;
		PendingCompress = PendingCompress | int(NewbPendingJumpStatus) << 2;
		PendingCompress = PendingCompress | int(PendingMove.bDoubleJump) << 3;
		PendingCompress = PendingCompress | int(NewbRun) << 4;
		PendingCompress = PendingCompress | int(NewbDuck) << 5;
		PendingCompress = PendingCompress | int(NewbJumpStatus) << 6;
		PendingCompress = PendingCompress | int(NewbDoubleJump) << 7;

		// send two moves simultaneously
		if (
			(InAccel == vect(0,0,0)) &&
			(PendingMove.StartVelocity == vect(0,0,0)) &&
			(DoubleClickMove == DCLICK_None) &&
			(PendingMove.Acceleration == vect(0,0,0)) &&
			(PendingMove.DoubleClickMove == DCLICK_None) &&
			!PendingMove.bDoubleJump
		)
		{
			if (Pawn == None)
				bCombine = (Velocity == vect(0,0,0));
			else
				bCombine = (Pawn.Velocity == vect(0,0,0));

			if (bCombine)
			{
				if (OldTimeDelta == 0)
					UTComp_ShortServerMove(TimeStamp, ClientLoc, NewbRun, NewbDuck, NewbJumpStatus, ClientRoll, View);
				else
					UTComp_ServerMove(TimeStamp, InAccel, ClientLoc, NewbRun, NewbDuck, NewbJumpStatus, NewbDoubleJump, DoubleClickMove, ClientRoll, View, OldTimeDelta, OldAccel);
				
				return;
			}
		}

		if (OldTimeDelta == 0)
		{
			UTComp_DualServerMove(
				PendingMove.TimeStamp,
				PendingMove.Acceleration * 10,
				PendingCompress,
				PendingMove.DoubleClickMove,
				((0xFFFF & PendingMove.Rotation.Pitch) << 16) | (0xFFFF & PendingMove.Rotation.Yaw),
				TimeStamp,
				InAccel,
				ClientLoc,
				DoubleClickMove,
				ClientRoll,
				View
			);
		}
		else
		{
			UTComp_DualServerMove(
				PendingMove.TimeStamp,
				PendingMove.Acceleration * 10,
				PendingCompress,
				PendingMove.DoubleClickMove,
				((0xFFFF & PendingMove.Rotation.Pitch) << 16) | (0xFFFF & PendingMove.Rotation.Yaw),
				TimeStamp,
				InAccel,
				ClientLoc,
				DoubleClickMove,
				ClientRoll,
				View,
				OldTimeDelta,
				OldAccel
			);
		}
	}
	else if (OldTimeDelta != 0)
	{
		UTComp_ServerMove(TimeStamp, InAccel, ClientLoc, NewbRun, NewbDuck, NewbJumpStatus, NewbDoubleJump, DoubleClickMove, ClientRoll, View, OldTimeDelta, OldAccel);
	}
	else if ((InAccel == vect(0,0,0)) && (DoubleClickMove == DCLICK_None) && !NewbDoubleJump)
	{
		UTComp_ShortServerMove(TimeStamp, ClientLoc, NewbRun, NewbDuck, NewbJumpStatus, ClientRoll, View);
	}
	else
	{
		UTComp_ServerMove(TimeStamp, InAccel, ClientLoc, NewbRun, NewbDuck, NewbJumpStatus, NewbDoubleJump, DoubleClickMove, ClientRoll, View);
	}
}

// ShortServerMove() -- compressed version of server move for bandwidth saving
function UTComp_ShortServerMove(float TimeStamp, vector ClientLoc, bool NewbRun, bool NewbDuck, bool NewbJumpStatus, byte ClientRoll, int View)
{
	UTComp_ServerMove(TimeStamp, vect(0,0,0), ClientLoc, NewbRun, NewbDuck, NewbJumpStatus, false, DCLICK_None, ClientRoll, View);
}

// DualServerMove() - replicated function sent by client to server - contains client movement and firing info for two moves
function UTComp_DualServerMove(
    float TimeStamp0, vector InAccel0, byte PendingCompress, eDoubleClickDir DoubleClickMove0, int View0,
    float TimeStamp, vector InAccel, vector ClientLoc, eDoubleClickDir DoubleClickMove, byte ClientRoll, int View, optional byte OldTimeDelta, optional int OldAccel
)
{
	local bool NewbRun, NewbDuck, NewbJumpStatus ,NewbDoubleJump;
	local bool NewbRun0, NewbDuck0, NewbJumpStatus0, NewbDoubleJump0;

	NewbRun0 =		(PendingCompress & 0x01) != 0;
	NewbDuck0 =		(PendingCompress & 0x02) != 0;
	NewbJumpStatus0 =	(PendingCompress & 0x04) != 0;
	NewbDoubleJump0 =	(PendingCompress & 0x08) != 0;
	NewbRun =		(PendingCompress & 0x10) != 0;
	NewbDuck =		(PendingCompress & 0x20) != 0;
	NewbJumpStatus =	(PendingCompress & 0x40) != 0;
	NewbDoubleJump =	(PendingCompress & 0x80) != 0;

	UTComp_ServerMove(TimeStamp0, InAccel0, vect(0,0,0), NewbRun0, NewbDuck0, NewbJumpStatus0, NewbDoubleJump0, DoubleClickMove0, ClientRoll, View0);
	if (ClientLoc == vect(0, 0, 0))
		ClientLoc = vect(0.1, 0 ,0);

	UTComp_ServerMove(TimeStamp, InAccel, ClientLoc, NewbRun, NewbDuck, NewbJumpStatus, NewbDoubleJump, DoubleClickMove, ClientRoll, View, OldTimeDelta, OldAccel);
}

// ServerMove() - replicated function sent by client to server - contains client movement and firing info.
function UTComp_ServerMove(
    float TimeStamp, vector InAccel, vector ClientLoc, bool NewbRun, bool NewbDuck, bool NewbJumpStatus, bool NewbDoubleJump,
    eDoubleClickDir DoubleClickMove, byte ClientRoll, int View, optional byte OldTimeDelta, optional int OldAccel
)
{
	local float deltaTime, clientErr, OldTimeStamp;
	local rotator DeltaRot, Rot, ViewRot;
	local vector Accel, LocDiff;
	local int maxPitch, ViewPitch, ViewYaw;
	local bool NewbPressedJump, OldbRun, OldbDoubleJump;
	local eDoubleClickDir OldDoubleClickMove;

	// if this move is outdated, discard it.
	if (CurrentTimeStamp >= TimeStamp)
		return;

	if (AcknowledgedPawn != Pawn)
	{
		OldTimeDelta = 0;
		InAccel = vect(0,0,0);
		GivePawn(Pawn);
	}

	// if OldTimeDelta corresponds to a lost packet, process it first
	if (OldTimeDelta != 0)
	{
		OldTimeStamp = TimeStamp - float(OldTimeDelta)/500 - 0.001;
		if (CurrentTimeStamp < OldTimeStamp - 0.001)
		{
			// split out components of lost move (approx)
			Accel.X = OldAccel >>> 23;
			if (Accel.X > 127)
				Accel.X = -1 * (Accel.X - 128);
			Accel.Y = (OldAccel >>> 15) & 255;
			if (Accel.Y > 127)
				Accel.Y = -1 * (Accel.Y - 128);
			Accel.Z = (OldAccel >>> 7) & 255;
			if (Accel.Z > 127)
				Accel.Z = -1 * (Accel.Z - 128);
			Accel *= 20;

			OldbRun = ((OldAccel & 64) != 0);
			OldbDoubleJump = ((OldAccel & 32) != 0);
			NewbPressedJump = ((OldAccel & 16) != 0);
			if (NewbPressedJump)
				bJumpStatus = NewbJumpStatus;

			switch (OldAccel & 7)
			{
				case 0:
					OldDoubleClickMove = DCLICK_None;
					break;
				case 1:
					OldDoubleClickMove = DCLICK_Left;
					break;
				case 2:
					OldDoubleClickMove = DCLICK_Right;
					break;
				case 3:
					OldDoubleClickMove = DCLICK_Forward;
					break;
				case 4:
					OldDoubleClickMove = DCLICK_Back;
					break;
			}
			//log("Recovered move from "$OldTimeStamp$" acceleration "$Accel$" from "$OldAccel);
			OldTimeStamp = FMin(OldTimeStamp, CurrentTimeStamp + MaxResponseTime);
			MoveAutonomous(OldTimeStamp - CurrentTimeStamp, OldbRun, (bDuck == 1), NewbPressedJump, OldbDoubleJump, OldDoubleClickMove, Accel, rot(0,0,0));
			CurrentTimeStamp = OldTimeStamp;
		}
	}

	// View components
	ViewPitch = View >>> 16;
	ViewYaw = View & 0xFFFF;
	// Make acceleration.
	Accel = InAccel * 0.1;

	NewbPressedJump = (bJumpStatus != NewbJumpStatus);
	bJumpStatus = NewbJumpStatus;

	// Save move parameters.
	deltaTime = FMin(MaxResponseTime, TimeStamp - CurrentTimeStamp);

	if (Pawn == None)
	{
		ResetTimeMargin();
	}
	else if (!CheckSpeedHack(deltaTime))
	{
		bWasSpeedHack = true;
		deltaTime = 0;
		Pawn.Velocity = vect(0,0,0);
	}
	else if (bWasSpeedHack)
	{
		// if have had a speedhack detection, then modify deltaTime if getting too far ahead again
		if ((TimeMargin > 0.5 * Level.MaxTimeMargin) && (Level.MaxTimeMargin > 0))
			deltaTime *= 0.8;
	}

	CurrentTimeStamp = TimeStamp;
	ServerTimeStamp = Level.TimeSeconds;
	ViewRot.Pitch = ViewPitch;
	ViewRot.Yaw = ViewYaw;
	ViewRot.Roll = 0;

	if (NewbPressedJump || (InAccel != vect(0,0,0)))
		LastActiveTime = Level.TimeSeconds;

	if (Pawn == None || Pawn.bServerMoveSetPawnRot)
		SetRotation(ViewRot);

	if (AcknowledgedPawn != Pawn)
		return;

	if ((Pawn != None) && Pawn.bServerMoveSetPawnRot)
	{
		Rot.Roll = 256 * ClientRoll;
		Rot.Yaw = ViewYaw;
		if ((Pawn.Physics == PHYS_Swimming) || (Pawn.Physics == PHYS_Flying))
			maxPitch = 2;
		else
			maxPitch = 0;

		if ((ViewPitch > maxPitch * RotationRate.Pitch) && (ViewPitch < 65536 - maxPitch * RotationRate.Pitch))
		{
			if (ViewPitch < 32768)
				Rot.Pitch = maxPitch * RotationRate.Pitch;
			else
				Rot.Pitch = 65536 - maxPitch * RotationRate.Pitch;
		}
		else
		{
			Rot.Pitch = ViewPitch;
		}
		DeltaRot = (Rotation - Rot);
		Pawn.SetRotation(Rot);
	}

	// Perform actual movement
	if ((Level.Pauser == None) && (deltaTime > 0))
		MoveAutonomous(deltaTime, NewbRun, NewbDuck, NewbPressedJump, NewbDoubleJump, DoubleClickMove, Accel, DeltaRot);

	// Accumulate movement error.
	if (ClientLoc == vect(0,0,0))
	{
		return;
	}
	else if (Level.TimeSeconds - LastUpdateTime > 0.3)
	{
		ClientErr = 10000;
	}
	else if (Level.TimeSeconds - LastUpdateTime > 180.0/Player.CurrentNetSpeed)
	{
		if (Pawn == None)
			LocDiff = Location - ClientLoc;
		else
			LocDiff = Pawn.Location - ClientLoc;
		ClientErr = LocDiff Dot LocDiff;
	}

	// if client has accumulated a noticeable positional error, correct him.
	if (ClientErr > 3)
	{
		if (Pawn == None)
		{
			PendingAdjustment.newPhysics = Physics;
			PendingAdjustment.NewLoc = Location;
			PendingAdjustment.NewVel = Velocity;
		}
		else
		{
			PendingAdjustment.newPhysics = Pawn.Physics;
			PendingAdjustment.NewVel = Pawn.Velocity;
			PendingAdjustment.NewBase = Pawn.Base;
			if ((Mover(Pawn.Base) != None) || (Vehicle(Pawn.Base) != None))
				PendingAdjustment.NewLoc = Pawn.Location - Pawn.Base.Location;
			else
				PendingAdjustment.NewLoc = Pawn.Location;
			PendingAdjustment.NewFloor = Pawn.Floor;
		}
		LastUpdateTime = Level.TimeSeconds;

		PendingAdjustmenT.TimeStamp = TimeStamp;
		PendingAdjustment.newState = GetStateName();
	}
}

simulated final function ReceiveWeaponEffect(class<UTComp_WeaponEffect> Effect, Pawn Source,  vector SourceLocation, vector Direction, vector HitLocation, vector HitNormal, int ReflectNum)
{
	Effect.static.Play(self,  Settings, Source, SourceLocation, Normal(Direction/32767),  HitLocation, Normal(HitNormal/32767),  ReflectNum);
}

/*
simulated final function DemoReceiveWeaponEffect(class<UTComp_WeaponEffect> Effect, Pawn Source, vector SourceLocation, vector Direction, vector HitLocation, vector HitNormal, int ReflectNum)
{
	if (LastWeaponEffectSent >= 0)
		return;

	Effect.static.Play(self, Settings, Source, SourceLocation, Normal(Direction/32767), HitLocation,  Normal(HitNormal/32767), ReflectNum);
}
*/
simulated final function SendWeaponEffect(class<UTComp_WeaponEffect> Effect, Pawn Source, vector SourceLocation, vector Direction, vector HitLocation, vector HitNormal, int ReflectNum)
{
	ReceiveWeaponEffect(Effect, Source, SourceLocation, Direction * 32767, HitLocation, HitNormal * 32767, ReflectNum);

	LastWeaponEffectSent = Level.TimeSeconds;
//	DemoReceiveWeaponEffect(Effect, Source, SourceLocation, Direction * 32767, HitLocation, HitNormal * 32767, ReflectNum);
}

defaultproperties
{
	MessageRed=(B=64,G=64,R=255,A=255)
	MessageGreen=(B=128,G=255,R=128,A=255)
	MessageBlue=(B=255,G=192,R=64,A=255)
	MessageYellow=(G=255,R=255,A=255)
	MessageGray=(B=155,G=155,R=255)
	WepStatNames(0)="Combo"
	WepStatNames(1)="I-Gib"
	WepStatNames(2)="Avril"
	WepStatNames(3)="Grenades"
	WepStatNames(4)="Spider"
	WepStatNames(5)="Sniper"
	WepStatNames(6)="Rockets"
	WepStatNames(7)="Flak"
	WepStatNames(8)="Mini"
	WepStatNames(9)="Link"
	WepStatNames(10)="Shock"
	WepStatNames(11)="Bio"
	WepStatNames(12)="Assault"
	WepStatNames(13)="Shield"
	WepStatNames(14)="Crush"
	WepStatDamTypesAlt(6)=class'XWeapons.DamTypeRocketHoming'
	WepStatDamTypesAlt(7)=class'XWeapons.DamTypeFlakShell'
	WepStatDamTypesAlt(8)=class'XWeapons.DamTypeMinigunAlt'
	WepStatDamTypesAlt(9)=class'XWeapons.DamTypeLinkShaft'
	WepStatDamTypesAlt(10)=class'XWeapons.DamTypeShockBall'
	WepStatDamTypesAlt(12)=class'XWeapons.DamTypeAssaultGrenade'
	WepStatDamTypesPrim(0)=class'XWeapons.DamTypeShockCombo'
	WepStatDamTypesPrim(1)=class'XWeapons.DamTypeSuperShockBeam'
	WepStatDamTypesPrim(2)=class'Onslaught.DamTypeONSAVRiLRocket'
	WepStatDamTypesPrim(3)=class'Onslaught.DamTypeONSGrenade'
	WepStatDamTypesPrim(4)=class'Onslaught.DamTypeONSMine'
	WepStatDamTypesPrim(5)=class'XWeapons.DamTypeSniperShot'
	WepStatDamTypesPrim(6)=class'XWeapons.DamTypeRocket'
	WepStatDamTypesPrim(7)=class'XWeapons.DamTypeFlakChunk'
	WepStatDamTypesPrim(8)=class'XWeapons.DamTypeMinigunBullet'
	WepStatDamTypesPrim(9)=class'XWeapons.DamTypeLinkPlasma'
	WepStatDamTypesPrim(10)=class'XWeapons.DamTypeShockBeam'
	WepStatDamTypesPrim(11)=class'XWeapons.DamTypeBioGlob'
	WepStatDamTypesPrim(12)=class'XWeapons.DamTypeAssaultBullet'
	WepStatDamTypesPrim(13)=class'XWeapons.DamTypeShieldImpact'
	WepStatDamTypesPrim(14)=class'Engine.Crushed'
	CustomWepTypes(0)=(WepName="Manta",DamType[0]="Onslaught.DamTypeHoverBikePancake",DamType[1]="Onslaught.DamTypeHoverBikeHeadshot",DamType[2]="Onslaught.DamTypeHoverBikePlasma")
	CustomWepTypes(1)=(WepName="Raptor",DamType[0]="Onslaught.DamTypeAttackCraftPancake",DamType[1]="Onslaught.DamTypeAttackCraftRoadkill",DamType[2]="Onslaught.DamTypeAttackCraftMissle",DamType[3]="Onslaught.DamTypeAttackCraftPlasma")
	CustomWepTypes(2)=(WepName="HBender",DamType[0]="Onslaught.DamTypePRVPancake",DamType[1]="Onslaught.DamTypePRVRoadkill",DamType[2]="Onslaught.DamTypePRVCombo",DamType[3]="Onslaught.DamTypePRVLaser",DamType[4]="Onslaught.DamTypeChargingBeam",DamType[5]="Onslaught.DamTypeSkyMine")
	CustomWepTypes(3)=(WepName="Scorpion",DamType[0]="Onslaught.DamTypeRVPancake",DamType[1]="Onslaught.DamTypeRVRoadkill",DamType[2]="Onslaught.DamTypeONSRVBlade",DamType[3]="Onslaught.DamTypeONSWeb")
	CustomWepTypes(4)=(WepName="Goliath",DamType[0]="Onslaught.DamTypeTankPancake",DamType[1]="Onslaught.DamTypeTankRoadkill",DamType[2]="Onslaught.DamTypeTankShell")
	CustomWepTypes(5)=(WepName="Leviath",DamType[0]="OnslaughtFull.DamTypeMASCannon",DamType[1]="OnslaughtFull.DamTypeMASPlasma",DamType[2]="OnslaughtFull.DamTypeMASRoadKill",DamType[3]="OnslaughtFull.DamTypeMASPanCake")
	CustomWepTypes(6)=(WepName="Fighter",DamType[0]="UT2k4AssaultFull.DamTypeSpaceFighterLaser",DamType[1]="UT2k4AssaultFull.DamTypeSpaceFighterLaser_Skaarj",DamType[2]="UT2k4AssaultFull.DamTypeSpaceFighterMissile",DamType[3]="UT2k4AssaultFull.DamTypeSpaceFighterMissileSkaarj")
	CustomWepTypes(7)=(WepName="IonTank",DamType[0]="OnslaughtFull.DamTypeIonTankBlast",DamType[1]="UT2k4AssaultFull.DamTypeIonCannonBlast")
	CustomWepTypes(8)=(WepName="SuperWep",DamType[0]="XWeapons.DamTypeRedeemer",DamType[1]="XWeapons.DamTypeIonBlast")
	CustomWepTypes(9)=(WepName="Paladin",DamType[0]="OnslaughtBP.DamTypeShockTankProximityExplosion",DamType[1]="OnslaughtBP.DamTypeShockTankShockBall")
	CustomWepTypes(10)=(WepName="Cicada",DamType[0]="OnslaughtBP.DamTypeONSCicadaRocket",DamType[1]="OnslaughtBP.DamTypeONSCicadaLaser")
	CustomWepTypes(11)=(WepName="SPMA",DamType[0]="OnslaughtBP.DamTypeArtilleryShell")
	CustomWepTypes(12)=(WepName="XxxX ESR",DamType[0]="XxxXESRInstaGib",DamType[1]="XxxXESRHeadshot")
	TimeBetweenUpdates=0.011111
	LastWeaponEffectSent=-1.000000
}