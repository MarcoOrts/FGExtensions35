function onInit()
	-- Extension launch message
	local msg = {sender = "", font = "emotefont"};
    msg.text = "AoO tracker v1 for 3.5E and PFRPG rulesets. \rCopyright 2019 Smiteworks.\rBy Kelrugem."
	ChatManager.registerLaunchMessage(msg);	
end