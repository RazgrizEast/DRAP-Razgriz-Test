local Archipelago = {}
Archipelago.seed = nil
Archipelago.slot = nil
Archipelago.apworld_version = nil -- comes over in slot data
Archipelago.hasConnectedPrior = false -- keeps track of whether the player has connected at all so players don't have to remove AP mod to play vanilla
Archipelago.isInit = false -- keeps track of whether init things like handlers need to run
Archipelago.waitingForSync = false -- randomizer calls APSync when "waiting for sync"; i.e., when you die

Archipelago.itemsQueue = {}
Archipelago.isProcessingItems = false -- this is set to true when the queue is being processed so we don't over-give

-- set the game name in apclientpp
AP_REF.APGameName = "Dead Rising Deluxe Remaster"

function Archipelago.Init()
    if not Archipelago.isInit then
        Archipelago.isInit = true
    end
end

function Archipelago.IsConnected()
    return AP_REF.APClient ~= nil and AP_REF.APClient:get_state() == AP_REF.AP.State.SLOT_CONNECTED
end

function Archipelago.GetPlayer()
    local player = {}

    if AP_REF.APClient == nil then
        return {}
    end

    player["slot"] = AP_REF.APClient:get_slot()
    player["seed"] = AP_REF.APClient:get_seed()
    player["number"] = AP_REF.APClient:get_player_number()
    player["alias"] = AP_REF.APClient:get_player_alias(player['number'])
    player["game"] = AP_REF.APClient:get_player_game(player['number'])

    return player
end

function Archipelago.Sync()
    if AP_REF.APClient == nil then
        return
    end

    AP_REF.APClient:Sync()
end

function Archipelago.DisableInGameClient(client_message)
    AP_REF.DisableInGameClient(client_message)
end

function Archipelago.EnableInGameClient()
    AP_REF.EnableInGameClient()
end

-- server sends slot data when slot is connected
function APSlotConnectedHandler(slot_data)
    Archipelago.hasConnectedPrior = true
    GUI.AddText('Connected.')

    return Archipelago.SlotDataHandler(slot_data)
end
AP_REF.on_slot_connected = APSlotConnectedHandler

function APSlotDisconnectedHandler()
    GUI.AddText('Disconnected.')
end
AP_REF.on_socket_disconnected = APSlotDisconnectedHandler -- there's no "slot disconnected", so this is half as good

function Archipelago.SlotDataHandler(slot_data)
    local player = Archipelago.GetPlayer()

    -- if the player connected to a different seed than we last connected to, reset everything so it will import properly
    if (Archipelago.seed ~= nil and player["seed"] ~= Archipelago.seed) or (Archipelago.slot ~= nil and player["slot"] ~= Archipelago.slot) then
        GUI.AddText('Resetting mods because seed or slot name was changed.')

        Archipelago.Reset()
    end

    Archipelago.seed = player["seed"]
    Archipelago.slot = player["slot"]

    if slot_data.apworld_version ~= nil then
        Archipelago.apworld_version = slot_data.apworld_version
    end
end

-- sent by server when items are received
function APItemsReceivedHandler(items_received)
    return Archipelago.ItemsReceivedHandler(items_received)
end
AP_REF.on_items_received = APItemsReceivedHandler

function Archipelago.ItemsReceivedHandler(items_received)
    local itemsWaiting = {}

    -- add all of the randomized items to an item queue to wait for send
    for k, row in pairs(items_received) do
        -- if the index of the incoming item is greater than the index of our last item at save, check to see if it's randomized
        -- because ONLY non-randomized items escape the queue; everything else gets queued
        if row["index"] ~= nil and (not Storage.lastSavedItemIndex or row["index"] > Storage.lastSavedItemIndex) then
            local item_data = Archipelago._GetItemFromItemsData({ id = row["item"] })
            local item_name = AP_REF.Sanitize(item_data["name"])
            local location_data = nil
            local is_randomized = 1

            if row["location"] ~= nil and row["location"] > 0 then
                location_data = Archipelago._GetLocationFromLocationData({ id = row["location"] })

                if location_data and location_data['raw_data']['randomized'] ~= nil then
                    is_randomized = location_data['raw_data']['randomized']
                end
            end

			if item_name and row["player"] ~= nil and is_randomized == 0 then
				Archipelago.ReceiveItem(AP_REF.Sanitize(item_name), row["player"], is_randomized)
			else
				table.insert(Archipelago.itemsQueue, row)
				table.insert(itemsWaiting, item_name)
			end
        end
    end
end

