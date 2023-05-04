class fpsInv extends Invasion
	config(fpsGame);

var config int MaxAlive;

struct MonsterInfo
{
	var int Wave;
	var float Size;
	var float Speed;
	var float Damage;
	var int Health;
	var string MClass;
};
var config array<MonsterInfo> MonsterTable;

struct BossInfo
{
	var int Wave;
	var int Bosses;
	var float Size;
	var float Speed;
	var float Damage;
	var int Health;
	var string BClass;
};
var config array<BossInfo> BossTable;

struct MonsterStruct
{
	var class<Monster> Monsters;
	var float MonsterSZ;
	var float MonsterSP;
	var float MonsterDB;
	var int MonsterHP;
};
var array<MonsterStruct> MonsterWaveTable;

struct BossStruct
{
	var class<Monster> Boss;
	var int Bosses;
	var float BossSZ;
	var float BossSP;
	var float BossDB;
	var int BossHP;
};
var array<BossStruct> BossWaveTable;

var array<class<Monster> > MonsterClasses;
var array<class<Monster> > BossClasses;

var bool bBossWave, bSwitchWave, bRespawn;
var int BossAlive, MaxBossAlive;

//	KillZone Activity
struct KillZoneInfo
{
	var array<int> Waves;
};
var config KillZoneInfo KillZoneTable;

//	GRI (GameReplicationInfo)
var fpsGRI GRI;
var int BossTime, KillTime;
var bool BossWave;

//	Colours
var Color SD_Green, SD_White;

event PreBeginPlay()
{
	Super.PreBeginPlay();

	WaveNum = InitialWave;
	InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;
	InvasionGameReplicationInfo(GameReplicationInfo).BaseDifficulty = int(GameDifficulty);
	GameReplicationInfo.bNoTeamSkins = true;
	GameReplicationInfo.bForceNoPlayerLights = true;
	GameReplicationInfo.bNoTeamChanges = true;
}

event PlayerController Login(string Portal, string Options, out string Error)
{
	local PlayerController PC;
	local Controller C;

  	if (MaxLives > 0)
	{
		for(C = Level.ControllerList; C != none; C = C.NextController)
		{
			if (C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.NumLives > LateEntryLives)
			{
				Options = ("?SpectatorOnly=1" $ Options);
				break;
			}
		}
	}

	PC = Super(UnrealMPGameInfo).Login(Portal, Options, Error);
	if (PC != none)
	{
		if (bMustJoinBeforeStart && GameReplicationInfo.bMatchHasBegun)
			UnrealPlayer(PC).bLatecomer = true;

		if (Level.NetMode == NM_Standalone)
		{
			if (PC.PlayerReplicationInfo.bOnlySpectator)
			{
				if (!bCustomBots && ( bAutoNumBots || (bTeamGame && (InitialBots % 2 == 1)) ))
					InitialBots++;
			}
			else
			{
				StandalonePlayer = PC;
			}
		}

		for(C = Level.ControllerList; C != none; C = C.NextController)
		{
			if (C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.bOutOfLives && !C.PlayerReplicationInfo.bOnlySpectator)
			{
				PC.PlayerReplicationInfo.bOutOfLives = true;
				PC.PlayerReplicationInfo.NumLives = 0;
			}
		}
	}

	return PC;
}

