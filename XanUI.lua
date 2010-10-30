--[[
	NOTE: A lot of this addon is from bits and peices of other addons.
	I just wanted to compile them together into one single addon for my own purposes
--]]

----------------------------------------------------------------
---COLOR BARS BY CLASS
----------------------------------------------------------------

local   UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS = UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS
local _, class, c

local function colour(statusbar, unit)
	if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
		_, class = UnitClass(unit)
		c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		statusbar:SetStatusBarColor(c.r, c.g, c.b)
	end
end

hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
	colour(self, self.unit)
end)

local sb = _G.GameTooltipStatusBar
local addon = CreateFrame("Frame", "StatusColour")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:SetScript("OnEvent", function()
	colour(sb, "mouseover")
end)


----------------------------------------------------------------
---FACTION INDICATORS (TARGET ONLY)
----------------------------------------------------------------

function XanUI_CreateFactionIcon(frame)
	local f
	
	f = CreateFrame("Frame", "$parentFaction", frame)

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(40)
	f:SetHeight(40)

	local t = f:CreateTexture("$parentIcon", "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\XanUI\\Unknown")
	t:SetAllPoints(f)
	
	if frame == TargetFrame then
		f:SetPoint("CENTER", 67, 24)
	else
		f:SetPoint("CENTER", -6, 10)
	end
	
	f:Hide()
end

function XanUI_UpdateFactionIcon(unit, frame)
	if not unit then return nil; end
	if not frame then return nil; end
	
	if frame == TargetFrame then
		--we have to move the target raid icon identifier to the right a bit (skull, diamond, star, etc..)
		TargetFrameTextureFrameRaidTargetIcon:SetPoint("CENTER", TargetFrame, "TOPRIGHT", -82, -74);
		--bottom right to the left of level icon
		
		--we have to move the target leader icon as well
		TargetFrameTextureFrameLeaderIcon:ClearAllPoints();
		TargetFrameTextureFrameLeaderIcon:SetPoint("TOPLEFT", -2, -15);

		--don't show the faction icon if the unit is already in PVP.  The PVP icon is a bigger notifier of what
		--faction a unit is... duh!
		if( UnitFactionGroup(unit) and not TargetFrameTextureFramePVPIcon:IsVisible()) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
		
	else
		if( UnitFactionGroup(unit) ) then
			getglobal(frame:GetName().."FactionIcon"):SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", UnitFactionGroup(unit)))
			getglobal(frame:GetName().."Faction"):Show()
		else
			getglobal(frame:GetName().."Faction"):Hide()
		end	
	end

end

XanUI_CreateFactionIcon(TargetFrame);
	

----------------------------------------------------------------
--Enable a toggle that allows the default blizzard raid UI panels to lock/unlock
----------------------------------------------------------------

SLASH_XANUI1 = "/xanui"
SlashCmdList["XANUI"] = function(arg)
	if not XanUIDB then return nil; end
	if XanUIDB["RaidLock"] == "yes" then
		XanUIDB["RaidLock"] = "no"
		DEFAULT_CHAT_FRAME:AddMessage("XanUI: Blizzard Raid Pullouts are now unlocked.");
	else
		XanUIDB["RaidLock"] = "yes"
		DEFAULT_CHAT_FRAME:AddMessage("XanUI: Blizzard Raid Pullouts are now locked.");
	end
	XanUI_UpdateRaidLocks()
end

function XanUI_UpdateRaidLocks()
	if not XanUIDB["RaidLock"] then XanUIDB["RaidLock"] = "yes" end
	
	--lock the frames
	if XanUIDB["RaidLock"] == "yes" then
		for i=1, 8 do
			local f=_G["RaidPullout"..i]
			if f then f:SetScript("OnDragStart", function() end) end 
		end
	else
	--unlock the frames
		for i=1, 8 do
			local f=_G["RaidPullout"..i] 
			if f then f:SetScript("OnDragStart", function(self) self:SetMovable(true) self:StartMoving() end) end
		end
	end
end

----------------------------------------------------------------
--RAID POSITION UPDATE
----------------------------------------------------------------

local function framesort(a, b)
	return a.label:GetText() < b.label:GetText()
end

function XanUI_UpdateRaidPositions()
	--number of pullsout per column
	local fpr = 3
	
	if NUM_RAID_PULLOUT_FRAMES and not InCombatLockdown() then
		local frm = {}
		local r = 1
		local n = 1

		for i = 1, NUM_RAID_PULLOUT_FRAMES do
			local f = getglobal("RaidPullout" .. i)
			local b = getglobal("RaidPullout" .. i .. "MenuBackdrop")
			
			--hide the background
			b:Hide()
			
			if f and f:IsShown() and f:IsVisible() and f.label and f.label:GetText() then
				frm[n] = f
				n = n + 1
			end
		end

		table.sort(frm, framesort)

		for i = 1, #frm do
		
			frm[i]:ClearAllPoints()
			frm[i]:Show()
			
			if i == 1 then
				frm[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 25, (-UIParent:GetHeight() / 6.5)-5)
			elseif r == fpr then
				frm[i]:SetPoint("TOPLEFT", frm[i - fpr], "TOPRIGHT", 25, 0)
				r = 1
			else
				frm[i]:SetPoint("TOPLEFT", frm[i - 1], "BOTTOMLEFT", 0, -13)
				r = r + 1
			end
		end
	end
