local RioHelper = LibStub("AceAddon-3.0"):GetAddon("RioHelper")

local DungeonAbbreviations = RioHelper.Data.DungeonAbbreviations
local WeeklyAffixAbbreviations = RioHelper.Data.WeeklyAffixAbbreviations

local Functions = RioHelper.Functions
local coerce = RioHelper.Functions.coerce

function RioHelper:OnInitialize()
    RioHelper:RegisterChatCommand("rh",
            function(input, _)
                local dungeonAbbreviationPar, keyLevelPar, weeklyAffixPar = RioHelper:GetArgs(input, 3)
                -- check if all parameters exist
                if dungeonAbbreviationPar == "help" or not dungeonAbbreviationPar or not keyLevelPar then
                    RioHelper:Print("Usage: /rh dungeonAbbreviation keyLevel [weeklyAffix]")
                    return
                end

                if DungeonAbbreviations[dungeonAbbreviationPar] == nil then
                    RioHelper:Print("\"dungeonAbbreviation\" must be on of the following values:")
                    RioHelper:Print(RioHelper.Data.ValidDungeonAbbreviationList)
                    return
                end
                local dungeonAbbreviation = dungeonAbbreviationPar

                local keyLevelMatch = keyLevelPar:match("\+?%d+")
                if not keyLevelMatch or keyLevelMatch ~= keyLevelPar or keyLevelPar+0 <= 1 then
                    RioHelper:Print("\"keyLevel\" must be 2 or higher but was: "..coerce(keyLevelPar))
                    return
                end
                local keyLevel = tonumber(keyLevelPar)
                if keyLevel > 50 then
                    RioHelper:Print("M+"..keyLevel.."??? You wish!")
                    return
                end

                local weeklyAffix;
                if weeklyAffixPar == nil then
                    for _, affix in pairs(C_MythicPlus.GetCurrentAffixes()) do
                        local currentAffixName, _, _ = C_ChallengeMode.GetAffixInfo(affix.id);
                        if currentAffixName == "Tyrannical" or currentAffixName == "Fortified" then
                            weeklyAffix = currentAffixName
                            break
                        end
                    end
                else
                    local weeklyAffixCandidate = RioHelper.Data.WeeklyAffixAbbreviations[weeklyAffixPar]
                    if weeklyAffixCandidate == nil then
                        RioHelper:Print("\"weeklyAffix\" was \""..coerce(weeklyAffixPar).."\" but must be on of the following values:")
                        RioHelper:Print(RioHelper.Data.ValidWeeklyAffixAbbreviationsList)
                        return
                    end
                    weeklyAffix = weeklyAffixCandidate
                end

                RioHelper:computeScoreBonus(dungeonAbbreviation, keyLevel, weeklyAffix)
            end
    )
    RioHelper:Print("RIO Helper loaded")
end

function RioHelper:computeScoreBonus(dungeonAbbreviationPar, keyLevelPar, weeklyAffixPar)
    assert(dungeonAbbreviationPar, "dungeonAbbreviationPar must not be nil")
    assert(keyLevelPar > 1, "keyLevelPar must be >= 2")
    assert(weeklyAffixPar, "weeklyAffixPar must not be nil")
    local dungeonId = DungeonAbbreviations[dungeonAbbreviationPar];
    local weeklyAffix = WeeklyAffixAbbreviations[weeklyAffixPar]
    local blizzardScores = {
        Tyrannical = { score = 0, baseScore = 0, timeBonus = 0, parTimePercentage = 0 },
        Fortified = { score = 0, baseScore = 0, timeBonus = 0, parTimePercentage = 0 }
    }
    local _, _, parTime = C_ChallengeMode.GetMapUIInfo(dungeonId)
    local blizzardDungeonAffixScoreData, blizzardDungeonTotalScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(dungeonId)
    blizzardDungeonTotalScore = coerce(blizzardDungeonTotalScore, 0)
    local blizzardCurrentSeasonTotalScore = C_ChallengeMode.GetOverallDungeonScore()

    blizzardScores[weeklyAffix] = Functions.computeScores(dungeonId, keyLevelPar, parTime)
    if (blizzardDungeonAffixScoreData ~= nil) then
        for _, weeklyAffixData in pairs(blizzardDungeonAffixScoreData) do
            if (weeklyAffixData.name ~= weeklyAffix) then
                blizzardScores[weeklyAffixData.name] = Functions.computeScores(dungeonId, weeklyAffixData.level, weeklyAffixData.durationSec)
            end
        end
    end
    local newSum = Functions.computeAffixScoreSum(blizzardScores.Tyrannical.score, blizzardScores.Fortified.score)
    local bonusScore = newSum - blizzardDungeonTotalScore
    RioHelper:Print(string.format(
            "%s from %s to %s - New total score: %s",
            Functions.formatNumber(bonusScore, 1),
            blizzardDungeonTotalScore,
            Functions.formatNumber(newSum, 1, true),
            Functions.formatNumber((blizzardCurrentSeasonTotalScore + bonusScore), 1, true)
    ))
end
