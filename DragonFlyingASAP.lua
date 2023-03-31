---------------------------------------------------------
-- Debugging
---------------------------------------------------------
local showDebugStatements = true
local showDebugVals = true
local showEventStatements = true

local debugIt = function(...)
    if showDebugStatements then
        DragonFlyingASAP:Print(...)
    end
end

local debugVals = function(...)
    if showDebugVals then
        DragonFlyingASAP:Print(...)
    end
end

local eventIt = function(...)
    if showEventStatements then
        DragonFlyingASAP:Print("EVENT:", ...)
    end
end


---------------------------------------------------------
-- Addon declaration
---------------------------------------------------------

DragonFlyingASAP = LibStub("AceAddon-3.0"):NewAddon("DragonFlyingASAP","AceConsole-3.0","AceEvent-3.0")

local _, namespace = ...

---------------------------------------------------------
-- Up-values
---------------------------------------------------------

local IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local HBD = LibStub("HereBeDragons-2.0");
local db


---------------------------------------------------------
-- Options table
---------------------------------------------------------

local addonOptions = {
    type = "group",
    name = "DragonFlyingASAP",
    desc = "Dragon Flying ASAP settings",
    get = function(info) return db[info[#info]] end,
    set = function(info, v)
        db[info[#info]] = v
        DragonFlyingASAP:SendMessage("DragonFlyingASAP_NotifyUpdate", "DragonFlyingASAP")
    end,
    args = {
        desc = {
            name = "These settings control the behavior of the addon.",
            type = "description",
            order = 0,
        },
        autoAcceptQuests = {
            name = "Auto-accept quests",
            desc = "Auto-accept quests related to Dragon Flying",
            type = "toggle",
            arg = "auto_accept_quests",
            order = 10,
        },
        autoAbandon = {
            name = "Auto-abandon quests",
            desc = "Auto-abandon any quests you accept that aren't related to dragon flying?",
            type = "toggle",
            arg = "auto_abandon_quests",
            order = 20,
        },
        autoSkipCinematics = {
            name = "Auto-skip cinematics",
            desc = "Auto-skip cinematics",
            type = "toggle",
            arg = "auto_skip_cinematics",
            order = 30,
        },
        autoSkipTalkingHeads = {
            name = "Auto-skip talking heads",
            desc = "Auto-skip talking heads",
            type = "toggle",
            arg = "auto_skip_talking_heads",
            order = 40,
        }
    }
}


---------------------------------------------------------
-- Local Variables
---------------------------------------------------------

local addonReady = false
local waypointAddedForCurrentStep = false
local deferredStartupTime = 3 -- in seconds

local defaults = {
    profile = {
        auto_accept_quests = true,
        auto_abandon_quests = true,
        auto_skip_cinematics = true,
        auto_skip_talking_heads = true
    }
}

local STEP_TYPE = {
    QuestStart = 1,
    QuestObjective = 2,
    QuestTurnIn = 3
}

local QUEST_IDS = {
    AspectralInvitation = 65437,
    ExpeditionaryCoordination = 65443,
    TheDarkTalons = 72256,
    WhispersOnTheWinds = 65439,
    ToTheDragonIsles = 65444,
    ExplorersInPeril = 65452,
    PrimalPests = 65453,
    PracticeMaterials = 65451
}

local UI_MAP_IDS = {
    Orgrimmar = 85,
    Durotar = 1,
    TheWakingShores = 2022
}

local ADDON_TIMINGS = {
    DeferredStartup = 3,
    AddonLoop = 15,
    GossipDeferral = 2
}

-- These are quests that automatically pop-up in-game upon login or entering a certain area
local dragonFlyingAutoPopupQuests = {
    TheDragonIslesAwait = 65435,  -- Encountered when creating brand-new 60 on Beta realm
    TheCallOfTheIsles = 70198     -- Encountered when copying existing 60 to Beta realm w/ all Pre-Release done
}

-- each one of these blocks is a 'step' required to be completed in-order to acquire dragon flying and all upgrades
local dragonFlyingSteps = {
    {
        questID = QUEST_IDS.TheDragonIslesAwait,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 44083799,
            title = "Acquire quest from Ebyssian in Orgrimmar; or from auto-popup"
        }
    },
    {
        questID = QUEST_IDS.TheDragonIslesAwait,
        type = STEP_TYPE.QuestTurnIn,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 44083799,
            title = "Turn-in quest to Ebyssian in Orgrimmar"
        }
    },
    {
        questID = QUEST_IDS.AspectralInvitation,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 44083799,
            title = "Acquire quest from Ebyssian in Orgrimmar"
        }
    },
    {
        questID = QUEST_IDS.AspectralInvitation,
        type = STEP_TYPE.QuestTurnIn,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 44083799,
            title = "Turn-in quest at Ebyssian in Orgrimmar"
        },
        notes = "Must watch cinematic to complete quest."
    },
    {
        questID = QUEST_IDS.ExpeditionaryCoordination,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 44183778,
            title = "Acquire quest from Naleidea Rivergleam in Orgrimmar (next to Ebyssian)."
        }
    },
    {
        questID = QUEST_IDS.TheDarkTalons,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 44043827,
            title = "Acquire quest from Scalecommander Cindrethresh in Orgrimmar (next to Ebyssian)."
        }
    },
    {
        questID = QUEST_IDS.ExpeditionaryCoordination,
        type = STEP_TYPE.QuestObjective,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 38605693,
            title = "Talk with Pathfinder Tacha"
        },
        objectiveIndex = 2
    },
    {
        questID = QUEST_IDS.ExpeditionaryCoordination,
        type = STEP_TYPE.QuestObjective,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 57105413,
            title = "Talk with Boss Magor"
        },
        objectiveIndex = 1
    },
    {
        questID = QUEST_IDS.ExpeditionaryCoordination,
        type = STEP_TYPE.QuestObjective,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 71455064,
            title = "Talk with Cataloger Coralie"
        },
        objectiveIndex = 3
    },
    {
        questID = QUEST_IDS.TheDarkTalons,
        type = STEP_TYPE.QuestObjective,
        waypoint = {
            uiMapID = UI_MAP_IDS.Orgrimmar,
            coords  = 55068960,
            title = "Deliver orders to Kodethi (on top of Gates of Orgrimmar)"
        },
        objectiveIndex = 1
    },
    {
        questID = QUEST_IDS.ExpeditionaryCoordination,
        type = STEP_TYPE.QuestTurnIn,
        waypoint = {
            uiMapID = UI_MAP_IDS.Durotar,
            coords  = 55811267,
            title = "Turn-in quest to Naleidea Rivergleam (outside Org at new zepplin tower)"
        }
    },
    {
        questID = QUEST_IDS.TheDarkTalons,
        type = STEP_TYPE.QuestTurnIn,
        waypoint = {
            uiMapID = UI_MAP_IDS.Durotar,
            coords  = 55811267,
            title = "Turn-in quest to Naleidea Rivergleam (outside Org at new zepplin tower)"
        }
    },
    {
        questID = QUEST_IDS.WhispersOnTheWinds,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.Durotar,
            coords  = 55921261,
            title = "Acquire quest from Khadghar (outside Org at new zepplin tower)"
        }
    },
    {
        questID = QUEST_IDS.WhispersOnTheWinds,
        type = STEP_TYPE.QuestTurnIn,
        waypoint = {
            uiMapID = UI_MAP_IDS.Durotar,
            coords  = 55851274,
            title = "Turn-in quest to Ebyssian (outside Org at new zepplin tower)"
        }
    },
    {
        questID = QUEST_IDS.ToTheDragonIsles,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.Durotar,
            coords  = 55811267,
            title = "Acquire quest from Naleidea Rivergleam (outside Org at new zepplin tower)"
        }
    },
    --{
    --    questID = QUEST_IDS.ToTheDragonIsles,
    --    type = STEP_TYPE.Custom,
    --    waypoint = {
    --        uiMapID = UI_MAP_IDS.Durotar,
    --        coords  = 55951324,
    --        title = "Wait for the new zepplin to arrive"
    --    }
    --},
    {
        questID = QUEST_IDS.ToTheDragonIsles,
        type = STEP_TYPE.QuestTurnIn,
        waypoint = {
            uiMapID = UI_MAP_IDS.TheWakingShores,
            coords  = 80622761,
            title = "Turn-in quest to Naleidea Rivergleam"
        }
    },
    {
        questID = QUEST_IDS.ExplorersInPeril,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.TheWakingShores,
            coords  = 80622761,
            title = "Acquire quest from Naleidea Rivergleam"
        }
    },
    {
        questID = QUEST_IDS.PrimalPests,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.TheWakingShores,
            coords  = 80652759,
            title = "Acquire quest from Scalecommander Cindrethresh"
        }
    },
    {
        questID = QUEST_IDS.PracticeMaterials,
        type = STEP_TYPE.QuestStart,
        waypoint = {
            uiMapID = UI_MAP_IDS.TheWakingShores,
            coords  = 80612766,
            title = "Acquire quest from Boss Magor"
        }
    },
    {
        questID = QUEST_IDS.PracticeMaterials,
        type = STEP_TYPE.QuestObjective,
        waypoint = {
            uiMapID = UI_MAP_IDS.TheWakingShores,
            coords  = 80362634,
            title = "Rescue Pathfinder Poppy"
        }
    },
    {
        questID = QUEST_IDS.PracticeMaterials,
        type = STEP_TYPE.QuestObjective,
        waypoint = {
            uiMapID = UI_MAP_IDS.TheWakingShores,
            coords  = 78722457,
            title = "Rescue Archivist Spearblossom"
        }
    },
    {
        questID = QUEST_IDS.PracticeMaterials,
        type = STEP_TYPE.QuestObjective,
        waypoint = {
            uiMapID = UI_MAP_IDS.TheWakingShores,
            coords  = 77322982,
            title = "Rescue Spelunker Lazee"
        }
    }
}


