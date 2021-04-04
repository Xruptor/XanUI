local debugf = tekDebug and tekDebug:GetFrame("xanUI")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
--don't run this if it's not retail
if not IsRetail then return end

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

local function doQuestCheck()
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

local Races={}; do--	Races/Genders
	local TexturePath,TextureWidth,TextureHeight,IconSize,RaceGrid;
	if IsRetail then
		local path,width,height,size="Interface\\Glues\\CharacterCreate\\CharacterCreateIcons",2048,1024,66;

--		|Tpath:size1:size2:xoffset:yoffset:dimx:dimy:coordx1:coordx2:coordy1:coordy2|t
		for race,data in pairs({
--			Race			Male, Female
			Human			={{1762,0},{1696,0}};
			Orc			={{1040,790},{1040,724}};
			Dwarf			={{910,910},{780,910}};
			NightElf		={{1040,658},{1040,592}};
			Scourge			={{1106,460},{1106,394}};
			Tauren			={{1106,196},{1106,130}};
			Gnome			={{1366,0},{1300,0}};
			Troll			={{1106,328},{1106,262}};
			Goblin			={{1498,0},{1432,0}};
			BloodElf		={{130,910},{0,910}};
			Draenei			={{650,910},{520,910}};
			Worgen			={{1106,856},{1106,790}};
			Pandaren		={{1040,922},{1040,856}};
			Nightborne		={{1040,526},{1040,460}};
			HighmountainTauren	={{1630,0},{1564,0}};
			VoidElf			={{1106,592},{1106,526}};
			LightforgedDraenei	={{1040,130},{1960,0}};
			ZandalariTroll		={{1172,130},{1106,922}};
			KulTiran		={{1894,0},{1828,0}};
			DarkIronDwarf		={{390,910},{260,910}};
			Vulpera			={{1106,724},{1106,658}};
			MagharOrc		={{1040,262},{1040,196}};
			Mechagnome		={{1040,394},{1040,328}};
		}) do for index,pos in ipairs(data) do
--			Gender from GetPlayerInfoByGUID() is 2/3
			Races[race..(index+1)]={
				path=path,
				width=width,
				height=height,
				coord_x1=pos[1],
				coord_x2=pos[1]+size,
				coord_y1=pos[2],
				coord_y2=pos[2]+size
			}
		end end
	else
		local path,width,height,size="Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races",256,256,64;

--		|Tpath:size1:size2:xoffset:yoffset:dimx:dimy:coordx1:coordx2:coordy1:coordy2|t
		for race,data in pairs({
--			Race			Male, Female
			Human			={{0,0},{0,2}};
			Orc			={{3,1},{3,3}};
			Dwarf			={{1,0},{1,2}};
			NightElf		={{3,0},{3,2}};
			Scourge			={{1,1},{1,3}};
			Tauren			={{0,1},{0,3}};
			Gnome			={{2,0},{2,2}};
			Troll			={{2,1},{2,3}};
		}) do for index,pos in ipairs(data) do
--			Gender from GetPlayerInfoByGUID() is 2/3
			Races[race..(index+1)]={
				path=path,
				width=width,
				height=height,
				coord_x1=pos[1]*size,
				coord_x2=(pos[1]+1)*size,
				coord_y1=pos[2]*size,
				coord_y2=(pos[2]+1)*size
			}
		end end
	end
end

do
	function E:PLAYER_LOGIN()
		E:CacheQuestIndexes()
		DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [|cFF20ff20QuestPlates Loaded|r]")
	end
	
	--this is if the world frame was refreshed or the user did a /reload etc..
	function addon:UI_SCALE_CHANGED()
		E:CacheQuestIndexes()
	end

	function E:QUEST_ACCEPTED(questID, ...)
		if C_QuestLog.IsQuestTask(questID) then

			local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
			if questName then
				ActiveWorldQuests[ questName ] = questID
			end
		else
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
QuestObjectiveStrings = {}
QuestObjectiveCount = 0

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
		local questInfo = C_QuestLog.GetInfo(qIndex)
		if questInfo and C_QuestLog.IsComplete(questInfo.questID) then
			return true
		end
	end
	if questID then
		if C_QuestLog.IsComplete(questID) or C_QuestLog.IsQuestFlaggedCompleted(questID) then
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

local function CanAccessObject(obj)
	return issecure() or not obj:IsForbidden();
end

