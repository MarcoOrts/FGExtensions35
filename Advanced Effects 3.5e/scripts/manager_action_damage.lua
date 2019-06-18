-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYDMG = "applydmg";
OOB_MSGTYPE_APPLYDMGSTATE = "applydmgstate";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMGSTATE, handleApplyDamageState);

	ActionsManager.registerModHandler("damage", modDamage);
	ActionsManager.registerModHandler("spdamage", modDamage);
	ActionsManager.registerModHandler("stabilization", modStabilization);

	ActionsManager.registerPostRollHandler("damage", onDamageRoll);
	ActionsManager.registerPostRollHandler("spdamage", onDamageRoll);
	
	ActionsManager.registerResultHandler("damage", onDamage);
	ActionsManager.registerResultHandler("spdamage", onDamage);
	ActionsManager.registerResultHandler("stabilization", onStabilization);
	
	--KEL Fortif roll
	ActionsManager.registerResultHandler("fortification", onFortification);
end

function handleApplyDamage(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
	local bImmune = {};
	local bFortif = {};
	if rTarget then
		rTarget.nOrder = msgOOB.nTargetOrder;
	end
	-- Debug.console(msgOOB);
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	-- KEL bImmune, bFortif
	local rDamageOutput = decodeDamageText(nTotal, msgOOB.sDamage);	
	if rTarget then
		for k, v in pairs(rDamageOutput.aDamageTypes) do
			local l = "KELFORTIF " .. k;
			local aSrcDmgClauseTypes = {};
			local aTemp = StringManager.split(k, ",", true);
			for i = 1, #aTemp do
				if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
					table.insert(aSrcDmgClauseTypes, aTemp[i]);
				end
			end
			if #aSrcDmgClauseTypes > 0 then
				if msgOOB.ImmuneAll == "true" then
					bImmune["all"] = true;
				else
					bImmune["all"] = false;
				end
				-- if msgOOB.FortifAll == "true" then
					-- bFortif["all"] = true;
				-- else
					-- bFortif["all"] = false;
				-- end
				if msgOOB[k] == "true" then
					bImmune[k] = true;
				else
					bImmune[k] = false;
				end
				if msgOOB[l] == "true" then
					bFortif[k] = true;
				else
					bFortif[k] = false;
				end
			end
		end
	end
	applyDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sRollType, msgOOB.sDamage, nTotal, bImmune, bFortif);
end
-- KEL bImmune bFortif
function notifyApplyDamage(rSource, rTarget, bSecret, sRollType, sDesc, nTotal, bImmune, bFortif)
	if not rTarget then
		return;
	end
	local sTargetType, sTargetNode = ActorManager.getTypeAndNodeName(rTarget);
	if sTargetType ~= "pc" and sTargetType ~= "ct" then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMG;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sRollType = sRollType;
	msgOOB.nTotal = nTotal;
	msgOOB.sDamage = sDesc;
	msgOOB.sTargetType = sTargetType;
	msgOOB.sTargetNode = sTargetNode;
	msgOOB.nTargetOrder = rTarget.nOrder;
	-- KEL bImmune, bFortif
	local rDamageOutput = decodeDamageText(nTotal, sDesc);	
	if rTarget then
		for k, v in pairs(rDamageOutput.aDamageTypes) do
			local l = "KELFORTIF " .. k;
			local aSrcDmgClauseTypes = {};
			local aTemp = StringManager.split(k, ",", true);
			for i = 1, #aTemp do
				if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
					table.insert(aSrcDmgClauseTypes, aTemp[i]);
				end
			end
			if #aSrcDmgClauseTypes > 0 then
				msgOOB.ImmuneAll = bImmune["all"];
				-- msgOOB.FortifAll = bFortif["all"];
				msgOOB[k] = bImmune[k];
				msgOOB[l] = bFortif[k];
			end
		end
	end
	-- Debug.console(msgOOB);

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	Comm.deliverOOBMessage(msgOOB, "");
end

function performStabilizationRoll(rActor)
	local rRoll = GameSystem.getStabilizationRoll(rActor);

	ActionsManager.performAction(nil, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "damage";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[DAMAGE";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	if rAction.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range ..")";
		rRoll.range = rAction.range;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	
	-- Save the damage clauses in the roll structure
	rRoll.clauses = rAction.clauses;
	
	-- Add the dice and modifiers
	for _,vClause in pairs(rRoll.clauses) do
		for _,vDie in ipairs(vClause.dice) do
			table.insert(rRoll.aDice, vDie);
		end
		rRoll.nMod = rRoll.nMod + vClause.modifier;
	end
	
	-- Encode the damage types
	encodeDamageTypes(rRoll);

	-- Encode meta tags
	if rAction.meta then
		if rAction.meta == "empower" then
			rRoll.sDesc = rRoll.sDesc .. " [EMPOWER]";
		elseif rAction.meta == "maximize" then
			rRoll.sDesc = rRoll.sDesc .. " [MAXIMIZE]";
		end
	end
	
	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modStabilization(rSource, rTarget, rRoll)
	GameSystem.modStabilization(rSource, rTarget, rRoll);
end

function modDamage(rSource, rTarget, rRoll)
	decodeDamageTypes(rRoll);
	CombatManager2.addRightClickDiceToClauses(rRoll);

	-- Set up
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	local bEffects = false;
	local aEffectDice = {};
	local nEffectMod = 0;
	local bPFMode = DataCommon.isPFRPG();
	
	-- Build attack type filter
	local aAttackFilter = {};
	if rRoll.range == "R" then
		table.insert(aAttackFilter, "ranged");
	elseif rRoll.range == "M" then
		table.insert(aAttackFilter, "melee");
	end
	
	-- Handle ability effects
	if rSource then
		-- Apply ability modifiers
		for kClause,vClause in ipairs(rRoll.clauses) do
			-- Get original stat modifier
			local nStatMod = ActorManager2.getAbilityBonus(rSource, vClause.stat);
			
			-- Get any stat effects bonus
			local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, vClause.stat);
			if nBonusEffects > 0 then
				bEffects = true;
				
				-- Calc total stat mod
				local nTotalStatMod = nStatMod + nBonusStat;
				
				-- Handle maximum stat mod setting
				-- WORKAROUND: If max limited, then assume no penalty allowed (i.e. bows)
				local nStatModMax = vClause.statmax or 0;
				if nStatModMax > 0 then
					nStatMod = math.max(math.min(nStatMod, nStatModMax), 0);
					nTotalStatMod = math.max(math.min(nTotalStatMod, nStatModMax), 0);
				end

				-- Handle multipliers correctly
				-- NOTE: Negative values are not multiplied, but positive values are.
				local nMult = vClause.statmult or 1;
				local nMultOrigStatMod, nMultNewStatMod;
				if nStatMod <= 0 then
					nMultOrigStatMod = nStatMod;
				else
					nMultOrigStatMod = math.floor(nStatMod * nMult);
				end
				if nTotalStatMod <= 0 then
					nMultNewStatMod = nTotalStatMod;
				else
					nMultNewStatMod = math.floor(nTotalStatMod * nMult);
				end
				
				-- Calculate bonus difference
				local nMultDiffStatMod = nMultNewStatMod - nMultOrigStatMod;
				if bCritical then
					local nCritMult = vClause.mult or 2;
					nMultDiffStatMod = nMultDiffStatMod * nCritMult;
				end
				
				-- Apply bonus difference
				nEffectMod = nEffectMod + nMultDiffStatMod;
				vClause.modifier = vClause.modifier + nMultDiffStatMod;
				rRoll.nMod = rRoll.nMod + nMultDiffStatMod;
			end
		end
	end

	-- Handle critical
	local bCritical = ModifierStack.getModifierKey("DMG_CRIT") or Input.isShiftPressed();
	if ActionAttack.isCrit(rSource, rTarget) then
		bCritical = true;
	end
	if bCritical then
		table.insert(aAddDesc, "[CRITICAL]");

		local nDieIndex = 1;
		local aNewClauses = {};
		for _,vClause in ipairs(rRoll.clauses) do
			nDieIndex = nDieIndex + #(vClause.dice);
			
			table.insert(aNewClauses, vClause);
			
			local nMult = vClause.mult or 2;
			if nMult > 1 then
				local rNewClause = UtilityManager.copyDeep(vClause);
				rNewClause.dice = {};
				rNewClause.modifier = 0;
				if rNewClause.dmgtype == "" then
					rNewClause.dmgtype = "critical";
				else
					rNewClause.dmgtype = rNewClause.dmgtype .. ",critical";
				end
				
				local nDice = #(vClause.dice);
				local nMod = vClause.modifier or 0;
				
				for i = 2, nMult do
					for j = 1, nDice do
						if vClause.dice[j]:sub(1,1) == "-" then
							table.insert(rRoll.aDice, nDieIndex, "-g" .. vClause.dice[j]:sub(3));
						else
							table.insert(rRoll.aDice, nDieIndex, "g" .. vClause.dice[j]:sub(2));
						end
						table.insert(rNewClause.dice, vClause.dice[j]);
					end
					rRoll.nMod = rRoll.nMod + nMod;
					rNewClause.modifier = rNewClause.modifier + nMod;
				end
				
				table.insert(aNewClauses, rNewClause);
			end
		end
		rRoll.clauses = aNewClauses;
	end
	
	-- Handle general damage effects
	if rSource then
		-- NOTE: Effect damage dice are not multiplied on critical, though numerical modifiers are multiplied
		-- http://rpg.stackexchange.com/questions/4465/is-smite-evil-damage-multiplied-by-a-critical-hit
		local aEffects, nEffectCount;
		if rRoll.sType == "spdamage" then
			aEffects, nEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "DMGS", true, aAttackFilter, rTarget);
		else
			aEffects, nEffectCount = EffectManager35E.getEffectsBonusByType(rSource, "DMG", true, aAttackFilter, rTarget);
		end
		if nEffectCount > 0 then
			-- Use the first damage clause to determine damage type and crit multiplier for effect damage
			local nEffectCritMult = 2;
			local sEffectBaseType = "";
			if #(rRoll.clauses) > 0 then
				nEffectCritMult = rRoll.clauses[1].mult or 2;
				sEffectBaseType = rRoll.clauses[1].dmgtype or "";
			end

			-- For each effect, add a damage clause
			for _,v in pairs(aEffects) do
				-- Process effect damage types
				local bEffectPrecision = false;
				local bEffectCritical = false;
				local aEffectDmgType = {};
				local aEffectSpecialDmgType = {};
				for _,sWord in ipairs(v.remainder) do
					if StringManager.contains(DataCommon.specialdmgtypes, sWord) then
						table.insert(aEffectSpecialDmgType, sWord);
						if sWord == "critical" then
							bEffectCritical = true;
						elseif sWord == "precision" then
							bEffectPrecision = true;
						end
					elseif StringManager.contains(DataCommon.dmgtypes, sWord) then
						table.insert(aEffectDmgType, sWord);
					end
				end
				
				if not bEffectCritical or bCritical then
					bEffects = true;
					
					local rClause = {};
					
					-- Add effect dice
					rClause.dice = {};
					for _,vDie in ipairs(v.dice) do
						table.insert(aEffectDice, vDie);
						table.insert(rClause.dice, vDie);
						if vDie:sub(1,1) == "-" then
							table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
						else
							table.insert(rRoll.aDice, "p" .. vDie:sub(2));
						end
					end

					if #aEffectDmgType == 0 then
						table.insert(aEffectDmgType, sEffectBaseType);
					end
					for _,vSpecialDmgType in ipairs(aEffectSpecialDmgType) do
						table.insert(aEffectDmgType, vSpecialDmgType);
					end
					rClause.dmgtype = table.concat(aEffectDmgType, ",");

					local nCurrentMod = v.mod;
					nEffectMod = nEffectMod + nCurrentMod;
					rClause.modifier = nCurrentMod;
					rRoll.nMod = rRoll.nMod + nCurrentMod;

					table.insert(rRoll.clauses, rClause);
					
					-- Add critical effect modifier
					local nCurrentMod;
					if bCritical and not bEffectPrecision and not bEffectCritical and nEffectCritMult > 1 then
						local rClauseCritical = {};
						nCurrentMod = (v.mod * (nEffectCritMult - 1));
						rClauseCritical.modifier = nCurrentMod;
						if rClause.dmgtype == "" then
							rClauseCritical.dmgtype = "critical";
						else
							rClauseCritical.dmgtype = rClause.dmgtype .. ",critical";
						end
						table.insert(rRoll.clauses, rClauseCritical);

						nEffectMod = nEffectMod + nCurrentMod;
						rRoll.nMod = rRoll.nMod + nCurrentMod;
					end
					
				end
			end
		end
		
		-- Apply damage type modifiers
		if rTarget then
			if rRoll.sType == "spdamage" then
				aEffects = EffectManager35E.getEffectsByType(rSource, "DMGSTYPE", {}, rTarget);
			else
				aEffects = EffectManager35E.getEffectsByType(rSource, "DMGTYPE", {}, rTarget);
			end
		else
			if rRoll.sType == "spdamage" then
				aEffects = EffectManager35E.getEffectsByType(rSource, "DMGSTYPE", {});
			else
				aEffects = EffectManager35E.getEffectsByType(rSource, "DMGTYPE", {});
			end
		end
		local aAddTypes = {};
		for _,v in ipairs(aEffects) do
			for _,v2 in ipairs(v.remainder) do
				if StringManager.contains(DataCommon.dmgtypes, v2) then
					table.insert(aAddTypes, v2);
				end
			end
		end
		if #aAddTypes > 0 then
			for _,vClause in ipairs(rRoll.clauses) do
				local aSplitTypes = StringManager.split(vClause.dmgtype, ",", true);
				for _,v2 in ipairs(aAddTypes) do
					if not StringManager.contains(aSplitTypes, v2) then
						if vClause.dmgtype ~= "" then
							vClause.dmgtype = vClause.dmgtype .. "," .. v2;
						else
							vClause.dmgtype = v2;
						end
					end
				end
			end
		end
		
		-- Apply condition modifiers
		if rRoll.sType ~= "spdamage" then
			if EffectManager35E.hasEffectCondition(rSource, "Sickened") then
				rRoll.nMod = rRoll.nMod - 2;
				nEffectMod = nEffectMod - 2;
				bEffects = true;
			end
			if EffectManager35E.hasEffect(rSource, "Incorporeal") and rRoll.range == "M" and not string.match(string.lower(rRoll.sDesc), "incorporeal touch") then
				bEffects = true;
				table.insert(aAddDesc, "[INCORPOREAL]");
			end
		end
	end
	
	-- Handle half damage
	local bHalf = ModifierStack.getModifierKey("DMG_HALF");
	if bHalf then
		table.insert(aAddDesc, "[HALF]");
	end
	
	-- Add note about effects
	if bEffects then
		local sEffects = "";
		local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true);
		if sMod ~= "" then
			sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
		else
			sEffects = "[" .. Interface.getString("effects_tag") .. "]";
		end
		table.insert(aAddDesc, sEffects);
	end
	
	-- Add notes to roll description
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end

	-- Add damage type info to roll description
	encodeDamageTypes(rRoll);
