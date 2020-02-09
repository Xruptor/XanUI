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
		
		DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [|cFF20ff20QuestPlates Loaded|r]")
	end

	function E:QUEST_ACCEPTED(qlIndex, questID, ...)
		if IsQuestTask(questID) then
			-- print('TASK_QUEST_ACCEPTED', questID, qlIndex, GetQuestLogTitle(qlIndex))
			local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
			if questName then
				ActiveWorldQuests[ questName ] = questID
			end
		else
			-- print('QUEST_ACCEPTED', questID, qlIndex, GetQuestLogTitle(qlIndex))
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
QuestLogIndex = {}

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

local function isQuestComplete(qIndex, questID)
	if qIndex then
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete = GetQuestLogTitle(qIndex)
		if ( isComplete and isComplete > 0 ) then
			return true
		end
	end
	if questID then
		if IsQuestComplete(questID) or C_QuestLog.IsQuestFlaggedCompleted(questID) then
			return true
		end
	end
end

local function tobool(obj)
	if obj == nil then return false end
	if tonumber(obj) and tonumber(obj) == 0 then
		return false
	elseif tonumber(obj) and tonumber(obj) == 1 then
		return true
	end
	return obj
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
	local stillShow = false
	local questIDList = {}
	local qlIndex
	local questID
	local lastIndex
	
