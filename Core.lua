WoHo.Tiles = {};--links to models. to get container use tiles[i]:GetParent.
WoHo.Selected = {};
WoHo.numSelected = 0;
WoHo.wantedClickAction = 0;
WoHo.attackAnimationDuration = 1;--duration in seconds
WoHo.gameInProgress = false;
WoHo.tileSize = 80;
WoHo.selectionBorderSize = 8;
WoHo.numTilesPerPlayer = 5;
WoHo.tilesOffsetFromTopAndBottom = 50;

--owner list:
--0: detail page
--1: players minions
--2: enemies minions

WoHo.Hands = {
	[0] = {},
	[1] = {},
	[2] = {},
};

--status
--0: <tile not occupied>
--1: name
--2: atk
--3: def
--4: note

function WoHo:StartGame()
	WoHo.gameInProgress = true;
	--WoHo.startGameButton:Hide();
	WoHo.detailPage:Hide();
	WoHo:RemoveAllSelections();
	
	for i, k in pairs(WoHo.Tiles) do
		k:GetParent():Show();
		k:SetDisplay();
	end;
	
	WoHo.makeMoveButton:Show();
end;

function WoHo:GetRandomMinionID()
	local rand = fastrandom(1,WoHo.numMinions);
	local count = 0;
	
	for i in pairs(WoHo.minions) do
		count = count + 1;
		if count == rand then
			return i;
		end;
	end;
	
	return 384;
end;

function WoHo:CreateDetailPage()
	--PAGE CONTAINER
	WoHo.detailPage = CreateFrame("Frame",nil,WoHo.board);
	WoHo.detailPage:SetWidth(WoHo.board:GetWidth()*0.33);
	WoHo.detailPage:SetHeight(WoHo.board:GetHeight());
	WoHo.detailPage:SetPoint("TOPRIGHT",WoHo.board,"TOPLEFT",-2,0);

	WoHo.detailPage.bg = WoHo.detailPage:CreateTexture();
	WoHo.detailPage.bg:SetAllPoints(WoHo.detailPage);
	WoHo.detailPage.bg:SetTexture(0,0,0);
	
	WoHo.detailPage:SetScript("OnShow",function()
		local displayID = WoHo.Hands[0][1];
		local m = WoHo.minions[displayID];
		
		WoHo.detailModel:SetDisplayInfo(displayID);
		WoHo.detailString:SetText(format("%s: Atk: %d. Def: %d. %s",m[1],m[2],m[3],m[4]));
	end);
	
	--MODEL
	WoHo.detailModel = WoHo:CreateModel(0,WoHo.detailPage,"TOPRIGHT",0,0,"TOPRIGHT",WoHo.detailPage:GetWidth(),WoHo.detailPage:GetHeight()*.75);
	
	--steal blizzards model functions (\Interface\SharedXML\ModelFrames.xml)
	Model_OnLoad(WoHo.detailModel);
	WoHo.detailModel:SetScript("OnEvent",Model_OnEvent);
	WoHo.detailModel:SetScript("OnMouseDown",Model_OnMouseDown);
	WoHo.detailModel:SetScript("OnMouseUp",Model_OnMouseUp);
	WoHo.detailModel:SetScript("OnMouseWheel",Model_OnMouseWheel);
	WoHo.detailModel:SetScript("OnUpdate",Model_OnUpdate);
	
	WoHo.detailModel.bg = WoHo.detailModel:CreateTexture();
	WoHo.detailModel.bg:SetAllPoints(WoHo.detailModel);
	WoHo.detailModel.bg:SetTexture(1,1,1);
	
	--DESC. STRING
	WoHo.detailString = WoHo.detailPage:CreateFontString(nil,"ARTWORK","GameFontNormal");
	WoHo.detailString:SetPoint("TOPLEFT",WoHo.detailModel,"BOTTOMLEFT",10,-10);
	WoHo.detailString:SetWidth(WoHo.detailPage:GetWidth()*.9);
	WoHo.detailString:SetHeight(WoHo.detailPage:GetHeight()-WoHo.detailModel:GetHeight());
	
	--Close button
	WoHo.detailPage.closeButton = CreateFrame("Button",nil,WoHo.detailPage,"UIPanelCloseButton");
	WoHo.detailPage.closeButton:SetPoint("TOPRIGHT",WoHo.detailPage,"TOPRIGHT");
	WoHo.detailPage.closeButton:SetFrameLevel(WoHo.detailModel:GetFrameLevel()+1);
	
	WoHo.detailPage:Hide();
end;

function WoHo:SetDetailDisplay(displayID)
	WoHo.detailPage:Hide();
	
	if not (displayID==0) then
		WoHo.Hands[0] = {displayID};
		WoHo.detailPage:Show();
	end;
end;

function WoHo:SetSelection(model)
	model:GetParent():SetBackdropBorderColor(1,0,0,1);
	WoHo.Selected[model.id] = true;
	WoHo.numSelected = WoHo.numSelected + 1;
end;

function WoHo:RemoveSelection(model)
	model:GetParent():SetBackdropBorderColor(0,0,0,0);
	WoHo.Selected[model.id] = nil;
	WoHo.numSelected = WoHo.numSelected - 1;
