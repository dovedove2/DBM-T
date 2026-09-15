local mod	= DBM:NewMod("CoSTrash", "DBM-Party-Legion", 7)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17650 $"):sub(12, -3))
mod:SetZone()
mod:SetOOCBWComms()

mod.isTrashMod = true

mod:RegisterEvents(
	"SPELL_CAST_START 209027 212031 209485 209410 209413 211470 211464 209404 209495 225100 211299 209378 207980 207979 214692 214688 214690 212773 210253",
	"SPELL_CAST_SUCCESS 214688 208585 208427 209767 208334 210872 210307 208939 208370 210925 210217 210922 210330 210253",
	"SPELL_AURA_APPLIED 209033 209512 207981 214690 212773",
	"SPELL_AURA_REMOVED 214690",
	"CHAT_MSG_MONSTER_SAY",
	"GOSSIP_SHOW",
	"UNIT_DIED"
)

local warnPhase2					= mod:NewAnnounce("warnSpy", 1, 248732)
local warnDrainMagic				= mod:NewCastAnnounce(209485, 4)
local warnCripple					= mod:NewTargetAnnounce(214690, 3)
local warnCarrionSwarm				= mod:NewTargetAnnounce(214688, 4)
local warnShadowBoltVolley			= mod:NewCastAnnounce(214692, 4)
local warnFelDetonation				= mod:NewCastAnnounce(211464, 4)
local warnSubdue					= mod:NewTargetAnnounce(212773, 4)
local warnSuppress					= mod:NewTargetAnnounce(209413, 4)
local warnDisintegrationBeam		= mod:NewTargetAnnounce(207980, 4)
local warnSubdue2					= mod:NewCastAnnounce(212773, 3)
local warnDisableBeacon				= mod:NewSpellAnnounce(210253, 1)
local warnEating					= mod:NewSpellAnnounce(208585, 1)
local warnSiphoningMagic			= mod:NewSpellAnnounce(208427, 1)
local warnPurifying					= mod:NewSpellAnnounce(209767, 1)
local warnDraining					= mod:NewSpellAnnounce(208334, 1)
local warnInvokingText				= mod:NewSpellAnnounce(210872, 1)
local warnDrinking					= mod:NewSpellAnnounce(210307, 1)
local warnReleaseSpores				= mod:NewSpellAnnounce(208939, 1)
local warnShuttingDown				= mod:NewSpellAnnounce(208370, 1)
local warnTreating					= mod:NewSpellAnnounce(210925, 1)
local warnPilfering					= mod:NewSpellAnnounce(210217, 1)
local warnDefacing					= mod:NewSpellAnnounce(210330, 1)
local warnTinkering					= mod:NewSpellAnnounce(210922, 1)

--local specWarnSuppress2				= mod:NewSpecialWarningYou(209413, nil, nil, nil, 1, 2)
local specWarnCripple2				= mod:NewSpecialWarningYou(214690, nil, nil, nil, 1, 3)
local specWarnCripple				= mod:NewSpecialWarningDispel(214690, "MagicDispeller2", nil, nil, 1, 2)
local specWarnShadowBoltVolley		= mod:NewSpecialWarningDodge(214692, "-Tank", nil, nil, 2, 3)
local specWarnCarrionSwarm			= mod:NewSpecialWarningDodge(214688, nil, nil, nil, 2, 2)
local specWarnFelDetonation			= mod:NewSpecialWarningDodge(211464, nil, nil, nil, 2, 3)
local specWarnDisintegrationBeam	= mod:NewSpecialWarningYou(207980, nil, nil, nil, 1, 6)
local specWarnShockwave				= mod:NewSpecialWarningDodge(207979, "Melee", nil, nil, 2, 3)
local specWarnFortification			= mod:NewSpecialWarningDispel(209033, "MagicDispeller", nil, nil, 1, 2)
local specWarnQuellingStrike		= mod:NewSpecialWarningDodge(209027, "Melee", nil, nil, 2, 2)
local specWarnChargedBlast			= mod:NewSpecialWarningDodge(212031, "Melee", nil, nil, 2, 2)
local specWarnChargedSmash			= mod:NewSpecialWarningDodge(209495, "Melee", nil, nil, 2, 2)
local specWarnDrainMagic			= mod:NewSpecialWarningInterrupt(209485, "HasInterrupt", nil, nil, 3, 5)
local specWarnSubdue				= mod:NewSpecialWarningInterrupt(212773, "HasInterrupt", nil, nil, 1, 3)
local specWarnSubdue2				= mod:NewSpecialWarningDispel(212773, "MagicDispeller2", nil, nil, 1, 2)
local specWarnNightfallOrb			= mod:NewSpecialWarningInterrupt(209410, "HasInterrupt", nil, nil, 1, 2)
local specWarnSuppress				= mod:NewSpecialWarningInterrupt(209413, "HasInterrupt", nil, nil, 1, 2)
local specWarnBewitch				= mod:NewSpecialWarningInterrupt(211470, "HasInterrupt", nil, nil, 1, 2)
local specWarnChargingStation		= mod:NewSpecialWarningInterrupt(225100, "HasInterrupt", nil, nil, 1, 2)
local specWarnSearingGlare			= mod:NewSpecialWarningInterrupt(211299, "HasInterrupt", nil, nil, 1, 2)
local specWarnSealMagic				= mod:NewSpecialWarningRun(209404, false, nil, 2, 4, 2)
local specWarnDisruptingEnergy		= mod:NewSpecialWarningMove(209512, nil, nil, nil, 1, 2)
local specWarnWhirlingBlades		= mod:NewSpecialWarningRun(209378, "Melee", nil, nil, 4, 3)

local timerCripple					= mod:NewTargetTimer(8, 214690, nil, nil, nil, 3, nil, DBM_CORE_MAGIC_ICON)
local timerCrippleCD				= mod:NewCDTimer(20.5, 214690, nil, "MagicDispeller2", nil, 3, nil, DBM_CORE_HEALER_ICON..DBM_CORE_MAGIC_ICON)
local timerShadowBoltVolleyCD		= mod:NewCDTimer(21, 214692, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerCarrionSwarmCD			= mod:NewCDTimer(17.5, 214688, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)

local timerDisintegrationBeamCD		= mod:NewCDTimer(11, 207980, nil, nil, nil, 3, nil, DBM_CORE_DEADLY_ICON)
local timerFelDetonationCD			= mod:NewCDTimer(12, 211464, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerWhirlingBladesCD			= mod:NewCDTimer(19, 209378, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)
local timerShockwaveCD				= mod:NewCDTimer(8, 207979, nil, nil, nil, 3, nil, DBM_CORE_TANK_ICON..DBM_CORE_DEADLY_ICON)

local timerRoleplay					= mod:NewCombatTimer(33.2)

local countdownFelDetonation		= mod:NewCountdown(12, 211464, nil, nil, 5)

local yellSuppress					= mod:NewYell(209413, nil, nil, nil, "SAY")
local yellSubdue					= mod:NewYell(212773, nil, nil, nil, "SAY")
local yellDisintegrationBeam		= mod:NewYell(207980, nil, nil, nil, "SAY")
local yellCripple					= mod:NewYell(214690, nil, nil, nil, "SAY")
local yellCarrionSwarm				= mod:NewYell(214688, nil, nil, nil, "SAY")

mod:AddBoolOption("SpyHelper", true)

mod.vb.wardens = 3

function mod:CarrionSwarmTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnCarrionSwarm:Show()
		specWarnCarrionSwarm:Play("watchstep")
		yellCarrionSwarm:Yell()
	else
		warnCarrionSwarm:Show(targetname)
	end
end

function mod:SuppressTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
	--	specWarnSuppress2:Show()
	--	specWarnSuppress2:Play("targetyou")
		yellSuppress:Yell()
	else
		warnSuppress:Show(targetname)
	end
end

function mod:DisintegrationBeamTarget(targetname, uId)
	if not targetname then return end
	if targetname == UnitName("player") then
		specWarnDisintegrationBeam:Show()
		specWarnDisintegrationBeam:Play("defensive")
		yellDisintegrationBeam:Yell()
	else
		warnDisintegrationBeam:Show(targetname)
	end
end

function mod:SPELL_CAST_START(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 209027 and self:AntiSpam(3, 5) then
		specWarnQuellingStrike:Show()
		specWarnQuellingStrike:Play("shockwave")
	elseif spellId == 212031 and self:AntiSpam(3, 6) then
		specWarnChargedBlast:Show()
		specWarnChargedBlast:Play("shockwave")
	elseif spellId == 209485 then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnDrainMagic:Show(args.sourceName)
			specWarnDrainMagic:Play("kickcast")
		else
			warnDrainMagic:Show()
			warnDrainMagic:Play("kickcast")
		end
	elseif spellId == 209410 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnNightfallOrb:Show(args.sourceName)
		specWarnNightfallOrb:Play("kickcast")
	elseif spellId == 209413 then
		self:BossTargetScanner(args.sourceGUID, "SuppressTarget", 0.1, 2)
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnSuppress:Show(args.sourceName)
			specWarnSuppress:Play("kickcast")
		end
	elseif spellId == 211470 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnBewitch:Show(args.sourceName)
		specWarnBewitch:Play("kickcast")
	elseif spellId == 225100 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnChargingStation:Show(args.sourceName)
		specWarnChargingStation:Play("kickcast")
	elseif spellId == 211299 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnSearingGlare:Show(args.sourceName)
		specWarnSearingGlare:Play("kickcast")
	elseif spellId == 211464 then
		warnFelDetonation:Show()
		if not UnitIsDeadOrGhost("player") then
			specWarnFelDetonation:Show()
			specWarnFelDetonation:Play("aesoon")
		end
		timerFelDetonationCD:Start()
		countdownFelDetonation:Start()
	elseif spellId == 209404 then
		specWarnSealMagic:Show()
		specWarnSealMagic:Play("runout")
	elseif spellId == 209495 and self:AntiSpam(2, 7) then
		--Don't want to move too early, just be moving already as cast is finishing
		specWarnChargedSmash:Schedule(1.2)
		specWarnChargedSmash:ScheduleVoice(1.2, "chargemove")
	elseif spellId == 209378 then
		if not UnitIsDeadOrGhost("player") then
			specWarnWhirlingBlades:Show()
			specWarnWhirlingBlades:Play("runout")
		end
		timerWhirlingBladesCD:Start()
	elseif spellId == 207980 then
		self:BossTargetScanner(args.sourceGUID, "DisintegrationBeamTarget", 0.1, 2)
		timerDisintegrationBeamCD:Start()
	elseif spellId == 207979 then
		if not UnitIsDeadOrGhost("player") then
			specWarnShockwave:Show()
			specWarnShockwave:Play("watchstep")
		end
		timerShockwaveCD:Start()
	elseif spellId == 214692 then
		warnShadowBoltVolley:Show()
		timerShadowBoltVolleyCD:Start()
		if self:IsHard() then
			if not UnitIsDeadOrGhost("player") then
				specWarnShadowBoltVolley:Show()
				specWarnShadowBoltVolley:Play("watchstep")
			end
		end
		self:ResetGossipState()
	elseif spellId == 214688 then
		self:BossTargetScanner(args.sourceGUID, "CarrionSwarmTarget", 0.1, 2)
	elseif spellId == 214690 then
		timerCrippleCD:Start()
	elseif spellId == 212773 and self:AntiSpam(2, 8) then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnSubdue:Show(args.sourceName)
			specWarnSubdue:Play("kickcast")
		else
			warnSubdue2:Show()
			warnSubdue2:Play("kickcast")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 214688 then
		timerCarrionSwarmCD:Start()
	elseif spellId == 210253 then
		warnDisableBeacon:Show(args.sourceName)
	elseif spellId == 208585 then
		warnEating:Show(args.sourceName)
	elseif spellId == 208427 then
		warnSiphoningMagic:Show(args.sourceName)
	elseif spellId == 209767 then
		warnPurifying:Show(args.sourceName)
	elseif spellId == 208334 then
		warnDraining:Show(args.sourceName)
	elseif spellId == 210872 then
		warnInvokingText:Show(args.sourceName)
	elseif spellId == 210307 then
		warnDrinking:Show(args.sourceName)
	elseif spellId == 208939 then
		warnReleaseSpores:Show(args.sourceName)
	elseif spellId == 208370 then
		warnShuttingDown:Show(args.sourceName)
	elseif spellId == 210925 then
		warnTreating:Show(args.sourceName)
	elseif spellId == 210217 then
		warnPilfering:Show(args.sourceName)
	elseif spellId == 210922 then
		warnTinkering:Show(args.sourceName)
	elseif spellId == 210330 then
		warnDefacing:Show(args.sourceName)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not self.Options.Enabled then return end
	local spellId = args.spellId
	if spellId == 209033 and not args:IsDestTypePlayer() then
		specWarnFortification:Show(args.destName)
		specWarnFortification:Play("dispelnow")
	elseif spellId == 209512 and args:IsPlayer() then
		specWarnDisruptingEnergy:Show()
		specWarnDisruptingEnergy:Play("runaway")
	elseif spellId == 214690 then
		warnCripple:Show(args.destName)
		timerCripple:Start(args.destName)
		if args:IsPlayer() then
			specWarnCripple2:Show()
			specWarnCripple2:Play("targetyou")
			yellCripple:Yell()
		elseif self:IsMagicDispeller2() then
			if not UnitIsDeadOrGhost("player") then
				specWarnCripple:Show(args.destName)
				specWarnCripple:Play("dispelnow")
			end
		end
	elseif spellId == 212773 then
		if args:IsPlayer() then
			yellSubdue:Yell()
		elseif self:IsMagicDispeller2() then
			if not UnitIsDeadOrGhost("player") then
				specWarnSubdue2:CombinedShow(0.3, args.destName)
				specWarnSubdue2:Play("dispelnow")
			end
		else
			warnSubdue:CombinedShow(0.3, args.destName)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 214690 then
		timerCripple:Cancel(args.destName)
	end
end


do
	local hintTranslations = {
		["gloves"] = L.Gloves,
		["no gloves"] = L.NoGloves,
		["cape"] = L.Cape,
		["no cape"] = L.Nocape,
		["light vest"] = L.LightVest,
		["dark vest"] = L.DarkVest,
		["female"] = L.Female,
		["male"] = L.Male,
		["short sleeves"] = L.ShortSleeve,
		["long sleeves"] = L.LongSleeve,
		["potions"] = L.Potions,
		["no potion"] = L.NoPotions,
		["book"] = L.Book,
		["pouch"] = L.Pouch
	}
	local hints = {}
	local clues = {
		[L.Gloves1] = "gloves",
		[L.Gloves2] = "gloves",
		[L.Gloves3] = "gloves",
		[L.Gloves4] = "gloves",
		[L.Gloves5 or false] = "gloves",
		[L.Gloves6 or false] = "gloves",
		
		[L.NoGloves1] = "no gloves",
		[L.NoGloves2] = "no gloves",
		[L.NoGloves3] = "no gloves",
		[L.NoGloves4] = "no gloves",
		[L.NoGloves5 or false] = "no gloves",
		[L.NoGloves6 or false] = "no gloves",
		[L.NoGloves7 or false] = "no gloves",
		
		[L.Cape1] = "cape",
		[L.Cape2] = "cape",
		
		[L.NoCape1] = "no cape",
		[L.NoCape2] = "no cape",
		
		[L.LightVest1] = "light vest",
		[L.LightVest2] = "light vest",
		[L.LightVest3] = "light vest",
		
		[L.DarkVest1] = "dark vest",
		[L.DarkVest2] = "dark vest",
		[L.DarkVest3] = "dark vest",
		[L.DarkVest4] = "dark vest",
		
		[L.Female1] = "female",
		[L.Female2] = "female",
		[L.Female3] = "female",
		[L.Female4] = "female",
		[L.Female5 or false] = "female",
		
		[L.Male1] = "male",
		[L.Male2] = "male",
		[L.Male3] = "male",
		[L.Male4] = "male",
		[L.Male5 or false] = "male",
		[L.Male6 or false] = "male",
		
		[L.ShortSleeve1] = "short sleeves",
		[L.ShortSleeve2] = "short sleeves",
		[L.ShortSleeve3] = "short sleeves",
		[L.ShortSleeve4] = "short sleeves",
		[L.ShortSleeve5 or false] = "short sleeves",
		
		[L.LongSleeve1] = "long sleeves",
		[L.LongSleeve2] = "long sleeves",
		[L.LongSleeve3] = "long sleeves",
		[L.LongSleeve4] = "long sleeves",
		[L.LongSleeve5 or false] = "long sleeves",
		
		[L.Potions1] = "potions",
		[L.Potions2] = "potions",
		[L.Potions3] = "potions",
		[L.Potions4] = "potions",
		[L.Potions5 or false] = "potions",
		[L.Potions6 or false] = "potions",
		
		[L.NoPotions1] = "no potion",
		[L.NoPotions2] = "no potion",
		
		[L.Book1] = "book",
		[L.Book2] = "book",
		[L.Book3 or false] = "book",
		
		[L.Pouch1] = "pouch",
		[L.Pouch2] = "pouch",
		[L.Pouch3] = "pouch",
		[L.Pouch4] = "pouch",
		[L.Pouch5 or false] = "pouch",
		[L.Pouch6 or false] = "pouch",
		[L.Pouch7 or false] = "pouch"
	}
	local bwClues = {
		[1] = "cape",
		[2] = "no cape",
		[3] = "pouch",
		[4] = "potions",
		[5] = "long sleeves",
 		[6] = "short sleeves",
 		[7] = "gloves",
 		[8] = "no gloves",
 		[9] = "male",
 		[10] = "female",
 		[11] = "light vest",
 		[12] = "dark vest",
 		[13] = "no potion",
		[14] = "book"
	}

	local function updateInfoFrame()
		local lines = {}
		for hint, j in pairs(hints) do
			local text = hintTranslations[hint] or hint
			lines[text] = ""
		end
		
		return lines
	end
	
	
	--/run DBM:GetModByName("CoSTrash"):ResetGossipState()
	function mod:ResetGossipState()
		table.wipe(hints)
		DBM.InfoFrame:Hide()
	end
	
	function mod:CHAT_MSG_MONSTER_SAY(msg)
		if msg:find(L.Found) then
			self:SendSync("Finished")
		elseif msg == L.proshlyapMurchal then
			self:SendSync("RolePlayMel")
		end
	end

	function mod:GOSSIP_SHOW()
		if not self.Options.SpyHelper then return end
		local guid = UnitGUID("npc")
		if not guid then return end
		local cid = self:GetCIDFromGUID(guid)
		if cid == 106024 or cid == 105729 or cid == 106468 or cid == 105249 or cid == 105340 or cid == 105117 or cid == 106110 or cid == 106018 or cid == 106113 or cid == 105831 or cid == 105157 or cid == 105160 or cid == 106108 or cid == 105215 or cid == 106112 then
			if select('#', GetGossipOptions()) > 0 then
				SelectGossipOption(1)
				CloseGossip()
			end
		end		
		-- Suspicious noble
		if cid == 107486 then
			if select('#', GetGossipOptions()) > 0 then
				SelectGossipOption(1)
			else
				local clue = clues[GetGossipText()]
				if clue and not hints[clue] then
					CloseGossip()
					if IsInRaid() then
						SendChatMessage(hintTranslations[clue], "RAID")
					elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
						SendChatMessage(hintTranslations[clue], "INSTANCE_CHAT")
					elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
						SendChatMessage(hintTranslations[clue], "PARTY")
					end
					hints[clue] = true
					self:SendSync("CoS", clue)
					DBM.InfoFrame:Show(5, "function", updateInfoFrame)
				end
			end
		end
	end
	
	function mod:OnSync(msg, clue)
		if not self.Options.SpyHelper then return end
		if msg == "CoS" and clue then
			hints[clue] = true
			DBM.InfoFrame:Show(5, "function", updateInfoFrame)
		elseif msg == "Finished" then
			warnPhase2:Show()
			self:ResetGossipState()
		--	self:Finish()
		elseif msg == "RolePlayMel" then
			timerRoleplay:Start()
		end
	end
	function mod:OnBWSync(msg, extra)
		if msg ~= "clue" then return end
		extra = tonumber(extra)
		if extra and extra > 0 and extra < 15 then
			DBM:Debug("Recieved BigWigs Comm:"..extra)
			local bwClue = bwClues[extra]
			hints[bwClue] = true
			DBM.InfoFrame:Show(5, "function", updateInfoFrame)
		end
	end
end


function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 104278 then
		timerFelDetonationCD:Cancel()
		countdownFelDetonation:Cancel()
	elseif cid == 104275 then
		self.vb.wardens = 2
		timerWhirlingBladesCD:Cancel()
	elseif cid == 104274 then
		self.vb.wardens = 1
		timerDisintegrationBeamCD:Cancel()
	elseif cid == 104273 then
		self.vb.wardens = 0
		timerShockwaveCD:Cancel()
	elseif cid == 108151 or cid == 107435 then
		timerCrippleCD:Cancel()
		timerShadowBoltVolleyCD:Cancel()
		timerCarrionSwarmCD:Cancel()
	end
end