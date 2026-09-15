local mod	= DBM:NewMod(1486, "DBM-Party-Legion", 4, 721)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
mod:SetCreatureID(95833)
mod:SetEncounterID(1806)
mod:SetZone()
mod:SetUsedIcons(8, 7)
mod:RegisterCombat("combat")
mod:SetWipeTime(120)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 192048 192133 192132",
	"SPELL_AURA_APPLIED_DOSE 192048 192133 192132",
	"SPELL_AURA_REMOVED 192048 192133 192132",
	"SPELL_CAST_START 192158 192018 192307 200901 191976",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--Notes: Saw no timer consistency since they are all over the place based on where boss is dragged.
--TODO: maybe figure out how dragging boss around affects timers. Might be worth the work for a 5 man boss though.

local warnExpelLight				= mod:NewTargetAnnounce(192048, 3)
local warnArcingBolt				= mod:NewTargetAnnounce(191976, 3)
--local warnPhase2					= mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)

local specWarnShieldOfLight			= mod:NewSpecialWarningDefensive(192018, "Tank", nil, nil, 3, 2)--Journal lies, this is NOT dodgable
local specWarnSanctify				= mod:NewSpecialWarningDodge(192158, "Ranged", nil, nil, 2, 5)
local specWarnSanctify2				= mod:NewSpecialWarningRun(192158, "Melee", nil, nil, 4, 5)
local specWarnEyeofStorm			= mod:NewSpecialWarningMoveTo(200901, nil, nil, nil, 1, 3)
local specWarnEyeofStorm2			= mod:NewSpecialWarningDefensive(200901, false, nil, nil, 2, 3)
local specWarnExpelLight			= mod:NewSpecialWarningMoveAway(192048, nil, nil, nil, 1, 2)
local specWarnArcingBolt			= mod:NewSpecialWarningMoveAway(191976, nil, nil, nil, 3, 3)

local yellExpelLight				= mod:NewYell(192048)
local yellExpelLight2				= mod:NewShortFadesYell(192048)
local yellArcingBolt				= mod:NewYell(191976)

local timerArcingBoltCD				= mod:NewCDTimer(11, 191976, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON) --
local timerShieldOfLightCD			= mod:NewCDTimer(27, 192018, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON)--28-34
local timerSpecialCD				= mod:NewNextTimer(30, 200736, nil, nil, nil, 2, 200901, DBM_CORE_DEADLY_ICON)--Shared timer by eye of storm and Sanctify Todo: add prediction for which spell
local timerExpelLightCD				= mod:NewCDTimer(23.5, 192048, nil, nil, nil, 3)--More review 23.5-30

local countdownSpecial				= mod:NewCountdown(30, 200736)
local countdownShieldOfLight		= mod:NewCountdown("Alt27", 192018, "Tank")

mod:AddSetIconOption("SetIconOnExpelLight", 192048, true, false, {8})
mod:AddSetIconOption("SetIconOnArcingBolt", 191976, true, false, {7})
mod:AddRangeFrameOption(8, 192048)

local eyeShortName = DBM:GetSpellInfo(91320)--Inner Eye
--mod.vb.phase = 1

function mod:ArcingBoltTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnArcingBolt:Show()
		specWarnArcingBolt:Play("defensive")
		yellArcingBolt:Yell()
	else
		warnArcingBolt:Show(targetname)
	end
	if self.Options.SetIconOnArcingBolt then
		self:SetIcon(targetname, 7, 5)
	end
end

function mod:OnCombatStart(delay)
	--self.vb.phase = 1
	timerArcingBoltCD:Start(4-delay)
	timerShieldOfLightCD:Start(24-delay)
	timerSpecialCD:Start(9-delay)
	timerExpelLightCD:Start(4-delay)
	countdownSpecial:Start(9-delay)
	countdownShieldOfLight:Start(24-delay)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 192048 then
		warnExpelLight:Show(args.destName)
		if not self:IsNormal() then
			if args:IsPlayer() then
				specWarnExpelLight:Show()
				specWarnExpelLight:Play("runout")
				yellExpelLight:Yell()
				yellExpelLight2:Countdown(3)
			end
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(8)
		end
		if self.Options.SetIconOnExpelLight then
			self:SetIcon(args.destName, 8, 5)
		end
		if not timerExpelLightCD:IsStarted() then --placeholder check till we find a better method
			timerExpelLightCD:Start()
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 192048 and args:IsPlayer() and self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	elseif spellId == 192133 then
		timerExpelLightCD:Stop()
	elseif spellId == 192132 then
		timerArcingBoltCD:Stop()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 192158 or spellId == 192307 then
		specWarnSanctify:Show()
		specWarnSanctify:Play("watchorb")
		timerSpecialCD:Start()
		countdownSpecial:Cancel()
		countdownSpecial:Start()
	elseif spellId == 192018 then
		specWarnShieldOfLight:Show()
		specWarnShieldOfLight:Play("defensive")
		timerShieldOfLightCD:Start()
		countdownShieldOfLight:Start()
	elseif spellId == 200901 then
		specWarnEyeofStorm:Show(eyeShortName)
		specWarnEyeofStorm:Play("findshelter")
		timerSpecialCD:Start()
		countdownSpecial:Cancel()
		countdownSpecial:Start()
	elseif spellId == 191976 then
		self:BossTargetScanner(args.sourceGUID, "ArcingBoltTarget", 0.1, 2)
		timerArcingBoltCD:Start()
	end
end
--[[
function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, _, spellGUID)
	local spellId = tonumber(select(5, strsplit("-", spellGUID)), 10)
	if spellId == 192130 then
		self.vb.phase = 2
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		timerSpecialCD:Start(8.5)
		countdownSpecial:Start(8.5)
		timerShieldOfLightCD:Start(24)
		countdownShieldOfLight:Start(24)
	end
end
--]]