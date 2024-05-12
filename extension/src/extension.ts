// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from "vscode";
import { run_handler } from "./run_tests";
import * as discover from "./discover";
import * as fs from "fs";

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	// work maybe??? please ???

	const controller = vscode.tests.createTestController(
		"jest-lua-companion",
		"JestLua Tests"
	);

	const run_profile = controller.createRunProfile(
		"Run",
		vscode.TestRunProfileKind.Run,
		(request, token) => {
			try {
				const stop = run_handler(controller, request);
				token.onCancellationRequested(() => stop);
			} catch (err: any) {
				const e: Error = err;
				vscode.window.showErrorMessage(
					`Something went wrong while trying to run tests (${e.message}).`
				);
			}
		}
	);

	run_profile.label = "Jest Testing";

	vscode.commands.registerCommand("jest-lua-companion.runTests", () => {
		try {
			run_handler(
				controller,
				new vscode.TestRunRequest([], [], run_profile, false)
			);
		} catch (err: any) {
			const e: Error = err;
			vscode.window.showErrorMessage(
				`Something went wrong while trying to run tests (${e.message}).`
			);
		}
	});
	context.subscriptions.push(controller, run_profile);

	try {
		const watch =
			vscode.workspace.createFileSystemWatcher("**/sourcemap.json");

		context.subscriptions.push(watch);

		const get_test_item = (
			items: vscode.TestItemCollection,
			id: string,
			label: string,
			uri?: vscode.Uri
		) => {
			const child = items.get(id);

			if (child) {
				child.label = label;
				return child;
			} else {
				const test_item = controller.createTestItem(id, label, uri);
				items.add(test_item);
				return test_item;
			}
		};

		const update_tests = () => {
			console.log("updating tests");
			const workspace = discover.get_workspace_folder();
			const result = discover.search_for_tests_within_sourcemap();

			result.tests.forEach((object) => {
				const hierarchy = result.hierarchy.get(object);
				const file_path = object.filePaths?.at(0);

				console.log(hierarchy!.join("/"));
				get_test_item(
					controller.items,
					hierarchy!.join("/"),
					object.filePaths?.at(0) ?? hierarchy!.join("/"),
					file_path
						? vscode.Uri.joinPath(workspace.uri, file_path)
						: undefined
				);
			});
		};

		update_tests();
		watch.onDidChange(update_tests);
		watch.onDidCreate(update_tests);

		console.log("Created watch");
	} catch (e: any) {
		let err: Error = e;
		if (!(e instanceof Error)) {
			err = new Error(e);
		}

		vscode.window.showErrorMessage(
			`Attempted to listen to sourcemap.json (${err}).`
		);
	}

	console.log("started extension");
}

// This method is called when your extension is deactivated
export function deactivate() {}
