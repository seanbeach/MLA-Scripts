-- TriggerType=Menu
-- DisplayOutputWindow=true

-- Builds a focus cue list from the preset list.
-- v1.0 09/05/2016 AV
-- Modified 2017-08-14 by SBeach- removed features I dont care about, added scenes
-- Modified 2017-09-20 by SBeach- added MLA selection commands and hacked into one list mode
-- Modified 2019-12-01 by SBeach fixed Scene setting to be 2.7 compatible.
-- Modified 2019-12-02 by SBeach added Notes setting, replace all label instances of "enter" with "ntr"
-- Modified 2019-12-03 by SBeach homes color and shutter strobe instead of referencing palettes.
-- Modified 2022-10-18 by SBeach fixed number casting issue with first cue prompt
-- Known Issue 2022-10-18: makeCueNumberPresetNumber tracks improperly

-- User control variables.
mainCueListNumber = 1 -- The cue list number that is the main show cue list
recallFromFocusCue = false -- When true, will recall all channels from presets focus cue.
recallChannelFromFocusCue = false -- Set to true if you want the channel recalled from it's focus cue.
makeCueNumberPresetNumber = false -- Set to true if you want the cue number to be the same as the preset number.
cueOffsetFP = 1000 -- Cue number offset for Focus Palettes (only when makeCueNumberPresetNumber is true).
cueOffsetPreset = 0 -- Cue number offset for Presets (only when makeCueNumberPresetNumber is true).

includePriority = {}
includePriority[1] = true --This is LOWEST priority (scb)
includePriority[2] = true
includePriority[3] = true
includePriority[4] = true
includePriority[5] = true
includePriority[6] = true -- This is HIGHEST priorty (scb)

-- StartBuild
-- Will be called at the start of the build.
function StartBuild()
	-- Place console into Blind
	OSC:EOS_SendKey("Blind")
	Wait(1)
	io.write("Build Started.\n")
end

-- EndBuild
-- Will be called at the end of the build for clean up.
function EndBuild()
	-- Place console into Live
	OSC:EOS_SendKey("Live")
	io.write("Build Ended.\n")
end

-- SetCue
function SetCue(cueNumber, cueLabel, presetNum)
	commandLine = "Cue ".. focusCueList.." / "..cueNumber.." Time 1#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)
	
	-- Confirm
	OSC:EOS_SendKey("Enter") -- Confirm
	Wait(0.2)
	
	-- Label cue
	commandLine = "Label " .. string.gsub(cueLabel, "enter", "ntr")
	io.write(commandLine, "\n")
	OSC:EOS_SendCommandLine(commandLine)
	Wait(0.2)
	OSC:EOS_SendKey("Enter") -- Confirm
	
	-- Link cue to MLA
	commandLine = "Execute String /mla/presetdoc/select/preset/"..presetNum
	io.write(commandLine, "\n")
	OSC:EOS_SendCommandLine(commandLine)
	Wait(0.2)
	OSC:EOS_SendKey("Enter") -- Confirm
end

-- SetScene
function SetScene(cueNumber, cueScene)
	commandLine = "Cue ".. focusCueList.." / "..cueNumber.." Scene "..string.gsub(cueScene,"enter","ntr").."#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)
	-- Clear any Errors
	Wait(0.2)
	OSC:EOS_SendKey("Clear") -- Clear Errors
end

-- Set Notes
function SetNotes(cueNumber, cueNotes)
	commandLine = "Cue ".. focusCueList.." / "..cueNumber.." Notes "..string.gsub(cueNotes,"enter","ntr").."#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)
	-- Clear any Errors
	Wait(0.2)
	OSC:EOS_SendKey("Clear") -- Clear Errors
end

-- SetChannelOnState
function SetChannelOnState()
	-- Here we set the light as we want it in the cue after the preset/focus cue been recalled.
	-- Typlically you will turn the channel on, but you may wish to put it in a colour too.

	-- Put the channel at Full
	commandLine = "At Full#"
	io.write(commandLine, "\n")
	OSC:EOS_SendCommandLine(commandLine)
end

-- RecallFromPreset
function RecallFromPreset(inChannelList, inPresetID)
	-- Recall the Preset
	commandLine = "Chan ".. inChannelList.. " Focus Beam Preset "..inPresetID.."#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)
	
	-- Home the Color
	commandLine = "Chan ".. inChannelList.. " Color Home#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)
	
	-- Home the Shutter Strobe
	commandLine = "Chan ".. inChannelList.. " Shutter_Strobe Home#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)
	
	-- Home the Shutter Strobe
	commandLine = "Chan ".. inChannelList.. " Strobe_Mode Home#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)
	
	-- Stop any Recalled Effects
	commandLine = "Chan ".. inChannelList.. " Effect#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)

	SetChannelOnState()
