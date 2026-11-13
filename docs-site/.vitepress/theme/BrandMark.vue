<script setup lang="ts">
// The animated Casama mascot, the same Lottie as casama.ai and the gallery (public/brand/, copied by
// scripts/web-brand-lottie.py). public/brand/casama-mark.js loads the player and plays it on screen only.
import { onBeforeUnmount, onMounted, ref } from "vue";

const box = ref<HTMLElement | null>(null);
let loading: Promise<void> | null = null;

function loadMark(): Promise<void> {
  const w = window as unknown as { casamaMark?: (el: HTMLElement) => void };
  if (w.casamaMark) return Promise.resolve();
  loading ??= new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = "/brand/casama-mark.js";
    s.onload = () => resolve();
    s.onerror = reject;
    document.head.appendChild(s);
  });
  return loading;
}

onMounted(() => {
  loadMark().then(() => {
    const w = window as unknown as { casamaMark?: (el: HTMLElement) => void };
    if (box.value) w.casamaMark?.(box.value);
  });
});

onBeforeUnmount(() => {
  const el = box.value as (HTMLElement & { casamaAnim?: { destroy(): void } }) | null;
  el?.casamaAnim?.destroy();
});
</script>

<template>
  <span ref="box" class="casama-mark" data-casama-mark aria-hidden="true" />
</template>
