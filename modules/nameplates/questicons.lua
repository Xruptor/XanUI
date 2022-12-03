local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "questicons"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
LibStub("AceEvent-3.0"):Embed(moduleFrame)

local iconKey = ADDON_NAME .. "QuestIcon"
local ICON_PATH = "Interface\\AddOns\\"..ADDON_NAME.."\\media\\questicon_1"

moduleFrame.QuestByTitle = {}
moduleFrame.QuestByID = {}
moduleFrame.QuestsToUpdate = {}

local function tobool(obj)
	if obj == nil then return false end
	if tonumber(obj) and tonumber(obj) == 0 then
		return false
	elseif tonumber(obj) and tonumber(obj) == 1 then
		return true
	end
	return obj
end

----------------------------------------------
----- QUEST API
----------------------------------------------

local function isQuestComplete(questIndex, questID)
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
	if questIndex then
		local qInfo = C_QuestLog.GetInfo(questIndex)
		if qInfo then
			if qInfo.title and not qInfo.isHeader then
				qInfo.tagInfo = C_QuestLog.GetQuestTagInfo(qInfo.questID) --grab the tags for things like worldquests
				
				moduleFrame.QuestByID[qInfo.questID] = qInfo.title
				moduleFrame.QuestByTitle[qInfo.title] = qInfo
			end
		else
			--we need to grab the quest info when it's sent back from the server
			moduleFrame.QuestByID[questID] = "UpdatePending"
		end
	end
end

local function CacheQuestByQuestID(questID)
	if questID then
		local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
		CacheQuest(questIndex, questID)
	end
end

local function DoQuestLogCache(byPassUpdate)
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

local function UpdateQuestIcon(f, plate, unitID, tooltipData)
	if not f or not plate then return end
	if not XanUIDB then return end
	
	local iconQuest = f[iconKey]

	--just in case check to see if we have the icon
	if not iconQuest then
		iconQuest = f:CreateTexture(nil, "OVERLAY")
		f[iconKey] = iconQuest
		iconQuest:SetTexture("Interface\\AddOns\\XanUI\\media\\questicon_1")
		iconQuest:SetSize(16, 32)
		iconQuest:SetPoint("BOTTOM", f, "TOP")
		iconQuest:Hide()
	end
	
	--make sure we have quest data to work with, in case we haven't scanned yet
	if not moduleFrame.scannedQuestLog then
		moduleFrame.scannedQuestLog = true
		DoQuestLogCache(true)
	end
	
	--check tooltipData
	if not tooltipData then
		tooltipData = C_TooltipInfo.GetUnit(unitID)
	end
	TooltipUtil.SurfaceArgs(tooltipData)
	
	local questType = 0
	local questFound = false
	
	--parse the tooltip data
	if tooltipData and tooltipData.lines then
		
		for i = 3, #tooltipData.lines do
			--only loop while we didn't find a quest to show an icon for
			if questFound then
				break
			end
			
			local line = tooltipData.lines[i]
			TooltipUtil.SurfaceArgs(line)
			
			if line then
				local text = line.leftText
				
				if moduleFrame.QuestByTitle[text] then
					local qInfo = moduleFrame.QuestByTitle[text]
					
					if qInfo.title and qInfo.questID then
						local isDone = isQuestComplete(nil, qInfo.questID)
						
						if not isDone then
						
							if qInfo and qInfo.tagInfo and qInfo.tagInfo.worldQuestType then
								questType = 2 --world quest
								
								local progress = C_TaskQuest.GetQuestProgressBarInfo(qInfo.questID)
								if progress then
									questType = 3 -- progress bar world type quest
								end
								
							else
								if C_QuestLog.IsQuestTask(qInfo.questID) then
									questType = 4 -- it's a Bonus Objective
								else
									questType = 1 --regular quest
								end
							end
							
							--if we found something then break out of the tooltip for loop scanning
							if questType > 0 then
								questFound = true
							end
							
						end
						
					end
					
				end
				
			end
			
		end

	end
	
	--do the quest icon
	if questType > 0 and iconQuest then

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
			iconQuest:SetVertexColor(1, 181/255, 17/255, 0.9) --show a lighter orange almost gold color
		end
		
		iconQuest:Show()
		return --return so not to Hide below
	end
	
	if iconQuest then iconQuest:Hide() end