end

function onDamageRoll(rSource, rRoll)
	-- Set up for meta damage processing
	local bMaximize = rRoll.sDesc:match(" %[MAXIMIZE%]");
	local bEmpower = rRoll.sDesc:match(" %[EMPOWER%]");
	
	-- Apply maximize meta damage
	if bMaximize then
		for _, v in ipairs(rRoll.aDice) do
			local nDieSides = tonumber(v.type:match("[dgpr](%d+)")) or 0;
			if nDieSides > 0 then
				v.result = nDieSides;
			end
		end
	end
	
	-- Decode damage types
	decodeDamageTypes(rRoll, true);

	-- Apply empower meta damage
	if bEmpower then
		local nEmpowerTotalMod = 0;
		
		for _,vClause in pairs(rRoll.clauses) do
			local nEmpowerMod = math.floor(vClause.nTotal / 2);
			
			nEmpowerTotalMod = nEmpowerTotalMod + nEmpowerMod;
			vClause.modifier = vClause.modifier + nEmpowerMod;
			vClause.nTotal = vClause.nTotal + nEmpowerMod;
			rRoll.nMod = rRoll.nMod + nEmpowerMod;
		end

		local sReplace = string.format(" [EMPOWER %+d]", nEmpowerTotalMod);
		rRoll.sDesc = rRoll.sDesc:gsub(" %[EMPOWER%]", sReplace);
	end
	
	-- Handle minimum damage
	local nTotal = ActionsManager.total(rRoll);
	if nTotal <= 0 and rRoll.aDice and #rRoll.aDice > 0 then
		rRoll.sDesc = rRoll.sDesc .. " [MIN DAMAGE]";
		local nMinMod = 1 - nTotal;
		rRoll.nMod = rRoll.nMod + nMinMod;
		
		local bLethal = true;
		local aDamageTypes = {};
		for _,vClause in pairs(rRoll.clauses) do
			local aSplit = StringManager.split(vClause.dmgtype, ",", true);
			for _,vSplit in ipairs(aSplit) do
				if vSplit ~= "" and not StringManager.contains(aDamageTypes, vSplit) then
					table.insert(aDamageTypes, vSplit);
					if vSplit == "nonlethal" then
						bLethal = false;
					end
				end
			end
		end
		local bPFMode = DataCommon.isPFRPG();
		if bPFMode and bLethal then
			table.insert(aDamageTypes, "nonlethal");
		end
		rRoll.clauses = { { dmgtype = table.concat(aDamageTypes, ","), dice = {}, modifier = 1, nTotal = 1 } };
	end
	
	-- Encode the damage results for damage application and readability
	encodeDamageText(rRoll);
end

