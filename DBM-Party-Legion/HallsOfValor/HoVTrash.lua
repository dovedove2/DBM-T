local mod	= DBM:NewMod("HoVTrash", "DBM-Party-Legion", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
--mod:SetModelID(47785)
mod:SetZone()

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 199805 192563 199726 200901 192158 192288 210875 199652 198931 198892 199210",
	"SPELL_CAST_SUCCESS 200901",
	"SPELL_AURA_APPLIED 198599 215430 199652",
	"SPELL_AURA_APPLIED_DOSE 199652",
	"SPELL_AURA_REMOVED 198599 215430 199652",
	"GOSSIP_SHOW",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED"
)

--Todo: add Fenryr prediction (left/right)

local warnThunderstrike				= mod:NewTargetAnnounce(215430, 4)
local warnCrackle					= mod:NewTargetAnnounce(199805, 2)
local warnChargedPulse				= mod:NewCastAnnounce(210875, 4)
local warnHealingLight				= mod:NewCastAnnounce(198931, 3)
--local warnPenetratingShot			= mod:NewCastAnnounce(199210, 3)

--local specWarnPenetratingShot		= mod:NewSpecialWarningDodge(199210, false, nil, nil, 3, 3)
local specWarnThunderstrike			= mod:NewSpecialWarningMoveAway(215430, nil, nil, nil, 1, 5)
local specWarnCracklingStorm		= mod:NewSpecialWarningYou(198892, nil, nil, nil, 4, 3)
local specWarnHealingLight			= mod:NewSpecialWarningInterrupt(198931, "HasInterrupt", nil, nil, 1, 2)
local specWarnCrackle				= mod:NewSpecialWarningDodge(199805, nil, nil, nil, 1, 2)
local specWarnSever					= mod:NewSpecialWarningDefensive(199652, "Tank", nil, nil, 3, 5)
local specWarnSever2				= mod:NewSpecialWarningStack(199652, nil, 2, nil, nil, 2, 2)
local specWarnCleansingFlame		= mod:NewSpecialWarningInterrupt(192563, "HasInterrupt", nil, nil, 1, 2)
local specWarnUnrulyYell			= mod:NewSpecialWarningInterrupt(199726, "HasInterrupt", nil, nil, 1, 2)
local specWarnSearingLight			= mod:NewSpecialWarningInterrupt(192288, "HasInterrupt", nil, nil, 1, 2)
local specWarnEyeofStorm			= mod:NewSpecialWarningMoveTo(200901, nil, nil, nil, 4, 3)
local specWarnEyeofStorm2			= mod:NewSpecialWarningDefensive(200901, false, nil, nil, 2, 3)
local specWarnSanctify				= mod:NewSpecialWarningDodge(192158, "Ranged", nil, nil, 2, 5)
local specWarnSanctify2				= mod:NewSpecialWarningRun(192158, "Melee", nil, nil, 4, 5)
local specWarnChargedPulse			= mod:NewSpecialWarningRun(210875, "Melee", nil, nil, 4, 5)
local specWarnChargedPulse2			= mod:NewSpecialWarningDodge(210875, "Ranged", nil, nil, 2, 5)

local timerSever					= mod:NewTargetTimer(12, 199652, nil, "Tank|Healer", nil, 3, nil, DBM_CORE_TANK_ICON)
local timerThunderstrike			= mod:NewTargetTimer(3, 215430, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)

