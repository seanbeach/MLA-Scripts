-- TriggerType=Menu

-- Mark the selected fixture as not focused and move to next.
-- Use this script with macro keys and EOS control of MLA enabled.
-- This script assumes Group 0.9 is your all moving lights group, edit for needs.

PresetDocView:DispatchAction("Set Channel Focused Flag", "False")
if PresetDocView:IsLastChannelRowSelected() then
	OSC:EOS_SendKey("Clear")
	OSC:EOS_SendKey("Highlight")
	OSC:EOS_SendKey("Clear")
	Wait(0.05)
	OSC:EOS_SendNewCommandLine("Group 0.9 Select_Active Highlight#")
else
	OSC:EOS_SendKey("Next")
end