--[[
	NOTE: This is my personal UI modifications.  It's not meant for the general public.
	Don't say I didn't warn you!
--]]

local ADDON_NAME, private = ...
if type(private) ~= "table" then
	private = {}
end
local L = private.L or setmetatable({}, { __index = function(_, key) return key end })

private.GetAddonFrame = private.GetAddonFrame or function(_, addonName)
	local name = addonName or ADDON_NAME
	local frame = _G[name]
	if not frame then
		frame = CreateFrame("Frame", name, UIParent, BackdropTemplateMixin and "BackdropTemplate")
		_G[name] = frame
	end
	return frame
end

local addon = private:GetAddonFrame(ADDON_NAME)
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

local SetCVar = (C_CVar and C_CVar.SetCVar) or SetCVar
local GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

function addon:GetCoinString(amount)
	local coinFn = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString or GetCoinText
	if not coinFn then
		return tostring(amount or 0)
	end
	return coinFn(amount or 0)
end

function addon:OnEnable(event, arg1)
	if event == "ADDON_LOADED" and arg1 and arg1 == ADDON_NAME then
		self:UnregisterEvent("ADDON_LOADED")
		self:RegisterEvent("PLAYER_LOGIN")
	elseif event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN")
		self:EnableAddon()
	end
end

function addon:ADDON_LOADED(event, arg1)
	self:OnEnable(event, arg1)
end

function addon:PLAYER_LOGIN(event, arg1)
	self:OnEnable(event, arg1)
end

addon:RegisterEvent("ADDON_LOADED")

function addon.CanAccessObject(obj)
	return issecure() or not obj:IsForbidden();
end

local function EnableTargetGenderIcon()
	if XanUIDB and XanUIDB.showGenderIcon == false then return end

	local function GetTargetFrame()
		return _G.TargetFrame
	end

	local genders = { nil, "male", "female" }

	local function EnsureIcon(frame)
		if not frame then return nil end
		if frame.xanUITargetGenderIcon then
			return frame.xanUITargetGenderIcon
		end
		local icon = frame:CreateTexture(nil, "OVERLAY")
		icon:SetSize(18, 18)
		icon:SetPoint("LEFT", frame, "RIGHT", -14, 0)
		icon:Hide()
		frame.xanUITargetGenderIcon = icon
		return icon
	end

	local function UpdateIcon()
		if XanUIDB and XanUIDB.showGenderIcon == false then return end
		local frame = GetTargetFrame()
		local icon = EnsureIcon(frame)
		if not icon then return end
		if not UnitExists("target") or not UnitIsPlayer("target") then
			icon:Hide()
			return
		end

		local _, race = UnitRace("target")
		local sexID = UnitSex("target")
		if not race or race:lower() ~= "dracthyr" or not genders[sexID] then
			icon:Hide()
			return
		end

		if genders[sexID] == "male" then
			icon:SetTexture(131149)
			icon:SetTexCoord(0, 0.5, 0, 1)
		elseif genders[sexID] == "female" then
			icon:SetTexture(131149)
			icon:SetTexCoord(1, 0.5, 0, 1)
		end
		icon:Show()
	end

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	frame:RegisterEvent("UNIT_MODEL_CHANGED")
	frame:RegisterEvent("UNIT_CONNECTION")
	frame:SetScript("OnEvent", function(_, event, arg1)
		if event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" or event == "UNIT_CONNECTION" then
			if arg1 ~= "target" then return end
		end
		UpdateIcon()
	end)

	if _G.TargetFrame and _G.TargetFrame.HookScript then
		_G.TargetFrame:HookScript("OnShow", UpdateIcon)
	end

	UpdateIcon()
end

