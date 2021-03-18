local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "classic_colorednameplates"

--colored nameplates for WOW Classic
local RAID_CLASS_COLORS, FACTION_BAR_COLORS = RAID_CLASS_COLORS, FACTION_BAR_COLORS

local function ClassicNameplateUpdateColor(self)
	local unit = self.unit
	if not unit then return end
	if not string.find(unit, 'nameplate') then return end

	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if not nameplate then return end
		
	local r,g,b
	if UnitIsUnit(unit.."target", "player") then
		r,g,b = 0,1,0
	elseif UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		local color = RAID_CLASS_COLORS[class]
		r, g, b = color.r, color.g, color.b
	elseif CompactUnitFrame_IsTapDenied(self) then
		r, g, b = 0.9, 0.9, 0.9
	else
		local color = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		r, g, b = color.r, color.g, color.b
	end
	self.healthBar:SetStatusBarColor(r,g,b)
end


local function EnableClassicColoredNameplates()
	if addon.IsRetail then return end
	
	--it's WOW classic
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ClassicNameplateUpdateColor)
	hooksecurefunc("CompactUnitFrame_UpdateHealth", ClassicNameplateUpdateColor)
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableClassicColoredNameplates } )

