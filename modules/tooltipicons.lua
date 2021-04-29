local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "tooltipicons"

local function showTooltipIcon(tooltip, link)
	if not (issecure() or not tooltip:IsForbidden()) then return end
	
	local linkType,id = link:match("^([^:]+):(%d+)")
	if linkType == "achievement" and id then
		if GetAchievementInfo(id) and select(10,GetAchievementInfo(id)) then
			tooltip.button:Show()
			tooltip.button:SetNormalTexture(select(10,GetAchievementInfo(id)))
			tooltip.button.doOverlay:Show()
			tooltip.button.type = "achievement"
		end
	elseif linkType == "spell" and id then
		if GetSpellInfo(id) and select(3,GetSpellInfo(id)) then
			tooltip.button:Show()
			tooltip.button:SetNormalTexture(select(3,GetSpellInfo(id)))
			tooltip.button.type = "spell"
		end
	else
		if id and GetItemIcon(id) then
			tooltip.button:Show()
			tooltip.button:SetNormalTexture(GetItemIcon(id))
			tooltip.button.type = "item"
		end
	end
	
end

local function RegisterTooltip(tooltip)

	local b = CreateFrame("Button", nil, tooltip)
	b:SetWidth(37)
	b:SetHeight(37)
	b:SetPoint("TOPRIGHT", tooltip, "TOPLEFT", 0, -3)
	b:Hide()

	local t = b:CreateTexture(nil,"OVERLAY")
	t:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
	t:SetTexCoord(0,0.5625,0,0.5625)
	t:SetPoint("CENTER",0,0)
	t:SetWidth(47)
	t:SetHeight(47)	
	t:Hide()
	b.doOverlay = t
	
	tooltip.button = b
	tooltip.button.func = showTooltipIcon
	
end

local function hookTip(tooltip)
	
	--create the button for the tooltip
	RegisterTooltip(tooltip)
	
	tooltip:HookScript("OnHide", function(self)
		self.button:Hide()
		self.button:SetNormalTexture(nil)
		self.button.doOverlay:Hide()
		self.button.type = nil
	end)	

	tooltip:HookScript('OnTooltipSetItem', function(self)
		local name, link = self:GetItem()
		if name and string.len(name) > 0 and link then --recipes return nil for GetItem() so check for it
			self.button.func(self, link)
		end
	end)

	hooksecurefunc(tooltip, 'SetHyperlink', function(self, link)
		if link then
			self.button.func(self, link)
		end
	end)
	
end

hookTip(ItemRefTooltip)
hookTip(GameTooltip)
