import { OpenAPIHono } from "@hono/zod-openapi";
import { API_VERSION, PRODUCT_NAME } from "./brand.ts";
import { RunEvent, RunEventEnvelope } from "./events.ts";
import { routes } from "./routes/index.ts";

export const openApiConfig: {
  openapi: string;
  info: { title: string; version: string; license: { name: string; url: string } };
  servers: { url: string }[];
} = {
  openapi: "3.1.0",
  info: {
    title: `${PRODUCT_NAME} API`,
    version: API_VERSION,
    license: { name: "Apache-2.0", url: "https://www.apache.org/licenses/LICENSE-2.0" },
  },
  servers: [{ url: "http://localhost:8787" }],
};

/** Register the shared security scheme and event components on any OpenAPIHono app. */
export function registerComponents(app: Pick<OpenAPIHono, "openAPIRegistry">) {
  app.openAPIRegistry.registerComponent("securitySchemes", "bearerAuth", {
    type: "http",
    scheme: "bearer",
    bearerFormat: "JWT",
    description: "Supabase access token",
  });
  app.openAPIRegistry.register("RunEvent", RunEvent);
  app.openAPIRegistry.register("RunEventEnvelope", RunEventEnvelope);
}

/** Build the OpenAPI document from route definitions alone (no handlers needed). */
export function buildOpenApiDocument() {
  const app = new OpenAPIHono();
  registerComponents(app);
  for (const route of Object.values(routes)) app.openAPIRegistry.registerPath(route);
  return app.getOpenAPI31Document(openApiConfig);
}
