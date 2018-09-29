local debugf = tekDebug and tekDebug:GetFrame("xanUI")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

--------------------
-- ICON SETTINGS

local AnchorPoint = 'RIGHT' -- Point of icon to anchor to nameplate (CENTER, LEFT, RIGHT, TOP, BOTTOM)
local RelativeTo = 'LEFT' -- Point of nameplate to anchor icon to (CENTER, LEFT, RIGHT, TOP, BOTTOM)
local OffsetX = 0 -- Horizontal offset for icon (from anchor point)
local OffsetY = 0 -- Vertical offset for icon
local IconScale = 1 -- Scale for icon

-- Uncomment these lines if you want to enable them, or set to 0 to turn them off
-- SetCVar('showQuestUnitCircles', 1) -- Enables subtle glow under quest mobs
-- SetCVar('UnitNameFriendlySpecialNPCName', 1) -- Show name for quest objectives, even out of range of nameplates

-- END OF SETTINGS
--------------------

local _, addon = ...
local E = addon:Eve()
SetCVar('showQuestTrackingTooltips', '1') -- Required for this addon to function, don't turn this off

local TextureAtlases = {
	['item'] = 'Banker', -- bag icon, you have to loot something for this quest
	--['monster'] = '', -- you must kill or interact with units for this quest
}

-- C_TaskQuest.GetQuestsForPlayerByMapID(GetCurrentMapAreaID())
local ActiveWorldQuests = {
	-- [questName] = questID ?
}

do
	function E:PLAYER_LOGIN()
		-- local areaID = GetCurrentMapAreaID()
		local uiMapID = C_Map.GetBestMapForUnit('player')
		if uiMapID then
			for k, task in pairs(C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID) or {}) do
				if task.inProgress then
					-- track active world quests
					local questID = task.questId
					local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
					if questName then
						-- print(k, questID, questName)
						ActiveWorldQuests[ questName ] = questID
					end
				end
			end
		end
	end

	function E:QUEST_ACCEPTED(questLogIndex, questID, ...)
		if IsQuestTask(questID) then
			-- print('TASK_QUEST_ACCEPTED', questID, questLogIndex, GetQuestLogTitle(questLogIndex))
			local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
			if questName then
				ActiveWorldQuests[ questName ] = questID
			end
		else
			-- print('QUEST_ACCEPTED', questID, questLogIndex, GetQuestLogTitle(questLogIndex))
		end
	end
	
	function E:QUEST_REMOVED(questID)
		local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
		if questName and ActiveWorldQuests[ questName ] then
			ActiveWorldQuests[ questName ] = nil
			-- print('TASK_QUEST_REMOVED', questID, questName)
			-- get task progress when it's updated to display on the nameplate
			-- C_TaskQuest.GetQuestProgressBarInfo
		end
	end
end

local OurName = UnitName('player')
local QuestPlateTooltip = CreateFrame('GameTooltip', 'QuestPlateTooltip', nil, 'GameTooltipTemplate')
QuestLogIndex = {} -- [questName] = questLogIndex, this is to "quickly" look up quests from its name in the tooltip

local function checkPartyShow(progressText, objectiveCount)

	if progressText then
		local x, y = strmatch(progressText, '(%d+)/(%d+)')
		if x and y then
			local numLeft = y - x
			if numLeft > objectiveCount then -- track highest number of objectives
				objectiveCount = numLeft
			end
		end
		if not x or (x and y and x ~= y) then
			return true, objectiveCount
		end
	end
	return false, objectiveCount
end

