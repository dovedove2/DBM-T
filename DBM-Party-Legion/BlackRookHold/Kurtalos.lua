local mod	= DBM:NewMod(1672, "DBM-Party-Legion", 1, 740)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
mod:SetCreatureID(98965, 98970)
mod:SetEncounterID(1835)
mod:SetZone()
mod:SetUsedIcons(8)
mod:SetBossHPInfoToHighest()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 198820 199143 199193 202019 198641 201733",
	"SPELL_CAST_SUCCESS 198635 201733",
	"SPELL_AURA_APPLIED 201733 199368",
	"SPELL_AURA_REMOVED 199193 201733",
	"CHAT_MSG_MONSTER_SAY",
	"UNIT_HEALTH",
	"UNIT_DIED"
)

--TODO
local warnPhase						= mod:NewPhaseChangeAnnounce(1) 
local warnPhase2					= mod:NewPrePhaseAnnounce(2, 1) 
local warnCloud						= mod:NewSpellAnnounce(199143, 2)
local warnSwarm						= mod:NewTargetAnnounce(201733, 2)
local warnWhirlingBlade				= mod:NewTargetAnnounce(198641, 3)
local warnGuile						= mod:NewPreWarnAnnounce(199193, 5, 1)
local warnShadowBoltVolley			= mod:NewPreWarnAnnounce(202019, 5, 1)
--local warnLegacyRavencrest			= mod:NewPreWarnAnnounce(199368, 5, 1)
 
local specWarnWhirlingBlade			= mod:NewSpecialWarningTarget(198641, nil, nil, nil, 2, 3)
local specWarnWhirlingBlade2		= mod:NewSpecialWarningYou(198641, nil, nil, nil, 4, 3)
local specWarnDarkblast				= mod:NewSpecialWarningDodge(198820, nil, nil, nil, 2)
local specWarnGuile					= mod:NewSpecialWarningDodge(199193, nil, nil, nil, 2, 2)
local specWarnGuileEnded			= mod:NewSpecialWarningEnd(199193, nil, nil, nil, 1, 2)
local specWarnSwarm					= mod:NewSpecialWarningYou(201733)
local specWarnSwarm2				= mod:NewSpecialWarningSwitch(201733, "-Healer", nil, nil, 1, 2)
local specWarnShadowBolt			= mod:NewSpecialWarningDefensive(202019, nil, nil, nil, 3, 2)
local specWarnLegacyRavencrest		= mod:NewSpecialWarningYou(199368, nil, nil, nil, 1, 2)
 
