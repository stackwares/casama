import * as actionRules from "./action-rules.ts";
import * as admin from "./admin.ts";
import * as appearance from "./appearance.ts";
import * as apps from "./apps.ts";
import * as autonomy from "./autonomy.ts";
import * as botTemplate from "./bot-template.ts";
import * as checkins from "./checkins.ts";
import * as billing from "./billing.ts";
import * as bots from "./bots.ts";
import * as computers from "./computers.ts";
import * as local from "./local.ts";
import * as mcp from "./mcp.ts";
import * as privacy from "./privacy.ts";
import * as projects from "./projects.ts";
import * as search from "./search.ts";
import * as skills from "./skills.ts";
import * as system from "./system.ts";
import * as voice from "./voice.ts";
import * as agentImport from "./agent-import.ts";
import * as knowledge from "./knowledge.ts";
import * as pages from "./pages.ts";
import * as replays from "./replays.ts";
import * as skillLearning from "./skill-learning.ts";
import * as plugins from "./plugins.ts";
import * as teach from "./teach.ts";
import * as watchers from "./watchers.ts";
import * as workspaceFiles from "./workspace-files.ts";
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
  ...skills,
  ...botTemplate,
  ...projects,
  ...checkins,
  ...actionRules,
  ...agentImport,
  ...knowledge,
  ...pages,
  ...replays,
  ...skillLearning,
  ...plugins,
  ...teach,
  ...watchers,
  ...workspaceFiles,
  ...mcp,
};
export {
  actionRules,
  admin,
  appearance,
  autonomy,
  billing,
  botTemplate,
  checkins,
  bots,
  computers,
  local,
  mcp,
  privacy,
  projects,
  search,
  skills,
  system,
  voice,
  agentImport,
  knowledge,
  pages,
  replays,
  skillLearning,
  plugins,
  teach,
  watchers,
  workspaceFiles,
  workspaces,
};
