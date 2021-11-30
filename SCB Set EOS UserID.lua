-- TriggerType=Menu
-- DisplayOutputWindow=false
-- Sets the EOS User ID - S.Beach 2019

userInput = PromptInputDialog("Change to EOS User:")
if userInput ~= nil then
	userID = tonumber(userInput)
	if userID > 0 then
		OSC:SendInt32("/eos/user",userID)
	end
end