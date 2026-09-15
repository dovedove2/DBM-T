local mod	= DBM:NewMod(1687, "DBM-Party-Legion", 5, 767)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17440 $"):sub(12, -3))
mod:SetCreatureID(91007)
mod:SetEncounterID(1793)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 200732 200551 200637 200700 200404",
	"SPELL_AURA_APPLIED 200154",
	"SPELL_AURA_REMOVED 200154",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

local warnCrystalSpikes				= mod:NewSpellAnnounce(200551, 2)
local warnBurningHatred				= mod:NewTargetAnnounce(200154, 2)

local specWarnMoltenCrash			= mod:NewSpecialWarningDefensive(200732, "Tank", nil, nil, 3, 2)
local specWarnLandSlide				= mod:NewSpecialWarningSpell(200700, "Tank", nil, nil, 1, 2)
local specWarnMagmaSculptor			= mod:NewSpecialWarningSwitch(200637, "Dps", nil, nil, 1, 2)
local specWarnMagmaWave				= mod:NewSpecialWarningMoveTo(200404, nil, nil, nil, 2, 2)
local specWarnBurningHatred			= mod:NewSpecialWarningYou(200154, nil, nil, nil, 1, 2)

local timerMoltenCrashCD			= mod:NewCDTimer(16.5, 200732, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON)--16.5-23
local timerLandSlideCD				= mod:NewCDTimer(16.6, 200700, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON)--16.5-27
local timerCrystalSpikesCD			= mod:NewCDTimer(21.4, 200551, nil, nil, nil, 3)
local timerMagmaSculptorCD			= mod:NewCDTimer(70.5, 200637, nil, nil, nil, 1)--Everyone?
local timerMagmaWaveCD				= mod:NewCDTimer(60, 200404, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerBurningHatred			= mod:NewTargetTimer(30, 200154, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)

local countdownMagmaWave			= mod:NewCountdown(60, 200404)
--local countdownMoltenCrash		= mod:NewCountdown("Alt28", 200732, "Tank")

local shelterName = DBM:GetSpellInfo(200551)

function mod:OnCombatStart(delay)
	timerMagmaSculptorCD:Start(9-delay)
	timerLandSlideCD:Start(17-delay)
	timerMoltenCrashCD:Start(20.5-delay)
	timerCrystalSpikesCD:Start(4.5-delay)
	timerMagmaWaveCD:Start(60.9-delay)
	countdownMagmaWave:Start(60.9-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 200732 then
		specWarnMoltenCrash:Show()
		specWarnMoltenCrash:Play("defensive")
		timerMoltenCrashCD:Start()
	elseif spellId == 200551 then
		warnCrystalSpikes:Show()
		timerCrystalSpikesCD:Start()
	elseif spellId == 200637 then
		specWarnMagmaSculptor:Show()
		specWarnMagmaSculptor:Play("killbigmob")
		timerMagmaSculptorCD:Start()
	elseif spellId == 200700 then
		specWarnLandSlide:Show()
		specWarnLandSlide:Play("shockwave")
		timerLandSlideCD:Start()
	elseif spellId == 200404 and self:AntiSpam(3, 1) then
		specWarnMagmaWave:Show(shelterName)
		specWarnMagmaWave:Play("findshelter")
		timerMagmaWaveCD:Start()
		countdownMagmaWave:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 200154 then
		timerBurningHatred:Start(args.destName)
		if args:IsPlayer() then
			specWarnBurningHatred:Show()
			specWarnBurningHatred:Play("targetyou")
		else
			warnBurningHatred:Show(args.destName)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 200154 then
		timerBurningHatred:Cancel(args.destName)
	--	if args:IsPlayer() then
	--	end
		if self.Options.SetIconOnBurningHatred then
			self:SetIcon(args.destName, 0)
		end
	end
end

--1 second faster than combat log. 1 second slower than Unit event callout but that's no longer reliable.
function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg:find("spell:200404") and self:AntiSpam(3, 1) then
		specWarnMagmaWave:Show(shelterName)
		specWarnMagmaWave:Play("findshelter")
		timerMagmaWaveCD:Start()
		countdownMagmaWave:Start()
	end
end