--Olmyr the Enlightened
local timerSearingLightCD			= mod:NewCDTimer(8, 192288, nil, "HasInterrupt", nil, 4, nil, DBM_CORE_INTERRUPT_ICON)
local timerSanctifyCD				= mod:NewCDTimer(30, 192158, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local countdownSanctify				= mod:NewCountdown("Alt30", 192158, nil, nil, 3)
--Solsten
local timerEyeofStormCD				= mod:NewCDTimer(30, 200901, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local countdownEyeofStorm			= mod:NewCountdown(30, 200901, nil, nil, 3)


local timerRoleplay					= mod:NewCombatTimer(10)

local yellCrackle					= mod:NewYell(199805)
local yellThunderstrike				= mod:NewYell(215430, nil, nil, nil, "SAY")
local yellCracklingStorm			= mod:NewYell(198892, nil, nil, nil, "SAY")

local eyeShortName = DBM:GetSpellInfo(91320)--Inner Eye

mod:AddBoolOption("BossActivation", true)
mod:AddRangeFrameOption(8, 215430)

function mod:CrackleTarget(targetname, uId)
	if not targetname then
		warnCrackle:Show(DBM_CORE_UNKNOWN)
		return
	end
	if targetname == UnitName("player") then
		specWarnCrackle:Show()
		specWarnCrackle:Play("watchstep")
		yellCrackle:Yell()
	else
		warnCrackle:Show(targetname)
	end
end

function mod:CracklingStormTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnCracklingStorm:Show()
		specWarnCracklingStorm:Play("runaway")
		yellCracklingStorm:Yell()
	end
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 199805 then
		self:BossTargetScanner(args.sourceGUID, "CrackleTarget", 0.1, 4)
	elseif spellId == 192563 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnCleansingFlame:Show(args.sourceName)
		specWarnCleansingFlame:Play("kickcast")
	elseif spellId == 199726 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnUnrulyYell:Show(args.sourceName)
		specWarnUnrulyYell:Play("kickcast")
	--elseif spellId == 199210 and self:AntiSpam(2, 3) then
		--warnPenetratingShot:Show()
		--specWarnPenetratingShot:Show()
		--specWarnPenetratingShot:Play("stilldanger")
	elseif spellId == 192288 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnSearingLight:Show(args.sourceName)
			specWarnSearingLight:Play("kickcast")
		end
		timerSearingLightCD:Start()
	elseif spellId == 200901 then
		if not UnitIsDeadOrGhost("player") then
			specWarnEyeofStorm:Show(eyeShortName)
			specWarnEyeofStorm:Play("findshelter")
		end
		timerEyeofStormCD:Start()
		countdownEyeofStorm:Start()
	elseif spellId == 192158 then
		if not UnitIsDeadOrGhost("player") then
			specWarnSanctify2:Show()
			specWarnSanctify2:Play("watchorb")
			specWarnSanctify:Show()
			specWarnSanctify:Play("watchorb")
		end
		timerSanctifyCD:Start()
		countdownSanctify:Start()
	elseif spellId == 210875 and self:AntiSpam(2, 1) then
		warnChargedPulse:Show()
		specWarnChargedPulse:Show()
		specWarnChargedPulse:Play("justrun")
		specWarnChargedPulse2:Show()
		specWarnChargedPulse2:Play("watchstep")
	elseif spellId == 199652 and self:AntiSpam(2, 2) then
		specWarnSever:Show()
		specWarnSever:Play("defensive")
	elseif spellId == 198931 and self:AntiSpam(2, 4) then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnHealingLight:Show(args.sourceName)
			specWarnHealingLight:Play("kickcast")
		else
			warnHealingLight:Show()
			warnHealingLight:Play("kickcast")
		end
	elseif spellId == 198892 then
		self:BossTargetScanner(args.sourceGUID, "CracklingStormTarget", 0.1, 2)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 200901 then
		if not UnitIsDeadOrGhost("player") then
			specWarnEyeofStorm2:Show()
			specWarnEyeofStorm2:Play("defensive")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if args.spellId == 215430 or args.spellId == 198599 then
		warnThunderstrike:CombinedShow(0.5, args.destName)
		timerThunderstrike:Start(args.destName)
		if not self:IsNormal() then
			if args:IsPlayer() then
				specWarnThunderstrike:Show()
				specWarnThunderstrike:Play("runout")
				yellThunderstrike:Yell()
			end
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(8)
		end
	elseif spellId == 199652 then
		local amount = args.amount or 1
		if args:IsPlayer() then
			if amount >= 2 then
				specWarnSever2:Show(amount)
				specWarnSever2:Play("stackhigh")
			end
		end
		timerSever:Start(args.destName)
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 215430 or 198599 then
		timerThunderstrike:Cancel(args.destName)
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
	elseif spellId == 199652 then
		timerSever:Cancel(args.destName)
	end
end

function mod:GOSSIP_SHOW()
	local guid = UnitGUID("npc")
	if not guid then return end
	local cid = self:GetCIDFromGUID(guid)
	if mod.Options.BossActivation then
		if cid == 97081 or cid == 95843 or cid == 97083 or cid == 97084 then
			if select('#', GetGossipOptions()) > 0 then
				SelectGossipOption(1)
				CloseGossip()
			end
		elseif cid == 95676 then
			if select('#', GetGossipOptions()) > 0 then
				SelectGossipOption(1, "", true)
				--self:SendSync("RPOdyn2")
			end
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.RPSkovald then
		timerRoleplay:Start(35.5)
	elseif msg == L.RPOdyn then
		timerRoleplay:Start(24.3)
	elseif msg == L.RPSolsten then
		timerEyeofStormCD:Start(10)
		countdownEyeofStorm:Start(10)
	elseif msg == L.RPSolsten2 then
		timerEyeofStormCD:Cancel()
		countdownEyeofStorm:Cancel()
	elseif msg == L.RPOlmyr then
		timerSanctifyCD:Start(9.9)
		countdownSanctify:Start(9.9)
		timerSearingLightCD:Start(4.9)
	elseif msg == L.RPOlmyr2 then
		timerSanctifyCD:Cancel()
		countdownSanctify:Cancel()
		timerSearingLightCD:Cancel()
	end
end

function mod:OnSync(msg)
	if msg == "RPOdyn2" then
		--timerRoleplay:Start(2.8)
		--countdownEyeofStorm:Start(2.8)
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 97219 then 
		timerEyeofStormCD:Cancel()
		countdownEyeofStorm:Stop()
	end
	if cid == 97202 then 
		timerSearingLightCD:Cancel()
		timerSanctifyCD:Cancel()
		countdownSanctify:Stop()
	end
end