local function EnableTargetSpecIcon()
	if not GetInspectSpecialization or not NotifyInspect then return end

	local function GetTargetFrame()
		return _G.TargetFrame
	end

	local specInfoFn = GetSpecializationInfoByID or (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoByID)
	local specRoleFn = GetSpecializationRoleByID or (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationRoleByID)

	local function EnsureIcon(frame)
		if not frame then return nil end
		if frame.xanUITargetSpecIcon then
			return frame.xanUITargetSpecIcon
		end
		local icon = frame:CreateTexture(nil, "OVERLAY")
		icon:SetSize(26, 26)
		icon:SetPoint("RIGHT", frame, "LEFT", 14, 0)
		icon:Hide()
		frame.xanUITargetSpecIcon = icon
		return icon
	end

	local function CanInspectTarget()
		if not UnitExists("target") or not UnitIsPlayer("target") then return false end
		if UnitIsUnit("target", "player") then return false end
		if CanInspect and not CanInspect("target") then return false end
		if CheckInteractDistance and not CheckInteractDistance("target", 1) then return false end
		return true
	end

	local function ClearIcon(icon)
		if not icon then return end
		icon:SetTexture(nil)
		icon:Hide()
	end

	local inspectPending = false

	local function RequestInspect()
		if inspectPending then return end
		if not CanInspectTarget() then return end
		inspectPending = true
		NotifyInspect("target")
		if C_Timer and C_Timer.After then
			C_Timer.After(0.5, function()
				inspectPending = false
			end)
		else
			inspectPending = false
		end
	end

	local function UpdateFromInspect()
		local frame = GetTargetFrame()
		local icon = frame and frame.xanUITargetSpecIcon
		if XanUIDB and XanUIDB.showSpecIcon == false then
			ClearIcon(icon)
			return
		end
		icon = EnsureIcon(frame)
		if not icon then return end
		if not CanInspectTarget() then
			ClearIcon(icon)
			return
		end

		local specID = GetInspectSpecialization("target")
		if not specID or specID <= 0 then
			ClearIcon(icon)
			return
		end
		if specRoleFn and not specRoleFn(specID) then
			ClearIcon(icon)
			return
		end

		local specIcon = nil
		if specInfoFn then
			local info = { specInfoFn(specID) }
			if #info == 1 and type(info[1]) == "table" then
				specIcon = info[1].icon
			else
				specIcon = info[4]
			end
		end

		if specIcon then
			icon:SetTexture(specIcon)
			icon:SetTexCoord(0, 1, 0, 1)
			icon:Show()
		else
			ClearIcon(icon)
		end
	end

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterEvent("INSPECT_READY")
	frame:RegisterEvent("UNIT_CONNECTION")
	frame:SetScript("OnEvent", function(_, event, arg1)
		if event == "INSPECT_READY" then
			if arg1 ~= UnitGUID("target") then return end
			UpdateFromInspect()
			if ClearInspectPlayer then
				ClearInspectPlayer()
			end
			return
		end

		UpdateFromInspect()
		RequestInspect()
	end)

	if _G.TargetFrame and _G.TargetFrame.HookScript then
		_G.TargetFrame:HookScript("OnShow", function()
			UpdateFromInspect()
			RequestInspect()
		end)
	end

	addon.UpdateTargetSpecIcon = UpdateFromInspect
	addon.RequestTargetInspect = RequestInspect

	UpdateFromInspect()
	RequestInspect()
end

