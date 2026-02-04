local ADDON_NAME, private = ...
local addon = private and private.GetAddonFrame and private:GetAddonFrame(ADDON_NAME) or _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local moduleName = "questicons"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
addon:EmbedEvents(moduleFrame)

local npHooks = addon["nameplateHooks"]
local iconKey = ADDON_NAME .. "QuestIcon"
local ICON_PATH = "Interface\\AddOns\\"..ADDON_NAME.."\\media\\quest4"

moduleFrame.QuestByTitle = {}
moduleFrame.QuestByID = {}
moduleFrame.QuestsToUpdate = {}

local enableDebug = false

local debugf = tekDebug and tekDebug:GetFrame(ADDON_NAME)
local function Debug(...)
	if not enableDebug then return end
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local C_QuestLog = C_QuestLog
local C_TaskQuest = C_TaskQuest
local C_TooltipInfo = C_TooltipInfo
local C_Scenario = C_Scenario
local C_PetBattles = C_PetBattles

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
		if not questID then
			questID = C_QuestLog.GetQuestIDForLogIndex(questIndex)
		end
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
			if questID then
				moduleFrame.QuestByID[questID] = "UpdatePending"
			end
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

    local x, y = line:match("(%d+)/(%d+)")
    x, y = tonumber(x), tonumber(y)

    if x and y then
        if x ~= y then
            return false
		else
			--if it matches then it's objective complete
			return true
        end
    else
        x = line:match("%((%d+)%%%)")
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
	if not XanUIDB.showQuests then
		local iconQuest = f[iconKey]
		if iconQuest then
			iconQuest:Hide()
		end
		return
	end

	local iconQuest = f[iconKey]
	Debug("------------------")
	Debug("UpdateQuestIcon", unitID)

	--just in case check to see if we have the icon
	if not iconQuest then
		iconQuest = f:CreateTexture(nil, "OVERLAY")
		f[iconKey] = iconQuest
		iconQuest:SetTexture(ICON_PATH)
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

	local function GetLineLeftText(line)
		if not line then return nil end
		if line.leftText then return line.leftText end
		if line.text then return line.text end
		if line.left and type(line.left) == "table" then
			if line.left.text then return line.left.text end
			if line.left.value then return line.left.value end
		end
		return nil
	end

	local questType = 0
	local questTypePriority = 0
	local hasObjective = false
	local hasIncompleteObjective = false
	local hasQuest = false
	local hasIncompleteQuest = false
	local scenarioName
	local questByTitle = moduleFrame.QuestByTitle

	--sometimes we are in a scenario that isn't exactly a task quest or treated as an bonus objective.  Example:  Dragonflight -> Grand Hunts
	--so we need to grab the scenario name to check for that if available
	if C_Scenario.IsInScenario() then
		scenarioName = C_Scenario.GetInfo()
	end

	--parse the tooltip data
	if tooltipData and tooltipData.lines then

		for i = 3, #tooltipData.lines do

			local line = tooltipData.lines[i]
			if TooltipUtil and TooltipUtil.SurfaceArgs then
				TooltipUtil.SurfaceArgs(line)
			end

			if line then
				local text = GetLineLeftText(line)

				if text and questByTitle[text] then
					local questID = questByTitle[text]

					if questID then
						local isDone = isQuestComplete(nil, questID)
						hasQuest = true
						if not isDone then
							hasIncompleteQuest = true
						end

						local qType = 0
						if C_QuestLog.IsWorldQuest(questID) then
							qType = 2 --world quest

							local progress = C_TaskQuest.GetQuestProgressBarInfo(questID)
							if progress then
								qType = 3 -- progress bar world type quest
							end

						else
							if C_QuestLog.IsQuestTask(questID) then
								qType = 4 -- it's a Bonus Objective
							else
								qType = 1 --regular quest
							end
						end

						local priority = 1
						if qType == 2 or qType == 3 then
							priority = 3 --world quest (progress bar or standard)
						elseif qType == 4 then
							priority = 2 --bonus/scenario
						else
							priority = 1 --regular
						end

						if not isDone then
							--prefer higher priority when multiple incomplete quest titles are present
							if priority >= questTypePriority then
								questType = qType
								questTypePriority = priority
							end
						elseif questType == 0 and questTypePriority == 0 then
							questType = qType
						end

						Debug("UpdateQuestIcon", "TooltipData", text, questID, isDone, questType)
					end

				elseif text and scenarioName and text == scenarioName then
					questType = 4 -- it's a Scenario quest (bonus objective)
					hasQuest = true
					hasIncompleteQuest = true
					Debug("UpdateQuestIcon", "scenarioName", scenarioName, questType)
				else
					--okay so technically speaking we could have scanned each objective using code instead of scanning the tooltip.
					--the problem is that although an objective can be marked as uncompleted, it may not exactly apply to the current unit being parsed.
					--in other words their part in the quest MAY be completed, but another unit required may not and still be part of the quest.
					--So if I were to scan for all objectives not finished, it would mark units that ARE completed in the quest as unfinished.
					--Hence, it's just better to scan the tooltip to see the objectives being applied to a particular unit.
					local obj = ScanObjective(text)

					--we have something to work with
					if obj ~= nil then
						hasObjective = true
						if not obj then
							hasIncompleteObjective = true
						end
						--if any of the objectives are incomplete then mark it as not done
						Debug("UpdateQuestIcon", "ScanObjective", obj)
					end
				end

			end

		end

	end

	--if we have something to work with and the first entry is still false, then the objective for quest or mob isn't done yet
	--make sure to convert the value boolean to string for comparison

	Debug("UpdateQuestIcon", "Totals", hasObjective, hasQuest, hasIncompleteObjective, hasIncompleteQuest)

	local doIcon = false

	--if we do have objectives and at least one is uncomplete, then process
	if hasObjective and hasIncompleteObjective then

		local partyChk = 0

		--if we don't have any quest found, it's probably a party members quest.
		if not hasQuest or questType == 0 then
			questType = 5 --set to party member, fel green color
			partyChk = 1
		--if all quests are completed and we still have uncompleted objectives, chances are its a party members quests
		elseif hasQuest and not hasIncompleteQuest then
			questType = 5 --set to party member, fel green color
			partyChk = 2
		end

		doIcon = true
		Debug("UpdateQuestIcon", "Chk1", questType, partyChk)

	--if we don't have objectives but at least one of our quests isn't completed, then show the icon anyways
	elseif not hasObjective and hasQuest and hasIncompleteQuest then
		doIcon = true
		Debug("UpdateQuestIcon", "Chk2")
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
	if not XanUIDB or not XanUIDB.showQuests then
		for _, f in pairs(npHooks:GetActiveNameplates()) do
			local iconQuest = f[iconKey]
			if iconQuest then
				iconQuest:Hide()
			end
		end
		return
	end
	Debug("UpdateAllQuestIcons", trigger)

	for plate, f in pairs(npHooks:GetActiveNameplates()) do
		UpdateQuestIcon(f, plate, f._unitID)
	end
