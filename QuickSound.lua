QuickSound = LibStub("AceAddon-3.0"):NewAddon("QuickSound", "AceConsole-3.0", "AceHook-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local options = {
	name = "QuickSound",
	handler = QuickSound,
	type = "group",
	childGroups = "tab",
	args = {
		appearance = {
			name = "Appearance",
			type = "group",
			desc = "Change how the QuickSound panel looks.",
			args = {
				mouseoverHeader = {
					order = 0,
					name = "Visibility",
					type = "header"
				},
				mouseoverDesc = {
					order = 1,
					name = "When toggled ON, the panel will only display on mouseover. When toggled OFF, it will always be visible.",
					type = "description"				
				},
				mouseover = {
					order = 2,
					name = "Mouseover Only",
					desc = "Whether the panel should only show on mouseover, or all of the time.",
					type = "toggle",
					get = "GetMouseoverOnly",
					set = "SetMouseoverOnly",
				},

				borderHeader = {
					order = 10,
					name = "Border",
					type = "header"
				},
				border = {
					order = 11,
					name = "Border Style",
					desc = "The border style used by the volume sliders panel.",
					type = "select",
					values = "GetBorderTypes",
					get = "GetBorderType",
					set = "SetBorderType",
				},
				borderSize = {
					order = 12,
					name = "Border Size",
					desc = "The size of the volume sliders panel border.",
					type = "range",
					min = 0,
					softMax = 30,
					step = 1,
					bigStep = 1,
					get = "GetBorderSize",
					set = "SetBorderSize",
				},
				borderColor = {
					order = 13,
					name = "Border Color",
					desc = "The color of the volume sliders panel border.",
					type = "color",
					hasAlpha = true,
					get = "GetBorderColor",
					set = "SetBorderColor",
				},

				backgroundHeader = {
					order = 20,
					name = "Background",
					type = "header"
				},
				background = {
					order = 21,
					name = "Background Style",
					desc = "The background style used by the volume sliders panel.",
					type = "select",
					values = "GetBackgroundTypes",
					get = "GetBackgroundType",
					set = "SetBackgroundType",
				},
				backgroundColor = {
					order = 22,
					name = "Background Color",
					desc = "The color of the volume sliders background.",
					type = "color",
					hasAlpha = true,
					get = "GetBackgroundColor",
					set = "SetBackgroundColor",
				},
				insets = {
					order = 23,
					name = "Background Inset",
					desc = "Empty padding space between the border and the background. You may need to adjust this setting if using a very thick or thin border.",
					type = "range",
					min = 0,
					softMax = 10,
					step = 1,
					bigStep = 1,
					get = "GetFrameInsets",
					set = "SetFrameInsets"
				}
			},
		},
	},
}

local defaultDB = {
	profile = {
		frameBorder = "Interface\\Tooltips\\UI-Tooltip-Border",
		frameBorderSize = 16,
		frameBorderColor = { 1, 1, 1, 1 },
		frameBackground = "Interface\\Tooltips\\UI-Tooltip-Background",
		frameBackgroundColor = { 0, 0, 0, 0.5 },
		frameInsets = 4,
		mouseoverOnly = true,
	}
}

