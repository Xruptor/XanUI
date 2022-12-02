--[[
	NOTE: This is my personal UI modifications.  It's not meant for the general public.
	Don't say I didn't warn you!
--]]

local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

addon.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
addon.moduleFuncs = {}

local debugf = tekDebug and tekDebug:GetFrame(ADDON_NAME)
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		if event == "ADDON_LOADED" then
			local arg1 = ...
			if arg1 and arg1 == ADDON_NAME then
				self:UnregisterEvent("ADDON_LOADED")
				self:RegisterEvent("PLAYER_LOGIN")
			end
			return
		end
		if IsLoggedIn() then
			self:EnableAddon(event, ...)
			self:UnregisterEvent("PLAYER_LOGIN")
		end
		return
	end
	if self[event] then
		return self[event](self, event, ...)
	end
end)

function addon.CanAccessObject(obj)
	return issecure() or not obj:IsForbidden();
end

function XanUI_SlashCommand(cmd)

	local a,b,c=strfind(cmd, "(%S+)"); --contiguous string of non-space characters
	
	if a then
		if c and c:lower() == "showrace" then
			if XanUIDB.showRaceIcon then
				XanUIDB.showRaceIcon = false
			else
				XanUIDB.showRaceIcon = true
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - is now [|cFF20ff20"..tostring(XanUIDB.showRaceIcon).."|r].")
			return true
		elseif c and c:lower() == "gendericon" then
			if XanUIDB.showGenderIcon then
				XanUIDB.showGenderIcon = false
			else
				XanUIDB.showGenderIcon = true
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - is now [|cFF20ff20"..tostring(XanUIDB.showGenderIcon).."|r].")
			return true
		elseif c and c:lower() == "gendertext" then
			if XanUIDB.showGenderText then
				XanUIDB.showGenderText = false
			else
				XanUIDB.showGenderText = true
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - is now [|cFF20ff20"..tostring(XanUIDB.showGenderText).."|r].")
			return true
		elseif c and c:lower() == "onlydrac" then
			if XanUIDB.onlyDracthyr then
				XanUIDB.onlyDracthyr = false
			else
				XanUIDB.onlyDracthyr = true
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - is now [|cFF20ff20"..tostring(XanUIDB.onlyDracthyr).."|r].")
			return true
		elseif c and c:lower() == "showquests" then
			if XanUIDB.showQuests then
				XanUIDB.showQuests = false
			else
				XanUIDB.showQuests = true
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - is now [|cFF20ff20"..tostring(XanUIDB.showQuests).."|r].")
			return true
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME, 64/255, 224/255, 208/255)
	DEFAULT_CHAT_FRAME:AddMessage("/xanui showrace - Toggles showing the race icon.")
	DEFAULT_CHAT_FRAME:AddMessage("/xanui gendericon - Toggles showing the gender icon.")
	DEFAULT_CHAT_FRAME:AddMessage("/xanui gendertext - Toggles showing the gender text.")
	DEFAULT_CHAT_FRAME:AddMessage("/xanui onlydrac - Toggles showing gender icon/text for Dracthyr only.")
	DEFAULT_CHAT_FRAME:AddMessage("/xanui showquests - Toggles showing quest icons.")
end

function addon:EnableAddon()

	if not XanUIDB then XanUIDB = {} end
	
	if XanUIDB.showRaceIcon == nil then XanUIDB.showRaceIcon = false end
	if XanUIDB.showGenderIcon == nil then XanUIDB.showGenderIcon = false end
	if XanUIDB.showGenderText == nil then XanUIDB.showGenderText = true end
	if XanUIDB.onlyDracthyr == nil then XanUIDB.onlyDracthyr = true end
	if XanUIDB.showQuests == nil then XanUIDB.showQuests = true end
	
	local ver = GetAddOnMetadata("xanUI","Version") or 0
		
	
	if addon.IsRetail then
	
		-- Always show missing transmogs in tooltips
		C_CVar.SetCVar("missingTransmogSourceInItemTooltips", "1")

		--mute ban-lu monk mount
		MuteSoundFile(1593212)
		MuteSoundFile(1593212)
		MuteSoundFile(1593213)	
		MuteSoundFile(1593214)	
		MuteSoundFile(1593215)	
		MuteSoundFile(1593216)
		MuteSoundFile(1593217)	
		MuteSoundFile(1593218)
		MuteSoundFile(1593219)
		MuteSoundFile(1593220)	
		MuteSoundFile(1593221)
		MuteSoundFile(1593222)
		MuteSoundFile(1593223)
		MuteSoundFile(1593224)
		MuteSoundFile(1593225)
		MuteSoundFile(1593226)
		MuteSoundFile(1593227)
		MuteSoundFile(1593228)	
		MuteSoundFile(1593229)
		MuteSoundFile(1593236)
		
		--disable stupid interupt/fizzle global cooldown sounds when casting
		--REALLY annoying especially when playing Arcane Mage
		local sounds = {
			569772, -- sound/spells/fizzle/fizzleholya.ogg
			569773, -- sound/spells/fizzle/fizzlefirea.ogg
			569774, -- sound/spells/fizzle/fizzlenaturea.ogg
			569775, -- sound/spells/fizzle/fizzlefrosta.ogg
			569776, -- sound/spells/fizzle/fizzleshadowa.ogg
			613892, -- sound/spells/fizzle/fizzlejadea.ogg  jade fizzle
		}

		for _, fdid in pairs(sounds) do
			MuteSoundFile(fdid)
		end
		
		--mute Chordy from shadowlands
		--MuteSoundFile(3719073)  --Lets find shinies
		
		--Hostile, Quest, and Interactive NPCs:
		C_CVar.SetCVar("UnitNameFriendlySpecialNPCName", "1")
		C_CVar.SetCVar("UnitNameHostleNPC", "1")
		C_CVar.SetCVar("UnitNameInteractiveNPC", "1")
		C_CVar.SetCVar("ShowQuestUnitCircles", "1")

	end
	
	--force Numeric for healthbar fix
	C_CVar.SetCVar("statusText","1")
	C_CVar.SetCVar("statusTextDisplay","NUMERIC")
	C_CVar.SetCVar("nameplateShowAll", 1) -- always show the nameplates (combat/noncombat)
	C_CVar.SetCVar("nameplateShowFriends", 1) -- show for friendly units
	C_CVar.SetCVar("nameplateShowEnemies", 1) -- Enemy
	C_CVar.SetCVar("nameplateShowEnemyMinus", 1) -- Enemy Minors
	C_CVar.SetCVar("nameplateMaxDistance", 100) --default 60
	C_CVar.SetCVar("UnitNameNPC", "0") --this is necessary as part of the (Hostile, Quest, and Interactive NPCs) group
	C_CVar.SetCVar("UnitNameFriendlyPlayerName", "1")
	C_CVar.SetCVar("UnitNameFriendlyMinionName", "1")
	C_CVar.SetCVar("UnitNameEnemyPlayerName", "1")
	C_CVar.SetCVar("UnitNameEnemyMinionName", "1")

	--NOW LOAD ALL THE MODULES
	for i=1, #addon.moduleFuncs do
		if addon.moduleFuncs[i].func then
			addon.moduleFuncs[i].func()
		end
	end

	SLASH_XANUI1 = "/xui";
	SLASH_XANUI2 = "/xanui";
	SlashCmdList["XANUI"] = XanUI_SlashCommand;
	
	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [v|cFF20ff20"..ver.."|r]   /xanui, /xui")
end
