-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function isPFRPG()
	return false;
end

-- Abilities (database names)
abilities = {
	"strength",
	"dexterity",
	"constitution",
	"intelligence",
	"wisdom",
	"charisma"
};

ability_ltos = {
	["strength"] = "STR",
	["dexterity"] = "DEX",
	["constitution"] = "CON",
	["intelligence"] = "INT",
	["wisdom"] = "WIS",
	["charisma"] = "CHA"
};

ability_stol = {
	["STR"] = "strength",
	["DEX"] = "dexterity",
	["CON"] = "constitution",
	["INT"] = "intelligence",
	["WIS"] = "wisdom",
	["CHA"] = "charisma"
};

-- Saves
save_ltos = {
	["fortitude"] = "FORT",
	["reflex"] = "REF",
	["will"] = "WILL"
};

save_stol = {
	["FORT"] = "fortitude",
	["REF"] = "reflex",
	["WILL"] = "will"
};

-- Values for wound comparison
healthstatusfull = "healthy";
healthstatushalf = "bloodied";
healthstatuswounded = "wounded";

-- Values for alignment comparison
alignment_lawchaos = {
	["lawful"] = 1,
	["chaotic"] = 3,
	["lg"] = 1,
	["ln"] = 1,
	["le"] = 1,
	["cg"] = 3,
	["cn"] = 3,
	["ce"] = 3,
};
alignment_goodevil = {
	["good"] = 1,
	["evil"] = 3,
	["lg"] = 1,
	["le"] = 3,
	["ng"] = 1,
	["ne"] = 3,
	["cg"] = 1,
	["ce"] = 3,
};
alignment_neutral = "n";

-- Values for size comparison
creaturesize = {
	["fine"] = -4,
	["diminutive"] = -3,
	["tiny"] = -2,
	["small"] = -1,
	["medium"] = 0,
	["large"] = 1,
	["huge"] = 2,
	["gargantuan"] = 3,
	["colossal"] = 4,
	["f"] = -4,
	["d"] = -3,
	["t"] = -2,
	["s"] = -1,
	["m"] = 0,
	["l"] = 1,
	["h"] = 2,
	["g"] = 3,
	["c"] = 4,
};

-- Values for creature type comparison
creaturedefaulttype = "humanoid";
creaturehalftype = "half-";
creaturehalftypesubrace = "human";
creaturetype = {
	"aberration",
	"animal",
	"construct",
	"dragon",
	"fey",
	"giant",
	"humanoid",
	"magical beast",
	"monstrous humanoid",
	"ooze",
	"outsider",
	"plant",
	"undead",
	"vermin",
};
creaturesubtype = {
	"air", -- Monster subtypes
	"angel",
	"aquatic",
	"archon",
	"augmented",
	"chaotic",
	"cold",
	"demon",
	"devil",
	"earth",
	"evil",
	"extraplanar",
	"fire",
	"good",
	"incorporeal",
	"lawful",
	"living construct",
	"native",
	"psionic",
	"shapechanger",
	"swarm",
	"water",
	"dwarf", -- Humanoid subtypes
	"elf", 
	"gnoll",
	"gnome", 
	"goblinoid",
	"halfling",
	"human",
	"orc",
	"reptilian",
};

-- Values supported in effect conditionals
conditionaltags = {
};

-- Conditions supported in effect conditionals and for token widgets
-- NOTE: From rules, missing dying, staggered and disabled
conditions = {
	"blinded", 
	"climbing",
	"confused",
	"cowering",
	"dazed",
	"dazzled",
	"deafened", 
	"entangled", 
	"exhausted",
	"fascinated",
	"fatigued",
	"flat-footed",
	"frightened", 
	"grappled", 
	"helpless",
	"incorporeal", 
	"invisible", 
	"kneeling",
	"nauseated",
	"panicked", 
	"paralyzed",
	"petrified",
	"pinned", 
	"prone", 
	"rebuked",
	"running",
	"shaken", 
	"sickened", 
	"sitting",
	"slowed", 
	"squeezing", 
	"stable", 
	"stunned",
	"turned",
	"unconscious"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"INIT",
	"ABIL",
	"AC",
	"ATK",
	"CMB",
	"CMD",
	"DMG",
	"DMGS",
	"HEAL",
	"SAVE",
	"SKILL",
	"STR",
	"CON",
	"DEX",
	"INT",
	"WIS",
	"CHA",
	"FORT",
	"REF",
	"WILL"
};

