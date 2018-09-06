--[[
	NOTE: This is my personal UI modifications.  It's not meant for the general public.
	Don't say I didn't warn you!
--]]

----------------------------------------------------------------
---COLOR BARS BY CLASS
----------------------------------------------------------------

local debugf = tekDebug and tekDebug:GetFrame("xanUI")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local function colour(statusbar, unit)
	if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
		local _, class = UnitClass(unit)
		local c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		statusbar:SetStatusBarColor(c.r, c.g, c.b)
	end
end

hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
	colour(self, self.unit)
end)

local sb = _G.GameTooltipStatusBar
local addon = CreateFrame("Frame", "StatusColour")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:SetScript("OnEvent", function()
	colour(sb, "mouseover")
end)

-- Always show missing transmogs in tooltips
C_TransmogCollection.SetShowMissingSourceInItemTooltips(true)

----------------------------------------------------------------
---ADD Missing stats to the character panel
----------------------------------------------------------------

--don't really want to show all stats but use this as a guideline
--[[ function xanUI_ShowAllStats()
	PAPERDOLL_STATCATEGORIES= {
		[1] = {
			categoryFrame = "AttributesCategory",
			stats = {
				[1] = { stat = "HEALTH" },
				[2] = { stat = "POWER" },
				[3] = { stat = "ALTERNATEMANA" },
				[5] = { stat = "ARMOR" },
				[6] = { stat = "STRENGTH" },
				[7] = { stat = "AGILITY" },
				[8] = { stat = "INTELLECT" },
				[9] = { stat = "STAMINA" },
				[10] = { stat = "ATTACK_DAMAGE" },
				[11] = { stat = "ATTACK_AP" },
				[12] = { stat = "ATTACK_ATTACKSPEED" },
				[13] = { stat = "SPELLPOWER" },
				[14] = { stat = "MANAREGEN", hideAt = 0 },
				[15] = { stat = "ENERGY_REGEN", hideAt = 0 },
				[16] = { stat = "RUNE_REGEN", hideAt = 0 },
				[17] = { stat = "FOCUS_REGEN", hideAt = 0 },
				[18] = { stat = "MOVESPEED" },
				[19] = { stat = "DURABILITY" },
				[20] = { stat = "REPAIRTOTAL" },
				[21] = { stat = "ITEMLEVEL" },
			},
		},
		[2] = {
			categoryFrame = "EnhancementsCategory",
			stats = {
				[1] = { stat = "CRITCHANCE" },
				[2] = { stat = "HASTE" },
				[3] = { stat = "VERSATILITY" },
				[4] = { stat = "MASTERY" },
				[5] = { stat = "LIFESTEAL" },
				[6] = { stat = "AVOIDANCE" },
				[7] = { stat = "DODGE" },
				[8] = { stat = "PARRY" },
				[9] = { stat = "BLOCK" },
			},
		},
	};
	PaperDollFrame_UpdateStats();
end ]]


function xanUI_InsertStats()
	
	--1 is the top category with intellect and such, 2 is the second category
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "ATTACK_DAMAGE" });
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "ATTACK_AP" });
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "SPELLPOWER" });

end

----------------------------------------------------------------
---FACTION INDICATORS
----------------------------------------------------------------