---------------------------------------------------------
-- Local Functions
---------------------------------------------------------

local displayToUser = function(...)
    DragonFlyingASAP:Print(...)
end

local getCoord = function(x, y)
	return floor(x * 10000 + 0.5) * 10000 + floor(y * 10000 + 0.5)
end

local getXY = function(coords)
	return floor(coords / 10000) / 10000, (coords % 10000) / 10000
end

local a = function()
end

local questInIndex = function(questID)
    for index, dragonFlyingStep in ipairs(dragonFlyingSteps) do
        if dragonFlyingStep.questID == questID then
            return true
        end
    end

    return false
end

local clearExistingWaypoints = function()
    debugIt("Clearing existing WoW UI waypoints")
    C_Map.ClearUserWaypoint()

    if TomTom then
        debugIt("Clearing existing TomTom waypoints")
        TomTom:ClearAllWaypoints()
    end
end

local displayWelcomeMessage = function()
    displayToUser("Waiting for in-game UI to render and other addons to load...")
    displayToUser("Please wait", ADDON_TIMINGS.DeferredStartup, "seconds for the addon to warm-up.")
end

local displayReadyMessage = function()
    displayToUser("Dragon Flying ASAP is now ready to go!")
    displayToUser("")
    displayToUser("Simply follow the waypoint markers and pick-up/turn-in required quests. Enjoy!")
