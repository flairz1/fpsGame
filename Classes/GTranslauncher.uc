class GTransLauncher extends Weapon
	config(fpsGameClient)
	HideDropDown;

//resources imported for gametype and this weapon
#exec obj load file="Content\rs_Inv.u" package="fpsGame"

var GTransBeacon GTransBeacon;

var() float MaxCamDist;
var() float AmmoChargeF;
var int RepAmmo;

var() float AmmoChargeMax;
var() float AmmoChargeRate;

var globalconfig bool bPrevWeaponSwitch;
var xBombFlag Bomb;

var bool bDrained;
var bool bBeaconDeployed;
var bool bTeamSet;
var byte ViewBeaconVolume;
var float PreDrainAmmo;
var rotator TranslocRot;
var float TranslocScale, OldTime;

replication
{
	reliable if (bNetOwner && (Role == ROLE_Authority))
		GTransBeacon, RepAmmo;
}

simulated function bool HasAmmo()
{
	return true;
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	Super.GiveTo(Other, Pickup);

	if (Bot(Other.Controller) != none)
		Bot(Other.Controller).bHasTranslocator = true;
}

function bool ShouldTranslocatorHop(Bot B)
{
	local float dist;
	local Actor N;
	local bool bHop;

	bHop = B.bTranslocatorHop;
	B.bTranslocatorHop = false;

	if (bHop && (B.Focus == B.TranslocationTarget) && (B.NextTranslocTime < Level.TimeSeconds) && B.InLatentExecution(B.LATENT_MOVETOWARD) && B.Squad.AllowTranslocationBy(B))
	{
		if ((GTransBeacon != none) && GTransBeacon.IsMonitoring(B.Focus))
			return false;

		dist = VSize(B.TranslocationTarget.Location - B.Pawn.Location);
		if (dist < 300)
		{
			N = B.AlternateTranslocDest();
			if ((N == none) || ((vector(B.Rotation) Dot Normal(N.Location - B.Pawn.Location)) < 0.5))
			{
				if (dist < 200)
				{
					B.TranslocationTarget = none;
					B.RealTranslocationTarget = none;
					return false;
				}
			}
			else
			{
				B.TranslocationTarget = N;
				B.RealTranslocationTarget = B.TranslocationTarget;
				B.Focus = N;
				return true;
			}
		}

		if ((vector(B.Rotation) Dot Normal(B.TranslocationTarget.Location - B.Pawn.Location)) < 0.5)
		{
			SetTimer(0.1, false);
			return false;
		}

		return true;
	}

	return false;
}

simulated function Timer()
{
	local Bot B;

	if (Instigator != none)
	{
		B = Bot(Instigator.Controller);
		if ((B != none) && (B.TranslocationTarget != none) && (B.bPreparingMove || ShouldTranslocatorHop(B)))
			FireHack(0);
	}

	Super.Timer();
}

function FireHack(byte Mode)
{
	local Actor TTarget;
	local vector TTargetLoc;

	if (Mode == 0)
	{
		if (GTransBeacon != none)
		{
			GTransBeacon.bNoAI = true;
			GTransBeacon.Destroy();
			GTransBeacon = none;
		}

		TTarget = Bot(Instigator.Controller).TranslocationTarget;
		if (TTarget == none)
			return;

		FireMode[0].PlayFiring();
		FireMode[0].FlashMuzzleFlash();
		FireMode[0].StartMuzzleSmoke();
		IncrementFlashCount(0);
		ProjectileFire(FireMode[0]).SpawnProjectile(Instigator.Location, Rot(0,0,0));

		TTargetLoc = TTarget.Location;
		if (JumpSpot(TTarget) != none)
		{
			TTargetLoc.Z += JumpSpot(TTarget).TranslocZOffset;
			if ((Instigator.Anchor != none) && Instigator.ReachedDestination(Instigator.Anchor))
				GTransbeacon.SetLocation(GTransBeacon.Location + Instigator.Anchor.Location + (Instigator.CollisionHeight - Instigator.Anchor.CollisionHeight) * vect(0,0,1)- Instigator.Location);
		}
		else if (TTarget.Velocity != vect(0,0,0))
		{
			TTargetLoc += 0.3 * TTarget.Velocity;
			TTargetLoc.Z = 0.5 * (TTargetLoc.Z + TTarget.Location.Z);
		}
		else if ((Instigator.Physics == PHYS_Falling) && (Instigator.Location.Z < TTarget.Location.Z) && (Instigator.PhysicsVolume.Gravity.Z > -800))
		{
			TTargetLoc.Z += 128;
		}

		GTransBeacon.Velocity = Bot(Instigator.Controller).AdjustToss(GTransBeacon.Speed, GTransBeacon.Location, TTargetLoc, false);
		GTransBeacon.SetTranslocationTarget(Bot(Instigator.Controller).RealTranslocationTarget);
	}
}

