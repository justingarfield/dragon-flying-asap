
if UnitFactionGroup("player") ~= "Horde" then return end

local _, DragonFlyingASAP = ...
local requiredQuests = DragonFlyingASAP.requiredQuests

requiredQuests = {
    {
        name = "Dragon Flying - Step 1",
        quests = {
            {
                questId = 65435,    -- The Dragon Isles Await
                waypoints = {
                    {
                        uiMapID = 85,       -- Orgrimmar
                        coords  = 44093796, -- Ebyssian Coords
                        note = "Ebyssian"
                    }
                },
                note = "Turn-in quest at Ebyssian"
            }
        }
    },
    {
        name = "Dragon Flying - Step 2",
        quests = {
            {
                questId = 65437,    -- Aspectral Invitation (triggers QUEST_DETAIL first, GOSSIP_SHOW after accepting, )
                waypoints = {
                    {
                        uiMapID = 85,       -- Orgrimmar
                        coords  = 44093796, -- World Coords
                        note = "Ebyssian"
                    }
                },
                note = "Turn-in quest at Ebyssian"
            }
        }
    },
    {
        name = "Dragon Flying - Step 3",
        quests = {
            {
                questId = 65443     -- Expeditionary Coordination
            }
        }
    },
    {
        name = "Dragon Flying - Step 4",
        quests = {
            {
                questId = 72256     -- The Dark Talons
            }
        }
    },
    {
        name = "Dragon Flying - Step 5",
        quests = {
            {
                questId = 65439     -- Whispers on the Winds
            }
        }
    }
}
