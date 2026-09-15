local mod	= DBM:NewMod(1470, "DBM-Party-Legion", 10, 707)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17650 $"):sub(12, -3))
mod:SetCreatureID(95888)
mod:SetEncounterID(1818)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 213576 213583 197251 213685 197422 214989",
	"SPELL_CAST_SUCCESS 197333 197513",
	"SPELL_AURA_APPLIED 205004 197541 216870",
	"SPELL_AURA_REMOVED 206567 197422",
	"SPELL_PERIODIC_DAMAGE 216870",
	"SPELL_PERIODIC_MISSED 216870",
	"UNIT_SPELLCAST_SUCCEEDED boss1",
	"UNIT_HEALTH boss1"
)

--TODO: do detonating moonglaive: 197513 spellcast_start. fix timers after HiddenOver (pause tech maybe)

local warnPhase						= mod:NewPhaseChangeAnnounce(1)
local warnPhase2					= mod:NewPrePhaseAnnounce(2, 1, 197422)
local warnDeepeningShadows			= mod:NewSpellAnnounce(213583, 4)
local warnCreepingDoom				= mod:NewSpellAnnounce(197422, 4)
local warnCreepingDoom2				= mod:NewSoonAnnounce(197422, 1)

local specWarnFelGlaive				= mod:NewSpecialWarningDodge(197333, false, nil, nil, 1, 2)
local specWarnDeepeningShadows2		= mod:NewSpecialWarningMove(213583, "-Tank", nil, nil, 1, 3)
--local specWarnDetonation			= mod:NewSpecialWarningDefensive(197541, nil, nil, nil, 2, 5)
local specWarnKick					= mod:NewSpecialWarningSpell(197251, "Tank", nil, nil, 3, 2)
local specWarnDeepeningShadows		= mod:NewSpecialWarningMoveTo(213583, nil, nil, nil, 3, 6)
local specWarnHiddenStarted			= mod:NewSpecialWarningSpell(192750, nil, nil, nil, 2, 2)
local specWarnHiddenOver			= mod:NewSpecialWarningEnd(192750, nil, nil, nil, 1, 2)
local specWarnCreepingDoom			= mod:NewSpecialWarningDodge(197422, nil, nil, nil, 2, 5)
local specWarnVengeance				= mod:NewSpecialWarningMoveTo(205004, nil, nil, nil, 3, 6)
local specWarnVengeance2			= mod:NewSpecialWarningSwitch(205004, "-Healer", nil, nil, 3, 6)