function class<DamageType> GetDamageType()
{
	return class'DamTypeTelefrag';
}

function float GetAIRating()
{
	local Bot B;

	B = Bot(Instigator.Controller);
	if (B == none)
		return AIRating;

	if (B.bPreparingMove && (B.TranslocationTarget != none))
		return 10;

	if (B.bTranslocatorHop && ((B.Focus == B.MoveTarget) || ((B.TranslocationTarget != none) && (B.Focus == B.TranslocationTarget))) && B.Squad.AllowTranslocationBy(B))
	{
		if ((GTransBeacon != none) && GTransBeacon.IsMonitoring(GTransbeacon.TranslocationTarget))
		{
			if ((GameObject(B.Focus) != none) && (B.Focus != GTransbeacon.TranslocationTarget))
			{
				if (Instigator.Weapon == self)
					SetTimer(0.2, false);
				return 4;
			}

			if  (
				(GTransbeacon.TranslocationTarget == Instigator.Controller.MoveTarget) ||
				(GTransbeacon.TranslocationTarget == Instigator.Controller.RouteGoal) ||
				(GTransbeacon.TranslocationTarget == Instigator.Controller.RouteCache[0]) ||
				(GTransbeacon.TranslocationTarget == Instigator.Controller.RouteCache[1]) ||
				(GTransbeacon.TranslocationTarget == Instigator.Controller.RouteCache[2]) ||
				(GTransbeacon.TranslocationTarget == Instigator.Controller.RouteCache[3])
			)
			{
				return 4;
			}
		}

		if (Instigator.Weapon == self)
			SetTimer(0.2, false);

		return 4;
	}

	if (Instigator.Weapon == self)
		return AIRating;
}

function bool BotFire(bool bFinished, optional name FiringMode)
{
	return false;
}

function bool ConsumeAmmo(int mode, float load, optional bool bAmountNeededIsMax)
{
	return true;
}

function ReduceAmmo()
{
	Enable('Tick');
	bDrained = false;
	AmmoChargeF -= 1;
	RepAmmo -= 1;
	if (Bot(Instigator.Controller) != none)
		Bot(Instigator.Controller).TranslocFreq = 3 + FMax(Bot(Instigator.Controller).TranslocFreq, Level.TimeSeconds);
}

simulated function GetAmmoCount(out float MaxAmmoPrimary, out float CurAmmoPrimary)
{
	MaxAmmoPrimary = AmmoChargeMax;
	CurAmmoPrimary = FMax(0, AmmoChargeF);
}

function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
	Super.GiveAmmo(m, WP, bJustSpawned);
	AmmoChargeF = default.AmmoChargeF;
	RepAmmo = int(AmmoChargeF);
}

function DrainCharges()
{
	Enable('Tick');
	PreDrainAmmo = AmmoChargeF;
	AmmoChargeF = -1;
	RepAmmo = -1;
	bDrained = true;
	if (Bot(Instigator.Controller) != none)
		Bot(Instigator.Controller).NextTranslocTime = Level.TimeSeconds + 3.5;
}