function onDamage(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");
	rMessage.text = string.gsub(rMessage.text, " %[MULT:[^]]*%]", "");

	local nTotal = ActionsManager.total(rRoll);
	
	-- Send the chat message
	local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		bShowMsg = false;
	end
	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end
	
	-- Apply damage to the PC or CT entry referenced
	-- KEL Apply first Fortification roll if avalaible
	local bDice = {};
	local isFortif = false;
	-- local bImmune = {};
	local bSImmune = {};
	-- local bFortif = {};
	local bSFortif = {};
	local MaxFortifMod = {};
	local bPFMode = DataCommon.isPFRPG();
	local rDamageOutput = decodeDamageText(nTotal, rMessage.text);
	if rTarget then
		local aImmune = EffectManager35E.getEffectsBonusByType(rTarget, "IMMUNE", false, {}, rSource);
		local aFortif = EffectManager35E.getEffectsBonusByType(rTarget, "FORTIF", false, {}, rSource);
		local bApplyIncorporeal = false;
		local bSourceIncorporeal = false;
		if string.match(rDamageOutput.sOriginal, "%[INCORPOREAL%]") then
			bSourceIncorporeal = true;
		end
		local bTargetIncorporeal = EffectManager35E.hasEffect(rTarget, "Incorporeal");
		if bTargetIncorporeal and not bSourceIncorporeal then
			bApplyIncorporeal = true;
			if bPFMode then
				aImmune["critical"] = true;
			end
		end
		for k, v in pairs(rDamageOutput.aDamageTypes) do
			MaxFortifMod[k] = 0;
		end
		for k, v in pairs(rDamageOutput.aDamageTypes) do
			-- GET THE INDIVIDUAL DAMAGE TYPES FOR THIS ENTRY (EXCLUDING UNTYPED DAMAGE TYPE)
			local aSrcDmgClauseTypes = {};
			local aTemp = StringManager.split(k, ",", true);
			for i = 1, #aTemp do
				if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
					table.insert(aSrcDmgClauseTypes, aTemp[i]);
				end
			end
			if #aSrcDmgClauseTypes > 0 then
				local nBasicDmgTypeMatchesFortif = 0;
				local nBasicDmgTypeMatches = 0;
				local nSpecialDmgTypes = 0;
				local nSpecialDmgTypeMatches = 0;
				local nSpecialDmgTypeMatchesFortif = 0;
				-- bImmune["all"] = false;
				bSImmune["all"] = "false";
				-- bFortif["all"] = false;
				bSFortif["all"] = "false";
				if aImmune["all"] then
					-- bImmune["all"] = true;
					bSImmune["all"] = "true";
				end
				if aFortif["all"] then
					-- bFortif["all"] = true;
					bSFortif["all"] = "true";
				end
				-- bImmune[k] = false;
				bSImmune[k] = "false";
				-- bFortif[k] = false;
				bSFortif[k] = "false";
				for _,sDmgType in pairs(aSrcDmgClauseTypes) do
					if StringManager.contains(DataCommon.basicdmgtypes, sDmgType) then
						if aImmune[sDmgType] then nBasicDmgTypeMatches = nBasicDmgTypeMatches + 1; end
						if aFortif[sDmgType] then nBasicDmgTypeMatchesFortif = nBasicDmgTypeMatchesFortif + 1; end
					else
						nSpecialDmgTypes = nSpecialDmgTypes + 1;
						if aImmune[sDmgType] then nSpecialDmgTypeMatches = nSpecialDmgTypeMatches + 1; end
						if aFortif[sDmgType] then nSpecialDmgTypeMatchesFortif = nSpecialDmgTypeMatchesFortif + 1; end
					end
				end
				if (nSpecialDmgTypeMatches > 0) then
					-- bImmune[k] = true;
					bSImmune[k] = "true";
				elseif (nBasicDmgTypeMatches > 0) and (nBasicDmgTypeMatches + nSpecialDmgTypes) == #aSrcDmgClauseTypes then
					-- bImmune[k] = true;
					bSImmune[k] = "true";
				end
				if (nSpecialDmgTypeMatchesFortif > 0) then
					-- bFortif[k] = true;
					bSFortif[k] = "true";
					for _,sDmgType in pairs(aSrcDmgClauseTypes) do
						if not StringManager.contains(DataCommon.basicdmgtypes, sDmgType) and aFortif[sDmgType] then
							MaxFortifMod[k] = math.max(MaxFortifMod[k], aFortif[sDmgType].mod);
						end
					end
				end
				if (nBasicDmgTypeMatchesFortif > 0) and (nBasicDmgTypeMatchesFortif + nSpecialDmgTypes) == #aSrcDmgClauseTypes then
					-- bFortif[k] = true;
					bSFortif[k] = "true";
					for _,sDmgType in pairs(aSrcDmgClauseTypes) do
						if StringManager.contains(DataCommon.basicdmgtypes, sDmgType) and aFortif[sDmgType] then
							MaxFortifMod[k] = math.max(MaxFortifMod[k], aFortif[sDmgType].mod);
						end
					end
				end
				-- local FortifApplied = false;
				if bSFortif[k] == "true" and not aFortif["all"] and bSImmune[k] == "false" and not aImmune["all"] then
					table.insert(bDice, "d100");
					table.insert(bDice, "d10");
					isFortif = true;
					-- FortifApplied = true;
				end
				if aFortif["all"] and not aImmune["all"] and bSImmune[k] == "false" then
					table.insert(bDice, "d100");
					table.insert(bDice, "d10");
					isFortif = true;
					MaxFortifMod[k] = math.max(MaxFortifMod[k], aFortif["all"].mod);
				end
			end
		end
	end
	-- KEL add information about IMMUNE and FORTIF to the standard way! (otherwise these effects can not be skipped anymore etc)
	if not isFortif then
		notifyApplyDamage(rSource, rTarget, rRoll.bTower, rRoll.sType, rMessage.text, nTotal, bSImmune, bSFortif);
	else
		local aRollFortif = { sType = "fortification", aDice = bDice, nMod = 0, bTower = rRoll.bTower, aType = rRoll.sType, aMessagetext = rMessage.text, aTotal = nTotal};
		if rTarget then
			for k, v in pairs(rDamageOutput.aDamageTypes) do
				local l = "KELFORTIF " .. k;
				local m = "KELFORTIFMOD " .. k;
				local aSrcDmgClauseTypes = {};
				local aTemp = StringManager.split(k, ",", true);
				for i = 1, #aTemp do
					if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
						table.insert(aSrcDmgClauseTypes, aTemp[i]);
					end
				end
				if #aSrcDmgClauseTypes > 0 then
					aRollFortif.ImmuneAll = bSImmune["all"];
					aRollFortif.FortifAll = bSFortif["all"];
					aRollFortif[k] = bSImmune[k];
					aRollFortif[l] = bSFortif[k];
					aRollFortif[m] = MaxFortifMod[k];
				end
			end
		end
		ActionsManager.roll(rSource, rTarget, aRollFortif);
	end
end 

function onStabilization(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local bSuccess = GameSystem.getStabilizationResult(rRoll);
	if bSuccess then
		rMessage.text = rMessage.text .. " [SUCCESS]";
	else
		rMessage.text = rMessage.text .. " [FAILURE]";
	end
	
	Comm.deliverChatMessage(rMessage);

	if bSuccess then
		local aEffect = { sName = "Stable", nDuration = 0 };
		if ActorManager.getFaction(rSource) ~= "friend" then
			aEffect.nGMOnly = 1;
		end
		EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), aEffect, true);
	else
		applyFailedStabilization(rSource);
	end
end

--
-- UTILITY FUNCTIONS
--

function encodeDamageTypes(rRoll)
	for _,vClause in ipairs(rRoll.clauses) do
		local sDice = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
		rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s) (%s) (%s) (%s) (%s)]", vClause.dmgtype, sDice, vClause.mult or 2, vClause.stat or "", vClause.statmax or 0, vClause.statmult or 1);
	end
end

function decodeDamageTypes(rRoll, bFinal)
	-- Process each type clause in the damage description as encoded previously
	local nMainDieIndex = 0;
	rRoll.clauses = {};
	for sDmgType, sDmgDice, sDmgMult, sDmgStat, sDmgStatMax, sDmgStatMult in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%) %(([^)]*)%) %(([^)]*)%) %(([^)]*)%) %(([^)]*)%)%]") do
		local rClause = {};
		rClause.dmgtype = StringManager.trim(sDmgType);
		rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDmgDice);
		rClause.mult = tonumber(sDmgMult) or 2;
		rClause.stat = sDmgStat;
		rClause.statmax = tonumber(sDmgStatMax) or 0;
		rClause.statmult = tonumber(sDmgStatMult) or 1;
		
		rClause.nTotal = rClause.modifier;
		for _,vDie in ipairs(rClause.dice) do
			nMainDieIndex = nMainDieIndex + 1;
			rClause.nTotal = rClause.nTotal + (rRoll.aDice[nMainDieIndex].result or 0);
		end
		
		table.insert(rRoll.clauses, rClause);
	end
	
	-- Handle rolls that went straight to roll without going through whole system (i.e. ongoing damage, regen, fast heal, etc.)
	local nClauses = #(rRoll.clauses);
	if nClauses == 0 then
		for sDamageType in rRoll.sDesc:gmatch("%[TYPE: ([^%]]+)%]") do
			local sDmgType = StringManager.trim(sDamageType:match("^([^(%]]+)"));
			local sDmgDice, sTotal = sDamageType:match("%(([%d%+%-Dd]+)%=(%d+)%)");
			if not sDmgDice then
				sTotal = sDamageType:match("%((%d+)%)")
			end
			
			local rClause = {};
			rClause.dmgtype = StringManager.trim(sDmgType);
			rClause.dice = {};
			rClause.modifier = tonumber(sTotal) or ActionsManager.total(rRoll);
			rClause.mult = 2;
			rClause.stat = "";
			rClause.statmax = 0;
			rClause.statmult = 1;
			
			rClause.nTotal = rClause.modifier;
			
			table.insert(rRoll.clauses, rClause);
		end
	end
	
	-- Handle drag results that are halved or doubled
	if #(rRoll.aDice) == 0 then
		local nResultTotal = 0;
		for i = nClauses + 1, #(rRoll.clauses) do
			nResultTotal = rRoll.clauses[i].nTotal;
		end
		if nResultTotal > 0 and nResultTotal ~= rRoll.nMod then
			if math.floor(nResultTotal / 2) == rRoll.nMod then
				for _,vClause in ipairs(rRoll.clauses) do
					vClause.modifier = math.floor(vClause.modifier / 2);
					vClause.nTotal = math.floor(vClause.nTotal / 2);
				end
			elseif nResultTotal * 2 == rRoll.nMod then
				for _,vClause in ipairs(rRoll.clauses) do
					vClause.modifier = 2 * vClause.modifier;
					vClause.nTotal = 2 * vClause.nTotal;
				end
			end
		end
	end
	
	-- Remove damage type information from roll description
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE:[^]]*%]", "");
	
	if bFinal then
		-- Capture any manual modifiers and adjust damage types accordingly
		-- NOTE: Positive values are added to first damage clause, Negative values reduce damage clauses until none remain
		local nFinalTotal = ActionsManager.total(rRoll);
		local nClausesTotal = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nClausesTotal = nClausesTotal + vClause.nTotal;
		end
		if nFinalTotal ~= nClausesTotal then
			local nRemainder = nFinalTotal - nClausesTotal;
			if nRemainder > 0 then
				if #(rRoll.clauses) == 0 then
					table.insert(rRoll.clauses, { dmgtype = "", stat = "", dice = {}, modifier = nRemainder, nTotal = nRemainder})
				else
					rRoll.clauses[1].modifier = rRoll.clauses[1].modifier + nRemainder;
					rRoll.clauses[1].nTotal = rRoll.clauses[1].nTotal + nRemainder;
				end
			else
				for _,vClause in ipairs(rRoll.clauses) do
					if vClause.nTotal >= -nRemainder then
						vClause.modifier = vClause.modifier + nRemainder;
						vClause.nTotal = vClause.nTotal + nRemainder;
						break;
					else
						vClause.modifier = vClause.modifier - vClause.nTotal;
						nRemainder = nRemainder + vClause.nTotal;
						vClause.nTotal = 0;
					end
				end
			end
		end
	end
end

function getDamageTypesFromString(sDamageTypes)
	local sLower = string.lower(sDamageTypes);
	local aSplit = StringManager.split(sLower, ",", true);
	
	local aDamageTypes = {};
	for k, v in ipairs(aSplit) do
		if StringManager.contains(DataCommon.dmgtypes, v) then
			table.insert(aDamageTypes, v);
		end
	end
	
	return aDamageTypes;
end

--
-- DAMAGE APPLICATION
--

function getParenDepth(sText, nIndex)
	local nDepth = 0;
	
	local cStart = string.byte("(");
	local cEnd = string.byte(")");
	
	for i = 1, nIndex do
		local cText = string.byte(sText, i);
		if cText == cStart then
			nDepth = nDepth + 1;
		elseif cText == cEnd then
			nDepth = nDepth - 1;
		end
	end
	
	return nDepth;
end

