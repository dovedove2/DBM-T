local mod	= DBM:NewMod("VoWTrash", "DBM-Party-Legion", 10)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
--mod:SetModelID(47785)
mod:SetZone()

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 196799 193069 196799 196249 193502 193936 161056 202728 196242 191527 191735 194064",
	"SPELL_AURA_APPLIED 202615 193069 193607 202608 161044 193164 210202 193997",
--	"SPELL_AURA_REMOVED",
	"SPELL_CAST_SUCCESS 202606",
	"CHAT_MSG_MONSTER_SAY",
	"GOSSIP_SHOW",
	"UNIT_DIED"
)

--TODO: meteor cast prediction once it's fixed

local warnTorment				= mod:NewTargetAnnounce(202615, 3)
local warnNightmares			= mod:NewTargetAnnounce(193069, 4)
local warnNightmares2			= mod:NewCastAnnounce(193069, 4)
local warnDoubleStrike			= mod:NewTargetAnnounce(193607, 2)
local warnMetamorphosis			= mod:NewSpellAnnounce(193502, 4)
--local warnAMotherLove			= mod:NewTargetAnnounce(194064, 3)
local warnPull					= mod:NewTargetAnnounce(193997, 3)

local specWarnPull				= mod:NewSpecialWarningYou(193997, nil, nil, nil, 4, 3)
--local specWarnAMotherLove		= mod:NewSpecialWarningMoveAway(194064, nil, nil, nil, 4, 3) --maybe add later
--local specWarnAMotherLove2		= mod:NewSpecialWarningTarget(194064, nil, nil, nil, 2, 2)
local specWarnDeafeningScreech	= mod:NewSpecialWarningDodge(191735, nil, nil, nil, 1, 2)
local specWarnFoulStench		= mod:NewSpecialWarningMove(210202, nil, nil, nil, 1, 2)
local specWarnDeafeningShout	= mod:NewSpecialWarningCast(191527, "SpellCaster", nil, nil, 1, 2)
local specWarnSummonGrimguard	= mod:NewSpecialWarningSwitch(202728, "Tank", nil, nil, 1, 2)
local specWarnTemporalAnomaly	= mod:NewSpecialWarningMove(161044, nil, nil, nil, 1, 2)
local specWarnArcaneSentries	= mod:NewSpecialWarningDodge(193936, nil, nil, nil, 2, 2)
local specWarnTemporalAnomaly2	= mod:NewSpecialWarningDodge(161056, nil, nil, nil, 2, 2)
local specWarnNightmares2		= mod:NewSpecialWarningDispel(193069, "MagicDispeller2", nil, nil, 1, 2)
local specWarnGiftoftheDoomsayer = mod:NewSpecialWarningDispel(193164, "MagicDispeller2", nil, nil, 1, 2)
local specWarnGiftoftheDoomsayer2 = mod:NewSpecialWarningYou(193164, false, nil, nil, 1, 2)
local specWarnAnguishedSouls	= mod:NewSpecialWarningMove(202608, nil, nil, nil, 1, 2)
local specWarnAnguishedSouls2	= mod:NewSpecialWarningDodge(202606, nil, nil, nil, 2, 2)
local specWarnTorment			= mod:NewSpecialWarningClose(202615, nil, nil, nil, 1, 2)
local specWarnTorment2			= mod:NewSpecialWarningDefensive(202615, nil, nil, nil, 2, 5)
local specWarnDoubleStrike		= mod:NewSpecialWarningDefensive(193607, false, nil, nil, 2, 2)
local specWarnUnleashedFury		= mod:NewSpecialWarningInterrupt(196799, "HasInterrupt", nil, nil, 2, 2)
local specWarnNightmares		= mod:NewSpecialWarningInterrupt(193069, "HasInterrupt", nil, nil, 3, 2)
local specWarnMeteor			= mod:NewSpecialWarningSoakPos(196249, nil, nil, nil, 1, 2)

local timerTemporalAnomalyCD	= mod:NewCDTimer(35, 161056, nil, nil, nil, 3, nil)
local timerArcaneSentriesCD		= mod:NewCDTimer(35, 193936, nil, nil, nil, 1, nil)

