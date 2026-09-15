local mod	= DBM:NewMod(1468, "DBM-Party-Legion", 10, 707)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
mod:SetCreatureID(95886)
mod:SetEncounterID(1816)
mod:SetZone()
mod:SetUsedIcons(8, 7, 6, 5, 4)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 192522 192631 192621 195187",
	"SPELL_AURA_APPLIED 192517 192519 215478",
	"SPELL_AURA_APPLIED_DOSE 192519",
	"SPELL_AURA_REMOVED 192517 192519",
	"CHAT_MSG_MONSTER_EMOTE"
)


local warnFiredUp2					= mod:NewTargetAnnounce(215478, 4)
local warnVolcano					= mod:NewSpellAnnounce(192621, 3, nil, nil, nil, nil, nil, 2)
local warnFiredUp					= mod:NewCastAnnounce(195187, 4)
local warnCountermeasure			= mod:NewSoonAnnounce(195189, 2, 235297)
--local warnCountermeasure2			= mod:NewAnnounce("Countermeasure", 2, 235297)

local specWarnProshlyap				= mod:NewSpecialWarningSpell(195189, nil, nil, nil, 1, 3)
local specWarnFiredUp2				= mod:NewSpecialWarningYou(215478, nil, nil, nil, 3, 5)
local specWarnFiredUp				= mod:NewSpecialWarningDefensive(195187, nil, nil, nil, 2, 6) --Detonate
local specWarnLava					= mod:NewSpecialWarningStack(192519, nil, 2, nil, nil, 1, 2)
local specWarnBrittle				= mod:NewSpecialWarningSpell(192517, nil, nil, nil, 1, 2)
local specWarnLavaWreath			= mod:NewSpecialWarningDodge(192631, nil, nil, nil, 2, 2)
local specWarnFissure				= mod:NewSpecialWarningSpell(192522, "Tank", nil, nil, 1, 2)

local timerFiredUp					= mod:NewCastTimer(5, 195187, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerBrittle					= mod:NewBuffActiveTimer(20, 192517, nil, nil, nil, 6, nil, DBM_CORE_DAMAGE_ICON)
local timerVolcanoCD				= mod:NewCDTimer(20, 192621, nil, nil, nil, 1)
local timerLavaWreathCD				= mod:NewCDTimer(42, 192631, nil, nil, nil, 2)
local timerFissureCD				= mod:NewCDTimer(42, 192522, nil, nil, nil, 5, nil, DBM_CORE_TANK_ICON)
local timerCountermeasureCD			= mod:NewCDTimer(75, 195189, nil, nil, nil, 7, 235297)

local countdownCountermeasure		= mod:NewCountdown(75, 195189, nil, nil, 5)
local countdownBrittle				= mod:NewCountdownFades("Alt20", 192517, nil, nil, 5)

local yellFiredUp					= mod:NewYell(215478)

mod:AddSetIconOption("SetIconOnFiredUp", 215478, true, false, {8, 7, 6, 5, 4})

mod.vb.countermeasure = 0
mod.vb.firedupIcon = 8

function mod:OnCombatStart(delay)
	self.vb.countermeasure = 0
	self.vb.firedupIcon = 8
	timerVolcanoCD:Start(10-delay)
	timerLavaWreathCD:Start(25-delay)
	timerFissureCD:Start(42-delay)
	timerCountermeasureCD:Start(6-delay)
	warnCountermeasure:Schedule(1-delay)
	countdownCountermeasure:Start(6-delay)

end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 192522 then
		specWarnFissure:Show()
		specWarnFissure:Play("shockwave")
		timerFissureCD:Start()
	elseif spellId == 192631 then
		if not UnitIsDeadOrGhost("player") then
			specWarnLavaWreath:Show()
			specWarnLavaWreath:Play("watchstep")
		end
		timerLavaWreathCD:Start()
	elseif spellId == 192621 then
		warnVolcano:Show()
		warnVolcano:Play("mobsoon")
		timerVolcanoCD:Start()
	elseif spellId == 195187 and self:AntiSpam(3, 1) then
		warnFiredUp:Show()
		if not UnitIsDeadOrGhost("player") then
			specWarnFiredUp:Schedule(2)
			specWarnFiredUp:ScheduleVoice(2, "defensive")
		end
		timerFiredUp:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 192517 and args:GetSrcCreatureID() == 95886 then
		self.vb.countermeasure = self.vb.countermeasure + 1
		if not UnitIsDeadOrGhost("player") then
			specWarnBrittle:Show(args.destName)
		end
		timerLavaWreathCD:Start(timerLavaWreathCD:GetRemaining()+20)
		timerFissureCD:Start(timerFissureCD:GetRemaining()+20)
		timerVolcanoCD:Start(timerVolcanoCD:GetRemaining()+20)
		timerFiredUp:Stop()
		specWarnFiredUp:Cancel()
		specWarnFiredUp:CancelVoice()
		timerBrittle:Start()
		countdownBrittle:Start()
		if self.vb.countermeasure >= 1 then
			warnCountermeasure:Schedule(70)
			timerCountermeasureCD:Start()
			countdownCountermeasure:Start()
		end
	elseif spellId == 192519 then
		local amount = args.amount or 1
		if not self:IsNormal() then
			if args:IsPlayer() then
				if amount >= 2 then
					specWarnLava:Show(amount)
					specWarnLava:Play("stackhigh")
				end
			end
		end
	elseif spellId == 215478 then
		self.vb.firedupIcon = self.vb.firedupIcon - 1
		warnFiredUp2:CombinedShow(1, args.destName)
		if args:IsPlayer() then
			specWarnFiredUp2:Show()
			specWarnFiredUp2:Play("defensive")
			yellFiredUp:Yell()
		end
		if self.Options.SetIconOnFiredUp then
			self:SetIcon(args.destName, self.vb.firedupIcon)
		end
		if self.vb.firedupIcon == 4 then
			self.vb.firedupIcon = 8
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg:find(L.MurchalProshlyapOchko) or msg == L.MurchalProshlyapOchko then
	--	warnCountermeasure2:Show()
		specWarnProshlyap:Show()
		timerCountermeasureCD:Cancel()
		countdownCountermeasure:Cancel()
	end
end