function int ReduceDamage(int Damage, Pawn injured, Pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local float InstigatorSkill, result;
	local BS_xPlayer BxP;
	local byte HSType;

	if (instigatedBy == none)
		return Super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

	if (
		instigatedBy != none &&
		BS_xPlayer(instigatedBy.Controller) != none &&
		(class<WeaponDamageType>(DamageType) != none || class<VehicleDamageType>(DamageType) != none)
	)
	{
		BxP = BS_xPlayer(instigatedBy.Controller);
		if (instigatedBy.IsPlayerPawn() && injured != instigatedBy)
		{
			if (instigatedBy == injured)
				HSType = 0;
			else if (instigatedBy.GetTeamNum() == 255 || instigatedBy.GetTeamNum() != injured.GetTeamNum())
				HSType = 1;
			else if (injured.GetTeamNum() == instigatedBy.GetTeamNum())
				HSType = 2;

			if (instigatedBy.LineOfSightTo(injured))
				BxP.ReceiveHitSound(Damage, HSType);
		}
	}

	if (instigatedby != none && instigatedBy.Controller != none)
	{
		if (injured != none && injured.Controller != none)
		{
			if (Monster(injured) != none && Monster(instigatedBy) != none && CompareControllers(injured.Controller, instigatedBy.Controller))
				Damage = 0;
		}

		if (Monster(injured) == none && MonsterController(instigatedBy.Controller) == none && !instigatedBy.Controller.IsA('SMPNaliFighterController'))
		{
			if (ClassIsChildOf(DamageType, class'DamTypeRoadkill'))
				Damage = 0;
		}
	}

	if (MonsterController(instigatedBy.Controller) != none)
	{
		InstigatorSkill = MonsterController(instigatedBy.Controller).Skill;
		if (NumPlayers > 4)
			InstigatorSkill += 1.00;

		if (InstigatorSkill < 7 && Monster(injured) == none)
		{
			if (InstigatorSkill <= 3)
				Damage = Damage * (0.25 + 0.05 * InstigatorSkill);
			else
				Damage = Damage * (0.40 + 0.10 * (InstigatorSkill - 3));
		}
	}
	else if (injured == instigatedBy)
	{
		Damage = Damage * 0.5;
	}

	if (InvasionBot(injured.Controller) != none)
	{
		if (!InvasionBot(injured.controller).bDamagedMessage && (injured.Health - Damage < 50))
		{
			InvasionBot(injured.controller).bDamagedMessage = true;
			if (FRand() < 0.50)
				injured.Controller.SendMessage(none, 'OTHER', 4, 12, 'TEAM');
			else
				injured.Controller.SendMessage(none, 'OTHER', 13, 12, 'TEAM');
		}

		if (GameDifficulty <= 3)
		{
			if (injured.IsPlayerPawn() && injured == instigatedby && Level.NetMode == NM_Standalone)
				Damage *= 0.50;

			if (MonsterController(instigatedBy.Controller) != none)
			{
				if (InstigatorSkill <= 3)
					Damage = Damage * (0.25 + 0.15 * InstigatorSkill);
			}
		}
	}
	result = Super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

	return result;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();

	GRI = fpsGRI(GameReplicationInfo);
}

function int MonsterCount()
{
	local MonsInv MInv;
	local int MCount;

	foreach DynamicActors(class'MonsInv', MInv)
		MCount++;

	NumMonsters = MCount;
	return MCount;
}

function int BossCount()
{
	local BossInv BInv;
	local int BCount;

	foreach DynamicActors(class'BossInv', BInv)
		BCount++;

	NumMonsters = BCount;
	return BCount;
}

function UpdateGRI()
{
	GRI.NumMons = MonsterCount();
	GRI.NumBoss = BossCount();
}

function Actor GetMonsterTarget()
{
	local Controller C;

	for(C = Level.ControllerList; C != none; C = C.NextController)
	{
		if (PlayerController(C) != none && C.Pawn != none)
			return C.Pawn;
	}
}

function bool ShouldMonsterAttack(Actor CurrentTarget, Controller C)
{
	if (CurrentTarget != none && C != none)
	{
		if (Pawn(CurrentTarget) != none && Pawn(CurrentTarget).Controller != none)
		{
			if (Pawn(CurrentTarget).Controller.IsA('PetController') || Pawn(CurrentTarget).Controller.IsA('AnimalController'))
			{
				return false;
			}
			else if (MonsterController(C) != none)
			{
				if (Pawn(CurrentTarget).Controller.IsA('PlayerController') || Pawn(CurrentTarget).Controller.IsA('FriendlyMonsterController'))
					return true;
				else
					return false;
			}
			else if (C.IsA('FriendlyMonsterController'))
			{
				if (Pawn(CurrentTarget).Controller.IsA('PlayerController') || Pawn(CurrentTarget).Controller.IsA('FriendlyMonsterController'))
					return false;
				else
					return true;
			}
		}
	}

	return false;
}

function bool CompareControllers(Controller B, Controller C)
{
	if (B.Class == C.Class)
		return true;

	if (
		(!B.IsA('FriendlyMonsterController') && MonsterController(B) != none && C.IsA('SMPNaliFighterController')) ||
		(B.IsA('SMPNaliFighterController') && !C.IsA('FriendlyMonsterController') && MonsterController(C) != none)
	)
	{
		return true;
	}

	if (B.IsA('PetController') || C.IsA('PetController'))
		return true;

	if ((B.IsA('FriendlyMonsterController') && PlayerController(C) != none) || (PlayerController(B) != none && C.IsA('FriendlyMonsterController')))
		return true;

	return false;
}