end


----------------------------------------------------------------
--Add percents and actual health/mana values to specific frames
--MAKE SURE YOU ENABLED THE TEXT STATUS IN THE BLIZZARD -> OPTIONS -> STATUS TEXT
----------------------------------------------------------------

hooksecurefunc( "TextStatusBar_UpdateTextString", function(self)

	if self and self:GetParent() then
		local frame = self:GetParent();
		
		if frame:GetName() then
		
			local parentName = frame:GetName();
			local textString = self.TextString;
			
			if textString then
				local value = self:GetValue();
				local valueMin, valueMax = self:GetMinMaxValues();
				
				--display according to frame name
				if parentName == "PlayerFrame" then
					if UnitIsDeadOrGhost("player") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("0%")
						end
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
						textString:SetText(value.." / "..valueMax);
						textString:Show();

						if not getglobal(parentName.."PercentStr") and string.find(self:GetName(), "HealthBar") then
							getglobal(parentName):CreateFontString("$parentPercentStr", "OVERLAY")
							getglobal(parentName.."PercentStr"):SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPRIGHT", -20, -12)
							getglobal(parentName.."PercentStr"):SetText(pervalue)
							getglobal(parentName.."PercentStr"):Show()
						elseif string.find(self:GetName(), "HealthBar") then
							getglobal(parentName.."PercentStr"):SetText(pervalue)
						end
						
					end
				elseif parentName == "TargetFrame" then
					if UnitIsDeadOrGhost("target") then
						if getglobal(parentName.."PercentStr") then
							getglobal(parentName.."PercentStr"):SetText("0%")
						end
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
						textString:SetText(XanUI_smallNum(value).." / "..XanUI_smallNum(valueMax));
						textString:Show();
						
						if not getglobal(parentName.."PercentStr") and string.find(self:GetName(), "HealthBar") then
							getglobal(parentName):CreateFontString("$parentPercentStr", "OVERLAY")
							getglobal(parentName.."PercentStr"):SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
							getglobal(parentName.."PercentStr"):SetPoint("CENTER", parentName, "TOPLEFT", 20, -12)
							getglobal(parentName.."PercentStr"):SetText(pervalue)
							getglobal(parentName.."PercentStr"):Show()
						elseif string.find(self:GetName(), "HealthBar") then
							getglobal(parentName.."PercentStr"):SetText(pervalue)
						end
					end
				elseif parentName == "FocusFrame" then
					if UnitIsDeadOrGhost("focus") then
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
						textString:SetText(XanUI_smallNum(value).." / "..XanUI_smallNum(valueMax));
						textString:Show();
					end
				elseif parentName == "PetFrame" then
					if UnitIsDeadOrGhost("pet") then
						textString:SetText("");
						textString:Hide();
						return
					end
					if valueMax > 0 then
						local pervalue = tostring(math.ceil((value / valueMax) * 100)) .. " %";
						textString:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10, "OUTLINE");
						textString:SetText(pervalue);
						textString:Show();
					end
				end	
			end
		end
	end
end)

function XanUI_smallNum(sNum)
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

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

local eventFrame = CreateFrame("Frame", "XanUIEventFrame", UIParent)
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and arg1 == "XanUI" then
		if not XanUIDB then XanUIDB = {} end
		DEFAULT_CHAT_FRAME:AddMessage("XanUI: Loaded /xanui");
	
	elseif ( event == "PLAYER_LOGIN") then
		XanUI_UpdateRaidLocks()
		
		--Move the TargetToT Frame to the right of the target frame
		TargetFrameToT:ClearAllPoints()
		TargetFrameToT:SetPoint("RIGHT", TargetFrame, "RIGHT", 80, 0);
		
		--Move the FocusFrameToT Frame to the right of the Focus frame
		FocusFrameToT:ClearAllPoints()
		FocusFrameToT:SetPoint("RIGHT", FocusFrame, "RIGHT", 80, 0);

		self:UnregisterEvent("PLAYER_LOGIN")
		
	elseif ( event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD" ) then
		XanUI_UpdateRaidPositions()
		
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		 XanUI_UpdateFactionIcon("target", TargetFrame)
	
	elseif ( event == "RAID_ROSTER_UPDATE" ) then
		XanUI_UpdateRaidPositions()
	end
end)

