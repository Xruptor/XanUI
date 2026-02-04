local ADDON_NAME, private = ...
local L = (private and private.L) or setmetatable({}, { __index = function(_, key) return key end })
local addon = private and private.GetAddonFrame and private:GetAddonFrame(ADDON_NAME) or _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

local moduleName = "missionmenu"

local function GetAtlasInfo(atlas)
	if type(atlas) == "table" then
		for _, name in ipairs(atlas) do
			local info = C_Texture.GetAtlasInfo(name)
			if info then
				local file = info.filename or info.file
				return file, info.width, info.height, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord, info.tilesHorizontally, info.tilesVertically
			end
		end
		return
	end

	local info = C_Texture.GetAtlasInfo(atlas)
	if info then
		local file = info.filename or info.file
		return file, info.width, info.height, info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord, info.tilesHorizontally, info.tilesVertically
	end
end

local function addButton(level, text, isTitle, notCheckable, hasArrow, value, func, minimapIcon)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.isTitle = isTitle
    info.notCheckable = notCheckable
    info.hasArrow = hasArrow
    info.value = value
    info.func = func

    if minimapIcon then
        local filename, width, height, txLeft, txRight, txTop, txBottom = GetAtlasInfo(minimapIcon)

        info.icon = filename
        info.tCoordLeft = txLeft
        info.tCoordRight = txRight
        info.tCoordTop = txTop
        info.tCoordBottom = txBottom
        info.tSizeX = 20  -- width
        info.tSizeY = 20  -- height
    end

    UIDropDownMenu_AddButton(info, level)
end

local function MM_CreateMenu()

    local xanMissionMenu = CreateFrame("Frame", "XanUI_MissionMenu")
	xanMissionMenu.displayMode = 'MENU'

	addon.MM_Dropdown = xanMissionMenu

	local playerInfo = {}
	playerInfo.factionGroup = UnitFactionGroup("player")
	playerInfo.className = select(2, UnitClass("player"))

	local covenantData = C_Covenants.GetCovenantData(C_Covenants.GetActiveCovenantID())

	playerInfo.covenantTex = covenantData ~= nil and covenantData.textureKit or "kyrian"
	playerInfo.covenantID = covenantData ~= nil and covenantData.ID or Enum.CovenantType.Kyrian

	local classIconName = playerInfo.className
	if playerInfo.className == "EVOKER" then
		classIconName = "SHAMAN" --for legion the Evokers don't have a class hall, use the shaman one instead
	end

	local landingEnum = Enum and Enum.ExpansionLandingPageType
	local warWithinLandingType = landingEnum
		and (landingEnum.TheWarWithin or landingEnum.WarWithin or landingEnum.KhazAlgar)
	local warWithinExpansionID = _G.LE_EXPANSION_WAR_WITHIN or _G.LE_EXPANSION_THE_WAR_WITHIN
		or (LE_EXPANSION_DRAGONFLIGHT and LE_EXPANSION_DRAGONFLIGHT + 1)
	local warWithinName = _G.EXPANSION_NAME10 or "The War Within"

	local expansions = {
		{
			["key"] = "WarlordsOfDraenor",
			["id"] = LE_EXPANSION_WARLORDS_OF_DRAENOR,
			["name"] = EXPANSION_NAME5,
			["banner"] = "accountupgradebanner-wod",
			["garrisonTypeID"] = Enum.GarrisonType.Type_6_0, --2
			["minimapIcon"] = string.format("GarrLanding-MinimapIcon-%s-Up", playerInfo.factionGroup),
			["landingPageType"] = 1, --use 1 for the older landingpages and 2 for the newer dragonflight ones
		},
		{
			["key"] = "Legion",
			["id"] = LE_EXPANSION_LEGION,
			["name"] = EXPANSION_NAME6,
			["banner"] = "accountupgradebanner-legion",
			["garrisonTypeID"] = Enum.GarrisonType.Type_7_0, --3
			["minimapIcon"] = string.format("legionmission-landingbutton-%s-up", classIconName),
			["landingPageType"] = 1,
		},
		{
			["key"] = "BattleForAzeroth",
			["id"] = LE_EXPANSION_BATTLE_FOR_AZEROTH,
			["name"] = EXPANSION_NAME7,
			["banner"] = "accountupgradebanner-bfa",
			["garrisonTypeID"] = Enum.GarrisonType.Type_8_0, --9
			["minimapIcon"] = string.format("bfa-landingbutton-%s-up", playerInfo.factionGroup),
			["landingPageType"] = 1,
		},
		{
			["key"] = "Shadowlands",
			["id"] = LE_EXPANSION_SHADOWLANDS,
			["name"] = EXPANSION_NAME8,
			["banner"] = "accountupgradebanner-shadowlands",
			["garrisonTypeID"] = Enum.GarrisonType.Type_9_0, --111
			["minimapIcon"] = string.format("shadowlands-landingbutton-%s-up", playerInfo.covenantTex),
			["landingPageType"] = 1,
		},
		{
			["key"] = "Dragonflight",
			["id"] = LE_EXPANSION_DRAGONFLIGHT,
			["name"] = EXPANSION_NAME9,
			["banner"] = "accountupgradebanner-dragonflight",
			["garrisonTypeID"] = landingEnum and landingEnum.Dragonflight,
			["minimapIcon"] = "dragonflight-landingbutton-up",
			["landingPageType"] = 2,
		},
		{
			["key"] = "TheWarWithin",
			["id"] = warWithinExpansionID,
			["name"] = warWithinName,
			["banner"] = "accountupgradebanner-warwithin",
			["garrisonTypeID"] = warWithinLandingType,
			["minimapIcon"] = { "khazalgar-landingbutton-up", "dragonflight-landingbutton-up" },
			["landingPageType"] = 2,
		},
	}

	local function openMissionPage(expansion)
		if expansion.landingPageType == 1 then
			if (ExpansionLandingPage and ExpansionLandingPage:IsShown()) then
				HideUIPanel(ExpansionLandingPage)
			end
			--have to hide and show again to fix an issue with reports sometimes not showing for legion/WOTD
			if (GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
				HideUIPanel(GarrisonLandingPage)
			end
			ShowGarrisonLandingPage(expansion.garrisonTypeID)
		else
			--do dragonflight
			if (GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
				HideUIPanel(GarrisonLandingPage)
			end
			ToggleExpansionLandingPage()
		end
	end

	xanMissionMenu.initialize = function(self, level)
		if level == 1 then
			PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT)
			addButton(level, L.MissionMenuTitle, 1, 1)

			for _, expansion in ipairs(expansions) do
				local garrTypeID = expansion.garrisonTypeID
				if garrTypeID then

					local passChk = false

					if expansion.landingPageType == 1 then
						--for shadowlands make sure we have a covenant
						if garrTypeID == Enum.GarrisonType.Type_9_0 then
							if covenantData then passChk = true end
						else
							if C_Garrison.HasGarrison(garrTypeID) then passChk = true end
						end
					else
						if expansion.id and C_PlayerInfo.IsExpansionLandingPageUnlockedForPlayer(expansion.id) then
							passChk = true
						end
					end

					if passChk then
						addButton(level, expansion.name, nil, 1, nil, expansion.key, function(frame, ...)
							openMissionPage(expansion)
						end, expansion.minimapIcon)
					end

				end
			end

			addButton(level, "", nil, 1) --space ;)
			addButton(level, L.Close, nil, 1)
		end
	end

