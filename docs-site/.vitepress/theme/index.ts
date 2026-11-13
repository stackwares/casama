import DefaultTheme from "vitepress/theme";
import { h } from "vue";
import BrandMark from "./BrandMark.vue";
import "./custom.css";

// The Casama mark is the animated mascot (BrandMark), not a picture: in the nav bar and on the home hero.
export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      "nav-bar-title-before": () => h(BrandMark, { class: "casama-mark-nav" }),
      "home-hero-image": () => h(BrandMark, { class: "image-src casama-mark-hero" }),
    });
  },
};
