-------------------------------------
-- Stripped core from SemlarPlates
-------------------------------------

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
--don't run this if it's not retail
if not IsRetail then return end

local addonName, addon = ...
local E = addon:Eve()
local Nameplates = {} -- [plate] = f, holds all nameplate frames
local ActiveNameplates = {} -- [plate] = f, only stores currently visible nameplates
local GUIDs = {} -- [guid] = plate

local function isObjSafe(obj)
	local inInstance, instanceType = IsInInstance()
	if inInstance then return false end --you can't modify plates while in instances, it will cause errors and taint issues.
	if not CanAccessObject(obj) then return false end --check if you can even touch the plate
	return true
end

function addon:GetActiveNameplates()
	return ActiveNameplates
end

function addon:GetFrameFromNameplate(plate)
	return Nameplates[plate]
end

function addon:GetPlateForUnit(unitID)
	local plate, f = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	if plate then
		f = Nameplates[plate]
	end
	return plate, f
end

function addon:GetUnitForPlate(plate)
	return Nameplates[plate] and Nameplates[plate]._unitID
end

function addon:GetPlateForGUID(guid)
	local plate = GUIDs[guid]
	if plate then
		return plate, ActiveNameplates[plate]
	end
end

function E:NAME_PLATE_CREATED(plate)
	--if a plate is restricted and cannot be used, lets avoid taints and errors
	--https://www.wowinterface.com/forums/showthread.php?t=56125
	if not isObjSafe(plate) then return end
	local f = CreateFrame('frame', nil, plate)
	f:SetAllPoints()
	Nameplates[plate] = f
	plate._frame = f
	E('OnNewPlate', f, plate)
end

function E:NAME_PLATE_UNIT_ADDED(unitID)
	local plate = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	local f = Nameplates[plate]
	ActiveNameplates[plate] = f
	f._unitID = unitID
	
	local guid = UnitGUID(unitID)
	if guid then
		GUIDs[guid] = plate
	end
	
	E('OnPlateShow', f, plate, unitID)
end

function E:NAME_PLATE_UNIT_REMOVED(unitID)
	local plate = C_NamePlate.GetNamePlateForUnit(unitID)
	if not isObjSafe(plate) then return end
	local f = Nameplates[plate]
	ActiveNameplates[plate] = nil
	
	local guid = UnitGUID(unitID)
	if guid then
		GUIDs[guid] = nil
	end
	
	E('OnPlateHide', f, plate, unitID)
end