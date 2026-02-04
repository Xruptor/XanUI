local ADDON_NAME, private = ...
local addon = private and private.GetAddonFrame and private:GetAddonFrame(ADDON_NAME) or _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local moduleName = "specicons"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
addon:EmbedEvents(moduleFrame)

local MAX_CACHE = 50
local CACHE_TTL = 120
local SPEC_ICON_SIZE = 26
local INSPECT_DELAY = 0.2
local INSPECT_FREQ = 2

local specCache = {}
local specOrder = {}
local specByClass = nil
local lastInspectRequest = 0

local specInfoFn = GetSpecializationInfoByID or (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoByID)
local specRoleFn = GetSpecializationRoleByID or (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationRoleByID)
local getNumClasses = GetNumClasses
local getNumSpecsForClass = (C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID) or GetNumSpecializationsForClassID
local getSpecInfoForClass = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoForClassID) or GetSpecializationInfoForClassID

local function Now()
	if GetTime then
		return GetTime()
	end
	return time()
end

local function CleanText(text)
	if not text then return nil end
	text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
	text = text:gsub("|r", "")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

local function BuildSpecMap()
	if specByClass ~= nil then return end
	specByClass = {}
	if not addon.IsRetail then
		return
	end
	if not getNumClasses or not getNumSpecsForClass or not getSpecInfoForClass then
		return
	end
	for classID = 1, getNumClasses() do
		local classSpecs = {}
		local specCount = getNumSpecsForClass(classID)
		for i = 1, specCount do
			local specID, name, _, icon = getSpecInfoForClass(classID, i)
			if specID and name then
				classSpecs[string.lower(name)] = { id = specID, icon = icon, name = name }
			end
		end
		if next(classSpecs) then
			specByClass[classID] = classSpecs
		end
	end
end

local function CacheSet(guid, specID, icon, source)
	if not guid or not specID then return end
	specCache[guid] = { specID = specID, icon = icon, ts = Now(), source = source }
	for i = #specOrder, 1, -1 do
		if specOrder[i] == guid then
			table.remove(specOrder, i)
		end
	end
	table.insert(specOrder, 1, guid)
	if #specOrder > MAX_CACHE then
		local old = table.remove(specOrder)
		if old then
			specCache[old] = nil
		end
	end
end

local function CacheClear()
	local count = #specOrder
	for k in pairs(specCache) do
		specCache[k] = nil
	end
	for i = #specOrder, 1, -1 do
		specOrder[i] = nil
	end
	return count
end

local function CacheGet(guid)
	local entry = guid and specCache[guid]
	if not entry then return nil end
	if Now() - entry.ts > CACHE_TTL then
		specCache[guid] = nil
		for i = #specOrder, 1, -1 do
			if specOrder[i] == guid then
				table.remove(specOrder, i)
				break
			end
		end
		return nil
	end
	return entry
end

