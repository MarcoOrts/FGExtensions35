-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

COLOR_HEALTH_UNCONSCIOUS = "6C2DC7";
COLOR_TOKEN_HEALTH_UNCONSCIOUS = "8C3BFF";

function getPercentWounded(sNodeType, node)
	local nHP = 0;
	local nTemp = 0;
	local nWounds = 0;
    local nInjury = 0;
	
	if sNodeType == "ct" then
		nHP = math.max(DB.getValue(node, "hp", 0), 0);
		nTemp = math.max(DB.getValue(node, "hptemp", 0), 0);
		nWounds = math.max(DB.getValue(node, "wounds", 0), 0);
        nInjury = math.max(DB.getValue(node, "injury", 0), 0);
	elseif sNodeType == "pc" then
		nHP = math.max(DB.getValue(node, "hp.total", 0), 0);
		nTemp = math.max(DB.getValue(node, "hp.temporary", 0), 0);
		nWounds = math.max(DB.getValue(node, "hp.wounds", 0), 0);
        nInjury = math.max(DB.getValue(node, "hp.injury", 0), 0);
	end
	
	local nPercentWounded = 0;
	local nPercentNonlethal = 0;
	if nHP > 0 then
		nPercentWounded = (nWounds + nInjury) / (nHP + nTemp);
        nPercentNonlethal = nWounds / (nHP + nTemp);
	end
	
	local sStatus;
	if sNodeType == "ct" and not User.isHost() then
		sStatus = DB.getValue(node, "status", "");
	else
		local rActor = ActorManager.getActor(sNodeType, node);
		local bDiesAtZero = false;
		if isCreatureType(rActor, "construct") or isCreatureType(rActor, "undead") or isCreatureType(rActor, "swarm") then
			bDiesAtZero = true;
		end

		if bDiesAtZero and nPercentWounded >= 1 then
			sStatus = "Dead";
		elseif nPercentWounded > 1 then
			local nDying = GameSystem.getDeathThreshold(rActor);
			
			if ((nWounds + nInjury) - (nHP + nTemp)) < nDying then
				sStatus = "Dying";
			else
				sStatus = "Dead";
			end
		elseif nPercentNonlethal == 1 then
			sStatus = "Unconscious";
		elseif nPercentWounded == 1 then
			sStatus = "Disabled";
		elseif nPercentWounded > 0 then
			local bDetailedStatus = OptionsManager.isOption("WNDC", "detailed");
		
			if bDetailedStatus then
				if nPercentWounded >= .75 then
					sStatus = "Critical";
				elseif nPercentWounded >= .5 then
					sStatus = "Heavy";
				elseif nPercentWounded >= .25 then
					sStatus = "Moderate";
				else
					sStatus = "Light";
				end
			else
				if nPercentWounded >= .5 then
					sStatus = "Heavy";
				else
					sStatus = "Wounded";
				end
			end
		else
			sStatus = "Healthy";
		end
	end
	
	return nPercentWounded, nPercentNonlethal, sStatus;
end

-- Based on the percent wounded, change the font color for the Wounds field
function getWoundColor(sNodeType, node)
	local nPercentWounded, nPercentNonlethal, sStatus = getPercentWounded(sNodeType, node);
	
	local sColor;
	if sStatus == "Unconscious" then
		sColor = COLOR_HEALTH_UNCONSCIOUS;
	elseif sStatus == "Disabled" or sStatus == "Staggered" then
		sColor = ColorManager.COLOR_HEALTH_SIMPLE_BLOODIED;
	else
		sColor = ColorManager.getHealthColor(nPercentWounded, false);
	end

	return sColor, nPercentWounded, nPercentNonlethal, sStatus;
end

-- Based on the percent wounded, change the token health bar color
function getWoundBarColor(sNodeType, node)
	local nPercentWounded, nPercentNonlethal, sStatus = getPercentWounded(sNodeType, node);
	
	local sColor;
	if sStatus == "Unconscious" then
		sColor = COLOR_TOKEN_HEALTH_UNCONSCIOUS;
	elseif sStatus == "Disabled" or sStatus == "Staggered" then
		sColor = ColorManager.COLOR_TOKEN_HEALTH_SIMPLE_BLOODIED;
	else
		sColor = ColorManager.getTokenHealthColor(nPercentWounded, true);
	end

	return sColor, nPercentWounded, nPercentNonlethal, sStatus;
end

