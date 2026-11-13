import * as aboutYou from "./about-you.ts";
import * as actionRules from "./action-rules.ts";
import * as admin from "./admin.ts";
import * as agentImport from "./agent-import.ts";
import * as appearance from "./appearance.ts";
import * as apps from "./apps.ts";
import * as attention from "./attention.ts";
import * as autonomy from "./autonomy.ts";
import * as billing from "./billing.ts";
import * as botSharing from "./bot-sharing.ts";
import * as botTemplate from "./bot-template.ts";
import * as bots from "./bots.ts";
import * as channels from "./channels.ts";
import * as chatExport from "./chat-export.ts";
import * as checkins from "./checkins.ts";
import * as computers from "./computers.ts";
import * as creations from "./creations.ts";
import * as deviceData from "./device-data.ts";
import * as encryption from "./encryption.ts";
import * as gallery from "./gallery.ts";
import * as galleryContent from "./gallery-content.ts";
import * as knowledge from "./knowledge.ts";
import * as links from "./links.ts";
import * as local from "./local.ts";
import * as mcp from "./mcp.ts";
import * as pages from "./pages.ts";
import * as passwordManagers from "./password-managers.ts";
import * as payments from "./payments.ts";
import * as plugins from "./plugins.ts";
import * as privacy from "./privacy.ts";
import * as projects from "./projects.ts";
import * as referrals from "./referrals.ts";
import * as replays from "./replays.ts";
import * as search from "./search.ts";
import * as secretStore from "./secret-store.ts";
import * as skillLearning from "./skill-learning.ts";
import * as skills from "./skills.ts";
import * as system from "./system.ts";
import * as teach from "./teach.ts";
import * as telephony from "./telephony.ts";
import * as voice from "./voice.ts";
import * as watchers from "./watchers.ts";
import * as workspaceFiles from "./workspace-files.ts";
import * as workspaces from "./workspaces.ts";

export const routes = {
  ...system,
  ...workspaces,
  ...bots,
  ...computers,
  ...creations,
  ...chatExport,
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
  ...botSharing,
  ...channels,
  ...encryption,
  ...gallery,
  ...galleryContent,
  ...telephony,
  ...payments,
  ...links,
  ...secretStore,
  ...deviceData,
  ...attention,
  ...aboutYou,
  ...pages,
  ...passwordManagers,
  ...replays,
  ...skillLearning,
  ...plugins,
  ...teach,
  ...watchers,
  ...workspaceFiles,
  ...mcp,
  ...referrals,
};
export {
  aboutYou,
  actionRules,
  admin,
  agentImport,
  appearance,
  attention,
  autonomy,
  billing,
  botSharing,
  bots,
  botTemplate,
  channels,
  checkins,
  computers,
  deviceData,
  encryption,
  gallery,
  knowledge,
  links,
  local,
  mcp,
  pages,
  passwordManagers,
  payments,
  plugins,
  privacy,
  projects,
  referrals,
  replays,
  search,
  secretStore,
  skillLearning,
  skills,
  system,
  teach,
  telephony,
  voice,
  watchers,
  workspaceFiles,
  workspaces,
};
