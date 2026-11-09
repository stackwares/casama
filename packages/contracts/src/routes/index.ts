import * as autonomy from "./autonomy.ts";
import * as bots from "./bots.ts";
import * as computers from "./computers.ts";
import * as system from "./system.ts";
import * as workspaces from "./workspaces.ts";

export const routes = { ...system, ...workspaces, ...bots, ...computers, ...autonomy };
export { autonomy, bots, computers, system, workspaces };
