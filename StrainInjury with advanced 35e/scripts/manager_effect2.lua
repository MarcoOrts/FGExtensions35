-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	EffectManager.applyOngoingDamageAdjustment = EffectManager2.applyOngoingDamageAdjustment;
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
	-- EXIT IF EMPTY FHEAL OR DMGO
	if #(rEffectComp.dice) == 0 and rEffectComp.mod == 0 then
		return;
	end
	
	-- BUILD MESSAGE
	local aResults = {};
	if rEffectComp.type == "FHEAL" then
		-- MAKE SURE AFFECTED ACTOR IS WOUNDED
		if DB.getValue(nodeActor, "wounds", 0) == 0 and DB.getValue(nodeActor, "injury", 0) == 0 and DB.getValue(nodeActor, "nonlethal", 0) == 0 then
			return;
		end
		
		table.insert(aResults, "[FHEAL] Fast Heal");

	elseif rEffectComp.type == "REGEN" then
		-- MAKE SURE AFFECTED ACTOR IS WOUNDED
		local bPFMode = DataCommon.isPFRPG();
		if bPFMode then
			if DB.getValue(nodeActor, "wounds", 0) == 0 and DB.getValue(nodeActor, "injury", 0) == 0  and DB.getValue(nodeActor, "nonlethal", 0) == 0 then
				return;
			end
		else
			if DB.getValue(nodeActor, "nonlethal", 0) == 0 then
				return;
			end
		end
		
		table.insert(aResults, "[REGEN] Regeneration");

	else
		table.insert(aResults, "[DAMAGE] Ongoing Damage");

		if #(rEffectComp.remainder) > 0 then
			local sDamageType = string.lower(table.concat(rEffectComp.remainder, ","));
			table.insert(aResults, "[TYPE: " .. sDamageType .. "]");
		end
	end

	-- MAKE ROLL AND APPLY RESULTS
	local rTarget = ActorManager.getActorFromCT(nodeActor);
	local rRoll = { sType = "damage", sDesc = table.concat(aResults, " "), aDice = rEffectComp.dice, nMod = rEffectComp.mod };
	if EffectManager.isGMEffect(nodeActor, nodeEffect) then
		rRoll.bSecret = true;
	end
	ActionsManager.roll(nil, rTarget, rRoll);
end
