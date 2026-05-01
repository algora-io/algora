```elixir
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket, type ViewHook } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import { getHooks } from "live_svelte";
import * as Components from "../svelte/**/*.svelte";
import posthog from "posthog-js";
import "emoji-picker-element";

// TODO: add eslint & biome
// TODO: enable strict mode
// TODO: eliminate anys

interface PhxEvent extends Event {
  target: Element;
  detail: Record<string, any>;
}

type PhxEventKey = `js:${string}` | `phx:${string}`;

declare global {
  interface Window {
    liveSocket: LiveSocket;
    addEventListener<K extends keyof WindowEventMap | PhxEventKey>(
      type: K,
      listener: (
        this: Window,
        ev: K extends keyof WindowEventMap ? WindowEventMap[K] : PhxEvent
      ) => any,
      options?: boolean | AddEventListenerOptions | undefined
    ): void;
  }
}

let isVisible = (el) =>
  !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0);

let execJS = (selector, attr) => {
  document.querySelectorAll(selector).forEach((el) => liveSocket.execJS(el, el.getAttribute(attr)));
};

const Hooks = {
  Capture: {
    mounted() {
      const token = this.el.getAttribute("data-token");
      if (!token) return;

      posthog.init(token, { api_host: this.el.getAttribute("data-host") });

      const email = this.el.getAttribute("data-email");
      if (!email) return;

      posthog.identify(email, { email });
    },
  },
  ScrollToEnd: {
    mounted() {
      requestAnimationFrame(() => {
        this.el.scrollLeft = this.el.scrollWidth;
      });
    },
    updated() {
      requestAnimationFrame(() => {
        this.el.scrollLeft = this.el.scrollWidth;
      });
    },
  },
  Flash: {
    mounted() {
      let hide = () =>
        liveSocket.execJS(this.el, this.el.getAttribute("phx-click"));
      this.timer = setTimeout(() => hide(), 5000);
      this.el.addEventListener("phx:hide-start", () =>
        clearTimeout(this.timer)
      );
      this.el.addEventListener("mouseover", () => {
        clearTimeout(this.timer);
        this.timer = setTimeout(() => hide(), 5000);
      });
    },
    destroyed() {
      clearTimeout(this.timer);
    },
  },
  Menu: {
    getAttr(name) {
      let val = this.el.getAttribute(name);
      if (val === null) {
        throw new Error(`no ${name} attribute configured for menu`);
      }
      return val;
    },
    reset() {
      this.enabled = false;
      this.activeClass = this.getAttr("data-active-class");
      this.deactivate(this.menuItems());
      this.activeItem = null;
      window.removeEventListener("keydown", this.handleKeyDown);
    },
    mounted() {
      this.menuItemsContainer = document.querySelector(
        `[aria-labelledby="${this.el.id}"]`
      );
      this.reset();
      this.handleKeyDown = (e) => this.onKeyDown(e);
      this.el.addEventListener("keydown", (e) => {
        if (
          (e.key === "Enter" || e.key === " ") &&
          e.currentTarget.isSameNode(this.el)
        ) {
          this.enabled = true;
        }
      });
      this.el.addEventListener("click", (e) => {
        if (!e.currentTarget.isSameNode(this.el)) {
          return;
        }

        window.addEventListener("keydown", this.handleKeyDown);
        // disable if button clicked and click was not a keyboard event
        if (this.enabled) {
          window.requestAnimationFrame(() => this.activate(0));
        }
      });
      this.menuItemsContainer.addEventListener("phx:hide-start", () =>
        this.reset()
      );
    },
    activate(index, fallbackIndex) {
      let menuItems = this.menuItems();
      this.activeItem = menuItems[index] || menuItems[fallbackIndex];
      this.activeItem.classList.add(this.activeClass);
      this.activeItem.focus();
    },
    deactivate(items) {
      items.forEach((item) => item.classList.remove(this.activeClass));
    },
    menuItems() {
      return Array.from(
        this.menuItemsContainer.querySelectorAll("[role=menuitem]")
      );
    },
    onKeyDown(e) {
      if (e.key === "Escape") {
        document.body.click();
        this.el.focus();
        this.reset();
      } else if (e.key === "Enter" && !this.activeItem) {
        this.activate(0);
      } else if (e.key === "Enter") {
        this.activeItem.click();
      }
      if (e.key === "ArrowDown") {
        e.preventDefault();
        let menuItems = this.menuItems();
        this.deactivate(menuItems);
        this.activate(menuItems.indexOf(this.activeItem) + 1, 0);
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        let menuItems = this.menuItems();
        this.deactivate(menuItems);
        this.activate(
          menuItems.indexOf(this.activeItem) - 1,
          menuItems.length - 1
        );
      } else if (e.key === "Tab") {
        e.preventDefault();
      }
    },
  },
  PWAInstallPrompt: {
    mounted() {
      let deferredPrompt: any;
      const installPrompt = document.getElementById("pwa-install-prompt");
      const installButton = document.getElementById("pwa-install-button");
      const closeButton = document.getElementById("pwa-close-button");
      const instructionsMobile = document.getElementById(
        "pwa-instructions-mobile"
      );
      if (
        !installPrompt ||
        !installButton ||
        !closeButton ||
        !instructionsMobile ||
        localStorage.getItem("pwaPromptShown")
      ) {
        return;
      }

      const scrollHeight =
        (document.documentElement.scrollHeight || document.body.scrollHeight) - 
        document.documentElement.clientHeight;

      const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
        navigator.userAgent
      );

      this.deferredPrompt = new window.Prompt(
        "We noticed that you didn't enable push notifications, can we add it to your device?",
        () => {
          deferredPrompt.dismiss();
        }
      );
    },
  },
};
```