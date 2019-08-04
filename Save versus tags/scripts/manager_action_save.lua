-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
-- KEL Add OOB messages for tag effects
OOB_MSGTYPE_APPLYSAVE = "applysave";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);

	ActionsManager.registerModHandler("save", modSave);
	ActionsManager.registerResultHandler("save", onSave);
end

function handleApplySave(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local rOrigin = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
	
	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	rAction.sSaveDesc = msgOOB.sSaveDesc;
	rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
	rAction.bRemoveOnMiss = (tonumber(msgOOB.nRemoveOnMiss) == 1);
	rAction.sSaveResult = msgOOB.sSaveResult;
	
	applySave(rSource, rOrigin, rAction);
end

function notifyApplySave(rSource, rRoll)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
	
	if rRoll.bTower then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.sSaveDesc = rRoll.sSaveDesc;
	msgOOB.nTarget = rRoll.nTarget;
	msgOOB.sSaveResult = rRoll.sSaveResult;
	if rRoll.bRemoveOnMiss then msgOOB.nRemoveOnMiss = 1; end

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	if rRoll.sSource ~= "" then
		msgOOB.sTargetType = "ct";
		msgOOB.sTargetNode = rRoll.sSource;
	else
		msgOOB.sTargetType = "";
		msgOOB.sTargetNode = "";
	end
	
	Comm.deliverOOBMessage(msgOOB, "");
end

function performPartySheetRoll(draginfo, rActor, sSave)
	local rRoll = getRoll(rActor, sSave);
	
	local nTargetDC = DB.getValue("partysheet.savedc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performVsRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc, tags)
	local rRoll = getVsRoll(rActor, sSave, rSource, sSaveDesc, tags);

	if bSecretRoll then
		rRoll.bSecret = true;
	end
	rRoll.nTarget = nTargetDC;
	if bRemoveOnMiss then
		rRoll.bRemoveOnMiss = "true";
	end
	if sSaveDesc then
		rRoll.sSaveDesc = sSaveDesc;
	end
	if rSource then
		rRoll.sSource = ActorManager.getCTNodeName(rSource);
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- ROLL VS SCHOOL ETC

function getVsRoll(rActor, sSave, rSource, sSaveDesc, tags)
	local rRoll = {};
	local VSData = {};
	rRoll.sType = "save";
	rRoll.aDice = { "d20" };
	rRoll.nMod = 0;
	
	-- Look up actor specific information
	local sAbility = nil;
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor then
		-- Debug.console(nodeActor);
		if sActorType == "pc" then
			rRoll.nMod = DB.getValue(nodeActor, "saves." .. sSave .. ".total", 0);
			sAbility = DB.getValue(nodeActor, "saves." .. sSave .. ".ability", "");
		else
			rRoll.nMod = DB.getValue(nodeActor, sSave .. "save", 0);
		end
	end

	rRoll.sDesc = "[SAVE] " .. StringManager.capitalize(sSave);
	-- Look up spell specific information
	local spell = (sSaveDesc:match("%[SPELL%]") ~= nil);
	local spelllike = (sSaveDesc:match("%[SPELLLIKE%]") ~= nil);
	local abjuration = (sSaveDesc:match("%[ABJURATION%]") ~= nil);
	local conjuration = (sSaveDesc:match("%[CONJURATION%]") ~= nil);
	local divination = (sSaveDesc:match("%[DIVINATION%]") ~= nil);
	local enchantment = (sSaveDesc:match("%[ENCHANTMENT%]") ~= nil);
	local evocation = (sSaveDesc:match("%[EVOCATION%]") ~= nil);
	local illusion = (sSaveDesc:match("%[ILLUSION%]") ~= nil);
	local necromancy = (sSaveDesc:match("%[NECROMANCY%]") ~= nil);
	local transmutation = (sSaveDesc:match("%[TRANSMUTATION%]") ~= nil);
	local universal = (sSaveDesc:match("%[UNIVERSAL%]") ~= nil);
	-- Adding auxiliary effect
	-- local rEffectSpell = {};
	-- rEffectSpell.sName = "tagsistagsKelrugemSave;";
	-- rEffectSpell.nDuration = 1;
	-- rEffectSpell.nInit = 0;
	-- rEffectSpell.nGMOnly = 1;
    -- rEffectSpell.sApply = "";
	
	if spell then
		rRoll.sDesc = rRoll.sDesc .. " [SPELL]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "spell;";
	end
	if spelllike then
		rRoll.sDesc = rRoll.sDesc .. " [SPELLLIKE]";
		-- rEffectSpell.sName = rEffectSpell.sName.. "spelllike;";
	end
	
	if abjuration then
		rRoll.sDesc = rRoll.sDesc .. " [ABJURATION]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "abjuration;";
	end
	if conjuration then
		rRoll.sDesc = rRoll.sDesc .. " [CONJURATION]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "conjuration;";
	end
	if divination then
		rRoll.sDesc = rRoll.sDesc .. " [DIVINATION]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "divination;";
	end
	if enchantment then
		rRoll.sDesc = rRoll.sDesc .. " [ENCHANTMENT]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "enchantment;";
	end
	if evocation then
		rRoll.sDesc = rRoll.sDesc .. " [EVOCATION]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "evocation;";
	end
	if illusion then
		rRoll.sDesc = rRoll.sDesc .. " [ILLUSION]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "illusion;";
	end
	if necromancy then
		rRoll.sDesc = rRoll.sDesc .. " [NECROMANCY]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "necromancy;";
	end
	if transmutation then
		rRoll.sDesc = rRoll.sDesc .. " [TRANSMUTATION]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "transmutation;";
	end
	if universal then
		rRoll.sDesc = rRoll.sDesc .. " [UNIVERSAL]";
        -- rEffectSpell.sName = rEffectSpell.sName.. "universal;";
	end
	if tags ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " [Other tags: " .. tags .. "]";
	end
	-- rEffectSpell.sName = rEffectSpell.sName.. tags;
	
	-- END auxiliary effect
	
	if sAbility and sAbility ~= "" then
		if (sSave == "fortitude" and sAbility ~= "constitution") or
				(sSave == "reflex" and sAbility ~= "dexterity") or
				(sSave == "will" and sAbility ~= "wisdom") then
			local sAbilityEffect = DataCommon.ability_ltos[sAbility];
			if sAbilityEffect then
				rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
			end
		end
	end
	-- Add tags
	rRoll.tags = tags;
	
	return rRoll;
end

-- END ROLL VS SCHOOL ETC

function performRoll(draginfo, rActor, sSave)
	local rRoll = getRoll(rActor, sSave);
	
	if User.isHost() and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, sSave)
	local rRoll = {};
	local VSData = {};
	rRoll.sType = "save";
	rRoll.aDice = { "d20" };
	rRoll.nMod = 0;
	
	-- Look up actor specific information
	local sAbility = nil;
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor then
		if sActorType == "pc" then
			rRoll.nMod = DB.getValue(nodeActor, "saves." .. sSave .. ".total", 0);
			sAbility = DB.getValue(nodeActor, "saves." .. sSave .. ".ability", "");
		else
			rRoll.nMod = DB.getValue(nodeActor, sSave .. "save", 0);
		end
	end

	rRoll.sDesc = "[SAVE] " .. StringManager.capitalize(sSave);
	if sAbility and sAbility ~= "" then
		if (sSave == "fortitude" and sAbility ~= "constitution") or
				(sSave == "reflex" and sAbility ~= "dexterity") or
				(sSave == "will" and sAbility ~= "wisdom") then
			local sAbilityEffect = DataCommon.ability_ltos[sAbility];
			if sAbilityEffect then
				rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
			end
		end
	end
	rRoll.tags = "";
	return rRoll;
end

function modSave(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		local bEffects = false;

		-- Determine ability used
		local sSave = nil;
		local sSaveMatch = string.match(rRoll.sDesc, "%[SAVE%] ([^[]+)");
		if sSaveMatch then
			sSave = string.lower(StringManager.trim(sSaveMatch));
		end
		local sActionStat = nil;
		local sModStat = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
		if sModStat then
			sActionStat = DataCommon.ability_stol[sModStat];
		end
		if not sActionStat then
			if sSave == "fortitude" then
				sActionStat = "constitution";
			elseif sSave == "reflex" then
				sActionStat = "dexterity";
			elseif sSave == "will" then
				sActionStat = "wisdom";
			end
		end
		
		-- Build save filter
		local aSaveFilter = {};
		if sSave then
			table.insert(aSaveFilter, sSave);
		end
		-- KEL Tags
		local spell = (rRoll.sDesc:match("%[SPELL%]") ~= nil);
		local spelllike = (rRoll.sDesc:match("%[SPELLLIKE%]") ~= nil);
		local abjuration = (rRoll.sDesc:match("%[ABJURATION%]") ~= nil);
		local conjuration = (rRoll.sDesc:match("%[CONJURATION%]") ~= nil);
		local divination = (rRoll.sDesc:match("%[DIVINATION%]") ~= nil);
		local enchantment = (rRoll.sDesc:match("%[ENCHANTMENT%]") ~= nil);
		local evocation = (rRoll.sDesc:match("%[EVOCATION%]") ~= nil);
		local illusion = (rRoll.sDesc:match("%[ILLUSION%]") ~= nil);
		local necromancy = (rRoll.sDesc:match("%[NECROMANCY%]") ~= nil);
		local transmutation = (rRoll.sDesc:match("%[TRANSMUTATION%]") ~= nil);
		local universal = (rRoll.sDesc:match("%[UNIVERSAL%]") ~= nil);
		
		local sEffectSpell = "";
	
		-- sEffectSpell.nDuration = 1;
		-- sEffectSpell.sName = "tagsistagsKelrugemSave;";
		-- sEffectSpell.nInit = 0;
		-- sEffectSpell.nGMOnly = 1;
		-- sEffectSpell.sApply = "";
		
		if spell then	
			sEffectSpell = sEffectSpell.. "spell;";
		end
		if spelllike then
			sEffectSpell = sEffectSpell.. "spelllike;";
		end
		if abjuration then
			sEffectSpell = sEffectSpell.. "abjuration;";
		end
		if conjuration then
			sEffectSpell = sEffectSpell.. "conjuration;";
		end
		if divination then
			sEffectSpell = sEffectSpell.. "divination;";
		end
		if enchantment then
			sEffectSpell = sEffectSpell.. "enchantment;";
		end
		if evocation then
			sEffectSpell = sEffectSpell.. "evocation;";
		end
		if illusion then
			sEffectSpell = sEffectSpell.. "illusion;";
		end
		if necromancy then
			sEffectSpell = sEffectSpell.. "necromancy;";
		end
		if transmutation then
			sEffectSpell = sEffectSpell.. "transmutation;";
		end
		if universal then
			sEffectSpell = sEffectSpell.. "universal;";
		end
		local tags = rRoll.tags;
		
		sEffectSpell = sEffectSpell.. tags;
		
		-- Get effect modifiers
		local rSaveSource = nil;
		if rRoll.sSource then
			rSaveSource = ActorManager.getActor("ct", rRoll.sSource);
		end
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager35E.getTagEffectsBonus(rSource, "SAVE", false, aSaveFilter, rSaveSource, sEffectSpell);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectManager35E.hasEffectCondition(rSource, "Frightened") or 
				EffectManager35E.hasEffectCondition(rSource, "Panicked") or
				EffectManager35E.hasEffectCondition(rSource, "Shaken") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		
		if EffectManager35E.hasEffectCondition(rSource, "Sickened") then
			nAddMod = nAddMod - 2;
			bEffects = true;
		end
		if sSave == "reflex" and EffectManager35E.hasEffectCondition(rSource, "Slowed") then
			nAddMod = nAddMod - 1;
			bEffects = true;
		end

		-- Get ability modifiers
		local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sActionStat);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- Get negative levels
		local nNegLevelMod, nNegLevelCount = EffectManager35E.getEffectsBonus(rSource, {"NLVL"}, true);
		if nNegLevelCount > 0 then
			bEffects = true;
			nAddMod = nAddMod - nNegLevelMod;
		end

		-- If effects, then add them
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function onSave(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
	
	if rRoll.nTarget then
		rRoll.nTotal = ActionsManager.total(rRoll);
		if #(rRoll.aDice) > 0 then
			local nFirstDie = rRoll.aDice[1].result or 0;
			if nFirstDie == 20 then
				rRoll.sSaveResult = "autosuccess";
			elseif nFirstDie == 1 then
				rRoll.sSaveResult = "autofailure";
			end
		end
		if (rRoll.sSaveResult or "") == "" then
			local nTarget = tonumber(rRoll.nTarget) or 0;
			if rRoll.nTotal >= nTarget then
				rRoll.sSaveResult = "success";
			else
				rRoll.sSaveResult = "failure";
			end
		end
		notifyApplySave(rSource, rRoll);
	end
end

function applySave(rSource, rOrigin, rAction, sUser)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Save";
	msgLong.text = "Save [" .. rAction.nTotal ..  "]";
	if rAction.nTarget then
		msgLong.text = msgLong.text .. "[vs. DC " .. rAction.nTarget .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
		msgLong.text = msgLong.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
	end
	if rOrigin then
		msgShort.text = msgShort.text .. " [vs " .. ActorManager.getDisplayName(rOrigin) .. "]";
		msgLong.text = msgLong.text .. " [vs " .. ActorManager.getDisplayName(rOrigin) .. "]";
	end
	
	msgShort.icon = "roll_cast";
		
	local sAttack = "";
	local bHalfMatch = false;
	if rAction.sSaveDesc then
		sAttack = rAction.sSaveDesc:match("%[SAVE VS[^]]*%] ([^[]+)") or "";
		bHalfMatch = (rAction.sSaveDesc:match("%[HALF ON SAVE%]") ~= nil);
	end
	rAction.sResult = "";
	
	if rAction.sSaveResult == "autosuccess" or rAction.sSaveResult == "success" then
		if rAction.sSaveResult == "autosuccess" then
			msgLong.text = msgLong.text .. " [AUTOMATIC SUCCESS]";
		else
			msgLong.text = msgLong.text .. " [SUCCESS]";
		end
		
		if rSource then
			local bHalfDamage = bHalfMatch;
			local bAvoidDamage = false;
			if bHalfDamage then
				local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
				if sSave then
					sSave = sSave:lower();
				end
				if sSave == "reflex" then
					if EffectManager35E.hasEffectCondition(rSource, "Improved Evasion") then 
						bAvoidDamage = true;
						msgLong.text = msgLong.text .. " [IMPROVED EVASION]";
					elseif EffectManager35E.hasEffectCondition(rSource, "Evasion") then
						bAvoidDamage = true;
						msgLong.text = msgLong.text .. " [EVASION]";
					end
				end
			end
			
			if bAvoidDamage then
				rAction.sResult = "none";
				rAction.bRemoveOnMiss = false;
			elseif bHalfDamage then
				rAction.sResult = "half_success";
				rAction.bRemoveOnMiss = false;
			end
			
			if rOrigin and rAction.bRemoveOnMiss then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rOrigin), ActorManager.getCTNodeName(rSource));
			end
		end
	else
		if rAction.sSaveResult == "autofailure" then
			msgLong.text = msgLong.text .. " [AUTOMATIC FAILURE]";
		else
			msgLong.text = msgLong.text .. " [FAILURE]";
		end

		if rSource then
			local bHalfDamage = false;
			if bHalfMatch then
				local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
				if sSave then
					sSave = sSave:lower();
				end
				if sSave == "reflex" then
					if EffectManager35E.hasEffectCondition(rSource, "Improved Evasion") then
						bHalfDamage = true;
						msgLong.text = msgLong.text .. " [IMPROVED EVASION]";
					end
				end
			end
			
			if bHalfDamage then
				rAction.sResult = "half_failure";
			end
		end
	end
	
	ActionsManager.outputResult(rAction.bSecret, rSource, rOrigin, msgLong, msgShort);
	
	if rSource and rOrigin then
		ActionDamage.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rAction.sResult);
	end
end