end

local registerEventBindings = function()
    -- C_AchievementInfo related
    DragonFlyingASAP:RegisterEvent("ACHIEVEMENT_EARNED") -- Used as we collect Dragon Glyphs

    -- C_Cinematic related
    DragonFlyingASAP:RegisterEvent("CINEMATIC_START")

    -- C_GossipInfo related
    DragonFlyingASAP:RegisterEvent("GOSSIP_SHOW")

    -- C_QuestLog related
    DragonFlyingASAP:RegisterEvent("QUEST_ACCEPTED")
    DragonFlyingASAP:RegisterEvent("QUEST_COMPLETE")
    DragonFlyingASAP:RegisterEvent("QUEST_DATA_LOAD_RESULT")
    DragonFlyingASAP:RegisterEvent("QUEST_DETAIL")
    DragonFlyingASAP:RegisterEvent("QUEST_TURNED_IN")

    -- C_QuestOffer related
    DragonFlyingASAP:RegisterEvent("QUEST_GREETING")
    DragonFlyingASAP:RegisterEvent("QUEST_PROGRESS")

    -- C TalkingHead related
    DragonFlyingASAP:RegisterEvent("TALKINGHEAD_REQUESTED")

    DragonFlyingASAP:RegisterEvent("DYNAMIC_GOSSIP_POI_UPDATED", "MyHandler")
    DragonFlyingASAP:RegisterEvent("GOSSIP_CLOSED")
    DragonFlyingASAP:RegisterEvent("GOSSIP_CONFIRM", "MyHandler")
    DragonFlyingASAP:RegisterEvent("GOSSIP_CONFIRM_CANCEL", "MyHandler")
    DragonFlyingASAP:RegisterEvent("GOSSIP_ENTER_CODE", "MyHandler")
    DragonFlyingASAP:RegisterEvent("GOSSIP_OPTIONS_REFRESHED", "MyHandler")

    DragonFlyingASAP:RegisterEvent("PLAYER_ENTERING_WORLD")
