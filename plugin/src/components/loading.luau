local RunService = game:GetService "RunService"

local vide = require(script.Parent.Parent.Parent.vide)

local create = vide.create
local source = vide.source
local cleanup = vide.cleanup

type can<T> = T | () -> T
type progress_circle = {
	color: can<Color3>,

	layout: vide.vFrame?,
}

local HIGHLIGHT = Color3.fromRGB(0, 162, 255)
local number_sequence = NumberSequence.new {
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.299, 0),
	NumberSequenceKeypoint.new(0.3, 1),
	NumberSequenceKeypoint.new(1, 1),
}

local function loading_circle(props: progress_circle)
	local rotation = source(0)

	cleanup(
		RunService.Heartbeat:Connect(
			function(dt) rotation(rotation() + dt * 360) end
		)
	)

	return create "Frame" {

		Size = UDim2.fromOffset(24, 24),

		BackgroundTransparency = 1,

		props.layout,

		create "Frame" {

			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),

			BackgroundColor3 = HIGHLIGHT,

			create "UICorner" {
				CornerRadius = UDim.new(1, 0),
			},

			create "UIGradient" {
				Transparency = number_sequence,
				Rotation = rotation,
			},
		},

		create "Frame" {

			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),

			BackgroundColor3 = props.color,

			create "UICorner" {
				CornerRadius = UDim.new(1, 0),
			},
		},
	}
end

return loading_circle