function AddMonster()
{
	local NavigationPoint StartSpot;
	local Monster NewMonster;
	local class<Monster> MClass;
	local MonsInv Inv;
	local int x, m;

	//test to prevent attacking each other
	foreach DynamicActors(class'MonsInv', Inv)
	{
		if (NewMonster.Controller != none && !NewMonster.Controller.IsA('FriendlyMonsterController'))
		{
			if (NewMonster.Controller.Target != none)
			{
				if (!ShouldMonsterAttack(NewMonster.Controller.Target, NewMonster.Controller))
					NewMonster.Controller.Target = GetMonsterTarget();
			}
		}
	}

	for(x = 0; x < FMax(5, (Level.GRI.PRIArray.Length-1)); x++) //5 per spawn seconds
	{
		m = Rand(MonsterWaveTable.length);
		MClass = MonsterWaveTable[m].Monsters;

		//StartSpot = FindPlayerStart(None,1);
		StartSpot = MonsterStart(none, 1);
		if (StartSpot == none)
		{
			Log("no valid path to spawn" @ MClass);
			return;
		}

		NewMonster = Spawn(MClass,,,StartSpot.Location + (MClass.default.CollisionHeight - StartSpot.CollisionHeight) * vect(0,0,1),StartSpot.Rotation);
		if (NewMonster == none)
		{
			Log("no valid path to spawn" @ MClass);
			return;
		}

		if (NewMonster != none)
		{
			Inv = Spawn(class'MonsInv', NewMonster);
			if (Inv != none)
				Inv.GiveTo(NewMonster);

			if (MonsterWaveTable[m].MonsterSZ <= 0)
			{
				NewMonster.SetLocation(NewMonster.Location + vect(0,0,1) * (NewMonster.default.CollisionHeight * NewMonster.default.DrawScale));
				NewMonster.SetDrawScale(NewMonster.default.DrawScale);
				NewMonster.SetCollisionSize(NewMonster.default.CollisionRadius, NewMonster.default.CollisionHeight);
				NewMonster.Prepivot.X = NewMonster.default.Prepivot.X;
				NewMonster.Prepivot.Y = NewMonster.default.Prepivot.Y;
				NewMonster.Prepivot.Z = NewMonster.default.Prepivot.Z;
			}
			else
			{
				NewMonster.SetLocation(NewMonster.Location + vect(0,0,1) * ((NewMonster.default.CollisionHeight * MonsterWaveTable[m].MonsterSZ) * (NewMonster.default.DrawScale * MonsterWaveTable[m].MonsterSZ)));
				NewMonster.SetDrawScale(NewMonster.default.DrawScale * MonsterWaveTable[m].MonsterSZ);
				NewMonster.SetCollisionSize(NewMonster.default.CollisionRadius * MonsterWaveTable[m].MonsterSZ, NewMonster.default.CollisionHeight * MonsterWaveTable[m].MonsterSZ);
				NewMonster.Prepivot.X = NewMonster.default.Prepivot.X * MonsterWaveTable[m].MonsterSZ;
				NewMonster.Prepivot.Y = NewMonster.default.Prepivot.Y * MonsterWaveTable[m].MonsterSZ;
				NewMonster.Prepivot.Z = NewMonster.default.Prepivot.Z * MonsterWaveTable[m].MonsterSZ;
			}

			if (MonsterWaveTable[m].MonsterSP <= 0)
			{
				NewMonster.GroundSpeed = NewMonster.default.GroundSpeed;
				NewMonster.JumpZ = NewMonster.default.JumpZ;
				NewMonster.WaterSpeed = NewMonster.default.WaterSpeed;
				NewMonster.AirSpeed = NewMonster.default.AirSpeed;
			}
			else
			{
				NewMonster.GroundSpeed = NewMonster.default.GroundSpeed * MonsterWaveTable[m].MonsterSP;
				NewMonster.JumpZ = NewMonster.default.JumpZ * MonsterWaveTable[m].MonsterSP;
				NewMonster.WaterSpeed = NewMonster.default.WaterSpeed * MonsterWaveTable[m].MonsterSP;
				NewMonster.AirSpeed = NewMonster.default.AirSpeed * MonsterWaveTable[m].MonsterSP;
			}

			if (MonsterWaveTable[m].MonsterDB <= 0)
				NewMonster.DamageScaling = NewMonster.default.DamageScaling;
			else
				NewMonster.DamageScaling = NewMonster.default.DamageScaling * MonsterWaveTable[m].MonsterDB;

			if (MonsterWaveTable[m].MonsterHP <= 0)
				NewMonster.Health = NewMonster.default.Health;
			else
				NewMonster.Health = MonsterWaveTable[m].MonsterHP;

			NewMonster.HealthMax = NewMonster.Health;
			NewMonster.bBoss = false;
			WaveMonsters++;
			NumMonsters++;
			x = 0;
		}
	}
}

