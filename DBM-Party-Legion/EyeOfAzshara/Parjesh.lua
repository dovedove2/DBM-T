local mod	= DBM:NewMod(1480, "DBM-Party-Legion", 3, 716)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17077 $"):sub(12, -3))
mod:SetCreatureID(91784)
mod:SetEncounterID(1810)
mod:SetZone()
mod:SetUsedIcons(8, 7)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 192094 197064 192131",
	"SPELL_CAST_START 192072 192073 196563 197502 191900",
	"SPELL_PERIODIC_DAMAGE 192053",
	"SPELL_PERIODIC_MISSED 192053",
	"UNIT_HEALTH boss1"
)

--TODO, interrupt warnings for adds maybe.

local warnEnrage2					= mod:NewSoonAnnounce(197064, 1)
local warnEnrage					= mod:NewTargetAnnounce(197064, 4)
local warnImpalingSpear				= mod:NewTargetAnnounce(192094, 4)
local warnThrowSpear				= mod:NewTargetAnnounce(192131, 3)

local specWarnReinforcements		= mod:NewSpecialWarningSwitch(196563, "Dps|Tank", nil, nil, 1, 2)
local specWarnCrashingwave			= mod:NewSpecialWarningDodge(191900, nil, nil, nil, 2, 2)
local specWarnImpalingSpear			= mod:NewSpecialWarningMoveTo(192094, nil, nil, nil, 3, 6)
local specWarnQuicksand				= mod:NewSpecialWarningGTFO(192053, nil, nil, nil, 1, 2)
local specWarnRestoration			= mod:NewSpecialWarningInterrupt(197502, "HasInterrupt", nil, nil, 1, 2)
--local specWarnThrowSpear			= mod:NewSpecialWarningDefensive(192131, nil, nil, nil, 1, 6)

local timerCrashingwaveCD			= mod:NewCDTimer(27, 191900, nil, nil, nil, 5, nil, DBM_CORE_TANK_ICON..DBM_CORE_DEADLY_ICON)
local timerHatecoilCD				= mod:NewCDTimer(27, 192072, nil, nil, nil, 1, nil, DBM_CORE_TANK_ICON..DBM_CORE_DAMAGE_ICON)
local timerSpearCD					= mod:NewCDTimer(27, 192094, nil, nil, nil, 3)
local timerThrowSpearCD				= mod:NewCDTimer(15, 192131, nil, nil, nil, 3, nil, DBM_CORE_HEALER_ICON..DBM_CORE_DEADLY_ICON)

local yellImpalingSpear				= mod:NewYell(192094)
--local yellThrowSpear				= mod:NewYell(192131)

local countdownCrashingwave			= mod:NewCountdown(27, 191900, nil, nil, 5)
local countdownSpear2				= mod:NewCountdownFades("Alt5", 192094, nil, nil, 5)

mod:AddSetIconOption("SetIconOnImpalingSpear", 192094, true, false, {8})
mod:AddSetIconOption("SetIconOnThrowSpear", 192131, true, false, {7})

local trash = DBM:GetSpellInfo(192072)


mod.vb.phase = 1
local warned_preP1 = false
local warned_preP2 = false



function mod:OnCombatStart(delay)
	self.vb.phase = 1
	warned_preP1 = false
	warned_preP2 = false
	timerHatecoilCD:Start(3-delay)
	timerSpearCD:Start(28.2-delay)
	timerCrashingwaveCD:Start(25.2-delay)
	countdownCrashingwave:Start(25.2-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 192094 then
		timerSpearCD:Start()
		if args:IsPlayer() then
			specWarnImpalingSpear:Show(trash)
			yellImpalingSpear:Yell()
			specWarnImpalingSpear:Play("192094")
		else
			warnImpalingSpear:Show(args.destName)
		end
		if self.Options.SetIconOnImpalingSpear then
			self:SetIcon(args.destName, 8, 5)
		end
	elseif spellId == 197064 then
		warnEnrage:Show(args.destName)
	elseif spellId == 192131 then
		warnThrowSpear:Show(args.destName)
		timerThrowSpearCD:Start()
		--if args:IsPlayer() then
		--	yellThrowSpear:Yell()
		--end
		if self.Options.SetIconOnThrowSpear then
			self:SetIcon(args.destName, 7, 9)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 192073 and self:IsNormal() then--Caster mob
		specWarnReinforcements:Show()
		specWarnReinforcements:Play("bigmobsoon")
		timerHatecoilCD:Start(20)
	elseif spellId == 192072 and self:IsNormal() then--Melee mob
		specWarnReinforcements:Show()
		specWarnReinforcements:Play("bigmobsoon")
		timerHatecoilCD:Start(33)
	elseif spellId == 196563 then--Both of them (heroic+)
		specWarnReinforcements:Show()
		specWarnReinforcements:Play("bigmobsoon")
		timerHatecoilCD:Start()
	elseif spellId == 197502 then
		specWarnRestoration:Show(args.sourceName)
		specWarnRestoration:Play("kickcast")
	elseif spellId == 191900 then
		specWarnCrashingwave:Show()
		specWarnCrashingwave:Play("watchstep")
		timerCrashingwaveCD:Start()
		countdownCrashingwave:Start()
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 192053 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		if self:IsHard() then
			specWarnQuicksand:Show()
			specWarnQuicksand:Play("runaway")
		end
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_HEALTH(uId)
	if self:IsHard() then
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 91784 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.40 then
			warned_preP1 = true
			warnEnrage2:Show()
		elseif self.vb.phase == 1 and warned_preP1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 91784 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.30 then
			warned_preP2 = true
			self.vb.phase = 2
		end
	else
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 91784 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.40 then
			warned_preP1 = true
		elseif self.vb.phase == 1 and warned_preP1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 91784 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.30 then
			warned_preP2 = true
			self.vb.phase = 2
		end
	end
end
