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

--stop the stupid text from displaying on hover over
--blizzard changed this with WOD
-- hooksecurefunc("ShowTextStatusBarText", function(self)
	-- HideTextStatusBarText(self)
-- end)



----------------------------------------------------------------
---SUPRESS THE STUPID RIGHT CLICK TARGETTING!!@!!!@@#$$#@
----------------------------------------------------------------

--[[ DoubleClickDuration = 0.3
LastRightClick = 0
WorldFrame:HookScript("OnMouseUp", function(self, button)
	if (UnitAffectingCombat("player") and
			button == "RightButton" and
			LastRightClick + DoubleClickDuration < GetTime()) then
		LastRightClick = GetTime()
		MouselookStop()
	end
end) ]]


----------------------------------------------------------------
---ADD OPTION TO MAP TO HIDE TREASURES
----------------------------------------------------------------

local function click(self)
	local checked = self.checked
	PlaySound(checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
	ToggleTreasuresSettings = checked
	WorldMapFrame_Update()
end

hooksecurefunc("WorldMapTrackingOptionsDropDown_Initialize",function(self,level,menuList)
	if level==1 then
		-- if setting is nil (not defined) then define it to true to check by default
		if ToggleTreasuresSettings==nil then
			ToggleTreasuresSettings = true
		end
		-- add the "Show Treasures" option
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Show Treasures"
		info.func = click
		info.checked = ToggleTreasuresSettings and true
		info.isNotRadio = true
		info.keepShownOnClick = 1
		UIDropDownMenu_AddButton(info)
	end
end)
-- need to re-initialize to pick up our hooked version of the function
UIDropDownMenu_Initialize(WorldMapFrameDropDown, WorldMapTrackingOptionsDropDown_Initialize, "MENU")

-- the heart of the addon; if ToggleTreasuresSettings is unchecked, then hide all "197" POIs
hooksecurefunc("WorldMapFrame_Update",function()
	if not ToggleTreasuresSettings then
		for i=1,GetNumMapLandmarks() do
			if select(4,GetMapLandmarkInfo(i))==197 then
				_G["WorldMapFramePOI"..i]:Hide()
			end
		end
	end
end)


-- Always show missing transmogs in tooltips
C_TransmogCollection.SetShowMissingSourceInItemTooltips(true)

----------------------------------------------------------------
---ADD Missing stats to the character panel
----------------------------------------------------------------

--don't really want to show all stats but use this as a guideline
function xanUI_ShowAllStats()
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
end


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
	if not unit then return nil; end
	if not frame then return nil; end

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
	else
		if( UnitFactionGroup(unit) and UnitFactionGroup(unit):lower() ~= "neutral"	) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
	end

end

xanUI_CreateFactionIcon(TargetFrame);
xanUI_CreateFactionIcon(TargetFrameToT)

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

--double check the target castbar hasn't lost the tradeskill setting (another mod may change it)
hooksecurefunc("CastingBarFrame_OnEvent", function(self, event, ...)
	if self and self:GetName() == "TargetFrameSpellBar" then
		if TargetFrameSpellBar.showTradeSkills ~= enableTradeskills then
			TargetFrameSpellBar.showTradeSkills = enableTradeskills
		end
	end
end)


--[[------------------------
	This will fix the issues where the damn pet bar isn't showing up sometimes
--------------------------]]

-- local function checkPetBar()
	-- if not InCombatLockdown() and not PetActionBarFrame:IsVisible() and UnitExists("pet") and not UnitIsUnconscious("pet") then
		-- if not UnitInVehicle("player") or not UnitHasVehicleUI("player") then
			-- PetActionBarFrame:Show()
		-- end
	-- end
-- end



----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

hooksecurefunc('QuestInfo_Display', function(template, parentFrame, acceptButton, material, mapView)
	local elementsTable = template.elements
	for i = 1, #elementsTable, 3 do
		if elementsTable[i] == QuestInfo_ShowTitle then
			if QuestInfoFrame.questLog then
				local questLogIndex = GetQuestLogSelection()
				local level = select(2, GetQuestLogTitle(questLogIndex))
				local newTitle = "["..level.."] "..QuestInfoTitleHeader:GetText()
				QuestInfoTitleHeader:SetText(newTitle)
			end
		end
	end
end)

hooksecurefunc("QuestLogQuests_Update", function(self, pIndex)
	local numEntries, numQuests = GetNumQuestLogEntries()
	local headerCollapsed = false
	local titleIndex = 0
	for questLogIndex = 1, numEntries do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(questLogIndex)
		if ( isHeader ) then
			headerCollapsed = isCollapsed
		elseif not isTask and (not isBounty or IsQuestComplete(questID)) and not headerCollapsed then
			titleIndex = titleIndex + 1
			local button = QuestLogQuests_GetTitleButton(titleIndex)
			local oldBlockHeight = button:GetHeight()
			local oldHeight = button.Text:GetStringHeight()
			local newTitle = "["..level.."] "..button.Text:GetText()
			button.Text:SetText(newTitle)
			local newHeight = button.Text:GetStringHeight()
			button:SetHeight(oldBlockHeight + newHeight - oldHeight)
		end
	end
end)

hooksecurefunc("GossipFrameUpdate", function(self)
	local buttonIndex = 1

	local availableQuests = {GetGossipAvailableQuests()}
	local numAvailableQuests = table.getn(availableQuests)
	for i=1, numAvailableQuests, 7 do
		local titleButton = _G["GossipTitleButton" .. buttonIndex]
		local title = ""
		if tonumber(availableQuests[i+1]) >= 0 then
			title = "["..availableQuests[i+1].."] "..availableQuests[i]
		else
			title = availableQuests[i]
		end
		local isTrivial = availableQuests[i+2]
		if isTrivial then
			titleButton:SetFormattedText(TRIVIAL_QUEST_DISPLAY, title)
		else
			titleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, title)
		end
		GossipResize(titleButton)
		buttonIndex = buttonIndex + 1
	end
	if numAvailableQuests > 1 then
		buttonIndex = buttonIndex + 1
	end

	local activeQuests = {GetGossipActiveQuests()}
	local numActiveQuests = table.getn(activeQuests)
	for i=1, numActiveQuests, 6 do
		local titleButton = _G["GossipTitleButton" .. buttonIndex]
		local title = ""
		if tonumber(activeQuests[i+1]) >= 0 then
			title = "["..activeQuests[i+1].."] "..activeQuests[i]
		else
			title = activeQuests[i]
		end
		local isTrivial = activeQuests[i+2]
		if isTrivial then
			titleButton:SetFormattedText(TRIVIAL_QUEST_DISPLAY, title)
		else
			titleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, title)
		end
		GossipResize(titleButton)
		buttonIndex = buttonIndex + 1
	end
