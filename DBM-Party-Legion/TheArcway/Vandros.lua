local mod	= DBM:NewMod(1501, "DBM-Party-Legion", 6, 726)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17650 $"):sub(12, -3))
mod:SetCreatureID(98208)
mod:SetEncounterID(1829)
mod:SetZone()
mod:SetUsedIcons(8)
mod.noNormal = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 203957 220871 203176",
	"SPELL_AURA_APPLIED_DOSE 203176",
	"SPELL_AURA_REMOVED 220871",
	"SPELL_CAST_START 202974 203882 203176",
	"SPELL_DAMAGE 203833",
	"SPELL_MISSED 203833",
	"UNIT_SPELLCAST_SUCCEEDED boss1",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_HEALTH boss1"
)

local warnBlast						= mod:NewStackAnnounce(203176, 3, false, nil, 2)
local warnTimeLock					= mod:NewTargetAnnounce(203957, 4)
local warnUnstableMana				= mod:NewTargetAnnounce(220871, 4)
local warnPhase						= mod:NewPhaseChangeAnnounce(1)
local warnPhase2					= mod:NewPrePhaseAnnounce(2, 1, 220871)

local specWarnTimeSplit				= mod:NewSpecialWarningMove(203833, nil, nil, nil, 1, 2)
local specWarnForceBomb				= mod:NewSpecialWarningDodge(202974, nil, nil, nil, 2, 5)
local specWarnBlast					= mod:NewSpecialWarningInterruptCount(203176, "HasInterrupt", nil, 2, 1, 2)
local specWarnBlastStacks			= mod:NewSpecialWarningDispel(203176, "MagicDispeller", nil, nil, 1, 2)
local specWarnTimeLock				= mod:NewSpecialWarningInterrupt(203957, "HasInterrupt", nil, nil, 1, 2)
local specWarnUnstableMana			= mod:NewSpecialWarningMoveAway(220871, nil, nil, nil, 3, 6)
local specWarnUnstableMana2			= mod:NewSpecialWarningClose(220871, nil, nil, nil, 2, 2)

local timerUnstableMana				= mod:NewTargetTimer(8, 220871, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerUnstableManaCD			= mod:NewCDTimer(30, 220871, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerForceBombD				= mod:NewCDTimer(42, 202974, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerEvent					= mod:NewCastTimer(124, 203914, nil, nil, nil, 6, nil, DBM_CORE_DEADLY_ICON)

local yellUnstableMana				= mod:NewYell(220871)
local yellUnstableMana2				= mod:NewFadesYell(220871)

local countdownEvent				= mod:NewCountdownFades(124, 203914, nil, nil, 10)

mod:AddSetIconOption("SetIconOnUnstableMana", 220871, true, false, {8})

mod.vb.phase = 1
mod.vb.interruptCount = 0
local warned_preP1 = false
local warned_preP2 = false

function mod:OnCombatStart(delay)
	self.vb.interruptCount = 0
	self.vb.phase = 1
	warned_preP1 = false
	warned_preP2 = false
	timerForceBombD:Start(25-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 203957 then
		warnTimeLock:Show(args.destName)
		if self:AntiSpam(3, 2) then
			if not UnitIsDeadOrGhost("player") then
				specWarnTimeLock:Show(args.sourceName)
				specWarnTimeLock:Play("kickcast")
			end
		end
	elseif spellId == 220871 then
		timerUnstableMana:Start(args.destName)
		if args:IsPlayer() then
			specWarnUnstableMana:Show()
			specWarnUnstableMana:Play("runout")
			specWarnUnstableMana:ScheduleVoice(1, "keepmove")
			yellUnstableMana:Yell()
			yellUnstableMana2:Countdown(8, 3)
		elseif self:CheckNearby(15, args.destName) then
			specWarnUnstableMana2:Show(args.destName)
			specWarnUnstableMana2:Play("runout")
		else
			warnUnstableMana:Show(args.destName)
		end
		if self.Options.SetIconOnUnstableMana then
			self:SetIcon(args.destName, 8, 8)
		end
		timerUnstableManaCD:Start()
	elseif spellId == 203176 then
		local amount = args.amount or 1
		if amount >= 4 then
			warnBlast:Show(args.destName, amount)
			if not UnitIsDeadOrGhost("player") then
				specWarnBlastStacks:Show(args.destName)
				specWarnBlastStacks:Play("dispelboss")
			end
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 202974 then
		if not UnitIsDeadOrGhost("player") then
			specWarnForceBomb:Show()
			specWarnForceBomb:Play("157349")
		end
		timerForceBombD:Start()
	elseif spellId == 203882 then
		timerForceBombD:Cancel()
		timerEvent:Start()
		countdownEvent:Start()
	elseif spellId == 203176 then
		timerEvent:Cancel()			--temp till fix
		countdownEvent:Cancel()
		if self.vb.interruptCount == 3 then self.vb.interruptCount = 0 end
		self.vb.interruptCount = self.vb.interruptCount + 1
		local kickCount = self.vb.interruptCount
		specWarnBlast:Show(args.sourceName, kickCount)
		--Takes 3 to block all casts, it only takes 2 in a row to break his stacks though.
		--3 count still makes sense for 2 though because you know which cast to skip to maintain order. Kick 1-2, skip 3, easy
		--A group with only one interruptor won't be able to prevent his stacks and need to use dispels on boss instead
		if kickCount == 1 then
			specWarnBlast:Play("kick1r")
		elseif kickCount == 2 then
			specWarnBlast:Play("kick2r")
		elseif kickCount == 3 then
			specWarnBlast:Play("kick3r")
		end
	end
end

function mod:SPELL_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 203833 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		if not self:IsNormal() then
			specWarnTimeSplit:Show()
			specWarnTimeSplit:Play("runaway")
		end
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

--[[
function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, bfaSpellId, _, legacySpellId)
	local spellId = legacySpellId or bfaSpellId
	if spellId == 147995 then
		self.vb.interruptCount = 0
		timerEvent:Cancel()
		countdownEvent:Cancel()
		timerForceBombD:Start(20)
	end
end
--]]

function mod:UNIT_HEALTH(uId)
	if not self:IsNormal() then
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 98208 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.60 then
			warned_preP1 = true
			warnPhase2:Show(DBM_CORE_AUTO_ANNOUNCE_TEXTS.stage:format(self.vb.phase+1))
		elseif self.vb.phase == 1 and warned_preP1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 98208 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.50 then
			self.vb.phase = 2
			warned_preP2 = true
		end
	else
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 98208 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.60 then
			warned_preP1 = true
		elseif self.vb.phase == 1 and warned_preP1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 98208 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.50 then
			self.vb.phase = 2
			warned_preP2 = true
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.RPVandros then
		self:SendSync("VandrosRP")
	end
end

function mod:OnSync(msg)
	if msg == "VandrosRP" then
		if self:IsMythic() then
			timerEvent:Cancel()
			countdownEvent:Cancel()
			timerForceBombD:Start(36)
			warnPhase:Show(DBM_CORE_AUTO_ANNOUNCE_TEXTS.stage:format(self.vb.phase))
			timerUnstableManaCD:Start(9)
		else
			timerEvent:Cancel()
			countdownEvent:Cancel()
			timerForceBombD:Start(36)
			warnPhase:Show(DBM_CORE_AUTO_ANNOUNCE_TEXTS.stage:format(self.vb.phase))
		end
	end
end