-- Condition effect types for token widgets
condcomps = {
	["blinded"] = "cond_blinded",
	["confused"] = "cond_confused",
	["cowering"] = "cond_cowering",
	["dazed"] = "cond_dazed",
	["dazzled"] = "cond_dazzled",
	["deafened"] = "cond_deafened",
	["entangled"] = "cond_entangled",
	["exhausted"] = "cond_exhausted",
	["fascinated"] = "cond_fascinated",
	["fatigued"] = "cond_fatigued",
	["flatfooted"] = "cond_flatfooted",
	["frightened"] = "cond_frightened",
	["grappled"] = "cond_grappled",
	["helpless"] = "cond_helpless",
	["incorporeal"] = "cond_incorporeal",
	["invisible"] = "cond_invisible",
	["nauseated"] = "cond_nauseated",
	["panicked"] = "cond_panicked",
	["paralyzed"] = "cond_paralyzed",
	["petrified"] = "cond_petrified",
	["pinned"] = "cond_pinned",
	["prone"] = "cond_prone",
	["rebuked"] = "cond_rebuked",
	["shaken"] = "cond_shaken",
	["sickened"] = "cond_sickened",
	["slowed"] = "cond_slowed",
	["stunned"] = "cond_stunned",
	["turned"] = "cond_turned",
	["unconscious"] = "cond_unconscious"
};

-- Other visible effect types for token widgets
othercomps = {
	["CONC"] = "cond_conceal",
	["TCONC"] = "cond_conceal",
	["COVER"] = "cond_cover",
	["SCOVER"] = "cond_cover",
	["NLVL"] = "cond_nlvl",
	["IMMUNE"] = "cond_immune",
	["RESIST"] = "cond_resist",
	["VULN"] = "cond_vuln",
	["REGEN"] = "cond_regen",
	["FHEAL"] = "cond_fheal",
	["DMGO"] = "cond_ongoing"
};

-- Effect components which can be targeted
targetableeffectcomps = {
	"CONC",
	"TCONC",
	"COVER",
	"SCOVER",
	"AC",
	"CMD",
	"SAVE",
	"ATK",
	"CMB",
	"DMG",
	"IMMUNE",
	"VULN",
	"RESIST"
};

connectors = {
	"and",
	"or"
};

-- Range types supported
rangetypes = {
	"melee",
	"ranged"
};

-- Damage types supported
energytypes = {
	"acid",  		-- ENERGY DAMAGE TYPES
	"cold",
	"electricity",
	"fire",
	"sonic",
	"force",  		-- OTHER SPELL DAMAGE TYPES
	"positive",
	"negative"
};

immunetypes = {
	"acid",  		-- ENERGY DAMAGE TYPES
	"cold",
	"electricity",
	"fire",
	"sonic",
	"nonlethal",	-- SPECIAL DAMAGE TYPES
	"critical",
	"poison",		-- OTHER IMMUNITY TYPES
	"sleep",
	"paralysis",
	"petrification",
	"charm",
	"sleep",
	"fear",
	"disease",
	"mind-affecting",
};

dmgtypes = {
	"acid",  		-- ENERGY DAMAGE TYPES
	"cold",
	"electricity",
	"fire",
	"sonic",
	"force",  		-- OTHER SPELL DAMAGE TYPES
	"positive",
	"negative",
	"adamantine", 	-- WEAPON PROPERTY DAMAGE TYPES
	"bludgeoning",
	"cold iron",
	"epic",
	"magic",
	"piercing",
	"silver",
	"slashing",
	"chaotic",		-- ALIGNMENT DAMAGE TYPES
	"evil",
	"good",
	"lawful",
	"nonlethal",	-- SPECIAL DAMAGE TYPES
	"spell",
	"critical",
	"precision",
	"ghost touch",
};