local function GetQuestProgress(unitID)
	--if not QuestPlatesEnabled or not name then return end
	--local guid = GUIDs[name]
	--local guid = unitID and UnitGUID(unitID)
	--if not guid then return end
	
	QuestPlateTooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')
	--QuestPlateTooltip:SetHyperlink('unit:' .. guid)
	QuestPlateTooltip:SetUnit(unitID)
	
	local progressGlob -- concatenated glob of quest text
	local questType -- 1 for player, 2 for group
	local isWorldQuest = false
	local objectiveCount = 0
	local questTexture -- if usable item
	local questLogIndex -- should generally be set, index usable with questlog functions
	local questID
	local stillShow = false
	
	for i = 3, QuestPlateTooltip:NumLines() do
		local str = _G['QuestPlateTooltipTextLeft' .. i]
		local text = str and str:GetText()
		if not text then return end
		questID = questID or ActiveWorldQuests[ text ]
		
		--(Name-Realm - 5/30 Quilboar Tusks) or (Name - 5/30 Quilboar Tusks)
		local playerName, progressText = strmatch(text, '\s?([^ ]-) ?%- (.+)$') -- nil or '' if 1 is missing but 2 is there
		local splitName, splitRealm = string.match(playerName or OurName, '^(.-) *%- *(.+)$') -- (Name-Realm)

		-- todo: if multiple entries are present, ONLY read the quest objectives for the player
		-- if a name is listed in the pattern then we must be in a group
		if splitName and string.len(splitName) > 0 and splitName ~= OurName then
			if not questType then
				questType = 2
			end
			if not stillShow then
				stillShow, objectiveCount = checkPartyShow(progressText, objectiveCount)
			end

		elseif playerName and string.len(playerName) > 0 and playerName ~= OurName then -- quest is for another group member
			if not questType then
				questType = 2
			end
			if not stillShow then
				stillShow, objectiveCount = checkPartyShow(progressText, objectiveCount)
			end

		else
			--it only enters here if we are a player.  if we are then it forces questType to 1 because of progressGlob down at the return
			if progressText then
				local x, y = strmatch(progressText, '(%d+)/(%d+)')
				if x and y then
					local numLeft = y - x
					if numLeft > objectiveCount then -- track highest number of objectives
						objectiveCount = numLeft
					end
				end

				--local x, y = strmatch(progressText, '(%d+)/(%d+)$')
				if not x or (x and y and x ~= y) then
					progressGlob = progressGlob and progressGlob .. '\n' .. progressText or progressText
				end
			else
				if ActiveWorldQuests[ text ] then

					local questID = ActiveWorldQuests[ text ]
					local progress = C_TaskQuest.GetQuestProgressBarInfo(questID)
					if progress then
						questType = 3 -- progress bar
						return text, questType, ceil(100 - progress), questID
					end
					--it's a world quest different color than standard quest
					if questID then
						local _, _, worldQuestType = GetQuestTagInfo(questID)
						if worldQuestType then
							isWorldQuest = true -- world quest
						end
					end
				else
					local index = QuestLogIndex[text]
					if index then
						questLogIndex = index
					end
				end
			end
		end
	end
	
	return progressGlob, progressGlob and 1 or questType, objectiveCount, questLogIndex, questID, isWorldQuest, stillShow
end

