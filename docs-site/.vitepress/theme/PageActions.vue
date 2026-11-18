<script setup lang="ts">
// Above every docs page: copy it as markdown, open the markdown copy, or hand it to an AI chat.
// The markdown copies are written by scripts/sync.ts next to each page (/develop/plugins.md).
import { useData } from "vitepress";
import { computed, ref } from "vue";

const { page } = useData();
const mdPath = computed(() => `/${page.value.relativePath}`);
const mdUrl = computed(() => `https://docs.casama.ai${mdPath.value}`);
// biome-ignore lint/correctness/noUnusedVariables: used in the template
const prompt = computed(
  () => `Read ${mdUrl.value} so you can answer questions about it and help me build with Casama.`,
);
const copied = ref<"" | "done" | "failed">("");

// biome-ignore lint/correctness/noUnusedVariables: used in the template
async function copy() {
  try {
    const r = await fetch(mdPath.value);
    if (!r.ok) throw new Error(String(r.status));
    await navigator.clipboard.writeText(await r.text());
    copied.value = "done";
  } catch {
    copied.value = "failed";
  }
  setTimeout(() => (copied.value = ""), 2000);
}
</script>

<template>
  <div class="page-actions" aria-label="Use this page with AI">
    <button type="button" @click="copy">
      {{ copied === "done" ? "Copied" : copied === "failed" ? "Couldn't copy" : "Copy page" }}
    </button>
    <a :href="mdPath" target="_blank" rel="noopener">Markdown</a>
    <a
      :href="`https://claude.ai/new?q=${encodeURIComponent(prompt)}`"
      target="_blank"
      rel="noopener"
      >Open in Claude</a
    >
    <a
      :href="`https://chatgpt.com/?hints=search&q=${encodeURIComponent(prompt)}`"
      target="_blank"
      rel="noopener"
      >Open in ChatGPT</a
    >
  </div>
</template>

<style scoped>
.page-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 6px;
  margin-bottom: 12px;
}
.page-actions button,
.page-actions a {
  border: 0;
  border-radius: 999px;
  padding: 0 14px;
  font-size: 13px;
  line-height: 32px;
  font-weight: 700;
  color: var(--vp-c-text-1);
  text-decoration: none;
  background: var(--vp-c-default-soft);
  cursor: pointer;
  transition:
    transform 0.14s cubic-bezier(0.16, 1, 0.3, 1),
    filter 0.2s ease;
}
.page-actions button:active,
.page-actions a:active {
  transform: scale(0.96);
}
@media (hover: hover) and (pointer: fine) {
  .page-actions button:hover,
  .page-actions a:hover {
    filter: brightness(1.08);
  }
}
</style>
