--[[
	NOTE: This is my personal UI modifications.  It's not meant for the general public.
	Don't say I didn't warn you!
--]]

local ADDON_NAME, private = ...
if type(private) ~= "table" then
	private = {}
end
local L = private.L or setmetatable({}, { __index = function(_, key) return key end })

if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
local addon = _G[ADDON_NAME]
addon.private = private
addon.L = L

local function EnsureEventDispatcher(target)
	if target._xanui_events then return end
	target._xanui_events = {}
	target._xanui_rawRegisterEvent = target.RegisterEvent
	target._xanui_rawUnregisterEvent = target.UnregisterEvent
	target._xanui_rawUnregisterAllEvents = target.UnregisterAllEvents

	target:SetScript("OnEvent", function(self, event, ...)
		local handlers = self._xanui_events and self._xanui_events[event]
		if not handlers then return end
		for i = 1, #handlers do
			local h = handlers[i]
			if h.passSelf then
				local fn = h.fn
				if type(fn) == "string" then
					fn = self[fn]
				end
				if fn then
					fn(self, event, ...)
				end
			else
				if type(h.fn) == "string" then
					local method = self[h.fn]
					if method then
						method(self, event, ...)
					end
				elseif h.fn then
					h.fn(event, ...)
				end
			end
		end
	end)
end

function addon:EmbedEvents(target)
	if target._xanui_events_embedded then return end
	target._xanui_events_embedded = true

	EnsureEventDispatcher(target)
	addon._xanui_messageHandlers = addon._xanui_messageHandlers or {}

	target.RegisterEvent = function(self, event, callback)
		if not event then return end
		local handlers = self._xanui_events[event]
		if not handlers then
			handlers = {}
			self._xanui_events[event] = handlers
		end
		if callback == nil then
			table.insert(handlers, { fn = event, passSelf = true })
		elseif type(callback) == "string" then
			table.insert(handlers, { fn = callback, passSelf = true })
		else
			table.insert(handlers, { fn = callback, passSelf = false })
		end
		self._xanui_rawRegisterEvent(self, event)
	end

	target.UnregisterEvent = function(self, event, callback)
		if not event then return end
		local handlers = self._xanui_events[event]
		if handlers then
			if callback then
				for i = #handlers, 1, -1 do
					if handlers[i].fn == callback then
						table.remove(handlers, i)
					end
				end
			else
				self._xanui_events[event] = nil
			end
		end
		self._xanui_rawUnregisterEvent(self, event)
	end

	target.UnregisterAllEvents = function(self)
		self._xanui_events = {}
		self._xanui_rawUnregisterAllEvents(self)
	end

	target.RegisterMessage = function(self, message, callback)
		if not message then return end
		local handlers = addon._xanui_messageHandlers[message]
		if not handlers then
			handlers = {}
			addon._xanui_messageHandlers[message] = handlers
		end
		local entry
		if callback == nil then
			entry = { target = self, fn = message, passSelf = true }
		elseif type(callback) == "string" then
			entry = { target = self, fn = callback, passSelf = true }
		else
			entry = { target = self, fn = callback, passSelf = false }
		end
		table.insert(handlers, entry)
	end

	target.UnregisterMessage = function(self, message, callback)
		if not message then return end
		local handlers = addon._xanui_messageHandlers and addon._xanui_messageHandlers[message]
		if not handlers then return end
		if callback then
			for i = #handlers, 1, -1 do
				local h = handlers[i]
				if h.target == self and h.fn == callback then
					table.remove(handlers, i)
				end
			end
		else
			for i = #handlers, 1, -1 do
				if handlers[i].target == self then
					table.remove(handlers, i)
				end
			end
		end
		if #handlers == 0 then
			addon._xanui_messageHandlers[message] = nil
		end
	end

	target.SendMessage = function(self, message, ...)
		if not message then return end
		local handlers = addon._xanui_messageHandlers and addon._xanui_messageHandlers[message]
		if not handlers then return end
		for i = 1, #handlers do
			local h = handlers[i]
			if h.passSelf then
				local fn = h.fn
				if type(fn) == "string" then
					fn = h.target[fn]
				end
				if fn then
					fn(h.target, message, ...)
				end
			else
				if type(h.fn) == "string" then
					local method = h.target[h.fn]
					if method then
						method(h.target, message, ...)
					end
				elseif h.fn then
					h.fn(message, ...)
				end
			end
		end
	end
end

addon:EmbedEvents(addon)

addon.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
addon.moduleFuncs = {}

local function OnEnable(event, arg1)
	if event == "ADDON_LOADED" and arg1 and arg1 == ADDON_NAME then
		addon:UnregisterEvent("ADDON_LOADED")
		addon:RegisterEvent("PLAYER_LOGIN", OnEnable)
	elseif event == "PLAYER_LOGIN" then
		addon:UnregisterEvent("PLAYER_LOGIN")
		addon:EnableAddon()
	end
