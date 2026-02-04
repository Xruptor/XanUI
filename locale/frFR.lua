local ADDON_NAME, private = ...
local L = private:NewLocale("frFR")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - est maintenant [|cFF20ff20%s|r]."
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - est maintenant [|cFF20ff20%s|r]."
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - est maintenant [|cFF20ff20%s|r]."
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - est maintenant [|cFF20ff20%s|r]."
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - est maintenant [|cFF20ff20%s|r]."

L.SlashHelpShowRace = "/xanui showrace - Bascule l'icone de race."
L.SlashHelpGenderIcon = "/xanui gendericon - Bascule l'icone de genre."
L.SlashHelpGenderText = "/xanui gendertext - Bascule le texte de genre."
L.SlashHelpOnlyDrac = "/xanui onlydrac - Bascule l'icone/texte de genre uniquement pour Dracthyr."
L.SlashHelpShowQuests = "/xanui showquests - Bascule les icones de quete."

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI : (AVERTISSEMENT) vous avez quitte le marchand avant que l'addon termine de vendre les gris."
L.SellGreysSummary = "xanUI : <%d> objets gris vendus. [%s]"
L.RepairGuild = "xanUI : Repare via la guilde. [%s]"
L.RepairGuildInsufficient = "xanUI : Fonds de guilde insuffisants pour reparer. [%s]"
L.RepairAll = "xanUI : Tous les objets repares. [%s]"
L.RepairInsufficient = "xanUI : Fonds insuffisants pour reparer. [%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI : Conversation TalkingHead reduite au silence.|r"

L.MissionMenuTitle = "Menu des missions XanUI"
L.Close = "Fermer"
L.RightClickSelectExpansion = "|cFF99CC33Clic droit pour selectionner une extension.|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
