-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
-- The idea of a save overlay is motivated by an extension from Ken L and the following is his changed and modified code basically. Thanks him for providing his ideas and extensions to the community :) 


OOB_MSGTYPE_APPLYOVERLAY = "applyoverlay";

function onInit()
	if not User.isHost() then
		TokenManager.addDefaultHealthFeatures(getHealthInfo, {"hp", "hptemp", "nonlethal", "wounds", "status"});
	else
		TokenManager.addDefaultHealthFeatures(getHealthInfo, {"hp", "hptemp", "nonlethal", "wounds"});
	end
	
	TokenManager.addEffectTagIconConditional("IF", handleIFEffectTag);
	TokenManager.addEffectTagIconSimple("IFT", "");
	TokenManager.addEffectTagIconBonus(DataCommon.bonuscomps);
	TokenManager.addEffectTagIconSimple(DataCommon.othercomps);
	TokenManager.addEffectConditionIcon(DataCommon.condcomps);
	TokenManager.addDefaultEffectFeatures(nil, EffectManager35E.parseEffectComp);
	-- Overlay
    DB.addHandler("combattracker.list.*.saveclear", "onUpdate", updateSaveOverlay);
    DB.addHandler("combattracker.list.*.death", "onUpdate", updateDeathOverlay);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYOVERLAY, handleApplyOverlay);
end

function getHealthInfo(nodeCT)
	local sColor, nPercentWounded, nPercentNonlethal, sStatus = ActorManager2.getWoundBarColor("ct", nodeCT);
	return nPercentNonlethal, sStatus, sColor;
end

function handleIFEffectTag(rActor, nodeEffect, vComp)
	return EffectManager35E.checkConditional(rActor, nodeEffect, vComp.remainder);
end

function setSaveOverlay(nodeCT, success, erase)
	if nodeCT then
		if erase then
			local saveclearNode = nodeCT.createChild("saveclear","number"); 
			if saveclearNode then
				saveclearNode.setValue(success);
			end
		elseif User.isHost() then
			local saveclearNode = nodeCT.createChild("saveclear","number"); 
			if saveclearNode then
				if success < getSaveOverlay(nodeCT) then
					saveclearNode.setValue(success); 
				end
			end
		else
			local msgOOB = {};
			msgOOB.type = OOB_MSGTYPE_APPLYOVERLAY;
			local rSource = ActorManager.getActorFromCT(nodeCT);
			local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
			msgOOB.sSourceType = sSourceType;
			msgOOB.sSourceNode = sSourceNode;
			msgOOB.savenumber = success;
			Comm.deliverOOBMessage(msgOOB, "");
		end
	end
end

function handleApplyOverlay(msgOOB)
	local success = tonumber(msgOOB.savenumber);
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local nodeCT = ActorManager.getCTNode(rSource);
	local saveclearNode = nodeCT.createChild("saveclear","number"); 
	
	if saveclearNode then
		if success < getSaveOverlay(nodeCT) then
			saveclearNode.setValue(success); 
		end
	end
end

function getSaveOverlay(nodeCT)
	if nodeCT then
		local saveoverlayNode = nodeCT.getChild("saveclear","number"); 
		if saveoverlayNode then
			return saveoverlayNode.getValue(); 
		end
	end
end

function updateSaveOverlay(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	local success = nodeField.getValue(); 
	local widgetSuccess;

	if tokenCT then
		local wToken, hToken = tokenCT.getSize();
		widgetSuccess = tokenCT.findWidget("success1");
		if widgetSuccess then widgetSuccess.destroy() end

		if success == -3 then 
			widgetSuccess = tokenCT.addBitmapWidget(); 
			widgetSuccess.setName("success1"); 
			widgetSuccess.bringToFront(); 
			widgetSuccess.setBitmap("overlay_save_success"); 
			widgetSuccess.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
		elseif success == -2 then
			widgetSuccess = tokenCT.addBitmapWidget(); 
			widgetSuccess.setName("success1"); 
			widgetSuccess.bringToFront(); 
			widgetSuccess.setBitmap("overlay_save_partial"); 
			widgetSuccess.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
		elseif success == -1 then
			widgetSuccess = tokenCT.addBitmapWidget(); 
			widgetSuccess.setName("success1"); 
			widgetSuccess.bringToFront(); 
			widgetSuccess.setBitmap("overlay_save_failure"); 
			widgetSuccess.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
		else
			-- No overlay
		end
	end
end

function setDeathOverlay(nodeCT, death)
	if nodeCT then
		local deathNode = nodeCT.createChild("death","number"); 
		if deathNode then
			deathNode.setValue(death);
		end
	end
end

function updateDeathOverlay(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	local deathvalue = nodeField.getValue(); 
	local widgetDeath;

	if tokenCT then
		local wToken, hToken = tokenCT.getSize();
		widgetDeath = tokenCT.findWidget("death1");
		if widgetDeath then widgetDeath.destroy() end

		if deathvalue == 1 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_death"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1)); 
		elseif deathvalue == 2 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_dying"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		elseif deathvalue == 3 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_dying_stable"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		elseif deathvalue == 4 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_critical"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		elseif deathvalue == 5 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_heavy"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		elseif deathvalue == 6 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_moderate"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		elseif deathvalue == 7 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_wounded"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		elseif deathvalue == 8 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_disabled"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		elseif deathvalue == 9 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_ko"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		elseif deathvalue == 10 then 
			widgetDeath = tokenCT.addBitmapWidget(); 
			widgetDeath.setName("death1"); 
			widgetDeath.bringToFront(); 
			widgetDeath.setBitmap("overlay_staggered"); 
			widgetDeath.setSize(math.floor(wToken*1), math.floor(hToken*1));
		else
			-- No overlay
		end
	end
end