function AddBoss()
{
	local NavigationPoint StartSpot;
	local Monster NewMonster;
	local class<Monster> BClass;
	local BossInv Inv;
	local int i;

	//test to prevent attacking each other
	foreach DynamicActors(class'BossInv', Inv)
	{
		if (NewMonster.Controller != none && !NewMonster.Controller.IsA('FriendlyMonsterController'))
		{
			if (NewMonster.Controller.Target != none)
			{
				if (!ShouldMonsterAttack(NewMonster.Controller.Target, NewMonster.Controller))
					NewMonster.Controller.Target = GetMonsterTarget();
			}
		}
	}
				
	for(i = 0; i < BossWaveTable.length; i++)
	{
		BClass = BossWaveTable[i].Boss;

		StartSpot = MonsterStart(none, 1);
		if (StartSpot == none)
		{
			Log("no valid path to spawn" @ BClass);
			return;
		}

		if (BClass != none)
			NewMonster = Spawn(BClass,,,StartSpot.Location + (BClass.default.CollisionHeight - StartSpot.CollisionHeight) * vect(0,0,1),StartSpot.Rotation);

		if (NewMonster != none)
		{
			Inv = Spawn(Class'BossInv', NewMonster);
			if (Inv != none)
				Inv.GiveTo(NewMonster);

			if (BossWaveTable[i].BossSZ <= 0)
			{
				NewMonster.SetLocation(NewMonster.Location + vect(0,0,1) * (NewMonster.default.CollisionHeight * NewMonster.default.DrawScale));
				NewMonster.SetDrawScale(NewMonster.default.DrawScale);
				NewMonster.SetCollisionSize(NewMonster.default.CollisionRadius, NewMonster.default.CollisionHeight);
				NewMonster.Prepivot.X = NewMonster.default.Prepivot.X;
				NewMonster.Prepivot.Y = NewMonster.default.Prepivot.Y;
				NewMonster.Prepivot.Z = NewMonster.default.Prepivot.Z;
			}
			else
			{
				NewMonster.SetLocation(NewMonster.Location + vect(0,0,1) * ((NewMonster.default.CollisionHeight * BossWaveTable[i].BossSZ) * (NewMonster.default.DrawScale * BossWaveTable[i].BossSZ)));
				NewMonster.SetDrawScale(NewMonster.default.DrawScale * BossWaveTable[i].BossSZ);
				NewMonster.SetCollisionSize(NewMonster.default.CollisionRadius * BossWaveTable[i].BossSZ, NewMonster.default.CollisionHeight * BossWaveTable[i].BossSZ);
				NewMonster.Prepivot.X = NewMonster.default.Prepivot.X * BossWaveTable[i].BossSZ;
				NewMonster.Prepivot.Y = NewMonster.default.Prepivot.Y * BossWaveTable[i].BossSZ;
				NewMonster.Prepivot.Z = NewMonster.default.Prepivot.Z * BossWaveTable[i].BossSZ;
			}

			if (BossWaveTable[i].BossSP <= 0)
			{
				NewMonster.GroundSpeed = NewMonster.default.GroundSpeed;
				NewMonster.JumpZ = NewMonster.default.JumpZ;
				NewMonster.WaterSpeed = NewMonster.default.WaterSpeed;
				NewMonster.AirSpeed = NewMonster.default.AirSpeed;
			}
			else
			{
				NewMonster.GroundSpeed = NewMonster.default.GroundSpeed * BossWaveTable[i].BossSP;
				NewMonster.JumpZ = NewMonster.default.JumpZ * BossWaveTable[i].BossSP;
				NewMonster.WaterSpeed = NewMonster.default.WaterSpeed * BossWaveTable[i].BossSP;
				NewMonster.AirSpeed = NewMonster.default.AirSpeed * BossWaveTable[i].BossSP;
			}

			if (BossWaveTable[i].BossDB <= 0)
				NewMonster.DamageScaling = NewMonster.default.DamageScaling;
			else
				NewMonster.DamageScaling = NewMonster.default.DamageScaling * BossWaveTable[i].BossDB;

			NewMonster.Health = BossWaveTable[i].BossHP;
			if (BossWaveTable[i].BossHP <= 0)
				NewMonster.Health = NewMonster.default.Health;
			else
				NewMonster.Health = BossWaveTable[i].BossHP;

			NewMonster.HealthMax = NewMonster.Health;
			NewMonster.bBoss = true;
			WaveMonsters++;
			NumMonsters++;
		}
	}
}

function KillZone()
{
	local Controller C;

	if (Level.TimeSeconds > WaveEndTime + KillTime && KillTime <= 0)
	{
		for(C = Level.ControllerList; C != none; C = C.NextController)
		{
			if (C.bIsPlayer && C.Pawn != none)
			{
				if (C.PlayerReplicationInfo != none)
					C.PlayerReplicationInfo.NumLives = 0;

				C.Pawn.Spawn(class'NewIonEffect').RemoteRole = ROLE_SimulatedProxy;
				C.Pawn.KilledBy(C.Pawn);
				break;
			}
		}
	}
	else
	{
		KillTime--;
		GRI.KillZoneLimit = KillTime;
		if (GRI.KillZoneLimit <= 10)
			BroadcastLocalizedMessage(class'TimedMessage', GRI.KillZoneLimit);

		if (MonsterCount() <= 0)
		{
			bWaveInProgress = false;
			WaveCountDown = 15;
			WaveNum++;
			GRI.KillZoneLimit = 0;
		}
	}
}