function decodeAndOrClauses(sText)
	local nIndexOR;
	local nStartOR, nEndOR, nStartAND, nEndAND;
	local nStartOR2, nEndOR2;
	local nParen;
	local sPhraseOR;

	local aClausesOR = {};
	local aSkipOR = {};
	local nIndexOR = 1;
	while nIndexOR < #sText do
		local nTempIndex = nIndexOR;
		repeat
			nParen = 0;
			nStartOR, nEndOR = string.find(sText, "%s+or%s+", nTempIndex);
			nStartOR2, nEndOR2 = string.find(sText, "%s*;%s*", nTempIndex);
			
			if nStartOR2 and (not nStartOR or nStartOR > nStartOR2) then
				nStartOR = nStartOR2;
				nEndOR = nEndOR2;
			end
			
			if nStartOR then
				nParen = getParenDepth(sText, nStartOR);
				if nParen ~= 0 then
					nTempIndex = nEndOR + 1;
				end
			end
		until not nStartOR or nParen == 0;
		
		if nStartOR then
			sPhraseOR = string.sub(sText, nIndexOR, nStartOR - 1);
		else
			sPhraseOR = string.sub(sText, nIndexOR);
		end

		local aClausesAND = {};
		local aSkipAND = {};
		local nIndexAND = 1;
		while nIndexAND < #sPhraseOR do
			nTempIndex = nIndexAND;
			repeat
				nParen = 0;
				nStartAND, nEndAND = string.find(sPhraseOR, "%s+and%s+", nTempIndex);
				
				if nStartAND then
					nParen = getParenDepth(sText, nIndexOR + nStartAND);
					if nParen ~= 0 then
						nTempIndex = nEndAND + 1;
					end
				end
			until not nStartAND or nParen == 0;
			
			if nStartAND then
				table.insert(aClausesAND, string.sub(sPhraseOR, nIndexAND, nStartAND - 1));
				nIndexAND = nEndAND + 1;
				table.insert(aSkipAND, nEndAND - nStartAND + 1);
			else
				table.insert(aClausesAND, string.sub(sPhraseOR, nIndexAND));
				nIndexAND = #sPhraseOR;
				if nStartOR then
					table.insert(aSkipAND, nEndOR - nStartOR + 1);
				else
					table.insert(aSkipAND, 0);
				end
			end
		end
		
		if nStartOR then
			nIndexOR = nEndOR + 1;
		else
			nIndexOR = #sText;
		end

		table.insert(aClausesOR, aClausesAND);
		table.insert(aSkipOR, aSkipAND);
	end
	
	return aClausesOR, aSkipOR;
end

function matchAndOrClauses(aClausesOR, aMatchWords)
	for kClauseOR, aClausesAND in ipairs(aClausesOR) do
		local bMatchAND = true;
		local nMatchAND = 0;

		for kClauseAND, sClause in ipairs(aClausesAND) do
			nMatchAND = nMatchAND + 1;

			if not StringManager.contains(aMatchWords, sClause) then
				bMatchAND = false;
				break;
			end
		end
		
		if bMatchAND and nMatchAND > 0 then
			return true;
		end
	end
		
	return false;
