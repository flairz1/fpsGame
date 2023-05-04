class UTComp_GameRules extends GameRules;

var MutUTComp UTCompMutator;
var bool bFirstRun;

function int NetDamage(int OriginalDamage, int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local byte HitSoundType;
	local UTComp_PRI uPRI;
	local Controller C;

	if (Damage > 0 && InstigatedBy != None && Injured != None && InstigatedBy.Controller != None && BS_xPlayer(InstigatedBy.Controller) != None)
	{
		if (UTCompMutator.iHitsounds > 0)
		{
			if (BS_xPlayer(InstigatedBy.Controller).bWantsStats && UTCompMutator.bWeaponStats)
			{
				BS_xPlayer(InstigatedBy.Controller).ReceiveHit(DamageType, Damage, Injured);
			}
			else
			{
				if (InstigatedBy == Injured)
					HitSoundType = 0;
				else if (InstigatedBy.GetTeamNum() == 255 || InstigatedBy.GetTeamNum() != Injured.GetTeamNum())
					HitSoundType = 1;
				else
					HitSoundType = 2;

				if (InstigatedBy.LineOfSightTo(Injured))
					BS_xPlayer(InstigatedBy.Controller).ReceiveHitSound(Damage, HitSoundType);
			}

			if (InstigatedBy == Injured)
				HitSoundType = 0;
			else if (InstigatedBy.GetTeamNum() == 255 || InstigatedBy.GetTeamNum() != Injured.GetTeamNum())
				HitSoundType = 1;
			else
				HitSoundType = 2;

			for(C = Level.ControllerList; C != None; C = C.NextController)
			{
				if (BS_xPlayer(C) != None && C.PlayerReplicationInfo != None && (C.PlayerReplicationInfo.bOnlySpectator || C.PlayerReplicationInfo.bOutOfLives) && PlayerController(C).ViewTarget == InstigatedBy)
					BS_xPlayer(C).ReceiveHitSound(Damage, HitSoundType);
			}
		}
		else if (BS_xPlayer(InstigatedBy.Controller).bWantsStats && UTCompMutator.bWeaponStats)
		{
			BS_xPlayer(InstigatedBy.Controller).ReceiveStats(DamageType, Damage, Injured);
		}

		BS_xPlayer(InstigatedBy.Controller).ServerReceiveHit(DamageType, Damage, Injured);
	}

	if (Injured != None && Injured.Controller != None && BS_xPlayer(Injured.Controller) != None)
	{
		uPRI = Class'UTComp_Util'.static.GetUTCompPRIForPawn(Injured);
		if (uPRI != None)
			uPRI.DamR += Damage;
	}

	if (NextGameRules != None)
		return NextGameRules.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);

	return Damage;
}

function LogPickup(Pawn other, Pickup item)
{
	UTCompMutator.LogPickup(other, item);
}

function bool OverridePickupQuery(Pawn Other, Pickup Item, out byte bAllowPickup)
{
	local UTComp_PRI uPRI;

	uPRI = class'UTComp_Util'.static.GetUTCompPRIForPawn(Other);
	if (uPRI != None && UTCompMutator.bPickupStats)
	{
		if (ShieldPack(Item) != None)
		{
			if (!Level.Game.bTeamGame || xPawn(Other) == None || xPawn(Other).CanUseShield(50) != 0)
				uPRI.PickedUpFifty++;
		}
		else if (SuperShieldPack(Item) != None)
		{
			uPRI.PickedUpHundred++;
			LogPickup(other, item);
		}
		else if (SuperHealthPack(Item) != None)
		{
			if (Other.Health < Other.SuperHealthMax)
			{
				uPRI.PickedUpKeg++;
				LogPickup(other, item);
			}
		}
		else if (HealthPack(Item) != None)
		{
			if (Other.Health < Other.HealthMax)
				uPRI.PickedUpHealth++;
		}
		else if (MiniHealthPack(Item) != None)
		{
			if (Other.Health < Other.SuperHealthMax)
				uPRI.PickedUpVial++;
		}
		else if (UDamagePack(Item) != None)
		{
			uPRI.PickedUpAmp++;
			LogPickup(other, item);
		}
		else if (AdrenalinePickup(Item) != None)
		{
			uPRI.PickedUpAdren += AdrenalinePickup(Item).AdrenalineAmount/2;
		}
	}

	if ((NextGameRules != None) &&  NextGameRules.OverridePickupQuery(Other, item, bAllowPickup))
		return true;

	return false;
}


function ScoreKill(Controller Killer, Controller Killed)
{
	local UTComp_PRI uPRI;
	local Controller C;
	local BS_xPlayer uPC;

	if (Killer != none && Killed !=None)
	{
		if (Killer == Killed)
		{
		}
		else if (Killer.PlayerReplicationInfo == None || Killed.PlayerReplicationInfo == None)
		{
		}
		else if (Killer.PlayerReplicationInfo.Team == None || (Killer.PlayerReplicationInfo.Team != Killed.PlayerReplicationInfo.Team))
		{
			uPRI = class'UTComp_Util'.static.GetUTCompPRI(Killer.PlayerReplicationInfo);
			if (uPRI != None)
				uPRI.RealKills++;
		}
		else
		{
			uPRI = class'UTComp_Util'.static.GetUTCompPRI(Killer.PlayerReplicationInfo);
			if (uPRI != None)
				uPRI.RealKills--;

			uPRI = None;
			uPRI = class'UTComp_Util'.static.GetUTCompPRI(Killed.PlayerReplicationInfo);
			if (uPRI != None)
				uPRI.RealKills++;
		}
	}

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		uPC = BS_xPlayer(C);
		if (uPC != None && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.bOnlySpectator)
		{
			if (xPawn(uPC.ViewTarget) != None && uPC.bSpecingViewGoal && (xPawn(uPC.ViewTarget).Controller == Killed || xPawn(uPC.ViewTarget).OldController == Killed))
			{
				uPC.SetLocation(uPC.CalcViewLocation);
				uPC.SetViewTarget(uPC);

				uPC.bBehindView = true;
				uPC.ClientSetLocation(uPC.CalcViewLocation, uPC.CalcViewRotation);
				uPC.ClientSetViewTarget(uPC);
			}
		}
	}

	if (NextGameRules != None)
		NextGameRules.ScoreKill(Killer,Killed);
}

function bool IsInZone(Controller C, int team)
{
	local string loc;

	if (C.PlayerReplicationInfo != None)
	{
		loc = C.PlayerReplicationInfo.GetLocationName();
		if (team == 0)
			return (Instr(Caps(loc), "RED") != -1);
		else
			return (Instr(Caps(loc), "BLUE") != -1);
	}

	return false;
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
	if (NextGameRules != None)
		return NextGameRules.CheckEndGame(Winner, Reason);

	return true;
}

function Reset()
{
	Super.Reset();
	bFirstRun = true;
}

defaultproperties
{
	bFirstRun=true
}