local function EnableTargetClassColors()
	if XanUIDB and XanUIDB.targetClassColor == false then return end
	local function FindStatusBarByUnit(frame, unit, depth)
		if not frame or not frame.GetChildren or depth > 6 then return nil end
		local children = { frame:GetChildren() }
		for i = 1, #children do
			local child = children[i]
			if child and child.IsObjectType and child:IsObjectType("StatusBar") then
				if child.unit == unit then
					return child
				end
			end
			local found = FindStatusBarByUnit(child, unit, depth + 1)
			if found then return found end
		end
		return nil
	end

	local function GetHealthBar(frame, unit)
		if not frame then return nil end
		if frame.IsObjectType and frame:IsObjectType("StatusBar") then
			return frame
		end
		if frame.healthbar then return frame.healthbar end
		if frame.HealthBar then return frame.HealthBar end
		if frame.healthBar then return frame.healthBar end
		if frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain then
			local main = frame.TargetFrameContent.TargetFrameContentMain
			if main.HealthBar then return main.HealthBar end
			if main.healthBar then return main.healthBar end
		end
		local name = frame.GetName and frame:GetName()
		if name and _G[name .. "HealthBar"] then
			return _G[name .. "HealthBar"]
		end
		if unit then
			local found = FindStatusBarByUnit(frame, unit, 0)
			if found then return found end
		end
		return nil
	end

	local function GetClassColor(classToken)
		if not classToken then return nil end
		local classColor = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classToken)
		if classColor then
			return classColor.r, classColor.g, classColor.b
		end
		local fallback = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
		if fallback then
			return fallback.r, fallback.g, fallback.b
		end
		return nil
	end

	local function ApplyColorToBar(bar, r, g, b)
		if not bar or not r or not g or not b then return end
		if bar._xanui_setting_texture then
			return
		end
		if bar.SetStatusBarTexture and not bar._xanui_texture_forced then
			-- Force a neutral texture so tinting isn't multiplied by a colored atlas/texture.
			bar._xanui_setting_texture = true
			bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
			bar._xanui_setting_texture = false
			bar._xanui_texture_forced = true
		elseif bar.GetStatusBarTexture then
			local tex = bar:GetStatusBarTexture()
			if tex and tex.SetTexture then
				tex:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
			end
		end
		if bar.SetStatusBarDesaturated then
			bar:SetStatusBarDesaturated(false)
		end
		if bar.SetStatusBarColor then
			bar:SetStatusBarColor(r, g, b)
		end
		if bar.GetStatusBarTexture then
			local tex = bar:GetStatusBarTexture()
			if tex and tex.SetVertexColor then
				tex:SetVertexColor(r, g, b)
			end
		end
		if bar.SetColorTexture then
			bar:SetColorTexture(r, g, b)
		end
	end

	local function ApplyColor(frame, unit)
		if not frame or not unit or not UnitExists(unit) then return end
		local bar = GetHealthBar(frame, unit)
		if not bar then return end
		if UnitIsPlayer(unit) then
			local _, classToken = UnitClass(unit)
			local r, g, b = GetClassColor(classToken)
			if r and g and b then
				ApplyColorToBar(bar, r, g, b)
			end
		else
			local r, g, b = UnitSelectionColor(unit, true)
			if r and g and b then
				ApplyColorToBar(bar, r, g, b)
			end
		end
	end

	local function IsLikelyHealthBar(bar, unit)
		if not bar or not unit then return false end
		if bar.unit and bar.unit ~= unit then return false end
		if bar.powerType ~= nil or bar.powerToken ~= nil then return false end
		if bar.ManaBarTexture or bar.ManaBarMask or bar.ManaBarText then return false end
		local name = bar.GetName and bar:GetName() or ""
		if name == "TargetFrameSpellBar" then return false end
		return true
	end

	local cachedBars = {
		target = nil,
		targettarget = nil,
	}

	local function CollectBars(frame, unit)
		if not frame then return {} end
		local bars = {}
		local function walk(f, depth)
			if not f or depth > 6 then return end
			if f.IsObjectType and f:IsObjectType("StatusBar") then
				if IsLikelyHealthBar(f, unit) then
					table.insert(bars, f)
				end
			end
			if f.GetChildren then
				for _, child in ipairs({ f:GetChildren() }) do
					walk(child, depth + 1)
				end
			end
		end
		walk(frame, 0)
		return bars
	end

	local function GetBarsForUnit(unit)
		if cachedBars[unit] then
			return cachedBars[unit]
		end
		local frame = unit == "target" and _G.TargetFrame or _G.TargetFrameToT
		local bars = CollectBars(frame, unit)
		cachedBars[unit] = bars
		return bars
	end

	local function ApplyToAllBars(unit)
		local frame = unit == "target" and _G.TargetFrame or _G.TargetFrameToT
		if not frame then return end
		local bars = GetBarsForUnit(unit)
		if UnitIsPlayer(unit) then
			local _, classToken = UnitClass(unit)
			local r, g, b = GetClassColor(classToken)
			if r and g and b then
				for i = 1, #bars do
					local bar = bars[i]
					if bar then
						ApplyColorToBar(bar, r, g, b)
					end
				end
			end
		else
			local r, g, b = UnitSelectionColor(unit, true)
			if r and g and b then
				for i = 1, #bars do
					local bar = bars[i]
					if bar then
						ApplyColorToBar(bar, r, g, b)
					end
				end
			end
		end
	end

	local function ApplyForUnit(unit)
		if unit == "target" then
			ApplyColor(_G.TargetFrame, "target")
		elseif unit == "targettarget" then
			ApplyColor(_G.TargetFrameToT, "targettarget")
		end
	end

	local function UpdateAll()
		if XanUIDB and XanUIDB.targetClassColor == false then return end
		ApplyColor(_G.TargetFrame, "target")
		ApplyColor(_G.TargetFrameToT, "targettarget")
		ApplyToAllBars("target")
		ApplyToAllBars("targettarget")
	end

	if _G.TargetFrame and _G.TargetFrame.HookScript then
		_G.TargetFrame:HookScript("OnShow", UpdateAll)
	end
	if _G.TargetFrameToT and _G.TargetFrameToT.HookScript then
		_G.TargetFrameToT:HookScript("OnShow", UpdateAll)
	end

	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("PLAYER_TARGET_CHANGED")
	f:RegisterEvent("UNIT_TARGET")
	f:RegisterEvent("UNIT_FACTION")
	f:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
	f:SetScript("OnEvent", function(_, event, arg1)
		if event == "UNIT_TARGET" and arg1 ~= "target" then return end
		if event == "PLAYER_TARGET_CHANGED" then
			cachedBars.target = nil
			cachedBars.targettarget = nil
		end
		UpdateAll()
	end)

	if hooksecurefunc then
		if _G.UnitFrameHealthBar_Update then
			hooksecurefunc("UnitFrameHealthBar_Update", function(frame, unit)
				if unit and frame then
					if XanUIDB and XanUIDB.targetClassColor == false then return end
					if unit == "target" or unit == "targettarget" then
						ApplyToAllBars(unit)
					else
						ApplyColor(frame, unit)
					end
				end
			end)
		end
		if _G.HealthBar_OnValueChanged then
			hooksecurefunc("HealthBar_OnValueChanged", function(bar)
				if not bar then return end
				local unit = bar.unit
				if not unit and bar.GetParent then
					local parent = bar:GetParent()
					unit = parent and parent.unit
				end
				if unit then
					if XanUIDB and XanUIDB.targetClassColor == false then return end
					if unit == "target" or unit == "targettarget" then
						ApplyToAllBars(unit)
					else
						ApplyColor(bar, unit)
					end
				end
			end)
		end
		if _G.TargetFrame_Update then
			hooksecurefunc("TargetFrame_Update", function()
				if XanUIDB and XanUIDB.targetClassColor == false then return end
				cachedBars.target = nil
				ApplyForUnit("target")
			end)
		end
		if _G.TargetFrame_CheckFaction then
			hooksecurefunc("TargetFrame_CheckFaction", function()
				if XanUIDB and XanUIDB.targetClassColor == false then return end
				ApplyForUnit("target")
			end)
		end
		if _G.TargetFrameToT_Update then
			hooksecurefunc("TargetFrameToT_Update", function()
				if XanUIDB and XanUIDB.targetClassColor == false then return end
				cachedBars.targettarget = nil
				ApplyForUnit("targettarget")
			end)
		end
	end
