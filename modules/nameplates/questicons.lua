local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "questicons"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
LibStub("AceEvent-3.0"):Embed(moduleFrame)

local npHooks = addon["nameplateHooks"]
local iconKey = ADDON_NAME .. "QuestIcon"
local ICON_PATH = "Interface\\AddOns\\"..ADDON_NAME.."\\media\\questicon_1"

moduleFrame.QuestByTitle = {}
moduleFrame.QuestByID = {}
moduleFrame.QuestsToUpdate = {}

local enableDebug = false

local debugf = tekDebug and tekDebug:GetFrame(ADDON_NAME)
local function Debug(...)
	if not enableDebug then return end
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local function GetHashTableLen(tbl)
	local count = 0
	for _, __ in pairs(tbl) do
		count = count + 1
	end
	return count
end

----------------------------------------------
----- QUEST API
----------------------------------------------

local function isQuestComplete(questIndex, questID)
	Debug("isQuestComplete", questIndex, questID)
	if questIndex then
		local qInfo = C_QuestLog.GetInfo(questIndex)
		if qInfo and C_QuestLog.IsComplete(qInfo.questID) then
			return true
		end
	end
	if questID then
		if C_QuestLog.IsComplete(questID) or C_QuestLog.IsQuestFlaggedCompleted(questID) then
			return true
		end
	end
	return false
end

local function CacheQuest(questIndex, questID)
	if questID and C_QuestLog.IsQuestTask(questID) then
		local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
		if questName then
			moduleFrame.QuestByID[questID] = questName
			moduleFrame.QuestByTitle[questName] = questID
		end
		Debug("CacheQuest", "C_TaskQuest", questID, questName)
	elseif questIndex then
		local qInfo = C_QuestLog.GetInfo(questIndex)
		if qInfo then
			--isBounty is the world map bounty quests. also known as daily emissary quests
			--lets not record those, they are hidden anyways
			if qInfo.title and not qInfo.isHeader then
				moduleFrame.QuestByID[qInfo.questID] = qInfo.title
				moduleFrame.QuestByTitle[qInfo.title] = qInfo.questID
				Debug("CacheQuest", "questIndex", qInfo.questID, qInfo.title)
			end
		else
			--we need to grab the quest info when it's sent back from the server
			moduleFrame.QuestByID[questID] = "UpdatePending"
		end
	end
end

local function CacheQuestByQuestID(questID)
	Debug("CacheQuestByQuestID", questID)
	if questID then
		local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
		CacheQuest(questIndex, questID)
	end
end

local function DoQuestLogCache(byPassUpdate)
	Debug("DoQuestLogCache", byPassUpdate)
	--reset these values
	moduleFrame.QuestByTitle = {}
	moduleFrame.QuestByID = {}

	for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
		CacheQuest(questIndex)
	end
	
	if not byPassUpdate then
		moduleFrame:UpdateAllQuestIcons("DoQuestLogCache")
	end
end

local function ScanObjective(line)

    local x, y = line:match('(%d+)/(%d+)')
    x, y = tonumber(x), tonumber(y)

    if x and y then
        if x ~= y then
            return false
		else
			--if it matches then it's objective complete
			return true
        end
    else
        x = line:match('%((%d+)%%%)')
        x = tonumber(x)

		--it's a power object, if 100 or greater then it's complete, otherwise false
        if x and x < 100 then
            return false
		elseif x and x >= 100 then
			return true
        end
    end

end

