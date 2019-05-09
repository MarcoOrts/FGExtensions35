function onInit()
	-- Extension launch message
	local msg = {sender = "", font = "emotefont"};
    msg.text = "FORTIF, HRESIST, ghost touch and Immediate action v1 for 3.5E and PFRPG rulesets. \rCopyright 2017 Smiteworks.\rBy Kelrugem.\rApply the 'FORTIF: (N) [damage type], all' effect for fortification against damage types with percentage (N). Apply the 'HRESIST: [damage type], all' effect to half the damage of that damage type for that actor. Works on PCs and NPCs. Also a bug fix for the correct order such that 1. HRESIST, 2. RESIST, 3. VULN. Refreshes the Immediate box at the end of turn. Ghost touch: Add 'ghost touch' as an effect and as a dmg type."
	ChatManager.registerLaunchMessage(msg);	
end