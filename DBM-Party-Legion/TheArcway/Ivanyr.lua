local mod	= DBM:NewMod(1497, "DBM-Party-Legion", 6, 726)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17650 $"):sub(12, -3))
mod:SetCreatureID(98203)
mod:SetEncounterID(1827)
mod:SetZone()
mod:SetUsedIcons(8, 7, 6)

mod.noNormal = true

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 196562 196805 196396",
	"SPELL_AURA_APPLIED_DOSE 196396",
	"SPELL_AURA_REMOVED 196562",
	"SPELL_CAST_SUCCESS 196562 196804 196392",
	"SPELL_PERIODIC_DAMAGE 196824",
	"SPELL_PERIODIC_MISSED 196824"
)


local warnOvercharge				= mod:NewStackAnnounce(196396, 4, nil, nil, 2)
local warnOverchargeMana			= mod:NewSoonAnnounce(196392, 1)
local warnVolatileMagic				= mod:NewTargetAnnounce(196562, 3)
local warnNetherLink				= mod:NewTargetAnnounce(196805, 4)

local specWarnVolatileMagic			= mod:NewSpecialWarningMoveAway(196562, nil, nil, nil, 4, 6)
local specWarnVolatileMagic2		= mod:NewSpecialWarningClose(196562, nil, nil, nil, 2, 2)

local specWarnNetherLink			= mod:NewSpecialWarningYou(196805, nil, nil, nil, 1, 2)
local specWarnNetherLinkGTFO		= mod:NewSpecialWarningMove(196805, nil, nil, nil, 1, 2)
local specWarnOverchargeMana		= mod:NewSpecialWarningInterrupt(196392, "HasInterrupt", nil, nil, 3, 2)

local timerVolatileMagicCD			= mod:NewCDTimer(32, 196562, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerNetherLinkCD				= mod:NewCDTimer(30, 196804, nil, nil, nil, 3)
local timerOverchargeManaCD			= mod:NewCDTimer(40, 196392, nil, nil, nil, 4, nil, DBM_CORE_INTERRUPT_ICON)

local yellVolatileMagic				= mod:NewYell(196562)
--local yellVolatileMagic2			= mod:NewShortFadesYell(196562)
local yellNetherLink				= mod:NewYell(196805)

local countdownOverchargeMana		= mod:NewCountdown(40, 196392, nil, nil, 5)

mod:AddSetIconOption("SetIconOnVolatileMagic", 196562, true, false, {8, 7, 6})
mod:AddRangeFrameOption(8, 196562)

mod.vb.volatilemagicIcon = 8

function mod:OnCombatStart(delay)
	self.vb.volatilemagicIcon = 8
	timerVolatileMagicCD:Start(8.5-delay)--APPLIED
	timerNetherLinkCD:Start(17.5-delay)--APPLIED
	warnOverchargeMana:Schedule(27-delay)
	timerOverchargeManaCD:Start(32-delay)
	countdownOverchargeMana:Start(32-delay)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 196562 then
		self.vb.volatilemagicIcon = self.vb.volatilemagicIcon - 1
		warnVolatileMagic:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnVolatileMagic:Show()
			specWarnVolatileMagic:Play("runout")
			yellVolatileMagic:Yell()
			--yellVolatileMagic2:Countdown(4)
		elseif self:CheckNearby(10, args.destName) then
			specWarnVolatileMagic2:CombinedShow(0.3, args.destName)
			specWarnVolatileMagic2:Play("runout")
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(8)
		end
		if self.Options.SetIconOnVolatileMagic then
			self:SetIcon(args.destName, self.vb.volatilemagicIcon)
		end
	elseif spellId == 196805 then
		warnNetherLink:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnNetherLink:Show()
			specWarnNetherLink:Play("targetyou")
			yellNetherLink:Yell()
		end
	elseif spellId == 196396 then
		local amount = args.amount or 1
		if amount >= 5 and amount % 5 == 0 then
			warnOvercharge:Show(args.destName, amount)
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 196562 then
		self.vb.volatilemagicIcon = self.vb.volatilemagicIcon + 1
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
		if self.Options.SetIconOnVolatileMagic then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 196562 then
		timerVolatileMagicCD:Start()
	elseif spellId == 196804 then
		timerNetherLinkCD:Start()
	elseif spellId == 196392 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnOverchargeMana:Show(args.sourceName)
			specWarnOverchargeMana:Play("kickcast")
		end
		timerOverchargeManaCD:Start()
		countdownOverchargeMana:Start()
		warnOverchargeMana:Schedule(35)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 196824 and destGUID == UnitGUID("player") and self:AntiSpam(2, 1) then
		if not self:IsNormal() then
			specWarnNetherLinkGTFO:Show()
			specWarnNetherLinkGTFO:Play("runaway")
		end
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE