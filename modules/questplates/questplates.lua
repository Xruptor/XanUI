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
-- C_CVar.SetCVar('showQuestUnitCircles', 1) -- Enables subtle glow under quest mobs
-- C_CVar.SetCVar('UnitNameFriendlySpecialNPCName', 1) -- Show name for quest objectives, even out of range of nameplates

-- END OF SETTINGS
--------------------

local _, addon = ...
local E = addon:Eve()
C_CVar.SetCVar('showQuestTrackingTooltips', '1') -- Required for this addon to function, don't turn this off

local GroupMembers = {}
local ActiveWorldQuests = {}
local QuestLogIndex = {}
local QuestObjectiveStrings = {}
local QuestObjectiveCount = 0
local QuestData = {}

local TextureAtlases = {
	['item'] = 'Banker', -- bag icon, you have to loot something for this quest
	--['monster'] = '', -- you must kill or interact with units for this quest
}

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

local OurName = UnitName('player')
local QuestPlateTooltip = CreateFrame('GameTooltip', 'QuestPlateTooltip', nil, 'GameTooltipTemplate')

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

local function isObjSafe(obj, checkInstance)
	local inInstance, instanceType = IsInInstance()
	if checkInstance and inInstance then return false end --you can't modify plates while in instances, it will cause errors and taint issues.
	if not CanAccessObject(obj) then return false end --check if you can even touch the plate
	return true
end

local QUEST_OBJECTIVE_PARSER_LEFT = function(text)
	local current, goal, objective_name = string.match(text,"^(%d+)/(%d+)( .*)$")
	
	if not objective_name then
		objective_name, current, goal = string.match(text,"^(.*: )(%d+)/(%d+)$")
	end
	
	return objective_name, current, goal
end

local QUEST_OBJECTIVE_PARSER_RIGHT = function(text)
	-- Quest objective: Versucht, zu kommunizieren: 0/1
	local objective_name, current, goal = string.match(text,"^(.*: )(%d+)/(%d+)$")
	
	if not objective_name then
		-- Quest objective: 0/1 Besucht die Halle der Kuriositäten
		current, goal, objective_name = string.match(text,"^(%d+)/(%d+)( .*)$")
	end
	
	return objective_name, current, goal
end

local STANDARD_QUEST_OBJECTIVE_PARSER = {
	-- x/y Objective
	enUS = QUEST_OBJECTIVE_PARSER_LEFT,
	-- enGB = enGB clients return enUS
	esMX = QUEST_OBJECTIVE_PARSER_LEFT,
	ptBR = QUEST_OBJECTIVE_PARSER_LEFT,
	itIT = QUEST_OBJECTIVE_PARSER_LEFT,
	koKR = QUEST_OBJECTIVE_PARSER_LEFT,
	zhTW = QUEST_OBJECTIVE_PARSER_LEFT,
	zhCN = QUEST_OBJECTIVE_PARSER_LEFT,
	
	-- Objective: x/y
	deDE = QUEST_OBJECTIVE_PARSER_RIGHT,
	frFR = QUEST_OBJECTIVE_PARSER_RIGHT,
	esES = QUEST_OBJECTIVE_PARSER_RIGHT,
	ruRU = QUEST_OBJECTIVE_PARSER_RIGHT,
}

