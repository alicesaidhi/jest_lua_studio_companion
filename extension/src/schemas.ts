import Ajv, { JSONSchemaType } from "ajv";

const config_file_schema = {
	type: "object",
	required: ["cwdInstance", "roots"],

	properties: {
		cwdInstance: { type: "string" },
		roots: {
			type: "array",
			uniqueItems: true,
			items: { type: "string" },
		},
		config: {
			type: "object",
			required: [],
			properties: {
				clearMocks: { type: "boolean" },
				debug: { type: "boolean" },
				expand: { type: "boolean" },
				json: { type: "boolean" },
				noStackTrace: { type: "boolean" },
				passWithNoTests: { type: "boolean" },
				resetMocks: { type: "boolean" },
				showConfig: { type: "boolean" },
				testMatch: { type: "array", items: { type: "string" } },
				testNamePattern: { type: "string" },
				testPathPattern: { type: "array", items: { type: "string" } },
				testPathPatternIgnore: {
					type: "array",
					items: { type: "string" },
				},
				testRegex: { type: "array", items: { type: "string" } },
				testTimeout: { type: "number" },
				updateSnapshot: { type: "boolean" },
				verbose: { type: "boolean" },
			},
		},
	},
};

const ajv = new Ajv({ coerceTypes: "array" });

export const check_config_schema = ajv.compile(config_file_schema);
