class MutUTComp extends Mutator
	Config(fpsGameServer);

//	server
var UTComp_ServerReplicationInfo SRI;
var UTComp_OverlayUpdate OverlayClass;
var UTComp_VotingHandler VotingClass;

var string MainController;
var class<PlayerController> MainControllerClass;

var bool bHasInteraction, bDefaultWeaponsChanged;

struct PowerupInfoStruct
{
	var xPickupBase PickupBase;
	var int Team;
	var float NextRespawnTime;
	var PlayerReplicationInfo LastTaker;
};
var PowerupInfoStruct PowerupInfo[8];

//	mutator
var config byte iBrightskins, iHitsounds;
var config bool bTeamOverlay, bPickupsOverlay;
var config bool bNewScoreboard, bWeaponStats, bPickupStats;
var config bool bNetcode, bShieldFix;

var config int MinNetSpeed, MaxNetSpeed;

//	voting
var config bool bDisableVoting, bBrightskinsVoting, bHitsoundsVoting;
var config bool bTeamOverlayVoting, bPickupsOverlayVoting, bNetcodeVoting;
var config float VotingPercentRequired, VotingTimeLimit;

//	netcode
var PawnCollisionCopy PCC;
var TimeStamp StampInfo;
var FakeProjectileManager FPM;
var Controller TSController;		// timestamp controller
var Pawn TSPawn;				// timestamp pawn

const AVERDT_SEND_PERIOD = 4.00;
var float AverDT, LastReplicatedAverDT;
var float ClientTimeStamp;

var float StampArray[256];
var float counter;

var bool bNetcodeMode;
var array<float> DeltaHistory;
var config float MinNetUpdateRate;
var config float MaxNetUpdateRate;

var class<Weapon> ReplacedWeaponClasses[13];
var class<Weapon> WeaponClasses[13];
var string WeaponClassNames[13];

var class<WeaponPickup> ReplacedWeaponPickupClasses[12];
var class<WeaponPickup> WeaponPickupClasses[12];
var string WeaponPickupClassNames[12];

function PreBeginPlay()
{
	ReplacePawnAndPC();
	SetupStats();
	SetupVoting();
	SetupColoredDeathMessages();
	StaticSaveConfig();
	SetupPowerupInfo();

	bNetcodeMode = bNetcode;

	Super.PreBeginPlay();
}

function SetupPowerupInfo()
{
	local xPickupBase pickupBase;
	local int i;
	local byte shieldPickupCount;
	local byte uDamagePickupCount;
	local byte kegPickupCount;
	local bool forceTeam;

	foreach AllActors(class'xPickupBase', pickupBase)
	{
		if (pickupBase.PowerUp == class'XPickups.SuperShieldPack' || pickupBase.PowerUp == class'XPickups.SuperHealthPack' || pickupBase.PowerUp == class'XPickups.UDamagePack')
		{
			PowerupInfo[i].PickupBase = pickupBase;

			if (pickupBase.myPickUp != None)
				PowerupInfo[i].NextRespawnTime = pickupBase.myPickUp.GetRespawnTime() + pickupBase.myPickup.RespawnEffectTime + Level.GRI.ElapsedTime;

			if (pickupBase.PowerUp == class'XPickups.SuperShieldPack')
				shieldPickupCount++;
			else if (pickupBase.PowerUp == class'XPickups.SuperHealthPack')
				kegPickupCount++;
			else if (pickupBase.PowerUp == class'XPickups.UDamagePack')
				uDamagePickupCount++;

			i++;
			if (i == 8)
			{
				break;
			}
		}
	}

	for(i = 0; i < 8; i++)
	{
		if (PowerupInfo[i].PickupBase == None)
			break;

		forceTeam = false;

		if (PowerupInfo[i].PickupBase.PowerUp == class'XPickups.SuperShieldPack' && shieldPickupCount == 2)
			forceTeam = true;
		else if (PowerupInfo[i].PickupBase.PowerUp == class'XPickups.SuperHealthPack' && kegPickupCount == 2)
			forceTeam = true;
		else if (PowerupInfo[i].PickUpBase.PowerUp == class'XPickups.UDamagePack' && uDamagePickupCount == 2)
			forceTeam = true;

		PowerupInfo[i].Team = GetTeamNum(PowerupInfo[i].PickupBase, forceTeam);
	}
}

function LogPickup(Pawn other, Pickup item)
{
	local int i;

	for(i = 0; i < 8; i++)
	{
		if (PowerupInfo[i].PickupBase == None)
			break;

		if (PowerupInfo[i].PickupBase.myPickup == item)
		{
			PowerupInfo[i].NextRespawnTime = item.GetRespawnTime() - item.RespawnEffectTime + Level.GRI.ElapsedTime;
			PowerupInfo[i].LastTaker = other.PlayerReplicationInfo;
		}
	}

	if (i > 0)
	{
		SortPowerupInfo(0, i-1);
	}
}

