local mod	= DBM:NewMod(1657, "DBM-Party-Legion", 2, 762)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 17077 $"):sub(12, -3))
mod:SetCreatureID(99192)
mod:SetEncounterID(1839)
mod:SetZone()
mod:SetUsedIcons(2, 1)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 200182 200243 200289",
	"SPELL_AURA_REFRESH 200243",
	"SPELL_AURA_REMOVED 200243",
	"SPELL_CAST_SUCCESS 200359 199837 200182 200238",
	"SPELL_CAST_START 200289 200185",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

--TOOD, maybe play gathershare for ALL (except tank) for nightmare target.
--TODO, maybe add an arrow group up hud for nightmare target depending on number of players it takes to clear it.
--TODO, feed on the weak have any significance?
local warnNightmare					= mod:NewTargetAnnounce(200185, 3)
local warnFeed						= mod:NewTargetAnnounce(200238, 3)
local warnParanoia					= mod:NewTargetAnnounce(200289, 3)
local warnApocNightmare				= mod:NewSpellAnnounce(200050, 3)

local specWarnFesteringRip			= mod:NewSpecialWarningDispel(200182, "Healer")--No disease dispeller in group? have fun wiping
local specWarnNightmare				= mod:NewSpecialWarningYou(200185, nil, nil, nil, 1, 2)
local yellNightmare					= mod:NewYell(200185)
local specWarnParanoia				= mod:NewSpecialWarningMoveAway(200289, nil, nil, nil, 1, 2)
local yellParanoia					= mod:NewYell(200289)
local specWarnApocNightmare			= mod:NewSpecialWarningDefensive(200050, nil, nil, nil, 1, 2)

local timerFesteringRipCD			= mod:NewCDTimer(17, 200182, nil, "Tank|Healer", nil, 5, nil, DBM_CORE_MAGIC_ICON)--17-21
local timerNightmareCD				= mod:NewCDTimer(20.5, 200185, nil, nil, nil, 3)--17-25 (old)
local timerParanoiaCD				= mod:NewCDTimer(30, 200359, nil, nil, nil, 3)--18-28 (old)
local timerFeedCD					= mod:NewCDTimer(25.5, 200238, nil, nil, nil, 3)
local timerApocNightmareCD			= mod:NewCDTimer(5, 200050, nil, nil, nil, 2)

mod:AddSetIconOption("SetIconOnNightmare", 200185)

mod.vb.nightmareIcon = 1


function mod:OnCombatStart(delay)
	self.vb.nightmareIcon = 1
	self.vb.phase = 1
	timerFesteringRipCD:Start(6-delay)
	timerNightmareCD:Start(6-delay)
	timerFeedCD:Start(14.5-delay)
	timerParanoiaCD:Start(21-delay)
	self:RegisterShortTermEvents(
			"UNIT_HEALTH_FREQUENT boss1 boss2 boss3 boss4 boss5"
		)
	--timerApocNightmareCD:Start(37)
end

function mod:ParanoiaTarget(targetname, uId)
	if not targetname then return end
	self:UnscheduleMethod("ClearTarget")
	self.vb.lastTarget = targetname
	self:ScheduleMethod(3, "ClearTarget")
	if targetname == UnitName("player") then
		specWarnParanoia:Show()
		specWarnParanoia:Play("scatter")
		yellParanoia:Yell()
	else
		warnParanoia:Show(targetname)
	end
end

function mod:ClearTarget()
	self.vb.lastTarget = nil
end

function mod:NightmareTarget(targetname, uId)
	if not targetname then return end
	self:UnscheduleMethod("ClearTarget")
	self.vb.lastTarget = targetname
	self:ScheduleMethod(2, "ClearTarget")
	if targetname == UnitName("player") then
		specWarnNightmare:Show()
		specWarnNightmare:Play("scatter")
		yellNightmare:Yell()
	else
		warnNightmare:Show(targetname)
	end
	if self.Options.SetIconOnNightmare then
		self:SetIcon(targetname, self.vb.nightmareIcon)
	end
	--Alternate Icons
	if self.vb.nightmareIcon == 1 then
		self.vb.nightmareIcon = 2
	else
		self.vb.nightmareIcon = 1
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 200359 then
		timerParanoiaCD:Start()
	elseif spellId == 200182 then
		timerFesteringRipCD:Start()
	elseif spellId == 200238 then
		timerFeedCD:Start()
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 200289 then
		self:BossTargetScanner(99192, "ParanoiaTarget", 0.05, 8, nil, nil, nil, nil, nil, self.vb.lastTarget)
	end
	if spellId == 200185 then
		timerNightmareCD:Start()
		self:BossTargetScanner(99192, "NightmareTarget", 0.05, 8, nil, nil, nil, nil, nil, self.vb.lastTarget)
	end
end


function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 200182 then
		specWarnFesteringRip:Show(args.destName)
	end
end
mod.SPELL_AURA_REFRESH = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 200243 then
		if self.Options.SetIconOnNightmare then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, _, _, spellGUID)
	local spellId = tonumber(select(5, strsplit("-", spellGUID)), 10)
	if spellId == 200050 then--Apocalyptic Nightmare
		warnApocNightmare:Show()
	end
end

function mod:ApocNightmareDelayed()
	specWarnApocNightmare:Show()
    specWarnApocNightmare:Play("defensive")
end

function mod:UNIT_HEALTH_FREQUENT(uId)
	if self.vb.phase == 2 then
		self:UnregisterShortTermEvents()
		return
	end
	local cid = self:GetUnitCreatureId(uId)
	if cid ~= 99192 then return end--Shade of Xavius
	local health = UnitHealth(uId) / UnitHealthMax(uId) * 100
	if health <= 50 then
		self.vb.phase = 2
		self:Schedule(2.5, self.ApocNightmareDelayed, self)
		timerApocNightmareCD:Start()
	end
end