function bool BossWaveBegin()
{
	AddBoss();
	return true;
}

function bool KillZoneBegin()
{
	local int k;

	for(k = 0; k < KillZoneTable.Waves.Length; k++)
	{
		if ((WaveNum+1) == KillZoneTable.Waves[k])
			return true;
	}

	return false;
}

function SetupWave()
{
	local int x, m;	// monsters
	local int i, b;	// bosses
	local int bt;	// bosstimer
	local int kt;	// killtimer

	BossWaveTable.length = 0;
	MaxBossAlive = 0;
	for(i = 0; i < BossTable.length; i++)
	{
		if ((WaveNum+1) == BossTable[i].Wave)
		{
			b = BossWaveTable.length;
			BossWaveTable.length = b + 1;
			BossWaveTable[b].Boss = class<Monster>(DynamicLoadObject(BossTable[i].BClass, class'Class', false));
			BossWaveTable[b].Bosses = BossTable[i].Bosses;
			BossWaveTable[b].BossSZ = BossTable[i].Size;
			BossWaveTable[b].BossSP = BossTable[i].Speed;
			BossWaveTable[b].BossDB = BossTable[i].Damage;
			BossWaveTable[b].BossHP = BossTable[i].Health;
			MaxBossAlive = BossWaveTable[b].Bosses;
		}
	}

	MonsterWaveTable.length = 0;
	for(x = 0; x < MonsterTable.length; x++)
	{
		if ((WaveNum+1) == MonsterTable[x].Wave)
		{
			m = MonsterWaveTable.length;
			MonsterWaveTable.length = m + 1;
			MonsterWaveTable[m].Monsters = class<Monster>(DynamicLoadObject(MonsterTable[x].MClass, class'Class', false));
			MonsterWaveTable[m].MonsterSZ = MonsterTable[x].Size;
			MonsterWaveTable[m].MonsterSP = MonsterTable[x].Speed;
			MonsterWaveTable[m].MonsterDB = MonsterTable[x].Damage;
			MonsterWaveTable[m].MonsterHP = MonsterTable[x].Health;
		}
	}

	bt = 0;
	kt = 0;
	WaveMonsters = 0;
	WaveNumClasses = 0;
	MaxMonsters = 400;
	WaveEndTime = Level.TimeSeconds + 110; //105 + 5(temp pause)
	AdjustedDifficulty = GameDifficulty + Waves[WaveNum].WaveDifficulty;

	bt = (60 + (((WaveNum+1) * 7) - (NumPlayers * 5)));
	kt = (60 + (((WaveNum+1) * 3) - (NumPlayers * 5)));

	BossTime = bt;
	KillTime = kt;
}

