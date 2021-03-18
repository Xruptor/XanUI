local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "factionicons"

local eventFrame = CreateFrame("frame", ADDON_NAME.."_"..moduleName, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, event, ...)
	end
end)

eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_TARGET")

local function createFactionIcon(frame)
	if not addon.CanAccessObject(frame) then return end
	local f

	f = CreateFrame("Frame", "$parentFaction", frame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(40)
	f:SetHeight(40)

	local t = f:CreateTexture("$parentIcon", "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\xanUI\\media\\Unknown")
	t:SetAllPoints(f)
	
	if frame == TargetFrame then
		f:SetPoint("CENTER", 67, 24)
	elseif frame == TargetFrameToT then
		f:SetPoint("CENTER", -35, 5)
	else
		f:SetPoint("CENTER", -6, 10)
	end
	
	f:Hide()
end

local function updateFactionIcon(unit, frame)
	if not addon.CanAccessObject(frame) then return end
	if not unit then return nil end
	if not frame then return nil end

	if frame == TargetFrame then
		--we have to move the target raid icon identifier to the right a bit (skull, diamond, star, etc..)
		TargetFrameTextureFrameRaidTargetIcon:SetPoint("CENTER", TargetFrame, "TOPRIGHT", -82, -74);
		--bottom right to the left of level icon
		
		--we have to move the target leader icon as well
		TargetFrameTextureFrameLeaderIcon:ClearAllPoints();
		TargetFrameTextureFrameLeaderIcon:SetPoint("TOPLEFT", -2, -15);

		--don't show the faction icon if the unit is already in PVP.  The PVP icon is a bigger notifier of what
		--faction a unit is... duh!
		if( UnitFactionGroup(unit) and UnitFactionGroup(unit):lower() ~= "neutral" and not TargetFrameTextureFramePVPIcon:IsVisible()) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
		
	elseif frame == TargetFrameToT then
		if( UnitFactionGroup(unit) and UnitFactionGroup(unit):lower() ~= "neutral"	) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end
	end
end

function eventFrame:PLAYER_TARGET_CHANGED()
	updateFactionIcon("target", TargetFrame)
end

function eventFrame:UNIT_TARGET(self, unitid)
	--update target of target because PLAYER_TARGET_CHANGED doesn't always work
	if UnitExists("targettarget") then
		updateFactionIcon("targettarget", TargetFrameToT)
	end
end

local function EnableFactionIcon()
	createFactionIcon(TargetFrame)
	createFactionIcon(TargetFrameToT)
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableFactionIcon } )

