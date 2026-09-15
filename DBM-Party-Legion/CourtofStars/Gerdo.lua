local mod	= DBM:NewMod(1718, "DBM-Party-Legion", 7, 800)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17077 $"):sub(12, -3))
mod:SetCreatureID(104215)
mod:SetEncounterID(1868)
mod:SetZone()

mod.noNormal = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 207261 207815 207806 215204 207278",
	"SPELL_AURA_APPLIED 215204",
	"SPELL_CAST_SUCCESS 207278 219488"
)

local warnHinder					= mod:NewCastAnnounce(215204, 3)
local warnHinder2					= mod:NewTargetAnnounce(215204, 4)
local warnFlask						= mod:NewSpellAnnounce(207815, 2)
local warnArcaneLockdown			= mod:NewCastAnnounce(207278, 3)
local warnStreetsweeper				= mod:NewSpellAnnounce(219488, 4)


local specWarnHinder				= mod:NewSpecialWarningInterrupt(215204, "HasInterrupt", nil, nil, 1, 2)
local specWarnHinder2				= mod:NewSpecialWarningDispel(215204, "MagicDispeller2", nil, nil, 1, 5)
local specWarnResonantSlash			= mod:NewSpecialWarningDodge(207261, nil, nil, nil, 2, 2)
--local specWarnStreetsweeper			= mod:NewSpecialWarningDodge(219488, nil, nil, nil, 2, 3) --cast is always "on tank" in logs, wait for server-side fix if any
local specWarnArcaneLockdown		= mod:NewSpecialWarningJump(207278, nil, nil, nil, 2, 6)
local specWarnBeacon				= mod:NewSpecialWarningSwitch(207806, nil, nil, nil, 1, 2)

local timerStreetsweeperCD			= mod:NewCDTimer(7, 219488, nil, nil, nil, 3)
local timerResonantSlashCD			= mod:NewCDTimer(12.1, 207261, nil, nil, nil, 3)
local timerArcaneLockdownCD			= mod:NewCDTimer(28, 207278, nil, nil, nil, 2)

--local yellStreetsweeper				= mod:NewYell(219488, nil, nil, nil, "SAY")


mod.vb.phase = 1

function mod:OnCombatStart(delay)
	self.vb.phase = 1
	timerResonantSlashCD:Start(7-delay)
	timerArcaneLockdownCD:Start(18-delay)
	timerStreetsweeperCD:Start(11-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 207261 then
		specWarnResonantSlash:Show()
		specWarnResonantSlash:Play("watchstep")
		if self.vb.phase == 2 then
			timerResonantSlashCD:Start(10)
		else
			timerResonantSlashCD:Start()
		end
	elseif spellId == 207815 then
		self.vb.phase = 2
		--timerResonantSlashCD:Start(10)
		--timerArcaneLockdownCD:Start(16)
		--timerStreetsweeperCD:Start(11)
		warnFlask:Show()
	elseif spellId == 207806 then
		specWarnBeacon:Show()
		specWarnBeacon:Play("mobsoon")
		--timerResonantSlashCD:Start(15)
		--timerArcaneLockdownCD:Start(10)
		--timerStreetsweeperCD:Start(11)
	elseif spellId == 215204 and self:AntiSpam(2, 1) then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnHinder:Show()
			specWarnHinder:Play("kickcast")
		else
			warnHinder:Show()
			warnHinder:Play("kickcast")
		end
	elseif spellId == 207278 then
		warnArcaneLockdown:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	
	--destGUID == UnitGUID("player")
	if spellId == 207278 then--Success since jumping on cast start too early
		specWarnArcaneLockdown:Show()
		specWarnArcaneLockdown:Play("keepjump")
		timerArcaneLockdownCD:Start()
	elseif spellId == 219488 then
		warnStreetsweeper:Show()
		warnStreetsweeper:Play("watchstep")
		timerStreetsweeperCD:Start()
		--if args:IsPlayer() then
		--	yellStreetsweeper:Yell()
		--	specWarnStreetsweeper:Show()
		--end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 215204 then
		warnHinder2:CombinedShow(0.3, args.destName)
		specWarnHinder2:CombinedShow(0.3, args.destName)
		specWarnHinder2:ScheduleVoice(0.3, "dispelnow")
	end
end
