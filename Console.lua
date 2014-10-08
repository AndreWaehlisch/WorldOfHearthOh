local function WoHoSlashCmd(msg, editbox)
	if not msg then
		return;
	end;
	
	local lowmsg = strlower(msg);
	local command, commandrest = lowmsg:match("^(%S*)%s*(.-)$");
	-- local arg1, arg1rest = commandrest:match("^(%S*)%s*(.-)$");
	-- local arg2, arg2rest = arg1rest:match("^(%S*)%s*(.-)$");

	WoHo.board:Show();
end;

WoHo:RegisterChatCommand("woho", WoHoSlashCmd);