state MatchInProgress
{
	function Timer()
	{
		local Bot B;
		local Controller C;
		local bool bOneMessage;

		Super(xTeamGame).Timer();
		UpdateGRI();

		if (bBossWave)
		{
			if (BossAlive < MaxBossAlive)
			{
				if (BossWaveBegin())
					BossAlive++;
				else if (WaveEndTime < Level.TimeSeconds)
					BossAlive = MaxBossAlive;

				if (BossAlive == MaxBossAlive)
					GRI.BossTimeLimit = BossTime;
			}
			else
			{
				if (BossTime <= 0)
				{
					for(C = Level.ControllerList; C != none; C = C.NextController)
					{
						if (C.bIsPlayer && C.Pawn != none)
						{
							if (C.PlayerReplicationInfo != none)
								C.PlayerReplicationInfo.NumLives = 0;

							C.Pawn.Spawn(class'NewIonEffect').RemoteRole = ROLE_SimulatedProxy;
							C.Pawn.KilledBy(C.Pawn);
							break;
						}
					}
				}
				else
				{
					BossTime--;
					GRI.BossTimeLimit = BossTime;
					if (GRI.BossTimeLimit <= 7)
						BroadcastLocalizedMessage(class'TimedMessage', GRI.BossTimeLimit);

					if (BossCount() <= 0)
					{
						bWaveInProgress = false;
						bBossWave = false;
						WaveCountDown = 15;
						bSwitchWave = false;
						GRI.BossTimeLimit = 0;
					}
				}
			}
			GRI.BossWave = true;
		}
		else if (bWaveInProgress)
		{
			bSwitchWave = true;
			if (Level.TimeSeconds > WaveEndTime)
			{
				if (KillZoneBegin())
				{
					KillZone();
				}
				else
				{
					if (MonsterCount() <= 0)
					{
						bWaveInProgress = false;
						WaveCountDown = 15;
						WaveNum++;
					}
				}
			}
			else
			{
				if (MonsterCount() <= MaxMonsters)
				{
					if (MonsterCount() < (default.MaxAlive - 5))
						AddMonster();
				}
			}
		}
		else if (MonsterCount() <= 0)
		{
			if (WaveNum >= FinalWave)
			{
				EndGame(none, "TimeLimit");
				return;
			}

			if (bSwitchWave && BossWaveTable.length > 0)
			{
				if (WaveCountDown == 15)
				{
					for(C = Level.ControllerList; C != none; C = C.NextController)
					{
						if (C.PlayerReplicationInfo != none)
						{
							if (!C.PlayerReplicationInfo.bOutOfLives)
								C.PlayerReplicationInfo.NumLives = MaxLives;

							if (C.Pawn != none)
							{
								ReplenishWeapons(C.Pawn);
							}
							else if (C.Pawn == none && !C.PlayerReplicationInfo.bOnlySpectator)
							{
								if (bRespawn)
								{
									C.PlayerReplicationInfo.bOutOfLives = false;
									C.PlayerReplicationInfo.NumLives = MaxLives;
									if (PlayerController(C) != none)
										C.GotoState('PlayerWaiting');
								}
								else if (C.PlayerReplicationInfo.bOutOfLives)
								{
									C.PlayerReplicationInfo.NumLives = 0;
								}
							}
						}
					}
				}

				if (WaveCountDown >= 5)
				{
					BroadcastLocalizedMessage(class'BossMessage',MaxBossAlive,,,);
					BossAlive = 0;
				}

				WaveCountDown--;
				if (WaveCountDown <= 1)
				{
					bBossWave = true;
					bWaveInProgress = true;
					WaveEndTime = Level.TimeSeconds;
				}

				if (WaveCountDown == 14)
					Log("Startup wave" @ WaveNum @ "-BossWave!");

				return;
			}
			bSwitchWave = false;

			WaveCountDown--;
			if (WaveCountDown == 14)
			{
				for(C = Level.ControllerList; C != none; C = C.NextController)
				{
					if (C.PlayerReplicationInfo != none)
					{
						C.PlayerReplicationInfo.bOutOfLives = false;
						C.PlayerReplicationInfo.NumLives = 0;
						if (C.Pawn != none)
							ReplenishWeapons(C.Pawn);
						else if (!C.PlayerReplicationInfo.bOnlySpectator && PlayerController(C) != none)
							C.GotoState('PlayerWaiting');
					}
				}
			}

			if (WaveCountDown == 13)
			{
				InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;
				for(C = Level.ControllerList; C != none; C = C.NextController)
				{
					if (PlayerController(C) != none)
					{
						PlayerController(C).PlayStatusAnnouncement('Next_wave_in', 1, true);
						if (C.Pawn == none && !C.PlayerReplicationInfo.bOnlySpectator)
							PlayerController(C).SetViewTarget(C);
					}

					if (C.PlayerReplicationInfo != none)
					{
						C.PlayerReplicationInfo.bOutOfLives = false;
						C.PlayerReplicationInfo.NumLives = 0;
						if (C.Pawn == none && !C.PlayerReplicationInfo.bOnlySpectator)
							C.ServerReStartPlayer();
					}
				}
			}
			else if (WaveCountDown > 1 && WaveCountDown < 12)
			{
				BroadcastLocalizedMessage(class'TimerMessage', WaveCountDown-1);
			}
			else if (WaveCountDown <= 1)
			{
				GRI.BossWave = false;
				bWaveInProgress = true;
				SetupWave();
				for(C = Level.ControllerList; C != none; C = C.NextController)
				{
					if (PlayerController(C) != none)
						PlayerController(C).LastPlaySpeech = 0;
				}

				for(C = Level.ControllerList; C != none; C = C.NextController)
				{
					if (Bot(C) != none)
					{
						B = Bot(C);
						InvasionBot(B).bDamagedMessage = false;
						B.bInitLifeMessage = false;
						if (!bOneMessage && FRand() < 0.65)
						{
							bOneMessage = true;
							if (B.Squad.SquadLeader != none && B.Squad.CloseToLeader(C.Pawn))
							{
								B.SendMessage(B.Squad.SquadLeader.PlayerReplicationInfo, 'OTHER', B.GetMessageIndex('INPOSITION'), 20, 'TEAM');
								B.bInitLifeMessage = false;
							}
						}
					}
				}
 			}
		}
	}

	function BeginState()
	{
		Super.BeginState();
		WaveNum = InitialWave;
		InvasionGameReplicationInfo(GameReplicationInfo).WaveNumber = WaveNum;
	}
}

