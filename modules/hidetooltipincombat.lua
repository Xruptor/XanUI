local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "hidetooltipincombat"
local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local playerQuests = {}
local auraSwitch = false

--settings to show auras or quests in tooltip
local showAuras = true
local showQuestObj = true
	
--trigger quest scans
local triggers = {
	["QUEST_COMPLETE"] = true,
	["UNIT_QUEST_LOG_CHANGED"] = true,
	["QUEST_WATCH_UPDATE"] = true,
	["QUEST_FINISHED"] = true,
	["QUEST_LOG_UPDATE"] = true,
}

local ignoreFrames = {
	["TemporaryEnchantFrame"] = true,
	["QuestInfoRewardsFrame"] = true,
	["MinimapCluster"] = true,
}
--add the loot frames
for i=1, NUM_GROUP_LOOT_FRAMES do
	ignoreFrames["GroupLootFrame" .. i] = true
end

local function CanAccessObject(obj)
	return issecure() or not obj:IsForbidden();
end

local function doQuestTitleGrab()
	playerQuests = {}

	if IsRetail then
		for i=1, C_QuestLog.GetNumQuestLogEntries() do
			local questInfo = C_QuestLog.GetInfo(i)
			
			if questInfo.title and not questInfo.isHeader then
				playerQuests[questInfo.title] = questInfo.title
			end
		end
	
	else
		for i=1, GetNumQuestLogEntries() do
			local questTitle, _, _, _, isHeader = GetQuestLogTitle(i)
			
			if questTitle and not isHeader then
				playerQuests[questTitle] = questTitle
			end
		end
	end
	
end

local eventFrame = CreateFrame("frame", ADDON_NAME.."_"..moduleName, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	--CUSTOM EVENTFRAME FOR THIS MODULE
	if self[event] then 
		return self[event](self, event, ...)
	elseif triggers[event] then
		doQuestTitleGrab()
	end 
end)

eventFrame:RegisterEvent("QUEST_COMPLETE")
eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
eventFrame:RegisterEvent("QUEST_WATCH_UPDATE")
eventFrame:RegisterEvent("QUEST_FINISHED")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")

----------------------
--      Enable      --
----------------------

local function processAuraTooltip(self, unitid, index, filter)
	if unitid == "player" then
		auraSwitch = true
		return
	end
	auraSwitch = false
end

local function checkPlayerQuest()
	for i=1,GameTooltip:NumLines() do
		local ttText = getglobal("GameTooltipTextLeft" .. i)
		if ttText and ttText:GetText() and playerQuests[ttText:GetText()] then
			return true
		end
	end
	return false
end

local function CheckInCombatLockdown()
	return InCombatLockdown() or UnitAffectingCombat("player")
end

local function CheckTooltipStatus(tooltip, unit)
	if not tooltip then return end
	if not InCombatLockdown() then return end

	--there are lots of taints involved with GameTooltip and NameplateTooltip since 7.2
	--https://us.battle.net/forums/en/wow/topic/20759156905
	--https://eu.battle.net/forums/en/wow/topic/17620312302
	if not CanAccessObject(tooltip) then return end
	
	--this is for the special buffs/debuffs icons above the nameplates, units are nameplate1, nameplate2, etc...
	if unit and string.find(unit, "nameplate") then
		tooltip:Hide()
		return
	end
	if tooltip == NamePlateTooltip then return end  --we really don't want to do anything else with nameplate

	local owner = tooltip:GetOwner()
	local ownerName = owner and owner:GetParent() and owner:GetParent():GetName()

	if showAuras then
		if auraSwitch then return end
		if ownerName and ownerName == "BuffFrame" then return end
	end
	
	if showQuestObj and checkPlayerQuest() then return end
	if ownerName and ignoreFrames[ownerName] then return end
	
	if not IsShiftKeyDown() then
		tooltip:Hide()
	end
end

local function EnableHideTooltipInCombat()

	doQuestTitleGrab()
	
	GameTooltip:HookScript("OnShow", function(objTooltip)
		CheckTooltipStatus(objTooltip)
	end)
	
	GameTooltip:HookScript("OnUpdate", function(objTooltip, elapsed)
		CheckTooltipStatus(objTooltip)
	end)
	
	--check if it's one of those new small buff icons that show ontop of the target mob nameplate
	hooksecurefunc(GameTooltip,"SetUnitAura",function(objTooltip, unit, index, filter)
		processAuraTooltip(objTooltip, unit, index, filter)
		CheckTooltipStatus(objTooltip, unit)
	end)

	GameTooltip:HookScript("OnHide", function(self)
		auraSwitch = false
	end)
	
	hooksecurefunc(GameTooltip, "SetUnitBuff", processAuraTooltip)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", processAuraTooltip)
	
	-------
	-------NamePlateTooltip
	-------
	
	--NamePlateTooltip that shows above nameplate with the buff/debuffs
	--check if it's one of those new small buff icons that show ontop of the target mob nameplate
	hooksecurefunc(NamePlateTooltip,"SetUnitAura",function(objTooltip, unit, index, filter)
		CheckTooltipStatus(objTooltip, unit)
	end)

end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableHideTooltipInCombat } )
