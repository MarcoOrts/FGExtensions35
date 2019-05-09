function onInit()
	-- Extension launch message
	local msg = {sender = "", font = "emotefont"};
    msg.text = "HRESIST v1 for 3.5E and PFRPG rulesets. \rCopyright 2017 Smiteworks.\rBy Kelrugem.\rApply the 'HRESIST: [damage type], all' effect to half the damage of that damage type for that actor. Works on PCs and NPCs. Also a bug fix for the correct order such that 1. HRESIST, 2. RESIST, 3. VULN."
	ChatManager.registerLaunchMessage(msg);	
end