local function UpdateQuestIcon(f, plate, unitID, tooltipData)
	if not f or not plate then return end
	if not XanUIDB then return end
	
	local iconQuest = f[iconKey]
	Debug("------------------")
	Debug("UpdateQuestIcon", unitID)

	--just in case check to see if we have the icon
	if not iconQuest then
		iconQuest = f:CreateTexture(nil, "OVERLAY")
		f[iconKey] = iconQuest
		iconQuest:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_1")
		iconQuest:SetSize(16, 32)
		iconQuest:SetPoint("BOTTOM", f, "TOP")
		iconQuest:Hide()
	end
	
	--don't do these things when in a BattlePet battle
	if C_PetBattles.IsInBattle() then
		iconQuest:Hide()
		return
	end
	
	--check tooltipData
	if not tooltipData then
		tooltipData = C_TooltipInfo.GetUnit(unitID)
	end
	if not tooltipData then
		iconQuest:Hide()
		return
	end

	TooltipUtil.SurfaceArgs(tooltipData)
	
	local questType = 0
	local objCache = {}
	local questIDCache = {}
	local scenarioName

	--sometimes we are in a scenario that isn't exactly a task quest or treated as an bonus objective.  Example:  Dragonflight -> Grand Hunts
	--so we need to grab the scenario name to check for that if available
	if C_Scenario.IsInScenario() then
		scenarioName = C_Scenario.GetInfo()
	end

	--parse the tooltip data
	if tooltipData and tooltipData.lines then
		
		for i = 3, #tooltipData.lines do

			local line = tooltipData.lines[i]
			TooltipUtil.SurfaceArgs(line)
			
			if line then
				local text = line.leftText

				if text and moduleFrame.QuestByTitle[text] then
					local questID = moduleFrame.QuestByTitle[text]

					if questID then
						local isDone = isQuestComplete(nil, questID)

						if C_QuestLog.IsWorldQuest(questID) then
							questType = 2 --world quest
							
							local progress = C_TaskQuest.GetQuestProgressBarInfo(questID)
							if progress then
								questType = 3 -- progress bar world type quest
							end
							
						else
							if C_QuestLog.IsQuestTask(questID) then
								questType = 4 -- it's a Bonus Objective
							else
								questType = 1 --regular quest
							end
						end

						table.insert(questIDCache, tostring(isDone))
						Debug("UpdateQuestIcon", "TooltipData", text, questID, isDone, questType, #questIDCache)
					end
				
				elseif text and scenarioName and text == scenarioName then
					questType = 4 -- it's a Scenario quest (bonus objective)
					table.insert(questIDCache, tostring(false))
					Debug("UpdateQuestIcon", "scenarioName", scenarioName, questType, #questIDCache)
				else
					--okay so technically speaking we could have scanned each objective using code instead of scanning the tooltip.
					--the problem is that although an objective can be marked as uncompleted, it may not exactly apply to the current unit being parsed.
					--in other words their part in the quest MAY be completed, but another unit required may not and still be part of the quest.
					--So if I were to scan for all objectives not finished, it would mark units that ARE completed in the quest as unfinished.
					--Hence, it's just better to scan the tooltip to see the objectives being applied to a particular unit.
					local obj = ScanObjective(text)

					--we have something to work with
					if obj ~= nil then
						--if any of the objectives are incomplete then mark it as not done
						table.insert(objCache, tostring(obj))
						Debug("UpdateQuestIcon", "ScanObjective", obj, #objCache)
					end
				end
				
			end
			
		end

	end
	
	--if we have something to work with and the first entry is still false, then the objective for quest or mob isn't done yet
	--make sure to convert the value boolean to string for comparison
	
	--make sure the false is on the top, make sure to convert the booleans to strings
	table.sort(objCache, function(a, b)
		return tostring(a) < tostring(b);
	end)
	table.sort(questIDCache, function(a, b)
		return tostring(a) < tostring(b);
	end)

	Debug("UpdateQuestIcon", "Totals", #objCache, #questIDCache)

	local doIcon = false

	--if we do have objectives and at least one is uncomplete, then process
	if #objCache > 0 and tostring(objCache[1]) == "false" then

		local partyChk = 0

		--if we don't have any quest found, it's probably a party members quest.
		if #questIDCache < 1 or questType == 0 then
			questType = 5 --set to party member, fel green color
			partyChk = 1
		--if all quests are completed and we still have uncompleted objectives, chances are its a party members quests
		elseif tostring(questIDCache[1]) == "true" then
			questType = 5 --set to party member, fel green color
			partyChk = 2
		end

		doIcon = true
		Debug("UpdateQuestIcon", "Chk1", #objCache, #questIDCache, questType, partyChk)

	--if we don't have objectives but at least one of our quests isn't completed, then show the icon anyways
	elseif #objCache < 1 and #questIDCache > 0 and tostring(questIDCache[1]) == "false"  then
		doIcon = true
		Debug("UpdateQuestIcon", "Chk2", #objCache, #questIDCache)
	end

	--only check the questIDCache if we don't have any returns on the objectives cache
	if doIcon then
		Debug("UpdateQuestIcon", "doIcon", doIcon, questType)

		if questType == 1 then
			--regular quest
			iconQuest:SetVertexColor(0.9, 0.4, 0.04, 0.9) --show orange much nicer
		elseif questType == 2 then
			--world quest
			iconQuest:SetVertexColor(9/255, 218/255, 224/255, 0.9) --light blueish tint
		elseif questType == 3 then
			-- progress bar world type quest
			iconQuest:SetVertexColor(0.3, 0.3, 1, 0.9) --dark blue tint
		elseif questType == 4 then
			--it's probably a Bonus Objective
			iconQuest:SetVertexColor(202/255, 128/255, 231/255, 0.9) --show a lavender purple color
		elseif questType == 5 then
			--party member quest
			iconQuest:SetVertexColor(77/255, 216/255, 39/255, 0.9) --show fel green color		
		else
			--something went wrong and the quest didn't get a questType and it isn't completed, show it as a rose red color
			iconQuest:SetVertexColor(1, 60/255, 56/255, 0.9) --rose color
		end
		
		iconQuest:Show()
		return --return so not to Hide below
		
	end

	iconQuest:Hide()
end

local function OnTooltipSetUnit(tooltip, tooltipData)
	if not npHooks then return end
	if not tooltipData or not tooltipData.guid then return end
	
	local plate, f = npHooks:GetPlateForGUID(tooltipData.guid)
	if f and f._unitID then
		UpdateQuestIcon(f, plate, f._unitID, tooltipData)
	end
end

function moduleFrame:UpdateAllQuestIcons(trigger)
	if not npHooks then return end
	Debug("UpdateAllQuestIcons", trigger)

	for plate, f in pairs(npHooks:GetActiveNameplates()) do
		UpdateQuestIcon(f, plate, f._unitID)
	end
end

----------------------------------------------
----- QUEST EVENTS
----------------------------------------------

function moduleFrame:QUEST_LOG_UPDATE()
	local numCount = GetHashTableLen(moduleFrame.QuestsToUpdate)

	if numCount > 0 then
		Debug("QUEST_LOG_UPDATE", "QuestsToUpdate", numCount)

		for questID, qTitle in pairs(moduleFrame.QuestsToUpdate) do
			local tmpID = moduleFrame.QuestByTitle[qTitle]
			if not tmpID then
				CacheQuestByQuestID(questID)
			end
			moduleFrame.QuestsToUpdate[questID] = nil
		end
		
		Debug("QUEST_LOG_UPDATE", "QuestsToUpdate")

		moduleFrame:UpdateAllQuestIcons("QUEST_LOG_UPDATE")
		return
	end

	--we don't want to spam the grabbing of all the quests every time a quest is updated.
	--instead we only want to update those individual quests that were updated.  If we were to spam the full quest log constantly each time, it would cause lag
	if not moduleFrame.scannedQuestLog then
		moduleFrame.scannedQuestLog = true
		Debug("QUEST_LOG_UPDATE")
		DoQuestLogCache()
	end
end

function moduleFrame:QUEST_ACCEPTED(event, questID)
	Debug("QUEST_ACCEPTED", questID)

	CacheQuestByQuestID(questID)
	if moduleFrame.QuestByID[questID] == "UpdatePending" then
		C_QuestLog.RequestLoadmoduleFrame.QuestByID(questID)
	end
	--possibly need to update icons when a quest is accepted, need to see if triggers QUEST_LOG_UPDATE
end

function moduleFrame:QUEST_REMOVED(event, questID)
	Debug("QUEST_REMOVED", questID)

	local qTitle = moduleFrame.QuestByID[questID]

	moduleFrame.QuestByID[questID] = nil
	moduleFrame.QuestsToUpdate[questID] = nil

	if qTitle then
		moduleFrame.QuestByTitle[qTitle] = nil
		moduleFrame:UpdateAllQuestIcons("QUEST_REMOVED")
	end
end

function moduleFrame:QUEST_DATA_LOAD_RESULT(event, questID, success)
	--this event is triggered when we request a quest update from the server using RequestLoadmoduleFrame.QuestByID
	if success and moduleFrame.QuestByID[questID] == "UpdatePending" then
		CacheQuestByQuestID(questID)
		moduleFrame:UpdateAllQuestIcons("QUEST_DATA_LOAD_RESULT")
	end
end

function moduleFrame:QUEST_WATCH_UPDATE(event, questID)
	Debug("QUEST_WATCH_UPDATE", questID)

	local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	if questIndex then
		local qInfo = C_QuestLog.GetInfo(questIndex)
		if qInfo and qInfo.title then
			moduleFrame.QuestsToUpdate[questID] = qInfo.title
		end
	end
end

function moduleFrame:UNIT_QUEST_LOG_CHANGED(event, unitID)
	Debug("UNIT_QUEST_LOG_CHANGED", unitID)
	if unitID == "player" then
		DoQuestLogCache()
	else
		moduleFrame:UpdateAllQuestIcons("UNIT_QUEST_LOG_CHANGED")
	end
end

function moduleFrame:UI_SCALE_CHANGED()
	Debug("UI_SCALE_CHANGED")
	DoQuestLogCache()
end

----------------------------------------------
----- NAMEPLATE EVENTS
----------------------------------------------

function moduleFrame:XANUI_ON_NEWPLATE(event, f, plate)
	local iconQuest = f[iconKey]

	if not iconQuest then
		iconQuest = f:CreateTexture(nil, "OVERLAY")
		f[iconKey] = iconQuest
		iconQuest:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_1")
		iconQuest:SetSize(16, 32)
		iconQuest:SetPoint("BOTTOM", f, "TOP")
		iconQuest:Hide()
	end
end

function moduleFrame:XANUI_ON_PLATESHOW(event, f, plate, unitID)
	UpdateQuestIcon(f, plate, unitID)
end

function moduleFrame:XANUI_ON_PLATEHIDE(event, f, plate, unitID)
	local iconQuest = f[iconKey]

	if f[iconQuest] then
		f[iconQuest]:Hide()
	end
end

----------------------------------------------
----- ADDON ENABLE
----------------------------------------------

local function EnableQuestIcons()
	if not addon.IsRetail then return end

	moduleFrame:RegisterEvent("QUEST_ACCEPTED")
	moduleFrame:RegisterEvent("QUEST_REMOVED")
	moduleFrame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
	moduleFrame:RegisterEvent("QUEST_WATCH_UPDATE")
	moduleFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
	moduleFrame:RegisterEvent("UI_SCALE_CHANGED")

	--QUESTTASK_UPDATE
	--TASK_PROGRESS_UPDATE

	moduleFrame:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		moduleFrame:RegisterEvent("QUEST_LOG_UPDATE")
		Debug("PLAYER_ENTERING_WORLD")
	end)
	moduleFrame:RegisterEvent("PLAYER_LEAVING_WORLD", function()
		moduleFrame:UnregisterEvent('QUEST_LOG_UPDATE')
		Debug("PLAYER_LEAVING_WORLD")
	end)

	moduleFrame:RegisterMessage('XANUI_ON_NEWPLATE')
	moduleFrame:RegisterMessage('XANUI_ON_PLATESHOW')
	moduleFrame:RegisterMessage('XANUI_ON_PLATEHIDE')
	
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableQuestIcons, name=moduleName } )