local function CacheDescribe(maxLines)
	local lines = {}
	local now = Now()
	local count = 0
	for i = 1, #specOrder do
		local guid = specOrder[i]
		if specCache[guid] then
			count = count + 1
		end
	end

	local limit = maxLines or 15
	for i = 1, #specOrder do
		if #lines >= limit then break end
		local guid = specOrder[i]
		local entry = specCache[guid]
		if entry then
			local age = math.max(0, math.floor(now - entry.ts))
			local specName = nil
			if specInfoFn and entry.specID then
				local info = { specInfoFn(entry.specID) }
				if #info == 1 and type(info[1]) == "table" then
					specName = info[1].name
				else
					specName = info[2]
				end
			end
			local label = specName and (specName .. " (" .. entry.specID .. ")") or tostring(entry.specID or "?")
			lines[#lines + 1] = string.format("%d) %s - %s - %s - %ss", i, guid, label, entry.source or "?", age)
		end
	end
	return count, lines
end

local function GetSpecFromTooltip(tooltip, unit)
	if not tooltip or not unit then return nil end
	local className, _, classID = UnitClass(unit)
	if not classID then return nil end

	BuildSpecMap()
	if not specByClass or not specByClass[classID] then return nil end

	local classSpecs = specByClass[classID]
	local classNameLower = className and string.lower(className) or nil
	local numLines = tooltip:NumLines() or 0
	local tooltipName = tooltip.GetName and tooltip:GetName()

	local function scanLines(requireClassName)
		for i = 2, numLines do
			local line = tooltipName and _G[tooltipName .. "TextLeft" .. i]
			local text = line and line.GetText and line:GetText()
			text = CleanText(text)
			if text and text ~= "" then
				local lower = string.lower(text)
				local hasClass = classNameLower and lower:find(classNameLower, 1, true)
				if (not requireClassName) or hasClass or not classNameLower then
					for specLower, spec in pairs(classSpecs) do
						if lower:find(specLower, 1, true) then
							return spec.id, spec.icon
						end
					end
				end
			end
		end
		return nil
	end

	return scanLines(true) or scanLines(false)
end

local function EnableSpecIcons()
	if moduleFrame._xanui_specicons_enabled then
		return
	end
	moduleFrame._xanui_specicons_enabled = true

	if not GetInspectSpecialization or not NotifyInspect then return end

	local function GetTargetFrame()
		return _G.TargetFrame
	end

	local function EnsureIcon(frame)
		if not frame then return nil end
		if frame.xanUITargetSpecIcon then
			return frame.xanUITargetSpecIcon
		end
		local icon = frame:CreateTexture(nil, "OVERLAY")
		icon:SetSize(SPEC_ICON_SIZE, SPEC_ICON_SIZE)
		icon:SetPoint("RIGHT", frame, "LEFT", 14, 0)
		icon:Hide()
		frame.xanUITargetSpecIcon = icon
		return icon
	end

	local function ClearIcon(icon)
		if not icon then return end
		icon:SetTexture(nil)
		icon:Hide()
	end

	local function CanInspectTarget()
		if not UnitExists("target") or not UnitIsPlayer("target") then return false end
		if UnitIsUnit("target", "player") then return false end
		if CanInspect and not CanInspect("target") then return false end
		if CheckInteractDistance and not CheckInteractDistance("target", 1) then return false end
		return true
	end

	local function IsInspectFrameOpen()
		return (InspectFrame and InspectFrame:IsShown()) or (Examiner and Examiner:IsShown())
	end

	local function ApplySpecIcon(icon, specID, specIcon)
		if not icon then return end
		if not specIcon and specInfoFn and specID then
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
			return true
		end
		ClearIcon(icon)
		return false
	end

	local function UpdateFromCache()
		local frame = GetTargetFrame()
		local icon = frame and frame.xanUITargetSpecIcon
		if XanUIDB and XanUIDB.showSpecIcon == false then
			ClearIcon(icon)
			return
		end
		icon = EnsureIcon(frame)
		if not icon then return end
		if not UnitExists("target") or not UnitIsPlayer("target") then
			ClearIcon(icon)
			return
		end

		local guid = UnitGUID("target")
		local entry = guid and CacheGet(guid)
		if not entry then
			ClearIcon(icon)
			return
		end

		ApplySpecIcon(icon, entry.specID, entry.icon)
	end

	local inspectPending = false

	local function RequestInspect()
		if inspectPending then return end
		if XanUIDB and XanUIDB.showSpecIcon == false then return end
		if not CanInspectTarget() then return end
		if IsInspectFrameOpen() then return end
		local guid = UnitGUID("target")
		if guid and CacheGet(guid) then
			return
		end

		inspectPending = true
		local now = Now()
		local last = lastInspectRequest or 0
		local wait = ((now - last) > INSPECT_FREQ) and INSPECT_DELAY or ((INSPECT_FREQ - (now - last)) + INSPECT_DELAY)

		if C_Timer and C_Timer.After then
			C_Timer.After(wait, function()
				if IsInspectFrameOpen() or not CanInspectTarget() then
					inspectPending = false
					return
				end
				lastInspectRequest = Now()
				NotifyInspect("target")
				C_Timer.After(0.5, function()
					inspectPending = false
				end)
			end)
		else
			lastInspectRequest = Now()
			NotifyInspect("target")
			inspectPending = false
		end
	end

	local function UpdateFromInspect()
		if XanUIDB and XanUIDB.showSpecIcon == false then
			UpdateFromCache()
			return
		end
		if not CanInspectTarget() then
			UpdateFromCache()
			return
		end

		local specID = GetInspectSpecialization("target")
		if not specID or specID <= 0 then
			UpdateFromCache()
			return
		end
		if specRoleFn and not specRoleFn(specID) then
			UpdateFromCache()
			return
		end

		local guid = UnitGUID("target")
		local specIcon = nil
		if specInfoFn then
			local info = { specInfoFn(specID) }
			if #info == 1 and type(info[1]) == "table" then
				specIcon = info[1].icon
			else
				specIcon = info[4]
			end
		end
		if guid then
			CacheSet(guid, specID, specIcon, "inspect")
		end
		local frame = GetTargetFrame()
		local icon = EnsureIcon(frame)
		ApplySpecIcon(icon, specID, specIcon)
	end

	local function OnTooltipSetUnit(tooltip)
		if not tooltip or not tooltip.GetUnit then return end
		local _, unit = tooltip:GetUnit()
		if not unit then
			local focus = GetMouseFocus and GetMouseFocus()
			if focus and focus.unit then
				unit = focus.unit
			end
		end
		if not unit or not UnitIsPlayer(unit) then return end
		local guid = UnitGUID(unit)
		if not guid then return end

		local specID, specIcon = GetSpecFromTooltip(tooltip, unit)
		if specID then
			CacheSet(guid, specID, specIcon, "tooltip")
			if UnitIsUnit(unit, "target") then
				UpdateFromCache()
			end
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

		UpdateFromCache()
		RequestInspect()
	end)

	do
		local hooked = false
		if TooltipDataProcessor and Enum and Enum.TooltipDataType and TooltipDataProcessor.AddTooltipPostCall then
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
				OnTooltipSetUnit(tooltip)
			end)
			hooked = true
		end
		if not hooked and GameTooltip then
			local hasScript = true
			if GameTooltip.HasScript then
				local ok, res = pcall(GameTooltip.HasScript, GameTooltip, "OnTooltipSetUnit")
				hasScript = ok and res or false
			end
			if hasScript and GameTooltip.HookScript then
				local ok = pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", OnTooltipSetUnit)
				if not ok and GameTooltip.SetScript then
					pcall(GameTooltip.SetScript, GameTooltip, "OnTooltipSetUnit", OnTooltipSetUnit)
				end
			end
		end
	end

	if _G.TargetFrame and _G.TargetFrame.HookScript then
		_G.TargetFrame:HookScript("OnShow", function()
			UpdateFromCache()
			RequestInspect()
		end)
	end

	addon.UpdateTargetSpecIcon = UpdateFromCache
	addon.RequestTargetInspect = RequestInspect
	addon.SpecCacheClear = CacheClear
	addon.SpecCacheDescribe = CacheDescribe
end

table.insert(addon.moduleFuncs, { func = EnableSpecIcons, name = moduleName })