end
-- KEL bImmune, bFortif
function getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput, bImmune, bFortif)
	-- SETUP
	local nDamageAdjust = 0;
	local nNonlethal = 0;
	local bVulnerable = false;
	local bResist = false;
	local aWords;
	local bPFMode = DataCommon.isPFRPG();
	-- KEL Removing IMMUNE here since called earlier
	-- GET THE DAMAGE ADJUSTMENT EFFECTS
	-- local aImmune = EffectManager35E.getEffectsBonusByType(rTarget, "IMMUNE", false, {}, rSource);
	local aVuln = EffectManager35E.getEffectsBonusByType(rTarget, "VULN", false, {}, rSource);
	local aResist = EffectManager35E.getEffectsBonusByType(rTarget, "RESIST", false, {}, rSource);
	-- KEL Adding HRESIST and FORTIF
	local aHResist = EffectManager35E.getEffectsBonusByType(rTarget, "HRESIST", false, {}, rSource);
	-- local aFortif = EffectManager35E.getEffectsBonusByType(rTarget, "FORTIF", false, {}, rSource);
	local aDR = EffectManager35E.getEffectsByType(rTarget, "DR", {}, rSource);
	
	-- local bApplyIncorporeal = false;
	-- local bSourceIncorporeal = false;
	-- if string.match(rDamageOutput.sOriginal, "%[INCORPOREAL%]") then
		-- bSourceIncorporeal = true;
	-- end
	-- local bTargetIncorporeal = EffectManager35E.hasEffect(rTarget, "Incorporeal");
	-- if bTargetIncorporeal and not bSourceIncorporeal then
		-- bApplyIncorporeal = true;
		-- if bPFMode then
			-- bImmune["critical"] = true;
		-- end
	-- end
	
	-- IF IMMUNE ALL, THEN JUST HANDLE IT NOW
	-- KEL Also for FORTIF
	if bImmune["all"] then
		return (0 - nDamage), 0, false, true;
	end
	-- if aFortif["all"] then
		-- return (0 - nDamage), 0, false, true;
	-- end
	-- if aFortif[""] then
		-- return (0 - nDamage), 0, false, true;
	-- end
	
	-- HANDLE REGENERATION
	if not bPFMode then
		local aRegen = EffectManager35E.getEffectsBonusByType(rTarget, "REGEN", false, {});
		local nRegen = 0;
		for _, _ in pairs(aRegen) do
			nRegen = nRegen + 1;
		end
		if nRegen > 0 then
			local aRemap = {};
			for k,v in pairs(rDamageOutput.aDamageTypes) do
				local bCheckRegen = true;
				
				local aSrcDmgClauseTypes = {};
				local aTemp = StringManager.split(k, ",", true);
				for i = 1, #aTemp do
					if aTemp[i] == "nonlethal" then
						bCheckRegen = false;
						break;
					elseif aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
						table.insert(aSrcDmgClauseTypes, aTemp[i]);
					end
				end

				if bCheckRegen then
					local bMatchAND, nMatchAND, bMatchDMG, aClausesOR;
					local bApplyRegen;
					for _,vRegen in pairs(aRegen) do
						bApplyRegen = true;
						
						local sRegen = table.concat(vRegen.remainder, " ");
						
						aClausesOR = decodeAndOrClauses(sRegen);
						if matchAndOrClauses(aClausesOR, aSrcDmgClauseTypes) then
							bApplyRegen = false;
						end
						
						if bApplyRegen then
							local kNew = table.concat(aSrcDmgClauseTypes, ",");
							if kNew ~= "" then
								kNew = kNew .. ",nonlethal";
							else
								kNew = "nonlethal";
							end
							aRemap[k] = kNew;
						end
					end
				end
			end
			for k,v in pairs(aRemap) do
				rDamageOutput.aDamageTypes[v] = rDamageOutput.aDamageTypes[k];
				rDamageOutput.aDamageTypes[k] = nil;
			end
		end
	end
	-- NKEL Define total damager per damage type (e.g. for rounding corrections in VULN and HRESIST) Therefore following for loop outside the big loop,
	-- local nDmgTotalperType = {};
	-- for k, v in pairs(rDamageOutput.aDamageTypes) do
		-- GET THE INDIVIDUAL DAMAGE TYPES FOR THIS ENTRY (EXCLUDING UNTYPED DAMAGE TYPE)
		-- local aSrcDmgClauseTypes = {};
		-- local aTemp = StringManager.split(k, ",", true);
		-- for i = 1, #aTemp do
			-- if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
				-- table.insert(aSrcDmgClauseTypes, aTemp[i]);
			-- end
		-- end
		-- if #aSrcDmgClauseTypes > 0 then
			-- for _,sDmgType in pairs(aSrcDmgClauseTypes) do	
				-- nDmgTotalperType[sDmgType] = 0;
			-- end
		-- end
	-- end
	-- NKEL Collect damage per type and make sure to avoid double counting (in very very rare situations using DMG effect with special damage type; when one is not careful one might have a damage type twice)
	-- KEL Variables for rounding corrections of VULN and HRESIST when multiple dice are affected (and incorp). Handle each damage type separately (?) for minimizing damage and according to the definition of vulnerability which is specific to the damage type
	local roundingvariableVulnCeil = {};
	roundingvariableVulnCeil["all"] = false;
	local roundingvariableHResistFloor = {};
	roundingvariableHResistFloor["all"] = false;
	local roundingvariableIncorpFloor = false;
	for k, v in pairs(rDamageOutput.aDamageTypes) do
		-- GET THE INDIVIDUAL DAMAGE TYPES FOR THIS ENTRY (EXCLUDING UNTYPED DAMAGE TYPE)
		local aSrcDmgClauseTypes = {};
		local aTemp = StringManager.split(k, ",", true);
		for i = 1, #aTemp do
			if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
				table.insert(aSrcDmgClauseTypes, aTemp[i]);
			end
		end
		if #aSrcDmgClauseTypes > 0 then
			local DMGAccounted = {};
			for _,sDmgType in pairs(aSrcDmgClauseTypes) do
				-- DMGAccounted[sDmgType] = false;
				roundingvariableVulnCeil[sDmgType] = false;
				roundingvariableHResistFloor[sDmgType] = false;
			end
			-- for _,sDmgType in pairs(aSrcDmgClauseTypes) do	
				-- if not DMGAccounted[sDmgType] then
					-- nDmgTotalperType[sDmgType] = nDmgTotalperType[sDmgType] + v;
					-- DMGAccounted[sDmgType] = true;
				-- end
			-- end
		end
	end
	-- ITERATE THROUGH EACH DAMAGE TYPE ENTRY
	local nVulnApplied = 0;
	for k, v in pairs(rDamageOutput.aDamageTypes) do
		-- GET THE INDIVIDUAL DAMAGE TYPES FOR THIS ENTRY (EXCLUDING UNTYPED DAMAGE TYPE)
		local aSrcDmgClauseTypes = {};
		local bHasEnergyType = false;
		local aTemp = StringManager.split(k, ",", true);
		for i = 1, #aTemp do
			if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
				table.insert(aSrcDmgClauseTypes, aTemp[i]);
				if not bHasEnergyType and (StringManager.contains(DataCommon.energytypes, aTemp[i]) or (aTemp[i] == "spell")) then
					bHasEnergyType = true;
				end
			end
		end

		-- HANDLE IMMUNITY, VULNERABILITY AND RESISTANCE
		-- KEL Order change; added FORTIF, HRESIST
		local nLocalDamageAdjust = 0;
		if #aSrcDmgClauseTypes > 0 then
			-- CHECK FOR IMMUNITY (Must be immune to all damage types in damage source)
			-- KEL FORTIF, HRESIST, RESIST now work like IMMUNE w.r.t. to damage types (see 3.3.7 patch notes)
			-- KEL IMMUNE and FORTIF handled earlier; removing its part
			-- local nBasicDmgTypeMatches = 0;
			-- local nBasicDmgTypeMatchesFortif = 0;
			local nBasicDmgTypeMatchesHResist = 0;
			
			local nSpecialDmgTypes = 0;
			-- local nSpecialDmgTypeMatches = 0;
			-- local nSpecialDmgTypeMatchesFortif = 0;
			local nSpecialDmgTypeMatchesHResist = 0;
			
			for _,sDmgType in pairs(aSrcDmgClauseTypes) do
				if StringManager.contains(DataCommon.basicdmgtypes, sDmgType) then
					-- if aImmune[sDmgType] then nBasicDmgTypeMatches = nBasicDmgTypeMatches + 1; end
					-- if aFortif[sDmgType] then nBasicDmgTypeMatchesFortif = nBasicDmgTypeMatchesFortif + 1; end
					if aHResist[sDmgType] then nBasicDmgTypeMatchesHResist = nBasicDmgTypeMatchesHResist + 1; end
				else
					nSpecialDmgTypes = nSpecialDmgTypes + 1;
					-- if aImmune[sDmgType] then nSpecialDmgTypeMatches = nSpecialDmgTypeMatches + 1; end
					-- if aFortif[sDmgType] then nSpecialDmgTypeMatchesFortif = nSpecialDmgTypeMatchesFortif + 1; end
					if aHResist[sDmgType] then nSpecialDmgTypeMatchesHResist = nSpecialDmgTypeMatchesHResist + 1; end
				end
			end
			-- local bImmune = false;
			-- local bFortif = false;
			local bHResist = false;
			-- if (nSpecialDmgTypeMatches > 0) then
				-- bImmune = true;
			-- elseif (nBasicDmgTypeMatches > 0) and (nBasicDmgTypeMatches + nSpecialDmgTypes) == #aSrcDmgClauseTypes then
				-- bImmune = true;
			-- end
			-- if (nSpecialDmgTypeMatchesFortif > 0) then
				-- bFortif = true;
			-- elseif (nBasicDmgTypeMatchesFortif > 0) and (nBasicDmgTypeMatchesFortif + nSpecialDmgTypes) == #aSrcDmgClauseTypes then
				-- bFortif = true;
			-- end
			if (nSpecialDmgTypeMatchesHResist > 0) then
				bHResist = true;
			elseif (nBasicDmgTypeMatchesHResist > 0) and (nBasicDmgTypeMatchesHResist + nSpecialDmgTypes) == #aSrcDmgClauseTypes then
				bHResist = true;
			end
			if bImmune[k] then
				nLocalDamageAdjust = nLocalDamageAdjust - v;
				bResist = true;
			elseif bFortif[k] then
				nLocalDamageAdjust = nLocalDamageAdjust - v;
				bResist = true;	
			else
				if aHResist["all"] then
					local nHresistAmount = 0;
					if not roundingvariableHResistFloor["all"] then
						nHresistAmount = math.ceil((v + nLocalDamageAdjust) / 2);
						if (v + nLocalDamageAdjust) % 2 ~= 0 then
							roundingvariableHResistFloor["all"] = true;
						end
					else
						nHresistAmount = math.floor((v + nLocalDamageAdjust) / 2);
						if (v + nLocalDamageAdjust) % 2 ~= 0 then
							roundingvariableHResistFloor["all"] = false;
						end
					end
					nLocalDamageAdjust = nLocalDamageAdjust - nHresistAmount;
					bResist = true;		
					-- aHResist["all"].nApplied = math.ceil((nDamage + nLocalDamageAdjust) / 2);
				end
				-- KEL HResist vs DMGTYPE; beware corrections for rounding over multiple affected dice (change rounding of odd number involved)
				local HResistApplied = false;
				for _,sDmgType in pairs(aSrcDmgClauseTypes) do
					if aHResist[sDmgType] and bHResist and not aHResist["all"] and not HResistApplied then
						HResistApplied = true;
						local nHresistAmount = 0;
						if not roundingvariableHResistFloor[sDmgType] then
							nHresistAmount = math.ceil((v + nLocalDamageAdjust) / 2);
							if (v + nLocalDamageAdjust) % 2 ~= 0 then
								roundingvariableHResistFloor[sDmgType] = true;
							end
						else
							nHresistAmount = math.floor((v + nLocalDamageAdjust) / 2);
							if (v + nLocalDamageAdjust) % 2 ~= 0 then
								roundingvariableHResistFloor[sDmgType] = false;
							end
						end
						nLocalDamageAdjust = nLocalDamageAdjust - nHresistAmount;
						bResist = true;	
					end
				end
			end
		end
		-- KEL breaking the if clause here to correct the order of DR and Incorp (always minimizing damage as rule)
		-- Thus, be careful with local variables
		
		-- HANDLE INCORPOREAL (PF MODE)
		-- KEL Also here rounding errors; also adding ghost touch
		if bApplyIncorporeal and (v + nLocalDamageAdjust) > 0 then
			local bIgnoreDamage = true;
			local bApplyIncorporeal2 = true;
			for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
				if sDmgType == "force" then
					bApplyIncorporeal2 = false;
				elseif sDmgType == "ghost touch" then
					bApplyIncorporeal2 = false;
				elseif sDmgType == "spell" or sDmgType == "magic" then
					bIgnoreDamage = false;
				end
			end
			if bApplyIncorporeal2 then
				if bIgnoreDamage then
					nLocalDamageAdjust = -v;
					bResist = true;
				elseif bPFMode then
					if not roundingvariableIncorpFloor then
						if (v + nLocalDamageAdjust) % 2 ~= 0 then
							roundingvariableIncorpFloor = true;
						end
						nLocalDamageAdjust = nLocalDamageAdjust - math.ceil((v + nLocalDamageAdjust) / 2);
					else
						if (v + nLocalDamageAdjust) % 2 ~= 0 then
							roundingvariableIncorpFloor = false;
						end
						nLocalDamageAdjust = nLocalDamageAdjust - math.floor((v + nLocalDamageAdjust) / 2);
					end
					bResist = true;
				end
			end
		end
		
		-- HANDLE DR  (FORM: <type> and <type> or <type> and <type>)
		if not bHasEnergyType and (v + nLocalDamageAdjust) > 0 then
			local bMatchAND, nMatchAND, bMatchDMG, aClausesOR;
			
			local bApplyDR;
			for _,vDR in pairs(aDR) do
				local kDR = table.concat(vDR.remainder, " ");
				
				if kDR == "" or kDR == "-" or kDR == "all" then
					bApplyDR = true;
				else
					bApplyDR = true;
					aClausesOR = decodeAndOrClauses(kDR);
					if matchAndOrClauses(aClausesOR, aSrcDmgClauseTypes) then
						bApplyDR = false;
					end
				end

				if bApplyDR then
					local nApplied = vDR.nApplied or 0;
					if nApplied < vDR.mod then
						local nChange = math.min((vDR.mod - nApplied), v + nLocalDamageAdjust);
						vDR.nApplied = nApplied + nChange;
						nLocalDamageAdjust = nLocalDamageAdjust - nChange;
						bResist = true;
					end
				end
			end
		end
		
		-- KEL going back to the initial if clause
		if #aSrcDmgClauseTypes > 0 then
			if not bImmune[k] and not bFortif[k] then
				local MaxResistMod = 0;
				local nSpecialDmgTypes = 0;
				local nBasicDmgTypeMatchesResist = 0;
				local nSpecialDmgTypeMatchesResist = 0;
				for _,sDmgType in pairs(aSrcDmgClauseTypes) do
					if StringManager.contains(DataCommon.basicdmgtypes, sDmgType) then
						if aResist[sDmgType] then nBasicDmgTypeMatchesResist = nBasicDmgTypeMatchesResist + 1; end
					else
						nSpecialDmgTypes = nSpecialDmgTypes + 1;
						if aResist[sDmgType] then nSpecialDmgTypeMatchesResist = nSpecialDmgTypeMatchesResist + 1; end
					end
				end
				local cResist = false;
				if (nSpecialDmgTypeMatchesResist > 0) then
					cResist = true;
					for _,sDmgType in pairs(aSrcDmgClauseTypes) do
						if not StringManager.contains(DataCommon.basicdmgtypes, sDmgType) and aResist[sDmgType] then
							MaxResistMod = math.max(MaxResistMod, aResist[sDmgType].mod);
						end
					end
				end
				if (nBasicDmgTypeMatchesResist > 0) and (nBasicDmgTypeMatchesResist + nSpecialDmgTypes) == #aSrcDmgClauseTypes then
					cResist = true;
					for _,sDmgType in pairs(aSrcDmgClauseTypes) do
						if StringManager.contains(DataCommon.basicdmgtypes, sDmgType) and aResist[sDmgType] then
							MaxResistMod = math.max(MaxResistMod, aResist[sDmgType].mod);
						end
					end
				end
				-- CHECK RESISTANCE TO DAMAGE TYPE
				-- KEL Rewriting that such that Resist- all etc. is not ignored for fire damage when Resist fire is there, too. Beware stacking.
				-- KEL Also avoid stacking of Resist slashing and piercing against daggers and so on
				local ResistApplied = false;
				for _,sDmgType in pairs(aSrcDmgClauseTypes) do
					if aResist[sDmgType] and cResist and not ResistApplied then
						local nApplied = aResist[sDmgType].nApplied or 0;
						ResistApplied = true;
						if nApplied < MaxResistMod then
							local nChange = math.min((MaxResistMod - nApplied), v + nLocalDamageAdjust);
							aResist[sDmgType].nApplied = nApplied + nChange;
							nLocalDamageAdjust = nLocalDamageAdjust - nChange;
							bResist = true;
						end
					end
					-- CHECK RESIST ALL
					local HandleAll = true;
					if aResist["all"] and aResist[""] then						
						if aResist["all"].mod < aResist[""].mod then
							HandleAll = false;
						end
					elseif not aResist["all"] and aResist[""] then
						HandleAll = false;
					end
					if aResist["all"] and HandleAll then
						local nApplied = aResist["all"].nApplied or 0;
						local HandleStacking = true;
						if aResist[sDmgType] and cResist then
							if aResist["all"].mod < MaxResistMod then
								HandleStacking = false;
							end
							local AlreadyApplied = aResist[sDmgType].nApplied or 0;
							nApplied = nApplied + AlreadyApplied;
						end
						if nApplied < aResist["all"].mod and HandleStacking then
							local nChange = math.min((aResist["all"].mod - nApplied), v + nLocalDamageAdjust);
							aResist["all"].nApplied = nApplied + nChange;
							nLocalDamageAdjust = nLocalDamageAdjust - nChange;
							ResistApplied = true;
							bResist = true;
						end
					end
					if aResist[""] and not HandleAll then
						local nApplied = aResist[""].nApplied or 0;
						local HandleStacking = true;
						if aResist[sDmgType] and cResist then
							if aResist[""].mod < MaxResistMod then
								HandleStacking = false;
							end
							local AlreadyApplied = aResist[sDmgType].nApplied or 0;
							nApplied = nApplied + AlreadyApplied;
						end
						if nApplied < aResist[""].mod and HandleStacking then
							local nChange = math.min((aResist[""].mod - nApplied), v + nLocalDamageAdjust);
							aResist[""].nApplied = nApplied + nChange;
							nLocalDamageAdjust = nLocalDamageAdjust - nChange;
							ResistApplied = true;
							bResist = true;
						end
					end
				end
				
				-- CHECK VULN TO DAMAGE TYPES
				-- KEL nLocalDamageAdjust in nVulnAmount and VULN fix, stacking and blah fix
				-- KEL Note/Beware: VULN: (N) overwrites VULN with no number; added VULN: all which overwrites all
				local FiniteMaxMod = 0;
				for _,sDmgType in pairs(aSrcDmgClauseTypes) do
					if aVuln[sDmgType] then
						FiniteMaxMod = math.max(FiniteMaxMod, aVuln[sDmgType].mod);
					end
				end
				if aVuln["all"] then
					FiniteMaxMod = math.max(FiniteMaxMod, aVuln["all"].mod);
				end
				if aVuln["all"] then
					local nVulnAmount = 0;
					if aVuln["all"].mod == 0 and not roundingvariableVulnCeil["all"] then
						nVulnAmount = math.floor((v + nLocalDamageAdjust) / 2);
						if (v + nLocalDamageAdjust) % 2 ~= 0 then
							roundingvariableVulnCeil["all"] = true;
						end
					elseif aVuln["all"].mod == 0 and roundingvariableVulnCeil["all"] then
						nVulnAmount = math.ceil((v + nLocalDamageAdjust) / 2);
						if (v + nLocalDamageAdjust) % 2 ~= 0 then
							roundingvariableVulnCeil["all"] = false;
						end
					elseif aVuln["all"].mod ~= 0 and not aVuln["all"].nApplied then
						nVulnAmount = FiniteMaxMod;
					end
					nLocalDamageAdjust = nLocalDamageAdjust + nVulnAmount;
					bVulnerable = true;
					aVuln["all"].nApplied = nVulnAmount;
				end
				local VulnApplied = false;
				for _,sDmgType in pairs(aSrcDmgClauseTypes) do
					if aVuln[sDmgType] and not VulnApplied and not aVuln["all"] then
						VulnApplied = true;
						local nVulnAmount = 0;
						if aVuln[sDmgType].mod == 0 and not roundingvariableVulnCeil[sDmgType] then
							nVulnAmount = math.floor((v + nLocalDamageAdjust) / 2);
							if (v + nLocalDamageAdjust) % 2 ~= 0 then
								roundingvariableVulnCeil[sDmgType] = true;
							end
						elseif aVuln[sDmgType].mod == 0 and roundingvariableVulnCeil[sDmgType] then
							nVulnAmount = math.ceil((v + nLocalDamageAdjust) / 2);
							if (v + nLocalDamageAdjust) % 2 ~= 0 then
								roundingvariableVulnCeil[sDmgType] = false;
							end
						elseif aVuln[sDmgType].mod ~= 0 and not aVuln[sDmgType].nApplied then
							nVulnAmount = FiniteMaxMod;
						end
						nLocalDamageAdjust = nLocalDamageAdjust + nVulnAmount;
						aVuln[sDmgType].nApplied = nVulnAmount;
						bVulnerable = true;
					end
				end
			end
			
			-- CALCULATE NONLETHAL DAMAGE
			local nNonlethalAdjust = 0;
			if (v + nLocalDamageAdjust) > 0 then
				local bNonlethal = false;
				for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
					if sDmgType == "nonlethal" then
						bNonlethal = true;
						break;
					end
				end
				if bNonlethal then
					nNonlethalAdjust = v + nLocalDamageAdjust;
				end
			end

			-- APPLY DAMAGE ADJUSTMENT FROM THIS DAMAGE CLAUSE TO OVERALL DAMAGE ADJUSTMENT
			nDamageAdjust = nDamageAdjust + nLocalDamageAdjust - nNonlethalAdjust;
			nNonlethal = nNonlethal + nNonlethalAdjust;
		end
	end

	-- RESULTS
	return nDamageAdjust, nNonlethal, bVulnerable, bResist;
