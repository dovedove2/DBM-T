local mod	= DBM:NewMod(1512, "DBM-Party-Legion", 8, 727)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17379 $"):sub(12, -3))
mod:SetCreatureID(96754)
mod:SetEncounterID(1823)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 194327",
--	"SPELL_AURA_REMOVED 194327",
	"SPELL_CAST_START 194231 194266 194216 194325",
	"SPELL_CAST_SUCCESS 194325"
)
--Note: can't detect Servitor cast nor Scythe cast, Todo: use servitor summon and boss drops target while casting Scythe

local warnFragment				= mod:NewTargetAnnounce(194327, 3)
local warnVoidSnap				= mod:NewCastAnnounce(194266, 4)

local specWarnFragment			= mod:NewSpecialWarningSwitch(194327, "Dps", nil, nil, 1, 2)
local specWarnFragment2			= mod:NewSpecialWarningYou(194327, nil, nil, nil, 3, 5)
local specWarnServitor			= mod:NewSpecialWarningSwitch(194231, "-Healer", nil, nil, 1, 2)
local specWarnVoidSnap			= mod:NewSpecialWarningInterrupt(194266, "HasInterrupt", nil, nil, 1, 2)
local specWarnScythe			= mod:NewSpecialWarningDodge(194216, nil, nil, nil, 2, 2)

local timerFragmentCD			= mod:NewCDTimer(30, 194327, nil, nil, nil, 3)
local timerServitorCD			= mod:NewCDTimer(23, 194231, nil, nil, nil, 1)--23-30
local timerScytheCD				= mod:NewCDTimer(9, 194216, nil, nil, nil, 1)

local yellFragment				= mod:NewYell(194327, nil, nil, nil, "SAY")

function mod:OnCombatStart(delay)
	timerServitorCD:Start(7-delay)
	timerFragmentCD:Start(21-delay)
	timerScytheCD:Start(11.8-delay)
end


function mod:FragmentTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnFragment2:Show()
		specWarnFragment2:Play("targetyou")
		yellFragment:Yell()
	else
		warnFragment:Show(targetname)
	end
end

function mod:OnCombatEnd()
--	if self.Options.RangeFrame then
--		DBM.RangeCheck:Hide()
--	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 194327 then
		specWarnFragment:Show()
		specWarnFragment:Play("mobkill")
	end
end

--[[
function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 194327 then

	end
end
--]]

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 194231 then
		specWarnServitor:Show()
		specWarnServitor:Play("bigmob")
		timerServitorCD:Start()
	elseif spellId == 194266 then
		warnVoidSnap:Show()
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnVoidSnap:Show(args.sourceName)
			specWarnVoidSnap:Play("kickcast")
		end
	elseif spellId == 194216 then
		specWarnScythe:Show()
		specWarnScythe:Play("shockwave")
	elseif spellId == 194325 then
		timerFragmentCD:Start()
		self:BossTargetScanner(args.sourceGUID, "FragmentTarget", 0.05, 4)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 194216 then
		timerScytheCD:Start()
	end
end
