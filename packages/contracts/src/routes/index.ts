import * as bots from "./bots.ts";
import * as computers from "./computers.ts";
import * as system from "./system.ts";
import * as workspaces from "./workspaces.ts";

export const routes = { ...system, ...workspaces, ...bots, ...computers };
export { bots, computers, system, workspaces };