local QuestPlates = {} -- [plate] = f
function E:OnNewPlate(f, plate)
	local frame = CreateFrame('frame', nil, f)
	frame:Hide()
	frame:SetAllPoints(f)
	QuestPlates[plate] = frame
	
	local icon = frame:CreateTexture(nil, nil, nil, 0)
	icon:SetSize(28, 22)
	icon:SetTexture('Interface/QuestFrame/AutoQuest-Parts')
	icon:SetTexCoord(0.30273438, 0.41992188, 0.015625, 0.953125)
	icon:SetPoint(AnchorPoint, frame, RelativeTo, OffsetX / IconScale, OffsetY / IconScale)
	frame:SetScale(IconScale)
	frame.jellybean = icon
	
	local iconAlert = frame:CreateTexture(nil, "OVERLAY")
	iconAlert:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_1")
	iconAlert:SetSize(16, 32)
	iconAlert:SetPoint("BOTTOM", f, "TOP")
	frame.iconAlert = iconAlert
	
	local itemTexture = frame:CreateTexture(nil, nil, nil, 1)
	itemTexture:SetPoint('TOPRIGHT', icon, 'BOTTOMLEFT', 12, 12)
	itemTexture:SetSize(16, 16)
	itemTexture:SetMask('Interface/CharacterFrame/TempPortraitAlphaMask')
	itemTexture:Hide()
	frame.itemTexture = itemTexture
	
	-- Loot icon, display if mob needs to be looted for quest item
	local lootIcon = frame:CreateTexture(nil, nil, nil, 1)
	lootIcon:SetAtlas('Banker')
	lootIcon:SetSize(16, 16)
	lootIcon:SetPoint('TOPLEFT', icon, 'BOTTOMRIGHT', -12, 12)
	lootIcon:Hide()
	frame.lootIcon = lootIcon
	
	local iconText = frame:CreateFontString(nil, 'OVERLAY', 'SystemFont_Outline_Small')
	iconText:SetPoint('CENTER', icon, 0.8, 0)
	iconText:SetShadowOffset(1, -1)
	--iconText:SetText(math.random(22))
	iconText:SetTextColor(1,.82,0)
	frame.iconText = iconText
	
	-- todo: add setting for displaying quest text again
	local questText = frame:CreateFontString(nil, 'BACKGROUND', 'GameFontWhiteSmall')
	questText:SetPoint('TOP', frame, 'BOTTOM')
	questText:SetShadowOffset(1, -1)
	questText:Hide()
	frame.questText = questText
	
	local qmark = frame:CreateTexture(nil, 'OVERLAY')
	qmark:SetSize(28, 28)
	qmark:SetPoint('CENTER', icon)
	qmark:SetTexture('Interface/WorldMap/UI-WorldMap-QuestIcon')
	qmark:SetTexCoord(0, 0.56, 0.5, 1)
	qmark:SetAlpha(0)
	
	local duration = 1
	local group = qmark:CreateAnimationGroup()
	local alpha = group:CreateAnimation('Alpha')
	alpha:SetOrder(1)
	alpha:SetFromAlpha(0)
	alpha:SetToAlpha(1)
	alpha:SetDuration(0)
	
	local translation = group:CreateAnimation('Translation')
	translation:SetOrder(1)
	translation:SetOffset(0, 20)
	translation:SetDuration(duration)
	translation:SetSmoothing('OUT')
	
	local alpha2 = group:CreateAnimation('Alpha')
	alpha2:SetOrder(1)
	alpha2:SetFromAlpha(1)
	alpha2:SetToAlpha(0)
	alpha2:SetDuration(duration)
	alpha2:SetSmoothing('OUT')
	
	frame.ani = group
	
	frame:HookScript('OnShow', function(self)
		group:Play()
	end)
	
	--healthbar checker, sometimes the health bar doesn't update properly and the health values are incorrect
	--so check for this and update accordingly
	local function checkHealth(self)
		local unit
		if self._pFrame and self._pFrame._unitID then unit = self._pFrame._unitID end
		if self:GetParent() and self:GetParent().unit then
			if not unit or unit ~= self:GetParent().unit then unit = self:GetParent().unit end
		end
		if unit then
			local minVal, maxVal = self:GetMinMaxValues()
			local currVal = self:GetValue()
			local unitHealth = UnitHealth(unit)
			local unitHealthMax = UnitHealthMax(unit)
			
			if minVal and maxVal and unitHealthMax and maxVal ~= unitHealthMax then
				--Debug("updatedMinMax", unit, maxVal, unitHealthMax, UnitName(unit))
				self:GetMinMaxValues(minVal, unitHealthMax)
			end
			if currVal and unitHealth and currVal ~= unitHealth then
				--Debug("updatedHealth", unit, currVal, unitHealth, UnitName(unit))
				self:SetValue(unitHealth)
			end
			--Debug('health updated', "Unit", unit, "minVal", minVal, "maxVal", maxVal, "currVal", currVal, "unitHealth", unitHealth, "unitHealthMax", unitHealthMax)
		end
	end
	
	local framePlate = plate:GetChildren()
	
	if framePlate and framePlate.healthBar then
		--framePlate.castBar
		framePlate.healthBar._pFrame = f
		framePlate.healthBar:HookScript("OnShow", checkHealth)
		framePlate.healthBar:HookScript("OnHide", checkHealth)
		framePlate.healthBar:HookScript("OnValueChanged", checkHealth)
		framePlate.healthBar:HookScript("OnUpdate", checkHealth)
	end
	
end

