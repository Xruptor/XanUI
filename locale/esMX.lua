local ADDON_NAME, private = ...
local L = private:NewLocale("esMX")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - ahora es [|cFF20ff20%s|r]."
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - ahora es [|cFF20ff20%s|r]."
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - ahora es [|cFF20ff20%s|r]."
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - ahora es [|cFF20ff20%s|r]."
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - ahora es [|cFF20ff20%s|r]."

L.SlashHelpShowRace = "/xanui showrace - Alterna el icono de raza."
L.SlashHelpGenderIcon = "/xanui gendericon - Alterna el icono de genero."
L.SlashHelpGenderText = "/xanui gendertext - Alterna el texto de genero."
L.SlashHelpOnlyDrac = "/xanui onlydrac - Alterna icono/texto de genero solo para Dracthyr."
L.SlashHelpShowQuests = "/xanui showquests - Alterna los iconos de misiones."

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (ADVERTENCIA) saliste del comerciante antes de que el addon terminara de vender los grises."
L.SellGreysSummary = "xanUI: <%d> objetos grises vendidos. [%s]"
L.RepairGuild = "xanUI: Reparado con la hermandad. [%s]"
L.RepairGuildInsufficient = "xanUI: Fondos de hermandad insuficientes para reparar. [%s]"
L.RepairAll = "xanUI: Todos los objetos reparados. [%s]"
L.RepairInsufficient = "xanUI: Fondos insuficientes para reparar. [%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: Conversacion de TalkingHead silenciada.|r"

L.MissionMenuTitle = "Menu de Misiones XanUI"
L.Close = "Cerrar"
L.RightClickSelectExpansion = "|cFF99CC33Clic derecho para seleccionar expansion.|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