local function isObjSafe(obj)
	local inInstance, instanceType = IsInInstance()
	if inInstance then return false end --you can't modify plates while in instances, it will cause errors and taint issues.
	if not CanAccessObject(obj) then return false end --check if you can even touch the plate
	return true
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
	local globCount = 0
	local questType -- 1 for player, 2 for group
	local isWorldQuest = false
	local objectiveCount = 0
	local questTexture -- if usable item
	local stillShow = false
	local questIDList = {}
	local qlIndex
	local questID
	local lastIndex
	local lastQuestID
	local questText
	
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
					globCount = globCount + 1
				end
			else
				if ActiveWorldQuests[ text ] then
					local qID = ActiveWorldQuests[ text ]
					
					--it's a world quest different color than standard quest
					if qID then
						local _, _, worldQuestType = C_QuestLog.GetQuestTagInfo(qID)
						if worldQuestType then
							isWorldQuest = true -- world quest
							--Debug("world quest", text, qID)
						end
					end
					
					local progress = C_TaskQuest.GetQuestProgressBarInfo(qID)
					if progress then
						--it's a world quest
						if isWorldQuest then
							questType = 3 -- progress bar, do world quest color
							return text, questType, ceil(100 - progress), nil, qID
						else
							--it's not a world quest, it's probably a "Bonus Objectives" quest for the zone
							questType = 4 -- progress bar (special case)
							return text, questType, ceil(100 - progress), nil, qID
						end
					end

				else

					local progressSwitch = false
					
					local x, y = strmatch(text, '(%d+)/(%d+)')
					if x and y and tonumber(x) and tonumber(y) then
						local numLeft = y - x
						if numLeft > objectiveCount then -- track highest number of objectives
							objectiveCount = numLeft
						end
						--if objectiveCount > 0 then
							progressGlob = progressGlob and progressGlob .. '\n' .. text or text
							globCount = globCount + 1
							progressSwitch = true
						--end
					end
					--string based comparison for x and y
					if not progressSwitch then
						if x and y and x ~= y then
							progressGlob = progressGlob and progressGlob .. '\n' .. text or text
							globCount = globCount + 1
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
		if (lastQuestID ~= qQuestIDChk or lastIndex ~= qIndexChk) and qIndexChk and qQuestIDChk then
			if isComplete == nil then
				isComplete = isQuestComplete(qIndexChk, qQuestIDChk) or false
			end
			table.insert(questIDList, {name = text, qlIndex = qIndexChk, questID = qQuestIDChk, isComplete = isComplete} )
			lastIndex = qIndexChk
			lastQuestID = qQuestIDChk
		end
	
	end
	
	--check to see if the quest is complete, if so then we can avoid putting alerts on the nameplate
	local markCompleted = false
	
	--sort table so false is last, that way the last thing that is marked is false.  If everything is true then the last thing will be marked true
	--this is because there aren't any more false
	if questIDList and #questIDList > 0 then
		table.sort(questIDList, function(a, b) return a.isComplete and not b.isComplete end)
		
		for i = 1, #questIDList do
			questText = questIDList[i].name
			qlIndex = questIDList[i].qlIndex
			questID = questIDList[i].questID
			markCompleted = questIDList[i].isComplete
			--Debug(questIDList[i].name, qlIndex, questID, markCompleted)
		end
	else
		--nothing to show
		markCompleted = true
	end
	
	------
	--btw we check for questType so not to overwrite the PARTY questType of 2 or any other assigned questType already
	------
	
	--Debug('initial', questText, progressGlob, questType, qlIndex, questID)
	
	--check for bonus objectives that aren't classified as a world quest, technically it will not pickup the progressglob above as it would fail
	--it would fail because it's a progress one and not a collection one like 1/10
	if questID and not markCompleted and not questType then
		--check for bonus objectives that aren't classified as a world quest
		local progress = C_TaskQuest.GetQuestProgressBarInfo(questID)
		if progress then
			--it's not a world quest, it's probably a "Bonus Objectives" quest for the zone
			questType = 4 -- progress bar (special case)
			return questText, questType, ceil(100 - progress), nil, questID
		end
	end
	
	--sometimes we have a questid and such but no glob and the quest isn't complete, so lets force it
	if not progressGlob and not markCompleted and not questType then
		if qlIndex or questID then
			questType = 5 --show rose color exclamation mark since we don't fully know if it's a legit mob to mark (sort of a failsafe)
			--we HAVE to put something in progressGlob for it to even pass checks further down
			progressGlob = "Unknown or Invalid Quest"
			globCount = globCount + 1
		end
	end

	--if we get to this point and we have a progressglob and it's not completed, then it's just a regular quest.  So mark it as 1
	if progressGlob and string.len(progressGlob) > 1 and not questType then
		--its a regular quest, just mark it as 1
		questType = 1
	end
	
	--FOR SCENARIOS
	--Blizzard_ScenarioObjectiveTracker.lua
	--------------------------------------
	-- local stageName, stageDescription, numCriteria, _, _, _, _, numSpells, spellInfo, weightedProgress, _, widgetSetID = C_Scenario.GetStepInfo();
	-- local inChallengeMode = (scenarioType == LE_SCENARIO_TYPE_CHALLENGE_MODE);
	-- local inProvingGrounds = (scenarioType == LE_SCENARIO_TYPE_PROVING_GROUNDS);
	-- local dungeonDisplay = (scenarioType == LE_SCENARIO_TYPE_USE_DUNGEON_DISPLAY);
	-- local inWarfront = (scenarioType == LE_SCENARIO_TYPE_WARFRONT);
	-- local scenariocompleted = currentStage > numStages;
	
	-- for criteriaIndex = 1, numCriteria do
		-- local criteriaString, criteriaType, completed, quantity, totalQuantity, flags, assetID, quantityString, criteriaID, duration, elapsed, _, isWeightedProgress = C_Scenario.GetCriteriaInfo(criteriaIndex);
		
	-- function ScenarioTrackerProgressBar_GetProgress(self)
		-- if (self.criteriaIndex) then
			-- return select(4, C_Scenario.GetCriteriaInfo(self.criteriaIndex)) or 0;
		-- else
			-- return select(10, C_Scenario.GetStepInfo()) or 0;
		-- end
	-- end
	--------------------------------------
	
	--Debug(UnitName(unitID), questText, progressGlob, questType, objectiveCount, qlIndex, questID, isWorldQuest, stillShow, isComplete)
	return progressGlob, questType, objectiveCount, qlIndex, questID, isWorldQuest, stillShow, markCompleted, globCount