end

local registerEventMonitors = function()
    -- C_AchievementInfo related
    DragonFlyingASAP:RegisterEvent("ACHIEVEMENT_PLAYER_NAME")
    DragonFlyingASAP:RegisterEvent("CRITERIA_COMPLETE")
    DragonFlyingASAP:RegisterEvent("CRITERIA_EARNED")
    DragonFlyingASAP:RegisterEvent("CRITERIA_UPDATE")
    DragonFlyingASAP:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
    DragonFlyingASAP:RegisterEvent("RECEIVED_ACHIEVEMENT_LIST")
    DragonFlyingASAP:RegisterEvent("RECEIVED_ACHIEVEMENT_MEMBER_LIST")
    DragonFlyingASAP:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED")
    DragonFlyingASAP:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE")

    -- C_AreaPoiInfo related
    DragonFlyingASAP:RegisterEvent("AREA_POIS_UPDATED")

    -- C_BehavioralMessaging related
    DragonFlyingASAP:RegisterEvent("BEHAVIORAL_NOTIFICATION")

    -- C_Cinematic related
    DragonFlyingASAP:RegisterEvent("CINEMATIC_STOP")
    DragonFlyingASAP:RegisterEvent("PLAY_MOVIE")
    DragonFlyingASAP:RegisterEvent("STOP_MOVIE")

    -- C_ClientScene related
    DragonFlyingASAP:RegisterEvent("CLIENT_SCENE_CLOSED")
    DragonFlyingASAP:RegisterEvent("CLIENT_SCENE_OPENED")

    -- C_QuestLog related
    DragonFlyingASAP:RegisterEvent("QUEST_AUTOCOMPLETE")
    DragonFlyingASAP:RegisterEvent("QUEST_LOG_CRITERIA_UPDATE")
    DragonFlyingASAP:RegisterEvent("QUEST_LOG_UPDATE")
    DragonFlyingASAP:RegisterEvent("QUEST_POI_UPDATE")
    DragonFlyingASAP:RegisterEvent("QUEST_REMOVED")

    DragonFlyingASAP:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
    DragonFlyingASAP:RegisterEvent("QUEST_WATCH_UPDATE")
    DragonFlyingASAP:RegisterEvent("QUESTLINE_UPDATE")
    DragonFlyingASAP:RegisterEvent("TASK_PROGRESS_UPDATE")
    DragonFlyingASAP:RegisterEvent("TREASURE_PICKER_CACHE_FLUSH")
    DragonFlyingASAP:RegisterEvent("WAYPOINT_UPDATE")
    DragonFlyingASAP:RegisterEvent("WORLD_QUEST_COMPLETED_BY_SPELL")

    -- C_LoadingScreen related
    DragonFlyingASAP:RegisterEvent("LOADING_SCREEN_DISABLED")
    DragonFlyingASAP:RegisterEvent("LOADING_SCREEN_ENABLED")

    -- C_LootJournal related
    DragonFlyingASAP:RegisterEvent("LOOT_JOURNAL_ITEM_UPDATE")

    -- C_LoreText related
    DragonFlyingASAP:RegisterEvent("LORE_TEXT_UPDATED_CAMPAIGN")

    -- C_ScriptedAnimations related
    DragonFlyingASAP:RegisterEvent("SCRIPTED_ANIMATIONS_UPDATE")

    -- C TalkingHead related
    DragonFlyingASAP:RegisterEvent("TALKINGHEAD_CLOSE")
