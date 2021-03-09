--[[
	NOTE: This is my personal UI modifications.  It's not meant for the general public.
	Don't say I didn't warn you!
--]]

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local enableTalkingHeadSilence = false

----------------------------------------------------------------
---COLOR BARS BY CLASS
----------------------------------------------------------------
local LibAceTimer = LibStub('AceTimer-3.0')

local debugf = tekDebug and tekDebug:GetFrame("xanUI")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local function CanAccessObject(obj)
	return issecure() or not obj:IsForbidden();
end

local function colour(statusbar, unit)
	if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
		if not CanAccessObject(statusbar) then return end
		local _, class = UnitClass(unit)
		local c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		statusbar:SetStatusBarColor(c.r, c.g, c.b)
	end
end

hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
	colour(self, self.unit)
end)

local sb = _G.GameTooltipStatusBar
local colorEventFrame = CreateFrame("Frame", "StatusColour")
colorEventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
colorEventFrame:SetScript("OnEvent", function()
	colour(sb, "mouseover")
end)

if IsRetail then
	-- Always show missing transmogs in tooltips
	C_TransmogCollection.SetShowMissingSourceInItemTooltips(true)
end

--/framestack in game lets you see frame information

----------------------------------------------------------------
---ADD Missing stats to the character panel
----------------------------------------------------------------

--don't really want to show all stats but use this as a guideline
--[[ function xanUI_ShowAllStats()
	PAPERDOLL_STATCATEGORIES= {
		[1] = {
			categoryFrame = "AttributesCategory",
			stats = {
				[1] = { stat = "HEALTH" },
				[2] = { stat = "POWER" },
				[3] = { stat = "ALTERNATEMANA" },
				[5] = { stat = "ARMOR" },
				[6] = { stat = "STRENGTH" },
				[7] = { stat = "AGILITY" },
				[8] = { stat = "INTELLECT" },
				[9] = { stat = "STAMINA" },
				[10] = { stat = "ATTACK_DAMAGE" },
				[11] = { stat = "ATTACK_AP" },
				[12] = { stat = "ATTACK_ATTACKSPEED" },
				[13] = { stat = "SPELLPOWER" },
				[14] = { stat = "MANAREGEN", hideAt = 0 },
				[15] = { stat = "ENERGY_REGEN", hideAt = 0 },
				[16] = { stat = "RUNE_REGEN", hideAt = 0 },
				[17] = { stat = "FOCUS_REGEN", hideAt = 0 },
				[18] = { stat = "MOVESPEED" },
				[19] = { stat = "DURABILITY" },
				[20] = { stat = "REPAIRTOTAL" },
				[21] = { stat = "ITEMLEVEL" },
			},
		},
		[2] = {
			categoryFrame = "EnhancementsCategory",
			stats = {
				[1] = { stat = "CRITCHANCE" },
				[2] = { stat = "HASTE" },
				[3] = { stat = "VERSATILITY" },
				[4] = { stat = "MASTERY" },
				[5] = { stat = "LIFESTEAL" },
				[6] = { stat = "AVOIDANCE" },
				[7] = { stat = "DODGE" },
				[8] = { stat = "PARRY" },
				[9] = { stat = "BLOCK" },
			},
		},
	};
	PaperDollFrame_UpdateStats();
end ]]


function xanUI_InsertStats()
	if not IsRetail then return end
	
	--1 is the top category with intellect and such, 2 is the second category
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "ATTACK_DAMAGE" });
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "ATTACK_AP" });
	tinsert(PAPERDOLL_STATCATEGORIES[1].stats, { stat = "SPELLPOWER" });

end

----------------------------------------------------------------
---Movable Pet Healthbar
----------------------------------------------------------------
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

function XanUI_CreatePetBar()
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
			XanUI_SaveLayout("XanUIPetHealthBar")
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
	
	XanUI_RestoreLayout("XanUIPetHealthBar")
		
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

----------------------------------------------------------------
---FACTION INDICATORS
----------------------------------------------------------------

function xanUI_CreateFactionIcon(frame)
	if not CanAccessObject(frame) then return end
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

function xanUI_UpdateFactionIcon(unit, frame)
	if not CanAccessObject(frame) then return end
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

----------------------------------------------------------------
---CLASS SPEC INDICATORS
----------------------------------------------------------------

local specEventFrame = CreateFrame("Frame")