end)

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
---Movable Pet Healthbar
----------------------------------------------------------------

local function getBarColor(hcur, hmax)
	local r
	local g = 1
	local cur = 2 * hcur/hmax
	if cur > 1 then
		return 2 - cur, 1, 0
	else
		return 1, cur, 0
	end
end

local function setPetBarHealth(bar)
	local hcur, hmax = UnitHealth(bar.unit), UnitHealthMax(bar.unit)
	local hper = 0
	if hmax > 0 then hper = hcur/hmax end
	bar:SetValue(hper)
	bar.percentfont:SetText(ceil(hper * 100).."%")
	bar:SetStatusBarColor(getBarColor(hcur, hmax))
end

local function OnUnitHealthFrequent(bar)
	if UnitIsDead("pet") or not UnitExists("pet") then bar:Hide() return end
	if not UnitIsDead("pet") and InCombatLockdown() and UnitExists("pet") then bar:Show() end
	
	setPetBarHealth(bar)
end

local function onUnitEvent(self, event, ...)
	local arg1 = ...
	local unit = self.unit

	if ( arg1 == unit ) then
		if ( event == "UNIT_HEALTH_FREQUENT" ) then
			OnUnitHealthFrequent(self)
		elseif ( event == "UNIT_COMBAT" or event == "UNIT_PET" or event == "UNIT_PORTRAIT_UPDATE" or event == "PET_DISMISS_START") then
			if UnitIsDead("pet") or not UnitExists("pet") or event == "PET_DISMISS_START" then self:Hide() end
		end
	end
