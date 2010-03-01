--This is a modified version of CT_PartyBuffs.
--All credit goes to the CTMOD Team
------------------------------------------------

local _G = getfenv(0);

local numBuffs = 6 --14 is max
local numDebuffs = 6 --6 is max
local numPetBuffs = 6 --9 is max

function XanUI_PartyBuffs_OnLoad()
	if UnitClass("player") == "Death Knight" then
		getglobal("XanUI_PetBuffFrame"):SetPoint("TOPLEFT", "PlayerFrame", "TOPLEFT", 108, -120);
		PetFrameDebuff1:SetPoint("TOPLEFT", "PetFrame", "TOPLEFT", 48, -63);
	else
		PetFrameDebuff1:SetPoint("TOPLEFT", "PetFrame", "TOPLEFT", 48, -59);
	end
	
	--lets move the party frames a bit lower to prevent any buff/debuff icon overlaps
	PartyMemberFrame1:SetPoint("TOPLEFT", UIParent, 10, -190);  --original -160
end

function XanUI_PartyBuffs_RefreshBuffs(self, elapsed)
	self.update = self.update + elapsed;
	if ( self.update > 0.5 ) then
		self.update = 0.5 - self.update;
		local name = self:GetName();
			local i;
			
		if ( numBuffs == 0 ) then
			for i = 1, 14, 1 do
				_G[name .. "Buff" .. i]:Hide();
			end
			return;
		end
		for i = 1, 14, 1 do
			if ( i > numBuffs ) then
				_G[name .. "Buff" .. i]:Hide();
			else
				local buffname, rank, bufftexture, count, debuffType, duration, expirationTime, source, isStealable = UnitBuff("party" .. self:GetID(), i);
				if ( bufftexture ) then
					_G[name .. "Buff" .. i .. "Icon"]:SetTexture(bufftexture);
					_G[name .. "Buff" .. i]:Show();
					
					cooldown = _G[name .. "Buff" .. i .. "Cooldown"]
					if ( duration ) then
						if ( duration > 0 ) then
							cooldown:Show();
							CooldownFrame_SetTimer(cooldown, expirationTime - duration, duration, 1);
						else
							cooldown:Hide();
						end
					end
				else
					_G[name .. "Buff" .. i]:Hide();
					_G[name .. "Buff" .. i .. "Cooldown"]:Hide();
				end
				
				if ( i <= 4 ) then
					_G["PartyMemberFrame" .. self:GetID() .. "Debuff" .. i]:Hide();
				end
				if ( i <= 6 ) then
					if ( i > numDebuffs ) then
						_G[name .. "Debuff" .. i]:Hide();
					else
						local debuffname, rank, debufftexture, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitDebuff("party" .. self:GetID(), i);
						if ( debufftexture ) then
							local color;
							if ( count > 1 ) then
								_G[name .. "Debuff" .. i .. "Count"]:SetText(count);
							else
								_G[name .. "Debuff" .. i .. "Count"]:SetText("");
							end
							if ( debuffType ) then
								color = DebuffTypeColor[debuffType];
							else
								color = DebuffTypeColor["none"];
							end
							_G[name .. "Debuff" .. i .. "Icon"]:SetTexture(debufftexture);
							_G[name .. "Debuff" .. i]:Show();
							_G[name .. "Debuff" .. i .. "Border"]:SetVertexColor(color.r, color.g, color.b);
						
							cooldown = _G[name .. "Debuff" .. i .. "Cooldown"]
							if ( duration ) then
								if ( duration > 0 ) then
									cooldown:Show();
									CooldownFrame_SetTimer(cooldown, expirationTime - duration, duration, 1);
								else
									cooldown:Hide();
								end
							end
						else
							_G[name .. "Debuff" .. i]:Hide();
							_G[name .. "Debuff" .. i .. "Cooldown"]:Hide();
						end
					end
				end
			end
		end
	end
end

function XanUI_PartyBuffs_RefreshPetBuffs(self, elapsed)
	self.update = self.update + elapsed;
	if ( self.update > 0.5 ) then
		self.update = 0.5 - self.update
		local i;
		if ( numPetBuffs == 0 ) then
			for i = 1, 9, 1 do
				_G[self:GetName() .. "Buff" .. i]:Hide();
			end
			return;
		end
		local _, _, bufftexture;
		for i = 1, 9, 1 do
			if ( i > numPetBuffs ) then
				_G[self:GetName() .. "Buff" .. i]:Hide();
			else
				local buffname, rank, bufftexture, count, debuffType, duration, expirationTime, source, isStealable = UnitBuff("pet", i);
				if ( bufftexture ) then
					_G[self:GetName() .. "Buff" .. i .. "Icon"]:SetTexture(bufftexture);
					_G[self:GetName() .. "Buff" .. i]:Show();
					
					cooldown = _G[self:GetName() .. "Buff" .. i .. "Cooldown"]
					if ( duration ) then
						if ( duration > 0 ) then
							cooldown:Show();
							CooldownFrame_SetTimer(cooldown, expirationTime - duration, duration, 1);
						else
							cooldown:Hide();
						end
					end
					
				else
					_G[self:GetName() .. "Buff" .. i]:Hide();
					_G[self:GetName() .. "Buff" .. i .. "Cooldown"]:Hide();
				end
			end
		end
	end
end

function XanUI_PartyMemberBuffTooltip_Update(pet)
	if ( ( pet and numPetBuffs > 0 ) or ( not pet and numBuffs > 0 ) ) then
		PartyMemberBuffTooltip:Hide();
	end
end

hooksecurefunc("PartyMemberBuffTooltip_Update", XanUI_PartyMemberBuffTooltip_Update);