basicdmgtypes = {
	"acid",  		-- ENERGY DAMAGE TYPES
	"cold",
	"electricity",
	"fire",
	"sonic",
	"force",  		-- OTHER SPELL DAMAGE TYPES
	"positive",
	"negative",
	"bludgeoning", 	-- WEAPON PROPERTY DAMAGE TYPES
	"piercing",
	"slashing",
};

specialdmgtypes = {
	"nonlethal",
	"spell",
	"critical",
	"precision",
};

-- Bonus types supported in power descriptions
bonustypes = {
	"alchemical",
	"armor",
	"circumstance",
	"competence",
	"deflection",
	"dodge",
	"enhancement",
	"insight",
	"luck",
	"morale",
	"natural",
	"profane",
	"racial",
	"resistance",
	"sacred",
	"shield",
	"size",
	"trait",
};

stackablebonustypes = {
	"circumstance",
	"dodge",
};

-- Armor class bonus types
-- (Map text types to internal types)
actypes = {
	["dex"] = "dex",
	["armor"] = "armor",
	["shield"] = "shield",
	["natural"] = "natural",
	["dodge"] = "dodge",
	["deflection"] = "deflection",
	["size"] = "size",
};
acarmormatch = {
	"padded",
	"padded armor",
	"padded barding",
	"leather",
	"leather armor",
	"leather barding",
	"studded leather",
	"studded leather armor",
	"studded leather barding",
	"chain shirt",
	"chain shirt barding",
	"hide",
	"hide armor",
	"hide barding",
	"scale mail",
	"scale mail barding",
	"chainmail",
	"chainmail barding",
	"breastplate",
	"breastplate barding",
	"splint mail",
	"splint mail barding",
	"banded mail",
	"banded mail barding",
	"half-plate",
	"half-plate armor",
	"half-plate barding",
	"full plate",
	"full plate armor",
	"full plate barding",
	"plate barding",
	"bracers of armor",
	"mithral chain shirt",
};
acshieldmatch = {
	"buckler",
	"light shield",
	"light wooden shield",
	"light steel shield",
	"heavy shield",
	"heavy wooden shield",
	"heavy steel shield",
	"tower shield",
};
acdeflectionmatch = {
	"ring of protection"
};

-- Spell effects supported in spell descriptions
spelleffects = {
	"blinded",
	"confused",
	"cowering",
	"dazed",
	"dazzled",
	"deafened",
	"entangled",
	"exhausted",
	"fascinated",
	"frightened",
	"helpless",
	"invisible",
	"panicked",
	"paralyzed",
	"shaken",
	"sickened",
	"slowed",
	"stunned",
	"unconscious"
};