end

local QuestPlates = {} -- [plate] = f

local function doRaceIcon(plate)
	local Q = QuestPlates[plate]
	local unitID = unitID or addon:GetUnitForPlate(plate)
	if not Q then return false end
	
	--check if we show race
	if XanUIDB and XanUIDB.showRace then
		local raceName, raceFile, raceID = UnitRace(unitID) 
		local gender = UnitSex(unitID)
		
		if raceFile and gender and UnitIsPlayer(unitID) then
		
			local race = Races[raceFile..gender]
			
			if race then
				Q.iconFrame.iconRace:SetTexCoord(race.coord_x1/race.width, race.coord_x2/race.width, race.coord_y1/race.height, race.coord_y2/race.height)
				Q.iconFrame:Show()
				return true
			end
		end
	end
	
	Q.iconFrame:Hide()
	return false
end

function E:OnNewPlate(f, plate)
	
	--if a plate is restricted and cannot be used, lets avoid taints and errors
	if not isObjSafe(plate) then return end
	
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
	
	local iconFrame = CreateFrame('frame', nil, f)
	iconFrame:Hide()
	iconFrame:SetAllPoints(f)
	frame.iconFrame = iconFrame
	
	local iconRace = iconFrame:CreateTexture(nil, "OVERLAY")
	iconRace:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreateIcons")
	iconRace:SetSize(40, 40)
	iconRace:SetPoint("BOTTOM", f, "TOP")
	frame.iconFrame.iconRace = iconRace
	
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
	
	f:HookScript("OnUpdate", function()
		if XanUIDB and iconFrame:IsVisible() and not XanUIDB.showRace then
			iconFrame:Hide()
		elseif XanUIDB and not iconFrame:IsVisible() and XanUIDB.showRace then
			local chk = doRaceIcon(plate)
			if chk then
				iconFrame:Show()
			end
		end
	end)
	
	--healthbar checker, sometimes the health bar doesn't update properly and the health values are incorrect
	--so check for this and update accordingly
	local function checkHealth(self)
		if not isObjSafe(self) then return end
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
		if not isObjSafe(framePlate.healthBar) then return end
		--framePlate.castBar
		framePlate.healthBar._pFrame = f
		framePlate.healthBar:HookScript("OnShow", checkHealth)
		framePlate.healthBar:HookScript("OnHide", checkHealth)
		framePlate.healthBar:HookScript("OnValueChanged", checkHealth)
		framePlate.healthBar:HookScript("OnUpdate", checkHealth)
	end
	