end

local skipTalkingHead = function()
    if not C_TalkingHead.IsCurrentTalkingHeadIgnored() then
        C_TalkingHead.IgnoreCurrentTalkingHead()
    end
end

local isDragonFlyingQuest = function(questID)
    local expansionNum = GetQuestExpansion(questID)
    return expansionNum == 9
end

local currentWaypointExists = function(waypoint)
    debugIt("currentWaypointExists:", waypoint)

    local uiMapID, coords, title = waypoint.uiMapID, waypoint.coords, waypoint.title
    local x, y = getXY(coords)
    debugVals(uiMapID, coords, title, x, y)

    if TomTom then
        if waypoint.uid then
            debugIt("Checking if TomTom Waypoint is still valid")
            return TomTom:IsValidWaypoint(waypoint.uid)
        else
            debugIt("Checking if TomTom Waypoint exists for provided args")
            return TomTom:WaypointExists(uiMapID, x, y, title);
        end
    else
        debugIt("Checking if User Waypoint exists")
        return C_Map.HasUserWaypoint()
    end
end

local removeCurrentWaypoint = function(waypoint)
    debugIt("removeCurrentWaypoint:", waypoint)

    local uiMapID, coords, title = waypoint.uiMapID, waypoint.coords, waypoint.title
    local x, y = getXY(coords)
    debugVals(uiMapID, coords, title, x, y)

    if TomTom then
        if waypoint.uid then
            debugIt("Removing TomTom Waypoint")
            TomTom:RemoveWaypoint(waypoint.uid)
        else
            debugIt("Clearing All TomTom Waypoints")
            TomTom:ClearAllWaypoints();
        end
    else
        debugIt("Removing User Waypoint")
        C_Map.ClearUserWaypoint()
    end
end

local addWaypoint = function(waypoint)
    debugIt("addWaypoint:", waypoint)

    local uiMapID, coords, title = waypoint.uiMapID, waypoint.coords, waypoint.title
    local x, y = getXY(coords)
    debugVals(uiMapID, coords, title, x, y)

    if TomTom then
        debugIt("Adding TomTom waypoint")
        waypoint.uid = TomTom:SetCustomWaypoint(uiMapID, x, y, { title = title });
    else
        debugIt("Adding WoW UI waypoint")
        if C_Map.CanSetUserWaypointOnMap(uiMapID) then
            local mapPoint = UiMapPoint.CreateFromCoordinates(uiMapID, x ,y)
            C_Map.SetUserWaypoint(mapPoint);
        end
    end
end

local isStepCompleted = function(step)
    local alreadyStartedQuest = (step.type == STEP_TYPE.QuestStart and C_QuestLog.IsOnQuest(step.questID))
    if alreadyStartedQuest then
        debugIt("The quest for the step has already been started...Step Completed")
        return true
    end

    local alreadyCompletedObjective = (step.type == STEP_TYPE.QuestObjective and C_QuestLog.IsOnQuest(step.questID))
    if alreadyCompletedObjective then
        local objectives = C_QuestLog.GetQuestObjectives(step.questID)
        for index, objective in ipairs(objectives) do
            debugVals(index, objective.text, objective.type, objective.finished, objective.numFulfilled, objective.numRequired)
            if index == step.objectiveIndex and objective.finished then
                debugIt("The quest objective for the step has already been completed...Step Completed.")
                return true
            end
        end
    end

    local questAlreadyTurnedIn = C_QuestLog.IsQuestFlaggedCompleted(step.questID)
    if questAlreadyTurnedIn then
        debugIt("The quest for the step has already been completed and turned-in...Step Completed")
        return true
    end

    local customStep = (step.type == STEP_TYPE.Custom)
    if customStep then
        debugIt("Still need to sort-out custom steps")
        return true
    end

    return false
end

