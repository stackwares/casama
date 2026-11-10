import * as admin from "./admin.ts";
import * as appearance from "./appearance.ts";
import * as apps from "./apps.ts";
import * as autonomy from "./autonomy.ts";
import * as billing from "./billing.ts";
import * as bots from "./bots.ts";
import * as computers from "./computers.ts";
import * as local from "./local.ts";
import * as privacy from "./privacy.ts";
import * as search from "./search.ts";
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
  ...appearance,
  ...apps,
  ...search,
};
export {
  admin,
  appearance,
  autonomy,
  billing,
  bots,
  computers,
  local,
  privacy,
  search,
  system,
  voice,
  workspaces,
};
