local mod	= DBM:NewMod("MawTrash", "DBM-Party-Legion", 8)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17204 $"):sub(12, -3))
--mod:SetEncounterID(1823)
mod:SetZone()

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 198405 195031 195293 196885 194099 192019",
	"SPELL_CAST_SUCCESS 195279",
	"SPELL_AURA_APPLIED 195279 200208",
	"SPELL_AURA_REMOVED 195279 200208",
	"SPELL_PERIODIC_DAMAGE 194102",
	"SPELL_PERIODIC_MISSED 194102",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED"
)

local warnScream				= mod:NewSpellAnnounce(198405, 4)

local specWarnBrackwaterBlast	= mod:NewSpecialWarningMoveAway(200208, nil, nil, nil, 1, 5)
local specWarnLanternDarkness	= mod:NewSpecialWarningDefensive(192019, nil, nil, nil, 2, 5)
local specWarnPoisonousSludge	= mod:NewSpecialWarningMove(194102, nil, nil, nil, 1, 2)
local specWarnBileBreath		= mod:NewSpecialWarningDodge(194099, nil, nil, nil, 2, 3)
local specWarnScream			= mod:NewSpecialWarningInterrupt(198405, "HasInterrupt", nil, nil, 1, 2)
local specWarnDebilitatingShout	= mod:NewSpecialWarningInterrupt(195293, "HasInterrupt", nil, nil, 1, 2)
local specWarnGiveNoQuarter		= mod:NewSpecialWarningDodge(196885, nil, nil, nil, 2, 3)
local specWarnBileBreath		= mod:NewSpecialWarningDodge(194099, nil, nil, nil, 2, 3)
local specWarnDefiantStrike		= mod:NewSpecialWarningDodge(195031, nil, nil, nil, 1, 2)

local timerLanternDarknessCD	= mod:NewCDTimer(16, 192019, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerBindCD				= mod:NewCDTimer(15, 195279, nil, "Tank", nil, 3, nil, DBM_CORE_TANK_ICON)
local timerDebilitatingShoutCD	= mod:NewCDTimer(14.5, 195293, nil, nil, nil, 4, nil, DBM_CORE_INTERRUPT_ICON)
local timerGiveNoQuarterCD		= mod:NewCDTimer(9, 196885, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)

local timerRoleplay				= mod:NewCombatTimer(10)


function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 198405 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnScream:Show(args.sourceName)
			specWarnScream:Play("kickcast")
		elseif self:AntiSpam(2, 1) then
			warnScream:Show()
			warnScream:Play("kickcast")
		end
	elseif spellId == 195031 and self:AntiSpam(2, 1) then
		if not self:IsNormal() then
			specWarnDefiantStrike:Show()
			specWarnDefiantStrike:Play("chargemove")
		end
	elseif spellId == 195293 and self:AntiSpam(2, 1) then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDebilitatingShout:Show(args.sourceName)
			specWarnDebilitatingShout:Play("kickcast")
		end
		timerDebilitatingShoutCD:Start()
	elseif spellId == 196885 and self:AntiSpam(2, 1) then
		if not self:IsNormal() then
			specWarnGiveNoQuarter:Show()
			specWarnGiveNoQuarter:Play("stilldanger")
		end
		timerGiveNoQuarterCD:Start()
	elseif spellId == 194099 then
		if not self:IsNormal() then
			specWarnBileBreath:Show()
			specWarnBileBreath:Play("stilldanger")
		end
	elseif spellId == 192019 and self:AntiSpam(3, 1) then
		timerLanternDarknessCD:Start()
		if not self:IsNormal() then
			specWarnLanternDarkness:Show()
			specWarnLanternDarkness:Play("defensive")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 195279 then
		timerBindCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 200208 then
		if not self:IsNormal() then
			if args:IsPlayer() and self:AntiSpam(2, 1) then
				specWarnBrackwaterBlast:Show()
				specWarnBrackwaterBlast:Play("moveaway")
			end
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Helya then
		--timerRoleplay:Start(13)	--tauri kinda does it too late, maybe look for tentacle/helya spawn
	--	self:SendSync("RPHelya")
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 194102 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		if not self:IsNormal() then
			specWarnPoisonousSludge:Show()
			specWarnPoisonousSludge:Play("runaway")
		end
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 99307 then
		timerGiveNoQuarterCD:Cancel()
		timerDebilitatingShoutCD:Cancel()
		timerBindCD:Cancel()
	elseif cid == 97182 then
		timerLanternDarknessCD:Cancel()
		timerBindCD:Cancel()
	end
end
