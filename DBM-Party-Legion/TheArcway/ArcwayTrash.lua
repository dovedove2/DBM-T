local mod	= DBM:NewMod("ArcwayTrash", "DBM-Party-Legion", 6)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
--mod:SetModelID(47785)
mod:SetZone()

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 211757 226206 193938 211115 211007 226285 226269 211217 211771 211917 211875",
	"SPELL_CAST_SUCCESS 211917",
	"SPELL_AURA_APPLIED 194006 210750 211745"
)

--Note: Unstable Amalgamation casts are hidden
local warnPhaseBreach				= mod:NewCastAnnounce(211115, 4)
local warnArcaneReconstitution		= mod:NewCastAnnounce(226206, 3)
local warnOozeExplosion				= mod:NewCastAnnounce(193938, 4)
local warnEyeVortex					= mod:NewCastAnnounce(211007, 4)
local warnDemonicAscension			= mod:NewCastAnnounce(226285, 4)
local warnTorment					= mod:NewCastAnnounce(226269, 4)

local specWarnFelstorm				= mod:NewSpecialWarningDodge(211917, nil, nil, nil, 2, 2)
local specWarnBladestorm			= mod:NewSpecialWarningRun(211875, "Melee", nil, nil, 4, 3)
local specWarnBladestorm2			= mod:NewSpecialWarningDodge(211875, "Ranged", nil, nil, 2, 2)

local specWarnOozeExplosion			= mod:NewSpecialWarningDodge(193938, nil, nil, nil, 2, 2)
local specWarnArcaneSlicer			= mod:NewSpecialWarningDodge(211217, nil, nil, nil, 2, 3)
local specWarnPropheciesofDoom		= mod:NewSpecialWarningDodge(211771, false, nil, nil, 2, 5)
local specWarnArgusPortal			= mod:NewSpecialWarningInterrupt(211757, "HasInterrupt", nil, nil, 1, 2)
local specWarnArcaneReconstitution	= mod:NewSpecialWarningInterrupt(226206, "HasInterrupt", nil, nil, 1, 2)
local specWarnTorment				= mod:NewSpecialWarningInterrupt(226269, false, nil, nil, 1, 2)
local specWarnPhaseBreach			= mod:NewSpecialWarningInterrupt(211115, false, nil, nil, 1, 6)
local specWarnDemonicAscension		= mod:NewSpecialWarningInterrupt(226285, "HasInterrupt", nil, nil, 1, 2)

local specWarnOozePuddle			= mod:NewSpecialWarningMove(194006, nil, nil, nil, 1, 2)
local specWarnColapsingRift			= mod:NewSpecialWarningMove(210750, nil, nil, nil, 1, 2)
local specWarnFelStrike				= mod:NewSpecialWarningMove(211745, nil, nil, nil, 1, 2)

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 211757 and self:CheckInterruptFilter(args.sourceGUID) then
		specWarnArgusPortal:Show(args.sourceName)
		specWarnArgusPortal:Play("kickcast")
	elseif spellId == 211771 and self:AntiSpam(2, 2) then
		specWarnPropheciesofDoom:Show()
		specWarnPropheciesofDoom:Play("defensive")
	elseif spellId == 193938 and self:AntiSpam(2, 1) then
		warnOozeExplosion:Show()
		specWarnOozeExplosion:Show()
		specWarnOozeExplosion:Play("aesoon")
	elseif spellId == 211007 then
		warnEyeVortex:Show()
		warnEyeVortex:Play("kickcast")
	elseif spellId == 211115 then
		warnPhaseBreach:Show()
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnPhaseBreach:Show(args.sourceName)
			specWarnPhaseBreach:Play("kickcast")
		end
	elseif spellId == 211217 and self:AntiSpam(2, 3) then
		specWarnArcaneSlicer:Show()
		specWarnArcaneSlicer:Play("shockwave")
	elseif spellId == 226269 then
		warnTorment:Show()
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnTorment:Show(args.sourceName)
			specWarnTorment:Play("kickcast")
		end
	elseif spellId == 211875 then
		specWarnBladestorm2:Show()
		specWarnBladestorm2:Play("watchstep")
		specWarnBladestorm:Show()
		specWarnBladestorm:Play("justrun")
	elseif spellId == 226206 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnArcaneReconstitution:Show(args.sourceName)
			specWarnArcaneReconstitution:Play("kickcast")
		else
			warnArcaneReconstitution:Show()
			warnArcaneReconstitution:Play("kickcast")
		end
	elseif spellId == 226285 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDemonicAscension:Show(args.sourceName)
			specWarnDemonicAscension:Play("kickcast")
		else
			warnDemonicAscension:Show()
			warnDemonicAscension:Play("kickcast")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 211917 then
		specWarnFelstorm:Show()
		specWarnFelstorm:Play("watchstep")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 194006 and args:IsPlayer() then
		specWarnOozePuddle:Show()
		specWarnOozePuddle:Play("runaway")
	elseif spellId == 210750 and args:IsPlayer() then
		specWarnColapsingRift:Show()
		specWarnColapsingRift:Play("runaway")
	elseif spellId == 211745 and args:IsPlayer() then
		specWarnFelStrike:Show()
		specWarnFelStrike:Play("runaway")
	end
end
