local ADDON_NAME, private = ...
local L = private:NewLocale("ruRU")
if not L then return end

L.SlashShowRaceStatus = "|cFF99CC33xanUI|r [|cFF20ff20showrace|r] - теперь [|cFF20ff20%s|r]."
L.SlashGenderIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendericon|r] - теперь [|cFF20ff20%s|r]."
L.SlashGenderTextStatus = "|cFF99CC33xanUI|r [|cFF20ff20gendertext|r] - теперь [|cFF20ff20%s|r]."
L.SlashOnlyDracStatus = "|cFF99CC33xanUI|r [|cFF20ff20onlydrac|r] - теперь [|cFF20ff20%s|r]."
L.SlashShowQuestsStatus = "|cFF99CC33xanUI|r [|cFF20ff20showquests|r] - теперь [|cFF20ff20%s|r]."
L.SlashSpecIconStatus = "|cFF99CC33xanUI|r [|cFF20ff20specicon|r] - is now [|cFF20ff20%s|r]."

L.SlashHelpShowRace = "/xanui showrace - Переключает показ иконки расы."
L.SlashHelpGenderIcon = "/xanui gendericon - Переключает показ иконки пола."
L.SlashHelpGenderText = "/xanui gendertext - Переключает показ текста пола."
L.SlashHelpOnlyDrac = "/xanui onlydrac - Переключает иконку/текст пола только для Dracthyr."
L.SlashHelpShowQuests = "/xanui showquests - Переключает показ иконок заданий."
L.SlashHelpSpecIcon = "/xanui specicon - Toggles showing the target spec icon."

L.AddonLoaded = "|cFF99CC33xanUI|r [v|cFF20ff20%s|r]   /xanui, /xui"

L.SellGreysInterrupted = "xanUI: (ВНИМАНИЕ) вы покинули торговца до завершения продажи серых предметов."
L.SellGreysSummary = "xanUI: <%d> серых предметов продано. [%s]"
L.RepairGuild = "xanUI: Ремонт за счет гильдии. [%s]"
L.RepairGuildInsufficient = "xanUI: Недостаточно средств гильдии для ремонта. [%s]"
L.RepairAll = "xanUI: Все предметы отремонтированы. [%s]"
L.RepairInsufficient = "xanUI: Недостаточно средств для ремонта. [%s]"

L.TalkingHeadSilenced = "|cFF00FF96xanUI: Диалог TalkingHead заглушен.|r"

L.MissionMenuTitle = "Меню миссий XanUI"
L.Close = "Закрыть"
L.RightClickSelectExpansion = "|cFF99CC33ПКМ для выбора дополнения.|r"

L.GenderMale = "[M]"
L.GenderFemale = "[F]"