function xanUI_UpdateClassSpecIcon()
	if not IsRetail then return end
	
	getglobal("TargetFrameClassSpec"):Hide()
	if CanInspect("target") then
		specEventFrame:RegisterEvent("INSPECT_READY")
		NotifyInspect("target")
	end
end

specEventFrame:SetScript("OnEvent", function(self, event, ...)
	if not IsRetail then return end
	
	if UnitIsPlayer("target") then
	
		local spec_id = GetInspectSpecialization("target")
		
		specEventFrame:UnregisterEvent("INSPECT_READY")
		ClearInspectPlayer()
		
		local id, name, description, icon, background, role, class = GetSpecializationInfoByID(spec_id)

		getglobal("TargetFrameClassSpecIcon"):SetTexture(icon)
		getglobal("TargetFrameClassSpec"):Show()
	else
		getglobal("TargetFrameClassSpec"):Hide()
	end

end)

function xanUI_CreateClassSpecIcons(frame)
	if not IsRetail then return end
	
	if not CanAccessObject(frame) then return end
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

----------------------------------------------------------------
----------------------------------------------------------------

function xanUI_smallNum(sNum)
	if not sNum then return end

	sNum = tonumber(sNum)

	if sNum < 1000 then
		return sNum
	elseif sNum >= 1000 then
		return string.format("%.1fK", sNum/1000)
	else	
		return sNum
	end
end

hooksecurefunc("TextStatusBar_UpdateTextString", function(self)
	if not CanAccessObject(self) then return end
	
	if self and self:GetParent() then
		local frame = self:GetParent();
		
		if frame:GetName() then
		
			local parentName = frame:GetName();
			local textString = self.TextString;
			
			--display according to frame name
			if parentName == "PlayerFrame" or parentName == "TargetFrame" or parentName == "TargetFrameToT" then
			
				local value = self:GetValue();
				local valueMin, valueMax = self:GetMinMaxValues();
			
				--check player death text
				if parentName == "PlayerFrame" then
					if UnitIsUnconscious("player") or UnitIsDeadOrGhost("player") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("Dead")
						end
						return
					end
				end
				--check target
				if parentName == "TargetFrame" then
					if UnitIsUnconscious("target") or UnitIsDeadOrGhost("target") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("Dead")
						end
						TargetFrame.healthbar.LeftText:Hide()
						TargetFrame.healthbar.RightText:Hide()							
						return
					end
				end
				--check target of target
				if parentName == "TargetFrameToT" then
					if UnitIsUnconscious("targettarget") or UnitIsDeadOrGhost("targettarget") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("Dead")
						end						
						return
					end
				end
				

				if valueMax > 0 then
					local pervalue = tostring(math.floor((value / valueMax) * 100)) .. " %";

					if not getglobal(parentName.."PercentStr") and string.find(self:GetName(), "HealthBar") then
						getglobal(parentName):CreateFontString("$parentPercentStr", "OVERLAY")
						getglobal(parentName.."PercentStr"):SetFont("Interface\\AddOns\\xanUI\\fonts\\barframes.ttf", 12, "OUTLINE");
						if parentName == "PlayerFrame" then
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPRIGHT", -20, -12)
						elseif parentName == "TargetFrame" then
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPLEFT", 20, -12)
						else
							--target of target
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPLEFT", 65, -8)
						end							
						getglobal(parentName.."PercentStr"):SetText(pervalue)
						getglobal(parentName.."PercentStr"):Show()
					elseif string.find(self:GetName(), "HealthBar") then
						getglobal(parentName.."PercentStr"):SetText(pervalue)
					end
					
					if getglobal(parentName.."PercentStr") and not getglobal(parentName.."PercentStr"):IsVisible() then
						getglobal(parentName.."PercentStr"):Show()
					end
					
				end

			end	
			
		end
	end
end)


--[[------------------------
	Blizzard Tradeskills Castbar
	This will modify the target castbar to also show tradeskills
--------------------------]]

local enableTradeskills = true

--initial override
if TargetFrameSpellBar then
	TargetFrameSpellBar.showTradeSkills = enableTradeskills
end


----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

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

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

function XanUI_SaveLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XanUIDB then XanUIDB = {} end
	
	local opt = XanUIDB[frame] or nil

	if not opt then
		XanUIDB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanUIDB[frame]
		return
	end

	local point, relativeTo, relativePoint, xOfs, yOfs = _G[frame]:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
