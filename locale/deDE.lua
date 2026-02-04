local ADDON_NAME, private = ...
local L = private:NewLocale("deDE")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - ist jetzt [|cFF20ff20%s|r]."
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - ist jetzt [|cFF20ff20%s|r]."
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - ist jetzt [|cFF20ff20%s|r]."
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - ist jetzt [|cFF20ff20%s|r]."
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - ist jetzt [|cFF20ff20%s|r]."

L.SlashHelpShowRace = "/xanui showrace - Schaltet das Rassenicon um."
L.SlashHelpGenderIcon = "/xanui gendericon - Schaltet das Geschlechtsicon um."
L.SlashHelpGenderText = "/xanui gendertext - Schaltet den Geschlechtstext um."
L.SlashHelpOnlyDrac = "/xanui onlydrac - Schaltet Geschlechtsicon/-text nur fur Dracthyr um."
L.SlashHelpShowQuests = "/xanui showquests - Schaltet Questicons um."

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (WARNUNG) Du hast den Handler verlassen, bevor das Addon alle grauen Gegenstande verkauft hat."
L.SellGreysSummary = "xanUI: <%d> Graue Gegenstande verkauft. [%s]"
L.RepairGuild = "xanUI: Repariert aus der Gildenbank. [%s]"
L.RepairGuildInsufficient = "xanUI: Unzureichende Gildenmittel fur Reparaturen. [%s]"
L.RepairAll = "xanUI: Alle Gegenstande repariert. [%s]"
L.RepairInsufficient = "xanUI: Unzureichende Mittel fur Reparaturen. [%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: TalkingHead-Konversation stummgeschaltet.|r"

L.MissionMenuTitle = "XanUI Missionsmenu"
L.Close = "Schliessen"
L.RightClickSelectExpansion = "|cFF99CC33Rechtsklick, um die Erweiterung zu wahlen.|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
