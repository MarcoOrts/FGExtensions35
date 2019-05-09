function onInit()
	-- Extension launch message
	local msg = {sender = "", font = "emotefont"};
    msg.text = "Immediate action v1 for 3.5E and PFRPG rulesets. \rCopyright 2017 Smiteworks.\rBy Kelrugem.\rRefreshes the Immediate box at the end of turn."
	ChatManager.registerLaunchMessage(msg);	
end