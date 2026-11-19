/**
 * What a watcher's run answers when the change isn't what it was watching for (D-413). Nothing is
 * posted or pushed for it: a page that changes every hour must not write to the person every hour.
 */
export const WATCHER_NO_MATCH = "NO_MATCH";
