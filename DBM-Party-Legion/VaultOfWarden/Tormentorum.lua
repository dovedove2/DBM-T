local mod	= DBM:NewMod(1695, "DBM-Party-Legion", 10, 707)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
mod:SetCreatureID(96015)
mod:SetEncounterID(1850)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 201488 200898",
	"SPELL_CAST_SUCCESS 200905 206303",
	"SPELL_AURA_APPLIED 212564 203685",
	"SPELL_AURA_APPLIED_DOSE 203685",
	"UNIT_SPELLCAST_SUCCEEDED boss1",
	"UNIT_HEALTH"
)

local warnTeleport				= mod:NewSpellAnnounce(200898, 2)
local warnTeleport2				= mod:NewSoonAnnounce(200898, 1)

local specWarnFleshtoStone		= mod:NewSpecialWarningStack(203685, nil, 7, nil, nil, 1, 3)
local specWarnFleshtoStone2		= mod:NewSpecialWarningDispel(203685, "MagicDispeller2", nil, nil, 3, 3)
local specWarnSapSoul			= mod:NewSpecialWarningInterrupt(200905, "HasInterrupt", nil, nil, 1, 2)
local specWarnSapSoulHard		= mod:NewSpecialWarningCast(200905, nil, nil, nil, 1, 2)
local specWarnFear				= mod:NewSpecialWarningSpell(201488, nil, nil, nil, 2, 2)
local specWarnStare				= mod:NewSpecialWarningYou(212564, nil, nil, nil, 1, 6)

local timerSapSoulCD			= mod:NewCDTimer(20, 200905, nil, nil, nil, 4, nil, DBM_CORE_INTERRUPT_ICON)
local timerTormOrbCD			= mod:NewNextTimer(20, 212567, nil, nil, nil, 7)

local countSapSoul				= mod:NewCountdown(20, 200905, true, 2, 5)

mod.vb.phase = 1
local warned_preP1 = false
local warned_preP2 = false
local warned_preP3 = false
local warned_preP4 = false

local function UpdateSapSoulTimer(self)
	countSapSoul:Cancel()
	timerSapSoulCD:Stop()
	countSapSoul:Start(6.5)
	timerSapSoulCD:Start(6.5)
end

function mod:OnCombatStart(delay)
	self.vb.phase = 1
	timerSapSoulCD:Start(10-delay)--Might be 10-13?
	countSapSoul:Start(10-delay)
	if not self:IsNormal() then
		timerTormOrbCD:Start(20-delay)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 201488 then
		if not UnitIsDeadOrGhost("player") then
			specWarnFear:Show()
			specWarnFear:Play("fearsoon")
		end
	elseif spellId == 200898 then
		warnTeleport:Show()
		if timerSapSoulCD:GetTime() < 6 then
			UpdateSapSoulTimer(self)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args.spellId == 200905 or spellId == 206303 then
		countSapSoul:Cancel()--Just in case
		timerSapSoulCD:Start()
		countSapSoul:Start()
		if self:IsHard() then--Mythic and mythic + only
			if not UnitIsDeadOrGhost("player") then
				specWarnSapSoulHard:Show()
				specWarnSapSoulHard:Play("stopcast")
			end
		else--Everything else
			if not UnitIsDeadOrGhost("player") then
				specWarnSapSoul:Show()
				specWarnSapSoul:Play("kickcast")
			end
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 212564 then
		if args:IsPlayer() and self:AntiSpam(2.5, 1) then
			specWarnStare:Show(L.lookSphere)
			specWarnStare:Play("turnaway")
		end
	elseif spellId == 203685 and args:IsDestTypePlayer() then
		local amount = args.amount or 1
		if amount >= 7 then
			if args:IsPlayer() then
				specWarnFleshtoStone:Show(amount)
				specWarnFleshtoStone:Play("stackhigh")
			else
				if not UnitIsDeadOrGhost("player") then
					specWarnFleshtoStone2:CombinedShow(0.5, args.destName)
					specWarnFleshtoStone2:ScheduleVoice(0.5, "dispelnow")
				end
			end
		end
	end	
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, bfaSpellId, _, legacySpellId)
	local spellId = legacySpellId or bfaSpellId
	if spellId == 214970 then--Summon Tormenting Orb
		timerTormOrbCD:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	if self:IsHard() then
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 96015 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.81 then
			warned_preP1 = true
			warnTeleport2:Show()
		elseif self.vb.phase == 1 and warned_preP1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 96015 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.71 then
			self.vb.phase = 2
			warned_preP2 = true
		elseif self.vb.phase == 2 and warned_preP2 and not warned_preP3 and self:GetUnitCreatureId(uId) == 96015 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.51 then
			warned_preP3 = true
			warnTeleport2:Show()
		elseif self.vb.phase == 2 and warned_preP3 and not warned_preP4 and self:GetUnitCreatureId(uId) == 96015 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.41 then
			self.vb.phase = 3
			warned_preP4 = true
		end
	else
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 96015 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.81 then
			warned_preP1 = true
		elseif self.vb.phase == 1 and warned_preP1 and not warned_preP2 and self:GetUnitCreatureId(uId) == 96015 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.71 then
			self.vb.phase = 2
			warned_preP2 = true
		elseif self.vb.phase == 2 and warned_preP2 and not warned_preP3 and self:GetUnitCreatureId(uId) == 96015 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.51 then
			warned_preP3 = true
		elseif self.vb.phase == 2 and warned_preP3 and not warned_preP4 and self:GetUnitCreatureId(uId) == 96015 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.41 then
			self.vb.phase = 3
			warned_preP4 = true
		end
	end
end