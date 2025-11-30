local Tools = {}

function Tools.ShowGUI()
    local scenario_text = '   (not connected)'
    local deathlink_text = '   (not connected)'
    local deathlink_color = AP_REF.HexToImguiColor('FFFFFF')
    local version_text = '   ' .. tostring(Manifest.version)
    local version_mismatch = false

    -- if the lookups contain data, then we're connected, so do everything that needs connection
    if Lookups.character and Lookups.scenario then
        scenario_text = "   " .. Lookups.character:gsub("^%l", string.upper) .. " " .. string.upper(Lookups.scenario) .. 
            " - " .. Lookups.difficulty:gsub("^%l", string.upper)

        if Archipelago.death_link then
            deathlink_text = "   On"
        else
            deathlink_text = "   Off"
            deathlink_color = AP_REF.HexToImguiColor('777777')
        end

        if Archipelago.apworld_version == nil or Archipelago.apworld_version ~= Manifest.version then
            if Archipelago.apworld_version ~= nil then
                version_text = version_text .. ' (world is ' .. Archipelago.apworld_version .. ')'
            else
                version_text = version_text .. ' (world is outdated)'
            end

            version_mismatch = true
        else
            version_text = version_text .. ' (matches)'
        end
    end

    imgui.set_next_window_size(Vector2f.new(200, 720), 0)
    imgui.begin_window("Archipelago Game Mod ", nil,
        8 -- NoScrollbar
    )

    imgui.text_colored("Mod Version Number: ", -10825765)
    
    if version_mismatch then
        imgui.text_colored(version_text, AP_REF.HexToImguiColor('fa3d2f'))
    else
        imgui.text(version_text)
    end

    imgui.separator()
    imgui.text(" The default keyboard key to")
    imgui.text(" show or hide these windows is")
    imgui.text(" INSERT.")
    imgui.separator()

    imgui.new_line()
    imgui.text_colored("Credits:", -10825765)
    imgui.text("@ArsonAssassin")
    imgui.new_line()

    if Lookups.character and Lookups.scenario then
        imgui.text_colored("Missing Items?", -10825765)
        imgui.text("If you were sent items at the ")
        imgui.text("start and didn't receive them,")
        imgui.text("click this button.")

        if imgui.button("Receive Items Again") then
            Storage.lastReceivedItemIndex = -1
            Storage.lastSavedItemIndex = -1
            Archipelago.waitingForSync = true
        end

    end
        imgui.end_window()
end

return Tools