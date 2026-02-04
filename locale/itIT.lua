local ADDON_NAME, private = ...
local L = private:NewLocale("itIT")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - ora e [|cFF20ff20%s|r]."
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - ora e [|cFF20ff20%s|r]."
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - ora e [|cFF20ff20%s|r]."
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - ora e [|cFF20ff20%s|r]."
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - ora e [|cFF20ff20%s|r]."
L.SlashSpecIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20specicon|r] - is now [|cFF20ff20%s|r]."

L.SlashHelpShowRace = "/xanui showrace - Attiva/disattiva l'icona della razza."
L.SlashHelpGenderIcon = "/xanui gendericon - Attiva/disattiva l'icona del genere."
L.SlashHelpGenderText = "/xanui gendertext - Attiva/disattiva il testo del genere."
L.SlashHelpOnlyDrac = "/xanui onlydrac - Attiva/disattiva icona/testo di genere solo per Dracthyr."
L.SlashHelpShowQuests = "/xanui showquests - Attiva/disattiva le icone delle missioni."
L.SlashHelpSpecIcon = "/xanui specicon - Toggles showing the target spec icon."

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (AVVISO) hai lasciato il mercante prima che l'addon finisse di vendere i grigi."
L.SellGreysSummary = "xanUI: <%d> oggetti grigi venduti. [%s]"
L.RepairGuild = "xanUI: Riparato con la gilda. [%s]"
L.RepairGuildInsufficient = "xanUI: Fondi di gilda insufficienti per riparare. [%s]"
L.RepairAll = "xanUI: Tutti gli oggetti riparati. [%s]"
L.RepairInsufficient = "xanUI: Fondi insufficienti per riparare. [%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: Conversazione TalkingHead silenziata.|r"

L.MissionMenuTitle = "Menu Missioni XanUI"
L.Close = "Chiudi"
L.RightClickSelectExpansion = "|cFF99CC33Clic destro per selezionare l'espansione.|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