end
addon:RegisterEvent("ADDON_LOADED", OnEnable)

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
			DEFAULT_CHAT_FRAME:AddMessage(string.format(L["|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - is now [|cFF20ff20%s|r]."], tostring(XanUIDB.showRaceIcon)))
			if addon["racegenderplates"] and addon["racegenderplates"].UpdateAllIcons then addon["racegenderplates"].UpdateAllIcons() end
			return true
		elseif c and c:lower() == "gendericon" then
			if XanUIDB.showGenderIcon then
				XanUIDB.showGenderIcon = false
			else
				XanUIDB.showGenderIcon = true
			end
			DEFAULT_CHAT_FRAME:AddMessage(string.format(L["|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - is now [|cFF20ff20%s|r]."], tostring(XanUIDB.showGenderIcon)))
			if addon["racegenderplates"] and addon["racegenderplates"].UpdateAllIcons then addon["racegenderplates"].UpdateAllIcons() end
			return true
		elseif c and c:lower() == "gendertext" then
			if XanUIDB.showGenderText then
				XanUIDB.showGenderText = false
			else
				XanUIDB.showGenderText = true
			end
			DEFAULT_CHAT_FRAME:AddMessage(string.format(L["|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - is now [|cFF20ff20%s|r]."], tostring(XanUIDB.showGenderText)))
			if addon["racegenderplates"] and addon["racegenderplates"].UpdateAllIcons then addon["racegenderplates"].UpdateAllIcons() end
			return true
		elseif c and c:lower() == "onlydrac" then
			if XanUIDB.onlyDracthyr then
				XanUIDB.onlyDracthyr = false
			else
				XanUIDB.onlyDracthyr = true
			end
			DEFAULT_CHAT_FRAME:AddMessage(string.format(L["|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - is now [|cFF20ff20%s|r]."], tostring(XanUIDB.onlyDracthyr)))
			if addon["racegenderplates"] and addon["racegenderplates"].UpdateAllIcons then addon["racegenderplates"].UpdateAllIcons() end
			return true
		elseif c and c:lower() == "showquests" then
			if XanUIDB.showQuests then
				XanUIDB.showQuests = false
			else
				XanUIDB.showQuests = true
			end
			DEFAULT_CHAT_FRAME:AddMessage(string.format(L["|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - is now [|cFF20ff20%s|r]."], tostring(XanUIDB.showQuests)))
			return true
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME, 64/255, 224/255, 208/255)
	DEFAULT_CHAT_FRAME:AddMessage(L["/xanui showrace - Toggles showing the race icon."])
	DEFAULT_CHAT_FRAME:AddMessage(L["/xanui gendericon - Toggles showing the gender icon."])
	DEFAULT_CHAT_FRAME:AddMessage(L["/xanui gendertext - Toggles showing the gender text."])
	DEFAULT_CHAT_FRAME:AddMessage(L["/xanui onlydrac - Toggles showing gender icon/text for Dracthyr only."])
	DEFAULT_CHAT_FRAME:AddMessage(L["/xanui showquests - Toggles showing quest icons."])
end

function addon:OpenBankBags()
	local min, max

	if addon.IsRetail then
		min, max =  NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS + NUM_BANKBAGSLOTS
	else
		min, max =  NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
	end

	if min and max then
		for i = min, max do
			OpenBag(i)
		end
	end
end

function addon:EnableAddon()

	if not XanUIDB then XanUIDB = {} end

	if XanUIDB.showRaceIcon == nil then XanUIDB.showRaceIcon = false end
	if XanUIDB.showGenderIcon == nil then XanUIDB.showGenderIcon = false end
	if XanUIDB.showGenderText == nil then XanUIDB.showGenderText = true end
	if XanUIDB.onlyDracthyr == nil then XanUIDB.onlyDracthyr = true end
	if XanUIDB.showQuests == nil then XanUIDB.showQuests = true end

	local ver = C_AddOns.GetAddOnMetadata("xanUI","Version") or 0


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

	--OPEN ALL BAGS AT BANK
	----------------------
	if C_PlayerInteractionManager then
		local InteractType = Enum.PlayerInteractionType
		addon:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(event, winArg)
			if winArg == InteractType.Banker then
				addon:OpenBankBags()
			end
		end)
	else
		Unit:RegisterEvent('BANKFRAME_OPENED', function()
			addon:OpenBankBags()
		end)
	end
	----------------------

	--NOW LOAD ALL THE MODULES
	for i=1, #addon.moduleFuncs do
		if addon.moduleFuncs[i].func then
			addon.moduleFuncs[i].func()
		end
	end

	SLASH_XANUI1 = "/xui";
	SLASH_XANUI2 = "/xanui";
	SlashCmdList["XANUI"] = XanUI_SlashCommand;

	DEFAULT_CHAT_FRAME:AddMessage(string.format(L["|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"], ver))
end
