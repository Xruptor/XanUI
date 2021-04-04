local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "soundalerts"

local eventFrame = CreateFrame("frame", ADDON_NAME.."_"..moduleName, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, event, ...)
	end
end)

eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
	
--only play the sound once during low health/mana then reset
local lowHealth = false
local lowMana = false

--edit these to your liking
local lowHealthThreshold = 0.35 --set the percentage threshold for low health
local lowManaThreshold = 0.35 --set the percentage threshold for low mana
local lowOtherThreshold = 0.35 --set the percentage threshold

function eventFrame:UNIT_HEALTH()
	if ((UnitHealth("player") / UnitHealthMax("player")) <= lowHealthThreshold) then
		if (not lowHealth) then
			PlaySoundFile("Interface\\AddOns\\xanUI\\sounds\\LowHealth.ogg", "Master")
			lowHealth = true
		end
	else
		lowHealth = false
	end
end

function eventFrame:UNIT_POWER_UPDATE(event, unit, powerType)
	if unit ~= "player" then return end

	if powerType == "MANA" then
		if ((UnitPower("player", Enum.PowerType.Mana) / UnitPowerMax("player", Enum.PowerType.Mana)) <= lowManaThreshold) then
			if (not lowMana) then
				PlaySoundFile("Interface\\AddOns\\xanUI\\sounds\\LowMana.ogg", "Master")
				lowMana = true
				return
			end
		else
			lowMana = false
		end
	end
	
end