simulated function bool StartFire(int Mode)
{
	if (!bPrevWeaponSwitch || (Mode == 1) || (Instigator.Controller.bAltFire == 0) || (PlayerController(Instigator.Controller) == none))
		return Super.StartFire(Mode);

	if ((OldWeapon != none) && OldWeapon.HasAmmo())
		Instigator.PendingWeapon = OldWeapon;

	ClientStopFire(0);
	Instigator.Controller.StopFiring();
	PutDown();
	return false;
}

simulated function Tick(float deltaTime)
{
	if (Role == ROLE_Authority)
	{
		if (AmmoChargeF >= AmmoChargeMax)
		{
			if (RepAmmo != int(AmmoChargeF))
				RepAmmo = int(AmmoChargeF);
			Disable('Tick');
			return;
		}

		AmmoChargeF += deltaTime*AmmoChargeRate;
		AmmoChargeF = FMin(AmmoChargeF, AmmoChargeMax);
		if (AmmoChargeF >= 1.5)
		{
			bDrained = false;
		}
		else if (bDrained)
		{
			if ((Bomb == none) && (xBombingRun(Level.Game) != none))
				Bomb = xBombFlag(UnrealMPGameInfo(Level.Game).GetGameObject('xBombFlag'));

			if ((Bomb != none) && (Bomb.Holder != none))
			{
				bDrained = false;
				AmmoChargeF = 1.5;
				if (Bot(Instigator.Controller) != none)
					Bot(Instigator.Controller).NextTranslocTime = Level.TimeSeconds - 1;
			}
		}

		if (RepAmmo != int(AmmoChargeF))
			RepAmmo = int(AmmoChargeF);
	}
	else
	{
		AmmoChargeF = FMin(RepAmmo + AmmoChargeF - int(AmmoChargeF) + deltaTime*AmmoChargeRate, AmmoChargeMax);
	}
}

simulated function DoAutoSwitch()
{}

simulated function ViewPlayer()
{
	if ((PlayerController(Instigator.Controller) != none) && (PlayerController(Instigator.Controller).ViewTarget == GTransBeacon))
	{
		PlayerController(Instigator.Controller).ClientSetViewTarget(Instigator);
		PlayerController(Instigator.Controller).SetViewTarget(Instigator);
		if (GTransBeacon != none)
		{
			GTransbeacon.SetRotation(PlayerController(Instigator.Controller).Rotation);
			GTransbeacon.SoundVolume = GTransbeacon.default.SoundVolume;
		}
	}
}

simulated function ViewCamera()
{
	if (GTransBeacon != none)
	{
		if (PlayerController(Instigator.Controller) != none)
		{
			PlayerController(Instigator.Controller).SetViewTarget(GTransBeacon);
			PlayerController(Instigator.Controller).ClientSetViewTarget(GTransBeacon);
			PlayerController(Instigator.Controller).SetRotation(GTransBeacon.Rotation);
			GTransbeacon.SoundVolume = ViewBeaconVolume;
		}
	}
}

simulated function Reselect()
{
	if ((GTransBeacon == none) || (PlayerController(Instigator.Controller) != none && (PlayerController(Instigator.Controller).ViewTarget == GTransBeacon)))
		ViewPlayer();
	else
		ViewCamera();
}

