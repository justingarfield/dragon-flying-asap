
```lua
/run local mapID = C_Map.GetBestMapForUnit("player"); print(format("You are in %s (%d)", C_Map.GetMapInfo(mapID).name, mapID))

/run local HBD = LibStub("HereBeDragons-2.0"); local x, y, currentPlayerUiMapID, currentPlayerUiMapType = HBD:GetPlayerZonePosition(); print(x); print(y); print(currentPlayerUiMapID); print(currentPlayerUiMapType);
/run local HBD = LibStub("HereBeDragons-2.0"); local x, y, instance = HBD:GetPlayerWorldPosition(); print(x); print(y); print(instance);

/run local DFA = LibStub("AceAddon-3.0"):GetAddon("HandyNotes_DragonFlyingASAP"); DFA.PrintDiagnostics();

/etrace

/run local mapID = C_Map.GetBestMapForUnit("player"); local pos = C_Map.GetPlayerMapPosition(mapID, "player"); local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos); C_Map.SetUserWaypoint(mapPoint)
/run local mapID = C_Map.GetBestMapForUnit("player"); local pos = C_Map.GetPlayerMapPosition(mapID, "player"); local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos); print(mapPoint)
/run local mapID = C_Map.GetBestMapForUnit("player"); local pos = C_Map.GetPlayerMapPosition(mapID, "player"); print(pos.GetXY());

/run local info = C_GossipInfo.GetActiveQuests();

/run local HBD = LibStub("HereBeDragons-2.0"); local x, y, instance = HBD:GetPlayerZonePosition(); TomTom:AddWaypoint(instance, x, y, { title = "A Title" });
/run local HBD = LibStub("HereBeDragons-2.0"); local x, y, instance = HBD:GetPlayerZonePosition(); C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(instance,x,y));
/run local mapID = C_Map.GetBestMapForUnit("player"); local pos = C_Map.GetPlayerMapPosition(mapID, "player"); local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos); C_Map.SetUserWaypoint(mapPoint)

/run local HBD = LibStub("HereBeDragons-2.0"); local x, y, instance = HBD:GetPlayerZonePosition(); print (floor(x * 10000 + 0.5) * 10000 + floor(y * 10000 + 0.5)); print(instance)

/run TomTom:ClearWaypoints()

/run local objectives = C_QuestLog.GetQuestObjectives(65443); for index, objective in ipairs(objectives) do print(index, objective.text, objective.type, objective.finished, objective.numFulfilled, objective.numRequired) end

/run local questID, type = GetAutoQuestPopUp(1); print(questId, type);

```


    if currentStep.type == STEP_TYPE.QuestObjective and C_QuestLog.IsOnQuest(currentStep.questID) then
        
        debugIt("current step's quest is active and no waypoint has been added yet. Adding OBJECTIVE waypoint...")
        addWaypoint(currentStep.waypoint)
        waypointAddedForCurrentStep = true
    end

    -- player needs to acquire quest to continue steps, add waypoint
    if currentStep.type == STEP_TYPE.QuestStart and not C_QuestLog.IsOnQuest(currentStep.questID) then
        debugIt("current step's quest is needed and no waypoint has been added yet. Adding STARTING waypoint...")
        
    end

    -- player is on current quest, add objective or turn-in waypoint
    if currentStep.type == STEP_TYPE.QuestTurnIn and C_QuestLog.IsOnQuest(currentStep.questID) then
        debugIt("current step's quest is active and no waypoint has been added yet. Adding TURN-IN waypoint...")
        addWaypoint(currentStep.waypoint)
        waypointAddedForCurrentStep = true
    end






-- TODO: Need to research this some more since, "Data might not be readily available from the server"
--       https://wowpedia.fandom.com/wiki/API_C_QuestLog.GetTitleForQuestID
local getQuestTitleByID = function(questID)
    local title = C_QuestLog.GetTitleForQuestID(questID)
    
    if not title then
        QuestEventListener:AddCallback(questID, function()
            local name = C_QuestLog.GetTitleForQuestID(questID)
            print(name)
        end)
    end

    return title
end

function DragonFlyingASAP:QuestDetail(event)
    DragonFlyingASAP:Print(event)

