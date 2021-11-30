-- TriggerType=Menu
-- DisplayOutputWindow=false

-- For Colin Scott 2021-08-17:
--- This script will iterate through an entire cue list, then copy annotations and
--- vector data from the first photo to the second photo, then delete the first photo.

CueListView:DispatchAction("Select First Cue Row")

repeat
	isLastCue = CueListView:IsLastCueRowSelected()
	iHazThisManyPhotos = CueListView:GetPhotoCountForSelectedCue()
	if iHazThisManyPhotos > 1 then
		cueInfo = CueInfo:GetSelectedCueInfo()
		if cueInfo ~= nil then
			cueInfo.Image2VectorData = cueInfo.Image1VectorData
			CueInfo:SaveCueInfo(cueInfo)
		end
		CueListView:DispatchAction("Display First Cue Photo")
		CueListView:DispatchAction("Remove Displayed Cue Photo")
	end
	if not isLastCue then
		CueListView:DispatchAction("Select Next Cue Row")
	end
until(isLastcue)