function Archipelago.CanReceiveItems()
    -- wait until the player is in game, with AP connected, and with an available item box (that's not in use), and with a reachable inventory
    -- before sending any items over
    return Archipelago.IsConnected()
end

function Archipelago.ProcessItemsQueue()
    -- if we're already processing items, wait for that to finish
    if Archipelago.isProcessingItems then
        return
    end

    if #Archipelago.itemsQueue == 0 then
        Archipelago.isProcessingItems = false
        return
    end
    
    Archipelago.isProcessingItems = true
    local items = Archipelago.itemsQueue
    Archipelago.itemsQueue = {}

    for k, row in pairs(items) do
        -- if the index of the incoming item is greater than the index of our last item at save, accept it
        if row["index"] ~= nil and (not Storage.lastSavedItemIndex or row["index"] > Storage.lastSavedItemIndex) then
            local item_data = Archipelago._GetItemFromItemsData({ id = row["item"] })
            local item_name = AP_REF.Sanitize(item_data["name"])
            local location_data = nil
            local is_randomized = 1

            if row["location"] ~= nil and row["location"] > 0 then
                location_data = Archipelago._GetLocationFromLocationData({ id = row["location"] })

                if location_data and location_data['raw_data']['randomized'] ~= nil then
                    is_randomized = location_data['raw_data']['randomized']
                end
            end

            -- if the index is also greater than the index of our last received index, update last received
            if row["index"] ~= nil and (not Storage.lastReceivedItemIndex or row["index"] > Storage.lastReceivedItemIndex) then
                Storage.lastReceivedItemIndex = row["index"]
            end
        end
    end

    Storage.Update()

    Archipelago.isProcessingItems = false -- unset for the next bit of processing
end

-- sent by server when locations are checked (collect, etc.?)
function APLocationsCheckedHandler(locations_checked)
    return Archipelago.LocationsCheckedHandler(locations_checked)
end
AP_REF.on_location_checked = APLocationsCheckedHandler

function Archipelago.LocationsCheckedHandler(locations_checked)
    local player = Archipelago.GetPlayer()
    
    -- if we received locations that were collected out, mark them sent so we don't get anything from it
    for k, location_id in pairs(locations_checked) do
        local location_name = AP_REF.APClient:get_location_name(tonumber(location_id), player['game'])


    end
end

-- called when server is sending JSON data of some sort?
function APPrintJSONHandler(json_rows)
    return Archipelago.PrintJSONHandler(json_rows)
end
AP_REF.on_print_json = APPrintJSONHandler

function Archipelago.PrintJSONHandler(json_rows)
    local player_sender, player_receiver, sender_number, receiver_number, item_id, location_id, item, location = nil
    local player = Archipelago.GetPlayer()
    local item_color = "06bda1" -- default color

    -- if it's a hint, ignore it and return
    if #json_rows > 0 and json_rows[1]["text"] ~= nil and string.find(json_rows[1]["text"], "[Hint]") then
        return
    end

    for k, row in pairs(json_rows) do
        -- if it's a player id and no sender is set, it's the sender
        if row["type"] ~= nil and row["type"] == "player_id" and not player_sender then
            player_sender = AP_REF.APClient:get_player_alias(tonumber(row["text"]))
            sender_number = tonumber(row["text"])
        -- if it's a player id and the sender is set, it's the receiver
        elseif row["type"] ~= nil and row["type"] == "player_id" and player_sender then
            player_receiver = AP_REF.APClient:get_player_alias(tonumber(row["text"]))        
            receiver_number = tonumber(row["text"])
        elseif row["type"] ~= nil and row["type"] == "item_id" then
            item_id = tonumber(row["text"])            
            
            if (row["flags"] & 1) > 0 then
                item_color = "ce28f7"
            elseif (row["flags"] & 2) > 0 then
                item_color = AP_REF.APUsefulColor
            elseif (row["flags"] & 4) > 0 then
                item_color = AP_REF.APTrapColor
            else
                item_color = "06bda1"
            end
        elseif row["type"] ~= nil and row["type"] == "location_id" then
            location_id = tonumber(row["text"])
        end
    end
    
    if player_sender and item_id and player_receiver and location_id then
        -- if we received, items received will give us the message
        -- if we sent, we want the text here
        -- everything else, don't care.
        if player['alias'] ~= nil and player_sender == player['alias'] then
            if not Storage.lastSavedItemIndex or row == nil or row["index"] == nil or row["index"] > Storage.lastSavedItemIndex then
                if player_receiver then
                    item = AP_REF.APClient:get_item_name(item_id, AP_REF.APClient:get_player_game(receiver_number))
                    location = AP_REF.APClient:get_location_name(location_id, player['game'])

                    GUI.AddSentItemText(player_sender, item, item_color, player_receiver, location)
                end
            end
        end
    end
end

function Archipelago.IsItemLocation(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data, true) -- include_sent_locations

    if not location then
        return false
    end

    return true
end

function Archipelago.IsLocationRandomized(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data, true) -- include_sent_locations

    if not location then
        return false
    end
    
    if location['raw_data']['randomized'] == 0 and not location['raw_data']['force_item'] then
        return false
    end

    return true
end

function Archipelago.GetLocationName(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data, true) -- include_sent_locations

    if not location then
        return ""
    end

    return location["name"]
end

function Archipelago.CheckForVictoryLocation(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data)

    if location ~= nil and location["raw_data"]["victory"] then
        Archipelago.SendVictory()

        return true
    end
    
    return false
end

-- Returns:
--   - true if location was sent with no issues
--   - false if location was not sent because it has been sent prior
--   - nil if location was not sent because the AP call failed
function Archipelago.SendLocationCheck(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data)
    local location_ids = {}

    if not location or not location['id'] or (location['id'] ~= nil and tonumber(location['id']) < 0) then
        -- if location wasn't found in session unsent locations, check all locations to make sure it's not a wrongly named location (indicating a version mismatch)
        -- if so, show a message; if not, just bail out of here since there's nothing to send
        local location_existing = Archipelago._GetLocationFromLocationData(location_data, true)

        if not location_existing['id'] or (location_existing['id'] ~= nil and tonumber(location_existing['id']) < 0) then
            GUI.AddTexts({
                { message="Invalid location.", color=AP_REF.HexToImguiColor('fa3d2f') },
                { message=" You tried to check " },
                { message=location_existing['name'], color=AP_REF.HexToImguiColor("d9d904") },
                { message=", but it does not exist in the multiworld. " }
            })

            GUI.AddTexts({
                { message="Your apworld version and client version must match.", color=AP_REF.HexToImguiColor('fa3d2f') }
            })
        else
            GUI.AddTexts({
                { message="Location already checked or collected: ", color=AP_REF.HexToImguiColor("AAAAAA") },
                { message=location_existing['name'] },
                { message=".", color=AP_REF.HexToImguiColor("AAAAAA") }
            })
        end

        return false
    end

    location_ids[1] = location["id"]

    local result = nil

    if Archipelago.IsConnected() then
        result = AP_REF.APClient.LocationChecks(AP_REF.APClient, location_ids)
    end

    if not result then
        return nil
    end

    local sent_loc = location['raw_data']    



    return true
end

function Archipelago.ReceiveItem(item_name, sender, is_randomized)
    local player_self = Archipelago.GetPlayer()
    local item_color = "06bda1" -- default color
    local sentToBox = is_randomized == 1 -- if randomized, it goes to box
    
    GUI.AddReceivedItemText(item_name, item_color, tostring(AP_REF.APClient:get_player_alias(sender)), tostring(player_self.alias), sentToBox)
end

function Archipelago.SendVictory()
    AP_REF.APClient:StatusUpdate(AP_REF.AP.ClientStatus.GOAL)   
end


function Archipelago._GetItemFromItemsData(item_data)
    local player = Archipelago.GetPlayer()
    local translated_item = {}
    
    translated_item['name'] = AP_REF.APClient:get_item_name(item_data['id'], player['game'])

    if not translated_item['name'] then
        return nil
    end

    translated_item['id'] = item_data['id']

    -- now that we have name and id, return them
    return translated_item
end

function Archipelago._GetLocationFromLocationData(location_data, include_sent_locations)
    local player = Archipelago.GetPlayer()

    include_sent_locations = include_sent_locations or false

    local translated_location = {}

    if location_data['id'] and not location_data['name'] then
        location_data['name'] = AP_REF.APClient:get_location_name(location_data['id'], player['game'])
    end

    -- Look up the location in Lookups.locations
    for k, loc in pairs(Lookups.locations) do
        local location_name_with_region = loc['region'] .. " - " .. loc['name']
        
        if location_data['name'] and location_name_with_region == location_data['name'] then
            -- Check if we should skip sent locations
            if not include_sent_locations and loc['sent'] then
                return nil
            end
            
            translated_location['name'] = location_data['name']
            translated_location['id'] = loc['id']
            translated_location['raw_data'] = loc
            
            return translated_location
        end
    end

    -- If we didn't find a match, still try to get the name and ID
    if location_data['name'] then
        translated_location['name'] = location_data['name']
    end

    if not translated_location['name'] then
        return nil
    end

    translated_location['id'] = AP_REF.APClient:get_location_id(translated_location['name'], player['game'])

    -- now that we have name and id, return them
    return translated_location
end

function Archipelago.Reset()
    Archipelago.seed = nil
    Archipelago.slot = nil
    Archipelago.itemsQueue = {}
end

return Archipelago