-- NPC damage properties
weapondmgtypes = {
	["axe"] = "slashing",
	["battleaxe"] = "slashing",
	["bolas"] = "bludgeoning,nonlethal",
	["chain"] = "piercing",
	["club"] = "bludgeoning",
	["crossbow"] = "piercing",
	["dagger"] = "piercing,slashing",
	["dart"] = "piercing",
	["falchion"] = "slashing",
	["flail"] = "bludgeoning",
	["glaive"] = "slashing",
	["greataxe"] = "slashing",
	["greatclub"] = "bludgeoning",
	["greatsword"] = "slashing",
	["guisarme"] = "slashing",
	["halberd"] = "piercing,slashing",
	["hammer"] = "bludgeoning",
	["handaxe"] = "slashing",
	["javelin"] = "piercing",
	["kama"] = "slashing",
	["kukri"] = "slashing",
	["lance"] = "piercing",
	["longbow"] = "piercing",
	["longspear"] = "piercing",
	["longsword"] = "slashing",
	["mace"] = "bludgeoning",
	["morningstar"] = "bludgeoning,piercing",
	["nunchaku"] = "bludgeoning",
	["pick"] = "piercing",
	["quarterstaff"] = "bludgeoning",
	["ranseur"] = "piercing",
	["rapier"] = "piercing",
	["sai"] = "bludgeoning",
	["sap"] = "bludgeoning,nonlethal",
	["scimitar"] = "slashing",
	["scythe"] = "piercing,slashing",
	["shortbow"] = "piercing",
	["shortspear"] = "piercing",
	["shuriken"] = "piercing",
	["siangham"] = "piercing",
	["sickle"] = "slashing",
	["sling"] = "bludgeoning",
	["spear"] = "piercing",
	["sword"] = {["short"] = "piercing", ["*"] = "slashing"},
	["trident"] = "piercing",
	["urgrosh"] = "piercing,slashing",
	["waraxe"] = "slashing",
	["warhammer"] = "bludgeoning",
	["whip"] = "slashing"
}

naturaldmgtypes = {
	["arm"] = "bludgeoning",
	["bite"] = "piercing,slashing,bludgeoning",
	["butt"] = "bludgeoning",
	["claw"] =  "piercing,slashing",
	["foreclaw"] =  "piercing,slashing",
	["gore"] = "piercing",
	["hoof"] = "bludgeoning",
	["hoove"] = "bludgeoning",
	["horn"] = "piercing",
	["pincer"] = "bludgeoning",
	["quill"] = "piercing",
	["ram"] = "bludgeoning",
	["rock"] = "bludgeoning",
	["slam"] = "bludgeoning",
	["snake"] = "piercing,slashing,bludgeoning",
	["spike"] = "piercing",
	["stamp"] = "bludgeoning",
	["sting"] = "piercing",
	["swarm"] = "piercing,slashing,bludgeoning",
	["tail"] = "bludgeoning",
	["talon"] =  "piercing,slashing",
	["tendril"] = "bludgeoning",
	["tentacle"] = "bludgeoning",
	["wing"] = "bludgeoning",
}

-- Skill properties
sensesdata = {
	["Listen"] = {
			stat = "wisdom"
		},
	["Spot"] = {
			stat = "wisdom"
		},
}

skilldata = {
	["Appraise"] = {
			stat = "intelligence"
		},
	["Balance"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Bluff"] = {
			stat = "charisma"
		},
	["Climb"] = {
			stat = "strength",
			armorcheckmultiplier = 1
		},
	["Concentration"] = {
			stat = "constitution"
		},
	["Craft"] = {
			sublabeling = true,
			stat = "intelligence"
		},
	["Decipher Script"] = {
			stat = "intelligence",
			trainedonly = 1
		},
	["Diplomacy"] = {
			stat = "charisma"
		},
	["Disable Device"] = {
			stat = "intelligence",
			trainedonly = 1
		},
	["Disguise"] = {
			stat = "charisma"
		},
	["Escape Artist"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Forgery"] = {
			stat = "intelligence"
		},
	["Gather Information"] = {
			stat = "charisma"
		},
	["Handle Animal"] = {
			stat = "charisma",
			trainedonly = 1
		},
	["Heal"] = {
			stat = "wisdom"
		},
	["Hide"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Intimidate"] = {
			stat = "charisma"
		},
	["Jump"] = {
			stat = "strength",
			armorcheckmultiplier = 1
		},
	["Knowledge"] = {
			sublabeling = true,
			stat = "intelligence",
			trainedonly = 1
		},
	["Listen"] = {
			stat = "wisdom"
		},
	["Move Silently"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1
		},
	["Open Lock"] = {
			stat = "dexterity",
			trainedonly = 1
		},
	["Perform"] = {
			sublabeling = true,
			stat = "charisma"
		},
	["Profession"] = {
			sublabeling = true,
			stat = "wisdom",
			trainedonly = 1
		},
	["Ride"] = {
			stat = "dexterity"
		},
	["Search"] = {
			stat = "intelligence"
		},
	["Sense Motive"] = {
			stat = "wisdom"
		},
	["Sleight of Hand"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1,
			trainedonly = 1
		},
	["Speak Language"] = {
		},
	["Spellcraft"] = {
			stat = "intelligence",
			trainedonly = 1
		},
	["Spot"] = {
			stat = "wisdom"
		},
	["Survival"] = {
			stat = "wisdom"
		},
	["Swim"] = {
			stat = "strength",
			armorcheckmultiplier = 2
		},
	["Tumble"] = {
			stat = "dexterity",
			armorcheckmultiplier = 1,
			trainedonly = 1
		},
	["Use Magic Device"] = {
			stat = "charisma",
			trainedonly = 1
		},
	["Use Rope"] = {
			stat = "dexterity"
		}
}

