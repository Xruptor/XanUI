local ADDON_NAME, private = ...
local L = private:NewLocale("ptBR")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - agora esta [|cFF20ff20%s|r]."
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - agora esta [|cFF20ff20%s|r]."
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - agora esta [|cFF20ff20%s|r]."
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - agora esta [|cFF20ff20%s|r]."
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - agora esta [|cFF20ff20%s|r]."

L.SlashHelpShowRace = "/xanui showrace - Alterna a exibicao do icone de raca."
L.SlashHelpGenderIcon = "/xanui gendericon - Alterna a exibicao do icone de genero."
L.SlashHelpGenderText = "/xanui gendertext - Alterna a exibicao do texto de genero."
L.SlashHelpOnlyDrac = "/xanui onlydrac - Alterna icone/texto de genero apenas para Dracthyr."
L.SlashHelpShowQuests = "/xanui showquests - Alterna os icones de missao."

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (AVISO) voce saiu do comerciante antes do addon terminar de vender os itens cinza."
L.SellGreysSummary = "xanUI: <%d> itens cinza vendidos. [%s]"
L.RepairGuild = "xanUI: Reparado com a guilda. [%s]"
L.RepairGuildInsufficient = "xanUI: Fundos da guilda insuficientes para reparar. [%s]"
L.RepairAll = "xanUI: Todos os itens reparados. [%s]"
L.RepairInsufficient = "xanUI: Fundos insuficientes para reparar. [%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: Conversa do TalkingHead silenciada.|r"

L.MissionMenuTitle = "Menu de Missoes XanUI"
L.Close = "Fechar"
L.RightClickSelectExpansion = "|cFF99CC33Clique com o botao direito para selecionar a expansao.|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