end

-- KEL Fortification roll
function onFortification(rSource, rTarget, rRoll)
	local rDamageOutput = decodeDamageText(tonumber(rRoll.aTotal), rRoll.aMessagetext);
	local FortifSuccess = {};
	local m = 1;
	local bImmune = {};
	local bFortif = {};
	local MaxFortifMod = {};
	if rTarget then
		for k, v in pairs(rDamageOutput.aDamageTypes) do
			local l = "KELFORTIF " .. k;
			local m = "KELFORTIFMOD " .. k;
			local aSrcDmgClauseTypes = {};
			local aTemp = StringManager.split(k, ",", true);
			for i = 1, #aTemp do
				if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
					table.insert(aSrcDmgClauseTypes, aTemp[i]);
				end
			end
			if #aSrcDmgClauseTypes > 0 then
				bImmune["all"] = rRoll.ImmuneAll;
				bFortif["all"] = rRoll.FortifAll;
				bImmune[k] = rRoll[k];
				bFortif[k] = rRoll[l];
				MaxFortifMod[k] = tonumber(rRoll[m]);
			end
		end
		for k, v in pairs(rDamageOutput.aDamageTypes) do
			local aSrcDmgClauseTypes = {};
			local aTemp = StringManager.split(k, ",", true);
			for i = 1, #aTemp do
				if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
					table.insert(aSrcDmgClauseTypes, aTemp[i]);
				end
			end
			if #aSrcDmgClauseTypes > 0 then
				-- local FortifApplied = false;
				-- for _,sDmgType in pairs(aSrcDmgClauseTypes) do
				if bFortif[k] == "true" and bFortif["all"] == "false" and bImmune[k] == "false" and bImmune["all"] == "false" then
					-- FortifApplied = true;
					local index = {};
					local o = 1;
					for _,n in ipairs(rRoll.aDice) do
						index[n] = o;
						o = o + 1;
					end
					for _,n in ipairs(rRoll.aDice) do
						if index[n] == m then
							local aRoll ={};
							aRoll.sType = rRoll.sType;
							aRoll.aDice = {n};
							aRoll.nMod = rRoll.nMod;
							aRoll.sDesc = "[FORTIFICATION CHANCE " .. MaxFortifMod[k] .. "]" .. "[vs. " .. k .. "]" .. "[to " .. ActorManager.getDisplayName(rTarget) .. "]";
							local rMessage = ActionsManager.createActionMessage(rSource, aRoll);
							if n.result <= MaxFortifMod[k] then
								FortifSuccess[k] = "true";
								rMessage.text = rMessage.text .. "[ZERO DMG]";
								rMessage.icon = "roll_attack_miss";
							else
								FortifSuccess[k] = "false";
								rMessage.text = rMessage.text .. "[FULL DMG]";
								rMessage.icon = "roll_attack_hit";
							end
							Comm.deliverChatMessage(rMessage);
						end
					end
					m = m + 1;
				end
				-- end
				if bFortif["all"] == "true" and bImmune["all"] == "false" and bImmune[k] == "false" then
					local index = {};
					local o = 1;
					for _,n in ipairs(rRoll.aDice) do
						index[n] = o;
						o = o + 1;
					end
					for _,n in ipairs(rRoll.aDice) do
						if index[n] == m then
							local aRoll ={};
							aRoll.sType = rRoll.sType;
							aRoll.aDice = {n};
							aRoll.nMod = rRoll.nMod;
							aRoll.sDesc = "[FORTIFICATION CHANCE " .. MaxFortifMod[k] .. "]" .. "[vs. " .. k .. "]" .. "[to " .. ActorManager.getDisplayName(rTarget) .. "]";
							local rMessage = ActionsManager.createActionMessage(rSource, aRoll);
							if n.result <= MaxFortifMod[k] then
								FortifSuccess[k] = "true";
								rMessage.text = rMessage.text .. "[ZERO DMG]";
								rMessage.icon = "roll_attack_miss";
							else
								FortifSuccess[k] = "false";
								rMessage.text = rMessage.text .. "[FULL DMG]";
								rMessage.icon = "roll_attack_hit";
							end
							Comm.deliverChatMessage(rMessage);
						end
					end
					m = m + 1;
				end
			end
		end
	end
	notifyApplyDamage(rSource, rTarget, rRoll.bTower, rRoll.aType, rRoll.aMessagetext, tonumber(rRoll.aTotal), bImmune, FortifSuccess);
end

-- Collapse damage clauses by damage type (in the original order, if possible)
function getDamageStrings(clauses)
	local aOrderedTypes = {};
	local aDmgTypes = {};
	for _,vClause in ipairs(clauses) do
		local rDmgType = aDmgTypes[vClause.dmgtype];
		if not rDmgType then
			rDmgType = {};
			rDmgType.aDice = {};
			rDmgType.nMod = 0;
			rDmgType.nTotal = 0;
			rDmgType.sType = vClause.dmgtype;
			aDmgTypes[vClause.dmgtype] = rDmgType;
			table.insert(aOrderedTypes, rDmgType);
		end

		for _,vDie in ipairs(vClause.dice) do
			table.insert(rDmgType.aDice, vDie);
		end
		rDmgType.nMod = rDmgType.nMod + vClause.modifier;
		rDmgType.nTotal = rDmgType.nTotal + (vClause.nTotal or 0);
	end
	
	return aOrderedTypes;
end

function encodeDamageText(rRoll)
	local aDamage = getDamageStrings(rRoll.clauses);
	for _, rDamage in ipairs(aDamage) do
		local sDmgTypeOutput = rDamage.sType;
		if sDmgTypeOutput == "" then
			sDmgTypeOutput = "untyped";
		end
		
		if #rDamage.aDice == 0 then
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%d)]", sDmgTypeOutput, rDamage.nTotal);
		else
			local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s=%d)]", sDmgTypeOutput, sDice, rDamage.nTotal);
		end
	end
	
	-- NOTE: Using damage type of the first damage clause for any targeted effect crit multiplier
	if #(rRoll.clauses) > 0 then
		local nEffectCritMult = rRoll.clauses[1].mult or 2;
		if nEffectCritMult then
			rRoll.sDesc = rRoll.sDesc .. string.format(" [MULT: %d]", nEffectCritMult);
		end
	end
end

