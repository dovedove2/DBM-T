local mod	= DBM:NewMod(1490, "DBM-Party-Legion", 3, 716)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17471 $"):sub(12, -3))
mod:SetCreatureID(91789)
mod:SetEncounterID(1811)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 193698",
	"SPELL_CAST_START 193682 193597 193611",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--TODO, maybe add a "get back in boss area warning" if you take Crackling THunder damage
--TODO, more curse notes perhaps? Add special warning for player maybe?

local warnCurseofWitch				= mod:NewTargetAnnounce(193698, 3)

local specWarnStaticNova			= mod:NewSpecialWarning("specWarnStaticNova", nil, DBM_CORE_AUTO_SPEC_WARN_OPTIONS.dodge:format(193597), nil, 3, 2)
local specWarnFocusedLightning		= mod:NewSpecialWarningMoveAway(193611, nil, nil, nil, 3, 6)
local specWarnAdds					= mod:NewSpecialWarningSwitch(193682, "Tank", nil, nil, 1, 2)
local yellCurseofWitch				= mod:NewShortFadesYell(193698)

local timerAddsCD					= mod:NewCDTimer(50, 193682, nil, nil, nil, 1)--47-51
local timerStaticNovaCD				= mod:NewCDTimer(34, 193597, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerFocusedLightningCD		= mod:NewNextTimer(35, 193611, nil, nil, nil, 3)
local timerMonsoonCD				= mod:NewCDTimer(20, 196610, nil, nil, nil, 7)

local countdownStaticNova			= mod:NewCountdown(34, 193597)

function mod:OnCombatStart(delay)
	timerStaticNovaCD:Start(10-delay)
	countdownStaticNova:Start(10-delay)
	timerAddsCD:Start(18.5-delay)
	timerFocusedLightningCD:Start(25-delay)
	timerMonsoonCD:Start(30-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 193698 then
		warnCurseofWitch:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			local _, _, _, _, _, _, expires = DBM:UnitDebuff("player", args.spellName)
			local debuffTime = expires - GetTime()
			yellCurseofWitch:Schedule(debuffTime-1, 1)
			yellCurseofWitch:Schedule(debuffTime-2, 2)
			yellCurseofWitch:Schedule(debuffTime-3, 3)
		end
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 193682 then
		specWarnAdds:Show()
		specWarnAdds:Play("mobsoon")
		timerAddsCD:Start()
	elseif spellId == 193597 then
		specWarnStaticNova:Show()
		specWarnStaticNova:Play("findshelter")
		
		countdownStaticNova:Start()
		timerStaticNovaCD:Start()

	elseif spellId == 193611 then
		specWarnFocusedLightning:Show()
		timerFocusedLightningCD:Start()
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, bfaSpellId, _, legacySpellId)
	local spellId = legacySpellId or bfaSpellId
	if spellId == 196634 or spellId == 196629 then --Муссон
		timerMonsoonCD:Start()
	end
end