end

function XanUI_SlashCommand(cmd)
	local token = cmd and cmd:match("^(%S+)") or ""
	token = token:lower()

	local function updateRaceGender()
		local mod = addon["racegenderplates"]
		if mod and mod.UpdateAllIcons then
			mod:UpdateAllIcons()
		end
	end

	local toggles = {
		showrace = { key = "showRaceIcon", msg = L.SlashShowRaceStatus, onChange = updateRaceGender },
		gendericon = { key = "showGenderIcon", msg = L.SlashGenderIconStatus, onChange = updateRaceGender },
		gendertext = { key = "showGenderText", msg = L.SlashGenderTextStatus, onChange = updateRaceGender },
		onlydrac = { key = "onlyDracthyr", msg = L.SlashOnlyDracStatus, onChange = updateRaceGender },
		specicon = {
			key = "showSpecIcon",
			msg = L.SlashSpecIconStatus,
			onChange = function()
				if addon.UpdateTargetSpecIcon then
					addon.UpdateTargetSpecIcon()
				end
				if XanUIDB and XanUIDB.showSpecIcon and addon.RequestTargetInspect then
					addon.RequestTargetInspect()
				end
			end,
		},
		showquests = {
			key = "showQuests",
			msg = L.SlashShowQuestsStatus,
			onChange = function()
				local mod = addon["questicons"]
				if mod and mod.UpdateAllQuestIcons then
					mod:UpdateAllQuestIcons("SlashToggle")
				end
			end,
		},
		targetclasscolor = {
			key = "targetClassColor",
			msg = L.SlashTargetClassColorStatus,
			onChange = function()
				EnableTargetClassColors()
			end,
		},
	}

	local entry = toggles[token]
	if entry then
		XanUIDB[entry.key] = not XanUIDB[entry.key]
		DEFAULT_CHAT_FRAME:AddMessage(string.format(entry.msg, tostring(XanUIDB[entry.key])))
		if entry.onChange then
			entry.onChange()
		end
		return true
	end

	DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME, 64 / 255, 224 / 255, 208 / 255)
	DEFAULT_CHAT_FRAME:AddMessage(L.SlashHelpShowRace)
	DEFAULT_CHAT_FRAME:AddMessage(L.SlashHelpGenderIcon)
	DEFAULT_CHAT_FRAME:AddMessage(L.SlashHelpGenderText)
	DEFAULT_CHAT_FRAME:AddMessage(L.SlashHelpOnlyDrac)
	DEFAULT_CHAT_FRAME:AddMessage(L.SlashHelpSpecIcon)
	DEFAULT_CHAT_FRAME:AddMessage(L.SlashHelpShowQuests)
	DEFAULT_CHAT_FRAME:AddMessage(L.SlashHelpTargetClassColor)
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