end

function DragonFlyingASAP:QuestComplete(event)
    DragonFlyingASAP:Print(event)
    
    GetQuestReward(default)
end










-- Events to monitor, but maybe not use in the end, not sure yet
function DragonFlyingASAP:ACHIEVEMENT_PLAYER_NAME(eventName, achievementID)
    eventIt(eventName, achievementID)
end

function DragonFlyingASAP:CRITERIA_COMPLETE(eventName, criteriaID)
    eventIt(eventName, criteriaID)
end

function DragonFlyingASAP:CRITERIA_EARNED(eventName, achievementID, description)
    eventIt(eventName, achievementID, description)
end

function DragonFlyingASAP:CRITERIA_UPDATE(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:INSPECT_ACHIEVEMENT_READY(eventName, guid)
    eventIt(eventName, guid)
end

function DragonFlyingASAP:RECEIVED_ACHIEVEMENT_LIST(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:RECEIVED_ACHIEVEMENT_MEMBER_LIST(eventName, achievementID)
    eventIt(eventName, achievementID)
end

function DragonFlyingASAP:TRACKED_ACHIEVEMENT_LIST_CHANGED(eventName, achievementID, added)
    eventIt(eventName, achievementID, added)
end

function DragonFlyingASAP:TRACKED_ACHIEVEMENT_UPDATE(eventName, achievementID, criteriaID, elapsed, duration)
    eventIt(eventName, achievementID, criteriaID, elapsed, duration)
end

function DragonFlyingASAP:AREA_POIS_UPDATED(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:BEHAVIORAL_NOTIFICATION(eventName, notificationType, dbId)
    eventIt(eventName, notificationType, dbId)
end

function DragonFlyingASAP:CINEMATIC_STOP(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:PLAY_MOVIE(eventName, movieID)
    eventIt(eventName, movieID)
end

function DragonFlyingASAP:STOP_MOVIE(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:CLIENT_SCENE_CLOSED(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:CLIENT_SCENE_OPENED(eventName, sceneType)
    eventIt(eventName, sceneType)
end

function DragonFlyingASAP:QUEST_AUTOCOMPLETE(eventName, questID)
    eventIt(eventName, questID)
end

function DragonFlyingASAP:QUEST_LOG_CRITERIA_UPDATE(eventName, questID, specificTreeID, description, numFulfilled, numRequired)
    eventIt(eventName, questID, specificTreeID, description, numFulfilled, numRequired)
end

function DragonFlyingASAP:QUEST_LOG_UPDATE(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:QUEST_POI_UPDATE(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:QUEST_REMOVED(eventName, questID, wasReplayQuest)
    eventIt(eventName, questID, wasReplayQuest)
end

function DragonFlyingASAP:QUEST_TURNED_IN(eventName, questID, xpReward, moneyReward)
    eventIt(eventName, questID, xpReward, moneyReward)
end

function DragonFlyingASAP:QUEST_WATCH_LIST_CHANGED(eventName, questID, added)
    eventIt(eventName, questID, added)
end

function DragonFlyingASAP:QUEST_WATCH_UPDATE(eventName, questID)
    eventIt(eventName, questID)
end

function DragonFlyingASAP:QUESTLINE_UPDATE(eventName, requestRequired)
    eventIt(eventName, requestRequired)
end

function DragonFlyingASAP:TASK_PROGRESS_UPDATE(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:TREASURE_PICKER_CACHE_FLUSH(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:WAYPOINT_UPDATE(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:WORLD_QUEST_COMPLETED_BY_SPELL(eventName, questID)
    eventIt(eventName, questID)
end

function DragonFlyingASAP:TALKINGHEAD_CLOSE(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:LOADING_SCREEN_DISABLED(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:LOADING_SCREEN_ENABLED(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:LOOT_JOURNAL_ITEM_UPDATE(eventName)
    eventIt(eventName)
end

function DragonFlyingASAP:LORE_TEXT_UPDATED_CAMPAIGN(eventName, campaignID, textEntries)
    eventIt(eventName, campaignID, textEntries)
end

function DragonFlyingASAP:SCRIPTED_ANIMATIONS_UPDATE(eventName)
    eventIt(eventName)
end






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