static function string MakeColorCode(color NewColor)
{
	if (NewColor.R == 0)
		NewColor.R = 1;

	if (NewColor.G == 0)
		NewColor.G = 1;

	if (NewColor.B == 0)
		NewColor.B = 1;

	return Chr(0x1B) $ Chr(NewColor.R) $ Chr(NewColor.G) $ Chr(NewColor.B);
}

function AddGameSpecificInventory(Pawn P)
{
	if (AllowTransloc())
		P.CreateInventory("fpsGame.GTranslauncher");

	Super(UnrealMPGameInfo).AddGameSpecificInventory(P);
}

function GetServerInfo(out ServerResponseLine ServerState)
{
	Super(xTeamGame).GetServerInfo(ServerState);
	ServerState.GameType = "Invasion";
}

function GetServerDetails(out ServerResponseLine ServerState)
{
	local Mutator M;
	local GameRules G;
	local int i, Len, NumMutators;
	local string MutatorName;
	local string s1, s2, s3;
	local bool bFound;

	s1 = MakeColorCode(default.SD_Green) $ "»";
	s2 = MakeColorCode(default.SD_White) $ "fps";
	s3 = MakeColorCode(default.SD_Green) $ "«";

	AddServerDetail(ServerState, "ServerMode", Eval(Level.NetMode == NM_ListenServer, "non-dedicated", "dedicated"));
	AddServerDetail(ServerState, "AdminName", GameReplicationInfo.AdminName);
	AddServerDetail(ServerState, "AdminEmail", GameReplicationInfo.AdminEmail);
	AddServerDetail(ServerState, "ServerVersion", Level.EngineVersion);
	AddServerDetail(ServerState, s1 $ s2 $ s3 @ "Current Wave", MakeColorCode(default.SD_White) $ (WaveNum + 1) $ MakeColorCode(default.SD_Green) $ "/" $ MakeColorCode(default.SD_White) $ FinalWave);

	if (AccessControl != none && AccessControl.RequiresPassword())
		AddServerDetail(ServerState, "GamePassword", "True");

	AddServerDetail(ServerState, "GameStats", GameStats != none);

	if (AllowGameSpeedChange() && (GameSpeed != 1.0))
		AddServerDetail(ServerState, "GameSpeed", int(GameSpeed*100)/100.0);

	AddServerDetail(ServerState, "FriendlyFireScale", int(FriendlyFireScale*100) $ "%");
	AddServerDetail(ServerState, "MaxSpectators", MaxSpectators);
	AddServerDetail(ServerState, "Translocator", bAllowTrans);
	AddServerDetail(ServerState, "WeaponStay", bWeaponStay);
	AddServerDetail(ServerState, "ForceRespawn", bForceRespawn);

	if (VotingHandler != none)
		VotingHandler.GetServerDetails(ServerState);

	for(M = BaseMutator; M != none; M = M.NextMutator)
	{
		M.GetServerDetails(ServerState);
		NumMutators++;
	}

	for(G = GameRulesModifiers; G != none; G = G.NextGameRules)
		G.GetServerDetails(ServerState);

	for(i = 0; i < ServerState.ServerInfo.Length; i++)
	{
		if (ServerState.ServerInfo[i].Key ~= "Mutator")
			NumMutators--;
	}

	if (NumMutators > 1)
	{
		for(M = BaseMutator.NextMutator; M != none; M = M.NextMutator)
		{
			MutatorName = M.GetHumanReadableName();
			for(i = 0; i < ServerState.ServerInfo.Length; i++)
			{
				if ((ServerState.ServerInfo[i].Value ~= MutatorName) && (ServerState.ServerInfo[i].Key ~= "Mutator"))
				{
					bFound = true;
					break;
				}
			}

			if (!bFound)
			{
				Len = ServerState.ServerInfo.Length;
				ServerState.ServerInfo.Length = Len+1;
				ServerState.ServerInfo[i].Key = "Mutator";
				ServerState.ServerInfo[i].Value = MutatorName;
			}
		}
	}
}

static event bool AcceptPlayInfoProperty(string PropertyName)
{
	if ((PropertyName == "bBalanceTeams") || (PropertyName == "bPlayersBalanceTeams") || (PropertyName == "GoalScore"))
		return false;

	return Super.AcceptPlayInfoProperty(PropertyName);
}

