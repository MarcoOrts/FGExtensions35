-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	EffectManager35E.applyOngoingDamageAdjustment = EffectManager2.applyOngoingDamageAdjustment;
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
	if #(rEffectComp.dice) == 0 and rEffectComp.mod == 0 then
		return;
	end
	
	local rTarget = ActorManager.getActorFromCT(nodeActor);
	
	local aResults = {};
	if rEffectComp.type == "FHEAL" then
		local _,_,sStatus = ActorManager2.getPercentWounded("ct", nodeActor);
		if sStatus == "Dead" then
			return;
		end
		if DB.getValue(nodeActor, "wounds", 0) == 0 and DB.getValue(nodeActor, "injury", 0) == 0 then
			return;
		end
		
		table.insert(aResults, "[FHEAL] Fast Heal");
	-- KEL replace nonlethal
	elseif rEffectComp.type == "REGEN" then
		local bPFMode = DataCommon.isPFRPG();
		if bPFMode then
			if DB.getValue(nodeActor, "wounds", 0) == 0 and DB.getValue(nodeActor, "injury", 0) == 0 then
				return;
			end
		else
			if DB.getValue(nodeActor, "wounds", 0) == 0 then
				return;
			end
		end
		
		table.insert(aResults, "[REGEN] Regeneration");

	else
		table.insert(aResults, "[DAMAGE] Ongoing Damage");
		if #(rEffectComp.remainder) > 0 then
			table.insert(aResults, "[TYPE: " .. table.concat(rEffectComp.remainder, ","):lower() .. "]");
		end
	end

	local rRoll = { sType = "damage", sDesc = table.concat(aResults, " "), aDice = rEffectComp.dice, nMod = rEffectComp.mod };
	if EffectManager.isGMEffect(nodeActor, nodeEffect) then
		rRoll.bSecret = true;
	end
	ActionsManager.roll(nil, rTarget, rRoll);
end
