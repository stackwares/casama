/**
 * Names the server sends with ids so the apps don't each keep a copy (D-372). Served in
 * GET /v1/app-config `names`; an app keeps its own copy only as the fallback for older servers.
 */

/**
 * An app's name in a tool call, by its slug with spaces, dashes and underscores taken out:
 * Composio's "googlecalendar" reads "Google Calendar". Slugs not here are capitalized.
 */
export const TOOL_APP_NAMES: Record<string, string> = {
  googlecalendar: "Google Calendar",
  googledrive: "Google Drive",
  googlesheets: "Google Sheets",
  googledocs: "Google Docs",
  googlemeet: "Google Meet",
  googlesuper: "Google",
  googletasks: "Google Tasks",
  googlephotos: "Google Photos",
  github: "GitHub",
  gitlab: "GitLab",
  linkedin: "LinkedIn",
  hubspot: "HubSpot",
  youtube: "YouTube",
  whatsapp: "WhatsApp",
  clickup: "ClickUp",
  outlook: "Outlook",
  microsoftteams: "Microsoft Teams",
  onedrive: "OneDrive",
  sharepoint: "SharePoint",
  quickbooks: "QuickBooks",
};