function getAbilityEffectsBonus(rActor, sAbility)
	if not rActor or not sAbility then
		return 0, 0;
	end
	
	local sAbilityEffect = DataCommon.ability_ltos[sAbility];
	if not sAbilityEffect then
		return 0, 0;
	end
	
	local nEffectMod, nAbilityEffects = EffectManager35E.getEffectsBonus(rActor, sAbilityEffect, true);
	
	if sAbility == "dexterity" then
		if EffectManager35E.hasEffectCondition(rActor, "Entangled") then
			nEffectMod = nEffectMod - 4;
			nAbilityEffects = nAbilityEffects + 1;
		end
		if DataCommon.isPFRPG() and EffectManager35E.hasEffectCondition(rActor, "Grappled") then
			nEffectMod = nEffectMod - 4;
			nAbilityEffects = nAbilityEffects + 1;
		end
	end
	if sAbility == "dexterity" or sAbility == "strength" then
		if EffectManager35E.hasEffectCondition(rActor, "Exhausted") then
			nEffectMod = nEffectMod - 6;
			nAbilityEffects = nAbilityEffects + 1;
		elseif EffectManager35E.hasEffectCondition(rActor, "Fatigued") then
			nEffectMod = nEffectMod - 2;
			nAbilityEffects = nAbilityEffects + 1;
		end
	end
	
	local nEffectBonusMod = 0;
	if nEffectMod > 0 then
		nEffectBonusMod = math.floor(nEffectMod / 2);
	else
		nEffectBonusMod = math.ceil(nEffectMod / 2);
	end

	local nAbilityMod = 0;
	local nAbilityScore = getAbilityScore(rActor, sAbility);
	if nAbilityScore > 0 and not DataCommon.isPFRPG() then
		local nAbilityDamage = getAbilityDamage(rActor, sAbility);
		
		local nCurrentBonus = math.floor((nAbilityScore - nAbilityDamage - 10) / 2);
		local nAffectedBonus = math.floor((nAbilityScore - nAbilityDamage + nEffectMod - 10) / 2);
		
		nAbilityMod = nAffectedBonus - nCurrentBonus;
	else
		nAbilityMod = nEffectBonusMod;
	end

	return nAbilityMod, nAbilityEffects;
end

function getAbilityDamage(rActor, sAbility)
	if not sAbility then
		return 0;
	end
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0;
	end
	
	local nStatDamage = 0;

	local sShort = string.sub(string.lower(sAbility), 1, 3);
	if sActorType == "pc" then
		if sShort == "lev" then
			nStatDamage = 0;
		elseif sShort == "bab" then
			nStatDamage = 0;
		elseif sShort == "str" then
			nStatDamage = DB.getValue(nodeActor, "abilities.strength.damage", 0);
		elseif sShort == "dex" then
			nStatDamage = DB.getValue(nodeActor, "abilities.dexterity.damage", 0);
		elseif sShort == "con" then
			nStatDamage = DB.getValue(nodeActor, "abilities.constitution.damage", 0);
		elseif sShort == "int" then
			nStatDamage = DB.getValue(nodeActor, "abilities.intelligence.damage", 0);
		elseif sShort == "wis" then
			nStatDamage = DB.getValue(nodeActor, "abilities.wisdom.damage", 0);
		elseif sShort == "cha" then
			nStatDamage = DB.getValue(nodeActor, "abilities.charisma.damage", 0);
		end
	end
	
	return nStatDamage;
end

function getAbilityScore(rActor, sAbility)
	if not sAbility then
		return -1;
	end
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return -1;
	end
	
	local nStatScore = -1;
	
	local sShort = string.sub(string.lower(sAbility), 1, 3);
	if sActorType == "pc" then
		if sShort == "lev" then
			nStatScore = DB.getValue(nodeActor, "level", 0);
		elseif sShort == "bab" then
			nStatScore = DB.getValue(nodeActor, "attackbonus.base", 0);
		elseif sShort == "cmb" then
			nStatScore = DB.getValue(nodeActor, "attackbonus.base", 0);
		elseif sShort == "str" then
			nStatScore = DB.getValue(nodeActor, "abilities.strength.score", 0);
		elseif sShort == "dex" then
			nStatScore = DB.getValue(nodeActor, "abilities.dexterity.score", 0);
		elseif sShort == "con" then
			nStatScore = DB.getValue(nodeActor, "abilities.constitution.score", 0);
		elseif sShort == "int" then
			nStatScore = DB.getValue(nodeActor, "abilities.intelligence.score", 0);
		elseif sShort == "wis" then
			nStatScore = DB.getValue(nodeActor, "abilities.wisdom.score", 0);
		elseif sShort == "cha" then
			nStatScore = DB.getValue(nodeActor, "abilities.charisma.score", 0);
		end
	else
		if sShort == "lev" then
			nStatScore = tonumber(string.match(DB.getValue(nodeActor, "hd", ""), "^(%d+)")) or 0;
		elseif sShort == "bab" then
			nStatScore = 0;

			local sBABGrp = DB.getValue(nodeActor, "babgrp", "");
			local sBAB = sBABGrp:match("[+-]?%d+");
			if sBAB then
				nStatScore = tonumber(sBAB) or 0;
			end
		elseif sShort == "cmb" then
			nStatScore = 0;

			local sBABGrp = DB.getValue(nodeActor, "babgrp", "");
			local sBAB = sBABGrp:match("CMB ([+-]?%d+)");
			if not sBAB then
				sBAB = sBABGrp:match("[+-]?%d+");
			end
			if sBAB then
				nStatScore = tonumber(sBAB) or 0;
			end
		elseif sShort == "str" then
			nStatScore = DB.getValue(nodeActor, "strength", 0);
		elseif sShort == "dex" then
			nStatScore = DB.getValue(nodeActor, "dexterity", 0);
		elseif sShort == "con" then
			nStatScore = DB.getValue(nodeActor, "constitution", 0);
		elseif sShort == "int" then
			nStatScore = DB.getValue(nodeActor, "intelligence", 0);
		elseif sShort == "wis" then
			nStatScore = DB.getValue(nodeActor, "wisdom", 0);
		elseif sShort == "cha" then
			nStatScore = DB.getValue(nodeActor, "charisma", 0);
		end
	end
	
	return nStatScore;