simulated event RenderOverlays(Canvas C)
{
	local float tileScaleX, tileScaleY, dist, clr;
	local float NewTranslocScale;

	if ((PlayerController(Instigator.Controller) != none) && (PlayerController(Instigator.Controller).ViewTarget == GTransBeacon))
	{
		tileScaleX = C.SizeX / 640.0f;
		tileScaleY = C.SizeY / 480.0f;

		C.DrawColor.R = 255;
		C.DrawColor.G = 255;
		C.DrawColor.B = 255;
		C.DrawColor.A = 255;

		C.Style = 255;
		C.SetPos(0,0);
		C.DrawTile(Material'TransCamFB', C.SizeX, C.SizeY, 0.0, 0.0, 512, 512);
		C.SetPos(0,0);

		if (!Level.IsSoftwareRendering())
		{
			dist = VSize(GTransBeacon.Location - Instigator.Location);
			if (dist > MaxCamDist)
			{
				clr = 255.0;
			}
			else
			{
				clr = (dist / MaxCamDist);
				clr *= 255.0;
			}
			clr = Clamp(clr, 20.0, 255.0);
			C.DrawColor.R = clr;
			C.DrawColor.G = clr;
			C.DrawColor.B = clr;
			C.DrawColor.A = 255;
			C.DrawTile(Material'ScreenNoiseFB', C.SizeX, C.SizeY, 0.0, 0.0, 512, 512);
		}
	}
	else
	{
		if (GTransBeacon == none)
			NewTranslocScale = 1;
		else
			NewTranslocScale = 0;

		if (NewTranslocScale != TranslocScale)
		{
			TranslocScale = NewTranslocScale;
			SetBoneScale(0, TranslocScale, 'Beacon');
		}

		if (TranslocScale != 0)
		{
			TranslocRot.Yaw += 120000 * (Level.TimeSeconds - OldTime);
			OldTime = Level.TimeSeconds;
			SetBoneRotation('Beacon', TranslocRot, 0);
		}

		if (!bTeamSet && (Instigator.PlayerReplicationInfo != none) && (Instigator.PlayerReplicationInfo.Team != none))
		{
			bTeamSet = true;
			if (Instigator.PlayerReplicationInfo.Team.TeamIndex == 1)
				Skins[1] = Material'GoldTransTex';
			else
				Skins[1] = Material'GoldTransTex';
		}
		Super.RenderOverlays(C);
	}
}

simulated function bool PutDown()
{
	ViewPlayer();
	return Super.PutDown();
}

simulated function Destroyed()
{
	if (GTransBeacon != none)
		GTransBeacon.Destroy();

	Super.Destroyed();
}

simulated function float ChargeBar()
{
	return AmmoChargeF - int(AmmoChargeF);
}

defaultproperties
{
	MaxCamDist=4000.000000
	AmmoChargeF=6.000000
	RepAmmo=6
	AmmoChargeMax=6.000000
	AmmoChargeRate=0.400000
	bPrevWeaponSwitch=True
	ViewBeaconVolume=40
	TranslocScale=1.000000
	FireModeClass(0)=Class'fpsGame.GTransFire'
	FireModeClass(1)=Class'fpsGame.GTransRecall'
	PutDownAnim="PutDown"
	IdleAnimRate=0.250000
	SelectSound=Sound'WeaponSounds.Misc.translocator_change'
	SelectForce="Translocator_change"
	AIRating=-1.000000
	CurrentRating=-1.000000
	bShowChargingBar=True
	bCanThrow=False
	Description="The Unbreakable Translocator"
	EffectOffset=(X=100.000000,Y=30.000000,Z=-19.000000)
	DisplayFOV=60.000000
	Priority=1
	HudColor=(R=212,G=175,B=55,A=255)
	SmallViewOffset=(X=38.000000,Y=16.000000,Z=-16.000000)
	CenteredOffsetY=0.000000
	CenteredRoll=0
	CustomCrosshair=2
	CustomCrossHairColor=(R=212,G=175,B=55,A=255)
	CustomCrossHairTextureName="Crosshairs.Hud.Crosshair_Cross3"
	InventoryGroup=10
	PickupClass=Class'fpsGame.GTransPickup'
	PlayerViewOffset=(X=28.500000,Y=12.000000,Z=-12.000000)
	PlayerViewPivot=(Pitch=1000,Yaw=400)
	BobDamping=1.800000
	AttachmentClass=Class'XWeapons.TransAttachment'
	IconMaterial=Texture'HUDContent.Generic.HUD'
	IconCoords=(X2=2,Y2=2)
	ItemName="Translocator"
	Mesh=SkeletalMesh'NewWeapons2004.NewTranslauncher_1st'
	DrawScale=0.800000
	Skins(0)=FinalBlend'EpicParticles.JumpPad.NewTransLaunBoltFB'
	Skins(1)=Texture'fpsGame.Skins.GoldTransTex'
	Skins(2)=Texture'WeaponSkins.AmmoPickups.NEWTranslocatorPUCK'
	Skins(3)=FinalBlend'WeaponSkins.AmmoPickups.NewTransGlassFB'
}