local function UpdateQuestIcon(plate, unitID)
	local Q = QuestPlates[plate]
	local unitID = unitID or addon:GetUnitForPlate(plate)
	if not Q then return end
	
	local scenarioName, currentStage, numStages, flags, _, _, _, xp, money, scenarioType, _, textureKitID = C_Scenario.GetInfo()
	local inChallengeMode = (scenarioType == LE_SCENARIO_TYPE_CHALLENGE_MODE)
	if inChallengeMode then
		Q:Hide()
		return
	end
	
	local progressGlob, questType, objectiveCount, questLogIndex, questID, isWorldQuest, stillShow = GetQuestProgress(unitID)
	
	if progressGlob and questType ~= 2 then
		Q.questText:SetText(progressGlob or '')
		
		--if questType == 3 then -- todo: progress bar
		--	Q.iconText:SetText(objectiveCount > 0 and objectiveCount or '?')
		--else
			Q.iconText:SetText(objectiveCount > 0 and objectiveCount or '?')
		--end

		Q.iconAlert:SetVertexColor(1, 0.1, 0.1, 0.9) --default red
		Q.iconAlert:Show()
		
		if isWorldQuest then
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(0.2, 1, 1)
			Q.iconAlert:SetVertexColor(9/255, 218/255, 224/255, 0.9) --blueish tint
		elseif questType == 1 then
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(1, .82, 0)
			Q.iconAlert:SetVertexColor(0.9, 0.4, 0.04, 0.9) --show orange much nicer
		elseif questType == 3 then
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(0.2, 1, 1)
			Q.iconAlert:SetVertexColor(0.3, 0.3, 1, 0.9) --blue tint
		end
		
		Q.itemTexture:Hide()
		Q.lootIcon:Hide()
		
		if questLogIndex or questID then
			if questID then
				for i = 1, 10 do
					local text, objectiveType, finished = GetQuestObjectiveInfo(questID, i, false)
					if not text then break end
					if not finished and (objectiveType == 'item' or objectiveType == 'object') then
						Q.lootIcon:Show()
					end
				end
			else
				local _, _, _, _, _, _, _, questID = GetQuestLogTitle(questLogIndex)
				for i = 1, GetNumQuestLeaderBoards(questLogIndex) or 0 do
					local text, objectiveType, finished = GetQuestObjectiveInfo(questID, i, false)
					if not finished and (objectiveType == 'item' or objectiveType == 'object') then
						Q.lootIcon:Show()
					end
				end
			end
			
			if questLogIndex then
				local link, itemTexture, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
				if link and itemTexture then
					Q.itemTexture:SetTexture(itemTexture)
					Q.itemTexture:Show()
				else
					Q.itemTexture:Hide()
				end
			end
		end
		
		if not Q:IsVisible() then
			Q.ani:Stop()
			Q:Show()
			Q.ani:Play()
		end

	elseif questType == 2 and stillShow then
			
		Q.jellybean:SetDesaturated(true)
		Q.iconText:SetTextColor(71/255, 183/255, 23/255, 0.9)
		Q.iconAlert:SetVertexColor(71/255, 183/255, 23/255, 0.9) --green tint
		Q.iconAlert:Show()
		Q.itemTexture:Hide()
		Q.lootIcon:Hide()
		Q.iconText:SetText(objectiveCount > 0 and objectiveCount or 'P')
			
		if not Q:IsVisible() then
			Q.ani:Stop()
			Q:Show()
			Q.ani:Play()
		end

	else
		Q:Hide()
	end	
end

function E:OnPlateShow(f, plate, unitID)
	UpdateQuestIcon(plate, unitID)
end

QuestObjectiveStrings = {}
local function CacheQuestIndexes()
	wipe(QuestLogIndex)
	for i = 1, GetNumQuestLogEntries() do
		-- for i = 1, GetNumQuestLogEntries() do if not select(4,GetQuestLogTitle(i)) and select(11,GetQuestLogTitle(i)) then QuestLogPushQuest(i) end end
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(i)
		if not isHeader then
			QuestLogIndex[title] = i
			for objectiveID = 1, GetNumQuestLeaderBoards(i) or 0 do
				local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, objectiveID, false)
				if objectiveText then
					QuestObjectiveStrings[ title .. objectiveText ] = {questID, objectiveID}
				end
			end
		end
	end
	
	for plate, f in pairs(addon:GetActiveNameplates()) do
		UpdateQuestIcon(plate, f._unitID)
	end
end

function E:UNIT_QUEST_LOG_CHANGED(unitID)
	if unitID == 'player' then
		CacheQuestIndexes()
	end
	
	for plate in pairs(addon:GetActiveNameplates()) do
		UpdateQuestIcon(plate)
	end
end

function E:QUEST_LOG_UPDATE()
	CacheQuestIndexes()
end
E:UnregisterEvent('QUEST_LOG_UPDATE')

function E:PLAYER_LEAVING_WORLD()
	E:UnregisterEvent('QUEST_LOG_UPDATE')
end

function E:PLAYER_ENTERING_WORLD()
	E:RegisterEvent('QUEST_LOG_UPDATE')
end