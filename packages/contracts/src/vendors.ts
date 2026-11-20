import { z } from "@hono/zod-openapi";

export const VendorReading = z
  .object({
    checked_at: z.string(),
    used: z.number().nullable(),
    remaining: z.number().nullable(),
    limit_value: z.number().nullable(),
    resets_at: z.string().nullable(),
    status: z.enum(["ok", "low", "out", "unknown"]),
    source: z.enum(["api", "own_count", "manual"]),
    error: z.string().nullable(),
  })
  .openapi("VendorReading");
export const VendorSettings = z
  .object({
    limit_value: z.number().positive().nullable(),
    period: z.enum(["day", "month", "billing_period", "prepaid"]).nullable(),
    period_start: z.string().datetime().nullable(),
    expires_at: z.string().datetime().nullable(),
    warn_at: z.number().gt(0).lte(1),
    enabled: z.boolean(),
    balance_warn_below: z.number().nonnegative().default(5),
  })
  .openapi("VendorSettings");
export const AdminVendor = VendorSettings.extend({
  billing_url: z.string().nullable(),
  impact: z.string().nullable(),
  vendor: z.string(),
  label: z.string(),
  kind: z.enum(["quota", "balance", "renewal"]),
  unit: z.string(),
  latest: VendorReading.nullable(),
  history: z.array(VendorReading),
}).openapi("AdminVendor");