end

function XanUI_RestoreLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not XanUIDB then XanUIDB = {} end

	local opt = XanUIDB[frame] or nil

	if not opt then
		XanUIDB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanUIDB[frame]
	end

	_G[frame]:ClearAllPoints()
	_G[frame]:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
	
	-- xpcall(self.SetPoint, geterrorhandler(), self, self.anchorPoint, self.relativeTo, self.relativePoint, xOffset, yOffset);
	--https://github.com/WeakAuras/WeakAuras2/commit/f02d15dcf50b158e9ba08af0f34f586fdadf015f
	--https://github.com/WeakAuras/WeakAuras2/pull/1425/commits/37c41ae0c9cf978d3151227e2c665eaf3b1cd00e
	--https://github.com/emptyrivers/WeakAuras2/commit/823e682849d7383f33d12eb61af96c8f1037a2d2
	
end

----------------------------------------------------------------
---Change Blizzard Buff timers to be more readable
----------------------------------------------------------------

--THIS CAUSES MASSIVE TAINT ISSUES NEED TO FIND A BETTER WAY

--[[ local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR   = 60 * SECONDS_PER_MINUTE
local SECONDS_PER_DAY    = 24 * SECONDS_PER_HOUR

function SecondsToTimeAbbrev(seconds)
	if seconds <= 0 then return "" end

	local days = seconds / SECONDS_PER_DAY
	if days >= 1 then return string.format("%.1fd", days) end

	local hours = seconds / SECONDS_PER_HOUR
	if hours >= 1 then return string.format("%.02fh", hours) end

	local minutes = seconds / SECONDS_PER_MINUTE
	local seconds = seconds % SECONDS_PER_MINUTE
	if minutes >= 1 then return string.format("%d:%02d", minutes, seconds) end
	return string.format("%ds", seconds)
end
 ]]


----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
--colored nameplates for WOW Classic

local RAID_CLASS_COLORS, FACTION_BAR_COLORS = RAID_CLASS_COLORS, FACTION_BAR_COLORS

local function ClassicNameplateUpdateColor(self)
	local unit = self.unit
	if not unit then return end
	if not string.find(unit, 'nameplate') then return end

	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if not nameplate then return end
		
	local r,g,b
	if UnitIsUnit(unit.."target", "player") then
		r,g,b = 0,1,0
	elseif UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		local color = RAID_CLASS_COLORS[class]
		r, g, b = color.r, color.g, color.b
	elseif CompactUnitFrame_IsTapDenied(self) then
		r, g, b = 0.9, 0.9, 0.9
	else
		local color = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
		r, g, b = color.r, color.g, color.b
	end
	self.healthBar:SetStatusBarColor(r,g,b)
end

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

local eventFrame = CreateFrame("frame","xanUIEventFrame",UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UNIT_TARGET")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");

local TomTomWPS = {}

