import * as vscode from "vscode";
import fastify from "fastify";
import { JsonSchemaToTsProvider } from "@fastify/type-provider-json-schema-to-ts";
import { AggregatedTestResult } from "./roblox_jest_result";
import * as discover from "./discover";
import * as fs from "fs";

export function run_handler(
	controller: vscode.TestController,
	request: vscode.TestRunRequest
) {
	const jest_location = discover.search_for_jest_within_sourcemap();
	const config = discover.read_toml_config();

	const run = controller.createTestRun(request);
	console.log("starting test run");

	// setup a server so that we can run the tests
	const server = fastify({
		bodyLimit: 10485760, // 10 MiB
		return503OnClosing: false,
		logger: true,
	}).withTypeProvider<JsonSchemaToTsProvider>();
	let responded = false;
	let did_finish = false;

	// todo: make this nicer
	server.route({
		method: "GET",
		url: "/",
		schema: {
			headers: {
				type: "object",
				properties: {
					["place-id"]: { type: "string" },
					["place-guid"]: { type: "string" },
				},
				required: ["place-id", "place-guid"],
			},
		},
		handler: (req, rep) => {
			//todo: filter place_id
			if (responded === false) {
				responded = true;
				rep.status(200).send([
					["request_start_tests", jest_location, config],
				]);
			} else {
				rep.status(200).send([]);
			}
		},
	});

	server.route({
		method: "POST",
		url: "/log",
		schema: {
			headers: {
				type: "object",
				properties: {
					["place-id"]: { type: "string" },
					["place-guid"]: { type: "string" },
				},
				required: ["place-id", "place-guid"],
			},
			body: {
				type: "array",
				items: { type: "string" },
			},
		},
		handler: (req, rep) => {
			const body = req.body;
			body.forEach((str) =>
				run.appendOutput("\r\n" + str.replaceAll("\n", "\r\n"))
			);
			rep.status(200).send();
		},
	});

	server.route({
		method: "POST",
		url: "/results",
		schema: {
			headers: {
				type: "object",
				properties: {
					["place-id"]: { type: "string" },
					["place-guid"]: { type: "string" },
				},
				required: ["place-id", "place-guid"],
			},
			body: {
				type: "object",
			},
		},
		handler: (req, rep) => {
			console.log("received results");
			const body = req.body as AggregatedTestResult;

			// clear all test items
			const used: vscode.TestItem[] = [];

			const get_test_item = (
				items: vscode.TestItemCollection,
				id: string,
				label: string
			) => {
				const child = items.get(id);

				if (child) {
					// child.label = label;
					used.push(child);
					return child;
				} else {
					const test_item = controller.createTestItem(id, label);
					items.add(test_item);
					used.push(test_item);
					return test_item;
				}
			};

			body.testResults.forEach((file_test_result) => {
				const host_test_item = get_test_item(
					controller.items,
					file_test_result.testFilePath,
					file_test_result.testFilePath
				);

				console.log(file_test_result.testFilePath);

				file_test_result.testResults.forEach((result) => {
					const test_item = get_test_item(
						host_test_item.children,
						result.fullName,
						result.title
					);

					// find the test item to add this to
					let parent_test_item = host_test_item;

					result.ancestorTitles.forEach((name) => {
						const found_item = parent_test_item.children.get(name);

						if (found_item === undefined) {
							const new_item = get_test_item(
								test_item.children,
								name,
								name
							);

							parent_test_item = new_item;
						} else {
							parent_test_item = found_item;
						}
					});

					if (result.status === "passed") {
						run.passed(test_item, result.duration);
					} else if (result.status === "failed") {
						const test_message = new vscode.TestMessage(
							result.failureMessages.join("\n")
						);
						run.failed(test_item, test_message, result.duration);
					} else {
						run.skipped(test_item);
					}
				});
			});

			const check_children = (items: vscode.TestItemCollection) => {
				items.forEach((item) => {
					if (used.includes(item)) {
						check_children(item.children);
					} else {
						items.delete(item.id);
					}
				});
			};

			check_children(controller.items);

			did_finish = true;

			run.end();
			rep.status(200).send();

			server.close();
		},
	});

	server.route({
		method: "POST",
		url: "/fail",
		schema: {
			headers: {
				type: "object",
				properties: {
					["place-id"]: { type: "string" },
					["place-guid"]: { type: "string" },
				},
				required: ["place-id", "place-guid"],
			},
		},
		handler: (req, rep) => {
			console.log(req.body);
			vscode.window.showErrorMessage(
				`Something went wrong within the plugin companion (${req.body}).`
			);

			did_finish = true;
			run.end();
			rep.status(200).send();

			server.close();
		},
	});

	server.listen({ port: 21356 });
	console.log("created server and listening");

	return () => {
		if (did_finish) {
			return;
		}

		run.end();
		server.close();
	};
}
