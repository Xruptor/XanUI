local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "addmissingstats"

--don't really want to show all stats but use this as a guideline
--[[ function xanUI_ShowAllStats()
	PAPERDOLL_STATCATEGORIES= {
		[1] = {
			categoryFrame = "AttributesCategory",
			stats = {
				[1] = { stat = "HEALTH" },
				[2] = { stat = "POWER" },
				[3] = { stat = "ALTERNATEMANA" },
				[5] = { stat = "ARMOR" },
				[6] = { stat = "STRENGTH" },
				[7] = { stat = "AGILITY" },
				[8] = { stat = "INTELLECT" },
				[9] = { stat = "STAMINA" },
				[10] = { stat = "ATTACK_DAMAGE" },
				[11] = { stat = "ATTACK_AP" },
				[12] = { stat = "ATTACK_ATTACKSPEED" },
				[13] = { stat = "SPELLPOWER" },
				[14] = { stat = "MANAREGEN", hideAt = 0 },
				[15] = { stat = "ENERGY_REGEN", hideAt = 0 },
				[16] = { stat = "RUNE_REGEN", hideAt = 0 },
				[17] = { stat = "FOCUS_REGEN", hideAt = 0 },
				[18] = { stat = "MOVESPEED" },
				[19] = { stat = "DURABILITY" },
				[20] = { stat = "REPAIRTOTAL" },
				[21] = { stat = "ITEMLEVEL" },
			},
		},
		[2] = {
			categoryFrame = "EnhancementsCategory",
			stats = {
				[1] = { stat = "CRITCHANCE" },
				[2] = { stat = "HASTE" },
				[3] = { stat = "VERSATILITY" },
				[4] = { stat = "MASTERY" },
				[5] = { stat = "LIFESTEAL" },
				[6] = { stat = "AVOIDANCE" },
				[7] = { stat = "DODGE" },
				[8] = { stat = "PARRY" },
				[9] = { stat = "BLOCK" },
			},
		},
	};
	PaperDollFrame_UpdateStats();
end ]]

local function EnableInsertStats()
	if not addon.IsRetail then return end

	local _, playerClass = UnitClass("player")

	--1 is the top category with intellect and such, 2 is the second category
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "ATTACK_DAMAGE" });
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "ATTACK_AP" });
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "SPELLPOWER" });

end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableInsertStats, name=moduleName } )
