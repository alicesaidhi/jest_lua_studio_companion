/*

Handles discovery of tests within a file

*/

import * as vscode from "vscode";
import * as toml from "toml";
import * as fs from "fs";
import { check_config_schema } from "./schemas";
import * as micromatch from "micromatch";

type Sourcemap = {
	name: string;
	className: string;
	filePaths?: string[];
	children?: Sourcemap[];
};

type ConfigFile = {
	cwdInstance: string;
	roots: string[];

	config?: {
		clearMocks?: boolean;
		debug?: boolean;
		expand?: boolean;
		json?: boolean;
		noStackTrace?: boolean;
		passWithNoTests?: boolean;
		resetMocks?: boolean;
		showConfig?: boolean;
		testMatch?: string[];
		testNamePattern?: string;
		testPathPattern?: string;
		testTimeout?: number;
		updateSnapshot?: boolean;
		verbose?: boolean;
	};
};

/*
Gets the workspace folder
*/
export function get_workspace_folder() {
	const folder =
		vscode.workspace.workspaceFolders?.[0] ??
		(vscode.window.activeTextEditor &&
			vscode.workspace.getWorkspaceFolder(
				vscode.window.activeTextEditor.document.uri
			));

	if (folder) {
		return folder;
	} else {
		throw Error("Unable to find workspace folder");
	}
}

/*
Reads the sourcemap.json
*/
export function get_sourcemap() {
	// finds the sourcemap json and reads it
	const workspace_folder = get_workspace_folder();

	const sourcemap_path = vscode.Uri.joinPath(
		workspace_folder.uri,
		"./sourcemap.json"
	).fsPath;

	try {
		return JSON.parse(
			fs.readFileSync(sourcemap_path, {
				encoding: "utf-8",
				flag: "r",
			})
		) as Sourcemap;
	} catch (e) {
		throw Error(`Unable to parse sourcemap.json (${sourcemap_path}).`);
	}
}

/*
Looks for tests within your sourcemap
*/

export function explore_hierarchy(sourcemap: Sourcemap) {
	const hierarchy = new Map<Sourcemap, string[]>();

	const explore_object = (object: Sourcemap) => {
		const object_hierarchy = hierarchy.get(object);

		object.children?.forEach((child) => {
			hierarchy.set(child, object_hierarchy!.concat(child.name));
			explore_object(child);
		});
	};

	hierarchy.set(sourcemap, []);
	explore_object(sourcemap);

	return hierarchy;
}

/* 
Looks for a jest installation within your sourcemap using BFS and returns the
path to that install file.
*/
export function search_for_jest_within_sourcemap() {
	// finds the sourcemap json and reads it
	const sourcemap = get_sourcemap();

	// finds the jest
	const hierarchy = new Map<Sourcemap, string[]>();
	let jest_location: Sourcemap | undefined = undefined;

	// must start with game!
	if (sourcemap.className !== "DataModel") {
		throw Error("Sourcemap does not start with the DataModel.");
	}

	hierarchy.set(sourcemap, []);

	let to_search: Sourcemap[] = [sourcemap];
	let new_elements: Sourcemap[] = [];

	const searchChild = (object: Sourcemap) => {
		const object_hierarchy = hierarchy.get(object);

		object.children?.forEach((child) => {
			hierarchy.set(child, object_hierarchy!.concat(child.name));

			if (child.name.toLowerCase() === "jest") {
				jest_location = child;
			} else {
				new_elements.push(child);
			}
		});
	};

	while (to_search.length !== 0 && jest_location === undefined) {
		to_search.forEach(searchChild);

		to_search = new_elements;
		new_elements = [];
	}

	if (jest_location !== undefined) {
		const object: Sourcemap = jest_location;
		console.log("found jest at", hierarchy.get(object));
		return hierarchy.get(object);
	} else {
		return undefined;
	}
}

/*
Reads the toml config file within the workspace
*/
export function read_toml_config() {
	const workspace_folder = get_workspace_folder();

	const config_path = vscode.Uri.joinPath(
		workspace_folder.uri,
		"./jest-runner.toml"
	).fsPath;

	let config: ConfigFile;

	try {
		config = toml.parse(
			fs.readFileSync(config_path, {
				encoding: "utf-8",
				flag: "r",
			})
		);
	} catch (e) {
		throw Error(`Could not parse jest-runner.toml (${config_path}).`);
	}

	console.log(config);

	if (!check_config_schema(config) as boolean) {
		throw Error("Invalid jest-runner.toml format");
	}

	return config;
}

/*
Reads the toml config sand searches for any files with tests matching within the workspace
*/
export function search_for_tests_within_sourcemap() {
	const config = read_toml_config();
	const test_match = config.config?.testMatch ?? [
		"**/__tests__/**/*",
		"**/?(*.)+(spec|test)",
	];

	const sourcemap = get_sourcemap();
	const hierarchy = explore_hierarchy(sourcemap);
	const tests: Sourcemap[] = [];

	hierarchy.forEach((path, child) => {
		if (micromatch.match([child.name], test_match).length !== 0) {
			tests.push(child);
		}
	});

	return {
		tests: tests,
		hierarchy: hierarchy,
	};
}