end

function getAbilityBonus(rActor, sAbility)
	if not sAbility then
		return 0;
	end
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0;
	end
	
	-- SETUP
	local sStat = sAbility;
	local bHalf = false;
	local bDouble = false;
	local nStatVal = 0;
	
	-- HANDLE HALF/DOUBLE MODIFIERS
	if string.match(sStat, "^half") then
		bHalf = true;
		sStat = string.sub(sStat, 5);
	end
	if string.match(sStat, "^double") then
		bDouble = true;
		sStat = string.sub(sStat, 7);
	end

	-- GET ABILITY VALUE
	local nStatScore = getAbilityScore(rActor, sStat);
	if nStatScore < 0 then
		return 0;
	end
	
	if StringManager.contains(DataCommon.abilities, sStat) then
		if sActorType == "pc" then
			nStatVal = nStatVal + DB.getValue(nodeActor, "abilities." .. sStat .. ".bonusmodifier", 0);
			
			local nAbilityDamage = DB.getValue(nodeActor, "abilities." .. sStat .. ".damage", 0);
			if DataCommon.isPFRPG() then
				if nAbilityDamage >= 0 then
					nAbilityDamage = math.floor(nAbilityDamage / 2) * 2;
				else
					nAbilityDamage = math.ceil(nAbilityDamage / 2) * 2;
				end
			end
			nStatScore = nStatScore - nAbilityDamage;
		end
		nStatVal = nStatVal + math.floor((nStatScore - 10) / 2);
	else
		nStatVal = nStatScore;
	end
	
	-- APPLY HALF/DOUBLE MODIFIERS
	if bDouble then
		nStatVal = nStatVal * 2;
	end
	if bHalf then
		nStatVal = math.floor(nStatVal / 2);
	end

	-- RESULTS
	return nStatVal;
end

function getSpellDefense(rActor)
	local nSR = 0;
	
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor then
		if sActorType == "ct" then
			nSR = DB.getValue(nodeActor, "sr", 0);
		elseif sActorType == "pc" then
			nSR = DB.getValue(nodeActor, "defenses.sr.total", 0);
		else
			local sSpecialQualities = string.lower(DB.getValue(nodeActor, "specialqualities", ""));
			local sSpellResist = string.match(sSpecialQualities, "spell resistance (%d+)");
			if not sSpellResist then
				sSpellResist = string.match(sSpecialQualities, "sr (%d+)");
			end
			if sSpellResist then
				nSR = tonumber(sSpellResist) or 0;
			end
		end
	end
	
	return nSR;
end