end

local function UpdateQuestIcon(plate, unitID)

	--if a plate is restricted and cannot be used, lets avoid taints and errors
	if not isObjSafe(plate) then return end
	
	local Q = QuestPlates[plate]
	local unitID = unitID or addon:GetUnitForPlate(plate)
	if not Q then return end
	
	local scenarioName, currentStage, numStages, flags, _, _, _, xp, money, scenarioType, _, textureKitID = C_Scenario.GetInfo()
	local inChallengeMode = (scenarioType == LE_SCENARIO_TYPE_CHALLENGE_MODE)
	if inChallengeMode then
		Q:Hide()
		return
	end
	
	local progressGlob, questType, objectiveCount, qlIndex, questID, isWorldQuest, stillShow, isComplete, globCount = GetQuestProgress(unitID)

	if isComplete then
		Q:Hide()
		return
	end

	if progressGlob and questType ~= 2 then
		Q.questText:SetText(progressGlob or '')

		local objText = objectiveCount > 0 and objectiveCount or '?'
		
		Q.iconText:SetText(objText)
		Q.iconAlert:SetVertexColor(119/255, 136/255, 153/255, 0.9) --default slate gray tint
		Q.iconAlert:SetSize(16, 32) --reset size
		Q.iconAlert:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_1") --reset the texture
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
		elseif questType == 4 then
			--its a power gain quest but isn't a world quest.  Probably a "Bonus Objective", show a lighter orange
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(1, .82, 0)
			Q.iconAlert:SetVertexColor(1, 181/255, 17/255, 0.9) --show a lighter orange almost gold color
		elseif questType == 5 then
			--this quest failed all other regular quest checks but still has some data, possibly due to an objective.
			--the quest is obviously not completed so lets show a rose color marker
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(1, .82, 0)
			Q.iconAlert:SetVertexColor(1, 60/255, 56/255, 0.9) --rose color
			--Q.iconAlert:SetVertexColor(1, 0.1, 0.1, 0.9) --default red
		end
		
		Q.itemTexture:Hide()
		Q.lootIcon:Hide()
		Q.jellybean:Hide()
		Q.iconText:Hide()
		
		--make sure we have a questID to work with
		if qlIndex and not questID then
			local questInfo = C_QuestLog.GetInfo(qlIndex)
			if questInfo and questInfo.questID then questID = questInfo.questID end
		end
		
		--if we still don't have questID then it will show a red exclamation mark because it's default, sort of a catch all if we have qlIndex
		if questID then
			local finishedQuest = true
			local stillUnfinished = false
			local objCount = 0
			
			--don't use GetNumQuestLeaderBoards, it sometimes fails and returns 0, just use a huge number and break on nil
			--I highly doubt there will ever be 50 objectives for a quest
			for i = 1, 50 do
				local text, objectiveType, finished = GetQuestObjectiveInfo(questID, i, false)
				if not text then break end
				
				objCount = objCount + 1
				
				if not finished and (objectiveType == 'item' or objectiveType == 'object') then
					Q.lootIcon:Show()
				end
				
				--Debug('obj', progressGlob, UnitName(unitID))
				--Debug('obj', progressGlob, text, objectiveType, finished, UnitName(unitID))

				--check to see if the text matches our progress, that means it was only one objective
				if progressGlob == text and not finished then
					--check for optional, just in case
					if string.find(text, "(Optional)")	then
						Q.iconAlert:SetVertexColor(77/255, 216/255, 39/255, 0.9) --give it a fel green color for optional
					end
					finishedQuest = false
					break
				--do plaintext search
				elseif string.find(progressGlob, text, 1, true) and not finished then
					finishedQuest = false
					break
				--check to see if ANY of our objective text is in our progressGlob
				elseif string.find(progressGlob, text) and not finished then
					finishedQuest = false
					break
				--sometimes we have optional objectives that aren't covered, lets give it a special color
				elseif string.find(text, "(Optional)") and not finished then
					finishedQuest = false
					Q.iconAlert:SetVertexColor(77/255, 216/255, 39/255, 0.9) --give it a fel green color for optional
					break
				--check for special world quest cases of progressbar quests
				elseif not finished and questType == 3 or questType == 4 then
					finishedQuest = false
					--with the progressbar quest types since we can't really grab the missing objective and just return the quest title
					--this will always fail the objective text check.  In these scenarios, lets see if we are not done in any objective.
					--if we aren't then show it anyways
					break
				--check for special cases of progressbar quests
				elseif not finished and objectiveType == 'progressbar' then
					finishedQuest = false
					--some type of world quest or quest with progress that has a weirdo quest objective text
					--since it's not finished, just show it anyways
					break
				--check for unknown quest progress
				elseif not finished and questType == 5 then
					finishedQuest = false
					break
				
				--last ditch effort check, store it for ultimate check, make sure that finishedQuest is still set to true and hasn't been set to false in previous checks
				elseif not finished and finishedQuest then
					stillUnfinished = true
					--don't break let it run through all objectives, just in case
				end

			end

			--Debug('isFinished?', finishedQuest, stillUnfinished, questType, objCount, progressGlob, UnitName(unitID))
			
			--this is a last desperate check, if we only have one objective and it's still listed as unfinished then show it
			--this causes it to show finished tooltips as gray icons even if there are other objectives that aren't done
			--but we will use a smaller tiny arrow to folks know
			if finishedQuest and stillUnfinished and (objCount > 1 or globCount > 1) then
				finishedQuest = false
				Q.iconAlert:SetVertexColor(119/255, 136/255, 153/255, 0.9) --slate gray tint
				Q.iconAlert:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_2") --change to small other arrow, not big one
				Q.iconAlert:SetSize(10, 16) --make it smaller
			elseif finishedQuest and stillUnfinished then
				--single objective quest that was marked as unfinished for some reason
				--It could be a Scenario, grabbing objectives from that is different than quest objectives
				--catch all just in case we have a quest that isn't finished and show it anyways
				--just use the optional fel green color
				finishedQuest = false
				Q.iconAlert:SetVertexColor(77/255, 216/255, 39/255, 0.9) --give it a fel green color for optional
			end
			
			--lets check to see if they are in an scenario, if so then always show a particular color
			local inInstance, instanceType = IsInInstance()
			if instanceType == "scenario" then
				Q.iconAlert:SetVertexColor(0.9, 0.4, 0.04, 0.9) --show orange
				Q.iconAlert:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_1") --reset the texture
				Q.iconAlert:SetSize(16, 32) --reset size
			end

			--all objectives complete so lets just hide it
			if finishedQuest then
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
		Q.jellybean:Show()
		Q.iconText:Show()
		
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
	--if a plate is restricted and cannot be used, lets avoid taints and errors
	if not isObjSafe(plate) then return end
	
	UpdateQuestIcon(plate, unitID)
	doRaceIcon(plate)
