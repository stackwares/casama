<script setup lang="ts">
// A search box at the top of /faq (placed by the theme's doc-before slot, since faq.md stays plain
// markdown). Every word must match a question or its answer: a "### question" section is the h3 and
// what follows it until the next h2 or h3, and a group (h2) with nothing left is hidden too.
import { useRoute } from "vitepress";
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";

const route = useRoute();
const isFaq = computed(() => /^\/faq(\.html)?$/.test(route.path));
const query = ref("");
const shown = ref(-1);

type Section = { heading: HTMLElement; nodes: HTMLElement[]; text: string };
type Group = { heading: HTMLElement | null; sections: Section[] };

function collect(): Group[] {
  const doc =
    document.querySelector<HTMLElement>(".vp-doc > div") ?? document.querySelector(".vp-doc");
  if (!doc) return [];
  const groups: Group[] = [{ heading: null, sections: [] }];
  let section: Section | null = null;
  for (const node of Array.from(doc.children) as HTMLElement[]) {
    if (node.tagName === "H2") {
      groups.push({ heading: node, sections: [] });
      section = null;
    } else if (node.tagName === "H3") {
      section = { heading: node, nodes: [node], text: "" };
      groups[groups.length - 1].sections.push(section);
    } else if (section && node.tagName !== "H1") {
      section.nodes.push(node);
    }
  }
  for (const g of groups) {
    for (const s of g.sections) {
      s.text = s.nodes
        .map((n) => n.textContent ?? "")
        .join(" ")
        .replace(/\s+/g, " ")
        .toLowerCase();
    }
  }
  return groups.filter((g) => g.sections.length);
}

function apply() {
  if (typeof document === "undefined" || !isFaq.value) return;
  const words = query.value.toLowerCase().split(/\s+/).filter(Boolean);
  let count = 0;
  for (const g of collect()) {
    let any = false;
    for (const s of g.sections) {
      const hit = words.every((w) => s.text.includes(w));
      for (const n of s.nodes) n.style.display = hit ? "" : "none";
      if (hit) {
        any = true;
        count++;
      }
    }
    if (g.heading) g.heading.style.display = any ? "" : "none";
  }
  shown.value = words.length ? count : -1;
}

watch(query, apply);
watch(
  () => route.path,
  () => {
    query.value = "";
    nextTick(apply);
  },
);
onBeforeUnmount(() => {
  query.value = "";
  apply();
});

// biome-ignore lint/correctness/noUnusedVariables: used in the template
function askHelp() {
  const text = query.value.trim().slice(0, 1000);
  const help = (window as unknown as { CasamaHelp?: { open: (o: { text: string }) => void } })
    .CasamaHelp;
  if (help) help.open({ text });
  else window.location.href = `https://casama.ai/help?q=${encodeURIComponent(text)}`;
}
</script>

<template>
  <div v-if="isFaq" class="faq-filter" role="search">
    <label for="faq-filter-input" class="visually-hidden">Search the questions</label>
    <input
      id="faq-filter-input"
      v-model="query"
      type="search"
      placeholder="Search the questions"
      autocomplete="off"
      spellcheck="false"
      maxlength="200"
    />
    <p class="visually-hidden" aria-live="polite">
      {{ shown < 0 ? "" : shown === 1 ? "1 matching question" : `${shown} matching questions` }}
    </p>
    <p v-if="shown === 0" class="faq-filter-none">No matching questions.</p>
    <button v-if="query.trim()" type="button" class="faq-filter-ask" @click="askHelp">
      Ask Casama Help about “{{ query.trim().length > 80 ? `${query.trim().slice(0, 80)}…` : query.trim() }}”
    </button>
  </div>
</template>
