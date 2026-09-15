local mod	= DBM:NewMod("EoATrash", "DBM-Party-Legion", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17204 $"):sub(12, -3))
--mod:SetModelID(47785)
mod:SetZone()

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 196870 195046 195284 197105",
	"SPELL_AURA_APPLIED 196127 192706"
)

--TODO, still missing some GTFOs for this. Possibly other important spells.
local warnArcaneBomb			= mod:NewTargetAnnounce(192706, 4)
local warnPolymorph				= mod:NewTargetAnnounce(197105, 2)

local specWarnStorm				= mod:NewSpecialWarningInterrupt(196870, "HasInterrupt", nil, nil, 1, 2)
local specWarnPolymorph2		= mod:NewSpecialWarningDispel(197105, "MagicDispeller2", nil, nil, 1, 3)
local specWarnPolymorph			= mod:NewSpecialWarningInterrupt(197105, "HasInterrupt", nil, nil, 3, 5)
local specWarnRejuvWaters		= mod:NewSpecialWarningInterrupt(195046, "HasInterrupt", nil, nil, 1, 2)
local specWarnUndertow			= mod:NewSpecialWarningInterrupt(195284, false, nil, nil, 1, 2)
local specWarnSpraySand			= mod:NewSpecialWarningDodge(196127, "Tank", nil, nil, 1, 2)
local specWarnArcaneBomb		= mod:NewSpecialWarningMoveAway(192706, nil, nil, nil, 3, 2)
local yellArcaneBomb			= mod:NewYell(192706)
local yellPolymorph				= mod:NewYell(197105)

function mod:PolymorphTarget(targetname, uId)
	if not targetname then return end
	warnPolymorph:Show(targetname)
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 196870 and self:CheckInterruptFilter(args.sourceGUID) then
		specWarnStorm:Show(args.sourceName)
		specWarnStorm:Play("kickcast")
	elseif spellId == 195046 and self:CheckInterruptFilter(args.sourceGUID) then
		specWarnRejuvWaters:Show(args.sourceName)
		specWarnRejuvWaters:Play("kickcast")
	elseif spellId == 195284 and self:CheckInterruptFilter(args.sourceGUID) then
		specWarnUndertow:Show(args.sourceName)
		specWarnUndertow:Play("kickcast")
	elseif spellId == 197105 then
		self:BossTargetScanner(args.sourceGUID, "PolymorphTarget", 0.1, 2)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnPolymorph:Show(args.sourceName)
			specWarnPolymorph:Play("kickcast")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 196127 then
		specWarnSpraySand:Show()
		specWarnSpraySand:Play("shockwave")
	elseif spellId == 197105 then
		if args:IsPlayer() then
			yellPolymorph:Yell()
		elseif self:IsMagicDispeller2() then
			if not UnitIsDeadOrGhost("player") then
				specWarnPolymorph2:Show(args.destName)
				specWarnPolymorph2:Play("dispelnow")
			end
		else
			warnPolymorph:Show(args.destName)
		end
	elseif spellId == 192706 then
		if args:IsPlayer() then
			specWarnArcaneBomb:Show()
			specWarnArcaneBomb:Play("runout")
			yellArcaneBomb:Yell()
		else
			warnArcaneBomb:Show(args.destName)
		end
	end
end