end

----------------------------------------------
----- QUEST EVENTS
----------------------------------------------

function moduleFrame:QUEST_LOG_UPDATE()
	if moduleFrame.questLogUpdatePending then return end
	moduleFrame.questLogUpdatePending = true
	C_Timer.After(0.1, function()
		moduleFrame.questLogUpdatePending = nil
		moduleFrame:HandleQuestLogUpdate()
	end)
end

function moduleFrame:HandleQuestLogUpdate()
	if next(moduleFrame.QuestsToUpdate) ~= nil then
		Debug("QUEST_LOG_UPDATE", "QuestsToUpdate")

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

	--lightweight refresh: update cached quest IDs without a full log scan
	for questID, qTitle in pairs(moduleFrame.QuestByID) do
		if questID ~= "UpdatePending" then
			CacheQuestByQuestID(questID)
		end
	end
	moduleFrame:UpdateAllQuestIcons("QUEST_LOG_UPDATE_LIGHT")

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
		C_QuestLog.RequestLoadQuestByID(questID)
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
	--this event is triggered when we request a quest update from the server using C_QuestLog.RequestLoadQuestByID
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

function moduleFrame:QUEST_TURNED_IN(event, questID)
	Debug("QUEST_TURNED_IN", questID)
	CacheQuestByQuestID(questID)
	moduleFrame:UpdateAllQuestIcons("QUEST_TURNED_IN")
end

function moduleFrame:QUEST_COMPLETED(event, questID)
	Debug("QUEST_COMPLETED", questID)
	CacheQuestByQuestID(questID)
	moduleFrame:UpdateAllQuestIcons("QUEST_COMPLETED")
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
		iconQuest:SetTexture(ICON_PATH)
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

	if iconQuest then
		iconQuest:Hide()
	end
end

----------------------------------------------
----- ADDON ENABLE
----------------------------------------------

local function EnableQuestIcons()
	if not addon.IsRetail then return end

	local function SafeRegisterEvent(event, callback)
		local ok = pcall(moduleFrame.RegisterEvent, moduleFrame, event, callback)
		if not ok then
			Debug("Skipped unknown event: " .. tostring(event))
		end
	end

	SafeRegisterEvent("QUEST_ACCEPTED")
	SafeRegisterEvent("QUEST_REMOVED")
	SafeRegisterEvent("QUEST_TURNED_IN")
	SafeRegisterEvent("QUEST_COMPLETED")
	SafeRegisterEvent("QUEST_DATA_LOAD_RESULT")
	SafeRegisterEvent("QUEST_WATCH_UPDATE")
	SafeRegisterEvent("UNIT_QUEST_LOG_CHANGED")
	SafeRegisterEvent("UI_SCALE_CHANGED")

	--QUESTTASK_UPDATE
	--TASK_PROGRESS_UPDATE

	SafeRegisterEvent("PLAYER_ENTERING_WORLD", function()
		SafeRegisterEvent("QUEST_LOG_UPDATE")
		Debug("PLAYER_ENTERING_WORLD")
	end)
	SafeRegisterEvent("PLAYER_LEAVING_WORLD", function()
		moduleFrame:UnregisterEvent('QUEST_LOG_UPDATE')
		Debug("PLAYER_LEAVING_WORLD")
	end)

	moduleFrame:RegisterMessage('XANUI_ON_NEWPLATE')
	moduleFrame:RegisterMessage('XANUI_ON_PLATESHOW')
	moduleFrame:RegisterMessage('XANUI_ON_PLATEHIDE')

	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
	end

	C_Timer.After(10, DoQuestLogCache)
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableQuestIcons, name=moduleName } )
