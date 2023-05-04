class UTComp_PRI extends LinkedReplicationInfo;

var int PickedUpFifty;
var int PickedUpHundred;
var int PickedUpAmp;
var int PickedUpVial;
var int PickedUpHealth;
var int PickedUpKeg;
var int PickedUpAdren;

var int NormalWepStatsAlt[15];
var int NormalWepStatsPrim[15];

var int NormalWepStatsAltHit[15];
var int NormalWepStatsPrimHit[15];

var int NormalWepStatsAltPercent[15];
var int NormalWepStatsPrimPercent[15];

var int NormalWepStatsAltDamage[15];
var int NormalWepStatsPrimDamage[15];

var string ColoredName;
var int RealKills;

var byte GetTeamX;

var byte Vote;
var byte VoteSwitch;
var byte VoteSwitch2;
var byte VotedYes, VotedNo;
var bool bShowSelf;
var string VoteOptions;
var string VoteOptions2;

var bool bSendWepStats;

var int DamR, DamG;

var byte CurrentVoteID;
var bool bIsLegitPlayer;
var int TotalDamageG;

const iMAXPLAYERS = 8;

struct TeamOverlayInfo
{
	var byte Armor;
	var byte Weapon;
	var int Health;
	var PlayerReplicationInfo PRI;
};
var TeamOverlayInfo OverlayInfoRed[iMAXPLAYERS];
var TeamOverlayInfo OverlayInfoBlue[iMAXPLAYERS];

var byte bHasDDRed[iMAXPLAYERS];
var byte bHasDDBlue[iMAXPLAYERS];

struct PowerupInfoStruct
{
	var Pickup Pickup;
	var int Team;
	var float NextRespawnTime;
	var PlayerReplicationInfo LastTaker;
};
var PowerupInfoStruct PowerupInfo[8];

var localized string WepStatNames[15];
var string HitPrim, HitAlt, FiredPrim, FiredAlt, DamagePrim, DamageAlt;

replication
{
	reliable if (Role == ROLE_Authority)
		GetTeamX, CurrentVoteID, ColoredName, RealKills;

	unreliable if (Role == ROLE_Authority && bNetOwner)
		PickedUpFifty, PickedUpHundred, PickedUpAmp, PickedUpVial, PickedUpHealth, PickedUpKeg,
		PickedUpAdren, DamR, VoteSwitch, VoteOptions, Vote, VoteOptions2, VoteSwitch2;

	unreliable if (Role == ROLE_Authority && bNetOwner && bSendWepStats)
		NormalWepStatsPrim, NormalWepStatsAlt;

	unreliable if (Role == ROLE_Authority && bNetOwner)
		OverlayInfoRed, OverlayInfoBlue, bHasDDRed, bHasDDBlue, VotedYes, VotedNo, PowerupInfo;

	reliable if (Role < ROLE_Authority)
		SetVoteMode, SetTeamX, CallVote, PassVote, SetColoredName, SetShowSelf;
}

simulated function UpdatePercentages()
{
	local int i;

	for(i = 0; i < ArrayCount(NormalWepStatsPrim); i++)
	{
		if (NormalWepStatsPrim[i] > 0)
			NormalWepStatsPrimPercent[i] = float(NormalWepStatsPrimHit[i]) / float(NormalWepStatsPrim[i])*100.0;
	}

	for(i = 0; i < ArrayCount(NormalWepStatsAlt); i++)
	{
		if (NormalWepStatsAlt[i] > 0)
			NormalWepStatsAltPercent[i] = float(NormalWepStatsAltHit[i]) / float(NormalWepStatsAlt[i])*100.0;
	}
}

function CallVote(byte b, byte switch, string Options, optional string Caller, optional byte P2, optional string Options2)
{
	local UTComp_VotingHandler uVote;

	foreach DynamicActors(class'UTComp_VotingHandler', uVote)
	{
		if (uVote.StartVote(b, switch, Options, caller, p2, options2, false))
			Vote = 1;
	}
}

function PassVote(byte b, byte switch, string Options, optional string Caller, optional byte P2, optional string Options2)
{
	local UTComp_VotingHandler uVote;

	if (Owner == none || Controller(Owner) == none || Controller(Owner).PlayerReplicationInfo == none || !Controller(Owner).PlayerReplicationInfo.bAdmin)
		return;

	foreach DynamicActors(class'UTComp_VotingHandler', uVote)
	{
		if (uVote.StartVote(b, switch, Options, caller, p2, options2, true))
			Vote = 1;
	}
}

function SetTeamX(byte b)
{
	GetTeamX = b;
}

function SetVoteMode(byte b)
{
	Vote = b;
}

function ClearStats()
{
	local int i;

	for(i = 0; i < 15; i++)
	{
		NormalWepStatsPrim[i] = 0;
		NormalWepStatsAlt[i] = 0;
		NormalWepStatsPrimHit[i] = 0;
		NormalWepStatsAltHit[i] = 0;
		NormalWepStatsPrimDamage[i] = 0;
		NormalWepStatsAltDamage[i] = 0;
	}

	DamR = 0;
	DamG = 0;
	PickedUpFifty = 0;
	PickedUpHundred = 0;
	PickedUpAmp = 0;
	PickedUpVial = 0;
	PickedUpHealth = 0;
	PickedUpKeg = 0;
	PickedUpAdren = 0;
	RealKills = 0;
	TotalDamageG = 0;
}

function SetColoredName(string S)
{
	ColoredName = S;
}

function SetShowSelf(bool b)
{
	bShowSelf = b;
}

function string MakeSafeName(string S)
{
	local int i;
	local bool NotSafeYet;

	while(Len(S) > 0 && NotSafeYet)
	{
		NotSafeYet = false;
		for(i = 1; i < 4; i++)
		{
			if (Mid(S, Len(S)-i) == Chr(0x1B))
			{
				S = Left(S, Len(S)-i);
				NotSafeYet = true;
				break;
			}
		}
	}
	return S;
}

event Tick(float deltaTime)
{
	Super.Tick(deltaTime);
}

defaultproperties
{
	GetTeamX=255
	Vote=255
	VoteSwitch=255
	bSendWepStats=true
	CurrentVoteID=255
}