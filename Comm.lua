WoHo.COMMPREFIX = "WoHo";

WoHo.COMM_MSG_CLIENT_INFO = "MyClient:"..GetAddOnMetadata("WorldOfHearthOh","Version");
WoHo.COMM_MSG_START_GAME = "Hi, I want to start a game with you. Lets rock!";
WoHo.COMM_MSG_ASK_FOR_CLIENT = "What client do you run?";

--embed AceComm for communication between clients (this imports all functions of the lib into the WoHo table)
LibStub("AceComm-3.0"):Embed(WoHo);

function WoHo:OnCommReceived(pre,msg,dist,sender)
	print(format("%s - %s: %s [%s]",pre,sender,msg,dist));
	
	if msg == WoHo.COMM_MSG_START_GAME then
		WoHo:COMM_GameRequested(sender);
	elseif msg == WoHo.COMM_MSG_ASK_FOR_CLIENT then
		WoHo:COMM_SendClient(sender);
	else
		print("Unknown COMM received:",msg,sender,dist);
	end;
end;

WoHo:RegisterComm(WoHo.COMMPREFIX);

function WoHo:COMM_AskForGame(target)
	assert(type(target) == "string","Wrong input for COMM target.");
	WoHo:SendCommMessage(WoHo.COMMPREFIX,WoHo.COMM_MSG_START_GAME,"WHISPER",target);
end;

function WoHo:COMM_AskForClient(target)
	assert(type(target) == "string","Wrong input for COMM target.");
	WoHo:SendCommMessage(WoHo.COMMPREFIX,WoHo.COMM_MSG_ASK_FOR_CLIENT,"WHISPER",target);
end;

function WoHo:COMM_SendClient(target)
	assert(type(target) == "string","Wrong input for COMM target.");
	WoHo:SendCommMessage(WoHo.COMMPREFIX,WoHo.COMM_MSG_CLIENT_INFO,"WHISPER",target);
end;

function WoHo:COMM_GameRequested(source)
	print(format("%s requested a game with you!",source));
end;