end

 
function XanUI_CreatePetBar()


	local bar = CreateFrame("StatusBar","XanUIPetHealthBar", UIParent)
	bar.unit = "pet"
	bar:SetSize(100,10)
	--bar.barSpark:Hide()
	--bar.barFlash:Hide()
	bar:SetPoint("CENTER",0,0)
	bar:SetMinMaxValues(0, 1)
	bar:SetStatusBarTexture("Interface\\AddOns\\xanUI\\media\\Minimalist")
	bar:SetStatusBarColor(0,1,0)
	--bar:SetOrientation("VERTICAL")
	bar:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", bar.unit)
	bar:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	bar:RegisterEvent("PET_DISMISS_START")
	bar:RegisterEvent("UNIT_PET")
	bar:RegisterEvent("UNIT_COMBAT")

	bar:SetScript("OnEvent", onUnitEvent)

	bar:SetMovable(true)
	bar:SetScript("OnMouseDown",bar.StartMoving)
	bar:SetScript("OnMouseUp", function() 
		bar:StopMovingOrSizing()
		XanUI_SaveLayout("XanUIPetHealthBar")
	end)
	
	local fontstr = bar:CreateFontString("XanUIPetHealthBarPercent", "OVERLAY")
	fontstr:SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
	fontstr:SetPoint("RIGHT", bar, "LEFT", 0, 0)
	bar.percentfont = fontstr
							
	bar:Hide()
	
	local incombat = false
	local holder = CreateFrame("Frame")
	holder:RegisterEvent("PLAYER_REGEN_ENABLED")
	holder:RegisterEvent("PLAYER_REGEN_DISABLED")
	holder:RegisterEvent("UNIT_PET")
	holder:RegisterEvent("COMBAT_LOG_EVENT")
	holder:SetScript("OnEvent", function(self, event)
		incombat = (event=="PLAYER_REGEN_DISABLED")

		if not UnitIsDead("pet") and incombat and UnitExists("pet") then
			setPetBarHealth(bar)
			bar:Show()
		elseif not UnitIsDead("pet") and InCombatLockdown() and UnitExists("pet") then
			--this is just a catch all in case player-regen doesn't show the frame for some stupid reason
			setPetBarHealth(bar)
			bar:Show()
		else
			bar:Hide()
		end

		if event=="UNIT_PET" then
			if UnitIsDead("pet") or not UnitExists("pet") then bar:Hide() end
		end

	end)
	
end

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

local eventFrame = CreateFrame("frame","xanUIEventFrame",UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_TARGET")

--we need to fix a problem where sometimes the pet bar isn't showing up!
-- eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
-- eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
-- eventFrame:RegisterEvent("PET_BAR_UPDATE")
-- eventFrame:RegisterEvent("UNIT_PET")
-- eventFrame:RegisterEvent("UNIT_AURA")
-- eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
-- eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
-- eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
-- eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
-- eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")


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
	
	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [v|cFFDF2B2B"..ver.."|r]   /xanui, /xui")

	--xanUI_UpdateRaidLocks()
	
	--create the castbars
	-- if XSpellBar then
		-- for i = 1,4 do
			-- XSpellBar:New(getglobal("PartyMemberFrame"..i))
		-- end
	-- end 

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
	
	
	--only do the pet bar for WARLOCK right now
	if select(2, UnitClass("player")) == "WARLOCK" then
		XanUI_CreatePetBar()
	end
	
	--restore petbar if it exists
	if _G["XanUIPetHealthBar"] then
		XanUI_RestoreLayout("XanUIPetHealthBar")
	end
	
	
	--fix an issue with shamans and the stupid overlay that keeps showing up for fulminate on reload
	--for spellID, overlayList in pairs(SpellActivationOverlayFrame.overlaysInUse) do
	--	print(spellID)
	--end
	if select(2, UnitClass("player")) == "SHAMAN" then
		SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, 190494) --fulminate
		eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	else
		eventFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	end
	
	eventFrame:UnregisterEvent("PLAYER_LOGIN")
end

function eventFrame:ACTIVE_TALENT_GROUP_CHANGED()
	if select(2, UnitClass("player")) == "SHAMAN" then
		SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, 190494) --fulminate
		--201846
	end
