local mod	= DBM:NewMod(1467, "DBM-Party-Legion", 10, 707)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17650 $"):sub(12, -3))
mod:SetCreatureID(95885)
mod:SetEncounterID(1815)
mod:DisableESCombatDetection()--Remove if blizz fixes trash firing ENCOUNTER_START
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 191941 192504 202740 204151",
	"SPELL_AURA_REMOVED 191941 192504 202740 204151",
	"SPELL_CAST_START 202765 204151 191823 191941 202913",
	"SPELL_PERIODIC_DAMAGE 202919 191853",
	"SPELL_PERIODIC_MISSED 202919 191853",
	"UNIT_SPELLCAST_SUCCEEDED boss1",
	"UNIT_HEALTH boss1"
)

local warnMetamorphosis				= mod:NewSoonAnnounce(192504, 1)
local warnMetamorphosis2			= mod:NewTargetAnnounce(192504, 4)
local warnMetamorphosis3			= mod:NewPreWarnAnnounce(192504, 5, 1)
local warnFuriousBlast				= mod:NewCastAnnounce(202765, 4)

local specWarnHatred				= mod:NewSpecialWarningDodge(190830, nil, nil, nil, 2, 2)
local specWarnDarkStrikes			= mod:NewSpecialWarningDefensive(204151, "Tank", nil, nil, 3, 6)
local specWarnFuriousBlast			= mod:NewSpecialWarningInterrupt(202765, "HasInterrupt", nil, nil, 3, 6)
local specWarnFelMortar				= mod:NewSpecialWarningDodge(202913, nil, nil, nil, 2, 2)
local specWarnFelMortarGTFO			= mod:NewSpecialWarningMove(191853, nil, nil, nil, 1, 2)

local timerSpecialCD				= mod:NewNextSpecialTimer(13.5)
local timerDarkStrikes				= mod:NewBuffActiveTimer(10, 191941, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON..DBM_CORE_DEADLY_ICON)
local timerDarkStrikesCD			= mod:NewCDTimer(30, 191941, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON..DBM_CORE_DEADLY_ICON)
local timerHatredCD					= mod:NewCDTimer(28, 190830, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerFelMortarCD				= mod:NewCDTimer(15, 202913, nil, nil, nil, 1, nil, DBM_CORE_DAMAGE_ICON..DBM_CORE_DEADLY_ICON)
local timerMetamorphosisCD			= mod:NewCDTimer(30, 192504, nil, nil, nil, 6, nil, DBM_CORE_DEADLY_ICON)
local timerFuriousBlastCD			= mod:NewCDTimer(30, 202765, nil, nil, nil, 2, nil, DBM_CORE_INTERRUPT_ICON..DBM_CORE_DEADLY_ICON)

local countdownFuriousBlast			= mod:NewCountdown(30, 202765, nil, nil, 5)

mod.vb.phase = 1
local warned_preP1 = false

function mod:OnCombatStart(delay)
	self.vb.phase = 1
	warned_preP1 = false
	timerDarkStrikesCD:Start(5-delay)
	timerFelMortarCD:Start(15-delay)
	if self:IsMythic() then
		timerMetamorphosisCD:Start(20-delay)
	else
		timerFuriousBlastCD:Start(31-delay)
		countdownFuriousBlast:Start(31-delay)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if (spellId == 204151 or spellId == 191941) then
		timerDarkStrikes:Start()
	elseif spellId == 202740 then
		self.vb.phase = 2
		warnMetamorphosis2:Show(args.destName)
		timerFuriousBlastCD:Stop()
		timerMetamorphosisCD:Stop()
		timerFelMortarCD:Start(9)
		timerDarkStrikesCD:Start(4)
	elseif spellId == 192504 then
		self.vb.phase = 3
		warnMetamorphosis2:Show(args.destName)
		timerFelMortarCD:Stop()
		timerMetamorphosisCD:Stop()
		--timerDarkStrikesCD:Start(27.3)
		timerHatredCD:Start(13.8)
		timerFuriousBlastCD:Start(9)
		countdownFuriousBlast:Start(9)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if (spellId == 204151 or spellId == 191941) then
		timerDarkStrikes:Cancel()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if (spellId == 204151 or spellId == 191941) and self:AntiSpam(2.5, 1) then
		specWarnDarkStrikes:Show()
		specWarnDarkStrikes:Play("defensive")
		timerDarkStrikesCD:Start()
	elseif spellId == 202765 or spellId == 191823 then
		warnFuriousBlast:Show()
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnFuriousBlast:Show(args.sourceName)
			specWarnFuriousBlast:Play("kickcast")
		else
			specWarnFuriousBlast:Show(args.sourceName)
			specWarnFuriousBlast:Play("kickcast")
		end
		--if self.vb.phase == 3 then
			--timerFuriousBlastCD:Start(35)
			--countdownFuriousBlast:Start(35)
		--else
			timerFuriousBlastCD:Start()
			countdownFuriousBlast:Start()
		--end
	elseif spellId == 202913 then
		if not UnitIsDeadOrGhost("player") then
			specWarnFelMortar:Show()
			specWarnFelMortar:Play("watchstep")
		end
		timerFelMortarCD:Start()
	end
end


function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 191853 and destGUID == UnitGUID("player") and self:AntiSpam(2, 2) then
		if not self:IsNormal() then
			specWarnFelMortarGTFO:Show()
			specWarnFelMortarGTFO:Play("runaway")
		end
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, bfaSpellId, _, legacySpellId)
	local spellId = legacySpellId or bfaSpellId
	if spellId == 190830 then
		if not UnitIsDeadOrGhost("player") then
			specWarnHatred:Show()
			specWarnHatred:Play("watchstep")
		end
		timerHatredCD:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	if not self:IsNormal() then
		if self.vb.phase == 2 and not warned_preP1 and self:GetUnitCreatureId(uId) == 95885 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.5 then
			warned_preP1 = true
			warnMetamorphosis:Show()
		end
	end
end