function xanUI_CreateFactionIcon(frame)
	local f
	
	f = CreateFrame("Frame", "$parentFaction", frame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(40)
	f:SetHeight(40)

	local t = f:CreateTexture("$parentIcon", "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\xanUI\\media\\Unknown")
	t:SetAllPoints(f)
	
	if frame == TargetFrame then
		f:SetPoint("CENTER", 67, 24)
	elseif frame == TargetFrameToT then
		f:SetPoint("CENTER", -35, 5)
	else
		f:SetPoint("CENTER", -6, 10)
	end
	
	f:Hide()
end

function xanUI_UpdateFactionIcon(unit, frame)
	if not unit then return nil end
	if not frame then return nil end

	if frame == TargetFrame then
		--we have to move the target raid icon identifier to the right a bit (skull, diamond, star, etc..)
		TargetFrameTextureFrameRaidTargetIcon:SetPoint("CENTER", TargetFrame, "TOPRIGHT", -82, -74);
		--bottom right to the left of level icon
		
		--we have to move the target leader icon as well
		TargetFrameTextureFrameLeaderIcon:ClearAllPoints();
		TargetFrameTextureFrameLeaderIcon:SetPoint("TOPLEFT", -2, -15);

		--don't show the faction icon if the unit is already in PVP.  The PVP icon is a bigger notifier of what
		--faction a unit is... duh!
		if( UnitFactionGroup(unit) and UnitFactionGroup(unit):lower() ~= "neutral" and not TargetFrameTextureFramePVPIcon:IsVisible()) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
		
	elseif frame == TargetFrameToT then
		if( UnitFactionGroup(unit) and UnitFactionGroup(unit):lower() ~= "neutral"	) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end
	end

end

xanUI_CreateFactionIcon(TargetFrame)
xanUI_CreateFactionIcon(TargetFrameToT)

----------------------------------------------------------------
---CLASS SPEC INDICATORS
----------------------------------------------------------------

local specEventFrame = CreateFrame("Frame")

function xanUI_UpdateClassSpecIcon()
	getglobal("TargetFrameClassSpec"):Hide()
	if CanInspect("target") then
		specEventFrame:RegisterEvent("INSPECT_READY")
		NotifyInspect("target")
	end
end

specEventFrame:SetScript("OnEvent", function(self, event, ...)
	
	if UnitIsPlayer("target") then
	
		local spec_id = GetInspectSpecialization("target")
		
		specEventFrame:UnregisterEvent("INSPECT_READY")
		ClearInspectPlayer()
		
		local id, name, description, icon, background, role, class = GetSpecializationInfoByID(spec_id)

		getglobal("TargetFrameClassSpecIcon"):SetTexture(icon)
		getglobal("TargetFrameClassSpec"):Show()
	else
		getglobal("TargetFrameClassSpec"):Hide()
	end

end)

function xanUI_CreateClassSpecIcons(frame)
	local f
	
	f = CreateFrame("Frame", "$parentClassSpec", frame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(42)
	f:SetHeight(42)

	local t = f:CreateTexture("$parentIcon", "BACKGROUND", nil, 2)
	local q = f:CreateTexture("$parentRing", "BACKGROUND", nil, 3)
	
	q:SetPoint("CENTER", f, "CENTER", 0, 0)
	q:SetSize(42, 42)
	q:SetAtlas('Talent-RingWithDot')

	t:SetPoint('TOPLEFT', q, 9, -9)
	t:SetPoint('BOTTOMRIGHT', q, -9, 9)
	
	f:SetPoint("CENTER", 88, 35)
	f:Hide()
end

xanUI_CreateClassSpecIcons(TargetFrame)


----------------------------------------------------------------
----------------------------------------------------------------

function xanUI_smallNum(sNum)
	if not sNum then return end

	sNum = tonumber(sNum)

	if sNum < 1000 then
		return sNum
	elseif sNum >= 1000 then
		return string.format("%.1fK", sNum/1000)
	else	
		return sNum
	end
end

--make sure to set Status Text to Numeric Values in Interface Options for this to work
--"PERCENT" and "NUMERIC"
--GetCVarDefault("statusTextDisplay") -> "NUMERIC"
--GetCVarDefault("statusText") -> "0"

--force Numeric for healthbar fix
SetCVar("statusTextDisplay","NUMERIC")
--InterfaceOptionsStatusTextPanelDisplayDropDown:SetValue("NUMERIC")

hooksecurefunc( "TextStatusBar_UpdateTextString", function(self)

	if self and self:GetParent() then
		local frame = self:GetParent();
		
		if frame:GetName() then
		
			local parentName = frame:GetName();
			local textString = self.TextString;
			
			--display according to frame name
			if parentName == "PlayerFrame" or parentName == "TargetFrame" or parentName == "TargetFrameToT" then
			
				local value = self:GetValue();
				local valueMin, valueMax = self:GetMinMaxValues();
			
				--check player death text
				if parentName == "PlayerFrame" then
					if UnitIsUnconscious("player") or UnitIsDeadOrGhost("player") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("Dead")
						end
						return
					end
				end
				--check target
				if parentName == "TargetFrame" then
					if UnitIsUnconscious("target") or UnitIsDeadOrGhost("target") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("Dead")
						end
						TargetFrame.healthbar.LeftText:Hide()
						TargetFrame.healthbar.RightText:Hide()							
						return
					end
				end
				--check target of target
				if parentName == "TargetFrameToT" then
					if UnitIsUnconscious("targettarget") or UnitIsDeadOrGhost("targettarget") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("Dead")
						end						
						return
					end
				end
				

				if valueMax > 0 then
					local pervalue = tostring(math.floor((value / valueMax) * 100)) .. " %";

					if not getglobal(parentName.."PercentStr") and string.find(self:GetName(), "HealthBar") then
						getglobal(parentName):CreateFontString("$parentPercentStr", "OVERLAY")
						getglobal(parentName.."PercentStr"):SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
						if parentName == "PlayerFrame" then
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPRIGHT", -20, -12)
						elseif parentName == "TargetFrame" then
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPLEFT", 20, -12)
						else
							--target of target
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPLEFT", 65, -8)
						end							
						getglobal(parentName.."PercentStr"):SetText(pervalue)
						getglobal(parentName.."PercentStr"):Show()
					elseif string.find(self:GetName(), "HealthBar") then
						getglobal(parentName.."PercentStr"):SetText(pervalue)
					end
					
					if getglobal(parentName.."PercentStr") and not getglobal(parentName.."PercentStr"):IsVisible() then
						getglobal(parentName.."PercentStr"):Show()
					end
					
				end

			end	
			
		end
	end
end)


--[[------------------------
	Blizzard Tradeskills Castbar
	This will modify the target castbar to also show tradeskills
--------------------------]]

local enableTradeskills = true

--initial override
if TargetFrameSpellBar then
	TargetFrameSpellBar.showTradeSkills = enableTradeskills
end

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

--SHOW Quest level information on the quest tracker
--Color it by level as well if necessary

hooksecurefunc(QUEST_TRACKER_MODULE, "Update", function(self)
	for i = 1, GetNumQuestWatches() do
		local questID, title, questLogIndex, numObjectives, requiredMoney, isComplete, startEvent, isAutoComplete, failureTime, timeElapsed, questType, isTask, isStory, isOnMap, hasLocalPOI = GetQuestWatchInfo(i)
		if ( not questID ) then
			break
		end
		local oldBlock = QUEST_TRACKER_MODULE:GetExistingBlock(questID)
		if oldBlock then
			local oldBlockHeight = oldBlock.height
			local oldHeight = QUEST_TRACKER_MODULE:SetStringText(oldBlock.HeaderText, title, nil, OBJECTIVE_TRACKER_COLOR["Header"])
			local newTitle = "["..select(2, GetQuestLogTitle(questLogIndex)).."] "..title
			local newHeight = QUEST_TRACKER_MODULE:SetStringText(oldBlock.HeaderText, newTitle, nil, OBJECTIVE_TRACKER_COLOR["Header"])
			oldBlock:SetHeight(oldBlockHeight + newHeight - oldHeight);
		end
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

function XanUI_SaveLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XanUIDB then XanUIDB = {} end
	
	local opt = XanUIDB[frame] or nil

	if not opt then
		XanUIDB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanUIDB[frame]
		return
	end

	local point, relativeTo, relativePoint, xOfs, yOfs = _G[frame]:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
end

function XanUI_RestoreLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XanUIDB then XanUIDB = {} end

	local opt = XanUIDB[frame] or nil

	if not opt then
		XanUIDB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanUIDB[frame]
	end

	_G[frame]:ClearAllPoints()
	_G[frame]:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
end

----------------------------------------------------------------
---Change Blizzard Buff timers to be more readable
----------------------------------------------------------------
local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR   = 60 * SECONDS_PER_MINUTE
local SECONDS_PER_DAY    = 24 * SECONDS_PER_HOUR

function SecondsToTimeAbbrev(seconds)
	if seconds <= 0 then return "" end

	local days = seconds / SECONDS_PER_DAY
	if days >= 1 then return string.format("%.1fd", days) end

	local hours = seconds / SECONDS_PER_HOUR
	if hours >= 1 then return string.format("%.02fh", hours) end

	local minutes = seconds / SECONDS_PER_MINUTE
	local seconds = seconds % SECONDS_PER_MINUTE
	if minutes >= 1 then return string.format("%d:%02d", minutes, seconds) end
	return string.format("%ds", seconds)
end


----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------


--[[ local worldmapProvider = CreateFromMixins(MapCanvasDataProviderMixin)
WorldMapFrame:AddDataProvider(worldmapProvider) ]]

-- function worldmapProvider:RefreshAllData(fromOnShow)
    -- self:RemoveAllData()

    -- for icon, data in pairs(worldmapPins) do
        -- self:HandlePin(icon, data)
    -- end
-- end

-- local function UpdateWorldMap()
    -- worldmapProvider:RefreshAllData()
-- end

--xanUI_Test = {}

--hooksecurefunc ("ToggleWorldMap", function (self)

--	if (WorldMapFrame:IsShown()) then
	

	--[[ 	if WorldMapFrame then
			-- xanUI_Test.pins = {}

			-- for sourcePin in worldmapProvider:GetMap():EnumerateAllPins() do
				-- table.insert(xanUI_Test.pins, sourcePin)
			-- end

			-- xanUI_Test.maps = worldmapProvider:GetMap():EnumerateAllPins()

			xanUI_Test.default_pins = {}
			xanUI_Test.default_state = {}
			xanUI_Test.dataProviders = WorldMapFrame.dataProviders
			
			xanUI_Test.get_maps = {}

			for dataProvider, state in pairs (WorldMapFrame.dataProviders) do
				table.insert(xanUI_Test.default_pins, dataProvider)
				table.insert(xanUI_Test.default_state, state)
				
				table.insert(xanUI_Test.get_maps, dataProvider:GetMap())
				
				--self:GetMap():RemoveAllPinsByTemplate("DigSitePinTemplate");
				
				--dataProvider:GetMap():GetMapID()
				--dataProvider:GetMap().pinPools
				
				--if dataProvider.RemoveAllData then
					--dataProvider:RemoveAllData()
				--end
			end
			
			
		end ]]
		
--[[ 			for dataProvider, state in pairs (WorldMapFrame.dataProviders) do
				local mapID = dataProvider:GetMap():GetMapID()
				local taskInfo = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
				
				if (taskInfo and #taskInfo > 0) then
					for i, info  in ipairs (taskInfo) do
						local questID = info.questId
						if (HaveQuestData (questID)) then
							local isWorldQuest = QuestUtils_IsQuestWorldQuest (questID)
							if (isWorldQuest) then
								Debug(mapID, questID)
							end
						end
					end
				end
				
			end ]]

--	end
	
--end)




--[[ local function OrigProviderOnRemoved(self, mapCanvas)
    -- temporary fix to prevent error when removing the original world quest provider, I've notified
    -- Blizzard developers directly about this issue and it should be resolved soon™
    local Map = self:GetMap()
    Map:UnregisterCallback('SetFocusedQuestID', self.setFocusedQuestIDCallback)
    Map:UnregisterCallback('ClearFocusedQuestID', self.clearFocusedQuestIDCallback)
    Map:UnregisterCallback('SetBountyQuestID', self.setBountyQuestIDCallback)
 
    MapCanvasDataProviderMixin.OnRemoved(self, mapCanvas)
end
 
for provider in next, WorldMapFrame.dataProviders do
    if(provider.GetPinTemplate and provider.GetPinTemplate() == 'WorldMap_WorldQuestPinTemplate') then
        -- BUG: the OnRemoved method is broken, so we replace it before we remove the provider
        provider.OnRemoved = OrigProviderOnRemoved
        WorldMapFrame:RemoveDataProvider(provider)
    end
end
 ]]


--[[ 

xanUI_pins = {}
xanUI_Texture = {}

--WorldQuestDataProviderMixin:AddWorldQuest(info)
--worldquest-icon-dungeon

hooksecurefunc (WorldMapFrame, "OnMapChanged", function()

	local mapID = WorldMapFrame.mapID

	for dataProvider, state in pairs (WorldMapFrame.dataProviders) do

		if mapID == dataProvider:GetMap():GetMapID() then
				
			local taskInfo = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
	
			if (taskInfo and #taskInfo > 0) then

				local questPins = {}
				
				for pin in dataProvider:GetMap():EnumerateAllPins() do
					if pin.questID and pin.Background then
						questPins[pin.questID] = pin
						table.insert(xanUI_pins, pin)
						--Debug("Background", pin.icon, pin.name, pin.Background:GetTexture())
					end
					
					if pin.Texture then
						table.insert(xanUI_Texture, pin.Texture)
						--Debug("Underlay", pin.icon, pin.name, pin.Texture:GetTexture())
					end
					
					--local filename, width, height, left, right, top, bottom, tilesHoriz, tilesVert = GetAtlasInfo("worldquest-icon-dungeon")
					
					--Debug(filename, width, height, left, right, top, bottom, tilesHoriz, tilesVert)
					
				end
			
				for i, info  in ipairs (taskInfo) do
					local questID = info.questId
					if (HaveQuestData (questID)) then
						if questPins[questID] and questPins[questID].worldQuest then
							--dataProvider:GetMap():RemovePin(questPins[questID])
						end
					end
				end
				
			end
			
			break
		end
		
	end

end) ]]
	
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------


local eventFrame = CreateFrame("frame","xanUIEventFrame",UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_TARGET")

local TomTomWPS = {}

function eventFrame:PLAYER_LOGIN()
	if not XanUIDB then XanUIDB = {} end
	if not XanUIDB["hidebossframes"] then XanUIDB["hidebossframes"] = false end

	local ver = GetAddOnMetadata("xanUI","Version") or 0
		
	SLASH_XANUI1 = "/xanui"
	SLASH_XANUI2 = "/xui"
	SlashCmdList["XANUI"] = function(msg)
	
		local a,b,c=strfind(msg, "(%S+)"); --contiguous string of non-space characters
		
		if a then
			if c and c:lower() == "hidebossframes" then
				if XanUIDB.hidebossframes then
					XanUIDB.hidebossframes = false
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Blizzard Boss Health Frames are now [|cFF99CC33ON|r]")
				else
					XanUIDB.hidebossframes = true
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Blizzard Boss Health Frames are now [|cFF99CC33OFF|r]")
					for i = 1, 4 do
						local frame = _G["Boss"..i.."TargetFrame"]
						frame:UnregisterAllEvents()
						frame:Hide()
						frame.Show = function () end
					end
				end
				return true
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage("xanUI")
		DEFAULT_CHAT_FRAME:AddMessage("/xanui hidebossframes - Toggles Hiding Blizzard Boss Health Frames On or Off")

	end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [v|cFF20ff20"..ver.."|r]   /xanui, /xui")

	--ADD TradeSkills to the Blizzard Default TargetFrameSpellBar
	TargetFrameSpellBar.showTradeSkills = enableTradeskills;

	--move the target or target frame ToT
	--some bosses have these special charge bars to the right of their frame
	--so lets put the TOT below it and to the right slightly
	TargetFrameToT:ClearAllPoints()
	TargetFrameToT:SetPoint("RIGHT", TargetFrame, "RIGHT", 100, -45);
	
	--Move the FocusFrameToT Frame to the right of the Focus frame
	FocusFrameToT:ClearAllPoints()
	FocusFrameToT:SetPoint("RIGHT", FocusFrame, "RIGHT", 95, 0);

	--hide the stupid blizzard boss frames
	if XanUIDB.hidebossframes then
		for i = 1, 4 do
			local frame = _G["Boss"..i.."TargetFrame"]
			frame:UnregisterAllEvents()
			frame:Hide()
			frame.Show = function () end
		end
	end
	
	--edit the character panel stats
	xanUI_InsertStats()

	if TomTom then
		--add the Shal'Aran portal destinations because it's annoying to remember them
		--crazy is for the crazy arrow, setting cleardistance allows the waypoint to persist even when you go near it.  Otherwise it gets removed when you approach.
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 39.1/100, 76.3/100, { title = "Portal: Felsoul Hold", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 21.5/100, 29.9/100, { title = "Portal: Falanaar", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 30.8/100, 10.9/100, { title = "Portal: Moon Guard Stronghold", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 43.6/100, 79.1/100, { title = "Portal: Lunastre Estate", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 36.2/100, 47.1/100, { title = "Portal: Ruins of Elune'eth", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 47.6/100, 81.6/100, { title = "Portal: The Waning Crescent", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 43.4/100, 60.7/100, { title = "Portal: Sanctum of Order", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 42.2/100, 35.4/100, { title = "Portal: Tel'anor", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 64.0/100, 60.4/100, { title = "Portal: Twilight Vineyards", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 54.4/100, 69.5/100, { title = "Portal: Harbor (Quest Required)", crazy=false, persistent=true, cleardistance=0 }) )
		table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 52.03/100, 78.86/100, { title = "Portal: Evermoon Terrace (Quest Required)", crazy=false, persistent=true, cleardistance=0 }) )
		--add them all to a table to remove them in the future
	end
		
	--NAMEPLATES
	--http://www.wowinterface.com/forums/showthread.php?t=55998
	SetCVar("nameplateShowAll", 1) -- always show the nameplates (combat/noncombat)
	SetCVar("nameplateShowFriends", 1) -- show for friendly units
	SetCVar("nameplateShowFriendlyNPCs", 0) --show the nameplates on friendly units as well

	--SetCVar("nameplateShowEnemyMinions", 0) -- Enemy Minions
	--SetCVar("nameplateShowEnemyMinus", 0) -- Enemy Minors
	
	SetCVar("nameplateMaxDistance", 100) --default 60

				
	eventFrame:UnregisterEvent("PLAYER_LOGIN")
end

function eventFrame:PLAYER_TARGET_CHANGED()
	xanUI_UpdateFactionIcon("target", TargetFrame)
	xanUI_UpdateClassSpecIcon()
end

function eventFrame:UNIT_TARGET(self, unitid)
	--update target of target because PLAYER_TARGET_CHANGED doesn't always work
	if UnitExists("targettarget") then
		xanUI_UpdateFactionIcon("targettarget", TargetFrameToT)
	end
	
end

----------------------------------------------------------------
---Shows total gold if any in the mailbox
----------------------------------------------------------------
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")

function eventFrame:MAIL_SHOW()
	if not MailFrame.totalMoneyInBox then
		MailFrame.totalMoneyInBox = MailFrame:CreateFontString(nil, "OVERLAY")
		MailFrame.totalMoneyInBox:SetFontObject('NumberFontNormal')
		MailFrame.totalMoneyInBox:SetPoint("CENTER", MailFrame, "TOP", 0, 12)
	end
end

function eventFrame:MAIL_INBOX_UPDATE()
	if not MailFrame.totalMoneyInBox then return end

	local mountCount = 0

	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			local packageIcon, stationeryIcon, sender, subject, money = GetInboxHeaderInfo(mailIndex)
			if money > 0 then
				mountCount = mountCount + money
			end
		end
	end
	
	if mountCount > 0 then
		MailFrame.totalMoneyInBox:SetText("Total Money: "..GetCoinTextureString(mountCount))
	else
		MailFrame.totalMoneyInBox:Hide()
	end
	
end


function eventFrame:MAIL_CLOSED()
	if MailFrame.totalMoneyInBox then MailFrame.totalMoneyInBox:Hide() end
end

----------------------------------------------------------------
---Open all bags when at bank
----------------------------------------------------------------
eventFrame:RegisterEvent("BANKFRAME_OPENED")

function eventFrame:BANKFRAME_OPENED()
	local numSlots, full
	local i

	numSlots, full = GetNumBankSlots()
	for i = 0, numSlots do
		OpenBag(NUM_BAG_SLOTS + 1 + i)
	end
end

----------------------------------------------------------------
---Sell Junk at Vendors
----------------------------------------------------------------
eventFrame:RegisterEvent("MERCHANT_SHOW")

local doGuildRepairs = false

function eventFrame:MERCHANT_SHOW()
	
	local moneyCount = 0
	local itemCount = 0
	
	for bag = 0,4 do
		for slot = 1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and select(3, GetItemInfo(link)) == 0 then
				
				local value = select(11, GetItemInfo(link)) or 0
				if value > 0 then
					UseContainerItem(bag, slot)
					moneyCount = moneyCount + value
				else
					PickupContainerItem(bag, slot)
					DeleteCursorItem()
				end
				
				itemCount = itemCount + 1
			end
		end
	end

	-- local ignoreList = {
		-- [140662] = "Deformed Eredar Head", --warlock artifact quest
		-- [140661] = "Damaged Eredar Head", --warlock artifact quest
		-- [140663] = "Malformed Eredar Head", --warlock artifact quest
		-- [140664] = "Deficient Eredar Head", --warlock artifact quest
		-- [140665] = "Nearly Satisfactory Eredar Head", --warlock artifact quest
	-- }

	-- result = tonumber(result:match("^(%d+):")) --just grab the first number
	-- if result and ignoreList[result] then
		-- ShowMerchantSellCursor(0)
		-- return
	-- else

	if moneyCount > 0 then
		DEFAULT_CHAT_FRAME:AddMessage("xanUI: <"..itemCount.."> Total items vendored. ["..GetCoinTextureString(moneyCount).."]")
	end
	
	--do repairs
	if CanMerchantRepair() then
		local repairCost, canRepair = GetRepairAllCost()
		if canRepair and repairCost > 0 then
			if doGuildRepairs and CanGuildBankRepair() then
				local amount = GetGuildBankWithdrawMoney()
				local guildMoney = GetGuildBankMoney()
				if amount == -1 then
					amount = guildMoney
				else
					amount = min(amount, guildMoney)
				end
				if amount > repairCost then
					RepairAllItems(1)
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Repaired from Guild. ["..GetCoinTextureString(repairCost).."]")
					return
				else
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Insufficient guild funds to make repairs. ["..GetCoinTextureString(repairCost).."]")
				end
			elseif GetMoney() > repairCost then
				RepairAllItems()
				DEFAULT_CHAT_FRAME:AddMessage("xanUI: Repaired all items. ["..GetCoinTextureString(repairCost).."]")
				return
			else
				DEFAULT_CHAT_FRAME:AddMessage("xanUI: Insufficient funds to make repairs. ["..GetCoinTextureString(repairCost).."]")
			end
		end
	end
	
end

if MerchantFrame:IsVisible() then eventFrame:MERCHANT_SHOW() end
