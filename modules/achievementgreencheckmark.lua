local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "achievementgreencheckmark"

--Add achievement green checkmarks on achivements the current character has completed.
--makes it easier to see it on achievement list quickly without using the stupid tooltip
local achGreenCheckLoaded = false
local achGreenChkList = {}

local function AchUpdateChecks()
	local i, icon
	for i, icon in pairs(achGreenChkList) do

		local achievement = icon:GetParent()
		local achievementID = achievement.id

		if achievementID and achievement:IsShown() then
			local _, _, _, completed, _, _, _, _, _, _, _, isGuild, wasEarnedByMe = GetAchievementInfo(achievementID)
			if wasEarnedByMe then
				icon:Show()
			else
				icon:Hide()
			end
		else
			icon:Hide()
		end
	end
end

local function AchGreenChkSetup()
	if achGreenCheckLoaded then return end

	for i=1,100 do 
		local prefix = "AchievementFrameAchievementsContainerButton"..i
		local button = _G[prefix]
		if not button then break end

		local chkFrame = CreateFrame("Frame", "", button)
		chkFrame:SetSize(24,24)
		chkFrame:SetPoint("TOPRIGHT", button, "TOPRIGHT", -67, -5)
		--chkFrame:SetPoint("TOPRIGHT", button, "TOPRIGHT", -50, -5)
		chkFrame:SetFrameLevel(button.shield:GetFrameLevel()+1)
		chkFrame.greenChk = chkFrame:CreateTexture("","OVERLAY")
		chkFrame.greenChk:SetAllPoints(true)
		chkFrame.greenChk:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
		
		button.xanUIGreenChk = chkFrame
		achGreenChkList[i] = chkFrame
		
	end

	local achievescroll = _G['AchievementFrameAchievementsContainer']
	hooksecurefunc("HybridScrollFrame_Update",function(scrollframe) if scrollframe==achievescroll then AchUpdateChecks() end end)

	achievescroll:HookScript("OnVerticalScroll", AchUpdateChecks)
	achievescroll:HookScript("OnMouseWheel", AchUpdateChecks)
	achievescroll.scrollDown:HookScript("OnClick", AchUpdateChecks)
	achievescroll.scrollUp:HookScript("OnClick", AchUpdateChecks)

	achGreenCheckLoaded = true
end

local function EnableAchGreenChk()
	if not addon.IsRetail then return end
	
	--achievement checkmark
	hooksecurefunc("ToggleAchievementFrame", function() AchGreenChkSetup() end)
end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableAchGreenChk } )

