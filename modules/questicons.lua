local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "questicons"
 
local iconKey = ADDON_NAME .. "QuestIcon"
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local ICON_PATH = "Interface\\AddOns\\"..ADDON_NAME.."\\media\\questicon_1"

local function CanAccessObject(obj)
	return issecure() or not obj:IsForbidden()
end

local function isObjSafe(obj, checkInstance)
	local inInstance, instanceType = IsInInstance()
	if C_PvP.IsArena() then return false end
	if checkInstance and inInstance then return false end --you can't modify plates while in instances, it will cause errors and taint issues.
	if not CanAccessObject(obj) then return false end --check if you can even touch the plate
	return true
end

local function UpdateQuestIcon(namePlate, unit)
	if not isObjSafe(namePlate) then return end
	if not XanUIDB then return end

end
 
local function UpdateAllQuestIcons()
    local nameplates = C_NamePlate.GetNamePlates()
    for index = 1, #nameplates do
        UpdateQuestIcon(nameplates[index], nameplates[index].namePlateUnitToken)
    end
end
 
local function EnableQuestIcons()
	if not addon.IsRetail then return end
	
	-- addon[moduleName.."Frame"] = CreateFrame("Frame")
	-- local frame = addon[moduleName.."Frame"]
	 
	-- frame:SetScript("OnEvent", function(self, event, unit)
		-- if event == "NAME_PLATE_UNIT_ADDED" then
			-- local namePlate = GetNamePlateForUnit(unit)
			-- UpdateQuestIcon(namePlate, unit)
		-- elseif event == "NAME_PLATE_UNIT_REMOVED" then
			-- local namePlate = GetNamePlateForUnit(unit)
			-- if namePlate[iconKey] then
				-- namePlate[iconKey]:Hide()
			-- end
		-- elseif event == "PLAYER_ENTERING_WORLD" then
			-- UpdateAllQuestIcons()
		-- end
	-- end)
	 
	-- frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	-- frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	-- frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	-- frame:RegisterEvent("PLAYER_ENTERING_WORLD")
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableQuestIcons, name=moduleName } )