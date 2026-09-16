local mod	= DBM:NewMod("DHTTrash", "DBM-Party-Legion", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17204 $"):sub(12, -3))
--mod:SetModelID(47785)
mod:SetZone()

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 200580 200630 200768",
	"SPELL_AURA_APPLIED 204243"
)

--TODO: Cat Leaps
local warnUnnervingScreech				= mod:NewCastAnnounce(200630, 4)

local specWarnPropellingCharge			= mod:NewSpecialWarningDodge(200768, nil, nil, nil, 2, 3)
local specWarnMaddeningRoar				= mod:NewSpecialWarningSpell(200580, nil, nil, nil, 1, 5)

local specWarnTormentingEye				= mod:NewSpecialWarningInterrupt(204243, "HasInterrupt", nil, nil, 1, 2)
local specWarnUnnervingScreech			= mod:NewSpecialWarningInterrupt(200630, "HasInterrupt", nil, nil, 1, 2)


function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 200630 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnUnnervingScreech:Show(args.sourceName)
			specWarnUnnervingScreech:Play("kickcast")
		else
			warnUnnervingScreech:Show()
			warnUnnervingScreech:Play("kickcast")
		end
	elseif spellId == 200580 and self:AntiSpam(2, 2) then
		if not self:IsNormal() then
			specWarnMaddeningRoar:Show()
			specWarnMaddeningRoar:Play("defensive")
	end
	elseif spellId == 200768 and self:AntiSpam(1.5, 7) then
		specWarnPropellingCharge:Show()
		specWarnPropellingCharge:Play("watchstep")
	end
end


function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 204243 and self:AntiSpam(2, 5) then
		if not self:IsNormal() then
			specWarnTormentingEye:Show(args.sourceName)
			specWarnTormentingEye:Play("kickcast")
		end
	end
end