-- Coin labels
currency = { "PP", "GP", "SP", "CP" };

-- Party sheet drop down list data
psabilitydata = {
	"Strength",
	"Dexterity",
	"Constitution",
	"Intelligence",
	"Wisdom",
	"Charisma"
};

pssavedata = {
	"Fortitude",
	"Reflex",
	"Will"
};

psskilldata = {
	"Bluff",
	"Climb",
	"Diplomacy",
	"Gather Information",
	"Heal",
	"Hide",
	"Jump",
	"Intimidate",
	"Knowledge (Arcana)",
	"Knowledge (Dungeoneering)",
	"Knowledge (Local)",
	"Knowledge (Nature)",
	"Knowledge (Planes)",
	"Knowledge (Religion)",
	"Listen",
	"Move Silently",
	"Search",
	"Spot",
	"Survival"
};

-- PC/NPC Class properties

class_stol = {
	["brb"] = "barbarian",
	["brd"] = "bard",
	["clr"] = "cleric",
	["drd"] = "druid",
	["ftr"] = "fighter",
	["mnk"] = "monk",
	["pal"] = "paladin",
	["rgr"] = "ranger",
	["rog"] = "rogue",
	["sor"] = "sorcerer",
	["wiz"] = "wizard",
};

classdata = {
	-- Core
	["barbarian"] = {
		hd = "d12", bab = "fast", fort = "good", ref = "bad", will = "bad", skillranks = 4,
		skills = "Climb (Str), Craft (Int), Handle Animal (Cha), Intimidate (Cha), Jump (Str), Listen (Wis), Ride (Dex), Survival (Wis), and Swim (Str)",
	},
	["bard"] = {
		hd = "d6", bab = "medium", fort = "bad", ref = "good", will = "good", skillranks = 6,
		skills = "Appraise (Int), Balance (Dex), Bluff (Cha), Climb (Str), Concentration (Con), Craft (Int), Decipher Script (Int), Diplomacy (Cha), Disguise (Cha), Escape Artist (Dex), Gather Information (Cha), Hide (Dex), Jump (Str), Knowledge (all skills, taken individually) (Int), Listen (Wis), Move Silently (Dex), Perform (Cha), Profession (Wis), Sense Motive (Wis), Sleight of Hand (Dex), Speak Language (None), Spellcraft (Int), Swim (Str), Tumble (Dex), and Use Magic Device (Cha)",
	},
	["cleric"] = {
		hd = "d8", bab = "medium", fort = "good", ref = "bad", will = "good", skillranks = 2,
		skills = " Concentration (Con), Craft (Int), Diplomacy (Cha), Heal (Wis), Knowledge (arcana) (Int), Knowledge (history) (Int), Knowledge (religion) (Int), Knowledge (the planes) (Int), Profession (Wis), and Spellcraft (Int)",
	},
	["druid"] = {
		hd = "d8", bab = "medium", fort = "good", ref = "bad", will = "good", skillranks = 4,
		skills = "Concentration (Con), Craft (Int), Diplomacy (Cha), Handle Animal (Cha), Heal (Wis), Knowledge (nature) (Int), Listen (Wis), Profession (Wis), Ride (Dex), Spellcraft (Int), Spot (Wis), Survival (Wis), and Swim (Str)",
	},
	["fighter"] = {
		hd = "d10", bab = "fast", fort = "good", ref = "bad", will = "bad", skillranks = 2,
		skills = "Climb (Str), Craft (Int), Handle Animal (Cha), Intimidate (Cha), Jump (Str), Ride (Dex), and Swim (Str)",
	},
	["monk"] = {
		hd = "d8", bab = "medium", fort = "good", ref = "good", will = "good", skillranks = 4,
		skills = "Balance (Dex), Climb (Str), Concentration (Con), Craft (Int), Diplomacy (Cha), Escape Artist (Dex), Hide (Dex), Jump (Str), Knowledge (arcana) (Int), Knowledge (religion) (Int), Listen (Wis), Move Silently (Dex), Perform (Cha), Profession (Wis), Sense Motive (Wis), Spot (Wis), Swim (Str), and Tumble (Dex)",
	},
	["paladin"] = {
		hd = "d10", bab = "fast", fort = "good", ref = "bad", will = "bad", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Diplomacy (Cha), Handle Animal (Cha), Heal (Wis), Knowledge (nobility and royalty) (Int), Knowledge (religion) (Int), Profession (Wis), Ride (Dex), and Sense Motive (Wis)",
	},
	["ranger"] = {
		hd = "d8", bab = "fast", fort = "good", ref = "good", will = "bad", skillranks = 6,
		skills = "Climb (Str), Concentration (Con), Craft (Int), Handle Animal (Cha), Heal (Wis), Hide (Dex), Jump (Str), Knowledge (dungeoneering) (Int), Knowledge (geography) (Int), Knowledge (nature) (Int), Listen (Wis), Move Silently (Dex), Profession (Wis), Ride (Dex), Search (Int), Spot (Wis), Survival (Wis), Swim (Str), and Use Rope (Dex)",
	},
	["rogue"] = {
		hd = "d6", bab = "medium", fort = "bad", ref = "good", will = "bad", skillranks = 8,
		skills = "Appraise (Int), Balance (Dex), Bluff (Cha), Climb (Str), Craft (Int), Decipher Script (Int), Diplomacy (Cha), Disable Device (Int), Disguise (Cha), Escape Artist (Dex), Forgery (Int), Gather Information (Cha), Hide (Dex), Intimidate (Cha), Jump (Str), Knowledge (local) (Int), Listen (Wis), Move Silently (Dex), Open Lock (Dex), Perform (Cha), Profession (Wis), Search (Int), Sense Motive (Wis), Sleight of Hand (Dex), Spot (Wis), Swim (Str), Tumble (Dex), Use Magic Device (Cha), and Use Rope (Dex)",
	},
	["sorcerer"] = {
		hd = "d4", bab = "slow", fort = "bad", ref = "bad", will = "good", skillranks = 2,
		skills = "Bluff (Cha), Concentration (Con), Craft (Int), Knowledge (arcana) (Int), Profession (Wis), and Spellcraft (Int)",
	},
	["wizard"] = {
		hd = "d4", bab = "slow", fort = "bad", ref = "bad", will = "good", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Decipher Script (Int), Knowledge (all skills, taken individually) (Int), Profession (Wis), and Spellcraft (Int)",
	},
	-- NPC
	["adept"] = {
		hd = "d6", bab = "slow", fort = "bad", ref = "bad", will = "good", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Handle Animal (Cha), Heal (Wis), Knowledge (all skills taken individually) (Int), Profession (Wis), Spellcraft (Int), and Survival (Wis)",
	},
	["aristocrat"] = {
		hd = "d8", bab = "medium", fort = "bad", ref = "bad", will = "good", skillranks = 4,
		skills = "Appraise (Int), Bluff (Cha), Diplomacy (Cha), Disguise (Cha), Forgery (Int), Gather Information (Cha), Handle Animal (Cha), Intimidate (Cha), Knowledge (all skills taken individually) (Int), Listen (Wis), Perform (Cha), Ride (Dex), Sense Motive (Wis), Speak Language (None), Spot (Wis), Swim (Str), and Survival (Wis)",
	},
	["commoner"] = {
		hd = "d4", bab = "slow", fort = "bad", ref = "bad", will = "bad", skillranks = 2,
		skills = "Climb (Str), Craft (Int), Handle Animal (Cha), Jump (Str), Listen (Wis), Profession (Wis), Ride (Dex), Spot (Wis), Swim (Str), and Use Rope (Dex)",
	},
	["expert"] = {
		hd = "d6", bab = "medium", fort = "bad", ref = "bad", will = "good", skillranks = 6,
		skills = "Any 10",
	},
	["warrior"] = {
		hd = "d8", bab = "fast", fort = "good", ref = "bad", will = "bad", skillranks = 2,
		skills = "Climb (Str), Handle Animal (Cha), Intimidate (Cha), Jump (Str), Ride (Dex), and Swim (Str)",
	},
	-- Prestige
	["arcane archer"] = {
		bPrestige = true, hd = "d8", bab = "fast", fort = "good", ref = "good", will = "bad", skillranks = 4,
		skills = "Craft (Int), Hide (Dex). Listen (Wis), Move Silently (Dex), Ride (Dex), Spot (Wis), Survival (Wis), and Use Rope (Dex)",
	},
	["arcane trickster"] = {
		bPrestige = true, hd = "d4", bab = "slow", fort = "bad", ref = "good", will = "good", skillranks = 4,
		skills = "Appraise (Int), Balance (Dex), Bluff (Cha), Climb (Str), Concentration (Con), Craft (Int), Decipher Script (Int), Diplomacy (Cha), Disable Device (Int), Disguise (Cha), Escape Artist (Dex), Gather Information (Cha), Hide (Dex), Jump (Str), Knowledge (all skills taken individually) (Int), Listen (Wis), Move Silently (Dex), Open Lock (Dex), Profession (Wis), Search (Int), Sense Motive (Wis), Sleight of Hand (Dex), Speak Language (None), Spellcraft (Int), Spot (Wis), Swim (Str), Tumble (Dex), and Use Rope (Dex)",
	},
	["archmage"] = {
		bPrestige = true, hd = "d4", bab = "slow", fort = "bad", ref = "bad", will = "good", skillranks = 2,
		skills = "Concentration (Con), Craft (alchemy) (Int), Knowledge (all skills taken individually) (Int), Profession (Wis), Search (Int), and Spellcraft (Int)",
	},
	["assassin"] = {
		bPrestige = true, hd = "d6", bab = "medium", fort = "bad", ref = "good", will = "bad", skillranks = 4,
		skills = "Balance (Dex), Bluff (Cha), Climb (Str), Craft (Int), Decipher Script (Int), Diplomacy (Cha), Disable Device (Int), Disguise (Cha), Escape Artist (Dex), Forgery (Int), Gather Information (Cha), Hide (Dex), Intimidate (Cha), Jump (Str), Listen (Wis), Move Silently (Dex), Open Lock (Dex), Search (Int), Sense Motive (Wis), Sleight of Hand (Dex), Spot (Wis), Swim (Str), Tumble (Dex), Use Magic Device (Cha), and Use Rope (Dex)",
	},
	["blackguard"] = {
		bPrestige = true, hd = "d10", bab = "fast", fort = "good", ref = "bad", will = "bad", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Diplomacy (Cha), Handle Animal (Cha), Heal (Wis), Hide (Dex), Intimidate (Cha), Knowledge (religion) (Int), Profession (Wis), and Ride (Dex)",
	},
	["dragon disciple"] = {
		bPrestige = true, hd = "d12", bab = "medium", fort = "good", ref = "bad", will = "good", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Diplomacy (Cha), Escape Artist (Dex), Gather Information (Cha), Knowledge (all skills, taken individually) (Int), Listen (Wis), Profession (Wis), Search (Int), Speak Language (None), Spellcraft (Int), and Spot (Wis)",
	},
	["duelist"] = {
		bPrestige = true, hd = "d10", bab = "fast", fort = "bad", ref = "good", will = "bad", skillranks = 4,
		skills = "Balance (Dex), Bluff (Cha), Escape Artist (Dex), Jump (Str), Listen (Wis), Perform (Cha), Sense Motive (Wis), Spot (Wis), and Tumble (Dex)",
	},
	["dwarven defender"] = {
		bPrestige = true, hd = "d12", bab = "fast", fort = "good", ref = "bad", will = "good", skillranks = 2,
		skills = "Craft (Int), Listen (Wis), Sense Motive (Wis), and Spot (Wis)",
	},
	["eldritch knight"] = {
		bPrestige = true, hd = "d6", bab = "fast", fort = "good", ref = "bad", will = "bad", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Decipher Script (Int), Jump (Str), Knowledge (arcana) (Int), Knowledge (nobility and royalty) (Int), Ride (Dex), Sense Motive (Wis), Spellcraft (Int), and Swim (Str)",
	},
	["hierophant"] = {
		bPrestige = true, hd = "d8", bab = "slow", fort = "good", ref = "bad", will = "good", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Diplomacy (Cha), Heal (Wis), Knowledge (arcana) (Int), Knowledge (religion) (Int), Profession (Wis), and Spellcraft (Int)",
	},
	["horizon walker"] = {
		bPrestige = true, hd = "d8", bab = "fast", fort = "good", ref = "bad", will = "bad", skillranks = 4,
		skills = "Balance (Dex), Climb (Str), Diplomacy (Cha), Handle Animal (Cha), Hide (Dex), Knowledge (geography) (Int), Listen (Wis), Move Silently (Dex), Profession (Wis), Ride (Dex), Speak Language (None), Spot (Wis), and Survival (Wis)",
	},
	["loremaster"] = {
		bPrestige = true, hd = "d4", bab = "slow", fort = "bad", ref = "bad", will = "good", skillranks = 4,
		skills = "Appraise (Int), Concentration (Con), Craft (alchemy) (Int), Decipher Script (Int), Gather Information (Cha), Handle Animal (Cha), Heal (Wis), Knowledge (all skills taken individually) (Int), Perform (Cha), Profession (Wis), Speak Language (None), Spellcraft (Int), and Use Magic Device (Cha)",
	},
	["mystic theurge"] = {
		bPrestige = true, hd = "d4", bab = "slow", fort = "bad", ref = "bad", will = "good", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Decipher Script (Int), Knowledge (arcana) (Int), Knowledge (religion) (Int), Profession (Wis), Sense Motive (Wis), and Spellcraft (Int)",
	},
	["shadowdancer"] = {
		bPrestige = true, hd = "d8", bab = "medium", fort = "bad", ref = "good", will = "bad", skillranks = 6,
		skills = "Balance (Dex), Bluff (Cha), Decipher Script (Int), Diplomacy (Cha), Disguise (Cha), Escape Artist (Dex), Hide (Dex), Jump (Str), Listen (Wis), Move Silently (Dex), Perform (Cha), Profession (Wis), Search (Int), Sleight of Hand (Dex), Spot (Wis), Tumble (Dex), and Use Rope (Dex)",
	},
	["thaumaturgist"] = {
		bPrestige = true, hd = "d4", bab = "slow", fort = "bad", ref = "bad", will = "good", skillranks = 2,
		skills = "Concentration (Con), Craft (Int), Diplomacy (Cha), Knowledge (religion) (Int), Knowledge (the planes) (Int), Profession (Wis), Sense Motive (Wis), Speak Language (None), and Spellcraft (Int)",
	},
};