function decodeDamageText(nDamage, sDamageDesc)
	local rDamageOutput = {};
	rDamageOutput.sOriginal = sDamageDesc;
	if string.match(sDamageDesc, "%[HEAL") then
		if string.match(sDamageDesc, "%[TEMP%]") then
			rDamageOutput.sType = "temphp";
			rDamageOutput.sTypeOutput = "Temporary hit points";
		else
			rDamageOutput.sType = "heal";
			rDamageOutput.sTypeOutput = "Heal";
		end
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

	elseif string.match(sDamageDesc, "%[FHEAL") then
		rDamageOutput.sType = "fheal";
		rDamageOutput.sTypeOutput = "Fast healing";
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

	elseif string.match(sDamageDesc, "%[REGEN") then
		local bPFMode = DataCommon.isPFRPG();
		if bPFMode then
			rDamageOutput.sType = "heal";
			rDamageOutput.sTypeOutput = "Regeneration";
		else
			rDamageOutput.sType = "regen";
			rDamageOutput.sTypeOutput = "Regeneration";
		end
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

	elseif nDamage < 0 then
		rDamageOutput.sType = "heal";
		rDamageOutput.sTypeOutput = "Heal";
		rDamageOutput.sVal = string.format("%01d", (0 - nDamage));
		rDamageOutput.nVal = 0 - nDamage;

	else
		rDamageOutput.sType = "damage";
		rDamageOutput.sTypeOutput = "Damage";
		rDamageOutput.sVal = string.format("%01d", nDamage);
		rDamageOutput.nVal = nDamage;

		-- Determine critical
		rDamageOutput.bCritical = string.match(sDamageDesc, "%[CRITICAL%]");

		-- Determine range
		rDamageOutput.sRange = string.match(sDamageDesc, "%[DAMAGE %((%w)%)%]") or "";
		rDamageOutput.aDamageFilter = {};
		if rDamageOutput.sRange == "M" then
			table.insert(rDamageOutput.aDamageFilter, "melee");
		elseif rDamageOutput.sRange == "R" then
			table.insert(rDamageOutput.aDamageFilter, "ranged");
		end

		-- NOTE: Effect damage dice are not multiplied on critical, though numerical modifiers are multiplied
		-- http://rpg.stackexchange.com/questions/4465/is-smite-evil-damage-multiplied-by-a-critical-hit

		-- Determine damage energy types
		rDamageOutput.aDamageTypes = {};
		local nDamageRemaining = nDamage;
		for sDamageType in sDamageDesc:gmatch("%[TYPE: ([^%]]+)%]") do
			local sDmgType = StringManager.trim(sDamageType:match("^([^(%]]+)"));
			local sDice, sTotal = sDamageType:match("%(([%d%+%-Dd]+)%=(%d+)%)");
			if not sDice then
				sTotal = sDamageType:match("%((%d+)%)")
			end
			local nDmgTypeTotal = tonumber(sTotal) or nDamageRemaining;

			if rDamageOutput.aDamageTypes[sDmgType] then
				rDamageOutput.aDamageTypes[sDmgType] = rDamageOutput.aDamageTypes[sDmgType] + nDmgTypeTotal;
			else
				rDamageOutput.aDamageTypes[sDmgType] = nDmgTypeTotal;
			end
			if not rDamageOutput.sFirstDamageType then
				rDamageOutput.sFirstDamageType = sDmgType;
			end

			nDamageRemaining = nDamageRemaining - nDmgTypeTotal;
		end
		if nDamageRemaining > 0 then
			rDamageOutput.aDamageTypes[""] = nDamageRemaining;
		elseif nDamageRemaining < 0 then
			ChatManager.SystemMessage("Total mismatch in damage type totals");
		end
		
		-- Determine effect damage multiple
		local sMult = sDamageDesc:match("%[MULT: ([^%]]+)%]");
		rDamageOutput.nFirstDamageMult = tonumber(sMult) or 2;
	end
	
	return rDamageOutput;
end
-- KEL bImmune, bFortif
function applyDamage(rSource, rTarget, bSecret, sRollType, sDamage, nTotal, bImmune, bFortif)
	local nTotalHP = 0;
	local nTempHP = 0;
	local nNonLethal = 0;
	local nWounds = 0;
	local bPFMode = DataCommon.isPFRPG();

	local aNotifications = {};
	local bRemoveTarget = false;
	
	-- Get health fields
	local sTargetType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if sTargetType ~= "pc" and sTargetType ~= "ct" then
		return;
	end
	
	if sTargetType == "pc" then
		nTotalHP = DB.getValue(nodeTarget, "hp.total", 0);
		nTempHP = DB.getValue(nodeTarget, "hp.temporary", 0);
		nNonlethal = DB.getValue(nodeTarget, "hp.nonlethal", 0);
		nWounds = DB.getValue(nodeTarget, "hp.wounds", 0);
	else
		nTotalHP = DB.getValue(nodeTarget, "hp", 0);
		nTempHP = DB.getValue(nodeTarget, "hptemp", 0);
		nNonlethal = DB.getValue(nodeTarget, "nonlethal", 0);
		nWounds = DB.getValue(nodeTarget, "wounds", 0);
	end
	
	-- Remember current health status
	local _,_,sOriginalStatus = ActorManager2.getPercentWounded(sTargetType, nodeTarget);

	-- Decode damage/heal description
	local rDamageOutput = decodeDamageText(nTotal, sDamage);

	-- Healing
	if rDamageOutput.sType == "heal" or rDamageOutput.sType == "fheal" then
		-- CHECK COST
		if nWounds <= 0 and nNonlethal <= 0 then
			table.insert(aNotifications, "[NOT WOUNDED]");
		else
			-- CALCULATE HEAL AMOUNTS
			local nHealAmount = rDamageOutput.nVal;
			
			local nNonlethalHealAmount = math.min(nHealAmount, nNonlethal);
			nNonlethal = nNonlethal - nNonlethalHealAmount;
			if (not bPFMode) and (rDamageOutput.sType == "fheal") then
				nHealAmount = nHealAmount - nNonlethalHealAmount;
			end

			local nOriginalWounds = nWounds;
			
			local nWoundHealAmount = math.min(nHealAmount, nWounds);
			nWounds = nWounds - nWoundHealAmount;
			
			-- IF WE HEALED FROM NEGATIVE TO ZERO OR HIGHER, THEN REMOVE STABLE EFFECT
			if (nOriginalWounds > nTotalHP) and (nWounds <= nTotalHP) then
				EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Stable");
			end
			
			-- SET THE ACTUAL HEAL AMOUNT FOR DISPLAY
			rDamageOutput.nVal = nNonlethalHealAmount + nWoundHealAmount;
			if nWoundHealAmount > 0 then
				rDamageOutput.sVal = "" .. nWoundHealAmount;
				if nNonlethalHealAmount > 0 then
					rDamageOutput.sVal = rDamageOutput.sVal .. " (+" .. nNonlethalHealAmount .. " NL)";
				end
			elseif nNonlethalHealAmount > 0 then
				rDamageOutput.sVal = "" .. nNonlethalHealAmount .. " NL";
			else
				rDamageOutput.sVal = "0";
			end
		end

	-- Regeneration
	elseif rDamageOutput.sType == "regen" then
		if nNonlethal <= 0 then
			table.insert(aNotifications, "[NO NONLETHAL DAMAGE]");
		else
			local nNonlethalHealAmount = math.min(rDamageOutput.nVal, nNonlethal);
			nNonlethal = nNonlethal - nNonlethalHealAmount;
			
			rDamageOutput.nVal = nNonlethalHealAmount;
			rDamageOutput.sVal = "" .. nNonlethalHealAmount .. " NL";
		end

	-- Temporary hit points
	elseif rDamageOutput.sType == "temphp" then
		nTempHP = nTempHP + nTotal;

	-- Damage
	else
		-- Apply any targeted damage effects 
		-- NOTE: Dice determined randomly, instead of rolled
		if rSource and rTarget and rTarget.nOrder then
			local aTargetedDamage;
			if sRollType == "spdamage" then
				aTargetedDamage = EffectManager35E.getEffectsBonusByType(rSource, {"DMGS"}, true, rDamageOutput.aDamageFilter, rTarget, true);
			else
				aTargetedDamage = EffectManager35E.getEffectsBonusByType(rSource, {"DMG"}, true, rDamageOutput.aDamageFilter, rTarget, true);
			end

			local nDamageEffectTotal = 0;
			local nDamageEffectCount = 0;
			for k, v in pairs(aTargetedDamage) do
				local nSubTotal = 0;
				if rDamageOutput.bCritical then
					local nMult = rDamageOutput.nFirstDamageMult or 2;
					nSubTotal = StringManager.evalDice(v.dice, (nMult * v.mod));
				else
					nSubTotal = StringManager.evalDice(v.dice, v.mod);
				end
				
				local sDamageType = rDamageOutput.sFirstDamageType;
				if sDamageType then
					sDamageType = sDamageType .. "," .. k;
				else
					sDamageType = k;
				end

				rDamageOutput.aDamageTypes[sDamageType] = (rDamageOutput.aDamageTypes[sDamageType] or 0) + nSubTotal;
				
				nDamageEffectTotal = nDamageEffectTotal + nSubTotal;
				nDamageEffectCount = nDamageEffectCount + 1;
			end
			nTotal = nTotal + nDamageEffectTotal;

			if nDamageEffectCount > 0 then
				if nDamageEffectTotal ~= 0 then
					local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]";
					table.insert(aNotifications, string.format(sFormat, nDamageEffectTotal));
				else
					table.insert(aNotifications, "[" .. Interface.getString("effects_tag") .. "]");
				end
			end
		end
		
		-- Handle evasion and half damage
		local isAvoided = false;
		local isHalf = string.match(sDamage, "%[HALF%]");
		local sAttack = string.match(sDamage, "%[DAMAGE[^]]*%] ([^[]+)");
		if sAttack then
			local sDamageState = getDamageState(rSource, rTarget, StringManager.trim(sAttack));
			if sDamageState == "none" then
				isAvoided = true;
				bRemoveTarget = true;
			elseif sDamageState == "half_success" then
				isHalf = true;
				bRemoveTarget = true;
			elseif sDamageState == "half_failure" then
				isHalf = true;
			end
		end
		if isAvoided then
			table.insert(aNotifications, "[EVADED]");
			for kType, nType in pairs(rDamageOutput.aDamageTypes) do
				rDamageOutput.aDamageTypes[kType] = 0;
			end
			nTotal = 0;
		elseif isHalf then
			table.insert(aNotifications, "[HALF]");
			local bCarry = false;
			for kType, nType in pairs(rDamageOutput.aDamageTypes) do
				local nOddCheck = nType % 2;
				rDamageOutput.aDamageTypes[kType] = math.floor(nType / 2);
				if nOddCheck == 1 then
					if bCarry then
						rDamageOutput.aDamageTypes[kType] = rDamageOutput.aDamageTypes[kType] + 1;
						bCarry = false;
					else
						bCarry = true;
					end
				end
			end
			nTotal = math.max(math.floor(nTotal / 2), 1);
		end
		
		-- Apply damage type adjustments
		-- KEL bImmune, bFortif
		local nDamageAdjust, nNonlethalDmgAmount, bVulnerable, bResist = getDamageAdjust(rSource, rTarget, nTotal, rDamageOutput, bImmune, bFortif);
		local nAdjustedDamage = nTotal + nDamageAdjust;
		if nAdjustedDamage < 0 then
			nAdjustedDamage = 0;
		end
		if bResist then
			if nAdjustedDamage <= 0 then
				table.insert(aNotifications, "[RESISTED]");
			else
				table.insert(aNotifications, "[PARTIALLY RESISTED]");
			end
		end
		if bVulnerable then
			table.insert(aNotifications, "[VULNERABLE]");
		end
		
		-- Reduce damage by temporary hit points
		if nTempHP > 0 and nAdjustedDamage > 0 then
			if nAdjustedDamage > nTempHP then
				nAdjustedDamage = nAdjustedDamage - nTempHP;
				nTempHP = 0;
				table.insert(aNotifications, "[PARTIALLY ABSORBED]");
			else
				nTempHP = nTempHP - nAdjustedDamage;
				nAdjustedDamage = 0;
				table.insert(aNotifications, "[ABSORBED]");
			end
		end

		-- Apply remaining damage
		if nNonlethalDmgAmount > 0 then
			if bPFMode and (nNonlethal + nNonlethalDmgAmount > nTotalHP) then
				local aRegen = EffectManager35E.getEffectsByType(rTarget, "REGEN");
				if #aRegen == 0 then
					local nOver = nNonlethal + nNonlethalDmgAmount - nTotalHP;
					if nOver > nNonlethalDmgAmount then
						nOver = nNonlethalDmgAmount;
					end
					nAdjustedDamage = nAdjustedDamage + nOver;
					nNonlethalDmgAmount = nNonlethalDmgAmount - nOver;
				end
			end
			nNonlethal = math.max(nNonlethal + nNonlethalDmgAmount, 0);
		end
		if nAdjustedDamage > 0 then
			nWounds = math.max(nWounds + nAdjustedDamage, 0);
			
			-- For Pathfinder, disable regeneration next round on correct damage type
			if bPFMode then
				local nodeTargetCT = ActorManager.getCTNode(rTarget);
				if nodeTargetCT then
					-- Calculate which damage types actually did damage
					local aTempDamageTypes = {};
					local aActualDamageTypes = {};
					for k,v in pairs(rDamageOutput.aDamageTypes) do
						if v > 0 then
							table.insert(aTempDamageTypes, k);
						end
					end
					local aActualDamageTypes = StringManager.split(table.concat(aTempDamageTypes, ","), ",", true);
					
					-- Check target's effects for regeneration effects that match
					for _,v in pairs(DB.getChildren(nodeTargetCT, "effects")) do
						local nActive = DB.getValue(v, "isactive", 0);
						if (nActive == 1) then
							local bMatch = false;
							local sLabel = DB.getValue(v, "label", "");
							local aEffectComps = EffectManager.parseEffect(sLabel);
							for i = 1, #aEffectComps do
								local rEffectComp = EffectManager35E.parseEffectComp(aEffectComps[i]);
								if rEffectComp.type == "REGEN" then
									local sRegen = table.concat(rEffectComp.remainder, " ");
									aClausesOR = decodeAndOrClauses(sRegen);
									if matchAndOrClauses(aClausesOR, aActualDamageTypes) then
										bMatch = true;
									end
								end
								
								if bMatch then
									EffectManager.disableEffect(nodeTargetCT, v);
								end
							end
						end
					end
				end
			end
		end
		
		-- Update the damage output variable to reflect adjustments
		rDamageOutput.nVal = nAdjustedDamage;
		if nAdjustedDamage > 0 then
			rDamageOutput.sVal = string.format("%01d", nAdjustedDamage);
			if nNonlethalDmgAmount > 0 then
				rDamageOutput.sVal = rDamageOutput.sVal .. string.format(" (+%01d NL)", nNonlethalDmgAmount);
			end
		elseif nNonlethalDmgAmount > 0 then
			rDamageOutput.sVal = string.format("%01d NL", nNonlethalDmgAmount);
		else
			rDamageOutput.sVal = "0";
		end
	end

	-- Set health fields
	if sTargetType == "pc" then
		DB.setValue(nodeTarget, "hp.temporary", "number", nTempHP);
		DB.setValue(nodeTarget, "hp.wounds", "number", nWounds);
		DB.setValue(nodeTarget, "hp.nonlethal", "number", nNonlethal);
	else
		DB.setValue(nodeTarget, "hptemp", "number", nTempHP);
		DB.setValue(nodeTarget, "wounds", "number", nWounds);
		DB.setValue(nodeTarget, "nonlethal", "number", nNonlethal);
	end

	-- Check for status change
	local bShowStatus = false;
	if ActorManager.getFaction(rTarget) == "friend" then
		bShowStatus = not OptionsManager.isOption("SHPC", "off");
	else
		bShowStatus = not OptionsManager.isOption("SHNPC", "off");
	end
	if bShowStatus then
		local _,_,sNewStatus = ActorManager2.getPercentWounded(sTargetType, nodeTarget);
		if sOriginalStatus ~= sNewStatus then
			table.insert(aNotifications, "[" .. Interface.getString("combat_tag_status") .. ": " .. sNewStatus .. "]");
		end
	end
	
	-- Output results
	messageDamage(rSource, rTarget, bSecret, rDamageOutput.sTypeOutput, sDamage, rDamageOutput.sVal, table.concat(aNotifications, " "));

	-- Remove target after applying damage
	if bRemoveTarget and rSource and rTarget then
		TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
	end