local timerMeteorCD				= mod:NewCDTimer(15, 196249, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerThunderclapCD		= mod:NewCDTimer(15, 196242, nil, nil, nil, 2, nil)

local timerDeafeningShoutCD		= mod:NewCDTimer(17, 191527, nil, "SpellCaster", nil, 4, nil, DBM_CORE_INTERRUPT_ICON)

local timerTormentCD			= mod:NewCDTimer(17, 202615, nil, nil, nil, 7, nil)

local timerDoubleStrikeCD		= mod:NewCDTimer(12, 193607, nil, "Tank", nil, 3, nil, DBM_CORE_TANK_ICON)
local timerDoubleStrike			= mod:NewTargetTimer(6, 193607, nil, false, nil, 3, nil)

local timerRoleplay				= mod:NewCombatTimer(26, nil, "Interface\\Icons\\Spell_Holy_BorrowedTime", nil, nil, 7)

local yellNightmares			= mod:NewYell(193069)
local yellTorment				= mod:NewYell(202615)
local yellAMotherLove			= mod:NewYell(194064)

--[[
function mod:AMotherLoveTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnAMotherLove:Show()
		specWarnAMotherLove:Play("runaway")
		yellAMotherLove:Yell()
	else
		warnAMotherLove:Show(targetname)
		specWarnAMotherLove2:Show(targetname)
		specWarnAMotherLove2:Play("runout")
	end
end
--]]

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 196799 and self:AntiSpam(3, 1) then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnUnleashedFury:Show(args.sourceName)
			specWarnUnleashedFury:Play("aesoon")
		else
			specWarnUnleashedFury:Show(args.sourceName)
			specWarnUnleashedFury:Play("aesoon")
		end
	elseif spellId == 193069 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnNightmares:Show(args.sourceName)
			specWarnNightmares:Play("kickcast")
		else
			warnNightmares2:Show()
			warnNightmares2:Play("kickcast")
		end
	elseif spellId == 196249 then
		specWarnMeteor:Show("circle")
		specWarnMeteor:Play("gathershare")
		timerMeteorCD:Start()
	elseif spellId == 193502 then
		warnMetamorphosis:Show()
	elseif spellId == 193936 then
		specWarnArcaneSentries:Show()
		timerArcaneSentriesCD:Start()
	elseif spellId == 161056 then
		specWarnTemporalAnomaly2:Show()
		timerTemporalAnomalyCD:Start()
	elseif spellId == 202728 then
		specWarnSummonGrimguard:Show()
	elseif spellId == 196242 then
		timerThunderclapCD:Start()
	elseif spellId == 191527 then
		specWarnDeafeningShout:Show()
		timerDeafeningShoutCD:Start()
	elseif spellId == 191735 then
		specWarnDeafeningScreech:Show()
		specWarnDeafeningScreech:Play("watchstep")
	--elseif spellId == 194064 then
		--self:BossTargetScanner(args.sourceGUID, "AMotherLoveTarget", 0.1, 2)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 202606 and self:AntiSpam(3, 1) then
		specWarnAnguishedSouls2:Show()
		specWarnAnguishedSouls2:Play("watchstep")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 202615 then
		warnTorment:Show(args.destName)
		timerTormentCD:Start()
		if args:IsPlayer() then
			specWarnTorment2:Show()
			yellTorment:Yell()
		else
			specWarnTorment:Show(args.destName)
		end
	elseif spellId == 193069 then
		warnNightmares:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			yellNightmares:Yell()
		else
			specWarnNightmares2:CombinedShow(0.3, args.destName)
			specWarnNightmares2:Play("dispelnow")
		end
	elseif spellId == 193607 then
		warnDoubleStrike:Show(args.destName)
		timerDoubleStrike:Start(args.destName)
		timerDoubleStrikeCD:Start()
		if args:IsPlayer() then
			specWarnDoubleStrike:Show()
			specWarnDoubleStrike:Play("defensive")
		end
	elseif spellId == 202608 then
		if args:IsPlayer() then
			specWarnAnguishedSouls:Show()
			specWarnAnguishedSouls:Play("runout")
		end
	elseif spellId == 161044 then
		if args:IsPlayer() then
			specWarnTemporalAnomaly:Show()
			specWarnTemporalAnomaly:Play("runout")
		end
	elseif spellId == 193164 then
		if args:IsPlayer() then
			specWarnGiftoftheDoomsayer2:Show()
			specWarnGiftoftheDoomsayer2:Play("targetyou")
		else
			specWarnGiftoftheDoomsayer:Show(args.destName)
			specWarnGiftoftheDoomsayer:Play("dispelnow")
		end
	elseif spellId == 210202 then
		if args:IsPlayer() then
			specWarnFoulStench:Show()
			specWarnFoulStench:Play("runout")
		end
	elseif spellId == 193997 then
		warnPull:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			specWarnPull:Show()
			specWarnPull:Play("justrun")
		end
	end
end

function mod:CHAT_MSG_MONSTER_SAY(msg)
	if msg == L.proshlyapMurchalRP then
		self:SendSync("Roleplay")
	end
end

function mod:OnSync(msg)
	if msg == "Roleplay" then
		timerRoleplay:Start()
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 102566 then
		timerTormentCD:Cancel()
	elseif cid == 96579 then
		timerTemporalAnomalyCD:Cancel()
		timerArcaneSentriesCD:Cancel()
	elseif cid == 99649 then
		timerMeteorCD:Cancel()
		timerThunderclapCD:Cancel()
	elseif cid == 96657 then
		timerDeafeningShoutCD:Cancel()
	end
end

function mod:GOSSIP_SHOW()
	local guid = UnitGUID("target")
	if not guid then return end
	local cid = self:GetCIDFromGUID(guid)
	if cid == 103860 then
		if select('#', GetGossipOptions()) > 0 then
			SelectGossipOption(1, "", true)
			CloseGossip()
		end
	end
end