--This is a modified version of Tuller's Sage UI
--All credit goes to Tuller
------------------------------------------------

XSpellBar = {}

local min = math.min
local GetTime = _G['GetTime']
local frames = {}

XSpellBar.showTradeSkills = true;

--Disable the default Target Spell Casting Bar
--TargetFrameSpellBar:UnregisterAllEvents()

--ADD TradeSkills to the Blizzard Default TargetFrameSpellBar
TargetFrameSpellBar.showTradeSkills = XSpellBar.showTradeSkills;

function XSpellBar:New(parent)

	local f = CreateFrame('Frame', parent:GetName() .. 'Cast', parent)
	f:SetScript('OnShow', self.Update)
	f:SetScript('OnUpdate', function(self, elapsed) XSpellBar:OnUpdate(self, elapsed) end)

	f:SetWidth(80)
	f:SetHeight(10)
	f:SetPoint('BOTTOMLEFT', parent, 'BOTTOMRIGHT',-6, 25)
	
	local icon = f:CreateTexture(f:GetName() .. 'Icon', 'ARTWORK')
	icon:SetPoint('BOTTOMLEFT', f)
	icon:SetHeight(10)
	icon:SetWidth(10)
	icon:SetTexture("Interface\\Icons\\Spell_Shadow_Shadowbolt")
	icon:Show()
	f.icon = icon
	
	local bar = CreateFrame("StatusBar", nil, f)
	bar:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT')
	bar:SetPoint('BOTTOMRIGHT', f)
	bar:SetScript('OnUpdate', function(self, elapsed) XSpellBar:OnUpdate(self, elapsed) end)
	bar:SetWidth(80)
	bar:SetHeight(10)
	bar:SetStatusBarTexture("Interface\\AddOns\\XanUI\\statusbar")
	bar:Show()
	f.bar = bar

	local barbg = CreateFrame("StatusBar", nil, f)
	barbg:SetMinMaxValues(0, 1)
	barbg:SetValue(1)
	barbg:SetAllPoints(bar)
	barbg:SetWidth(80)
	barbg:SetHeight(10)
	barbg:SetStatusBarTexture("Interface\\AddOns\\XanUI\\statusbar")
	barbg:Show()
	f.bg = barbg
	
	local text = bar:CreateFontString(nil, "OVERLAY")
	text:SetFont("Interface\\AddOns\\XanUI\\fonts\\barframes.ttf", 10);
	text:SetJustifyH("LEFT")
	text:SetJustifyV("CENTER")
	text:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT')
	text:SetWordWrap(false)
	text:SetWidth(bar:GetWidth()-10)
	f.text = text

	table.insert(frames, f)
	
	XSpellBar:UpdateUnit(nil, f)

	return f
end

function XSpellBar:UpdateUnit(newUnit, frm)
	local newUnit = newUnit or frm:GetParent():GetAttribute('unit')
	if frm.unit ~= newUnit then
		frm.unit = newUnit
		XSpellBar:Update(frm)
	end
end

function XSpellBar:Update(frm)
	if not frm then frm = self end
	if frm.unit then
		if UnitCastingInfo(frm.unit) then
			XSpellBar:OnSpellStart(frm)
		elseif UnitChannelInfo(frm.unit) then
			XSpellBar:OnChannelStart(frm)
		else
			XSpellBar:Finish(frm)
		end
	end
end

function XSpellBar:OnUpdate(frm, elapsed)
	if frm.casting then
		local value = min(GetTime(), frm.maxValue)

		if value == frm.maxValue then
			XSpellBar:Finish(frm)
		else
			frm.bar:SetValue(value)
		end
	elseif frm.channeling then
		local value = min(GetTime(), frm.endTime)

		if value == frm.endTime then
			XSpellBar:Finish(frm)
		else
			frm.bar:SetValue(frm.startTime + (frm.endTime - value))
		end
	end
end

--[[ Event Functions ]]--

function XSpellBar:OnSpellStart(frm)
	if not frm then frm = self end
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(frm.unit)
	if not(name) or (not XSpellBar.showTradeSkills and isTradeSkill) then
		frm:Hide()
		return
	end

	frm.bar:SetStatusBarColor(0, 1, 1, 0.8)
	frm.bg:SetStatusBarColor(0, 1, 1, 0.3)
	
	frm.startTime = startTime / 1000
	frm.maxValue = endTime / 1000

	frm.bar:SetMinMaxValues(frm.startTime, frm.maxValue)
	frm.bar:SetValue(frm.startTime)

	frm.icon:SetTexture(texture)

	frm.text:SetText(name)

	frm.casting = true
	frm.channeling = nil
	frm:Show()
end

