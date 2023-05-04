class TimedMessage extends CriticalEventPlus
	abstract;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if (Switch <= 10)
		return (Switch $ "..");
	else if (Switch == 11)
		return ("15 seconds..");
	else if (Switch == 12)
		return ("30 seconds left..");
	else if (Switch == 13)
		return ("1 minute remaining..");
	else if (Switch == 14)
		return ("2 minutes remaining..");
	else if (Switch == 15)
		return ("3 minutes remaining..");
	else if (Switch == 16)
		return ("5 minutes remaining..");
}

static function ClientReceive(PlayerController P, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

	if ((Switch > 0) && (Switch < 11))
		P.QueueAnnouncement(Class'TimerMessage'.default.CountDown[Switch-1], 1, AP_InstantOrQueueSwitch, 1);
}

defaultproperties
{
	bIsConsoleMessage=false
	DrawColor=(R=0,G=0,B=0,A=0)
	StackMode=SM_Down
	PosY=0.130000
}