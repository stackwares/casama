export type OrgRole = "owner" | "admin" | "member";

const rank: Record<OrgRole, number> = { member: 1, admin: 2, owner: 3 };

/** True when `role` grants at least `required` (owner > admin > member). Mirrors SQL has_role(). */
export const roleAtLeast = (role: OrgRole, required: OrgRole) => rank[role] >= rank[required];

/** Roles that `actor` may assign to others. Only owners create owners. */
export function assignableRoles(actor: OrgRole): OrgRole[] {
  if (actor === "owner") return ["owner", "admin", "member"];
  if (actor === "admin") return ["admin", "member"];
  return [];
}
