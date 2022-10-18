-- TriggerType=Key
-- TriggerKey=[
-- DisplayOutputWindow=true

-- Fresh rewrite on September 2nd, 2022


-- Configuration:
	delayForMove = 2	-- This is how long to wait for a fixture to move into place
	delayBetween = 0.2	-- How long between fixtures (slow down for slow dousers/dimmers)
	
	useHighlight = false		-- TRUE will use Highlight/Lowlight for shooting
								-- FALSE will use FULL and OUT for shooting
	
	homeBeforeRecall = true		-- Home the fixture before assigning presets (true)
	stopEffects = true			-- Stop effects that may be in presets (true)
	sneakBeforeShooting = true	-- Sneak everything that may be leftover from a previous shoot (true)
	sneakWhenDone = true		-- Sneak everything when done with photos to be tidy (true)
	
	takePresetPhoto = true		-- Take a group preset photo (true)
	skipExistingPhotos = false	-- Will skip units with existing photos (false)
	
	takeChannelPhotos = true				-- Shoot channel photos
	ignoreAutoAndShootEverything = false	-- Shoot every fixture regardless of auto checkbox
	
	replacePresetPhotos = false		-- Replace preset photos with new ones when old ones exist (false)
	replaceChannelPhotos = false	-- Replace fixture photos with new ones when old ones exist (false)
	promptReplacePhotos = true		-- Ask what to do when existing photos are found, if false, use behavior above (true)
	
	setFocusedAfterPhotoTaken = true	-- Set the focus status to true when done taking photos (true)
	
	silentMode = false          -- Suppress log messages (false)
	
	--List of parameters to home at every fixture:
	homeParameters = "Color Shutter_Strobe Strobe_Mode"
	
-- Utilities	
	function EOS(cmd)
		OSC:EOS_SendNewCommandLine(cmd)
		Log("  EOS: " .. cmd)
	end

	function EOSAppend(cmd)
		OSC:EOS_SendCommandLine(cmd)
		Log("  EOS: " .. cmd)
	end

	function Log(message)
		if not silentMode then io.write(message,"\n") end
	end


-- Get Preset Info
	selectedPreset	= PresetInfo:GetSelectedPreset()
	presetID 		= selectedPreset.PresetID
	presetType		= selectedPreset.PresetType
	hasExistingPresetPhotos = PresetDocView:GetPhotoCountForSelectedPreset() > 0
	
	Log("Preset ID: " .. selectedPreset.PresetID .. " Name: " .. selectedPreset.PresetName)

-- Make sure we have something to shoot
	channelCount	= PresetDocView:GetChannelCount()
	if channelCount == 0 then
		Log("NO CHANNELS TO SHOOT!")
		return
	end
	
-- Get the channel selection
	hasExistingChannelPhotos = false
	selection = ""
	PresetDocView:DispatchAction("Select First Channel")
	for i = 1, channelCount do
		selectedChannel = PresetInfo:GetSelectedChannel()
		chan = selectedChannel.ChannelNumber
		if selectedChannel.AutoPhotograph or ignoreAutoAndShootEverything then
			-- Check for existing channel photos
			channelPhotoCount = PresetDocView:GetPhotoCountForSelectedChannel()
			hasExistingChannelPhotos = hasExistingChannelPhotos or channelPhotoCount > 0
			if channelPhotoCount < 1 or not skipExistingPhotos then
				if selection == "" then
					selection = chan
				else
					selection = selection .. " + " .. chan
				end
			end
		end
		PresetDocView:DispatchAction("Select Next Channel")
	end
	
-- Make sure we have something to shoot (again)
	if selection == "" then
		Log("No channels are set up for auto photograph.")
		retry = PromptChoiceDialog( "No channels were selected for auto-photograph or photos already exist, would you like to shoot everything?", "Photograph Everything", "Cancel" )
		if retry then
			ignoreAutoAndShootEverything = true
			skipExistingPhotos = false
			selection = CreateChannelSelection()
		end
	end
	if selection == "" then
		Log("No channels were ready to photograph.")
		return
	end

-- Check if we should delete old photos
	if promptReplacePhotos then
		if hasExistingPresetPhotos then
			replacePresetPhotos = not PromptChoiceDialog( "This preset has existing preset photos, would you like to add photos or replace the old ones.", "Add More", "Replace" )
		end
		if hasExistingChannelPhotos then
			replaceChannelPhotos = not PromptChoiceDialog( "One or more channels set for autophotograph in this preset have existing channel photos, would you like to add photos or replace the old ones.", "Add More", "Replace" )
		end
	end
	
--Delete old preset photos if needed
	if replacePresetPhotos then
		for p = 1, PresetDocView:GetPhotoCountForSelectedPreset() do
			PresetDocView:DispatchAction("Display Preset Photo", 1)
			PresetDocView:DispatchAction("Remove Displayed Preset Photo")
		end
	end

-- Shoot Preset Photo
	EOS("Live #")
	if sneakBeforeShooting then EOS("Sneak#") end
	
	if takePresetPhoto then
		EOS("Chan " .. selection .. "#") -- Select Channels
	
		if presetType == "Preset" then
			EOSAppend("Preset " .. presetID .. "#") --apply preset
		elseif presetType == "Beam Palette" then
			EOSAppend("Beam_Palette" .. presetID .. "#") --apply bp
		end
	
		if homeParameters ~= "" then EOSAppend(homeParameters .. " Home#") end
		if stopEffects then EOSAppend("Effect#") end
	
		if not useHighlight then EOSAppend("At Full#") end

		Wait(delayForMove)
	
		Log("Taking Preset Photo")
		PresetDocView:DispatchAction("Take Preset Photo")

		if not useHighlight then EOSAppend("At 0#") end
	end
	
-- Shoot Channel Photos
	if takeChannelPhotos then
		PresetDocView:DispatchAction("Select First Channel")
		for i = 1, channelCount do
			selectedChannel = PresetInfo:GetSelectedChannel()
			chan = selectedChannel.ChannelNumber
			if selectedChannel.AutoPhotograph or ignoreAutoAndShootEverything then
				channelPhotoCount = PresetDocView:GetPhotoCountForSelectedChannel()
				
				--Delete old photos if needed
				if replaceChannelPhotos and channelPhotoCount > 0 then
					for p = 1, channelPhotoCount do
						PresetDocView:DispatchAction("Display Channel Photo", 1)
						PresetDocView:DispatchAction("Remove Displayed Channel Photo")
					end
				end
				
				-- Only shoot ones we need to
				if channelPhotoCount < 1 or not skipExistingPhotos or ignoreAutoAndShootEverything then
					EOS("Chan " .. chan .. " At Full#")
					Wait(delayBetween)
					Log("Taking Channel Photo")
					PresetDocView:DispatchAction("Take Channel Photo")
					if setFocusedAfterPhotoTaken then
						PresetDocView:DispatchAction("Set Channel Focused Flag", "True")
					end
					EOS("Chan " .. chan .. " At 0#")
				end
			end
			PresetDocView:DispatchAction("Select Next Channel")
		end
	end


--Wrap it up
	if sneakWhenDone then EOS("Sneak#") end