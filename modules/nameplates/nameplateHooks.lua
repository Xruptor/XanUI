local ADDON_NAME, private = ...
local addon = private and private.GetAddonFrame and private:GetAddonFrame(ADDON_NAME) or _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local moduleName = "nameplateHooks"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
addon:EmbedEvents(moduleFrame)

local Nameplates = {}
local ActiveNameplates = {}
local GUIDs = {}

local IsInInstance = IsInInstance
local IsArena = (C_PvP and C_PvP.IsArena) or function() return false end
local Util = addon and addon.Util
local SafeIndex = (Util and Util.SafeIndex) or function(t, k)
	if not t then return nil end
	local ok, value = pcall(function() return t[k] end)
	if ok then return value end
	return nil
end
local SafeSet = (Util and Util.SafeSet) or function(t, k, v)
	if not t then return false end
	local ok = pcall(function() t[k] = v end)
	return ok
end
local CanAccessValue = (Util and Util.CanAccessValue) or function(_) return true end

local function CanAccessObject(obj)
	if not obj then return false end
	if not CanAccessValue(obj) then return false end
	return issecure() or (obj.IsForbidden and not obj:IsForbidden()) or false
end

local function isObjSafe(obj, checkInstance)
	local inInstance = IsInInstance()
	if IsArena() then return false end
	if checkInstance and inInstance then return false end --you can't modify plates while in instances, it will cause errors and taint issues.
	if not CanAccessObject(obj) then return false end --check if you can even touch the plate
	return true
end

function moduleFrame:GetActiveNameplates()
	return ActiveNameplates
end

function moduleFrame:GetFrameFromNameplate(plate)
	if not CanAccessValue(plate) then return end
	return SafeIndex(Nameplates, plate)
end

function moduleFrame:GetPlateForUnit(unitID)
	local plate, f = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	if plate then
		if not CanAccessValue(plate) then return end
		f = SafeIndex(Nameplates, plate)
	end
	return plate, f
end

function moduleFrame:GetUnitForPlate(plate)
	if not CanAccessValue(plate) then return end
	local f = SafeIndex(Nameplates, plate)
	return f and f._unitID
end

function moduleFrame:GetPlateForGUID(guid)
	if not CanAccessValue(guid) then return end
	local plate = SafeIndex(GUIDs, guid)
	if plate then
		if not CanAccessValue(plate) then return end
		return plate, SafeIndex(ActiveNameplates, plate)
	end
end

function moduleFrame:NAME_PLATE_CREATED(event, plate)
	--if a plate is restricted and cannot be used, lets avoid taints and errors
	--https://www.wowinterface.com/forums/showthread.php?t=56125
	if not isObjSafe(plate) then return end

	--okay so instead of actually touching the nameplate, we are going to create our own overlay frame that we will use instead
	--this will prevent taints and tampering with the nameplate and still allow us to put stuff on it.
	local f = CreateFrame('frame', nil, plate)
	f:SetAllPoints()
	SafeSet(Nameplates, plate, f)
	plate._frame = f

	moduleFrame:SendMessage('XANUI_ON_NEWPLATE', f, plate)
end

function moduleFrame:NAME_PLATE_UNIT_ADDED(event, unitID)
	local plate = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	if not plate then return end

	if not CanAccessValue(plate) then return end
	local f = SafeIndex(Nameplates, plate)
	if not f then return end

	SafeSet(ActiveNameplates, plate, f)
	f._unitID = unitID

	local guid = UnitGUID(unitID)
	if guid and CanAccessValue(guid) then
		SafeSet(GUIDs, guid, plate)
	end

	moduleFrame:SendMessage('XANUI_ON_PLATESHOW', f, plate, unitID)
end

function moduleFrame:NAME_PLATE_UNIT_REMOVED(event, unitID)
	local plate = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	if not plate then return end

	if not CanAccessValue(plate) then return end
	local f = SafeIndex(Nameplates, plate)
	if not f then return end

	SafeSet(ActiveNameplates, plate, nil)

	local guid = UnitGUID(unitID)
	if guid and CanAccessValue(guid) then
		SafeSet(GUIDs, guid, nil)
	end

	moduleFrame:SendMessage('XANUI_ON_PLATEHIDE', f, plate, unitID)
end

local function EnableNamePlateHooks()
	if not addon.IsRetail then return end

	moduleFrame:RegisterEvent("NAME_PLATE_CREATED")
	moduleFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	moduleFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableNamePlateHooks, name=moduleName } )
