local mod	= DBM:NewMod(1719, "DBM-Party-Legion", 7, 800)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17077 $"):sub(12, -3))
mod:SetCreatureID(104217)
mod:SetEncounterID(1869)
mod:SetZone()

mod.noNormal = true

mod:RegisterCombat("combat")

--Out of combat register, to support the secondary bosses off to sides
mod:RegisterEvents(
	"SPELL_CAST_START 208165 207881 207980 207906",
	"SPELL_AURA_APPLIED 207906",
	"SPELL_AURA_APPLIED_DOSE 207906"
)
local warnBurningIntensity			= mod:NewStackAnnounce(207906, 4)

local specWarnWitheringSoul			= mod:NewSpecialWarningInterrupt(208165, "HasInterrupt")
local specWarnInfernalEruption		= mod:NewSpecialWarningDodge(207881, nil, nil, nil, 2, 2)
--local specWarnDisintegrationBeam	= mod:NewSpecialWarningSpell(207980, false, nil, 2, 1, 2)

local timerBurningIntensityCD		= mod:NewCDTimer(23.5, 207906, nil, "Tank|Healer", nil, 5)
local timerWitheringSoulCD			= mod:NewCDTimer(14.5, 208165, nil, nil, nil, 3)
local timerInfernalEruptionCD		= mod:NewCDTimer(32, 207881, nil, nil, nil, 2)

local countdownInfernalEruption		= mod:NewCountdown(32, 207881, nil, nil, 5)

function mod:OnCombatStart(delay)
	timerWitheringSoulCD:Start(12-delay)
	timerInfernalEruptionCD:Start(19.5-delay)
	countdownInfernalEruption:Start(19.5-delay)
	timerBurningIntensityCD:Start(6-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 208165 then
		if self:CheckInterruptFilter(args.sourceGUID) then
			specWarnWitheringSoul:Show(args.sourceName)
		end
		timerWitheringSoulCD:Start()
	elseif spellId == 207881 then
		specWarnInfernalEruption:Show()
		specWarnInfernalEruption:Play("watchstep")
		timerInfernalEruptionCD:Start()
		countdownInfernalEruption:Start()
	elseif spellId == 207906 then
		timerBurningIntensityCD:Start(23)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 207906 then
		local amount = args.amount or 1
		warnBurningIntensity:Show(args.destName, amount)
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED