local mod	= DBM:NewMod(1665, "DBM-Party-Legion", 5, 767)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17436 $"):sub(12, -3))
mod:SetCreatureID(91004)
mod:SetEncounterID(1791)
mod:SetZone()
mod:SetHotfixNoticeRev(15186)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 198496 216290 193375 198428",
	"SPELL_CAST_SUCCESS 216290 198428",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)
--TODO: maybe bellow of the deeps, maybe improve timers

local warnStrikeofMountain			= mod:NewSpellAnnounce(216290, 2)
local warnBellowofDeeps				= mod:NewSpellAnnounce(193375, 2)
local warnStanceofMountain			= mod:NewCountAnnounce(198564, 2)

local specWarnSunder				= mod:NewSpecialWarningDefensive(198496, "Tank", nil, 2, 1, 2)
local specWarnStrikeofMountain		= mod:NewSpecialWarningDodge(198428, false, nil, nil, 1, 2)

local timerSunderCD					= mod:NewCDTimer(8, 198496, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerStrikeCD					= mod:NewCDTimer(15, 198428, nil, nil, nil, 3)
local timerBellowCD					= mod:NewCDTimer(34, 193375, nil, false, nil, 3)
local timerStanceOfMountainCD		= mod:NewCDCountTimer(53.8, 198564, nil, nil, nil, 6)

mod.vb.stanceofmountainCast = 0
mod.vb.strikeTimer = 0
mod.vb.sunderTimer = 0
mod.vb.bellowTimer = 0

function mod:OnCombatStart(delay)
	self.vb.stanceofmountainCast = 0
	self.vb.strikeTimer = 0
	self.vb.sunderTimer = 0
	self.vb.bellowTimer = 0
	timerSunderCD:Start(7.5-delay)
	timerStrikeCD:Start(14.9-delay)
	timerBellowCD:Start(20-delay)
	timerStanceOfMountainCD:Start(26.8-delay, 1)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 198496 then
		timerSunderCD:Start()
		self.vb.strikeTimer = timerStrikeCD:GetRemaining()
		self.vb.bellowTimer = timerBellowCD:GetRemaining()
		if self.vb.strikeTimer < 2.5 then
			timerStrikeCD:Start(self.vb.strikeTimer+15)
		end
		if timerBellowCD:GetRemaining() < 2.5 then
			timerBellowCD:Start(self.vb.bellowTimer+34)
		end
		specWarnSunder:Show()
		specWarnSunder:Play("defensive")
	elseif spellId == 198428 then
		self.vb.sunderTimer = timerSunderCD:GetRemaining()
		self.vb.bellowTimer = timerBellowCD:GetRemaining()
		if self.vb.sunderTimer < 3.1 then
			timerSunderCD:Start(self.vb.sunderTimer+8)
		end
		if self.vb.bellowTimer < 3.1 then
			timerBellowCD:Start(self.vb.bellowTimer+34)
		end
		timerStrikeCD:Start()
		warnStrikeofMountain:Show()
	elseif spellId == 193375 then
		timerBellowCD:Start()
		self.vb.sunderTimer = timerSunderCD:GetRemaining()
		self.vb.strikeTimer = timerStrikeCD:GetRemaining()
		if self.vb.sunderTimer < 4 then
			timerSunderCD:Start(self.vb.sunderTimer+8)
		end
		if self.vb.strikeTimer < 4 then
			timerStrikeCD:Start(self.vb.strikeTimer+15)
		end
		warnBellowofDeeps:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 198428 then
		if not UnitIsDeadOrGhost("player") then
			specWarnStrikeofMountain:Show()
			specWarnStrikeofMountain:Play("watchstep")
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, _, spellGUID)
	local spellId = tonumber(select(5, strsplit("-", spellGUID)), 10)
	if spellId == 198509 then--Stance of the Mountain
		self.vb.stanceofmountainCast = self.vb.stanceofmountainCast+1
		warnStanceofMountain:Show(self.vb.stanceofmountainCast)
		self.vb.sunderTimer = timerSunderCD:GetRemaining()
		self.vb.strikeTimer = timerStrikeCD:GetRemaining()
		self.vb.bellowTimer = timerBellowCD:GetRemaining()
		timerSunderCD:Stop()
		timerStrikeCD:Stop()
		timerBellowCD:Stop()
		timerStanceOfMountainCD:Stop()
	elseif spellId == 198631 then--Stance of mountain ending
		timerStanceOfMountainCD:Start(53.8, self.vb.stanceofmountainCast+1)
		timerSunderCD:Start(self.vb.sunderTimer)
		timerStrikeCD:Start(self.vb.strikeTimer)
		timerBellowCD:Start(self.vb.bellowTimer)
	end
end
