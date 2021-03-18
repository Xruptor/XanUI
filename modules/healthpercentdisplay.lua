local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "healthpercentdisplay"

--this is an old function that isn't used anymore, we used to use it to shorten the healthbar numbers because they used to be large in the millions
local function xanUI_smallNum(sNum)
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

--Display a small percent string above the health unitframes
hooksecurefunc("TextStatusBar_UpdateTextString", function(self)
	if not addon.CanAccessObject(self) then return end
	
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
