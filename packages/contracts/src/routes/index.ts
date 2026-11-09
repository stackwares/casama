import * as admin from "./admin.ts";
import * as autonomy from "./autonomy.ts";
import * as billing from "./billing.ts";
import * as bots from "./bots.ts";
import * as computers from "./computers.ts";
import * as local from "./local.ts";
import * as privacy from "./privacy.ts";
import * as system from "./system.ts";
import * as voice from "./voice.ts";
import * as workspaces from "./workspaces.ts";

export const routes = {
  ...system,
  ...workspaces,
  ...bots,
  ...computers,
  ...autonomy,
  ...voice,
  ...local,
  ...admin,
  ...billing,
  ...privacy,
};
export { admin, autonomy, billing, bots, computers, local, privacy, system, voice, workspaces };