end

local function OnTooltipSetUnit(tooltip, tooltipData)
	local npHooks = addon["nameplateHooks"]
	if not npHooks then return end
	if not tooltipData or not tooltipData.guid then return end
	
	local plate, f = npHooks:GetPlateForGUID(tooltipData.guid)
	if f and f._unitID then
		UpdateQuestIcon(f, plate, f._unitID, tooltipData)
	end
end

function moduleFrame:UpdateAllQuestIcons(trigger)
	local npHooks = addon["nameplateHooks"]
	if not npHooks then return end
	
	--make sure we have quest data to work with
	if not moduleFrame.scannedQuestLog then
		moduleFrame.scannedQuestLog = true
		DoQuestLogCache(true)
	end
	
	for plate, f in pairs(npHooks:GetActiveNameplates()) do
		UpdateQuestIcon(f, plate, f._unitID)
	end
end

----------------------------------------------
----- QUEST EVENTS
----------------------------------------------

function moduleFrame:QUEST_LOG_UPDATE()
	if moduleFrame.updateQuestLog then
		moduleFrame.updateQuestLog = false

		for questID, qTitle in pairs(moduleFrame.QuestsToUpdate) do
			local qObj = moduleFrame.QuestByTitle[qTitle]
			if not qObj then
				CacheQuestByQuestID(questID)
			end
			moduleFrame.QuestsToUpdate[questID] = nil
		end
		
		moduleFrame:UpdateAllQuestIcons("QUEST_LOG_UPDATE")
	end

	if not moduleFrame.scannedQuestLog then
		moduleFrame.scannedQuestLog = true
		DoQuestLogCache(true)
	end
end

function moduleFrame:QUEST_ACCEPTED(event, questID)
	CacheQuestByQuestID(questID)
	if moduleFrame.QuestByID[questID] == "UpdatePending" then
		C_QuestLog.RequestLoadmoduleFrame.QuestByID(questID)
	end
	--possibly need to update icons when a quest is accepted, need to see if triggers QUEST_LOG_UPDATE
end

function moduleFrame:QUEST_REMOVED(event, questID)
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
	local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	if questIndex then
		local qInfo = C_QuestLog.GetInfo(questIndex)
		if qInfo and qInfo.title then
			moduleFrame.QuestsToUpdate[questID] = qInfo.title
		end
	end
end

function moduleFrame:UNIT_QUEST_LOG_CHANGED(event, unitID)
	if unitID == "player" then
		moduleFrame.updateQuestLog = true
	end
end

function moduleFrame:UI_SCALE_CHANGED()
	if not moduleFrame.scannedQuestLog then
		moduleFrame.scannedQuestLog = true
		DoQuestLogCache(true)
	end
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
	if f[iconQuest] then
		f[iconQuest]:Hide()
	end
end

----------------------------------------------
----- ADDON ENABLE
----------------------------------------------

local function EnableQuestIcons()
	if not addon.IsRetail then return end
	
	moduleFrame:RegisterEvent("QUEST_LOG_UPDATE")
	moduleFrame:RegisterEvent("QUEST_ACCEPTED")
	moduleFrame:RegisterEvent("QUEST_REMOVED")
	moduleFrame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
	moduleFrame:RegisterEvent("QUEST_WATCH_UPDATE")
	moduleFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
	moduleFrame:RegisterEvent("UI_SCALE_CHANGED")

	moduleFrame:RegisterEvent("PLAYER_ENTERING_WORLD", function() moduleFrame:UpdateAllQuestIcons("PLAYER_ENTERING_WORLD") end)
	moduleFrame:RegisterMessage('XANUI_ON_NEWPLATE')
	moduleFrame:RegisterMessage('XANUI_ON_PLATESHOW')
	moduleFrame:RegisterMessage('XANUI_ON_PLATEHIDE')
	
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableQuestIcons, name=moduleName } )