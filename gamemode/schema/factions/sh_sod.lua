FACTION.isDefault = false

FACTION.image = "materials/backgroundgreyln.png"
FACTION.name = "Staff on Duty"
FACTION.description = ""
FACTION.noNeeds = true
FACTION.color = Color(50, 50, 50, 255)
FACTION.models = {
    Model("models/Combine_Super_Soldier.mdl"),
}

function FACTION:OnSpawn(client)
    client:SetMaxHealth(99999)
    client:SetHealth(99999)
end

function FACTION:GetDefaultName(client)
	return client:SteamName() .. " on Duty", true
end

function FACTION:OnCharacterCreated(client, character)
	character:GiveFlags("tpP")
end

FACTION_SOD = FACTION.index
