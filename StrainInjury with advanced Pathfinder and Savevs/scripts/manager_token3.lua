-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	TokenManager.addDefaultHealthFeatures(getHealthInfo, {"injury"});
end
function getHealthInfo(nodeCT)
	local sColor, nPercentWounded, nPercentNonlethal, sStatus = ActorManager2.getWoundBarColor("ct", nodeCT);
	return nPercentNonlethal, sStatus, sColor;
end