function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string incomingName)
{
	local NavigationPoint N, BestStart;
	local Teleporter Tel;
	local float BestRating, NewRating;
	local byte Team;

	if (
		(Player != none) && (Player.StartSpot != none) && (Level.NetMode == NM_Standalone) &&
		(bWaitingToStartMatch || ((Player.PlayerReplicationInfo != none) && Player.PlayerReplicationInfo.bWaitingPlayer))
	)
	{
		return Player.StartSpot;
	}

	if (GameRulesModifiers != none)
	{
		N = GameRulesModifiers.FindPlayerStart(Player, InTeam, incomingName);
		if (N != none)
			return N;
	}

	if (incomingName != "")
	{
		foreach AllActors(class 'Teleporter', Tel)
		{
			if (string(Tel.Tag) ~= incomingName)
				return Tel;
		}
	}

	if (Player != none && Player.PlayerReplicationInfo != none)
	{
		if (Player.PlayerReplicationInfo.Team != none)
			Team = Player.PlayerReplicationInfo.Team.TeamIndex;
		else
			Team = InTeam;
	}
	else
	{
		Team = InTeam;
	}

	for(N = Level.NavigationPointList; N != none; N = N.NextNavigationPoint)
	{
		NewRating = RatePlayerStart(N, Team, Player);
		if (NewRating > BestRating)
		{
			BestRating = NewRating;
			BestStart = N;
		}
	}

	if (BestStart == none || (PlayerStart(BestStart) == none && Player != none && Player.bIsPlayer))
	{
		Log("Warning - PATHS NOT DEFINED or NO PLAYERSTART with positive rating");
		BestRating = -100000000;
		foreach AllActors(class'NavigationPoint', N)
		{
			NewRating = RatePlayerStart(N, 0, Player);
			if (InventorySpot(N) != none)
				NewRating -= 50;

			NewRating += 20 * FRand();
			if (NewRating > BestRating)
			{
				BestRating = NewRating;
				BestStart = N;
			}
		}
	}

	return BestStart;
}

function NavigationPoint MonsterStart(Controller Player, optional byte InTeam, optional string incomingName)
{
	local NavigationPoint Best;

	if (Player != none && Player.StartSpot != none)
		LastPlayerStartSpot = Player.StartSpot;

	Best = FindPlayerStart(Player, InTeam, incomingName);
	if (Best != none)
		LastStartSpot = Best;

	return Best;
}

function float RatePlayerStart(NavigationPoint N, byte Team, Controller Player)
{
	local PlayerStart P;
	local float Score, NextDist;
	local Controller C;

	P = PlayerStart(N);
	if (P == none || !P.bEnabled || P.PhysicsVolume.bWaterVolume)
		return -10000000;

	if (P.bPrimaryStart)
		Score = 10000000;
	else
		Score = 5000000;

	if (N == LastStartSpot || N == LastPlayerStartSpot)
		Score -= 10000.0;
	else
		Score += 3000 * FRand();

	for(C = Level.ControllerList; C != none; C = C.NextController)
	{
		if (C.bIsPlayer && C.Pawn != none)
		{
			if (C.Pawn.Region.Zone == N.Region.Zone)
				Score -= 1500;

			//NextDist = VSize(C.Pawn.Location - N.Location);
			NextDist = VSize(N.Location);
			if (NextDist < C.Pawn.CollisionRadius + C.Pawn.CollisionHeight)
				Score -= 1000000.0;
			/*
			else if ((NextDist < 3000) && FastTrace(N.Location, C.Pawn.Location))
				Score -= (10000.0 - NextDist);
			else if (NumPlayers + NumBots == 2)
			{
				Score += 2 * VSize(C.Pawn.Location - N.Location);
				if (FastTrace(N.Location, C.Pawn.Location))
					Score -= 10000;
			}
			*/
		}
	}
	return FMax(Score, 5);
}

defaultproperties
{
	MaxAlive=30
	GoalScore=0
	TimeLimit=0
	bRespawn=true
	bAllowTaunts=false
	bAllowTrans=true
	bAllowVehicles=true
	bPlayersMustBeReady=false
	bForceNoPlayerLights=true
	SpawnProtectionTime=0.000000
	SD_Green=(R=50,G=200,B=50,A=255)
	SD_White=(R=200,G=200,B=200,A=255)
	MapListType="fpsGame.fpsInvMapList"
	MapPrefix="DM"
	WaveConfigMenu="fpsGame.fpsInv"
	HUDType="fpsGame.fpsHud"
	MutatorClass="fpsGame.MutFPSGame"
	PlayerControllerClassName="fpsGame.BS_xPlayer"
	GameReplicationInfoClass=class'fpsGame.fpsGRI'
	GameName="FPS Invasion"
	Description="FPS - Fails Per Seconds - FPS Invasion|fps discord: discord.gg/Ey28vnr|owner discord: voltz#1308"
	Acronym="FPS Inv"
}