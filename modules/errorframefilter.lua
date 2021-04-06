local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "errorframefilter"

local eventFrame = CreateFrame("frame", ADDON_NAME.."_"..moduleName, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, event, ...)
	end
end)

local blacklist = {
	["ERR_ABILITY_COOLDOWN"] = true,           -- Ability is not ready yet. (Ability)
	["ERR_ITEM_COOLDOWN"] = false,				-- Item is not ready yet
	["ERR_BADATTACKPOS"] = true, 				-- You are too far away!
	["ERR_OUT_OF_ENERGY"] = true,              -- Not enough energy. (Err)
	["ERR_OUT_OF_RANGE"] = true, 				-- Out of range.
	["ERR_OUT_OF_RAGE"] = true,                -- Not enough rage.
	["ERR_OUT_OF_FOCUS"] = true,                -- Not enough focus
	["ERR_NO_ATTACK_TARGET"] = true,           -- There is nothing to attack.
	["SPELL_FAILED_MOVING"] = false,
	["SPELL_FAILED_AFFECTING_COMBAT"] = true, 	--You are in combat
	["ERR_NOT_IN_COMBAT"] = false, 				--You can't do that while in combat  (Not on by default)
	["SPELL_FAILED_UNIT_NOT_INFRONT"] = true, 	--Target needs to be in front of you
	["ERR_BADATTACKFACING"] = true, 				-- You are facing the wrong way!
	["SPELL_FAILED_TOO_CLOSE"] = true, 			--Target to close.
	["ERR_INVALID_ATTACK_TARGET"] = true,      -- You cannot attack that target.
	["ERR_SPELL_COOLDOWN"] = true,             -- Spell is not ready yet. (Spell)
	["SPELL_FAILED_NO_COMBO_POINTS"] = true,   -- That ability requires combo points.
	["SPELL_FAILED_TARGETS_DEAD"] = true,      -- Your target is dead.
	["SPELL_FAILED_SPELL_IN_PROGRESS"] = true, -- Another action is in progress. (Spell)
	["SPELL_FAILED_TARGET_AURASTATE"] = false,  -- You can't do that yet. (TargetAura)
	["SPELL_FAILED_CASTER_AURASTATE"] = true,  -- You can't do that yet. (CasterAura)
	["SPELL_FAILED_NO_ENDURANCE"] = true,      -- Not enough endurance
	["SPELL_FAILED_BAD_TARGETS"] = true,       -- Invalid target
	["SPELL_FAILED_NOT_MOUNTED"] = false,       -- You are mounted
	["SPELL_FAILED_NOT_ON_TAXI"] = false,       -- You are in flight
	
	["ERR_OUT_OF_MANA"] = true, -- Not enough mana
	["ERR_OUT_OF_HEALTH"] = true, -- Not enough health
	["ERR_OUT_OF_RUNES"] = true, --Not enough runes
	["ERR_OUT_OF_RUNIC_POWER"] = true, --Not enough runic power
	["ERR_OBJECT_IS_BUSY"] = false, -- That object is busy.   (Not on by default)
	["ERR_USE_TOO_FAR"] = true, --You are too far away.
	["ERR_NOEMOTEWHILERUNNING"] = false, --You can't do that while moving!
	["ERR_NOT_WHILE_SHAPESHIFTED"] = false, --You can't do that while shapeshifted.   (Not on by default)
	["ERR_SPELL_OUT_OF_RANGE"] = true, --Out of range.
	["ERR_ATTACK_FLEEING"] = true, --Can't attack while fleeing.
	["ERR_ATTACK_CHARMED"] = true, --Can't attack while charmed.
	["ERR_ATTACK_CONFUSED"] = true, --Can't attack while confused.
	["ERR_ATTACK_DEAD"] = true, --Can't attack while dead.
	["ERR_ATTACK_PACIFIED"] = true, --Can't attack while pacified.
	["ERR_ATTACK_STUNNED"] = true, --Can't attack while stunned.
	["ERR_GENERIC_NO_TARGET"] = true, --You have no target.
	["SPELL_FAILED_NOT_BEHIND"] = true, --You must be behind your target
	["SPELL_FAILED_TARGET_FRIENDLY"] = false, --target is friendly,
	["ERR_POTION_COOLDOWN"] = false, --You cannot drink any more yet.
	["ERR_PET_SPELL_OUT_OF_RANGE"] = false, --Your pet is out of range.
}

--disable default error message
UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
--add our custom event tracker
eventFrame:RegisterEvent("UI_ERROR_MESSAGE")

function eventFrame:UI_ERROR_MESSAGE(event, messageType, message)
	local errorName, soundKitID, voiceID = GetGameMessageInfo(messageType)
	if blacklist[errorName] then return end
	UIErrorsFrame:AddMessage(message, 1, .1, .1)
end

