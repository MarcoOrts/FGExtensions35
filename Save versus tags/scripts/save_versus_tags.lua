function onInit()
	-- Extension launch message
	local msg = {sender = "", font = "emotefont"};
    msg.text = "Save versus tags. \rCopyright 2019 Smiteworks.\rBy Kelrugem.\rApply the IFTAG: [tags of spells] to make more complex effects for special situations."
	ChatManager.registerLaunchMessage(msg);	
end