function SortPowerupInfo(int low, int high)
{
	local int i, j;
	local float x;
	local PowerupInfoStruct Temp;

	i = Low;
	j = High;
	x = PowerupInfo[(Low + High) / 2].NextRespawnTime;

	// partition
	do
	{
		while (PowerupInfo[i].NextRespawnTime < x)
			i += 1;

		while ((PowerupInfo[j].NextRespawnTime > x) && (x > 0))
			j -= 1;

		if (i <= j)
		{
			// swap array elements, inlined
			Temp = PowerupInfo[i];
			PowerupInfo[i] = PowerupInfo[j];
			PowerupInfo[j] = Temp;
			i += 1;
			j -= 1;
		}
	} until (i > j);

	// recursion
	if (low < j)
		SortPowerupInfo(low, j);

	if (i < high)
		SortPowerupInfo(i, high);
}

function int GetTeamNum(Actor a, bool forceTeam)
{
	local string locationName;
	local Volume V;
	local Volume Best;

	locationName = a.Region.Zone.LocationName;
	if (InStr(Caps(locationName), "RED") != -1)
		return 0;

	if (InStr(Caps(locationName), "BLUE") != -1)
		return 1;

	// For example the 100 in Citadel, we need to find in what volume it is.
	foreach AllActors(class'Volume', V)
	{
		if (V.LocationName == "" || V.LocationName == class'Volume'.default.LocationName)
			continue;

		if ((Best != None) && (V.LocationPriority <= Best.LocationPriority))
			continue;

		if (V.Encompasses(a))
			Best = V;
	}

	if (Best != None)
	{
		Log("BestName" @ a @ Best.LocationName);
		if (Instr(Caps(Best.LocationName), "RED") != -1)
			return 0;

		if (Instr(Caps(Best.LocationName), "BLUE") != -1)
			return 1;
	}

	return 255;
}

function SetupColoredDeathMessages()
{
	if (Level.Game.DeathMessageClass == class'xGame.xDeathMessage')
		Level.Game.DeathMessageClass = class'UTComp_xDeathMessage';
	else if (Level.Game.DeathMessageClass == Class'SkaarjPack.InvasionDeathMessage')
		Level.Game.DeathMessageClass = class'UTComp_InvasionDeathMessage';
}

function ModifyPlayer(Pawn Other)
{
	if (bNetcodeMode)
	{
		SpawnCollisionCopy(Other);
		RemoveOldPawns();
	}

	Super.ModifyPlayer(Other);
}

function DriverEnteredVehicle(Vehicle V, Pawn P)
{
	SpawnCollisionCopy(V);

	if (NextMutator != none)
		NextMutator.DriverEnteredVehicle(V, P);
}

function SpawnCollisionCopy(Pawn Other)
{
	if (PCC == none)
	{
		PCC = Spawn(class'PawnCollisionCopy');
		PCC.SetPawn(Other);
	}
	else
	{
		PCC.AddPawnToList(Other);
	}
}

function RemoveOldPawns()
{
	PCC = PCC.RemoveOldPawns();
}

function ListPawns()
{
	local PawnCollisionCopy PCC2;

	for(PCC2 = PCC; PCC2 != None; PCC2 = PCC2.Next)
		PCC2.Identify();
}

static function bool IsPredicted(actor A)
{
	if (A == none || xPawn(A) != None)
		return true;

	if ((Vehicle(A) != None && Vehicle(A).Driver != None))
		return true;

	return false;
}

function SetupTeamOverlay()
{
	if ((!bTeamOverlay && !bPickupsOverlay))	// || !Level.Game.bTeamGame)
		return;

	if (OverlayClass == None)
	{
		OverlayClass = Spawn(class'UTComp_OverlayUpdate', self);
		OverlayClass.UTCompMutator = self;
		OverlayClass.InitializeOverlay();
	}
}

function SetupVoting()
{
	if (bDisableVoting)
		return;

	if (VotingClass == None)
	{
		VotingClass = Spawn(class'UTComp_VotingHandler', self);
		VotingClass.fVotingTime = VotingTimeLimit;
		VotingClass.fVotingPercent = VotingPercentRequired;
		VotingClass.InitializeVoting();
		VotingClass.UTCompMutator = self;
	}
}

