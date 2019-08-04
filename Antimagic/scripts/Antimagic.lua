function onInit()
	-- Extension launch message
	local msg = {sender = "", font = "emotefont"};
    msg.text = "Antimagic v1 for 3.5E and PFRPG rulesets. \rCopyright 2017 Smiteworks.\rBy Kelrugem.\rApply to all magical effects the string 'MAGIC' and for the penalties 'ANTI'. Then use the antimagic toggle in the CT."
	ChatManager.registerLaunchMessage(msg);	
end