local timerDarkBlastCD				= mod:NewCDTimer(14, 198820, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerUnerringShearCD			= mod:NewCDTimer(12, 198635, nil, "Tank", nil, 5, nil, DBM_CORE_TANK_ICON)
local timerGuileCD					= mod:NewCDCountTimer(84, 199193, nil, nil, nil, 6, nil, DBM_CORE_DEADLY_ICON)
local timerGuile					= mod:NewBuffFadesTimer(25, 199193, nil, nil, nil, 6, nil, DBM_CORE_MYTHIC_ICON)
local timerCloudCD					= mod:NewCDTimer(28.8, 199143, nil, nil, nil, 3, nil, DBM_CORE_MAGIC_ICON)
local timerSwarmCD					= mod:NewCDTimer(15, 201733, nil, nil, nil, 3)
local timerShadowBoltVolleyCD		= mod:NewCDTimer(8, 202019, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerLegacyRavencrestCD		= mod:NewCDTimer(23.3, 199368, nil, nil, nil, 7)
local timerWhirlingBladeCD			= mod:NewCDTimer(23, 198641, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
 
local yellWhirlingBlade				= mod:NewYell(198641)
local yellSwarm						= mod:NewYell(201733)
 
local countdownDarkblast			= mod:NewCountdown(18, 198820, nil, nil, 5)
local countdownShear				= mod:NewCountdown(12, 198635, "Tank")
local countdownGuile				= mod:NewCountdown(84, 199193, nil, nil, 5)
local countdownGuile2				= mod:NewCountdownFades("Alt25", 199193, nil, nil, 5)
 
mod:AddSetIconOption("SetIconOnWhirlingBlade", 198641, true, false, {8})
mod:AddSetIconOption("SetIconOnSwarm", 201733, true, false, {8})
 
mod.vb.phase = 1 
mod.vb.shadowboltCount = 0 
mod.vb.guileCount = 0 
 
local warned_preP1 = false 
 
function mod:WhirlingBladeTarget(targetname, uId)
	if not targetname then return end 
	if targetname == UnitName("player") then 
		specWarnWhirlingBlade2:Show() 
		specWarnWhirlingBlade2:Play("runout") 
		yellWhirlingBlade:Yell() 
	elseif self:CheckNearby(40, targetname) then 
		specWarnWhirlingBlade:Show(targetname) 
		specWarnWhirlingBlade:Play("watchstep") 
	else 
		warnWhirlingBlade:Show(targetname) 
	end 
	if self.Options.SetIconOnWhirlingBlade then 
		self:SetIcon(targetname, 8, 10) 
	end 
end 
 
function mod:SwarmTarget(targetname, uId)
	if not targetname then return end 
	if targetname == UnitName("player") then 
		specWarnSwarm:Show() 
		specWarnSwarm:Play("targetyou") 
		yellSwarm:Yell() 
	elseif self:CheckNearby(20, targetname) then 
		specWarnSwarm2:Schedule(1.5) 
		specWarnSwarm2:ScheduleVoice(1.5, "mobkill") 
	else 
		warnSwarm:Show(targetname) 
	end 
end 
 
function mod:OnCombatStart(delay) 
	self.vb.phase = 1 
	self.vb.shadowboltCount = 0 
	self.vb.guileCount = 0 
	warned_preP1 = false 
	timerUnerringShearCD:Start(5.5-delay)
	countdownShear:Start(5.5-delay)
	timerDarkBlastCD:Start(9.5-delay)
	countdownDarkblast:Start(9.5-delay)
	timerWhirlingBladeCD:Start(13-delay)

end 
 
function mod:SPELL_CAST_START(args) 
	local spellId = args.spellId 
	if spellId == 198820 and self:AntiSpam(3, 2) then 
		if self.vb.phase == 1 then 
			if not UnitIsDeadOrGhost("player") then 
				specWarnDarkblast:Show() 
				specWarnDarkblast:Play("watchstep") 
			end 
			timerDarkBlastCD:Start() 
			countdownDarkblast:Start() 
		end 
	elseif spellId == 199143 then 
		warnCloud:Show() 
		timerCloudCD:Start() 
	elseif spellId == 199193 then
		self.vb.guileCount = self.vb.guileCount + 1 
		timerCloudCD:Stop() 
		timerSwarmCD:Stop() 
		timerShadowBoltVolleyCD:Stop() 
		if not UnitIsDeadOrGhost("player") then 
			specWarnGuile:Show() 
			specWarnGuile:Play("watchstep") 
			specWarnGuile:ScheduleVoice(1.5, "keepmove") 
		end 
		--specWarnGuileEnded:Schedule(20) 
		timerGuile:Start() 
		countdownGuile2:Start() 
		timerGuileCD:Start(nil, self.vb.guileCount+1) 
		countdownGuile:Start() 
		warnGuile:Schedule(79) 
		timerCloudCD:Start(28)
		timerSwarmCD:Start(36) 
		--[[if self.vb.guileCount == 1 then 
		elseif self.vb.guileCount == 2 then 
			timerSwarmCD:Start(27.5) 
			timerCloudCD:Start(32.5) 
		end--]]
	elseif spellId == 202019 then 
		self.vb.shadowboltCount = self.vb.shadowboltCount + 1 
		if self.vb.shadowboltCount == 1 then 
			if not UnitIsDeadOrGhost("player") then 
				specWarnShadowBolt:Show() 
				specWarnShadowBolt:Play("defensive") 
			end 
		end 
	elseif spellId == 198641 then
		self:BossTargetScanner(args.sourceGUID, "WhirlingBladeTarget", 0.1, 2) 
		timerWhirlingBladeCD:Start() 
	elseif spellId == 201733 then
		self:BossTargetScanner(args.sourceGUID, "SwarmTarget", 0.1, 2) 
	end 
end 
 
function mod:SPELL_CAST_SUCCESS(args) 
	local spellId = args.spellId 
	if spellId == 198635 then 
		timerUnerringShearCD:Start() 
		countdownShear:Start() 
	elseif spellId == 201733 then
		timerSwarmCD:Start() 
	end 
end 
 
function mod:SPELL_AURA_APPLIED(args) 
	local spellId = args.spellId 
	if spellId == 201733 then
		if self.Options.SetIconOnSwarm then 
			self:SetIcon(args.destName, 8) 
		end 
	elseif spellId == 199368 then
		
		timerLegacyRavencrestCD:Stop()
		if args:IsPlayer() then 
			specWarnLegacyRavencrest:Show() 
			specWarnLegacyRavencrest:Play("targetyou") 
		end 
	end 
end 
 
function mod:SPELL_AURA_REMOVED(args) 
	local spellId = args.spellId 
	if spellId == 199193 then 
		specWarnGuileEnded:Show() 
		specWarnGuileEnded:Play("safenow") 
		timerCloudCD:Start(3) 
		if not self:IsNormal() then 
			timerSwarmCD:Start(10.5) 
		end 
	elseif spellId == 201733 then
		if self.Options.SetIconOnSwarm then 
			self:SetIcon(args.destName, 0) 
		end 
	end 
end 
 
function mod:UNIT_DIED(args) 
	local cid = self:GetCIDFromGUID(args.destGUID) 
	if cid == 98965 then --phase 2 start
		if not self:IsNormal() then 
			timerSwarmCD:Start(23.5)
		end 
		--warnLegacyRavencrest:Schedule(18.5) 
		timerLegacyRavencrestCD:Start() 
		timerCloudCD:Start(28.2)
		countdownDarkblast:Start(19) 
		timerShadowBoltVolleyCD:Start(19.4) 
		warnShadowBoltVolley:Schedule(14.4) 
		timerGuileCD:Start(38.7, 1)
		warnGuile:Schedule(33.7) 
		countdownGuile:Start(38.7) 
	end 
end 
 
function mod:CHAT_MSG_MONSTER_SAY(msg)
	if msg == L.proshlyapMurchal then 
		self.vb.phase = 2 
		warnPhase:Show(DBM_CORE_AUTO_ANNOUNCE_TEXTS.stage:format(self.vb.phase)) 
		timerWhirlingBladeCD:Cancel() 
		countdownShear:Cancel() 
		timerDarkBlastCD:Cancel() 
		timerUnerringShearCD:Cancel() 
		countdownDarkblast:Cancel() 
	end 
end 
 
function mod:UNIT_HEALTH(uId) 
	if not self:IsNormal() then 
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 98965 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.31 then
			warned_preP1 = true 
			warnPhase2:Show(DBM_CORE_AUTO_ANNOUNCE_TEXTS.stage:format(self.vb.phase+1)) 
		end 
	else 
		if self.vb.phase == 1 and not warned_preP1 and self:GetUnitCreatureId(uId) == 98965 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.31 then
			warned_preP1 = true 
		end 
	end 
end