end;

function WoHo:RemoveAllSelections()
	for i in pairs(WoHo.Selected) do
		WoHo:RemoveSelection(WoHo.Tiles[i]);
	end;
end;

function WoHo:CreateAnimationPath(frame)
	local model = frame;
	
	function frame:AnimationPlay()
		WoHo.board:SetMovable(false);
		
		local frame = frame:GetParent();
		
		--the anchor point of the frame before the animation
		frame.oldpoint = { frame:GetPoint(1) };
		--timers for OnUpdate script
		local elapsTime = 0;
		local timeVar = 0;
		
		--duration of the forth animation (this is the half of the whole duration)
		local duration = assert(frame.duration,"No animation duration found for this frame.")/2;
		
		--target frame of the animation
		local target = assert(frame.animationTarget,"No target frame found for this frame."):GetParent();
		
		--coordinates of start positions of frame and target
		local frameX = frame:GetLeft();
		local frameY = frame:GetBottom();
		local targetX = target:GetLeft();
		local targetY = target:GetBottom();
		local connectionVectorX = targetX-frameX;
		local connectionVectorY = targetY-frameY;
		
		frame:ClearAllPoints();
		frame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",frameX,frameY);
		
		local function r(t,xy)--xy==1 for x and xy==2 for y
			local connectionVector = (xy == 1) and connectionVectorX or connectionVectorY;
			local frame = (xy == 1) and frameX or frameY;
			local target = (xy == 1) and targetX or targetY;
			
			if t < duration then
				return connectionVector*(t/duration)+frame;
			else
				return (-connectionVector)*((t-duration)/duration)+target;
			end;
		end;
		
		--DO the moving
		frame:SetScript("OnUpdate",function(self,elapsed)
			timeVar = timeVar + elapsed;
			
			if timeVar >= duration*2 then
				model:AnimationStop();
				return;
			end;
			
			frame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",r(timeVar,1),r(timeVar,2));
		end);
	end;
	
	function frame:AnimationStop()
		WoHo.board:SetMovable(true);
		
		local frame = frame:GetParent();
		
		if not frame.oldpoint then
			return;
		end;
		
		frame:SetScript("OnUpdate",nil);
		frame:ClearAllPoints();
		frame:SetPoint(
			frame.oldpoint[1],
			frame.oldpoint[2],
			frame.oldpoint[3],
			frame.oldpoint[4],
			frame.oldpoint[5]
		);
	end;
	
	function frame:SetAnimationPath(target,duration)
		local frame = frame:GetParent();
		frame.animationTarget = assert(target,"No target frame specified!");
		frame.duration = duration or WoHo.attackAnimationDuration;--duration in seconds
	end;
end;

function WoHo:AttackAnimation(source,target)
	source:AnimationStop();
	source:SetAnimationPath(target);
	source:AnimationPlay();
end;

function WoHo:KillMinion(minion)
	minion.displayID = 0;
	minion.status = 0;
	minion:ClearModel();
end;

function WoHo:Attack(source,target)
	WoHo:AttackAnimation(source,target);

	local sourceATK = WoHo.minions[source.displayID][source.status];
	local targetATKDEF = WoHo.minions[target.displayID][target.status];
	
	if sourceATK > targetATKDEF then
		WoHo:KillMinion(target);
	elseif sourceATK == targetATKDEF then
		WoHo:KillMinion(source);
		WoHo:KillMinion(target);
	else
		WoHo:KillMinion(source);
	end;
end;

function WoHo:LeftButtonTile(tile)
	if tile.owner == 0 then
		return;
	end;
	
	local id = tile.id;
	
	if WoHo.wantedClickAction == 0 then
		if tile.owner == 1 then
			if WoHo.Selected[id] then
				WoHo:RemoveAllSelections();
			else
				WoHo:RemoveAllSelections();
				WoHo:SetSelection(tile);
			end;
		elseif tile.owner == 2 then
			if WoHo.numSelected == 1 then
				WoHo:SetSelection(tile);
			elseif WoHo.numSelected == 2 then
				for i in pairs(WoHo.Selected) do
					if WoHo.Tiles[i].owner == 2 then
						WoHo:RemoveSelection(WoHo.Tiles[i]);
					end;
				end;
				WoHo:SetSelection(tile);
			end;
		end;
	end;
end;

