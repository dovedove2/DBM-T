local mod	= DBM:NewMod(1487, "DBM-Party-Legion", 4, 721)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17095 $"):sub(12, -3))
mod:SetCreatureID(95674, 99868)
mod:SetEncounterID(1807)
mod:DisableEEKillDetection()
mod:SetZone()
mod:SetUsedIcons(8)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 197556 196838",
	"SPELL_AURA_REMOVED 196838",
	"SPELL_CAST_START 196838 196543",
	"SPELL_CAST_SUCCESS 196567 196512 207707",
	"UNIT_DIED"
)

--TODO, Keep checking/fixing timers
local warnLeap							= mod:NewTargetAnnounce(197556, 2)
local warnPhase2						= mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnFixate						= mod:NewTargetAnnounce(196838, 3)
local warnClawFrenzy					= mod:NewSpellAnnounce(196512, 2, nil, "Melee")

local specWarnLeap						= mod:NewSpecialWarningMoveAway(197556, nil, nil, nil, 1, 2)
local specWarnHowl						= mod:NewSpecialWarningCast(196543, "SpellCaster", nil, nil, 1, 2)
local specWarnFixate					= mod:NewSpecialWarningRun(196838, nil, nil, nil, 4, 2)
local specWarnFixateOver				= mod:NewSpecialWarningEnd(196838, nil, nil, nil, 1)
local specWarnWolves					= mod:NewSpecialWarningSwitch("ej12600", "Tank|Dps")

local timerLeapCD						= mod:NewCDTimer(35, 197556, nil, nil, nil, 3)--31-36
local timerClawFrenzyCD					= mod:NewCDTimer(10, 196512, nil, "Melee", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerHowlCD						= mod:NewCDTimer(35, 196543, nil, "SpellCaster", nil, 2)
local timerFixateCD						= mod:NewCDTimer(35, 196838, nil, nil, nil, 3)
--local timerWolvesCD						= mod:NewCDTimer(35, "ej12600", nil, nil, nil, 1, 199184)

local yellLeap							= mod:NewYell(197556)
local yellFixate						= mod:NewYell(196838)--

mod:AddSetIconOption("SetIconOnFixate", 196838, true, false, {8})

mod:AddRangeFrameOption(10, 197556)

mod.vb.phase = 1

function mod:FixateTarget(targetname, uId)
	if not targetname then return end
	if self:AntiSpam(5, targetname) then
		if targetname == UnitName("player") then
			specWarnFixate:Show()
			specWarnFixate:Play("runaway")
			specWarnFixate:ScheduleVoice(1, "keepmove")
			yellFixate:Yell()
		else
			warnFixate:Show(targetname)
		end
		if self.Options.SetIconOnFixate then
			self:SetIcon(targetname, 8, 10)
		end
	end
end

function mod:OnCombatStart(delay)
	self.vb.phase = 1
	self:SetWipeTime(5)
	timerHowlCD:Start(22-delay)
	timerLeapCD:Start(6.5-delay)
	timerClawFrenzyCD:Start(15-delay)
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 197556 then
		warnLeap:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnLeap:Show()
			specWarnLeap:Play("runout")
			timerLeapCD:Start()
			yellLeap:Yell()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(10)
			end
		end
	elseif spellId == 196838 then
		--Backup if target scan failed
		if self:AntiSpam(5, args.destName) then
			if args:IsPlayer() then
				specWarnFixate:Show()
				specWarnFixate:Play("runaway")
				specWarnFixate:ScheduleVoice(1, "keepmove")
			else
				warnFixate:Show(args.destName)
			end
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 197556 and args:IsPlayer() and self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	elseif spellId == 196838 and args:IsPlayer() then
		specWarnFixateOver:Show()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 196838 then
		timerFixateCD:Start()
		self:BossTargetScanner(99868, "FixateTarget", 0.2, 12, true, nil, nil, nil, true)--Target scanning used to grab target 2-3 seconds faster. Doesn't seem to anymore?
	elseif spellId == 196543 then
		specWarnHowl:Show()
		specWarnHowl:Play("stopcast")
		timerHowlCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 196567 then--Stealth (boss retreat)
		--Stop all timers but not combat
		for i, v in ipairs(self.timers) do
			v:Stop()
		end
		--Artificially set no wipe to 10 minutes
		self:SetWipeTime(600)
		--Scan for Boss to be re-enraged
		self:RegisterShortTermEvents(
			"ENCOUNTER_START",
			"ZONE_CHANGED_NEW_AREA"
		)
	elseif spellId == 196512 then
		warnClawFrenzy:Show()
		timerClawFrenzyCD:Start()
	elseif spellId == 207707 and self:AntiSpam(2, 1) then--Wolves spawning out of stealth
		specWarnWolves:Show()
		--timerWolvesCD:Start()
	end
end

function mod:ENCOUNTER_START(encounterID)
	--Re-engaged, kill scans and long wipe time
	if encounterID == 1807 and self:IsInCombat() then
--		self:SetWipeTime(5)
--		self:UnregisterShortTermEvents()
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		--timerWolvesCD:Start(4)
		timerHowlCD:Start(4)
		timerFixateCD:Start(22.8)
		timerClawFrenzyCD:Start(46)
		timerLeapCD:Start(14)
	end
end

function mod:UNIT_DIED(args)
	if self:GetCIDFromGUID(args.destGUID) == 99868 then
		DBM:EndCombat(self)
	end
end

function mod:ZONE_CHANGED_NEW_AREA()
	--Left zone
	--Normal wipes respawn you sindie
	self:SetWipeTime(5)
	self:UnregisterShortTermEvents()
end