function addon:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(event, winArg)
	local interactType = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Banker
	if interactType and winArg == interactType then
		self:OpenBankBags()
	end
end

function addon:BANKFRAME_OPENED()
	self:OpenBankBags()
end

function addon:EnableAddon()

	if not XanUIDB then XanUIDB = {} end

	local defaults = {
		showRaceIcon = false,
		showGenderIcon = false,
		showSpecIcon = true,
		showGenderText = true,
		onlyDracthyr = true,
		showQuests = true,
		targetClassColor = true,
	}
	for key, value in pairs(defaults) do
		if XanUIDB[key] == nil then
			XanUIDB[key] = value
		end
	end

	local ver = GetAddOnMetadata and GetAddOnMetadata("xanUI", "Version") or 0


	if addon.IsRetail then

		-- Always show missing transmogs in tooltips
		if SetCVar then
			SetCVar("missingTransmogSourceInItemTooltips", "1")
		end

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
		if SetCVar then
			SetCVar("UnitNameFriendlySpecialNPCName", "1")
			SetCVar("UnitNameHostleNPC", "1")
			SetCVar("UnitNameInteractiveNPC", "1")
			SetCVar("ShowQuestUnitCircles", "1")
		end

	end

	--force Numeric for healthbar fix
	if SetCVar then
		SetCVar("statusText", "1")
		SetCVar("statusTextDisplay", "NUMERIC")
		SetCVar("nameplateShowAll", 1) -- always show the nameplates (combat/noncombat)
		SetCVar("nameplateShowFriends", 1) -- show for friendly units
		SetCVar("nameplateShowEnemies", 1) -- Enemy
		SetCVar("nameplateShowEnemyMinus", 1) -- Enemy Minors
		SetCVar("nameplateMaxDistance", 100) --default 60
		SetCVar("UnitNameNPC", "0") --this is necessary as part of the (Hostile, Quest, and Interactive NPCs) group
		SetCVar("UnitNameFriendlyPlayerName", "1")
		SetCVar("UnitNameFriendlyMinionName", "1")
		SetCVar("UnitNameEnemyPlayerName", "1")
		SetCVar("UnitNameEnemyMinionName", "1")
	end

	--OPEN ALL BAGS AT BANK
	----------------------
	if C_PlayerInteractionManager then
		addon:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	else
		addon:RegisterEvent("BANKFRAME_OPENED")
	end
	----------------------

	--NOW LOAD ALL THE MODULES
	for i=1, #addon.moduleFuncs do
		if addon.moduleFuncs[i].func then
			addon.moduleFuncs[i].func()
		end
	end

	EnableTargetClassColors()
	EnableTargetGenderIcon()
	EnableTargetSpecIcon()

	SLASH_XANUI1 = "/xui";
	SLASH_XANUI2 = "/xanui";
	SlashCmdList["XANUI"] = XanUI_SlashCommand;

	DEFAULT_CHAT_FRAME:AddMessage(string.format(L.AddonLoaded, ver))
end
