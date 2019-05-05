function onInit()
	-- Extension launch message
	local msg = {sender = "", font = "emotefont"};
    msg.text = "Keen v1.2 for FGII V3.0.10 3.5E and PFRPG rulesets. \rCopyright 2017 Smiteworks.\rBy Rhythmist.\rApply the 'keen' effect to double threat range for that actor. Works on PCs and NPCs."
	ChatManager.registerLaunchMessage(msg);	
end