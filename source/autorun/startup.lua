log.debug("[Randomizer] Loading mod...")


-- START globals
AP_REF = require("AP_REF/core")

Main = require("DRAP/main")

GUI = require("AP_REF/GUI")
Storage = require("AP_REF/Storage")
Tools = require("AP_REF/Tools")

re.on_pre_application_entry("UpdateBehavior", function()
    -- if not Scene:isInGame() then
    --     Archipelago.DisableInGameClient("Start a new game or load a file before connecting to AP.");
    -- else
    --     Archipelago.EnableInGameClient();
    -- end

    if Scene:isInGame() then 
        Archipelago.Init()

        if Archipelago.waitingForSync then
            Archipelago.waitingForSync = false
            Archipelago.Sync()
        end

        if Archipelago.CanReceiveItems() then
            Archipelago.ProcessItemsQueue()
        end

		if Scene:isGameOver() then
			
			if not Archipelago.waitingForSync then
				Archipelago.waitingForSync = true
			end

		end
	end
end)

re.on_frame(function ()
    -- ... one day OpieOP
    -- if Scene:isTitleScreen() then
    --     GUI.ShowRandomizerLogo()
    -- end

    if reframework:is_drawing_ui() then
        Tools.ShowGUI()
    end

    if Scene:isInGame() or Scene:isGameOver() then
        GUI.CheckForAndDisplayMessages()
    else
        -- if the player isn't in-game or on game over screen, GUI isn't showing, so keep the timer to clear messages at 0 until they are
        GUI.lastText = os.time()
    end
end)

re.on_draw_ui(function () -- this is only called when Script Generated UI is visible
    -- nothing, but could add some debug stuff here one day
end)

log.debug("[Randomizer] Mod loaded.")