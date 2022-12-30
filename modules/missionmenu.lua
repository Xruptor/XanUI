local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local moduleName = "missionmenu"

local function GetAtlasInfo(atlas)
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

    local xpacTable = {}

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

	local expansions = {
		["WarlordsOfDraenor"] = {
			["key"] = "WarlordsOfDraenor",
			["id"] = LE_EXPANSION_WARLORDS_OF_DRAENOR,
			["name"] = EXPANSION_NAME5,
			["banner"] = "accountupgradebanner-wod",
			["garrisonTypeID"] = Enum.GarrisonType.Type_6_0,
			["minimapIcon"] = string.format("GarrLanding-MinimapIcon-%s-Up", playerInfo.factionGroup),
		},
		["Legion"] = {
			["key"] = "Legion",
			["id"] = LE_EXPANSION_LEGION,
			["name"] = EXPANSION_NAME6,
			["banner"] = "accountupgradebanner-legion",
			["garrisonTypeID"] = Enum.GarrisonType.Type_7_0,
			["minimapIcon"] = string.format("legionmission-landingbutton-%s-up", classIconName),
		},
		["BattleForAzeroth"] = {
			["key"] = "BattleForAzeroth",
			["id"] = LE_EXPANSION_BATTLE_FOR_AZEROTH,
			["name"] = EXPANSION_NAME7,
			["banner"] = "accountupgradebanner-bfa",
			["garrisonTypeID"] = Enum.GarrisonType.Type_8_0,
			["minimapIcon"] = string.format("bfa-landingbutton-%s-up", playerInfo.factionGroup),
		},
		["Shadowlands"] = {
			["key"] = "Shadowlands",
			["id"] = LE_EXPANSION_SHADOWLANDS,
			["name"] = EXPANSION_NAME8,
			["banner"] = "accountupgradebanner-shadowlands",
			["garrisonTypeID"] = Enum.GarrisonType.Type_9_0,
			["minimapIcon"] = string.format("shadowlands-landingbutton-%s-up", playerInfo.covenantTex),
		},
		["Dragonflight"] = {
			["key"] = "Dragonflight",
			["id"] = LE_EXPANSION_DRAGONFLIGHT,
			["name"] = EXPANSION_NAME9,
			["banner"] = "accountupgradebanner-dragonflight",
			["garrisonTypeID"] = Enum.ExpansionLandingPageType.Dragonflight,
			["minimapIcon"] = "dragonflight-landingbutton-up",
		},
	}

	for name, expansion in pairs(expansions) do
		tinsert(xpacTable, expansion);
	end
	table.sort(xpacTable, function(a, b)
		return a.id < b.id;
	end)

	local function openMissionPage(expansion)
		--as long as the expansion isn't Dragonflight
		if (expansion.garrisonTypeID ~= Enum.ExpansionLandingPageType.Dragonflight) then
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
			addButton(level, 'XanUI MissionMenu', 1, 1)

			for _, expansion in ipairs(xpacTable) do
				local garrTypeID = expansion.garrisonTypeID
				if garrTypeID then
					addButton(level, expansion.name, nil, 1, nil, expansion.key, function(frame, ...)
						openMissionPage(expansion)
					end, expansion.minimapIcon)
				end
			end

			addButton(level, "", nil, 1) --space ;)
			addButton(level, "Close", nil, 1)
		end
	end

end

local function MBtn_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(self.title, 1, 1, 1)
	GameTooltip:AddLine(self.description, nil, nil, nil, true)

	local tooltipAddonText = "|cFF99CC33Right-click to select expansion.|r"
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