local QuestObjectiveParser = STANDARD_QUEST_OBJECTIVE_PARSER[GetLocale()] or QUEST_OBJECTIVE_PARSER_LEFT

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
	local questIDList = {}
	local qlIndex
	local questID
	local lastIndex
	local lastQuestID
	local questText
	local questTitle
	
	local objSwitch_Comp = false
	local objSwitch_NotComp = false
	
	local objCompleted = false
	local qHasOptional = false
	local qHasLoot = false
	
	local progressChk = false
	
	for i = 3, QuestPlateTooltip:NumLines() do
		local str = _G['QuestPlateTooltipTextLeft' .. i]
		local text = str and str:GetText()
		if not text then return end
		
		local text_r, text_g, text_b = str:GetTextColor()
		
		if text_r and text_r > 0.99 and text_g > 0.82 and text_b == 0 then
			-- A line with this color is either the quest title or a player name (if on a group quest, but always after the quest title)
			
			if text == OurName then
				progressChk = true
			elseif not GroupMembers[text] then
				progressChk = true
				questTitle = text
			else
				progressChk = false
				--it's probably a group quest because the title was a player name, so lets check
				if GroupMembers[text] and not questType then questType = 2 end
			end
			
		elseif progressChk then
			
			local objective_name, current, goal = QuestObjectiveParser(text)
			local objChk = QuestObjectiveStrings[text] or QuestObjectiveStrings[questTitle]
			
			--it's dark grey text which means the objective on the tooltip is completed.
			--it's like 0.5019 or something but just do above 0.50 and less than 0.51 to grab it
			if objChk then
				--only check objectives not other text in the tooltip
				if text_r and text_r > 0.50 and text_r < 0.51 and text_g > 0.50 and text_g < 0.51 and text_b > 0.50 and text_b < 0.51 then
					objSwitch_Comp = true
				else
					objSwitch_NotComp = true
				end
			end
			
			--check if the last quest title was a world quest, if so set it
			if questTitle and ActiveWorldQuests[questTitle] then
				local qID = ActiveWorldQuests[questTitle]
				
				--it's a world quest different color than standard quest
				if qID then
					isWorldQuest = true -- world quest

					local progress = C_TaskQuest.GetQuestProgressBarInfo(qID)
					if progress then
						questType = 3 -- progress bar, do world quest color
						return questTitle, questType, ceil(100 - progress), nil, qID
					end
				end
			end
			
			--this switch is only used to determine if a number based objective was done rather than a string based one
			local progressSwitch = false
			
			if current and goal and tonumber(current) and tonumber(goal) then
				local numLeft = goal - current
				if numLeft > objectiveCount then -- track highest number of objectives
					objectiveCount = numLeft
				end
				--if objectiveCount > 0 then
				progressGlob = progressGlob and progressGlob .. '\n' .. text or text
				globCount = globCount + 1
				progressSwitch = true
				--end
			end
			
			--string based comparison for current and goal
			--this is for quests that don't have a counting goal like 3/10 but something like - Talk to NPC 0/1 or Used Item - Not Used/Used
			if not progressSwitch then
				if current and goal and current ~= goal then
					progressGlob = progressGlob and progressGlob .. '\n' .. text or text
					globCount = globCount + 1
				end
			end
			
		end
		
		local qIndexChk
		local qQuestIDChk				
		local isComplete
		
		local data = QuestLogIndex[text] or QuestLogIndex[questTitle]
		--if not by quest title try the objectives
		if not data then data = QuestObjectiveStrings[text] or QuestObjectiveStrings[questTitle] end
		
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
			if data.qHasLoot then
				qHasLoot = true
			end
			if data.qHasOptional then
				qHasOptional = true
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
			
			--set our fallback variables incase of markCompleted below is messed update
			questText = text
			qlIndex = qIndexChk
			questID = qQuestIDChk
		end
		
	end
	
	--can get quest info using questID by using QuestData[questID]
	-- if questID then
		-- local questData = QuestData[questID]
	-- end
	
	--check our completed objectives, if any return true then keep it hidden otherwise if all are finished then show gray marker
	if not objSwitch_NotComp and objSwitch_Comp then
		objCompleted = true
	end

	--check to see if the quest is complete, if so then we can avoid putting alerts on the nameplate
	local markCompleted = true
	
	if questIDList and #questIDList > 0 then
		for i = 1, #questIDList do
			--if any of the quests are marked as not completed, then reset the switch and exit loop
			--NOTE:!!!! make sure to set our variables to the uncompleted quest!!! important for checks below
			if not questIDList[i].isComplete then
				questText = questIDList[i].name
				qlIndex = questIDList[i].qlIndex
				questID = questIDList[i].questID
				markCompleted = false
				break
			end
		end
	end

	------
	--btw we check for questType so not to overwrite the PARTY questType of 2 or any other assigned questType already
	------

	--Bonus Objectives are referred to as (TASKS) by Blizzard
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
		if C_QuestLog.IsQuestTask(questID) then
			questType = 4 -- it's a Bonus Objective
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
	
	--if we get to this point and we have a progressglob and it's not completed, then it's just a regular quest. So mark it as 1
	if progressGlob and string.len(progressGlob) > 1 and not questType then
		--its a regular quest, just mark it as 1
		questType = 1
	end

	--Debug("----------")
	--Debug("LAST", UnitName(unitID), text, questTitle, questText, progressGlob, questType, objectiveCount, qlIndex, questID, isWorldQuest, markCompleted, globCount, objCompleted, qHasOptional, qHasLoot)
	--Debug("Check", "questType=", questType, "objectiveCount", objectiveCount, "questID=", questID, "isWorldQuest=", isWorldQuest)
	return progressGlob, questType, objectiveCount, qlIndex, questID, isWorldQuest, markCompleted, globCount, objCompleted, qHasOptional, qHasLoot
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
		if not isObjSafe(self, true) then return end
		
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
	
	--hide it at first
	Q:Hide()
	
	local progressGlob, questType, objectiveCount, qlIndex, questID, isWorldQuest, isComplete, globCount, objCompleted, qHasOptional, qHasLoot = GetQuestProgress(unitID)
	
	if isComplete then
		return
	end
	
	--FOR SCENARIOS
	--Blizzard_ScenarioObjectiveTracker.lua
	--------------------------------------
	local scenarioName, currentStage, numStages, flags, _, _, _, xp, money, scenarioType, _, textureKitID = C_Scenario.GetInfo()
	local inChallengeMode = (scenarioType == LE_SCENARIO_TYPE_CHALLENGE_MODE)
	-- local inProvingGrounds = (scenarioType == LE_SCENARIO_TYPE_PROVING_GROUNDS);
	-- local dungeonDisplay = (scenarioType == LE_SCENARIO_TYPE_USE_DUNGEON_DISPLAY);
	-- local inWarfront = (scenarioType == LE_SCENARIO_TYPE_WARFRONT);
	-- local scenariocompleted = currentStage > numStages;
	
	if inChallengeMode then
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
		
		if questType ~= 3 and isWorldQuest then
			--if it's not a power world quest but it's still a world quest
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(0.2, 1, 1)
			Q.iconAlert:SetVertexColor(9/255, 218/255, 224/255, 0.9) --light blueish tint
		elseif questType == 1 then
			--regular quest
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(1, .82, 0)
			Q.iconAlert:SetVertexColor(0.9, 0.4, 0.04, 0.9) --show orange much nicer
		elseif questType == 3 then
			--its a power gain type world quest
			Q.jellybean:SetDesaturated(false)
			Q.iconText:SetTextColor(0.2, 1, 1)
			Q.iconAlert:SetVertexColor(0.3, 0.3, 1, 0.9) --dark blue tint
		elseif questType == 4 then
			--it's probably a Bonus Objective
			--its a power gain quest but isn't a world quest. Probably a "Bonus Objective", show a lighter orange
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
			
			if objCompleted then
				Q.iconAlert:SetVertexColor(119/255, 136/255, 153/255, 0.9) --slate gray tint
				Q.iconAlert:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_2") --change to small other arrow, not big one
				Q.iconAlert:SetSize(10, 16) --make it smaller
			end
			
			if qHasOptional and not isWorldQuest then
				Q.iconAlert:SetVertexColor(77/255, 216/255, 39/255, 0.9) --give it a fel green color for optional
			end
				
			if qHasLoot and not objCompleted then
				Q.lootIcon:Show()
			end
			
			--lets check to see if they are in an scenario, if so then always show a particular color
			local inInstance, instanceType = IsInInstance()
			if instanceType == "scenario" then
				Q.iconAlert:SetVertexColor(0.9, 0.4, 0.04, 0.9) --show orange
				Q.iconAlert:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_1") --reset the texture
				Q.iconAlert:SetSize(16, 32) --reset size
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
		
	elseif questType == 2 then
		
		Q.jellybean:SetDesaturated(true)
		Q.iconText:SetTextColor(71/255, 183/255, 23/255, 0.9)
		Q.iconAlert:SetVertexColor(71/255, 183/255, 23/255, 0.9) --green tint
		Q.iconAlert:Show()
		Q.itemTexture:Hide()
		Q.lootIcon:Hide()
		
		local objText = objectiveCount > 0 and objectiveCount or 'P'
		
		Q.iconText:SetText(objText)
		Q.jellybean:Show()
		Q.iconText:Show()
		
		if not Q:IsVisible() then
			Q.ani:Stop()
			Q:Show()
			Q.ani:Play()
		end
	end
	
