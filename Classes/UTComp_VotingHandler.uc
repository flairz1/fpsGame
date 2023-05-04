class UTComp_VotingHandler extends Info;

const VOTING_TIMER = 1.0;
var float fVotingTime;
var float fVotingPercent;

var byte CurrentVoteID;
var byte iOldVoteID;

var string sVotingOptions;
var string sVotingOptionsAlt;
var int VoteSwitch;
var int VoteSwitch2;
var bool bAdminBypassVote;
var bool bVoteFailed;
var string CallingPlayer;

var MutUTComp UTCompMutator;

function InitializeVoting()
{
	SetTimer(VOTING_TIMER, true);
}

function bool StartVote(byte b, byte p, string Options, optional string Caller, optional byte P2, optional string Options2, optional bool bAdminBypass)
{
	if (CurrentVoteID == 255)
	{
		CurrentVoteID = b;
		VoteSwitch = p;
		VoteSwitch2 = p2;
		sVotingOptions = Options;
		sVotingOptionsAlt = Options2;
		fVotingTime = default.fVotingTime;
		bAdminBypassVote = bAdminBypass;
		CallingPlayer = Caller;
		return true;
	}
	return false;
}

function Timer()
{
	if (UTCompMutator.bDisableVoting)
		return;

	if (VoteInProgress() && !TimedOut() && VotePasses())
	{
		TakeActionOnVote(CurrentVoteID, VoteSwitch, sVotingOptions);
		ResetVoting();
	}
}

function ResetVoting()
{
	VoteSwitch = 255;
	CurrentVoteID = 255;
	iOldVoteID = 255;
}

function bool TimedOut()
{
	fVotingTime -= VOTING_TIMER;
	if (fVotingTime <= 0)
	{
		CurrentVoteID = 255;
		iOldVoteID = 255;
		if (bVoteFailed)
		{
			NotifyPlayersFail();
			bVoteFailed = false;
		}
		else
		{
			NotifyPlayersTimeOut();
		}
		return true;
	}
	return false;
}

function TakeActionOnVote(byte VoteType, byte VoteSwitch, string Options)
{
	fVotingTime = 0;

	if (VoteType == 1 && UTCompMutator.bBrightskinsVoting)
	{
		UTCompMutator.iBrightskins = Min(VoteSwitch+1, 3);
		UTCompMutator.default.iBrightskins = Min(VoteSwitch+1, 3);
		UTCompMutator.SRI.i_Brightskins = Min(VoteSwitch+1, 3);
	}
	else if (VoteType == 2 && UTCompMutator.bHitSoundsVoting)
	{
		UTCompMutator.iHitsounds = Min(VoteSwitch, 2);
		UTCompMutator.default.iHitsounds = Min(VoteSwitch, 2);
		UTCompMutator.SRI.i_Hitsounds = Min(VoteSwitch, 2);
	}
	else if (VoteType == 3 && UTCompMutator.bTeamOverlayVoting)
	{
		UTCompMutator.bTeamOverlay = (VoteSwitch == 1);
		UTCompMutator.default.bTeamOverlay = (VoteSwitch == 1);
		UTCompMutator.SRI.b_TeamOverlay = (VoteSwitch == 1);
	}
	else if (VoteType == 4 && UTCompMutator.bNetcodeVoting)
	{
		UTCompMutator.bNetcode = (VoteSwitch == 1);
		UTCompMutator.default.bNetcode = (VoteSwitch == 1);
		UTCompMutator.SRI.b_Netcode = (VoteSwitch == 1);
	}
	// PickupsOverlayVoting?

	UTCompMutator.static.StaticSaveConfig();
}

function bool ValidVotingOptions(string votingOptions)
{
	local array<string> options;
	local array<string> keyValue;
	local string sVotingOptionsWithoutMapName;
	local int i, sVotingOptionsStart;
	local bool isValidOption;

	sVotingOptionsStart = InStr(sVotingOptions, "?");

	if (sVotingOptionsStart != -1)
		sVotingOptionsWithoutMapName = Mid(sVotingOptions, sVotingOptionsStart + 1);

	Split(sVotingOptionsWithoutMapName, "?", options);
	for(i = 1; i < options.length; i++)
	{
		isValidOption = false;
		Split(options[i], "=", keyValue);
		if (keyValue.Length > 0)
		{
			switch (keyValue[0])
			{
				case "Game":
					isValidOption = true;
					break;
			}
		}

		if (!isValidOption)
		{
			Log("UTComp_Vote: Invalid voting parameter:"@keyValue[0]);
			return false;
		}
	}

	return true;
}

