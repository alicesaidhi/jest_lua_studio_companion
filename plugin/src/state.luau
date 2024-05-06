local Selection = game:GetService "Selection"

local vide = require(script.Parent.Parent.vide)
local jest_result_to_state = require(script.Parent.jest_result_to_state)
local videx = require(script.Parent.libraries.videx)

local source = vide.source

type Status = "passed" | "failed" | "skipped" | "pending" | "todo" | "disabled"

return videx.new(
	source {
		stored_test_results = {

			{
				name = "test",
				status = "passed",
			},
			{
				name = "test 2",
				status = "failed",
			},

			{
				name = "test 3",
				status = "skipped",
			},
		} :: {
			{
				name: string,
				status: Status,
			}
		},
		jest_results = videx.null :: jest_result_to_state.AggregatedTestResult?,

		selected = Selection:Get(),
	},
	source {}
)