local modelID = 1;
function WoHo:CreateModel(owner,parent,point,x,y,parentPoint,width,height)
	local container = CreateFrame("PlayerModel",nil,parent);
	
	if parentPoint then
		container:SetPoint(point,parent,parentPoint,x,y);
	else
		container:SetPoint(point,x,y);
	end;
	
	container:SetSize(width or WoHo.tileSize, height or width or WoHo.tileSize);
	
	local myModel = CreateFrame("PlayerModel",nil,container);
	WoHo.Tiles[modelID] = myModel;
	WoHo:CreateAnimationPath(myModel);
	myModel:SetHeight(container:GetHeight()*0.9);
	myModel:SetWidth(container:GetWidth()*0.9);
	myModel:SetPoint("CENTER");
	myModel.id = modelID;
	myModel.status = 2;--TODO: make real status when playing card
	modelID = modelID + 1;
	myModel.owner = owner;
	
	function myModel:SetDisplay(displayID)
		if displayID then
			myModel:SetDisplayInfo(displayID);
			myModel.displayID = displayID;
		else
			myModel:SetDisplay(WoHo:GetRandomMinionID());
		end;
		myModel.status = 2;
	end;
	
	--background texture
	myModel.bg = myModel:CreateTexture();
	myModel.bg:SetAllPoints(myModel);
	myModel.bg:SetTexture(1,1,1);
	container:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeSize = WoHo.selectionBorderSize,
	});
	container:SetBackdropBorderColor(0,0,0,0);
	
	myModel:SetScript("OnMouseUp",function(self,button)
		if button == "LeftButton" then
			WoHo:LeftButtonTile(self);
		elseif button == "RightButton" then
			WoHo:SetDetailDisplay(self.displayID);
		end;
	end);
	
	container:Hide();
	
	return myModel;
end;

function WoHo:CreateBoard()
	--create the board
	WoHo.board = CreateFrame("Frame");
	local board = WoHo.board;
	
	board:Hide();
	
	board:SetSize(600,400);
	board:SetPoint("CENTER",UIParent,"CENTER");
	
	board:SetMovable(true);
	board:EnableMouse(true);
	board:RegisterForDrag("LeftButton");
	
	board:SetScript("OnDragStart",function(self)
		if self:IsMovable() then
			self:StartMoving();
		end;
	end);
	
	board:SetScript("OnDragStop",function(self)
		self:StopMovingOrSizing();
	end);
	
	--board close button
	board.closeButton = CreateFrame("Button",nil,WoHo.board,"UIPanelCloseButton");
	board.closeButton:SetPoint("TOPRIGHT",WoHo.board,"TOPRIGHT");
	
	--board background
	board.bg = board:CreateTexture();
	board.bg:SetAllPoints(board);
	board.bg:SetTexture(.2,.2,.2,.9);
	
	--detail page (right click details)
	WoHo:CreateDetailPage();
	
	--player field
	for i = 1, WoHo.numTilesPerPlayer do
		local xOffset = ((WoHo.board:GetWidth()-(WoHo.tileSize*WoHo.numTilesPerPlayer))/2)+(i-1)*(WoHo.tileSize+2);
		WoHo:CreateModel(1,WoHo.board,"BOTTOMLEFT",xOffset,WoHo.tilesOffsetFromTopAndBottom,"BOTTOMLEFT");
	end;
	
	--enemy field
	for i = 1, WoHo.numTilesPerPlayer do
		local xOffset = ((WoHo.board:GetWidth()-(WoHo.tileSize*WoHo.numTilesPerPlayer))/2)+(i-1)*(WoHo.tileSize+2);
		WoHo:CreateModel(2,WoHo.board,"TOPLEFT",xOffset,-WoHo.tilesOffsetFromTopAndBottom,"TOPLEFT");
	end;
	
	--start game button
	WoHo.startGameButton = CreateFrame("Button",nil,WoHo.board,"UIPanelButtonTemplate");
	WoHo.startGameButton:SetSize(150,40);
	WoHo.startGameButton:SetPoint("CENTER");
	WoHo.startGameButton:SetText("Start Game!");
	WoHo.startGameButton:SetScript("OnClick",WoHo.StartGame);
	
	--make move button
	WoHo.makeMoveButton = CreateFrame("Button",nil,WoHo.board,"UIPanelButtonTemplate");
	WoHo.makeMoveButton:Hide();
	WoHo.makeMoveButton:SetSize(80,40);
	WoHo.makeMoveButton:SetPoint("LEFT",WoHo.startGameButton,"RIGHT",10,0);
	WoHo.makeMoveButton:SetText("Make Move");
	WoHo.makeMoveButton:SetScript("OnClick",function()
		if WoHo.numSelected == 2 then
			local source, target;
			for i in pairs(WoHo.Selected) do
				local owner = WoHo.Tiles[i].owner
				if owner == 1 then
					source = WoHo.Tiles[i];
				elseif owner == 2 then
					target = WoHo.Tiles[i];
				end;
			end;
			
			if source.status == 0 or target.status == 0 then
				return;
			end;
			
			WoHo:Attack(source,target)
		end;
	end);
end;

-----------------------------------------
--Slash Commands
-----------------------------------------
SLASH_WOHO1 = "/woho";
local function WoHoSlashCmd(msg,self)
	if not msg then
		return;
	end;
	
	local lowmsg = strlower(msg);
	local command, commandrest = lowmsg:match("^(%S*)%s*(.-)$");
	-- local arg1, arg1rest = commandrest:match("^(%S*)%s*(.-)$");
	-- local arg2, arg2rest = arg1rest:match("^(%S*)%s*(.-)$");

	WoHo.board:Show();
end;
SlashCmdList["WOHO"] = WoHoSlashCmd;

WoHo:CreateBoard();