end

function messageDamage(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult)
	if not (rTarget or sExtraResult ~= "") then
		return;
	end
	
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};

	if sDamageType == "Heal" or sDamageType == "Temporary hit points" then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";
	else
		msgShort.icon = "roll_damage";
		msgLong.icon = "roll_damage";
	end

	msgShort.text = sDamageType .. " ->";
	msgLong.text = sDamageType .. " [" .. sTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. " [to " .. ActorManager.getDisplayName(rTarget) .. "]";
		msgLong.text = msgLong.text .. " [to " .. ActorManager.getDisplayName(rTarget) .. "]";
	end
	
	if sExtraResult and sExtraResult ~= "" then
		msgLong.text = msgLong.text .. " " .. sExtraResult;
	end
	
	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

function applyFailedStabilization(rActor)
	local sDamageTypeOutput = "Damage";
	local sDamage = "[DAMAGE] Dying";
	local nTotal = 1;
	
	local nTotalHP = 0;
	local nTempHP = 0;
	local nWounds = 0;

	local aNotifications = {};
	
	-- Get health fields
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if sActorType ~= "pc" and sActorType ~= "ct" then
		return;
	end
	
	if sActorType == "pc" then
		nTotalHP = DB.getValue(nodeActor, "hp.total", 0);
		nTempHP = DB.getValue(nodeActor, "hp.temporary", 0);
		nWounds = DB.getValue(nodeActor, "hp.wounds", 0);
	else
		nTotalHP = DB.getValue(nodeActor, "hp", 0);
		nTempHP = DB.getValue(nodeActor, "hptemp", 0);
		nWounds = DB.getValue(nodeActor, "wounds", 0);
	end
	
	-- Remember current health status
	local _,_,sOriginalStatus = ActorManager2.getPercentWounded(sActorType, nodeActor);

	-- Track adjustments, if any
	local nAdjustedDamage = nTotal;

	-- Reduce damage by temporary hit points
	if nTempHP > 0 and nAdjustedDamage > 0 then
		if nAdjustedDamage > nTempHP then
			nAdjustedDamage = nAdjustedDamage - nTempHP;
			nTempHP = 0;
			table.insert(aNotifications, "[PARTIALLY ABSORBED]");
		else
			nTempHP = nTempHP - nAdjustedDamage;
			nAdjustedDamage = 0;
			table.insert(aNotifications, "[ABSORBED]");
		end
	end

	-- Apply remaining damage
	if nAdjustedDamage > 0 then
		nWounds = math.max(nWounds + nAdjustedDamage, 0);
	end
	
	-- Set health fields
	if sActorType == "pc" then
		DB.setValue(nodeActor, "hp.temporary", "number", nTempHP);
		DB.setValue(nodeActor, "hp.wounds", "number", nWounds);
	else
		DB.setValue(nodeActor, "hptemp", "number", nTempHP);
		DB.setValue(nodeActor, "wounds", "number", nWounds);
	end

	-- Check for status change
	local _,_,sNewStatus = ActorManager2.getPercentWounded(sActorType, nodeActor);
	if sOriginalStatus ~= sNewStatus then
		table.insert(aNotifications, "[Status: " .. sNewStatus:upper() .. "]");
	end
	
	-- Update the damage output variable to reflect adjustments
	local sDamageOutput;
	if nAdjustedDamage > 0 then
		sDamageOutput = string.format("%01d", nAdjustedDamage);
	else
		sDamageOutput = "0";
	end

	-- Output results
	messageDamage(nil, rActor, false, sDamageTypeOutput, sDamage, sDamageOutput, table.concat(aNotifications, " "));
end

--
-- TRACK DAMAGE STATE
--

local aDamageState = {};

function applyDamageState(rSource, rTarget, sAttack, sState)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMGSTATE;
	
	msgOOB.sSourceNode = ActorManager.getCTNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rTarget);
	
	msgOOB.sAttack = sAttack;
	msgOOB.sState = sState;

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyDamageState(msgOOB)
	local rSource = ActorManager.getActor("ct", msgOOB.sSourceNode);
	local rTarget = ActorManager.getActor("ct", msgOOB.sTargetNode);
	
	if User.isHost() then
		setDamageState(rSource, rTarget, msgOOB.sAttack, msgOOB.sState);
	end
end

function setDamageState(rSource, rTarget, sAttack, sState)
	if not User.isHost() then
		applyDamageState(rSource, rTarget, sAttack, sState);
		return;
	end
	
	local sSourceCT = ActorManager.getCTNodeName(rSource);
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sSourceCT == "" or sTargetCT == "" then
		return;
	end
	
	if not aDamageState[sSourceCT] then
		aDamageState[sSourceCT] = {};
	end
	if not aDamageState[sSourceCT][sAttack] then
		aDamageState[sSourceCT][sAttack] = {};
	end
	if not aDamageState[sSourceCT][sAttack][sTargetCT] then
		aDamageState[sSourceCT][sAttack][sTargetCT] = {};
	end
	aDamageState[sSourceCT][sAttack][sTargetCT] = sState;
end

function getDamageState(rSource, rTarget, sAttack)
	local sSourceCT = ActorManager.getCTNodeName(rSource);
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sSourceCT == "" or sTargetCT == "" then
		return "";
	end
	
	if not aDamageState[sSourceCT] then
		return "";
	end
	if not aDamageState[sSourceCT][sAttack] then
		return "";
	end
	if not aDamageState[sSourceCT][sAttack][sTargetCT] then
		return "";
	end
	
	local sState = aDamageState[sSourceCT][sAttack][sTargetCT];
	aDamageState[sSourceCT][sAttack][sTargetCT] = nil;
	return sState;
end