end

local function MBtn_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(self.title, 1, 1, 1)
	GameTooltip:AddLine(self.description, nil, nil, nil, true)

	local tooltipAddonText = L.RightClickSelectExpansion
	GameTooltip_AddNormalLine(GameTooltip, " ") --empty line
	GameTooltip_AddNormalLine(GameTooltip, tooltipAddonText)
	GameTooltip:Show()
end

local function MBtn_OnClick(self, button, isDown)
	if (button == "RightButton") then
		ToggleDropDownMenu(1, nil, addon.MM_Dropdown, self, 0, 0)
	else
		if (GarrisonLandingPage and GarrisonLandingPage:IsShown()) then
			HideUIPanel(GarrisonLandingPage)
		end
		ExpansionLandingPageMinimapButton:OnClick(button)
	end
end

function MBtn_GarrisonPage(garrTypeID)
	if (GarrisonLandingPageReport ~= nil) then
		--hide report page tabs if not Shadowlands, otherwise it will overlap with other landing pages
		if (garrTypeID ~= Enum.GarrisonType.Type_9_0) then
			GarrisonLandingPageReport.Sections:Hide()
			GarrisonLandingPage.FollowerTab.CovenantFollowerPortraitFrame:Hide()
		else
			GarrisonLandingPageReport.Sections:Show()
		end
	end
	--ignore invasions if not WOTD
	if ( garrTypeID ~= Enum.GarrisonType.Type_6_0 and GarrisonLandingPage.InvasionBadge:IsShown() ) then
		GarrisonLandingPage.InvasionBadge:Hide()
	end
end

local function EnableMissionMenu()
	if not addon.IsRetail then return end

	MM_CreateMenu()

	if ExpansionLandingPageMinimapButton then
		ExpansionLandingPageMinimapButton:HookScript("OnEnter", MBtn_OnEnter)
		ExpansionLandingPageMinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		ExpansionLandingPageMinimapButton:SetScript("OnClick", MBtn_OnClick)
	end

	-- GarrisonLandingPage Fixes
	hooksecurefunc("ShowGarrisonLandingPage", MBtn_GarrisonPage)

end

--add to our module loader
table.insert(addon.moduleFuncs, { func=EnableMissionMenu, name=moduleName } )
