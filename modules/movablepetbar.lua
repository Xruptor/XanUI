local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "movablepetbar"

local function getBarColor(hcur, hmax)
	local r
	local g = 1
	local cur = 2 * hcur/hmax
	if cur > 1 then
		return 2 - cur, 1, 0
	else
		return 1, cur, 0
	end
end

local function setPetBarHealth()
	if not XanUIPetHealthBar then return end
	local hcur, hmax = UnitHealth("pet"), UnitHealthMax("pet")
	local hper = 0
	
	XanUIPetHealthBar.petname:SetText(UnitName("pet"))

	if hmax > 0 then hper = hcur/hmax end
	XanUIPetHealthBar:SetValue(hper)
	XanUIPetHealthBar.percentfont:SetText(ceil(hper * 100).."%")
	XanUIPetHealthBar:SetStatusBarColor(getBarColor(hcur, hmax))
end

local function createPetBar()
 	local bar = CreateFrame("StatusBar","XanUIPetHealthBar", UIParent)
	bar.unit = "pet"
	bar:SetSize(100,10)
	--bar.barSpark:Hide()
	--bar.barFlash:Hide()
	bar:SetPoint("CENTER",0,0)
	bar:SetMinMaxValues(0, 1)
	bar:SetStatusBarTexture("Interface\\AddOns\\xanUI\\media\\Minimalist")
	bar:SetStatusBarColor(0,1,0)
	--bar:SetOrientation("VERTICAL")
 	bar:SetMovable(true)
	bar:SetScript("OnMouseDown",function()
		if (IsShiftKeyDown()) then
			bar.isMoving = true
			bar:StartMoving()
	 	end
	end)
	bar:SetScript("OnMouseUp",function()
		if( bar.isMoving ) then
			bar.isMoving = nil
			bar:StopMovingOrSizing()
			addon.SaveLayout("XanUIPetHealthBar")
		end
	end)
	
 	local barBG = bar:CreateTexture("XanUIPetHealthBar_BG", "BACKGROUND")
	barBG:SetSize(100,10)
	barBG:SetPoint("CENTER",bar,"CENTER")
	barBG:SetTexture("Interface\\AddOns\\xanUI\\media\\Minimalist")
	barBG:SetColorTexture(0.1, 0.1, 0.1, 0.6)

	local petNameFont = bar:CreateFontString("XanUIPetHealthBarPetName", "OVERLAY")
	petNameFont:SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
	petNameFont:SetPoint("RIGHT", bar, "LEFT", -5, 0)
	bar.petname = petNameFont
	
	local fontstr = bar:CreateFontString("XanUIPetHealthBarPercent", "OVERLAY")
	fontstr:SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
	fontstr:SetPoint("LEFT", bar, "RIGHT", 5, 0)
	bar.percentfont = fontstr
							
	bar:Hide()
	
	addon.RestoreLayout("XanUIPetHealthBar")	
end

local function pethealth(frame, unit)
	if not XanUIPetHealthBar then return end
	if unit ~= "pet" then return end
	
	if not UnitExists("pet") and XanUIPetHealthBar:IsVisible() then
		XanUIPetHealthBar:Hide()
	elseif UnitExists("pet") and not XanUIPetHealthBar:IsVisible() then
		XanUIPetHealthBar:Show()
	end
	
	if UnitIsDead("pet") then
		XanUIPetHealthBar.petname:SetText("Dead")
		XanUIPetHealthBar:SetValue(0)
		XanUIPetHealthBar.percentfont:SetText("0%")
	else
		setPetBarHealth()
	end
end

hooksecurefunc("UnitFrameHealthBar_Update", pethealth)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
	pethealth(self, self.unit)
end)

local petUpdateFrame = CreateFrame("frame","xanUIpetUpdateFrame",UIParent)
petUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
	self.OnUpdateCounter = (self.OnUpdateCounter or 0) + elapsed
	if self.OnUpdateCounter < 0.05 then return end
	self.OnUpdateCounter = 0

	pethealth(self, "pet")
end)

local function EnablePetBar()
	--only create the pet bar for Warlock, Mage and Hunter
	local _, class = UnitClass("player")
	
	if class == "HUNTER" or class == "WARLOCK" or class == "MAGE" then
		createPetBar()
	end
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnablePetBar } )
