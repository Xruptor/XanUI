local ADDON_NAME, private = ...
local L = private:NewLocale("enUS", true)
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - is now [|cFF20ff20%s|r]."
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - is now [|cFF20ff20%s|r]."
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - is now [|cFF20ff20%s|r]."
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - is now [|cFF20ff20%s|r]."
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - is now [|cFF20ff20%s|r]."
L.SlashTargetClassColorStatus = "|cFF99CC33xanUI|r [|cFF20ff20targetclasscolor|r] - is now [|cFF20ff20%s|r]."
L.SlashSpecIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20specicon|r] - is now [|cFF20ff20%s|r]."

L.SlashHelpShowRace = "/xanui showrace - Toggles showing the race icon."
L.SlashHelpGenderIcon = "/xanui gendericon - Toggles showing the gender icon."
L.SlashHelpGenderText = "/xanui gendertext - Toggles showing the gender text."
L.SlashHelpOnlyDrac = "/xanui onlydrac - Toggles showing gender icon/text for Dracthyr only."
L.SlashHelpShowQuests = "/xanui showquests - Toggles showing quest icons."
L.SlashHelpTargetClassColor = "/xanui targetclasscolor - Toggles class color on target/targettarget health bars."
L.SlashHelpSpecIcon = "/xanui specicon - Toggles showing the target spec icon."

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (WARNING) you exited merchant before addon could finish selling greys."
L.SellGreysSummary = "xanUI: <%d> Total grey items vendored. [%s]"
L.RepairGuild = "xanUI: Repaired from Guild. [%s]"
L.RepairGuildInsufficient = "xanUI: Insufficient guild funds to make repairs. [%s]"
L.RepairAll = "xanUI: Repaired all items. [%s]"
L.RepairInsufficient = "xanUI: Insufficient funds to make repairs. [%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: TalkingHead conversation silenced.|r"

L.MissionMenuTitle = "XanUI MissionMenu"
L.Close = "Close"
L.RightClickSelectExpansion = "|cFF99CC33Right-click to select expansion.|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
