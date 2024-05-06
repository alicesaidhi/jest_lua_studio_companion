export type Status =
	| "passed"
	| "failed"
	| "skipped"
	| "pending"
	| "todo"
	| "disabled";

export type PerfStats = {
	end: number;
	runtime: number;
	slow: boolean;
	start: number;
};

export type FailureDetails = {
	__stack: string;
	matcherResult: {
		actual: number;
		expected: number;
		message: string;
		name: string;
		pass: boolean;
	}[];
	message: string;
	name: string;
	stack: string;
};

export type TestResult = {
	ancestorTitles: string[];
	duration: number; // in ms i assume
	failureDetails: FailureDetails[];
	failureMessages: string[];
	fullName: string;
	invocations: number;
	numPassingAsserts: number;
	retryReasons: unknown[];
	status: Status;
	title: string;
};

export type FileTestResult = {
	leaks: boolean;
	numFailingTests: number;
	numPassingTests: number;
	numPendingTests: number;
	numTodoTests: number;

	//todo: figure out what openHandles are
	//todo: do something with snapshots maybe?

	perfStats: PerfStats;

	skipped: boolean;

	testFilePath: string;
	testResults: TestResult[];
};

export type AggregatedTestResult = {
	numFailedTestSuites: number;
	numFailedTests: number;
	numPassedTestSuites: number;
	numPassedTests: number;
	numPendingTestSuites: number;
	numPendingTests: number;
	numRuntimeErrorTestSuites: number;
	numTodoTests: number;
	numTotaltestSuites: number;
	numTotalTests: number;

	//todo: figure out what openHandles are
	//todo: do something with snapshots maybe?

	// Unix timestamp describing when the test began running
	startTime: number;

	success: boolean;
	wasInterrupted: boolean;

	testResults: FileTestResult[];
};