end

function E:CacheQuestIndexes()
	doQuestCheck()
	
	wipe(QuestLogIndex)
	wipe(QuestObjectiveStrings)
	QuestObjectiveCount = 0
	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local questInfo = C_QuestLog.GetInfo(i)
		
		--isBounty is the world map bounty quests.  also known as daily emissary quests
		--lets not record those, they are hidden anyways
		if questInfo and not questInfo.isHeader and not questInfo.isBounty then

			QuestLogIndex[questInfo.title] = {qlIndex = i, questID = questInfo.questID, isComplete = C_QuestLog.IsComplete(questInfo.questID)}
			--I highly doubt there will ever be 50 objectives for a quest, just break on no description
			
			local numObjectives = C_QuestLog.GetNumQuestObjectives(questInfo.questID)
			local objectives = C_QuestLog.GetQuestObjectives(questInfo.questID)
						
			for objectiveIndex=1, numObjectives do
				local objective = objectives[objectiveIndex]

				if not objective.text then break end
				QuestObjectiveStrings[objective.text] = {qlIndex = i, questID = questInfo.questID, isComplete = objective.finished, objID = objectiveIndex}
				QuestObjectiveCount = QuestObjectiveCount + 1
			end
			
		end
	end
	
	for plate, f in pairs(addon:GetActiveNameplates()) do
		UpdateQuestIcon(plate, f._unitID)
	end
end

function E:UNIT_QUEST_LOG_CHANGED(unitID)
	if unitID == 'player' then
		E:CacheQuestIndexes()
	end
	
	for plate in pairs(addon:GetActiveNameplates()) do
		UpdateQuestIcon(plate)
	end
end

function E:QUEST_LOG_UPDATE()
	E:CacheQuestIndexes()
end
E:UnregisterEvent('QUEST_LOG_UPDATE')

function E:PLAYER_LEAVING_WORLD()
	E:UnregisterEvent('QUEST_LOG_UPDATE')
end

function E:PLAYER_ENTERING_WORLD()
	E:RegisterEvent('QUEST_LOG_UPDATE')
end
