local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "specindicators"

local eventFrame = CreateFrame("frame", ADDON_NAME.."_"..moduleName, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, event, ...)
	end
end)

local function updateClassSpecIcon()
	if not addon.IsRetail then return end

	getglobal("TargetFrameClassSpec"):Hide()
	if CanInspect("target") then
		eventFrame:RegisterEvent("INSPECT_READY")
		NotifyInspect("target")
	end
end

local function createClassSpecIcons(frame)
	if not addon.IsRetail then return end
	
	if not addon.CanAccessObject(frame) then return end
	local f
	
	f = CreateFrame("Frame", "$parentClassSpec", frame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(42)
	f:SetHeight(42)

	local t = f:CreateTexture("$parentIcon", "BACKGROUND", nil, 2)
	local q = f:CreateTexture("$parentRing", "BACKGROUND", nil, 3)
	
	q:SetPoint("CENTER", f, "CENTER", 0, 0)
	q:SetSize(42, 42)
	q:SetAtlas('Talent-RingWithDot')

	t:SetPoint('TOPLEFT', q, 9, -9)
	t:SetPoint('BOTTOMRIGHT', q, -9, 9)
	
	f:SetPoint("CENTER", 88, 35)
	f:Hide()
end

eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

function eventFrame:PLAYER_TARGET_CHANGED()
	updateClassSpecIcon()
end

function eventFrame:INSPECT_READY()
	if not addon.IsRetail then return end
	if not getglobal("TargetFrameClassSpec") then return end

	if UnitIsPlayer("target") then
		local spec_id = GetInspectSpecialization("target")
		
		eventFrame:UnregisterEvent("INSPECT_READY")
		ClearInspectPlayer()
		
		local id, name, description, icon, background, role, class = GetSpecializationInfoByID(spec_id)

		getglobal("TargetFrameClassSpecIcon"):SetTexture(icon)
		getglobal("TargetFrameClassSpec"):Show()
	else
		getglobal("TargetFrameClassSpec"):Hide()
	end
end

local function EnableClassSpecIcons()
	if not addon.IsRetail then return end
	createClassSpecIcons(TargetFrame)
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableClassSpecIcons } )

