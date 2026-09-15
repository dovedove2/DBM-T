local mod	= DBM:NewMod(1489, "DBM-Party-Legion", 4, 721)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17518 $"):sub(12, -3))
mod:SetCreatureID(95676)
mod:SetEncounterID(1809)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 197963 197964 197965 197966 197967 198190",
	"SPELL_CAST_START 198263 198077 198750",
	"SPELL_CAST_SUCCESS 197961",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--http://legion.wowhead.com/icons/name:boss_odunrunes_

local warnUnworthy					= mod:NewTargetAnnounce(198190, 3)
local warnSpear						= mod:NewSpellAnnounce(198072, 2)--Target not available so no target warning.

local specWarnTempest				= mod:NewSpecialWarningRun(198263, nil, nil, nil, 4, 2)
local specWarnShatterSpears			= mod:NewSpecialWarningDodge(198077, nil, nil, nil, 2, 2)
local specWarnRunicBrand			= mod:NewSpecialWarningMoveTo(197961, nil, nil, nil, 2, 6)
--local specWarnAdd					= mod:NewSpecialWarningSwitch(201221, "-Healer", nil, nil, 1, 2) --TODO
local specWarnSurge					= mod:NewSpecialWarningInterrupt(198750, "HasInterrupt", nil, nil, 1, 2)

local timerSpearCD					= mod:NewCDTimer(8, 198072, nil, nil, nil, 3)--More data needed
local timerTempestCD				= mod:NewCDCountTimer(55.8, 198263, nil, nil, nil, 2, nil, DBM_CORE_DEADLY_ICON)--More data needed
local timerShatterSpearsCD			= mod:NewCDTimer(55.8, 198077, nil, nil, nil, 2)
local timerRunicBrandCD				= mod:NewCDCountTimer(55.8, 197961, nil, nil, nil, 3)
local timerAddCD					= mod:NewCDTimer(55.8, 201221, nil, nil, nil, 1, 201215)--54-58

mod.vb.tempestCount = 0
mod.vb.brandCount = 0
mod.vb.spearCount = 0


function mod:OnCombatStart(delay)
	self.vb.tempestCount = 0
	self.vb.brandCount = 0
	self.vb.spearCount = 0
	timerSpearCD:Start(7.8-delay)
	timerTempestCD:Start(23.1-delay, 1)
	timerAddCD:Start(17.8-delay)
	timerShatterSpearsCD:Start(39.7-delay)
	timerRunicBrandCD:Start(45.7-delay, 1)
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 197963 and args:IsPlayer() then--Purple K (NE)
		specWarnRunicBrand:Show("|TInterface\\Icons\\Boss_OdunRunes_Purple.blp:12:12|tNE|TInterface\\Icons\\Boss_OdunRunes_Purple.blp:12:12|t")
		specWarnRunicBrand:Play("frontright")
	elseif spellId == 197964 and args:IsPlayer() then--Orange N (SE)
		specWarnRunicBrand:Show("|TInterface\\Icons\\Boss_OdunRunes_Orange.blp:12:12|tSE|TInterface\\Icons\\Boss_OdunRunes_Orange.blp:12:12|t")
		specWarnRunicBrand:Play("backright")
	elseif spellId == 197965 and args:IsPlayer() then--Yellow H (SW)
		specWarnRunicBrand:Show("|TInterface\\Icons\\Boss_OdunRunes_Yellow.blp:12:12|tSW|TInterface\\Icons\\Boss_OdunRunes_Yellow.blp:12:12|t")
		specWarnRunicBrand:Play("backleft")
	elseif spellId == 197966 and args:IsPlayer() then--Blue fishies (NW)
		specWarnRunicBrand:Show("|TInterface\\Icons\\Boss_OdunRunes_Blue.blp:12:12|tNW|TInterface\\Icons\\Boss_OdunRunes_Blue.blp:12:12|t")
		specWarnRunicBrand:Play("frontleft")
	elseif spellId == 197967 and args:IsPlayer() then--Green box (N)
		specWarnRunicBrand:Show("|TInterface\\Icons\\Boss_OdunRunes_Green.blp:12:12|tN|TInterface\\Icons\\Boss_OdunRunes_Green.blp:12:12|t")
		specWarnRunicBrand:Play("frontcenter")--Does not exist yet
	elseif spellId == 198190 then
		warnUnworthy:CombinedShow(0.5, args.destName)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 198072 then
		warnSpear:Show()
	elseif spellId == 198263 then
		self.vb.tempestCount = self.vb.tempestCount + 1
		specWarnTempest:Show(self.vb.tempestCount)
		specWarnTempest:Play("runout")
		timerAddCD:Start(50.5)
		timerTempestCD:Start(55.8, self.vb.tempestCount+1)
	elseif spellId == 198077 then
		specWarnShatterSpears:Show()
		specWarnShatterSpears:Play("watchorb")
		timerShatterSpearsCD:Start()
	elseif spellId == 198750 and self:CheckInterruptFilter(args.sourceGUID) then
		specWarnSurge:Show(args.sourceName)
		specWarnSurge:Play("kickcast")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 197961 then
		self.vb.brandCount = self.vb.brandCount + 1
		timerRunicBrandCD:Start(55.8, self.vb.brandCount+1)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, _, spellGUID)
	local spellId = tonumber(select(5, strsplit("-", spellGUID)), 10)
	if spellId == 198396 then
		self.vb.spearCount = self.vb.spearCount + 1
		warnSpear:Show()
		if self.vb.spearCount == 1 then
			timerSpearCD:Start()
		elseif self.vb.spearCount == 2 then
			timerSpearCD:Start(20)
		elseif self.vb.spearCount == 3 then
			timerSpearCD:Start(28)
			self.vb.spearCount = 0
		end
		
	elseif spellId == 201221 then--Summon Stormforged
		--specWarnAdd:Show()
		--specWarnAdd:Play("killmob")
		--timerAddCD:Start()
	end
end