function eventFrame:PLAYER_LOGIN()
	if not XanUIDB then XanUIDB = {} end
	if not XanUIDB.hidebossframes then XanUIDB.hidebossframes = false end
	if not XanUIDB.raidplates then XanUIDB.raidplates = false end

	local ver = GetAddOnMetadata("xanUI","Version") or 0
		
	SLASH_XANUI1 = "/xanui"
	SLASH_XANUI2 = "/xui"
	SlashCmdList["XANUI"] = function(msg)
	
		local a,b,c=strfind(msg, "(%S+)"); --contiguous string of non-space characters
		
		if a then
			if c and c:lower() == "hidebossframes" then
				if XanUIDB.hidebossframes then
					XanUIDB.hidebossframes = false
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Blizzard Boss Health Frames are now [|cFF99CC33ON|r]")
				else
					XanUIDB.hidebossframes = true
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Blizzard Boss Health Frames are now [|cFF99CC33OFF|r]")
					for i = 1, 4 do
						local frame = _G["Boss"..i.."TargetFrame"]
						frame:UnregisterAllEvents()
						frame:Hide()
						frame.Show = function () end
					end
				end
				return true
			elseif c and c:lower() == "raidplates" then
				if XanUIDB.raidplates then
					XanUIDB.raidplates = false
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Raid Nameplates are now [|cFF99CC33OFF|r]")
				else
					XanUIDB.raidplates = true
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Raid Nameplates are now [|cFF99CC33ON|r]")
				end
				return true
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage("xanUI")
		DEFAULT_CHAT_FRAME:AddMessage("/xanui hidebossframes - Toggles Hiding Blizzard Boss Health Frames On or Off")
		DEFAULT_CHAT_FRAME:AddMessage("/xanui raidplates - Toggles Raid Nameplates On or Off")

	end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cFF99CC33xanUI|r [v|cFF20ff20"..ver.."|r]   /xanui, /xui")

	--ADD TradeSkills to the Blizzard Default TargetFrameSpellBar
	TargetFrameSpellBar.showTradeSkills = enableTradeskills;

	--move the target or target frame ToT
	--some bosses have these special charge bars to the right of their frame
	--so lets put the TOT below it and to the right slightly
	TargetFrameToT:ClearAllPoints()
	TargetFrameToT:SetPoint("RIGHT", TargetFrame, "RIGHT", 100, -45);
	
	xanUI_CreateFactionIcon(TargetFrame)
	xanUI_CreateFactionIcon(TargetFrameToT)

	--hide the stupid blizzard boss frames
	if XanUIDB.hidebossframes then
		if not IsRetail then return end
		for i = 1, 4 do
			local frame = _G["Boss"..i.."TargetFrame"]
			frame:UnregisterAllEvents()
			frame:Hide()
			frame.Show = function () end
		end
	end
	
	if IsRetail then
	
		--SHOW Quest level information on the quest tracker
		--Color it by level as well if necessary

			hooksecurefunc(QUEST_TRACKER_MODULE, "Update", function(self)
				for i = 1, C_QuestLog.GetNumQuestWatches() do
					local questInfo = C_QuestLog.GetInfo(i)
					--local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
					--local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
					--local title = C_QuestLog.GetTitleForQuestID(questID)
					if ( not questInfo or not questInfo.questID ) then
						break
					end
					local oldBlock = QUEST_TRACKER_MODULE:GetExistingBlock(questInfo.questID)
					if oldBlock then
						local oldBlockHeight = oldBlock.height
						local oldHeight = QUEST_TRACKER_MODULE:SetStringText(oldBlock.HeaderText, questInfo.title, nil, OBJECTIVE_TRACKER_COLOR["Header"])
						local newTitle = "["..questInfo.level.."] "..questInfo.title
						local newHeight = QUEST_TRACKER_MODULE:SetStringText(oldBlock.HeaderText, newTitle, nil, OBJECTIVE_TRACKER_COLOR["Header"])
						oldBlock:SetHeight(oldBlockHeight + newHeight - oldHeight);
					end
				end
			end)

		--another method
		--[[ if IsAddOnLoaded("Blizzard_ObjectiveTracker") then
			hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE, "AddObjective", function(self, block, objectiveKey, text, lineType, useFullHeight, dashStyle, colorStyle, adjustForNoText)
				local blockQuestID = block.id
				if (block.HeaderText and blockQuestID) then
					local i = 1
					--get QuestTitle for blockQuestID
					while GetQuestLogTitle(i) do
						local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, questID, isDaily = GetQuestLogTitle(i)
						if (questTitle and blockQuestID and questID and level and blockQuestID == questID) then
							self:SetStringText(block.HeaderText, "[" .. level .. "] " .. questTitle, nil, OBJECTIVE_TRACKER_COLOR["Header"], block.isHighlighted)
							break
						end
						i = i + 1
					end
				end
			end)
		end ]]

		--Move the FocusFrameToT Frame to the right of the Focus frame
		FocusFrameToT:ClearAllPoints()
		FocusFrameToT:SetPoint("RIGHT", FocusFrame, "RIGHT", 95, 0);
	
		-- Always show missing transmogs in tooltips
		C_TransmogCollection.SetShowMissingSourceInItemTooltips(true)
		
		--edit the character panel stats
		xanUI_InsertStats()
		
		--achievement checkmark
		hooksecurefunc("ToggleAchievementFrame", function() AchGreenChkSetup() end)
		
		--spec icons
		xanUI_CreateClassSpecIcons(TargetFrame)
		
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
		
	else
		--it's WOW classic
		hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ClassicNameplateUpdateColor)
		hooksecurefunc("CompactUnitFrame_UpdateHealth", ClassicNameplateUpdateColor)

	end
	
	--if TomTom and IsRetail then
		--add the Shal'Aran portal destinations because it's annoying to remember them
		--crazy is for the crazy arrow, setting cleardistance allows the waypoint to persist even when you go near it.  Otherwise it gets removed when you approach.
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 39.1/100, 76.3/100, { title = "Portal: Felsoul Hold", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 21.5/100, 29.9/100, { title = "Portal: Falanaar", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 30.8/100, 10.9/100, { title = "Portal: Moon Guard Stronghold", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 43.6/100, 79.1/100, { title = "Portal: Lunastre Estate", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 36.2/100, 47.1/100, { title = "Portal: Ruins of Elune'eth", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 47.6/100, 81.6/100, { title = "Portal: The Waning Crescent", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 43.4/100, 60.7/100, { title = "Portal: Sanctum of Order", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 42.2/100, 35.4/100, { title = "Portal: Tel'anor", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 64.0/100, 60.4/100, { title = "Portal: Twilight Vineyards", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 54.4/100, 69.5/100, { title = "Portal: Harbor (Quest Required)", crazy=false, persistent=true, cleardistance=0 }) )
		--table.insert(TomTomWPS, TomTom:AddWaypoint(TomTom.NameToMapId["Suramar"], 52.03/100, 78.86/100, { title = "Portal: Evermoon Terrace (Quest Required)", crazy=false, persistent=true, cleardistance=0 }) )
		--add them all to a table to remove them in the future
	--end
		
	--make sure to set Status Text to Numeric Values in Interface Options for this to work
	--"PERCENT" and "NUMERIC"
	--GetCVarDefault("statusTextDisplay") -> "NUMERIC"
	--GetCVarDefault("statusText") -> "0"

	--force Numeric for healthbar fix
	SetCVar("statusText","1")
	SetCVar("statusTextDisplay","NUMERIC")
	--InterfaceOptionsStatusTextPanelDisplayDropDown:SetValue("NUMERIC")
	
	--OPTIONS PANEL
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/InterfaceOptionsPanels.lua
	
	--NAMEPLATES
	--http://www.wowinterface.com/forums/showthread.php?t=55998
	SetCVar("nameplateShowAll", 1) -- always show the nameplates (combat/noncombat)
	SetCVar("nameplateShowFriends", 1) -- show for friendly units
	--SetCVar("nameplateShowFriendlyNPCs", 0) --show the nameplates on friendly units as well

	SetCVar("nameplateShowEnemies", 1) -- Enemy
	--SetCVar("nameplateShowEnemyMinions", 0) -- Enemy Minions
	SetCVar("nameplateShowEnemyMinus", 1) -- Enemy Minors
	
	SetCVar("nameplateMaxDistance", 100) --default 60

	--Hostile, Quest, and Interactive NPCs:
	if IsRetail then
		SetCVar("UnitNameFriendlySpecialNPCName", "1");
		SetCVar("UnitNameHostleNPC", "1");
		SetCVar("UnitNameInteractiveNPC", "1");
		SetCVar("ShowQuestUnitCircles", "1");
	end
	SetCVar("UnitNameNPC", "0"); --this is necessary as part of the (Hostile, Quest, and Interactive NPCs) group
	
	--NamePanelOptions
	--SetCVar("UnitNameOwn", "0");
	--SetCVar("UnitNameNonCombatCreatureName", "0");
	SetCVar("UnitNameFriendlyPlayerName", "1");
	SetCVar("UnitNameFriendlyMinionName", "1");
	SetCVar("UnitNameEnemyPlayerName", "1");
	SetCVar("UnitNameEnemyMinionName", "1");

	--only create the pet bar for Warlock, Mage and Hunter
	local _, class = UnitClass("player")
	
	if class == "HUNTER" or class == "WARLOCK" or class == "MAGE" then
		XanUI_CreatePetBar()
	end
	
	if enableTalkingHeadSilence then
		XanUI_SetupTalkingHeadSilence()
	end
	
	eventFrame:UnregisterEvent("PLAYER_LOGIN")
end

function eventFrame:ADDON_LOADED(event, addonName)
	if enableTalkingHeadSilence then
		XanUI_SetupTalkingHeadSilence(addonName)
	end
end

function eventFrame:PLAYER_TARGET_CHANGED()
	xanUI_UpdateFactionIcon("target", TargetFrame)
	xanUI_UpdateClassSpecIcon()
end

function eventFrame:UNIT_TARGET(self, unitid)
	--update target of target because PLAYER_TARGET_CHANGED doesn't always work
	if UnitExists("targettarget") then
		xanUI_UpdateFactionIcon("targettarget", TargetFrameToT)
	end
	
end

----------------------------------------------------------------
---Shows talking head dialogue only once per session, don't spam it constantly
----------------------------------------------------------------

if enableTalkingHeadSilence then
	eventFrame:RegisterEvent("TALKINGHEAD_REQUESTED")
end

local talkingHeadDB = {}
local lastTalkingVO

function eventFrame:TALKINGHEAD_REQUESTED()
	local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead = C_TalkingHead.GetCurrentLineInfo()
	
	-- if (talkingHeadDB[vo]) then
		-- C_Timer.After(1, TalkingHeadFrame_CloseImmediately)
	-- else
		-- talkingHeadDB[vo] = true
	-- end
	
	local inInstance, instanceType = IsInInstance()
	
	--only do the talking head filtering in instances, in outside world for quests and stuff don't filter it
	if inInstance and vo then
		if not talkingHeadDB[vo] then
			_G.TalkingHeadFrame_PlayCurrent()
			talkingHeadDB[vo] = true
		else
			--don't spam the notice
			if not lastTalkingVO or lastTalkingVO ~= vo then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF96xanUI: TalkingHead conversation silenced.|r")
				lastTalkingVO = vo
			end
		end
	else
		_G.TalkingHeadFrame_PlayCurrent()
	end
end

function XanUI_SetupTalkingHeadSilence(addonName)
	LoadAddOn("Blizzard_TalkingHeadUI") 
	
	if addonName and addonName == "Blizzard_TalkingHeadUI" then
		_G.TalkingHeadFrame:UnregisterEvent('TALKINGHEAD_REQUESTED')
		return
	end
	
	if _G.TalkingHeadFrame or IsAddOnLoaded("Blizzard_TalkingHeadUI") then
		_G.TalkingHeadFrame:UnregisterEvent('TALKINGHEAD_REQUESTED')
	end

end

----------------------------------------------------------------
---Shows total gold if any in the mailbox
----------------------------------------------------------------
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")

function eventFrame:MAIL_SHOW()
	if not MailFrame.totalMoneyInBox then
		MailFrame.totalMoneyInBox = MailFrame:CreateFontString(nil, "OVERLAY")
		MailFrame.totalMoneyInBox:SetFontObject('NumberFontNormal')
		MailFrame.totalMoneyInBox:SetPoint("CENTER", MailFrame, "TOP", 0, 12)
	end
end

function eventFrame:MAIL_INBOX_UPDATE()
	if not MailFrame.totalMoneyInBox then return end

	local mountCount = 0

	local numInbox = GetInboxNumItems()

	--scan the inbox
	if (numInbox > 0) then
		for mailIndex = 1, numInbox do
			local packageIcon, stationeryIcon, sender, subject, money = GetInboxHeaderInfo(mailIndex)
			if money > 0 then
				mountCount = mountCount + money
			end
		end
	end
	
	if mountCount > 0 then
		MailFrame.totalMoneyInBox:SetText("Total Money: "..GetCoinTextureString(mountCount))
	else
		MailFrame.totalMoneyInBox:Hide()
	end
	
end


function eventFrame:MAIL_CLOSED()
	if MailFrame.totalMoneyInBox then MailFrame.totalMoneyInBox:Hide() end
end

----------------------------------------------------------------
---Open all bags when at bank
----------------------------------------------------------------
eventFrame:RegisterEvent("BANKFRAME_OPENED")

function eventFrame:BANKFRAME_OPENED()
	local numSlots, full
	local i

	numSlots, full = GetNumBankSlots()
	for i = 0, numSlots do
		OpenBag(NUM_BAG_SLOTS + 1 + i)
	end
end

----------------------------------------------------------------
---Sell Junk at Vendors
----------------------------------------------------------------
eventFrame:RegisterEvent("MERCHANT_SHOW")

local doGuildRepairs = false
eventFrame.GreyLootList = {}
eventFrame.moneyCount = 0
eventFrame.itemCount = 0
eventFrame.sellAttempts = 0
eventFrame.totalSlots = 0

local ignoreList = {
	[140662] = "Deformed Eredar Head", --warlock artifact quest
	[140661] = "Damaged Eredar Head", --warlock artifact quest
	[140663] = "Malformed Eredar Head", --warlock artifact quest
	[140664] = "Deficient Eredar Head", --warlock artifact quest
	[140665] = "Nearly Satisfactory Eredar Head", --warlock artifact quest
	--these two items for some reason break the selling
	------
	[158178] = "Mangled Tortollan Scroll", -- mangled-tortollan-scroll
	--[167873] = "Remnant of the Void", -- remnant-of-the-void
	------
}

function eventFrame:StopSellingTimer(endedEarly)
	LibAceTimer:CancelTimer(eventFrame.sellGreyTimer)
	eventFrame.sellGreyTimer = nil
	if endedEarly then
		DEFAULT_CHAT_FRAME:AddMessage("xanUI: (WARNING) you exited merchant before addon could finish selling greys.")
	end

	if eventFrame.moneyCount > 0 then
		DEFAULT_CHAT_FRAME:AddMessage("xanUI: <"..eventFrame.itemCount.."> Total grey items vendored. ["..GetCoinTextureString(eventFrame.moneyCount).."]")
	end		
end

function eventFrame:MERCHANT_SHOW()
	
	--reset our variables
	eventFrame.moneyCount = 0
	eventFrame.itemCount = 0
	eventFrame.GreyLootList = {}
	eventFrame.totalSlots = 0
	eventFrame.sellIndexCount = 0
	
	-- gather info
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if itemID and not ignoreList[itemID] then
				local _, stackCount, _, quality, _, _, itemLink, _, noValue = GetContainerItemInfo(bag, slot)
				if quality == 0 and not noValue then
					local _, _, _, _, _, itemType, _, _, _, _, itemSellPrice = GetItemInfo(itemID)
					--make sure it's not a quest item and it has a sell value
					if itemType ~= "Quest" and quality == 0 and itemSellPrice > 0 then
						local stackPrice = (itemSellPrice or 0) * stackCount
						table.insert(eventFrame.GreyLootList, {bag=bag, slot=slot, itemID=itemID, stackCount=stackCount, stackPrice=stackPrice, itemSellPrice=itemSellPrice} )
					end
				end
			end
			eventFrame.totalSlots = eventFrame.totalSlots + 1
		end
	end
	
	--do the timer for selling, only if we have something to work with
	if #eventFrame.GreyLootList > 0 and not eventFrame.sellGreyTimer then
		eventFrame.sellGreyTimer = LibAceTimer:ScheduleRepeatingTimer(function()
			
			--if they closed early then send a warning
			if not MerchantFrame:IsVisible() then eventFrame:StopSellingTimer(true) end
			
			--if our attempts are more than wants on the list or more than our total amount of slots then exit
			if eventFrame.sellIndexCount > #eventFrame.GreyLootList or eventFrame.sellIndexCount >= eventFrame.totalSlots or eventFrame.sellIndexCount > 2000 then
				eventFrame:StopSellingTimer()
				return
			end
			
			eventFrame.sellIndexCount = eventFrame.sellIndexCount + 1
			
			--grab the next entry in our table
			if eventFrame.GreyLootList[eventFrame.sellIndexCount] then
			
				local index = eventFrame.sellIndexCount
				--print(index, eventFrame.GreyLootList[index].bag, eventFrame.GreyLootList[index].slot, eventFrame.GreyLootList[index].itemID, eventFrame.GreyLootList[index].stackCount, eventFrame.GreyLootList[index].stackPrice, eventFrame.GreyLootList[index].itemSellPrice)
				
				eventFrame.moneyCount = eventFrame.moneyCount + eventFrame.GreyLootList[index].stackPrice
				eventFrame.itemCount = eventFrame.itemCount + 1
				
				--print(eventFrame.itemCount , eventFrame.moneyCount)
				UseContainerItem(eventFrame.GreyLootList[index].bag, eventFrame.GreyLootList[index].slot)	
			else
				--we don't have another index so exit the timer
				eventFrame:StopSellingTimer()
			end
		
		end, 0.15)
	end
	
	--do repairs
	if CanMerchantRepair() then
		local repairCost, canRepair = GetRepairAllCost()
		if canRepair and repairCost > 0 then
			if doGuildRepairs and CanGuildBankRepair() then
				local amount = GetGuildBankWithdrawMoney()
				local guildMoney = GetGuildBankMoney()
				if amount == -1 then
					amount = guildMoney
				else
					amount = min(amount, guildMoney)
				end
				if amount > repairCost then
					RepairAllItems(1)
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Repaired from Guild. ["..GetCoinTextureString(repairCost).."]")
					return
				else
					DEFAULT_CHAT_FRAME:AddMessage("xanUI: Insufficient guild funds to make repairs. ["..GetCoinTextureString(repairCost).."]")
				end
			elseif GetMoney() > repairCost then
				RepairAllItems()
				DEFAULT_CHAT_FRAME:AddMessage("xanUI: Repaired all items. ["..GetCoinTextureString(repairCost).."]")
				return
			else
				DEFAULT_CHAT_FRAME:AddMessage("xanUI: Insufficient funds to make repairs. ["..GetCoinTextureString(repairCost).."]")
			end
		end
	end
	
end

--https://github.com/Gethe/wow-ui-source/blob/2ca215b373e6107bdc7f1e2715fc0c2ec4720a14/AddOns/Blizzard_InspectUI/InspectPaperDollFrame.lua
--DressUpSources(C_TransmogCollection.GetInspectSources());

-- function TransmogOutfitGetTransmog(slot)
	-- local transmog
	-- local baseSourceID, _, appliedSourceID, _, pendingSourceID, _, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slot, LE_TRANSMOG_TYPE_APPEARANCE)
	-- if hasPendingUndo then
		-- transmog = baseSourceID
	-- elseif pendingSourceID ~= 0 then
		-- transmog = pendingSourceID
	-- elseif appliedSourceID ~= 0 then
		-- transmog = appliedSourceID
	-- else
		-- transmog = baseSourceID
	-- end
	-- return transmog
-- end

-- function TransmogOutfitSetTransmog(slot, transmog)
	-- local _, _, _, canTransmogrify = C_Transmog.GetSlotInfo(slot, LE_TRANSMOG_TYPE_APPEARANCE)
	-- if canTransmogrify then
		-- C_Transmog.SetPending(slot, LE_TRANSMOG_TYPE_APPEARANCE, transmog)
	-- end
-- end

-- function TransmogOutfitGetEnchant(slot)
	-- local enchant
	-- local baseSourceID, _, appliedSourceID, _, pendingSourceID, _, hasPendingUndo = C_Transmog.GetSlotVisualInfo(slot, LE_TRANSMOG_TYPE_ILLUSION)
	-- if hasPendingUndo then
		-- enchant = baseSourceID
	-- elseif pendingSourceID ~= 0 then
		-- enchant = pendingSourceID
	-- elseif appliedSourceID ~= 0 then
		-- enchant = appliedSourceID
	-- else
		-- enchant = baseSourceID
	-- end
	-- return enchant
-- end

-- function TransmogOutfitSetEnchant(slot, enchant)
	-- local _, _, _, canTransmogrify = C_Transmog.GetSlotInfo(slot, LE_TRANSMOG_TYPE_ILLUSION)
	-- if canTransmogrify then
		-- C_Transmog.SetPending(slot, LE_TRANSMOG_TYPE_ILLUSION, enchant)
	-- end
-- end


-- SLASH_LOC1 = "/loc";
-- SlashCmdList["LOC"] = function(arg)
    -- local id = C_Map.GetBestMapForUnit("player")
    -- if not id then
        -- print("No");
        -- return;
    -- end

    -- local pos = C_Map.GetPlayerMapPosition(id, "player");
    -- if not pos then
        -- print("No");
        -- return;
    -- end
    -- local x,y = pos:GetXY();
    -- local output = string.format("%s:%.2f,%.2f",GetZoneText(),x100,y100);

    -- if arg == 'say' then
        -- SendChatMessage(output, "SAY");
    -- elseif arg == 'party' then
        -- SendChatMessage(output, "PARTY");
    -- elseif arg == 'raid' then
        -- SendChatMessage(output, "RAID");
    -- elseif arg == 'general' then
        -- local channelId;
        -- for i=1,20,1 do
            -- local id, name = GetChannelName(i);
            -- if(string.find(name:lower(), "general") ~= nil) then
                -- channelId = i;
                -- break;
            -- end
        -- end
        -- SendChatMessage(output, "CHANNEL", nil, channelId);
    -- else
        -- print(output);
    -- end
 -- end 
 
 
 -- /run local x, y = GetPlayerMapPosition("player") SendChatMessage(("%s is up at %s (%0.1f, %0.1f)"):format(UnitName("target"), GetMinimapZoneText(), x*100, y*100), "CHANNEL", nil, 1)