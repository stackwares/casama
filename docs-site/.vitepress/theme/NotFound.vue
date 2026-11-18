<script setup lang="ts">
// The docs' 404: the painted lost scene with the real mascot on it, as on casama.ai, casama.link and the gallery.
import { withBase } from "vitepress";
</script>

<template>
  <div class="casama-lost">
    <div class="casama-lost-art" aria-hidden="true">
      <img :src="withBase('/casama-brand-animated.svg')" alt="" width="120" height="120" />
    </div>
    <h1>That page isn't in the docs.</h1>
    <p>It may have moved, or the link may be wrong. Try the search, or start from one of these.</p>
    <ul>
      <li><a :href="withBase('/')">Docs home</a></li>
      <li><a :href="withBase('/quick-start')">Quick start</a></li>
      <li><a :href="withBase('/self-hosting/')">Self-hosting</a></li>
      <li><a href="https://casama.ai">casama.ai</a></li>
    </ul>
  </div>
</template>