function SetupStats()
{
	class'xWeapons.TransRecall'.default.Transmaterials[0] = None;
	class'xWeapons.TransRecall'.default.Transmaterials[1] = None;

	if (!bWeaponStats)
		return;

	if (bNetcode)
		class'xWeapons.ShieldFire'.default.AutoFireTestFreq = 0.05;

	class'xWeapons.AssaultRifle'.default.FireModeClass[0] = class'UTComp_AssaultFire';
	class'xWeapons.AssaultRifle'.default.FireModeClass[1] = class'UTComp_AssaultGrenade';

	class'xWeapons.BioRifle'.default.FireModeClass[0] = class'UTComp_BioFire';
	class'xWeapons.BioRifle'.default.FireModeClass[1] = class'UTComp_BioChargedFire';

	class'xWeapons.ShockRifle'.default.FireModeClass[0] = class'UTComp_ShockBeamFire';
	class'xWeapons.ShockRifle'.default.FireModeClass[1] = class'UTComp_ShockProjFire';

	class'xWeapons.LinkGun'.default.FireModeClass[0] = class'UTComp_LinkAltFire';
	class'xWeapons.LinkGun'.default.FireModeClass[1] = class'UTComp_LinkFire';

	class'xWeapons.MiniGun'.default.FireModeClass[0] = class'UTComp_MinigunFire';
	class'xWeapons.MiniGun'.default.FireModeClass[1] = class'UTComp_MinigunAltFire';

	class'xWeapons.FlakCannon'.default.FireModeClass[0] = class'UTComp_FlakFire';
	class'xWeapons.FlakCannon'.default.FireModeClass[1] = class'UTComp_FlakAltFire';

	class'xWeapons.RocketLauncher'.default.FireModeClass[0] = class'UTComp_RocketFire';
	class'xWeapons.RocketLauncher'.default.FireModeClass[1] = class'UTComp_RocketMultiFire';

	class'xWeapons.SniperRifle'.default.FireModeClass[0] = class'UTComp_SniperFire';
	class'UTClassic.ClassicSniperRifle'.default.FireModeClass[0] = class'UTComp_ClassicSniperFire';

	class'Onslaught.ONSMineLayer'.default.FireModeClass[0] = class'UTComp_ONSMineThrowFire';

	class'Onslaught.ONSGrenadeLauncher'.default.FireModeClass[0] = class'UTComp_ONSGrenadeFire';

	class'OnsLaught.ONSAvril'.default.FireModeClass[0] = class'UTComp_ONSAvrilFire';

	class'xWeapons.SuperShockRifle'.default.FireModeClass[0] = class'UTComp_SuperShockBeamFire';
	class'xWeapons.SuperShockRifle'.default.FireModeClass[1] = class'UTComp_SuperShockBeamFire';
}