--local timerDetonation				= mod:NewTargetTimer(10, 197541, nil, nil, nil, 3, nil, DBM_CORE_HEALER_ICON)
local timerKickCD					= mod:NewCDTimer(20, 197251, nil, nil, nil, 5, nil, DBM_CORE_TANK_ICON)
local timerDeepeningShadowsCD		= mod:NewCDTimer(31, 213576, nil, nil, nil, 3)
local timerCreepingDoomCD			= mod:NewCDTimer(60, 197422, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerCreepingDoom				= mod:NewBuffActiveTimer(35.2, 197422, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerVengeanceCD				= mod:NewCDTimer(40, 205004, nil, nil, nil, 1, nil, DBM_CORE_DAMAGE_ICON)

local countdownCreepingDoom			= mod:NewCountdown(60, 197422, nil, nil, 5)
local countdownCreepingDoom2		= mod:NewCountdownFades("Alt35.2", 197422, nil, nil, 5)

mod.vb.phase = 1
local warned_preP1 = false
local warned_preP2 = false

function mod:OnCombatStart(delay)
	self.vb.phase = 1
	warned_preP1 = false
	warned_preP2 = false
	timerKickCD:Start(8-delay)
	timerDeepeningShadowsCD:Start(10.9-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 213576 or spellId == 213583 then
		if ExtraActionBarFrame:IsShown() then
			specWarnDeepeningShadows:Show(args.spellName)
			specWarnDeepeningShadows:Play("213576")
		else
			warnDeepeningShadows:Show()
		end
		timerDeepeningShadowsCD:Start()
	elseif spellId == 197251 or spellId == 214989 then
		specWarnKick:Show()
		specWarnKick:Play("carefly")
		timerKickCD:Start()
	elseif spellId == 197422 then --Static Creeping Doom
		if not UnitIsDeadOrGhost("player") then
			specWarnCreepingDoom:Show()
			specWarnCreepingDoom:Play("stilldanger")
			specWarnCreepingDoom:ScheduleVoice(2, "keepmove")
		end
		timerCreepingDoom:Start()
		timerVengeanceCD:Start(35.2)
		timerKickCD:Start(timerKickCD:GetRemaining()+35)
		timerDeepeningShadowsCD:Start(timerDeepeningShadowsCD:GetRemaining()+35)
		countdownCreepingDoom2:Start()
		
	elseif spellId == 213685 then --Moving Creeping Doom
		warnCreepingDoom:Show()
		if not UnitIsDeadOrGhost("player") then
			specWarnCreepingDoom:Show()
			specWarnCreepingDoom:Play("stilldanger")
			specWarnCreepingDoom:ScheduleVoice(2, "keepmove")
		end
		timerCreepingDoom:Start(30)
		--countdownCreepingDoom2:Start(30)
		timerCreepingDoomCD:Start()
		countdownCreepingDoom:Start()
		warnCreepingDoom2:Schedule(55)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 197333 then
		specWarnFelGlaive:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if args.spellId == 205004 then
		if ExtraActionBarFrame:IsShown() then
			specWarnVengeance:Show(args.spellName)
			specWarnVengeance:Play(205004)
		else
			if not UnitIsDeadOrGhost("player") then
				specWarnVengeance2:Show()
				specWarnVengeance2:Play("justrun")
			end
		end
		timerVengeanceCD:Start()
	--elseif spellId == 197541 then
	--	timerDetonation:Start(args.destName)
		--if args:IsPlayer() then
			--specWarnDetonation:Show()
			--specWarnDetonation:Play("defensive")
		--end
	elseif spellId == 216870 then
		if self:IsHard() then
			specWarnDeepeningShadows2:Show()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 206567 then
		if not UnitIsDeadOrGhost("player") then
			specWarnHiddenOver:Show()
			specWarnHiddenOver:Play("end")
		end
		--timerVengeanceCD:Start(14)
		--timerKickCD:Start(15.5)
		--timerDeepeningShadowsCD:Start(20)
	elseif spellId == 197422 then --Static Creeping Doom ends
		timerCreepingDoomCD:Start(20)
		countdownCreepingDoom:Start(20)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, bfaSpellId, _, legacySpellId)
	local spellId = legacySpellId or bfaSpellId
	if spellId == 203416 then
		timerDeepeningShadowsCD:Stop()
		timerKickCD:Stop()
		if not UnitIsDeadOrGhost("player") then
			specWarnHiddenStarted:Show()
		--	specWarnHiddenStarted:Play("end")
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 216870 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		if self:IsHard() then
			specWarnDeepeningShadows2:Show()
			specWarnDeepeningShadows2:Play("runaway")
		end
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_HEALTH(uId)
	if not self:IsNormal() then
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 95888 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.50 then
			warned_preP1 = true
			warnPhase2:Show(DBM_CORE_AUTO_ANNOUNCE_TEXTS.stage:format(self.vb.phase+1))
		elseif self.vb.phase == 1 and warned_preP1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 95888 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.40 then
			self.vb.phase = 2
			warned_preP2 = true
			warnPhase:Show(DBM_CORE_AUTO_ANNOUNCE_TEXTS.stage:format(self.vb.phase))
			warnPhase:Play("phasechange")
		end
	else
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 95888 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.50 then
			warned_preP1 = true
		elseif self.vb.phase == 1 and warned_preP1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 95888 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.40 then
			self.vb.phase = 2
			warned_preP2 = true
			warnPhase:Show(DBM_CORE_AUTO_ANNOUNCE_TEXTS.stage:format(self.vb.phase))
			warnPhase:Play("phasechange")
		end
	end
end