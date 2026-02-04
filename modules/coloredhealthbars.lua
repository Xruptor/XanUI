local ADDON_NAME, private = ...
local addon = private and private.GetAddonFrame and private:GetAddonFrame(ADDON_NAME) or _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local moduleName = "coloredhealthbars"

addon[moduleName] = CreateFrame("Frame", moduleName.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local moduleFrame = addon[moduleName]
addon:EmbedEvents(moduleFrame)

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
		if not bars or #bars == 0 then return end
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

addon.EnableTargetClassColors = EnableTargetClassColors

table.insert(addon.moduleFuncs, { func = EnableTargetClassColors, name = moduleName })
