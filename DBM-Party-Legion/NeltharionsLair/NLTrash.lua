local mod	= DBM:NewMod("NLTrash", "DBM-Party-Legion", 5)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
--mod:SetModelID(47785)
mod:SetZone()

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 183088 193585 226296 202181",
	"SPELL_AURA_APPLIED 200154 201983 193585",
	"SPELL_PERIODIC_DAMAGE 226388 183407",
	"SPELL_PERIODIC_MISSED 226388 183407",
	"CHAT_MSG_MONSTER_YELL"
)
--TODO: maybe metamorphosis for grubs

local warnStoneGaze				= mod:NewTargetAnnounce(202181, 4)
local warnBurningHatred			= mod:NewTargetAnnounce(200154, 3)
local warnFrenzy				= mod:NewTargetAnnounce(201983, 4)
local warnBound					= mod:NewCastAnnounce(193585, 3)
local warnBound2				= mod:NewTargetAnnounce(193585, 4)
local warnPiercingShards		= mod:NewCastAnnounce(226296, 4)

local specWarnStoneGaze			= mod:NewSpecialWarningInterrupt(202181, "HasInterrupt", nil, nil, 1, 2)
local specWarnStoneGaze2		= mod:NewSpecialWarningYou(202181, nil, nil, nil, 2, 6)
local specWarnBound				= mod:NewSpecialWarningInterrupt(193585, "HasInterrupt", nil, nil, 1, 2)
local specWarnBurningHatred		= mod:NewSpecialWarningRun(200154, nil, nil, nil, 4, 2)
local specWarnAcidSplatter		= mod:NewSpecialWarningMove(183407, nil, nil, nil, 1, 2)
local specWarnRancidOoze		= mod:NewSpecialWarningMove(226388, nil, nil, nil, 1, 2)
local specWarnAvalanche			= mod:NewSpecialWarningDodge(183088, "Tank", nil, nil, 1, 2)
local specWarnPiercingShards	= mod:NewSpecialWarningSpell(226296, "Tank", nil, nil, 2, 2)

local timerFrenzy				= mod:NewTargetTimer(8, 201983, nil, "Tank", nil, 3, nil)

local timerRoleplay				= mod:NewTimer(23, "timerRoleplay", "Interface\\Icons\\Spell_Holy_BorrowedTime", nil, nil, 7)

local yellStoneGaze				= mod:NewYell(202181)

function mod:StoneGazeTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnStoneGaze2:Show()
		specWarnStoneGaze2:Play("targetyou")
		yellStoneGaze:Yell()
	else
		warnStoneGaze:CombinedShow(1, targetname)
	end
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 183088 and self:AntiSpam(2, 2) then
		specWarnAvalanche:Show()
		specWarnAvalanche:Play("shockwave")
	elseif spellId == 193585 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnBound:Show(args.sourceName)
			specWarnBound:Play("kickcast")
		else
			warnBound:Show()
			warnBound:Play("kickcast")
		end
	elseif spellId == 226296 then
		warnPiercingShards:Show()
		warnPiercingShards:Play("watchstep") --maybe change to frontal/stun
		specWarnPiercingShards:Show()
	elseif spellId == 202181 then
		self:BossTargetScanner(args.sourceGUID, "StoneGazeTarget", 0.1, 2)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnStoneGaze:Show()
			specWarnStoneGaze:Play("kickcast")
		end
	end
end

		
function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 200154 and self:AntiSpam(2.5, args.destName) then
		if args:IsPlayer() then
			specWarnBurningHatred:Show()
			specWarnBurningHatred:Play("targetyou")
		else
			warnBurningHatred:Show(args.destName)
		end
	elseif spellId == 201983 then
		warnFrenzy:Show(args.destName)
		timerFrenzy:Start(args.destName)
	elseif spellId == 193585 then
		warnBound2:CombinedShow(0.5, args.destName)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.RoleP1 then
		self:SendSync("RP1")
	end
end

function mod:OnSync(msg, GUID)
	if msg == "RP1" then
		timerRoleplay:Start(24)
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId)
	if spellId == 226388 and destGUID == UnitGUID("player") and self:AntiSpam(3, 1) then
		if not self:IsNormal() then
			specWarnRancidOoze:Show()
			specWarnRancidOoze:Play("runaway")
		end
	elseif spellId == 183407 and destGUID == UnitGUID("player") and self:AntiSpam(3, 1) then
		if not self:IsNormal() then
			specWarnAcidSplatter:Show()
			specWarnAcidSplatter:Play("runaway")
		end
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
