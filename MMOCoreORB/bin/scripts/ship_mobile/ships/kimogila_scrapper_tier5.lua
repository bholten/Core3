kimogila_scrapper_tier5 = ShipAgent:new {
	template = "hutt_light_s02_tier5",
	pilotTemplate = "light_fighter_tier5",
	shipType = "fighter",

	experience = 6039.8,

	lootChance = 0.117,
	lootRolls = 1,
	lootTable = "space_pirate_tier5",

	minCredits = 350,
	maxCredits = 750,

	aggressive = 0,

	spaceFaction = "pirate",
	alliedFactions = {"pirate", "nym"},
	enemyFactions = {"imperial", "rebel", "hutt", "valarian", "rsf", "corsec", "blacksun"},

	color1 = 38,
	color2 = 22,
	texture = 6,
	appearance = "generic_pirate",

	tauntType = "generic",
	tauntAttackChance = 0.1,
	tauntDefendChance = 0.05,
	tauntDieChance = 0.1,

	pvpBitmask = ATTACKABLE,
	shipBitmask = NONE,
	optionsBitmask = AIENABLED,

	customShipAiMap = "",

	conversationTemplate = "",
	conversationMobile = "",
	conversationMessage = "", --Too Far Message
}

ShipAgentTemplates:addShipAgentTemplate(kimogila_scrapper_tier5, "kimogila_scrapper_tier5")