end

-- RecallFromFocusPalette
function RecallFromFocusPalette(inChannelList, inPresetID)
	-- Recall the Preset
	commandLine = "Chan ".. inChannelList.. " Focus Palette "..inPresetID.."#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)

	SetChannelOnState()
end

-- RecallFromCue
function RecallFromCue(inChannelList, inCue)
	commandLine = "Chan ".. inChannelList.." Focus Beam Recall_From Cue "..mainCueListNumber.."/"..inCue.."#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)
	
	-- Stop any Recalled Effects
	commandLine = "Chan ".. inChannelList.. " Effect#"
	io.write(commandLine, "\n")
	OSC:EOS_SendNewCommandLine(commandLine)

	SetChannelOnState()
end

-- Main Code block.

lastStoredCueNumber = 0
lastStoredScene = ""

focusCueList = PromptInputDialog("Enter Focus Cue List number.")
focusCueFirstCue = PromptInputDialog("Enter Starting Cue Number in Cue List ".. focusCueList .. "/")

if focusCueList ~= "" then
	StartBuild()
	
	PresetDocView:DispatchAction("Select First Preset")
	presetListFinished = false
	
	cueNumber = tonumber(focusCueFirstCue) or 1
	
	while presetListFinished == false do
		presetInfo = PresetInfo:GetSelectedPreset()
		isFocusPalette = false
		presetPriority = 7 - presetInfo.Priority -- (scb) invert priority context for 'muricans
		-- Only process presets that are not set to 'Ignore'.
		--  (scb) and included in our priority array
		
		if presetInfo.PresetUnused == false and includePriority[presetPriority] then
			presetNumber   = presetInfo.PresetID
			presetScene    = presetInfo.Scenery

			-- Build preset name and cue number.
			presetName = ""
			if string.find(presetInfo.PresetType,"Preset") ~= nil then
				presetName = "Pr "..presetNumber..": "..presetInfo.PresetName.." [Priority "..presetPriority.."]"
				isFocusPalette = false
				if makeCueNumberPresetNumber == true then
					cueNumber = cueOffsetPreset + presetNumber
				end
			elseif string.find(presetInfo.PresetType,"Focus Palette") ~= nil then
				presetName = "FP "..presetNumber.." - "..presetInfo.PresetName
				isFocusPalette = true
				if makeCueNumberPresetNumber == true then
					cueNumber = cueOffsetFP + presetNumber
				end
			end

			-- As we are doing this in Blind, we should select/create the cue first.

			SetCue(cueNumber, presetName, presetNumber)
			
			if presetScene ~= lastStoredScene then
				SetScene(cueNumber, presetScene)
				lastStoredScene = presetScene
			end
			
			SetNotes(cueNumber, presetInfo.Notes)

			-- We need to turn off any channels tracked on.
			-- We only do this if we are creating a new cue.

			if cueNumber ~= lastStoredCueNumber then
				commandLine = "Select_Active Home#"
				io.write(commandLine, "\n")
				OSC:EOS_SendNewCommandLine(commandLine)
				
				Wait(0.2)
				commandLine = "At Out#"
				io.write(commandLine, "\n")
				OSC:EOS_SendCommandLine(commandLine)
				
				Wait(0.2)
				OSC:EOS_SendKey("Clear") -- Clear Errors
			end
		

			-- Get channels we need from preset.
		
			channelCount = PresetDocView:GetChannelCount()
			channelListFinished = false
			channelList = ""
			if channelCount > 0 then
				PresetDocView:DispatchAction("Select First Channel")
				firstChannelDone = false
				while channelListFinished == false do
					channelInfo = PresetInfo:GetSelectedChannel()
					channelNum = channelInfo.ChannelNumber

					if firstChannelDone == false then
						channelList = channelNum
						firstChannelDone = true
					else
						channelList = channelList .." + " ..channelNum
					end

					-- Continue to next channel, or are we done.
					if PresetDocView:IsLastChannelRowSelected() == true then
						channelListFinished = true
					else
						PresetDocView:DispatchAction("Select Next Channel")
					end
				end
			end

			-- We now have a channel list.
			-- Now Recall from Preset

			if isFocusPalette == true then
				RecallFromFocusPalette(channelList, presetNumber)
			else
				RecallFromPreset(channelList, presetNumber)
			end


			lastStoredCueNumber = cueNumber

			cueNumber = cueNumber + 1
		end

		-- Continue to next preset, or are we done.
		if PresetDocView:IsLastPresetRowSelected() == true then
			presetListFinished = true
		else
			PresetDocView:DispatchAction("Select Next Preset")
		end
	end 
	EndBuild()
end
