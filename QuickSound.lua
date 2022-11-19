QuickSound = {}

function QuickSound:Init()
	
	QuickSound:BuildRootFrame()
	QuickSound:BuildSliders()

	QuickSound:MakeFrameMouseover(QuickSound.SlidersPanel)
	
end

function QuickSound:BuildRootFrame()

	--Create root frame
	QuickSound.SlidersPanel = CreateFrame("Frame", "QuickSound_SlidersPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate")

	QuickSound.SlidersPanel:SetPoint("CENTER")
	QuickSound.SlidersPanel:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	QuickSound.SlidersPanel:SetBackdropColor(0, 0, 0, 0.5)
	QuickSound.SlidersPanel:SetSize(200, 190)

	--Make sliders frame movable
	QuickSound.SlidersPanel:SetMovable(true)
	QuickSound.SlidersPanel:EnableMouse(true)
	QuickSound.SlidersPanel:RegisterForDrag("LeftButton")
	QuickSound.SlidersPanel:SetScript("OnDragStart", QuickSound.SlidersPanel.StartMoving)
	QuickSound.SlidersPanel:SetScript("OnDragStop", QuickSound.SlidersPanel.StopMovingOrSizing)
	QuickSound.SlidersPanel:SetClampedToScreen(true)
	
	QuickSound.SlidersPanel:SetAlpha(0)
	
end


function QuickSound:BuildSliders()

	--Create master volume slider
	QuickSound.MasterVolumeSlider = CreateFrame("Slider", "QuickSound_MasterVolumeSlider", QuickSound.SlidersPanel, "OptionsSliderTemplate")
	QuickSound:SetupVolumeSlider(
		QuickSound.MasterVolumeSlider,
		"Master",
		"Controls the game's master volume.",
		"Sound_MasterVolume"
	)
	QuickSound.MasterVolumeSlider:SetPoint("TOP", QuickSound.SlidersPanel, "TOP", 0, -25)

	--Create sfx volume slider
	QuickSound.SFXVolumeSlider = CreateFrame("Slider", "QuickSound_SFXVolumeSlider", QuickSound.SlidersPanel, "OptionsSliderTemplate")
	QuickSound:SetupVolumeSlider(
		QuickSound.SFXVolumeSlider,
		"Sound",
		"Adjusts the sound effect volume.",
		"Sound_SFXVolume"
	)
	QuickSound.SFXVolumeSlider:SetPoint("TOP", QuickSound.MasterVolumeSlider, "BOTTOM", 0, -15)

	--Create music volume slider
	QuickSound.MusicVolumeSlider = CreateFrame("Slider", "QuickSound_MusicVolumeSlider", QuickSound.SlidersPanel, "OptionsSliderTemplate")
	QuickSound:SetupVolumeSlider(
		QuickSound.MusicVolumeSlider,
		"Music",
		"Adjusts the background music volume.",
		"Sound_MusicVolume"
	)
	QuickSound.MusicVolumeSlider:SetPoint("TOP", QuickSound.SFXVolumeSlider, "BOTTOM", 0, -15)

	--Create ambient volume slider
	QuickSound.AmbientVolumeSlider = CreateFrame("Slider", "QuickSound_AmbientVolumeSlider", QuickSound.SlidersPanel, "OptionsSliderTemplate")
	QuickSound:SetupVolumeSlider(
		QuickSound.AmbientVolumeSlider,
		"Ambient",
		"Adjusts the ambient sound volume.",
		"Sound_AmbienceVolume"
	)
	QuickSound.AmbientVolumeSlider:SetPoint("TOP", QuickSound.MusicVolumeSlider, "BOTTOM", 0, -15)

	--Create dialogue volume slider
	QuickSound.DialogVolumeSlider = CreateFrame("Slider", "QuickSound_DialogVolumeSlider", QuickSound.SlidersPanel, "OptionsSliderTemplate")
	QuickSound:SetupVolumeSlider(
		QuickSound.DialogVolumeSlider,
		"Dialog",
		"Adjusts the dialog volume.",
		"Sound_DialogVolume"
	)
	QuickSound.DialogVolumeSlider:SetPoint("TOP", QuickSound.AmbientVolumeSlider, "BOTTOM", 0, -15)

end


--------------------------------------------------
-- Utility Functions
--------------------------------------------------
function QuickSound:MakeFrameMouseover(frame)
	frame:SetScript("OnEnter", function(self, motion)
		if motion then
			frame:SetAlpha(1)
		end
	end)
	frame:SetScript("OnLeave", function(self, motion)
		if motion then
			frame:SetAlpha(0)
		end
	end)

	local children = { frame:GetChildren() }
	for i, child in ipairs(children) do
		QuickSound:SetChildFrameMouseover(frame, child)
	end
end

function QuickSound:SetChildFrameMouseover(root, child) 
	child:HookScript("OnEnter", function(self, motion)
		if motion then
			root:SetAlpha(1)
		end
	end)

	child:HookScript("OnLeave", function(self, motion)
		if motion then
			root:SetAlpha(0)
		end
	end)

	local children = { child:GetChildren() }
	for i, c in ipairs(children) do
		QuickSound:SetChildFrameMouseover(root, c)
	end
end

function QuickSound:SetupVolumeSlider(slider, title, tooltip, cvar)
	slider.tooltipText = tooltip

	local sname = slider:GetName()
	_G[sname .. 'Low']:SetText('0')
	_G[sname .. 'High']:SetText('100')
	_G[sname .. 'Text']:SetText(title)

	slider:SetMinMaxValues(0, 100)
	slider:SetValue(C_CVar.GetCVar(cvar) * 100)
	slider:SetValueStep(1)
	slider:SetObeyStepOnDrag(true)

	slider:SetScript("OnValueChanged", function(self, value)
		C_CVar.SetCVar(cvar, value / 100)
	end)
end

QuickSound:Init()