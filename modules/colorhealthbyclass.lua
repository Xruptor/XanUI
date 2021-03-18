local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "colorhealthbyclass"

local function colour(statusbar, unit)
	if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
		if not addon.CanAccessObject(statusbar) then return end
		local _, class = UnitClass(unit)
		local c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		statusbar:SetStatusBarColor(c.r, c.g, c.b)
	end
end

hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
	colour(self, self.unit)
end)

local sb = _G.GameTooltipStatusBar
local colorEventFrame = CreateFrame("Frame", "StatusColour")
colorEventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
colorEventFrame:SetScript("OnEvent", function()
	colour(sb, "mouseover")
end)