function QuickSound:OnInitialize()
	-- DB
	self.db = LibStub("AceDB-3.0"):New("QuickSoundDB", defaultDB, true)
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	-- Setup Configs
	local AceGUI = LibStub("AceGUI-3.0")
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")

	AceConfig:RegisterOptionsTable("QuickSound", options, "qso")
	AceConfigDialog:AddToBlizOptions("QuickSound", "QuickSound")

	self:RegisterChatCommand("qs", "OpenSettings")

	-- Initialize Addon
	-- Create root frame
	self.SlidersPanel = CreateFrame("Frame", "QuickSound_SlidersPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	self:UpdateStyle()
	self.SlidersPanel:SetSize(200, 190)

	--Make sliders frame movable
	self.SlidersPanel:SetMovable(true)
	self.SlidersPanel:EnableMouse(true)
	self.SlidersPanel:RegisterForDrag("LeftButton")
	self.SlidersPanel:SetScript("OnDragStart", self.StartFrameDrag)
	self.SlidersPanel:SetScript("OnDragStop", self.EndFrameDrag)
	self.SlidersPanel:SetClampedToScreen(true)
	self.SlidersPanel:SetScript("OnEnter", self.MouseEnter)
	self.SlidersPanel:SetScript("OnLeave", self.MouseLeave)

	-- Create master volume slider	
	self.MasterVolumeSlider = CreateFrame("Slider", "QuickSound_MasterVolumeSlider", self.SlidersPanel, "OptionsSliderTemplate")
	self:SetupVolumeSlider(
		self.MasterVolumeSlider,
		"Master",
		"Controls the game's master volume.",
		"Sound_MasterVolume"
	)
	self.MasterVolumeSlider:SetPoint("TOP", self.SlidersPanel, "TOP", 0, -25)

	-- Create sfx volume slider
	self.SFXVolumeSlider = CreateFrame("Slider", "QuickSound_SFXVolumeSlider", self.SlidersPanel, "OptionsSliderTemplate")
	self:SetupVolumeSlider(
		self.SFXVolumeSlider,
		"Sound",
		"Adjusts the sound effect volume.",
		"Sound_SFXVolume"
	)
	self.SFXVolumeSlider:SetPoint("TOP", self.MasterVolumeSlider, "BOTTOM", 0, -15)

	-- Create music volume slider
	self.MusicVolumeSlider = CreateFrame("Slider", "QuickSound_MusicVolumeSlider", self.SlidersPanel, "OptionsSliderTemplate")
	self:SetupVolumeSlider(
		self.MusicVolumeSlider,
		"Music",
		"Adjusts the background music volume.",
		"Sound_MusicVolume"
	)
	self.MusicVolumeSlider:SetPoint("TOP", self.SFXVolumeSlider, "BOTTOM", 0, -15)

	-- Create ambient volume slider
	self.AmbientVolumeSlider = CreateFrame("Slider", "QuickSound_AmbientVolumeSlider", self.SlidersPanel, "OptionsSliderTemplate")
	self:SetupVolumeSlider(
		self.AmbientVolumeSlider,
		"Ambient",
		"Adjusts the ambient sound volume.",
		"Sound_AmbienceVolume"
	)
	self.AmbientVolumeSlider:SetPoint("TOP", self.MusicVolumeSlider, "BOTTOM", 0, -15)

	-- Create dialogue volume slider
	self.DialogVolumeSlider = CreateFrame("Slider", "QuickSound_DialogVolumeSlider", self.SlidersPanel, "OptionsSliderTemplate")
	self:SetupVolumeSlider(
		self.DialogVolumeSlider,
		"Dialog",
		"Adjusts the dialog volume.",
		"Sound_DialogVolume"
	)
	self.DialogVolumeSlider:SetPoint("TOP", self.AmbientVolumeSlider, "BOTTOM", 0, -15)
end

function QuickSound:OnEnable()
	QuickSound:Print("QuickSound enabled.")

	-- Hook Profile Functions
	self:SecureHook(self.db, "SetProfile", function()
		QuickSound:UpdateStyle()
	end)
end

function QuickSound:OnDisable()
	QuickSound:Print("Quicksound disabled.")
	QuickSound:UnhookAll()
end

--------------------------------------------------
-- Utility Functions
--------------------------------------------------
function QuickSound:MouseEnter(motion)
	if QuickSound.db.profile.mouseoverOnly and motion then
		QuickSound:SetAlpha(QuickSound.SlidersPanel, 1)
	end
end

function QuickSound:MouseLeave(motion)
	if QuickSound.db.profile.mouseoverOnly and motion then
		QuickSound:SetAlpha(QuickSound.SlidersPanel, 0)
	end
end

function QuickSound:SetAlpha(frame, alpha)
	frame:SetAlpha(alpha)
	local children = { frame:GetChildren() }
	for i, child in ipairs(children) do
		self:SetAlpha(child, alpha)
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
	slider:SetScript("OnEnter", self.MouseEnter)
	slider:SetScript("OnLeave", self.MouseLeave)

	slider:SetScript("OnValueChanged", function(self, value)
		C_CVar.SetCVar(cvar, value / 100)
	end)
end

--------------------------------------------------
-- Dragging Logic
--------------------------------------------------
function QuickSound:StartFrameDrag()
	self:StartMoving()
end

function QuickSound:EndFrameDrag()
	self:StopMovingOrSizing()
end

--------------------------------------------------
-- Options Functions
--------------------------------------------------
function QuickSound:GetBorderTypes()
	local LSM = LibStub("LibSharedMedia-3.0")
	local map = LSM:HashTable(LSM.MediaType.BORDER)
	local reverse = {}
	for k, v in pairs(map) do
		reverse[v] = k
	end
	return reverse
end

function QuickSound:GetBackgroundTypes()
	local LSM = LibStub("LibSharedMedia-3.0")
	local map = LSM:HashTable(LSM.MediaType.BACKGROUND)
	local reverse = {}
	for k, v in pairs(map) do
		reverse[v] = k
	end
	return reverse
end

-- Border Type
function QuickSound:GetBorderType(info)
	return self.db.profile.frameBorder
end

function QuickSound:SetBorderType(info, input)
	self.db.profile.frameBorder = input
	self:UpdateStyle()
end

-- Border Size
function QuickSound:GetBorderSize(info)
	return self.db.profile.frameBorderSize
end

function QuickSound:SetBorderSize(info, input)
	self.db.profile.frameBorderSize = input
	self:UpdateStyle()
end

-- Border Color
function QuickSound:GetBorderColor(info)
	return unpack(self.db.profile.frameBorderColor)
end

function QuickSound:SetBorderColor(info, r, g, b, a)
	self.db.profile.frameBorderColor = {r, g, b, a}
	self:UpdateStyle()
end

-- Background Type
function QuickSound:GetBackgroundType(info)
	return self.db.profile.frameBackground
end

function QuickSound:SetBackgroundType(info, input)
	self.db.profile.frameBackground = input
	self:UpdateStyle()
end

-- Background Color
function QuickSound:GetBackgroundColor(info)
	return unpack(self.db.profile.frameBackgroundColor)
end

function QuickSound:SetBackgroundColor(info, r, g, b, a)
	self.db.profile.frameBackgroundColor = {r, g, b, a}
	self:UpdateStyle()
end

-- Frame Insets
function QuickSound:GetFrameInsets(info)
	return self.db.profile.frameInsets
end

function QuickSound:SetFrameInsets(info, input)
	self.db.profile.frameInsets = input
	self:UpdateStyle()
end

-- Mouseover Only
function QuickSound:GetMouseoverOnly(info)
	return self.db.profile.mouseoverOnly
end

function QuickSound:SetMouseoverOnly(info, input)
	self.db.profile.mouseoverOnly = input
	self:UpdateStyle()
end

-- Style Updater
function QuickSound:UpdateStyle()
	local LSM = LibStub("LibSharedMedia-3.0")
	local insets = self:GetFrameInsets()

	self.SlidersPanel:SetBackdrop({
		bgFile = self:GetBackgroundType(),
		edgeFile = self:GetBorderType(),
		edgeSize = self:GetBorderSize(),
		insets = { 
			left = insets,
			right = insets,
			top = insets,
			bottom = insets
		}
	})

	self.SlidersPanel:SetBackdropColor(self:GetBackgroundColor())
	self.SlidersPanel:SetBackdropBorderColor(self:GetBorderColor())

	if self:GetMouseoverOnly() then
		self:SetAlpha(self.SlidersPanel, 0)
	else
		self:SetAlpha(self.SlidersPanel, 1)
	end
end

function QuickSound:OpenSettings()
	Settings.OpenToCategory("QuickSound")
end