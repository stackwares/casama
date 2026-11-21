/** Builds the page agent once (in memory) and hands the code to every test file. */
import type { TestProject } from "vitest/node";
import { bundle } from "../scripts/build.ts";

declare module "vitest" {
  export interface ProvidedContext {
    agentCode: string;
  }
}

export default async function setup(project: TestProject) {
  project.provide("agentCode", await bundle());
}