simulated function Tick(float deltaTime)
{
	local PlayerController PC;
	local Mutator M;
	local int x;

	if (Level.NetMode == NM_DedicatedServer)
	{
		if (bNetcodeMode)
		{
			if (bDefaultWeaponsChanged)
			{
				return;
			}
			else
			{
				for(M = Level.Game.BaseMutator; M != None; M = M.NextMutator)
				{
					if (M.DefaultWeaponName != "")
					{
						for(x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
						{
							if (M.DefaultWeaponName ~= WeaponClassNames[x])
							{
								M.DefaultWeaponName = string(WeaponClasses[x]);
								bDefaultWeaponsChanged = true;
							}
						}
					}
				}
			}

			ClientTimeStamp += deltaTime;
			counter += 1;
			StampArray[counter%256] = ClientTimeStamp;
			AverDT = (9.0*AverDT + deltaTime) * 0.1;
			SetPawnStamp();
			if (ClientTimeStamp > LastReplicatedAverDT + AVERDT_SEND_PERIOD)
			{
				StampInfo.ReplicatedAverDT(AverDT);
				LastReplicatedAverDT = ClientTimeStamp;
			}
		}

		return;
	}

	if (FPM == None && Level.NetMode == NM_Client)
		FPM = Spawn(Class'FakeProjectileManager');

	if (bHasInteraction)
		return;

	PC = Level.GetLocalPlayerController();
	if (PC != None)
	{
		BS_xPlayer(PC).Overlay = UTComp_Overlay(PC.Player.InteractionMaster.AddInteraction(string(class'UTComp_Overlay'), PC.Player));
		bHasInteraction = true;
		class'DamTypeLinkShaft'.default.bSkeletize = false;
	}
}

function SetPawnStamp()
{
	local rotator R;
	local int i;

	if (TSPawn == none)
	{
		if (TSController == none)
			TSController = Spawn(class'TimeStamp_Controller');

		if (TSController.Pawn != none)
			TSPawn = TSController.Pawn;

		return;
	}

	R.Yaw = (counter%256)*256;
	i = counter/256;
	R.Pitch = i*256;

	TSPawn.SetRotation(R);
}

simulated function float GetStamp(int stamp)
{
	return StampArray[stamp%256];
}

function ReplacePawnAndPC()
{
	if (Level.Game.DefaultPlayerClassName ~= "xGame.xPawn")
		Level.Game.DefaultPlayerClassName = string(class'UTComp_xPawn');

	if (class'xPawn'.default.ControllerClass == class'XGame.XBot')
		class'xPawn'.default.ControllerClass = class'UTComp_xBot';

	Level.Game.PlayerControllerClassName = string(class'BS_xPlayer');
}

function SpawnReplicationClass()
{
	if (SRI == none)
		SRI = Spawn(class'UTComp_ServerReplicationInfo', self);

//	Voting Replication
	SRI.b_NoVoting = bDisableVoting;
	SRI.b_BrightskinsVoting = bBrightskinsVoting;
	SRI.b_HitsoundsVoting = bHitsoundsVoting;
	SRI.b_TeamOverlayVoting = bTeamOverlayVoting;
	SRI.b_PickupsOverlayVoting = bPickupsOverlayVoting;
	SRI.b_NetcodeVoting = bNetcodeVoting;
//	Client Replication
	SRI.i_Brightskins = Clamp(iBrightskins, 1, 3);
	SRI.i_Hitsounds = iHitsounds;
	SRI.b_TeamOverlay = bTeamOverlay;
	SRI.b_PickupsOverlay = bPickupsOverlay;
	SRI.b_NewScoreboard = bNewScoreboard;
	SRI.b_WeaponStats = bWeaponStats;
	SRI.b_PickupStats = bPickupStats;
	SRI.b_Netcode = bNetcode;

	SRI.MinNetSpeed = MinNetSpeed;
	SRI.MaxNetSpeed = MaxNetSpeed;
	SRI.bShieldFix = bShieldFix;
}

function PostBeginPlay()
{
	local UTComp_GameRules G;
	local string URL;

	Super.PostBeginPlay();

	URL = Level.GetLocalURL();
	URL = Mid(URL, InStr(URL, "?"));
	ParseURL(URL);
	SetupTeamOverlay();

	SpawnReplicationClass();

	G = Spawn(class'UTComp_GameRules');
	G.UTCompMutator = self;

	if (Level.Game.GameRulesModifiers == none)
		Level.Game.GameRulesModifiers = G;
	else
		Level.Game.GameRulesModifiers.AddGameRules(G);

	if (StampInfo == none && bNetcodeMode)
		StampInfo = Spawn(class'TimeStamp');
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local LinkedReplicationInfo LinkedPRI;
	local int x, i;
	local WeaponLocker L;

	bSuperRelevant = 0;

	if (bNetcodeMode)
	{
		if (xWeaponBase(Other) != None)
		{
			for(x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
			{
				if (xWeaponBase(Other).WeaponType == ReplacedWeaponClasses[x])
					xWeaponBase(Other).WeaponType = WeaponClasses[x];
			}
			return true;
		}
		else if (WeaponPickup(Other) != None)
		{
			for(x = 0; x < ArrayCount(ReplacedWeaponPickupClasses); x++)
			{
				if (Other.Class == ReplacedWeaponPickupClasses[x])
				{
					ReplaceWith(Other, WeaponPickupClassNames[x]);
					return false;
				}
			}
		}
		else if (WeaponLocker(Other) != None)
		{
			L = WeaponLocker(Other);
			for(x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
			{
				for(i = 0; i < L.Weapons.Length; i++)
				{
					if (L.Weapons[i].WeaponClass == ReplacedWeaponClasses[x])
						L.Weapons[i].WeaponClass = WeaponClasses[x];
				}
			}
			return true;
		}
	}

	if (PlayerReplicationInfo(Other) != None)
	{
		if (PlayerReplicationInfo(Other).CustomReplicationInfo != None)
		{
			LinkedPRI = PlayerReplicationInfo(Other).CustomReplicationInfo;
			while(LinkedPRI.NextReplicationInfo != None)
			{
				LinkedPRI = LinkedPRI.NextReplicationInfo;
			}
			LinkedPRI.NextReplicationInfo = Spawn(class'UTComp_PRI', Other.Owner);

			if (bNetcodeMode)
				LinkedPRI.NextReplicationInfo.NextReplicationInfo = Spawn(class'NewNet_PRI', Other.Owner);
		}
		else
		{
			PlayerReplicationInfo(Other).CustomReplicationInfo = Spawn(class'UTComp_PRI', Other.Owner);
			if (bNetcodeMode)
				PlayerReplicationInfo(Other).CustomReplicationInfo.NextReplicationInfo = Spawn(class'NewNet_PRI', Other.Owner);
		}
	}

	return true;
}

function bool SniperCheckReplacement( Actor Other, out byte bSuperRelevant )
{
	local int i;
	local WeaponLocker L;

	bSuperRelevant = 0;
	if (xWeaponBase(Other) != None)
	{
		if (xWeaponBase(Other).WeaponType == class'UTClassic.ClassicSniperRifle')
			xWeaponBase(Other).WeaponType = class'XWeapons.SniperRifle';
	}
	else if (ClassicSniperRiflePickup(Other) != None)
	{
		ReplaceWith(Other, "XWeapons.SniperRiflePickup");
	}
	else if (ClassicSniperAmmoPickup(Other) != None)
	{
		ReplaceWith(Other, "XWeapons.SniperAmmoPickup");
	}
	else if (WeaponLocker(Other) != None)
	{
		L = WeaponLocker(Other);
		for(i = 0; i < L.Weapons.Length; i++)
		{
			if (L.Weapons[i].WeaponClass == class'ClassicSniperRifle')
				L.Weapons[i].WeaponClass = class'SniperRifle';
		}
		return true;
	}
	else
	{
		return true;
	}

	return false;
}

function ModifyLogin(out string Portal, out string Options)
{
	local bool bSeeAll, bSpectator;

	if (Level.Game == none)
	{
		Log ("utv2004s: Level.Game is none?");
		return;
	}

	if (MainController != "")
	{
		Level.Game.PlayerControllerClassName = MainController;
		Level.Game.PlayerControllerClass = MainControllerClass;
		MainController = "";
	}

	bSpectator = (Level.Game.ParseOption(Options, "SpectatorOnly") ~= "1");
	bSeeAll = (Level.Game.ParseOption(Options, "UTVSeeAll") ~= "true");

	if (bSeeAll && bSpectator)
	{
		Log ("utv2004s: Creating utv Controller");
		MainController = Level.Game.PlayerControllerClassName;
		MainControllerClass = Level.Game.PlayerControllerClass;
		Level.Game.PlayerControllerClassName = string(class'UTV_BS_xPlayer');
		Level.Game.PlayerControllerClass = none;
	}

	if (Level.Game.ScoreBoardType ~= "SkaarjPack.ScoreboardInvasion")
	{
		if (bNewScoreBoard)
			Level.Game.ScoreBoardType = string(class'UTComp_ScoreBoard');
		else
			Level.Game.ScoreBoardType = string(class'UTComp_ScoreBoardDM');
	}

	Super.ModifyLogin(Portal, Options);
}

function ServerTraveling(string URL, bool bItems)
{
	class'xPawn'.default.ControllerClass = class'xGame.xBot';

	class'xWeapons.AssaultRifle'.default.FireModeClass[0] = class'xWeapons.AssaultFire';
	class'xWeapons.AssaultRifle'.default.FireModeClass[1] = class'xWeapons.AssaultGrenade';

	class'xWeapons.BioRifle'.default.FireModeClass[0] = class'xWeapons.BioFire';
	class'xWeapons.BioRifle'.default.FireModeClass[1] = class'xWeapons.BioChargedFire';

	class'xWeapons.ShockRifle'.default.FireModeClass[0] = class'xWeapons.ShockBeamFire';
	class'xWeapons.ShockRifle'.default.FireModeClass[1] = class'xWeapons.ShockProjFire';

	class'xWeapons.LinkGun'.default.FireModeClass[0] = class'xWeapons.LinkAltFire';
	class'xWeapons.LinkGun'.default.FireModeClass[1] = class'xWeapons.LinkFire';

	class'xWeapons.MiniGun'.default.FireModeClass[0] = class'xWeapons.MinigunFire';
	class'xWeapons.MiniGun'.default.FireModeClass[1] = class'xWeapons.MinigunAltFire';

	class'xWeapons.FlakCannon'.default.FireModeClass[0] = class'xWeapons.FlakFire';
	class'xWeapons.FlakCannon'.default.FireModeClass[1] = class'xWeapons.FlakAltFire';

	class'xWeapons.RocketLauncher'.default.FireModeClass[0] = class'xWeapons.RocketFire';
	class'xWeapons.RocketLauncher'.default.FireModeClass[1] = class'xWeapons.RocketMultiFire';

	class'xWeapons.SniperRifle'.default.FireModeClass[0] = class'xWeapons.SniperFire';
	class'UTClassic.ClassicSniperRifle'.default.FireModeClass[0] = class'UTClassic.ClassicSniperFire';

	class'Onslaught.ONSMineLayer'.default.FireModeClass[0] = class'Onslaught.ONSMineThrowFire';

	class'Onslaught.ONSGrenadeLauncher'.default.FireModeClass[0] = class'UTComp_ONSGrenadeFire';

	class'OnsLaught.ONSAvril'.default.FireModeClass[0] = class'Onslaught.ONSAvrilFire';

	class'xWeapons.SuperShockRifle'.default.FireModeClass[0] = class'xWeapons.SuperShockBeamFire';
	class'xWeapons.SuperShockRifle'.default.FireModeClass[1] = class'xWeapons.SuperShockBeamFire';

	ParseURL(Url);

	Super.ServerTraveling(URL, bItems);
}

function ParseURL(string Url)
{
	local string Skinz0r, Sounds, Overlay, PickupsOverlay, NewNetcode;
	local array<string> Parts;
	local int i;

	Split(Url, "?", Parts);

	for(i = 0; i < Parts.Length; i++)
	{
		if (Parts[i] != "")
		{
			if (Left(Parts[i], Len("BrightSkinsMode")) ~= "BrightSkinsMode")
				Skinz0r = Right(Parts[i], Len(Parts[i])-Len("BrightSkinsMode")-1);

			if (Left(Parts[i], Len("HitSoundsMode")) ~= "HitSoundsMode")
				Sounds = Right(Parts[i], Len(Parts[i])-Len("HitSoundsMode")-1);

			if (Left(Parts[i], Len("EnableTeamOverlay")) ~= "EnableTeamOverlay")
				Overlay = Right(Parts[i], Len(Parts[i])-Len("EnableTeamOverlay")-1);

			if (Left(Parts[i], Len("EnablePickupsOverlay")) ~= "EnablePickupsOverlay")
				PickupsOverlay = Right(Parts[i], Len(Parts[i])-Len("EnablePickupsOverlay")-1);

			if (Left(Parts[i], Len("EnableEnhancedNetcode")) ~= "EnableEnhancedNetcode")
				NewNetcode = Right(Parts[i], Len(Parts[i])-Len("EnableEnhancedNetcode")-1);
		}
	}

	if (Skinz0r != "" && int(Skinz0r) < 4 && int(Skinz0r) > 0)
	{
		default.iBrightskins = int(Skinz0r);
		iBrightskins = default.iBrightskins;
	}

	if (Sounds != "" && int(Sounds) < 3 && int(Sounds) >= 0)
	{
		default.iHitsounds = int(Sounds);
		iHitsounds = default.iHitsounds;
	}

	if (Overlay != "" && (Overlay ~= "False" || Overlay ~= "True"))
	{
		default.bTeamOverlay = (Overlay ~= "True");
		bTeamOverlay = default.bTeamOverlay;
	}

	if (PickupsOverlay != "" && (PickupsOverlay ~= "False" || PickupsOverlay ~= "True"))
	{
		default.bPickupsOverlay = (PickupsOverlay ~= "True");
		bPickupsOverlay = default.bPickupsOverlay;
	}

	if (NewNetcode != "" && (NewNetcode ~= "false" || NewNetcode ~= "True"))
	{
		default.bNetcode = (NewNetcode ~= "True");
		bNetcodeMode = default.bNetcode;
		bNetcode = default.bNetcode;
	}

	StaticSaveConfig();
}

function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
	Super.GetServerDetails(ServerState);

	Level.Game.AddServerDetail(ServerState, "Enhanced Netcode", string(bNetcodeMode));
}

static function FillPlayInfo (PlayInfo PlayInfo)
{
	PlayInfo.AddClass(default.Class);

	PlayInfo.AddSetting("UTComp Settings", "bDisableVoting", "Disables Voting", 1, 1, "Check");
	PlayInfo.AddSetting("UTComp Settings", "bBrightskinsVoting", "Allow players to vote on Brightskins settings", 1, 1,"Check");
	PlayInfo.AddSetting("UTComp Settings", "bHitsoundsVoting", "Allow players to vote on Hitsounds settings", 1, 1,"Check");
	PlayInfo.AddSetting("UTComp Settings", "bTeamOverlayVoting", "Allow players to vote on team overlay setting", 1, 1,"Check");
	PlayInfo.AddSetting("UTComp Settings", "bPickupsOverlayVoting", "Allow players to vote on pickups overlay setting", 1, 1,"Check");
	PlayInfo.AddSetting("UTComp Settings", "bNetcodeVoting", "Allow players to vote on enhanced netcode setting", 1, 1,"Check");
	PlayInfo.AddSetting("UTComp Settings", "iBrightskins", "Brightskins Mode", 1, 1, "Select", "0;Disabled;1;Epic Style;2;BrighterEpic Style;3;UTComp Style");
	PlayInfo.AddSetting("UTComp Settings", "iHitsounds", "Hitsounds Mode", 1, 1, "Select", "0;Disabled;1;Line Of Sight;2;Everywhere");
	PlayInfo.AddSetting("UTComp Settings", "bTeamOverlay", "Enable Team Overlay", 1, 1, "Check");
	PlayInfo.AddSetting("UTComp Settings", "bPickupsOverlay", "Enable Pickups Overlay for spectators", 1, 1, "Check");
	PlayInfo.AddSetting("UTComp Settings", "bNetcode", "Enable Enhanced Netcode", 1, 1, "Check");
	PlayInfo.AddSetting("UTComp Settings", "MinNetSpeed", "Minimum NetSpeed for Clients",255, 1, "Text","0;0:100000",);
	PlayInfo.AddSetting("UTComp Settings", "MaxNetSpeed", "Maximum NetSpeed for Clients",255, 1, "Text","0;0:100000",);
	PlayInfo.AddSetting("UTComp Settings", "MinNetUpdateRate", "Minimum rate of client updates", 1, 1, "Text", "0;0:999",, True, True);
	PlayInfo.AddSetting("UTComp Settings", "MaxNetUpdateRate", "Maximum rate of client updates", 1, 1, "Text", "0;0:999",, True, True);

	PlayInfo.PopClass();
	Super.FillPlayInfo(PlayInfo);
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bDisableVoting":			return "Check this to disable all voting options.";
		case "bBrightSkinsVoting":		return "Check this to enable voting for brightskins.";
		case "bHitsoundsVoting":		return "Check this to enable voting for hitsounds.";
		case "bTeamOverlayVoting":		return "Check this to enable voting for Team Overlay.";
		case "bPickupsOverlayVoting":		return "Check this to enable voting for pickups overlay for spectators.";
		case "bNetcodeVoting":			return "Check this to enable voting for Enhanced Netcode.";
		case "iBrightskins":			return "Sets the server-forced brightskins mode.";
		case "iHitsounds":			return "Sets the server-Forced hitsound mode.";
		case "bTeamOverlay":			return "Check this to enable the team overlay.";
		case "bPickupsOverlay":			return "Check this to enable the pickups overlay for spectators.";
		case "bNetcode":				return "Check this to enable the enhanced netcode.";
		case "MinNetSpeed":			return "Minimum NetSpeed for clients on this server";
		case "MaxNetSpeed":			return "Maximum NetSpeed for clients on this server";
		case "MinNetUpdateRate":		return "Minimum Rate at which clients are expected to send updates to the server";
		case "MaxNetUpdateRate":		return "Maximum Rate at which clients can send updates to the server";
	}

	return Super.GetDescriptionText(PropName);
}

function bool ReplaceWith(Actor Other, string aClassName)
{
	local Actor A;
	local class<Actor> aClass;

	if (aClassName == "")
		return true;

	aClass = class<Actor>(DynamicLoadObject(aClassName, class'Class'));
	if (aClass != None)
		A = Spawn(aClass, Other.Owner, Other.tag, Other.Location, Other.Rotation);

	if (Pickup(Other) != None)
	{
		if (Pickup(Other).MyMarker != None)
		{
			Pickup(Other).MyMarker.markedItem = Pickup(A);
			if (Pickup(A) != None)
			{
				Pickup(A).MyMarker = Pickup(Other).MyMarker;
				A.SetLocation(A.Location + (A.CollisionHeight - Other.CollisionHeight) * vect(0,0,1));
			}
			Pickup(Other).MyMarker = None;
		}
		else if (Pickup(A) != None && WeaponPickup(A) == None)
		{
			Pickup(A).RespawnTime = 0.0;
		}
	}

	if (A != None)
	{
		A.event = Other.event;
		A.tag = Other.tag;
		return true;
	}

	return false;
}

function string GetInventoryClassOverride(string InventoryClassName)
{
	local int x;

	if (bNetcodeMode)
	{
		for(x = 0; x < ArrayCount(WeaponClassNames); x++)
		{
			if (InventoryClassName ~= WeaponClassNames[x])
				return string(WeaponClasses[x]);
		}
	}

	if (NextMutator != None)
		return NextMutator.GetInventoryClassOverride(InventoryClassName);

	return InventoryClassName;
}

defaultproperties
{
	bDisableVoting=false
	bBrightskinsVoting=true
	bHitsoundsVoting=true
	bTeamOverlayVoting=true
	bPickupsOverlayVoting=true
	bNetcodeVoting=true
	VotingPercentRequired=51.000000
	VotingTimeLimit=30.000000
	iBrightskins=3
	iHitsounds=1
	bTeamOverlay=true
	bPickupsOverlay=true
	bNewScoreboard=true
	bWeaponStats=true
	bPickupStats=true
	bShieldFix=true
	MinNetSpeed=5000
	MaxNetSpeed=30000
	MinNetUpdateRate=60.000000
	MaxNetUpdateRate=250.000000
	WeaponClasses(0)=class'NewNet_ShockRifle'
	WeaponClasses(1)=class'NewNet_LinkGun'
	WeaponClasses(2)=class'NewNet_MiniGun'
	WeaponClasses(3)=class'NewNet_FlakCannon'
	WeaponClasses(4)=class'NewNet_RocketLauncher'
	WeaponClasses(5)=class'NewNet_SniperRifle'
	WeaponClasses(6)=class'NewNet_BioRifle'
	WeaponClasses(7)=class'NewNet_AssaultRifle'
	WeaponClasses(8)=class'NewNet_ClassicSniperRifle'
	WeaponClasses(9)=class'NewNet_ONSAvril'
	WeaponClasses(10)=class'NewNet_ONSMineLayer'
	WeaponClasses(11)=class'NewNet_ONSGrenadeLauncher'
	WeaponClasses(12)=class'NewNet_SuperShockRifle'
	WeaponClassNames(0)="xWeapons.ShockRifle"
	WeaponClassNames(1)="xWeapons.LinkGun"
	WeaponClassNames(2)="xWeapons.MiniGun"
	WeaponClassNames(3)="xWeapons.FlakCannon"
	WeaponClassNames(4)="xWeapons.RocketLauncher"
	WeaponClassNames(5)="xWeapons.SniperRifle"
	WeaponClassNames(6)="xWeapons.BioRifle"
	WeaponClassNames(7)="xWeapons.AssaultRifle"
	WeaponClassNames(8)="UTClassic.ClassicSniperRifle"
	WeaponClassNames(9)="Onslaught.ONSAVRiL"
	WeaponClassNames(10)="Onslaught.ONSMineLayer"
	WeaponClassNames(11)="Onslaught.ONSGrenadeLauncher"
	WeaponClassNames(12)="xWeapons.SuperShockRifle"
	ReplacedWeaponClasses(0)=class'XWeapons.ShockRifle'
	ReplacedWeaponClasses(1)=class'XWeapons.LinkGun'
	ReplacedWeaponClasses(2)=class'XWeapons.Minigun'
	ReplacedWeaponClasses(3)=class'XWeapons.FlakCannon'
	ReplacedWeaponClasses(4)=class'XWeapons.RocketLauncher'
	ReplacedWeaponClasses(5)=class'XWeapons.SniperRifle'
	ReplacedWeaponClasses(6)=class'XWeapons.BioRifle'
	ReplacedWeaponClasses(7)=class'XWeapons.AssaultRifle'
	ReplacedWeaponClasses(8)=class'UTClassic.ClassicSniperRifle'
	ReplacedWeaponClasses(9)=class'Onslaught.ONSAVRiL'
	ReplacedWeaponClasses(10)=class'Onslaught.ONSMineLayer'
	ReplacedWeaponClasses(11)=class'Onslaught.ONSGrenadeLauncher'
	ReplacedWeaponClasses(12)=class'XWeapons.SuperShockRifle'
	ReplacedWeaponPickupClasses(0)=class'XWeapons.ShockRiflePickup'
	ReplacedWeaponPickupClasses(1)=class'XWeapons.LinkGunPickup'
	ReplacedWeaponPickupClasses(2)=class'XWeapons.MinigunPickup'
	ReplacedWeaponPickupClasses(3)=class'XWeapons.FlakCannonPickup'
	ReplacedWeaponPickupClasses(4)=class'XWeapons.RocketLauncherPickup'
	ReplacedWeaponPickupClasses(5)=class'XWeapons.SniperRiflePickup'
	ReplacedWeaponPickupClasses(6)=class'XWeapons.BioRiflePickup'
	ReplacedWeaponPickupClasses(7)=class'XWeapons.AssaultRiflePickup'
	ReplacedWeaponPickupClasses(8)=class'UTClassic.ClassicSniperRiflePickup'
	ReplacedWeaponPickupClasses(9)=class'Onslaught.ONSAVRiLPickup'
	ReplacedWeaponPickupClasses(10)=class'Onslaught.ONSMineLayerPickup'
	ReplacedWeaponPickupClasses(11)=class'Onslaught.ONSGrenadePickup'
	WeaponPickupClasses(0)=class'NewNet_ShockRiflePickup'
	WeaponPickupClasses(1)=class'NewNet_LinkGunPickup'
	WeaponPickupClasses(2)=class'NewNet_MiniGunPickup'
	WeaponPickupClasses(3)=class'NewNet_FlakCannonPickup'
	WeaponPickupClasses(4)=class'NewNet_RocketLauncherPickup'
	WeaponPickupClasses(5)=class'NewNet_SniperRiflePickup'
	WeaponPickupClasses(6)=class'NewNet_BioRiflePickup'
	WeaponPickupClasses(7)=class'NewNet_AssaultRiflePickup'
	WeaponPickupClasses(8)=class'NewNet_ClassicSniperRiflePickup'
	WeaponPickupClasses(9)=class'NewNet_ONSAVRiLPickup'
	WeaponPickupClasses(10)=class'NewNet_ONSMineLayerPickup'
	WeaponPickupClasses(11)=class'NewNet_ONSGrenadePickup'
	WeaponPickupClassNames(0)="fpsGame.NewNet_ShockRiflePickup"
	WeaponPickupClassNames(1)="fpsGame.NewNet_LinkGunPickup"
	WeaponPickupClassNames(2)="fpsGame.NewNet_MiniGunPickup"
	WeaponPickupClassNames(3)="fpsGame.NewNet_FlakCannonPickup"
	WeaponPickupClassNames(4)="fpsGame.NewNet_RocketLauncherPickup"
	WeaponPickupClassNames(5)="fpsGame.NewNet_SniperRiflePickup"
	WeaponPickupClassNames(6)="fpsGame.NewNet_BioRiflePickup"
	WeaponPickupClassNames(7)="fpsGame.NewNet_AssaultRiflePickup"
	WeaponPickupClassNames(8)="fpsGame.NewNet_ClassicSniperRiflePickup"
	WeaponPickupClassNames(9)="fpsGame.NewNet_ONSAVRiLPickup"
	WeaponPickupClassNames(10)="fpsGame.NewNet_ONSMineLayerPickup"
	WeaponPickupClassNames(11)="fpsGame.NewNet_ONSGrenadePickup"
	bAddToServerPackages=true
	FriendlyName="UTComp Black"
	Description="A mutator for brightskins, hitsounds, and various other features.|edited for fps invasion -voltz"
	bNetTemporary=true
	bAlwaysRelevant=true
	RemoteRole=ROLE_SimulatedProxy
}