-- used to remove any already completed steps before the addon is marked as ready
local primeSteps = function()
    local tmpQuests = {}

    for index, dragonFlyingStep in ipairs(dragonFlyingSteps) do
        if isStepCompleted(dragonFlyingStep) then
            debugIt("Removed step", index, dragonFlyingStep.questID)
        else
            debugIt("Added step", index, dragonFlyingStep.questID)
            table.insert(tmpQuests, dragonFlyingStep)
        end
    end

    dragonFlyingSteps = tmpQuests
    tmpQuests = {}
end

local advanceToNextStep = function()
    local tmpQuests = {}

    for index, dragonFlyingStep in ipairs(dragonFlyingSteps) do
        if index > 1 then
            table.insert(tmpQuests, dragonFlyingStep)
        end
    end

    dragonFlyingSteps = tmpQuests
    tmpQuests = {}
end

local getCurrentStep = function ()
    namespace:debugIt("getCurrentStep")

    local currentStep = dragonFlyingSteps[1]
    namespace:debugVals(currentStep.questID, currentStep.type)

    local waypoint = currentStep.waypoint
    namespace:debugVals(waypoint.uiMapID, waypoint.coords, waypoint.title)

    return currentStep
end

local addWaypointForCurrentStep = function()
    debugIt("addWaypointForCurrentStep")

    local currentStep = getCurrentStep()

    addWaypoint(currentStep.waypoint)
    waypointAddedForCurrentStep = true;
end

-- Auto-accept quests like 'The Dragon Isles Await' that just appear immediately on login
local autoAcceptPopupQuests = function()
    debugIt("autoAcceptPopupQuests")

    for index=1, GetNumAutoQuestPopUps() do
        local questID, type = GetAutoQuestPopUp(index)
        if questID == QUEST_IDS.TheCallOfTheIsles then
            AcknowledgeAutoAcceptQuest()
            displayToUser("Auto-accepted auto-quest for questID", questID)
        end
        if questInIndex(questID) and type == "OFFER" then
            AcknowledgeAutoAcceptQuest()
            displayToUser("Auto-accepted auto-quest for questID", questID)
        end
    end
end

local addonUpdate = function()

    local currentStep = getCurrentStep()

    autoAcceptPopupQuests()

    if isStepCompleted(currentStep) then
        waypointAddedForCurrentStep = false
        advanceToNextStep()
    end

    if not waypointAddedForCurrentStep then

        if currentWaypointExists(currentStep.waypoint) then
            removeCurrentWaypoint(currentStep.waypoint)
        end

        addWaypointForCurrentStep()
    end

end

-- used when the player turns in a quest
local handleQuestTurnIn = function(questID)
    addonUpdate()
end

local handleQuestDetail = function(questStartItemID)
    local questID = GetQuestID()
    debugVals("questID:", questID)

    local title = GetTitleText()

    if not questInIndex(questID) then
        CloseQuest()
        displayToUser("Auto-closed quest '", title, "' (", questID, "). Not pertinent to acquiring dragon flying.")
        return
    end

    AcceptQuest()
    displayToUser("Auto-accepted quest:", title)
    addonUpdate()
end

local update = function()

    local currentStep = getCurrentStep()

    autoAcceptPopupQuests()

    if isStepCompleted(currentStep) then
        waypointAddedForCurrentStep = false
        advanceToNextStep()
    end

    if not waypointAddedForCurrentStep then

        if currentWaypointExists(currentStep.waypoint) then
            removeCurrentWaypoint(currentStep.waypoint)
        end

        addWaypointForCurrentStep()
    end

    C_Timer.After(ADDON_TIMINGS.AddonLoop, addonLoop)
end

local deferredStartup = function()
    clearExistingWaypoints()

    primeSteps()

    registerEventBindings()

    displayReadyMessage()
    addonReady = true
    update()
end


---------------------------------------------------------
-- Addon initialization, enabling and disabling
---------------------------------------------------------

function DragonFlyingASAP:OnInitialize()
    eventIt("OnInitialize")

    --LibStub("AceConfig-3.0"):RegisterOptionsTable("DragonFlyingASAP", addonOptions, nil)

    --self.db = LibStub("AceDB-3.0"):New("DragonFlyingASAPDB")
end

function DragonFlyingASAP:OnEnable()
    eventIt("OnEnable")

    displayWelcomeMessage()

    -- We defer startup so that other addons like TomTom can initialize and be ready for our API calls
    --C_Timer.After(ADDON_TIMINGS.DeferredStartup, deferredStartup)
