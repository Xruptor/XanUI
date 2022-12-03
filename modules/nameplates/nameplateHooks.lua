local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "nameplateHooks"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
LibStub("AceEvent-3.0"):Embed(moduleFrame)

local Nameplates = {}
local ActiveNameplates = {}
local GUIDs = {}

local function CanAccessObject(obj)
	if not obj then return false end
	return issecure() or (obj.IsForbidden and not obj:IsForbidden()) or false
end

local function isObjSafe(obj, checkInstance)
	local inInstance, instanceType = IsInInstance()
	if C_PvP.IsArena() then return false end
	if checkInstance and inInstance then return false end --you can't modify plates while in instances, it will cause errors and taint issues.
	if not CanAccessObject(obj) then return false end --check if you can even touch the plate
	return true
end

function moduleFrame:GetActiveNameplates()
	return ActiveNameplates
end

function moduleFrame:GetFrameFromNameplate(plate)
	return Nameplates[plate]
end

function moduleFrame:GetPlateForUnit(unitID)
	local plate, f = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	if plate then
		f = Nameplates[plate]
	end
	return plate, f
end

function moduleFrame:GetUnitForPlate(plate)
	return Nameplates[plate] and Nameplates[plate]._unitID
end

function moduleFrame:GetPlateForGUID(guid)
	local plate = GUIDs[guid]
	if plate then
		return plate, ActiveNameplates[plate]
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
	Nameplates[plate] = f
	plate._frame = f

	moduleFrame:SendMessage('XANUI_ON_NEWPLATE', f, plate)
end
	
function moduleFrame:NAME_PLATE_UNIT_ADDED(event, unitID)
	local plate = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	if not plate then return end
	
	local f = Nameplates[plate]
	if not f then return end
	
	ActiveNameplates[plate] = f
	f._unitID = unitID
	
	local guid = UnitGUID(unitID)
	if guid then
		GUIDs[guid] = plate
	end
	
	moduleFrame:SendMessage('XANUI_ON_PLATESHOW', f, plate, unitID)
end

function moduleFrame:NAME_PLATE_UNIT_REMOVED(event, unitID)
	local plate = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	if not plate then return end
	
	local f = Nameplates[plate]
	if not f then return end
	
	ActiveNameplates[plate] = nil
	
	local guid = UnitGUID(unitID)
	if guid then
		GUIDs[guid] = nil
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