function getArmorComps(rActor)
	local aComps = {};
	
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return aComps;
	end

	if sActorType == "pc" then
		local nACBonusComp = DB.getValue(nodeActor, "ac.sources.armor", 0);
		if nACBonusComp ~= 0 then
			aComps["armor"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.shield", 0);
		if nACBonusComp ~= 0 then
			aComps["shield"] = nACBonusComp;
		end
		local sAbility = DB.getValue(nodeActor, "ac.sources.ability", "");
		if DataCommon.ability_ltos[sAbility] then
			aComps[DataCommon.ability_ltos[sAbility]] = getAbilityBonus(rActor, sAbility);
		end
		local sAbility2 = DB.getValue(nodeActor, "ac.sources.ability2", "");
		if DataCommon.ability_ltos[sAbility2] then
			aComps[DataCommon.ability_ltos[sAbility2]] = getAbilityBonus(rActor, sAbility2);
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.size", 0);
		if nACBonusComp ~= 0 then
			aComps["size"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.naturalarmor", 0);
		if nACBonusComp ~= 0 then
			aComps["natural"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.deflection", 0);
		if nACBonusComp ~= 0 then
			aComps["deflection"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.dodge", 0);
		if nACBonusComp ~= 0 then
			aComps["dodge"] = nACBonusComp;
		end
		nACBonusComp = DB.getValue(nodeActor, "ac.sources.misc", 0);
		if nACBonusComp ~= 0 then
			aComps["misc"] = nACBonusComp;
		end
	else
		local sAC = DB.getValue(nodeActor, "ac", ""):lower();
		local nAC = tonumber(sAC:match("^(%d+)")) or 10;
		local sACComps = sAC:match("%(([^)]+)%)");
		local nCompTotal = 10;
		if sACComps then
			local aACSplit = StringManager.split(sACComps, ",", true);
			for _,vACComp in ipairs(aACSplit) do
				local sACCompBonus, sACCompType = vACComp:match("^([+-]%d+)%s+(.*)$");
				if not sACCompType then
					sACCompType, sACCompBonus = vACComp:match("^(.*)%s+([+-]%d+)$");
				end
				local nACCompBonus = tonumber(sACCompBonus) or 0;
				if sACCompType and nACCompBonus ~= 0 then
					sACCompType = sACCompType:gsub("[+-]%d+", "");
					sACCompType = StringManager.trim(sACCompType);
					
					if DataCommon.actypes[sACCompType] then
						aComps[DataCommon.actypes[sACCompType]] = nACCompBonus;
						nCompTotal = nCompTotal + nACCompBonus;
					elseif StringManager.contains (DataCommon.acarmormatch, sACCompType) then
						aComps["armor"] = nACCompBonus;
						nCompTotal = nCompTotal + nACCompBonus;
					elseif StringManager.contains (DataCommon.acshieldmatch, sACCompType) then
						aComps["shield"] = nACCompBonus;
						nCompTotal = nCompTotal + nACCompBonus;
					elseif StringManager.contains (DataCommon.acdeflectionmatch, sACCompType) then
						aComps["deflection"] = nACCompBonus;
						nCompTotal = nCompTotal + nACCompBonus;
					end
				end
			end
		end
		if nCompTotal ~= nAC then
			aComps["misc"] = nAC - nCompTotal;
		end
	end

	return aComps;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
	-- VALIDATE
	if not rDefender or not rRoll then
		return nil, 0, 0, 0;
	end
	
	local sAttack = rRoll.sDesc;
	
	-- DETERMINE ATTACK TYPE AND DEFENSE
	local sAttackType = "M";
	if rRoll.sType == "attack" then
		sAttackType = string.match(sAttack, "%[ATTACK.*%((%w+)%)%]");
	end
	local bOpportunity = string.match(sAttack, "%[OPPORTUNITY%]");
	local bTouch = true;
	if rRoll.sType == "attack" then
		bTouch = string.match(sAttack, "%[TOUCH%]");
	end
	local bFlatFooted = string.match(sAttack, "%[FF%]");
	local nCover = tonumber(string.match(sAttack, "%[COVER %-(%d)%]")) or 0;
	local bConceal = string.match(sAttack, "%[CONCEAL%]");
	local bTotalConceal = string.match(sAttack, "%[TOTAL CONC%]");
	local bAttackerBlinded = string.match(sAttack, "%[BLINDED%]");

	-- Determine the defense database node name
	local nDefense = 10;
	local nFlatFootedMod = 0;
	local nTouchMod = 0;
	local sDefenseStat = "dexterity";
	local sDefenseStat2 = "";
	local sDefenseStat3 = "";
	if rRoll.sType == "grapple" then
		sDefenseStat3 = "strength";
	end

	local sDefenderType, nodeDefender = ActorManager.getTypeAndNode(rDefender);
	if not nodeDefender then
		return nil, 0, 0, 0;
	end

	if sDefenderType == "pc" then
		if rRoll.sType == "attack" then
			nDefense = DB.getValue(nodeDefender, "ac.totals.general", 10);
			nFlatFootedMod = nDefense - DB.getValue(nodeDefender, "ac.totals.flatfooted", 10);
			nTouchMod = nDefense - DB.getValue(nodeDefender, "ac.totals.touch", 10);
		else
			nDefense = DB.getValue(nodeDefender, "ac.totals.cmd", 10);
			nFlatFootedMod = DB.getValue(nodeDefender, "ac.totals.general", 10) - DB.getValue(nodeDefender, "ac.totals.flatfooted", 10);
		end
		sDefenseStat = DB.getValue(nodeDefender, "ac.sources.ability", "");
		if sDefenseStat == "" then
			sDefenseStat = "dexterity";
		end
		sDefenseStat2 = DB.getValue(nodeDefender, "ac.sources.ability2", "");
		if rRoll.sType == "grapple" then
			sDefenseStat3 = DB.getValue(nodeDefender, "ac.sources.cmdability", "");
			if sDefenseStat3 == "" then
				sDefenseStat3 = "strength";
			end
		end
	elseif sDefenderType == "ct" then
		if rRoll.sType == "attack" then
			nDefense = DB.getValue(nodeDefender, "ac_final", 10);
			nFlatFootedMod = nDefense - DB.getValue(nodeDefender, "ac_flatfooted", 10);
			nTouchMod = nDefense - DB.getValue(nodeDefender, "ac_touch", 10);
		else
			nDefense = DB.getValue(nodeDefender, "cmd", 10);
			nFlatFootedMod = DB.getValue(nodeDefender, "ac_final", 10) - DB.getValue(nodeDefender, "ac_flatfooted", 10);
		end
	else
		if rRoll.sType == "attack" then
			local sAC = DB.getValue(nodeDefender, "ac", "");
			nDefense = tonumber(string.match(sAC, "^%s*(%d+)")) or 10;

			local sFlatFootedAC = string.match(sAC, "flat-footed (%d+)");
			if sFlatFootedAC then
				nFlatFootedMod = nDefense - tonumber(sFlatFootedAC);
			else
				nFlatFootedMod = getAbilityBonus(rDefender, sDefenseStat);
			end
			
			local sTouchAC = string.match(sAC, "touch (%d+)");
			if sTouchAC then
				nTouchMod = nDefense - tonumber(sTouchAC);
			end
		else
			local sBABGrp = DB.getValue(nodeDefender, "babgrp", "");
			local sMatch = string.match(sBABGrp, "CMD ([+-]?[0-9]+)");
			if sMatch then
				nDefense = tonumber(sMatch) or 10;
			else
				nDefense = 10;
			end
			
			local sAC = DB.getValue(nodeDefender, "ac", "");
			local nAC = tonumber(string.match(sAC, "^%s*(%d+)")) or 10;

			local sFlatFootedAC = string.match(sAC, "flat-footed (%d+)");
			if sFlatFootedAC then
				nFlatFootedMod = nAC - tonumber(sFlatFootedAC);
			else
				nFlatFootedMod = getAbilityBonus(rDefender, sDefenseStat);
			end
		end
	end
	nDefenseStatMod = getAbilityBonus(rDefender, sDefenseStat) + getAbilityBonus(rDefender, sDefenseStat2);
	
	-- MAKE SURE FLAT-FOOTED AND TOUCH ADJUSTMENTS ARE POSITIVE
	if nTouchMod < 0 then
		nTouchMod = 0;
	end
	if nFlatFootedMod < 0 then
		nFlatFootedMod = 0;
	end
	
	-- APPLY FLAT-FOOTED AND TOUCH ADJUSTMENTS
	if bTouch then
		nDefense = nDefense - nTouchMod;
	end
	if bFlatFooted then
		nDefense = nDefense - nFlatFootedMod;
	end
	
	-- EFFECT MODIFIERS
	local nAttackEffectMod = 0;
	local nDefenseEffectMod = 0;
	local nMissChance = 0;
	if ActorManager.hasCT(rDefender) then
		-- SETUP
		local bCombatAdvantage = false;
		local bZeroAbility = false;
		local nBonusAC = 0;
		local nBonusStat = 0;
		local nBonusSituational = 0;
		
		local bPFMode = DataCommon.isPFRPG();
		
		-- BUILD ATTACK FILTER 
		local aAttackFilter = {};
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity");
		end

		-- GET ATTACKER BASE MODIFIER
		local aBonusTargetedAttackDice, nBonusTargetedAttack = EffectManager35E.getEffectsBonus(rAttacker, "ATK", false, aAttackFilter, rDefender, true);
		if rRoll.sType == "grapple" then
			local aPFDice, nPFMod, nPFCount = EffectManager35E.getEffectsBonus(rAttacker, {"CMB"}, false, aAttackFilter, rDefender, true);
			if nPFCount > 0 then
				bEffects = true;
				for k, v in ipairs(aPFDice) do
					table.insert(aBonusTargetedAttackDice, v);
				end
				nBonusTargetedAttack = nBonusTargetedAttack + nPFMod;
			end
		end
		nAttackEffectMod = nAttackEffectMod + StringManager.evalDice(aBonusTargetedAttackDice, nBonusTargetedAttack);
					
		-- CHECK IF COMBAT ADVANTAGE ALREADY SET BY ATTACKER EFFECT
		if string.match(sAttack, "%[CA%]") then
			bCombatAdvantage = true;
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - GENERAL
		if EffectManager35E.hasEffect(rAttacker, "CA", rDefender, true) then
			bCombatAdvantage = true;
		end
		if EffectManager35E.hasEffect(rAttacker, "Invisible", rDefender, true) then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManager35E.hasEffect(rDefender, "GRANTCA", rAttacker) then
			bCombatAdvantage = true;
		end
		if EffectManager35E.hasEffect(rDefender, "Blinded") then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManager35E.hasEffect(rDefender, "Cowering") or
				EffectManager35E.hasEffect(rDefender, "Rebuked") then
			nBonusSituational = nBonusSituational - 2;
			bCombatAdvantage = true;
		end
		if EffectManager35E.hasEffect(rDefender, "Slowed") then
			nBonusSituational = nBonusSituational - 1;
		end
		if EffectManager35E.hasEffect(rDefender, "Flat-footed") or 
				EffectManager35E.hasEffect(rDefender, "Climbing") or 
				EffectManager35E.hasEffect(rDefender, "Running") then
			bCombatAdvantage = true;
		end
		if EffectManager35E.hasEffect(rDefender, "Pinned") then
			bCombatAdvantage = true;
			if bPFMode then
				nBonusSituational = nBonusSituational - 4;
			else
				if not EffectManager35E.hasEffect(rAttacker, "Grappled") then
					nBonusSituational = nBonusSituational - 4;
				end
			end
		elseif not bPFMode and EffectManager35E.hasEffect(rDefender, "Grappled") then
			if not EffectManager35E.hasEffect(rAttacker, "Grappled") then
				bCombatAdvantage = true;
			end
		end
		if EffectManager35E.hasEffect(rDefender, "Helpless") or 
				EffectManager35E.hasEffect(rDefender, "Paralyzed") or 
				EffectManager35E.hasEffect(rDefender, "Petrified") or
				EffectManager35E.hasEffect(rDefender, "Unconscious") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 4;
			end
			bZeroAbility = true;
		end
		if EffectManager35E.hasEffect(rDefender, "Kneeling") or 
				EffectManager35E.hasEffect(rDefender, "Sitting") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 2;
			elseif sAttackType == "R" then
				nBonusSituational = nBonusSituational + 2;
			end
		elseif EffectManager35E.hasEffect(rDefender, "Prone") then
			if sAttackType == "M" then
				nBonusSituational = nBonusSituational - 4;
			elseif sAttackType == "R" then
				nBonusSituational = nBonusSituational + 4;
			end
		end
		if EffectManager35E.hasEffect(rDefender, "Squeezing") then
			nBonusSituational = nBonusSituational - 4;
		end
		if EffectManager35E.hasEffect(rDefender, "Stunned") then
			nBonusSituational = nBonusSituational - 2;
			if rRoll.sType == "grapple" then
				nBonusSituational = nBonusSituational - 4;
			end
			bCombatAdvantage = true;
		end
		if EffectManager35E.hasEffect(rDefender, "Invisible", rAttacker) then
			bTotalConceal = true;
		end
		
		-- DETERMINE EXISTING AC MODIFIER TYPES
		local aExistingBonusByType = getArmorComps (rDefender);
		
		-- GET DEFENDER ALL DEFENSE MODIFIERS
		local aIgnoreEffects = {};
		if bTouch then
			table.insert(aIgnoreEffects, "armor");
			table.insert(aIgnoreEffects, "shield");
			table.insert(aIgnoreEffects, "natural");
		end
		if bFlatFooted or bCombatAdvantage then
			table.insert(aIgnoreEffects, "dodge");
		end
		if rRoll.sType == "grapple" then
			table.insert(aIgnoreEffects, "size");
		end
		local aACEffects, nACEffectCount = EffectManager35E.getEffectsBonusByType(rDefender, {"AC"}, true, aAttackFilter, rAttacker);
		for k,v in pairs(aACEffects) do
			if not StringManager.contains(aIgnoreEffects, k) then
				local sBonusType = DataCommon.actypes[k];
				if sBonusType then
					-- Dodge bonuses stack (by rules)
					if sBonusType == "dodge" then
						nBonusAC = nBonusAC + v.mod;
					-- Size bonuses stack (by usage expectation)
					elseif sBonusType == "size" then
						nBonusAC = nBonusAC + v.mod;
					elseif aExistingBonusByType[sBonusType] then
						if v.mod < 0 then
							nBonusAC = nBonusAC + v.mod;
						elseif v.mod > aExistingBonusByType[sBonusType] then
							nBonusAC = nBonusAC + v.mod - aExistingBonusByType[sBonusType];
						end
					else
						nBonusAC = nBonusAC + v.mod;
					end
				else
					nBonusAC = nBonusAC + v.mod;
				end
			end
		end
		if rRoll.sType == "grapple" then
			local nPFMod, nPFCount = EffectManager35E.getEffectsBonus(rDefender, {"CMD"}, true, aAttackFilter, rAttacker);
			if nPFCount > 0 then
				nBonusAC = nBonusAC + nPFMod;
			end
		end
		
		-- GET DEFENDER DEFENSE STAT MODIFIERS
		local nBonusStat = 0;
		local nBonusStat1 = getAbilityEffectsBonus(rDefender, sDefenseStat);
		if sDefenderType == "pc" and (nBonusStat1 > 0) then
			if DB.getValue(nodeDefender, "encumbrance.armormaxstatbonusactive", 0) == 1 then
				local nCurrentStatBonus = getAbilityBonus(rDefender, sDefenseStat);
				local nMaxStatBonus = math.max(DB.getValue(nodeDefender, "encumbrance.armormaxstatbonus", 0), 0);
				local nMaxEffectStatModBonus = math.max(nMaxStatBonus - nCurrentStatBonus, 0);
				if nBonusStat1 > nMaxEffectStatModBonus then 
					nBonusStat1 = nMaxEffectStatModBonus; 
				end
			end
		end
		if not bFlatFooted and sDefenseStat == "dexterity" then
			nFlatFootedMod = nFlatFootedMod + nBonusStat1;
		end
		nBonusStat = nBonusStat + nBonusStat1;
		local nBonusStat2 = getAbilityEffectsBonus(rDefender, sDefenseStat2);
		if not bFlatFooted and sDefenseStat2 == "dexterity" then
			nFlatFootedMod = nFlatFootedMod + nBonusStat2;
		end
		nBonusStat = nBonusStat + nBonusStat2;
		local nBonusStat3 = getAbilityEffectsBonus(rDefender, sDefenseStat3);
		if not bFlatFooted and sDefenseStat3 == "dexterity" then
			nFlatFootedMod = nFlatFootedMod + nBonusStat3;
		end
		nBonusStat = nBonusStat + nBonusStat3;
		if bFlatFooted or bCombatAdvantage then
			-- IF NEGATIVE AND AC STAT BONUSES, THEN ONLY APPLY THE AMOUNT THAT EXCEEDS AC STAT BONUSES
			if nBonusStat < 0 then
				if nDefenseStatMod > 0 then
					nBonusStat = math.min(nDefenseStatMod + nBonusStat, 0);
				end
				
			-- IF POSITIVE AND AC STAT PENALTIES, THEN ONLY APPLY UP TO AC STAT PENALTIES
			else
				if nDefenseStatMod < 0 then
					nBonusStat = math.min(nBonusStat, -nDefenseStatMod);
				else
					nBonusStat = 0;
				end
			end
		end
		
		-- HANDLE NEGATIVE LEVELS
		if rRoll.sType == "grapple" then
			local nNegLevelMod, nNegLevelCount = EffectManager35E.getEffectsBonus(rDefender, {"NLVL"}, true);
			if nNegLevelCount > 0 then
				nBonusSituational = nBonusSituational - nNegLevelMod;
			end
		end
		
		-- HANDLE DEXTERITY MODIFIER REMOVAL
		if bZeroAbility then
			if bFlatFooted then
				nBonusSituational = nBonusSituational - 5;
			else
				nBonusSituational = nBonusSituational - nFlatFootedMod - 5;
			end
		elseif bCombatAdvantage and not bFlatFooted then
			nBonusSituational = nBonusSituational - nFlatFootedMod;
		end

		-- GET DEFENDER SITUATIONAL MODIFIERS - COVER
		if nCover < 8 then
			local aCover = EffectManager35E.getEffectsByType(rDefender, "SCOVER", aAttackFilter, rAttacker);
			if #aCover > 0 or EffectManager35E.hasEffect(rDefender, "SCOVER", rAttacker) then
				nBonusSituational = nBonusSituational + 8 - nCover;
			elseif nCover < 4 then
				aCover = EffectManager35E.getEffectsByType(rDefender, "COVER", aAttackFilter, rAttacker);
				if #aCover > 0 or EffectManager35E.hasEffect(rDefender, "COVER", rAttacker) then
					nBonusSituational = nBonusSituational + 4 - nCover;
				elseif nCover < 2 then
					aCover = EffectManager35E.getEffectsByType(rDefender, "PCOVER", aAttackFilter, rAttacker);
					if #aCover > 0 or EffectManager35E.hasEffect(rDefender, "PCOVER", rAttacker) then
						nBonusSituational = nBonusSituational + 2 - nCover;
					end
				end
			end
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - CONCEALMENT
		local aConceal = EffectManager35E.getEffectsByType(rDefender, "TCONC", aAttackFilter, rAttacker);
		if #aConceal > 0 or EffectManager35E.hasEffect(rDefender, "TCONC", rAttacker) or bTotalConceal or bAttackerBlinded then
			nMissChance = 50;
		else
			aConceal = EffectManager35E.getEffectsByType(rDefender, "CONC", aAttackFilter, rAttacker);
			if #aConceal > 0 or EffectManager35E.hasEffect(rDefender, "CONC", rAttacker) or bConceal then
				nMissChance = 20;
			end
		end
		
		-- CHECK INCORPOREALITY
		if not bPFMode then
			local bIncorporealAttack = false;
			if string.match(sAttack, "%[INCORPOREAL%]") then
				bIncorporealAttack = true;
			end
			local bIncorporealDefender = EffectManager35E.hasEffect(rDefender, "Incorporeal", rAttacker);
			local bGhostTouchAttacker = EffectManager35E.hasEffect(rAttacker, "ghost touch", rDefender);

			if bIncorporealDefender and not bGhostTouchAttacker and not bIncorporealAttack then
				nMissChance = 50;
			end
		end
		
		-- ADD IN EFFECT MODIFIERS
		nDefenseEffectMod = nBonusAC + nBonusStat + nBonusSituational;
	
	-- NO DEFENDER SPECIFIED, SO JUST LOOK AT THE ATTACK ROLL MODIFIERS
	else
		if bTotalConceal or bAttackerBlinded then
			nMissChance = 50;
		elseif bConceal then
			nMissChance = 20;
		end
		
		if bIncorporealAttack then
			nMissChance = 50;
		end
	end
	
	-- Return the final defense value
	return nDefense, nAttackEffectMod, nDefenseEffectMod, nMissChance;
end

function isAlignment(rActor, sAlignCheck)
	local nCheckLawChaosAxis = 0;
	local nCheckGoodEvilAxis = 0;
	local aCheckSplit = StringManager.split(sAlignCheck:lower(), " ", true);
	for _,v in ipairs(aCheckSplit) do
		if nCheckLawChaosAxis == 0 and DataCommon.alignment_lawchaos[v] then
			nCheckLawChaosAxis = DataCommon.alignment_lawchaos[v];
		end
		if nCheckGoodEvilAxis == 0 and DataCommon.alignment_goodevil[v] then
			nCheckGoodEvilAxis = DataCommon.alignment_goodevil[v];
		end
	end
	if nCheckLawChaosAxis == 0 and nCheckGoodEvilAxis == 0 then
		return false;
	end
	
	local nActorLawChaosAxis = 2;
	local nActorGoodEvilAxis = 2;
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	local sField = "alignment";
	if sType ~= "pc" and DataCommon.isPFRPG() then
		sField = "type";
	end
	local aActorSplit = StringManager.split(DB.getValue(nodeActor, sField, ""):lower(), " \n", true);
	for _,v in ipairs(aActorSplit) do
		if nActorLawChaosAxis == 2 and DataCommon.alignment_lawchaos[v] then
			nActorLawChaosAxis = DataCommon.alignment_lawchaos[v];
		end
		if nActorGoodEvilAxis == 2 and DataCommon.alignment_goodevil[v] then
			nActorGoodEvilAxis = DataCommon.alignment_goodevil[v];
		end
	end
	
	local bLCReturn = true;
	if nCheckLawChaosAxis > 0 then
		if nActorLawChaosAxis > 0 then
			bLCReturn = (nActorLawChaosAxis == nCheckLawChaosAxis);
		else
			bLCReturn = false;
		end
	end
	
	local bGEReturn = true;
	if nCheckGoodEvilAxis > 0 then
		if nActorGoodEvilAxis > 0 then
			bGEReturn = (nActorGoodEvilAxis == nCheckGoodEvilAxis);
		else
			bGEReturn = false;
		end
	end
	
	return (bLCReturn and bGEReturn);
end

function getSize(rActor)
	local nActorSize = nil;
	
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	local sField = "size";
	if sType ~= "pc" then
		sField = "type";
	end
	local aActorSplit = StringManager.split(DB.getValue(nodeActor, sField, ""):lower(), " \n", true);
	for _,v in ipairs(aActorSplit) do
		if not nActorSize and DataCommon.creaturesize[v] then
			nActorSize = DataCommon.creaturesize[v];
			break;
		end
		if sType ~= "pc" and 
				not DataCommon.alignment_lawchaos[v] and 
				not DataCommon.alignment_goodevil[v] and 
				(v ~= DataCommon.alignment_neutral) and 
				not DataCommon.creaturesize[v] then
			break;
		end
	end
	
	if not nActorSize then
		nActorSize = 0;
	end
	return nActorSize;
end

function isSize(rActor, sSizeCheck)
	local sSizeCheckLower = StringManager.trim(sSizeCheck:lower());

	local sCheckOp = sSizeCheckLower:match("^[<>]?=?");
	if sCheckOp then
		sSizeCheckLower = StringManager.trim(sSizeCheckLower:sub(#sCheckOp + 1));
	end
	
	local nCheckSize = nil;
	if DataCommon.creaturesize[sSizeCheckLower] then
		nCheckSize = DataCommon.creaturesize[sSizeCheckLower];
	end
	if not nCheckSize then
		return false;
	end
	
	local nActorSize = getSize(rActor);
	
	local bReturn = true;
	if sCheckOp then
		if sCheckOp == "<" then
			bReturn = (nActorSize < nCheckSize);
		elseif sCheckOp == ">" then
			bReturn = (nActorSize > nCheckSize);
		elseif sCheckOp == "<=" then
			bReturn = (nActorSize <= nCheckSize);
		elseif sCheckOp == ">=" then
			bReturn = (nActorSize >= nCheckSize);
		else
			bReturn = (nActorSize == nCheckSize);
		end
	else
		bReturn = (nActorSize == nCheckSize);
	end
	
	return bReturn;
end

function getCreatureTypeHelper(sTypeCheck, bUseDefaultType)
	local aCheckSplit = StringManager.split(sTypeCheck:lower(), ", %(%)", true);
	
	local aTypeCheck = {};
	local aSubTypeCheck = {};
	
	-- Handle half races
	local nHalfRace = 0;
	for k = 1, #aCheckSplit do
		if aCheckSplit[k]:sub(1, #DataCommon.creaturehalftype) == DataCommon.creaturehalftype then
			aCheckSplit[k] = aCheckSplit[k]:sub(#DataCommon.creaturehalftype + 1);
			nHalfRace = nHalfRace + 1;
		end
	end
	if nHalfRace == 1 then
		if not StringManager.contains (aCheckSplit, DataCommon.creaturehalftypesubrace) then
			table.insert(aCheckSplit, DataCommon.creaturehalftypesubrace);
		end
	end
	
	-- Check each word combo in the creature type string against standard creature types and subtypes
	for k = 1, #aCheckSplit do
		for _,sMainType in ipairs(DataCommon.creaturetype) do
			local aMainTypeSplit = StringManager.split(sMainType, " ", true);
			if #aMainTypeSplit > 0 then
				local bMatch = true;
				for i = 1, #aMainTypeSplit do
					if aMainTypeSplit[i] ~= aCheckSplit[k - 1 + i] then
						bMatch = false;
						break;
					end
				end
				if bMatch then
					table.insert(aTypeCheck, sMainType);
					k = k + (#aMainTypeSplit - 1);
				end
			end
		end
		for _,sSubType in ipairs(DataCommon.creaturesubtype) do
			local aSubTypeSplit = StringManager.split(sSubType, " ", true);
			if #aSubTypeSplit > 0 then
				local bMatch = true;
				for i = 1, #aSubTypeSplit do
					if aSubTypeSplit[i] ~= aCheckSplit[k - 1 + i] then
						bMatch = false;
						break;
					end
				end
				if bMatch then
					table.insert(aSubTypeCheck, sSubType);
					k = k + (#aSubTypeSplit - 1);
				end
			end
		end
	end
	
	-- Make sure we have a default creature type (if requested)
	if bUseDefaultType then
		if #aTypeCheck == 0 then
			table.insert(aTypeCheck, DataCommon.creaturedefaulttype);
		end
	end
	
	-- Combine into a single list
	for _,vSubType in ipairs(aSubTypeCheck) do
		table.insert(aTypeCheck, vSubType);
	end
	
	return aTypeCheck;
end

function isCreatureType(rActor, sTypeCheck)
	local aTypeCheck = getCreatureTypeHelper(sTypeCheck, false);
	if #aTypeCheck == 0 then
		return false;
	end
	
	local sType, nodeActor = ActorManager.getTypeAndNode(rActor);
	local sField = "race";
	if sType ~= "pc" then
		sField = "type";
	end
	local aTypeActor = getCreatureTypeHelper(DB.getValue(nodeActor, sField, ""), true);

	local bReturn = false;
	for kCheck,vCheck in ipairs(aTypeCheck) do
		if StringManager.contains(aTypeActor, vCheck) then
			bReturn = true;
			break;
		end
	end
	return bReturn;
end
