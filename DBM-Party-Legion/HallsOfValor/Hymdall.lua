local mod	= DBM:NewMod(1485, "DBM-Party-Legion", 4, 721)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17448 $"):sub(12, -3))
mod:SetCreatureID(94960)
mod:SetEncounterID(1805)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 191284 193235 188404 193092",
	"SPELL_PERIODIC_DAMAGE 193234",
	"SPELL_PERIODIC_MISSED 193234",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

local warnBreath					= mod:NewSpellAnnounce(188404, 3, nil, nil, nil, nil, nil, 2)
local warnDancingBlade				= mod:NewSpellAnnounce(193235, 3) --Make this NewTargetAnnounce if fixed
local warnSweep						= mod:NewSpellAnnounce(193092, 2, nil, "Melee")

local specWarnSweep					= mod:NewSpecialWarningDefensive(193092, nil, nil, nil, 3, 3)
local specWarnHornOfValor			= mod:NewSpecialWarningSoon(188404, nil, nil, nil, 2, 2)
local specWarnDancingBlade			= mod:NewSpecialWarningMove(193235, nil, nil, nil, 1, 2)
local specWarnDancingBlade2			= mod:NewSpecialWarningRun(193235, nil, nil, nil, 1, 3)
local yellDancingBlade				= mod:NewYell(193235)

local timerDancingBladeCD			= mod:NewCDTimer(10, 193235, nil, nil, nil, 3)
local timerHornCD					= mod:NewCDTimer(41.8, 191284, nil, nil, nil, 3)
local timerSweepCD					= mod:NewCDTimer(18, 193092, nil, "Melee", nil, 5, nil, DBM_CORE_TANK_ICON..DBM_CORE_DEADLY_ICON)

local yellDancingBlade				= mod:NewYell(193235, nil, nil, nil, "SAY")

local countdownHorn					= mod:NewCountdown(41.8, 191284, nil, nil, 5) 

mod.vb.bladeParity = false

function mod:OnCombatStart(delay)
	timerHornCD:Start(9.7-delay)
	countdownHorn:Start(9.7-delay)
	timerDancingBladeCD:Start(4.9-delay)
	timerSweepCD:Start(16-delay)
	self.vb.bladeParity = false
end

function mod:DancingBladeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnDancingBlade2:Show()
		specWarnDancingBlade2:Play("runout")
		yellDancingBlade:Yell()
	else
		--warnDancingBlade:Show(targetname)
	end
end

function mod:SweepTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnSweep:Show()
		specWarnSweep:Play("defensive")
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 191284 then
		specWarnHornOfValor:Show()
		specWarnHornOfValor:Play("breathsoon")
		timerHornCD:Start()
		countdownHorn:Start()
		timerDancingBladeCD:Start(26)
		self.vb.bladeParity = true
	elseif spellId == 193235 then
		self:BossTargetScanner(94960, "DancingBladeTarget", 0.1, 5, true, nil, nil, nil, true)
		if self.vb.bladeParity == true then
			timerDancingBladeCD:Start()
		else
			timerDancingBladeCD:Start(31)
		end
		self.vb.bladeParity = false
		warnDancingBlade:Show()
	elseif spellId == 188404 and self:AntiSpam(5, 2) then
		warnBreath:Show()
		warnBreath:Play("watchstep")
	elseif spellId == 193092 then
		warnSweep:Show()
		timerSweepCD:Start()
		self:BossTargetScanner(args.sourceGUID, "SweepTarget", 0.05, 2)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 193234 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		specWarnDancingBlade:Show()
		specWarnDancingBlade:Play("runaway")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

--[[function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, _, _, spellId)
	if spellId == 193092 then
		warnSweep:Show()
	end
end--]]