function bool VoteInProgress()
{
	if (CurrentVoteID != 255)
	{
		if (CurrentVoteID != iOldVoteID)
		{
			NotifyPlayersStart();
			iOldVoteID = CurrentVoteID;
		}
		return true;
	}
	return false;
}

function NotifyPlayersPasses()
{
	NotifyPlayersEnd();
	if (VoteSwitch == 8 || VoteSwitch == 9 || VoteSwitch == 10)
		BroadCastLocalizedMessage(class'UTComp_Vote_Passed', 1);
	else
		BroadCastLocalizedMessage(class'UTComp_Vote_Passed');
}

function NotifyPlayersStart()
{
	NotifyPlayers();
	BroadCastLocalizedMessage(class'UTComp_Vote_Started', CurrentVoteID);
	Level.Game.Broadcast(Self, "A vote has started by "$CallingPlayer$", press F5 to vote.");
}

function NotifyPlayersTimeOut()
{
	NotifyPlayersEnd();
	BroadCastLocalizedMessage(class'UTComp_Vote_TimeOut');
}

function NotifyPlayersFail()
{
	NotifyPlayersEnd();
	BroadCastLocalizedMessage(class'UTComp_Vote_Failed');
}

function NotifyPlayers()
{
	local Controller C;
	local UTComp_PRI uPRI;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (PlayerController(C) != None && C.PlayerReplicationInfo != None)
			uPRI = Class'UTComp_Util'.static.GetUTCompPRI(C.PlayerReplicationInfo);

		if (uPRI != None)
		{
			uPRI.CurrentVoteID = CurrentVoteID;
			uPRI.VoteSwitch = VoteSwitch;
			uPRI.VoteSwitch2 = VoteSwitch2;
			uPRI.VoteOptions = sVotingOptions;
			uPRI.VoteOptions2 = sVotingOptionsAlt;
		}
	}
}

function NotifyPlayersEnd()
{
	local Controller C;
	local UTComp_PRI uPRI;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (PlayerController(C) != None && C.PlayerReplicationInfo != None)
			uPRI = Class'UTComp_Util'.static.GetUTCompPRI(C.PlayerReplicationInfo);

		if (uPRI != None)
		{
			uPRI.CurrentVoteID = 255;
			uPRI.VoteSwitch = 255;
			uPRI.Vote = 255;
			uPRI.VoteOptions = "";
		}
	}
}

function bool VotePasses()
{
	local Controller C;
	local UTComp_PRI uPRI;
	local float fTotalVoteYes;
	local float fTotalVoteNo;
	local float fTotalAbstained;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (C.PlayerReplicationInfo != None && PlayerController(C) != None && !C.PlayerReplicationInfo.bOnlySpectator)
			uPRI = Class'UTComp_Util'.static.GetUTCompPRI(C.PlayerReplicationInfo);

		if (uPRI != None)
		{
			if (uPRI.Vote == 1)
				fTotalVoteYes += 1.0;
			else if (uPRI.Vote == 2)
				fTotalVoteNo += 1.0;
			else
				fTotalAbstained += 1.0;
		}
		uPRI = None;
	}
	UpdatePlayersOfTotal(fTotalVoteYes, fTotalVoteNo);

	if (fTotalVoteYes >= 1.0 && fTotalVoteYes / (fTotalVoteNo+fTotalAbstained + fTotalVoteYes) >= (fVotingPercent/100.0))
	{
		NotifyPlayersPasses();
		return true;
	}

	if (bAdminBypassVote)
	{
		NotifyPlayersPasses();
		bAdminBypassVote = false;
		return true;
	}

	if (fTotalVoteNo >= 1.0 && fTotalVoteNo / (fTotalVoteYes+fTotalVoteNo + fTotalAbstained) > (100.0 - fVotingPercent)/100.0)
	{
		fVotingTime = 0.0;
		bVoteFailed = true;
	}
	return false;
}

function UpdatePlayersOfTotal(float VotedYes, float VotedNo)
{
	local Controller C;
	local UTComp_PRI uPRI;

	for(C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (PlayerController(C) != None && C.PlayerReplicationInfo != None)
			uPRI = Class'UTComp_Util'.static.GetUTCompPRI(C.PlayerReplicationInfo);

		if (uPRI != None)
		{
			uPRI.VotedYes = VotedYes;
			uPRI.VotedNo = VotedNo;
		}
	}
}

defaultproperties
{
	fVotingTime=30.000000
	fVotingPercent=51.000000
	CurrentVoteID=255
	iOldVoteID=255
	VoteSwitch=255
}