function OnIRStart(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target

	GawainCheckCombo(caster, keys.ability)
	GenerateArtificialSun(caster, target:GetAbsOrigin())

	if target:GetTeamNumber() == caster:GetTeamNumber() then
		target:EmitSound("Hero_Omniknight.Purification")
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_invigorating_ray_ally", {})
		if ply.IsSunlightAcquired then
			keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_invigorating_ray_armor_buff", {})
		end
	else
		if IsSpellBlocked(keys.target) then return end
		target:EmitSound("Hero_Omniknight.Purification")
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_invigorating_ray_enemy", {})
	end
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
end

function OnIRTickAlly(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target
	target:SetHealth(target:GetHealth() + keys.Damage/5)
	if ply.IsSunlightAcquired then
		target:SetMana(target:GetMana() + keys.Damage/5)
	end
end

function OnIRTickEnemy(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target
	if ply.IsEclipseAcquired then 
		damage = keys.Damage/5
	else
		damage = keys.Damage/5 * 0.66
	end
	DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, keys.ability, false)
end

function OnDevoteStart(keys)
	local caster = keys.caster
	Timers:CreateTimer(function()
		if caster:HasModifier("modifier_blade_of_the_devoted") then
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false) 
			
			for k,v in pairs(targets) do
				keys.ability:ApplyDataDrivenModifier(keys.caster, v, "modifier_blade_of_the_devoted_ally_deniable",{})
			end
		end
		return 0.1
	end)

	caster:EmitSound("Hero_EmberSpirit.FireRemnant.Cast")
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( lightFx1, 0, caster:GetAbsOrigin())
end

function OnDevoteHit(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target

	GenerateArtificialSun(caster, target:GetAbsOrigin())

	if target:GetTeamNumber() == caster:GetTeamNumber() then
		-- process team effect
		target:SetHealth(target:GetHealth() + keys.Damage + caster:GetAttackDamage())
		if ply.IsSunlightAcquired then
			HardCleanse(target)
			for i=0, 15 do 
				local ability = target:GetAbilityByIndex(i)
				if ability ~= nil then
					local remainingCD = ability:GetCooldownTimeRemaining()
					ability:EndCooldown()
					ability:StartCooldown(remainingCD-15)
				else 
					break
				end
			end
		end
	else
		-- process enemy effect
		DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
		target:AddNewModifier(caster, caster, "modifier_stunned", {Duration = 0.1})
	end

	if ply.IsEclipseAcquired then
		keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_blade_of_the_devoted_eclispe",{})
		caster.CurrentDevoteDamage = keys.Damage/2
	end

	target:EmitSound("Hero_Invoker.ColdSnap")
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
	local flameFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( flameFx1, 0, target:GetAbsOrigin())
end

function OnDevoteConsecutiveHit(keys)
	local caster = keys.caster
	local target = keys.target

	DoDamage(caster, target, caster.CurrentDevoteDamage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
	caster.CurrentDevoteDamage = caster.CurrentDevoteDamage/2
	target:AddNewModifier(caster, caster, "modifier_stunned", {Duration = 0.1})

	target:EmitSound("Hero_Invoker.ColdSnap")
	local lightFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
	local flameFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( flameFx1, 0, target:GetAbsOrigin())
end

function OnGalatineStart(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local casterLoc = caster:GetAbsOrigin()
	local targetPoint = keys.target_points[1]
	local orbLoc = caster:GetAbsOrigin()
	local dist = (targetPoint - casterLoc):Length2D()
	local diff = (targetPoint - caster:GetAbsOrigin()):Normalized()
	local timeElapsed = 0
	local flyingDist = 0
	local InFirstLoop = true

	caster.IsGalatineActive = true

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 1.75)
	keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_excalibur_galatine_anim",{})
	EmitGlobalSound("Gawain.Galatine")


	local castFx1 = ParticleManager:CreateParticle("particles/custom/saber_excalibur_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( castFx1, 0, caster:GetAbsOrigin())

	local castFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( castFx2, 0, caster:GetAbsOrigin())

	local galatineDummy = CreateUnitByName("gawain_galatine_dummy", Vector(20000,20000,0), true, nil, nil, caster:GetTeamNumber())
	local flameFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_excalibur_galatine_orb.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
	ParticleManager:SetParticleControl( flameFx1, 0, galatineDummy:GetAbsOrigin())


	Timers:CreateTimer(1.5, function()
		if caster:IsAlive() and timeElapsed < 1.5 and flyingDist < dist and caster.IsGalatineActive then
			if InFirstLoop then
				caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_detonate", true, true)
				InFirstLoop = false
			end
			orbLoc = orbLoc + diff * 33
			galatineDummy:SetAbsOrigin(orbLoc)
			flyingDist = (casterLoc - orbLoc):Length2D()
			timeElapsed = timeElapsed + 0.033
			return 0.033
		else 
			GenerateArtificialSun(caster, orbLoc)

			if caster:GetAbilityByIndex(2):GetAbilityName() == "gawain_excalibur_galatine_detonate" then
				caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_detonate", true, true)
			end
			-- Explosion on allies
			local targets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for k,v in pairs(targets) do
				v:SetHealth(v:GetHealth() + keys.Damage * 66/100)
				if ply.IsSunlightAcquired then
					local healTimer = 1
					Timers:CreateTimer(1.0, function()
						if healTimer > 3 then return end
						v:SetHealth(v:GetHealth() + keys.Damage/6)
						healTimer = healTimer + 1
						return 1.0
					end)
				end
			end

			-- Explosion on enemies
			local targets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for k,v in pairs(targets) do
				DoDamage(caster, v, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
				if ply.IsEclipseAcquired then
					local multiplier = (keys.Radius - (galatineDummy:GetAbsOrigin() - v:GetAbsOrigin()):Length2D())/keys.Radius
					DoDamage(caster, v, keys.Damage/2 * multiplier , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
				end
			end

			local explodeFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_hit.vpcf", PATTACH_ABSORIGIN, galatineDummy )
			ParticleManager:SetParticleControl( explodeFx1, 0, galatineDummy:GetAbsOrigin())			

			local explodeFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
			ParticleManager:SetParticleControl( explodeFx2, 0, galatineDummy:GetAbsOrigin())

			galatineDummy:EmitSound("Ability.LightStrikeArray")

			galatineDummy:ForceKill(true) 
			ParticleManager:DestroyParticle( flameFx1, false )
			ParticleManager:ReleaseParticleIndex( flameFx1 )
			ParticleManager:DestroyParticle( castFx1, false )
			ParticleManager:ReleaseParticleIndex( castFx1 )
			return
		end
	end)
end

function OnGalatineDetonate(keys)
	local caster = keys.caster
	caster.IsGalatineActive = false
	if caster:GetAbilityByIndex(2):GetAbilityName() == "gawain_excalibur_galatine_detonate" then
		caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_detonate", true, true)
	end
end

function OnEmbraceStart(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local target = keys.target

	GenerateArtificialSun(caster, target:GetAbsOrigin())

	if target:GetTeamNumber() == caster:GetTeamNumber() then
		-- process team effect
		local currentHealth = target:GetMaxHealth() - target:GetHealth()
		target:SetHealth(target:GetHealth() + currentHealth/2)
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_suns_embrace_ally",{})
		if ply.IsSunlightAcquired then
			keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_suns_embrace_sunlight_bonus",{})
		end
	else
		-- process enemy effect
		--DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
		if IsSpellBlocked(keys.target) then return end
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_suns_embrace_enemy",{})
		if ply.IsEclipseAcquired then
			target:AddNewModifier(caster, caster, "modifier_stunned", {Duration = 1.5})
		end
	end

	target:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")
	target:EmitSound("Hero_EmberSpirit.FlameGuard.Loop")
	target:EmitSound("Hero_Chen.HandOfGodHealHero")
end

function OnEmbraceTickAlly(keys)
	local caster = keys.caster
	local target = keys.target
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		keys.ability:ApplyDataDrivenModifier(keys.caster, v, "modifier_suns_embrace_burn",{})
	end
end

function OnEmbraceTickEnemy(keys)
	local caster = keys.caster
	local target = keys.target
	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		keys.ability:ApplyDataDrivenModifier(keys.caster, v, "modifier_suns_embrace_burn",{})
	end
end

function OnEmbraceDamageTick(keys)
	local caster = keys.caster
	local target = keys.target
	DoDamage(caster, target, keys.Damage/32 , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

function OnEmbraceEnd(keys)
	local caster = keys.caster
	local target = keys.target
	print("ended")
	StopSoundEvent("Hero_EmberSpirit.FlameGuard.Loop", caster)
end

function OnSupernovaStart(keys)
	local caster = keys.caster
	local target = keys.target
	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_supernova", {})
	caster.IsComboActive = true
	caster.SunTable = {}

	Timers:CreateTimer(4.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(400, 400, 400))
			EmitGlobalSound("Hero_Wisp.Relocate")
		end
	end)
	Timers:CreateTimer(5.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(550, 550, 550))
		end
	end)
	Timers:CreateTimer(6.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(700, 700, 700))
		end
	end)
	Timers:CreateTimer(7.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(850, 850, 850))
		end
	end) 
	Timers:CreateTimer(8.0, function()
		if target:IsAlive() then
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(1000, 1000, 1000))
		end
	end) 
	target:EmitSound("Hero_Enigma.Black_Hole")
	target:EmitSound("DOTA_Item.BlackKingBar.Activate")
end

function OnSupernovaTick(keys)
	local caster = keys.caster
	local target = keys.target

	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		if v:GetUnitName() == "gawain_artificial_sun" then
			if v.IsAddedToTable ~= true then
				table.insert(caster.SunTable, v)
				v.IsAddedToTable = true
				v.IsAttached = true
				v.AttachTarget = target
			end
		end
	end
end

function OnSupernovaEnd(keys)
	local caster = keys.caster
	local target = keys.target
	local sunCount = #caster.SunTable
	local dmg = keys.Damage
	caster.IsComboActive = false

	for i=1, sunCount do
		caster.SunTable[i]:ForceKill(true)
		if i-1 ~= 0 then
			dmg = dmg + keys.Damage * (0.67 ^ (i-1))
		end
	end

	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		DoDamage(caster, v, dmg, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		v:AddNewModifier(caster, caster, "modifier_stunned", {Duration = 2.0})
	end

	local lightFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_supernova_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( lightFx1, 0, target:GetAbsOrigin())
	ParticleManager:CreateParticle("particles/custom/screen_yellow_splash_gawain.vpcf", PATTACH_EYES_FOLLOW, caster)
	EmitGlobalSound("Hero_Phoenix.SuperNova.Explode")
	StopSoundEvent("Hero_Enigma.Black_Hole", target)
end

function GenerateArtificialSun(caster, location)
	local ply = caster:GetPlayerOwner()
	local IsSunActive = true
	local radius = 666
	local artSun = CreateUnitByName("gawain_artificial_sun", location, true, nil, nil, caster:GetTeamNumber())
	caster:FindAbilityByName("gawain_solar_embodiment"):ApplyDataDrivenModifier(caster, artSun, "modifier_artificial_sun_aura", {})
	if ply.IsDawnAcquired then
		radius = 999
		artSun:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 333}) 
	end
	artSun:SetDayTimeVisionRange(radius)
	artSun:SetNightTimeVisionRange(radius)

	artSun:SetAbsOrigin(artSun:GetAbsOrigin() + Vector(0,0, 500))


	if ply.IsDawnAcquired then
		artSun.IsAttached = true

		local targets = FindUnitsInRadius(caster:GetTeam(), location, nil, 666, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false) 
		print("finding targets")
		if #targets == 0 then
			artSun.IsAttached = false
		else
			print("found target " .. targets[1]:GetUnitName())
			artSun.AttachTarget = targets[1]
		end
	end

	Timers:CreateTimer(9, function()
		if IsValidEntity(artSun) and artSun:IsAlive() and caster.IsComboActive ~= true then
			artSun:ForceKill(true)
		end
	end)
end

function OnSunPassiveThink(keys)
	local target = keys.target
	if target.IsAttached and target.AttachTarget ~= nil then
		target:SetAbsOrigin(target.AttachTarget:GetAbsOrigin() + Vector(0,0,500))
	end
end

function OnFairyDamageTaken(keys)
	local caster = keys.caster
	local currentHealth = caster:GetHealth()

	if currentHealth == 0 and keys.ability:IsCooldownReady() then
		caster:SetHealth(500)
		keys.ability:StartCooldown(60) 
		local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
	end
end

function OnMeltdownStart(keys)
	local caster = keys.caster
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		if v:GetUnitName() == "gawain_artificial_sun" then
			keys.ability:ApplyDataDrivenModifier(caster, v, "modifier_divine_meltdown", {})

			v:EmitSound("Hero_DoomBringer.ScorchedEarthAura")
			v:EmitSound("Hero_Warlock.RainOfChaos_buildup" )
			v.metldownFx = ParticleManager:CreateParticle("particles/custom/gawain/gawain_meltdown.vpcf", PATTACH_ABSORIGIN_FOLLOW, v )
			ParticleManager:SetParticleControl( v.metldownFx, 0, v:GetAbsOrigin())
			Timers:CreateTimer(5.0, function()
				if IsValidEntity(v) and v:IsAlive() then
					ParticleManager:DestroyParticle( v.metldownFx, false )
					ParticleManager:ReleaseParticleIndex( v.metldownFx )
				
				end
				StopSoundOn("Hero_DoomBringer.ScorchedEarthAura", v)
			end)
			print("found sun")
		end
	end
end

function OnMeltdownThink(keys)
	local caster = keys.caster
	local target = keys.target
	if target.MeltdownCounter == nil then 
		target.MeltdownCounter = 9
	else
		target.MeltdownCounter = target.MeltdownCounter - 1
	end
	print(target.MeltdownCounter)
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
		DoDamage(caster, v, v:GetHealth() * target.MeltdownCounter/100, DAMAGE_TYPE_PURE, 0, keys.ability, false)
	end

end

function OnSunCleanup(keys)
	local caster = keys.caster
	local target = keys.target
	if target.metldownFx ~= nil then
		ParticleManager:DestroyParticle( target.metldownFx, false )
		ParticleManager:ReleaseParticleIndex( target.metldownFx )
		StopSoundOn("Hero_DoomBringer.ScorchedEarthAura", target)
	end
end

function GawainCheckCombo(caster, ability)
	if caster:GetStrength() >= 20 and caster:GetAgility() >= 20 and caster:GetIntellect() >= 20 then
		if ability == caster:FindAbilityByName("gawain_invigorating_ray") and caster:FindAbilityByName("gawain_suns_embrace"):IsCooldownReady() and caster:FindAbilityByName("gawain_supernova"):IsCooldownReady() then
			caster:SwapAbilities("gawain_suns_embrace", "gawain_supernova", true, true) 
			Timers:CreateTimer({
				endTime = 3,
				callback = function()
				caster:SwapAbilities("gawain_suns_embrace", "gawain_supernova", true, true) 
			end
			})			
		end
	end
end

function OnDawnAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    ply.IsDawnAcquired = true
    hero:FindAbilityByName("gawain_solar_embodiment"):SetLevel(2)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnFairyAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    ply.IsFairyAcquired = true

    hero:AddAbility("gawain_blessing_of_fairy")
    hero:FindAbilityByName("gawain_blessing_of_fairy"):SetLevel(1)
    --hero:SwapAbilities(hero:GetAbilityByIndex(4):GetName(), "gawain_blessing_of_fairy", true, true)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnMeltdownAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    ply.IsMeltdownAcquired = true
    hero:SwapAbilities(hero:GetAbilityByIndex(4):GetName(), "gawain_divine_meltdown", true, true)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnSunlightAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()

    ply.IsSunlightAcquired = true
    caster:FindAbilityByName("gawain_attribute_eclipse"):StartCooldown(9999)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

function OnEclipseAcquired(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()

    ply.IsEclipseAcquired = true
    caster:FindAbilityByName("gawain_attribute_sunlight"):StartCooldown(9999)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end