--old is for i=3
	for i = 2, QuestPlateTooltip:NumLines() do
		local str = _G['QuestPlateTooltipTextLeft' .. i]
		local text = str and str:GetText()
		if not text then return end
		
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
		--Debug("t1", "inside", playerName, progressText, splitName, splitRealm)
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
					local qID = ActiveWorldQuests[ text ]
					--Debug("Active Quest", qID, text)
					local progress = C_TaskQuest.GetQuestProgressBarInfo(qID)
					if progress then
						questType = 3 -- progress bar
						return text, questType, ceil(100 - progress), nil, qID
					end
					--it's a world quest different color than standard quest
					if qID then
						local _, _, worldQuestType = GetQuestTagInfo(qID)
						if worldQuestType then
							isWorldQuest = true -- world quest
							--Debug("world quest", text, qID)
						end
					end
				else

					local progressSwitch = false
					
					if text ~= nil then
			
						local x, y = strmatch(text, '(%d+)/(%d+)')
						if x and y and tonumber(x) and tonumber(y) then
							local numLeft = y - x
							if numLeft > objectiveCount then -- track highest number of objectives
								objectiveCount = numLeft
							end
							--if objectiveCount > 0 then
								progressGlob = progressGlob and progressGlob .. '\n' .. text or text
								progressSwitch = true
							--end
						end
						--string based comparison for x and y
						if not progressSwitch then
							if x and y and x ~= y then
								progressGlob = progressGlob and progressGlob .. '\n' .. text or text
							end
						end
					end
				end
				
			end
		end
		
		local qIndexChk
		local qQuestIDChk				
		local isComplete
		
		local data = QuestLogIndex[text]
		--if not by quest title try the objectives
		if not data then data = QuestObjectiveStrings[text] end
		
		if data then
			if data.qlIndex then
				qIndexChk = data.qlIndex
			end
			if data.questID then
				qQuestIDChk = data.questID
			end
			if data.isComplete then
				isComplete = tobool(data.isComplete)
			end
		end

		--only insert the questID once if found, we don't need to add for each objective
		if lastIndex ~= qIndexChk and qIndexChk and qQuestIDChk then
			if isComplete == nil then
				isComplete = isQuestComplete(qIndexChk, qQuestIDChk) or false
			end
			table.insert(questIDList, {name = text, qlIndex = qIndexChk, questID = qQuestIDChk, isComplete = isComplete} )
			lastIndex = qIndexChk
		end
			
	end
	
	--check to see if the quest is complete, if so then we can avoid putting alerts on the nameplate
	local markCompleted = false
	
	--sort table so false is last, that way the last thing that is marked is false.  If everything is true then the last thing will be marked true
	--this is because there aren't any more false
	if questIDList and #questIDList > 0 then
		table.sort(questIDList, function(a, b) return a.isComplete and not b.isComplete end)
		
		for i = 1, #questIDList do
			qlIndex = questIDList[i].qlIndex
			questID = questIDList[i].questID
			markCompleted = questIDList[i].isComplete
		end
	else
		--nothing to show
		markCompleted = true
	end
	
	--sometimes we have a questid and such but no glob and the quest isn't complete, so lets force it
	if not progressGlob and not markCompleted then
		if qlIndex or questID then
			questType = 5 --show grey exclamation mark since we don't fully know if it's a legit mob to mark (sort of a failsafe)
			progressGlob = "Unknown Quest Obj"
		end
	end

	--Debug(progressGlob, progressGlob and 1 or questType, objectiveCount, qlIndex, questID, isWorldQuest, stillShow, isComplete)
	return progressGlob, questType or progressGlob and 1, objectiveCount, qlIndex, questID, isWorldQuest, stillShow, markCompleted
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
		if not CanAccessObject(self) then return end
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
		if not CanAccessObject(framePlate.healthBar) then return end
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
	
	local progressGlob, questType, objectiveCount, qlIndex, questID, isWorldQuest, stillShow, isComplete = GetQuestProgress(unitID)

	if isComplete then
		Q:Hide()
		return
	end

	if progressGlob and questType ~= 2 then
		Q.questText:SetText(progressGlob or '')

		local objText = objectiveCount > 0 and objectiveCount or '?'
		
		Q.iconText:SetText(objText)
		Q.iconAlert:SetVertexColor(1, 0.1, 0.1, 0.9) --default red
		Q.iconAlert:Show()
		
		--if it's not a power world quest but it's still a world quest
		if questType ~= 3 and isWorldQuest then
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(0.2, 1, 1)
			Q.iconAlert:SetVertexColor(9/255, 218/255, 224/255, 0.9) --blueish tint
		elseif questType == 1 then
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(1, .82, 0)
			Q.iconAlert:SetVertexColor(0.9, 0.4, 0.04, 0.9) --show orange much nicer
		elseif questType == 3 then
			--its a power gain type world quest
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(0.2, 1, 1)
			Q.iconAlert:SetVertexColor(0.3, 0.3, 1, 0.9) --blue tint
		elseif questType == 5 then
			--this quest failed all other regular quest checks but still has some data, possibly due to an objective.
			--the quest is obviously not completed so lets show a gray marker
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(1, .82, 0)
			Q.iconAlert:SetVertexColor(119/255, 136/255, 153/255, 0.9) --slate gray tint
		end
		
		Q.itemTexture:Hide()
		Q.lootIcon:Hide()
		Q.jellybean:Hide()
		Q.iconText:Hide()
		
		--make sure we have a questID to work with
		if qlIndex and not questID then
			local xName, _, _, _, _, _, _, xQuestID = GetQuestLogTitle(qlIndex)
			if xQuestID then questID = xQuestID end
		end

		if questID then
			local finishedObj = true
			
			--don't use GetNumQuestLeaderBoards, it sometimes fails and returns 0, just use a huge number and break on nil
			--I highly doubt there will ever be 50 objectives for a quest
			for i = 1, 50 do
				local text, objectiveType, finished = GetQuestObjectiveInfo(questID, i, false)
				if not text then break end
				
				if not finished and (objectiveType == 'item' or objectiveType == 'object') then
					Q.lootIcon:Show()
				end

				--check to see if the text matches our progress, that means it was only one objective
				if progressGlob == text and not finished then
					finishedObj = false
					break
				--check to see if ANY of our objective text is in our progressGlob
				elseif string.find(progressGlob, text) and not finished then
					finishedObj = false
					break
				--sometimes we have optional objectives that aren't covered, lets give it a special color
				elseif string.find(text, "(Optional)") and not finished then
					finishedObj = false
					Q.iconAlert:SetVertexColor(77/255, 216/255, 39/255, 0.9) --give it a fel green color for optional
					break
				--check for special cases of progressbar quests
				elseif not finished and objectiveType == 'progressbar' then
					finishedObj = false
					--some type of world quest or quest with progress that has a weirdo quest objective text
					--since it's not finished, just show it anyways
					break
				--check for special world quest cases of progressbar quests
				elseif not finished and questType == 3 then
					finishedObj = false
					--with the progressbar quest types since we can't really grab the missing objective and just return the quest title
					--this will always fail the objective text check.  In these scenarios, lets see if we are not done in any objective.
					--if we aren't then show it anyways
					break
				--something we are missing, so show it anyways if it's not finished
				elseif not finished then
					finishedObj = false
					--this is a catch all that we must have forgotten SOMETHING with this quest.
					--in this case lets show the bogus weird color for the objective
					Q.iconAlert:SetVertexColor(119/255, 136/255, 153/255, 0.9) --slate gray tint
					break
				end
			end

			--all objectives complete so lets just hide it
			if finishedObj then
				Q:Hide()
				return
			end
			
			--only do this if we have a questIndex
			if qlIndex then
				local link, itemTexture, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(qlIndex)
				if link and itemTexture then
					Q.itemTexture:SetTexture(itemTexture)
					Q.itemTexture:Show()
				else
					Q.itemTexture:Hide()
				end
			end
		end
		
		--if we don't exactly have an objective count, don't show the jellybean
		if objText ~= '?' then
			Q.jellybean:Show()
			Q.iconText:Show()
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
		Q.jellybean:Hide()
		Q.iconText:Hide()
		
		local objText = objectiveCount > 0 and objectiveCount or 'P'
		
		Q.iconText:SetText(objText)
			
		--if we don't exactly have an objective count, don't show the jellybean
		if objText ~= 'P' then
			Q.jellybean:Show()
			Q.iconText:Show()
		end
		
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
			QuestLogIndex[title] = {qlIndex = i, questID = questID, isComplete = isComplete}
			--I highly doubt there will ever be 50 objectives for a quest, just break on no description
			for q = 1, 50 do
				local description, objectiveType, isCompleted = GetQuestLogLeaderBoard(q, i)
				if not description then break end
				--local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, objectiveID, false)
				QuestObjectiveStrings[description] = {qlIndex = i, questID = questID, isComplete = isCompleted, objID = q}
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