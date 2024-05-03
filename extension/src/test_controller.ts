import * as vscode from "vscode";

const controller = vscode.tests.createTestController(
	"jestlua_tests",
	"Jest Lua Tests"
);

/*
Processes the results that are obtained from the companion plugin

*/
export function process_results() {}
