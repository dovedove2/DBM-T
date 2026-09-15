local mod	= DBM:NewMod(1469, "DBM-Party-Legion", 10, 707)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17650 $"):sub(12, -3))
mod:SetCreatureID(95887)
mod:SetEncounterID(1817)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 193443 194942",
	"SPELL_AURA_APPLIED 195034 194333",
	"SPELL_AURA_APPLIED_DOSE 195034",
	"SPELL_AURA_REMOVED 194333 194323",
	"SPELL_PERIODIC_DAMAGE 194945",
	"SPELL_PERIODIC_MISSED 194945"
)

local warnRadiationLevel			= mod:NewStackAnnounce(195034, 4, nil, nil, 2)
local warnFocused					= mod:NewSoonAnnounce(194289, 1)

local specWarnGaze					= mod:NewSpecialWarningDodge(194942, nil, nil, nil, 2, 2)
local specWarnBeamed				= mod:NewSpecialWarningSpell(194333, false, nil, nil, 3, 2)
local specWarnFocused				= mod:NewSpecialWarningSwitch(194289, nil, nil, nil, 2, 2)
local specWarnGazeGTFO				= mod:NewSpecialWarningMove(194945, nil, nil, nil, 1, 2)

local timerGazeCD					= mod:NewCDTimer(15, 194942, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerFocusedCD				= mod:NewCDTimer(60, 194289, nil, nil, nil, 7)
local timerFocused					= mod:NewCastTimer(60, 194289, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerBeamed					= mod:NewTargetTimer(15, 194333, nil, false, nil, 3, nil, DBM_CORE_DAMAGE_ICON)

local countdownFocused				= mod:NewCountdown(60, 194289, nil, nil, 5)

mod.vb.focusedCount = 0

function mod:OnCombatStart(delay)
	self.vb.focusedCount = 0
	timerGazeCD:Start(15-delay)
	timerFocusedCD:Start(30-delay)
	countdownFocused:Start(30-delay)
	warnFocused:Schedule(25-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 193443 then
		self.vb.focusedCount = self.vb.focusedCount + 1
		timerGazeCD:Stop()
		timerFocused:Start()
		if not UnitIsDeadOrGhost("player") then
			specWarnFocused:Show()
			specWarnFocused:Play("specialsoon")
		end
	elseif spellId == 194942 then
		if not UnitIsDeadOrGhost("player") then
			specWarnGaze:Show()
			specWarnGaze:Play("watchstep")
		end
		timerGazeCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 195034 then
		local amount = args.amount or 1
		if not self:IsNormal() then
			if amount >= 10 and amount % 5 == 0 then
				warnRadiationLevel:Show(args.destName, amount)
			end
		end
	elseif spellId == 194333 then
		timerBeamed:Start(args.destName)
		timerFocused:Stop()
		if not UnitIsDeadOrGhost("player") then
			specWarnBeamed:Show(args.destName)
		end
		---timerFocusedCD:Start()
		--countdownFocused:Start()
		--warnFocused:Schedule(55)
		--timerGazeCD:Start(14)
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 194333 then
		timerBeamed:Cancel(args.destName)
	end
	if spellId == 194323 then
		timerFocused:Stop()
		timerFocusedCD:Start()
		countdownFocused:Start()
		warnFocused:Schedule(55)
		timerGazeCD:Start(14)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 194945 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		if not self:IsNormal() then
			specWarnGazeGTFO:Show()
			specWarnGazeGTFO:Play("runaway")
		end
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE