/*

Creates a server that on request that will request the Studio Client to run the
given tests and also return any data like logs.

*/

import { JsonSchemaToTsProvider } from "@fastify/type-provider-json-schema-to-ts";
import Fastify, {
	FastifyBaseLogger,
	FastifyInstance,
	FastifyReply,
	FastifyRequest,
} from "fastify";
import { IncomingMessage, Server, ServerResponse } from "http";
import * as vscode from "vscode";

export type Command = "start_tests";

export class JestServer {
	/*
	The fastify server that we are using
	*/
	private server: FastifyInstance<
		Server<typeof IncomingMessage, typeof ServerResponse>,
		IncomingMessage,
		ServerResponse<IncomingMessage>,
		FastifyBaseLogger,
		JsonSchemaToTsProvider
	>;

	/* A buffer of commands that need to be processed by a companion plugin. */
	commands: Command[];
	/* Used to tell if a companion plugin has connected to this server or not */
	is_connected: boolean = false;
	connected_placeid: string = "";
	connected_guid: string = "";

	/* A list of place id's that the client place must have */
	allowed_place_ids: string[];

	/* The current processing run */
	private run?: vscode.TestRun;

	constructor(port: number, allowed_placeids: string[]) {
		this.commands = [];
		this.allowed_place_ids = allowed_placeids;
		this.server = Fastify({
			bodyLimit: 10485760, // 10 MiB
		}).withTypeProvider<JsonSchemaToTsProvider>();

		/*
		Clients poll this path frequently to try and retrieve any commands that
		they may need to perform. Attempt to connect the client and return any commands.
		
		todo: look into supporting multiple clients?
		*/
		this.server.route({
			method: "GET",
			url: "/",
			schema: {
				headers: {
					type: "object",
					properties: {
						["place_id"]: { type: "string" },
						["place_guid"]: { type: "string" },
					},
					required: ["place_id", "place_guid"],
				},
			},
			handler: (req, rep) => {
				const { place_id, place_guid } = req.headers;
				if (this.check_connected(place_guid, place_id)) {
					rep.status(403).send();
				} else {
					this.get_commands(rep);
				}
			},
		});

		/*
		
		*/

		this.server.route({
			method: "POST",
			url: "/log",
			schema: {
				body: {
					type: "array",
					items: { type: "string" },
				},
			},
			handler: (request, response) => {},
		});

		this.server.listen({ port: port });
	}

	/*
	Checks if the given place that is trying to connect is valid
	*/
	private check_connected(guid: string, placeid: string) {
		if (this.is_connected && this.connected_guid === guid) {
			return true;
		} else if (
			this.is_connected === false &&
			(this.allowed_place_ids.includes(placeid) ||
				this.allowed_place_ids.length === 0)
		) {
			this.connected_placeid = placeid;
			this.connected_guid = guid;
			this.is_connected = true;
			return true;
		} else {
			return false;
		}
	}

	/*
	This function is used to tell the companion plugin about any commands that
	they need to process.
	*/
	private get_commands(reply: FastifyReply) {
		reply.status(200).send(this.commands);
		// reset the commands buffer.
		this.commands = [];
	}

	/*
	This function adds a command to the buffer that the companion plugin will read
	and then perform.
	*/
	public add_command(command: Command) {
		this.commands.push(command);
	}

	/*

	*/
	private log(request: FastifyRequest, reply: FastifyReply) {
		const body = request.body;
	}

	/*
	Closes the server and prevents any new requests from being made
	*/
	public close() {
		this.server.close();
	}
}