end

function E:OnPlateShow(f, plate, unitID)
	--if a plate is restricted and cannot be used, lets avoid taints and errors
	if not isObjSafe(plate) then return end
	
	UpdateQuestIcon(plate, unitID)
	doRaceIcon(plate)
end

function E:CacheQuestIndexes()

	wipe(QuestLogIndex)
	wipe(QuestObjectiveStrings)
	wipe(ActiveWorldQuests)
	wipe(QuestData)
	
	QuestObjectiveCount = 0
	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local questInfo = C_QuestLog.GetInfo(i)
		
		if questInfo and not questInfo.isHeader then
			local info = C_QuestLog.GetQuestTagInfo(questInfo.questID)
			if info and info.worldQuestType then
				ActiveWorldQuests[questInfo.title] = questInfo.questID
			end
		end
				
		--isBounty is the world map bounty quests. also known as daily emissary quests
		--lets not record those, they are hidden anyways
		if questInfo and not questInfo.isHeader and not questInfo.isBounty then
			
			local numObjectives = C_QuestLog.GetNumQuestObjectives(questInfo.questID)
			local objectives = C_QuestLog.GetQuestObjectives(questInfo.questID)
			local qHasLoot = false
			local qHasOptional = false
			
			QuestData[questInfo.questID] = {}
			
			for objectiveIndex=1, numObjectives do
				local objective = objectives[objectiveIndex]
				
				if not objective.text then break end
				
				if string.find(objective.text, "(Optional)") and not objective.finished then
					qHasOptional = true
				end
				
				if not objective.finished and (objective.type == 'item' or objective.type == 'object') then
					qHasLoot = true
				end
				
				local objInfo = {
					qlIndex = i,
					objText = objective.text,
					objType = objective.type,
					questID = questInfo.questID,
					isComplete = objective.finished,
					objID = objectiveIndex,
					qHasLoot = qHasLoot,
					qHasOptional = qHasOptional,
				}
				
				QuestObjectiveStrings[objective.text] = objInfo
				table.insert(QuestData[questInfo.questID], objInfo)

				QuestObjectiveCount = QuestObjectiveCount + 1
			end
			
			--do the quest storing last, that way we can check quest objectives first for tags, like qHastLoot and qHasOptional
			QuestLogIndex[questInfo.title] = {
				qlIndex = i,
				questID = questInfo.questID,
				isComplete = C_QuestLog.IsComplete(questInfo.questID),
				qHasLoot = qHasLoot,
				qHasOptional = qHasOptional,
			}
			
		end
	end
	
	for plate, f in pairs(addon:GetActiveNameplates()) do
		UpdateQuestIcon(plate, f._unitID)
	end
end

function E:PLAYER_LOGIN()
	E:CacheQuestIndexes()
	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [|cFF20ff20QuestPlates Loaded|r]")
end

function E:GROUP_ROSTER_UPDATE()
	local group_size = (IsInRaid() and GetNumGroupMembers()) or (IsInGroup() and GetNumSubgroupMembers()) or 0
	
	-- local is_in_raid = IsInRaid()
	-- local is_in_group = is_in_raid or IsInGroup()
	
	wipe(GroupMembers)
	
	if group_size > 0 then
		local group_type = (IsInRaid() and "raid") or IsInGroup() and "party" or "solo"
		
		for i = 1, group_size do
			--local unit_name = UnitName(group_type .. i)
			if UnitExists(group_type .. i) then
				--print("Adding member:", UnitName(group_type .. i))
				GroupMembers[UnitName(group_type .. i)] = true
			end
		end
	end
	
end

--this is if the world frame was refreshed or the user did a /reload etc..
function addon:UI_SCALE_CHANGED()
	E:CacheQuestIndexes()
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