function XSpellBar:OnSpellDelayed(frm)
	if not frm then frm = self end
	if frm:IsVisible() then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(frm.unit)
		if not(name) or (not XSpellBar.showTradeSkills and isTradeSkill) then
			frm:Hide()
			return
		end

		frm.startTime = startTime / 1000
		frm.maxValue = endTime / 1000

		frm.bar:SetMinMaxValues(frm.startTime, frm.maxValue)

		if not frm.casting then
			frm.bar:SetStatusBarColor(1, 0.7, 0, 0.8)
			frm.bg:SetStatusBarColor(1, 0.7, 0, 0.3)
			frm.casting = true
			frm.channeling = nil
		end
	end
end

function XSpellBar:OnChannelStart(frm)
	if not frm then frm = self end
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(frm.unit)
	if not(name) or (not XSpellBar.showTradeSkills and isTradeSkill) then
		frm:Hide()
		return
	end

	frm.bar:SetStatusBarColor(0, 1, 1, 0.8)
	frm.bg:SetStatusBarColor(0, 1, 1, 0.3)

	frm.startTime = startTime / 1000
	frm.endTime = endTime / 1000
	frm.duration = frm.endTime - frm.startTime
	frm.maxValue = frm.startTime

	frm.bar:SetMinMaxValues(frm.startTime, frm.endTime)
	frm.bar:SetValue(frm.endTime)
	
	frm.icon:SetTexture(texture)

	frm.text:SetText(name)

	frm.casting = nil
	frm.channeling = true
	frm:Show()
end

function XSpellBar:OnChannelUpdate(frm)
	if not frm then frm = self end
	if frm:IsVisible() then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(frm.unit)
		if not(name) or (not XSpellBar.showTradeSkills and isTradeSkill) then
			frm:Hide()
			return
		end

		frm.startTime = startTime / 1000
		frm.endTime = endTime / 1000
		frm.maxValue = self.startTime
		frm.bar:SetMinMaxValues(frm.startTime, frm.endTime)
	end
end

function XSpellBar:OnSpellStop(frm)
	if not frm then frm = self end
	if not frm.channeling then
		XSpellBar:Finish(frm)
	end
end

function XSpellBar:Finish(frm)
	if not frm then frm = self end
	frm.casting = nil
	frm.channeling = nil
	frm.bar:SetStatusBarColor(0, 0, 0, 0.8)
	frm.bg:SetStatusBarColor(0, 0, 0, 0.3)
	frm:Hide()
end


--[[ Utility Functions ]]--

function XSpellBar:ForVisibleUnit(unit, method, ...)

	for _,frm in pairs(frames) do
		if frm.unit == unit and frm:GetParent():IsVisible() then
			XSpellBar[method](frm, ...)
		end
	end
end

function XSpellBar:ForAllVisible(method, ...)
	for _,frm in pairs(frames) do
		if frm:GetParent():IsVisible() then
			XSpellBar[method](frm, ...)
		end
	end
end

--double check the target castbar hasn't lost the tradeskill setting (another mod may change it)
hooksecurefunc("CastingBarFrame_OnEvent", function(self, event, ...)
	if self and self:GetName() == "TargetFrameSpellBar" and XSpellBar then
		if TargetFrameSpellBar.showTradeSkills ~= XSpellBar.showTradeSkills then
			TargetFrameSpellBar.showTradeSkills = XSpellBar.showTradeSkills;
		end
	end
end)

--[[ Events ]]--

do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, unit)
		if event == 'UNIT_SPELLCAST_START' then
			XSpellBar:ForVisibleUnit(unit, 'OnSpellStart')
		elseif event == 'UNIT_SPELLCAST_DELAYED' then
			XSpellBar:ForVisibleUnit(unit, 'OnSpellDelayed')
		elseif event == 'UNIT_SPELLCAST_CHANNEL_START' then
			XSpellBar:ForVisibleUnit(unit, 'OnChannelStart')
		elseif event == 'UNIT_SPELLCAST_CHANNEL_UPDATE' then
			XSpellBar:ForVisibleUnit(unit, 'OnChannelUpdate')
		elseif event == 'UNIT_SPELLCAST_STOP' then
			XSpellBar:ForVisibleUnit(unit, 'OnSpellStop')
		elseif event == 'UNIT_SPELLCAST_FAILED' or event == 'UNIT_SPELLCAST_INTERRUPTED' or event == 'UNIT_SPELLCAST_CHANNEL_STOP' then
			XSpellBar:ForVisibleUnit(unit, 'Finish')
		elseif event == 'PLAYER_ENTERING_WORLD' then
			XSpellBar:ForAllVisible('Update')
		end
	end)

	f:RegisterEvent('PLAYER_ENTERING_WORLD')
	f:RegisterEvent('UNIT_SPELLCAST_START')
	f:RegisterEvent('UNIT_SPELLCAST_DELAYED')
	f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
	f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
	f:RegisterEvent('UNIT_SPELLCAST_STOP')
	f:RegisterEvent('UNIT_SPELLCAST_FAILED')
	f:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
	f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
end