end

-- local upt_throt  = 0

-- eventFrame:HookScript("OnUpdate", function(self, elapsed)
	--do some throttling
	-- upt_throt = upt_throt + elapsed
	-- if upt_throt < 3 then return end
	-- upt_throt = 0
			
	--because hunters start off with a fake pet that they really can't dismiss or control, we can ignore the pet show function
	--until they learn tame pet
	-- if select(2, UnitClass("player")) == "HUNTER" then
		--check for tame pet
		-- if IsSpellKnown(1515) then
			-- checkPetBar()
		-- end
	-- else
		-- checkPetBar()
	-- end
	
-- end)

function eventFrame:PLAYER_TARGET_CHANGED()
	xanUI_UpdateFactionIcon("target", TargetFrame)
end

function eventFrame:UNIT_TARGET(self, unitid)
	--update target of target because PLAYER_TARGET_CHANGED doesn't always work
	if UnitExists("targettarget") then
		xanUI_UpdateFactionIcon("targettarget", TargetFrameToT)
	end
	
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

local function colorMoneyText(value)
	if not value then return "" end
	local gold = abs(value / 10000)
	local silver = abs(mod(value / 100, 100))
	local copper = abs(mod(value, 100))
	
	local GOLD_ABRV = "g"
	local SILVER_ABRV = "s"
	local COPPER_ABRV = "c"
	
	local WHITE = "ffffff"
	local COLOR_COPPER = "eda55f"
	local COLOR_SILVER = "c7c7cf"
	local COLOR_GOLD = "ffd700"

	if value >= 10000 or value <= -10000 then
		return format("|cff%s%d|r|cff%s%s|r |cff%s%d|r|cff%s%s|r |cff%s%d|r|cff%s%s|r", WHITE, gold, COLOR_GOLD, GOLD_ABRV, WHITE, silver, COLOR_SILVER, SILVER_ABRV, WHITE, copper, COLOR_COPPER, COPPER_ABRV)
	elseif value >= 100 or value <= -100 then
		return format("|cff%s%d|r|cff%s%s|r |cff%s%d|r|cff%s%s|r", WHITE, silver, COLOR_SILVER, SILVER_ABRV, WHITE, copper, COLOR_COPPER, COPPER_ABRV)
	else
		return format("|cff%s%d|r|cff%s%s|r", WHITE, copper, COLOR_COPPER, COPPER_ABRV)
	end
end

function eventFrame:MERCHANT_SHOW()
	
	local moneyCount = 0
	local itemCount = 0
	
	for bag = 0,4 do
		for slot = 1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and select(3, GetItemInfo(link)) == 0 then
				
				local value = select(11, GetItemInfo(link))
				
				if value > 0 then
					moneyCount = moneyCount + value
					PickupContainerItem(bag, slot)
					PickupMerchantItem()
					itemCount = itemCount + 1
				end
				
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
		DEFAULT_CHAT_FRAME:AddMessage("xanUI: <"..itemCount.."> Total items vendored. ["..colorMoneyText(moneyCount).."]")
	end
end

if MerchantFrame:IsVisible() then eventFrame:MERCHANT_SHOW() end

------------------------------------------------
------------------------------------------------
------------------------------------------------

-- function eventFrame:PARTY_MEMBERS_CHANGED()
	-- xanUI_UpdateRaidPositions()
	-- checkPetBar()
-- end

-- function eventFrame:PLAYER_ENTERING_WORLD()
	-- xanUI_UpdateRaidPositions()
	-- checkPetBar()
-- end


-- function eventFrame:PET_BAR_UPDATE()
	-- checkPetBar()
-- end

-- function eventFrame:UNIT_PET(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:UNIT_AURA(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:UNIT_SPELLCAST_START(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:UNIT_SPELLCAST_STOP(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:UNIT_SPELLCAST_SUCCEEDED(event, unitID)
	-- if (unitID and unitID == "player") then
		-- checkPetBar()
	-- end
-- end

-- function eventFrame:PLAYER_REGEN_DISABLED()
	-- checkPetBar()
-- end

-- function eventFrame:PLAYER_REGEN_ENABLED()
	-- checkPetBar()
-- end