end

function DragonFlyingASAP:OnDisable()
    eventIt("OnDisable")

    addonReady = false
end


---------------------------------------------------------
-- Event Handlers
---------------------------------------------------------

function DragonFlyingASAP:MyHandler(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:PLAYER_ENTERING_WORLD(eventName)
    eventIt(eventName)

    deferredStartup()
end

function DragonFlyingASAP:GOSSIP_CLOSED(eventName)
    eventIt(eventName)

    C_Timer.After(ADDON_TIMINGS.GossipDeferral, addonUpdate)
end

function DragonFlyingASAP:ACHIEVEMENT_EARNED(eventName, achievementID, alreadyEarned)
    eventIt(eventName, achievementID, alreadyEarned)
end

function DragonFlyingASAP:CINEMATIC_START(eventName, canBeCancelled)
    eventIt(eventName, canBeCancelled)

    StopCinematic()
end

function DragonFlyingASAP:GOSSIP_SHOW(eventName, uiTextureKit)
    eventIt(eventName, uiTextureKit)

    if not addonReady then return end

    local activeQuests = C_GossipInfo.GetActiveQuests()
    for i, v in pairs(activeQuests) do
        debugVals(i, v.title, v.questID, v.isComplete)
        if questInIndex(v.questID) and v.isComplete then
            C_GossipInfo.SelectActiveQuest(v.questID)
            addonUpdate()
        end
    end

    local gossipOptions = C_GossipInfo.GetOptions()
	for i, v in pairs(gossipOptions) do
		debugVals(i, v.icon, v.name, v.gossipOptionID)
		if v.gossipOptionID == 55582    -- Aspectral Invitation
          or v.gossipOptionID == 53882  -- Expeditionary Coordination: Pathfinder Tacha
          or v.gossipOptionID == 53883  -- Expeditionary Coordination: Boss Magor
          or v.gossipOptionID == 54035  -- Expeditionary Coordination: Cataloger Coralie
          or v.gossipOptionID == 107450 -- The Dark Talons: Kodethi
          or v.gossipOptionID == 55626  -- Whispers on the Winds: Khadgar
        then
			C_GossipInfo.SelectOption(v.gossipOptionID)
            displayToUser("Auto-accepted quest gossip")
		end
	end
end

function DragonFlyingASAP:QUEST_PROGRESS(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:QUEST_DETAIL(eventName, questStartItemID)
    eventIt(eventName, questStartItemID)

    if not addonReady then return end

    handleQuestDetail(questStartItemID)
end

function DragonFlyingASAP:QUEST_COMPLETE(eventName)
    eventIt(eventName)

    if not addonReady then return end

    local questID = GetQuestID()
    debugVals("questID:", questID)

    -- Auto-complete quests
    if questInIndex(questID) then
        local title = GetTitleText()
        GetQuestReward()
        addonUpdate()
        displayToUser("Auto-completed quest:", title)
    end
end

function DragonFlyingASAP:QUEST_GREETING(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:QUEST_DATA_LOAD_RESULT(eventName, questID, success)
    eventIt(eventName, questID, success)
end

function DragonFlyingASAP:TALKINGHEAD_REQUESTED(eventName)
    eventIt(eventName)

    skipTalkingHead()
end

function DragonFlyingASAP:QUEST_ACCEPTED(eventName, questID)
    eventIt(eventName, questID)

    if not addonReady then return end

    if not questInIndex(questID) then
        if C_QuestLog.CanAbandonQuest(questID) then
            C_QuestLog.SetSelectedQuest(questID)
            C_QuestLog.SetAbandonQuest()
            C_QuestLog.AbandonQuest()
            displayToUser("Auto-abandoned quest...not pertinent to Dragon Flying")
        end
    end

    addonUpdate()
end

function DragonFlyingASAP:QUEST_TURNED_IN(eventName, questID, xpReward, moneyReward)
    eventIt(eventName, questID, xpReward, moneyReward)

    if not addonReady then return end

    if questInIndex(questID) then
        handleQuestTurnIn(questID)
    end
end
