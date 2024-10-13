import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket, type ViewHook } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import { VidstackPlayer, VidstackPlayerLayout } from "vidstack/global/player";
import { isHLSProvider } from "vidstack";
import HLS from "@algora/hls.js";

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
  document
    .querySelectorAll(selector)
    .forEach((el) => liveSocket.execJS(el, el.getAttribute(attr)));
};

const Hooks = {
  Flash: {
    mounted() {
      let hide = () =>
        liveSocket.execJS(this.el, this.el.getAttribute("phx-click"));
      this.timer = setTimeout(() => hide(), 8000);
      this.el.addEventListener("phx:hide-start", () =>
        clearTimeout(this.timer)
      );
      this.el.addEventListener("mouseover", () => {
        clearTimeout(this.timer);
        this.timer = setTimeout(() => hide(), 8000);
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
    destroyed() {
      this.reset();
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

      const isMobile =
        /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
          navigator.userAgent
        );

      let promptShown = false;

      const showPrompt = () => {
        if (!promptShown) {
          installPrompt.classList.remove("hidden");
          if (isMobile) {
            instructionsMobile.classList.remove("hidden");
            installButton.classList.add("hidden");
          } else {
            installButton.classList.remove("hidden");
            instructionsMobile.classList.add("hidden");
          }
          promptShown = true;
        }
      };

      window.addEventListener(
        "scroll",
        () => {
          const scrollPos =
            document.documentElement.scrollTop || document.body.scrollTop;

          if (scrollPos > Math.min(500, scrollHeight / 2) && deferredPrompt) {
            showPrompt();
          }
        },
        { passive: true }
      );

      window.addEventListener("beforeinstallprompt", (e) => {
        e.preventDefault();
        deferredPrompt = e;
      });

      installButton.addEventListener("click", async () => {
        if (deferredPrompt) {
          deferredPrompt.prompt();
          deferredPrompt = null;
        }
        installPrompt.classList.add("hidden");
        localStorage.setItem("pwaPromptShown", "true");
      });

      closeButton.addEventListener("click", () => {
        installPrompt.classList.add("hidden");
        localStorage.setItem("pwaPromptShown", "true");
      });

      window.addEventListener("appinstalled", () => {
        installPrompt.classList.add("hidden");
        deferredPrompt = null;
        localStorage.setItem("pwaPromptShown", "true");
      });
    },
  },
  NavBar: {
    mounted() {
      const offset = 16;
      this.isOpaque = false;

      const onScroll = () => {
        if (!this.isOpaque && window.scrollY > offset) {
          this.isOpaque = true;
          this.el.classList.add("bg-gray-950");
          this.el.classList.remove("bg-transparent");
        } else if (this.isOpaque && window.scrollY <= offset) {
          this.isOpaque = false;
          this.el.classList.add("bg-transparent");
          this.el.classList.remove("bg-gray-950");
        }
      };

      window.addEventListener("scroll", onScroll, { passive: true });
    },
  },
  MobileMenu: {
    mounted() {
      this.menuOpen = false;
      this.backdrop = this.el.querySelector("#menu-backdrop");
      this.menuContainer = this.el.querySelector("#menu-container");
      this.closeButton = this.el.querySelector("#close-button");
      this.closeMenuButton = this.el.querySelector("#close-menu-button");
      this.openButton = this.el.querySelector("#open-button");
      this.openMenuButton = this.el.querySelector("#open-menu-button");

      this.closeMenuButton.addEventListener("click", () => this.toggleMenu());
      this.openMenuButton.addEventListener("click", () => this.toggleMenu());
    },

    toggleMenu() {
      this.menuOpen = !this.menuOpen;

      if (this.menuOpen) {
        this.backdrop.classList.remove("opacity-0");
        this.backdrop.classList.add("opacity-100");

        this.menuContainer.classList.remove("-translate-x-full");
        this.menuContainer.classList.add("translate-x-0");

        this.closeButton.classList.remove("opacity-0");
        this.closeButton.classList.add("opacity-100");

        this.openButton.classList.remove("opacity-100");
        this.openButton.classList.add("opacity-0");
      } else {
        this.backdrop.classList.remove("opacity-100");
        this.backdrop.classList.add("opacity-0");

        this.menuContainer.classList.remove("translate-x-0");
        this.menuContainer.classList.add("-translate-x-full");

        this.closeButton.classList.remove("opacity-100");
        this.closeButton.classList.add("opacity-0");

        this.openButton.classList.remove("opacity-0");
        this.openButton.classList.add("opacity-100");
      }
    },
  },
  CopyToClipboard: {
    value() {
      return this.el.dataset.value;
    },
    notice() {
      return this.el.dataset.notice;
    },
    mounted() {
      this.el.addEventListener("click", () => {
        navigator.clipboard.writeText(this.value()).then(() => {
          this.pushEvent("copied_to_clipboard", { notice: this.notice() });
        });
      });
    },
  },
} satisfies Record<string, Partial<ViewHook> & Record<string, unknown>>;

// Accessible focus handling
let Focus = {
  focusMain() {
    let target =
      document.querySelector<HTMLElement>("main h1") ||
      document.querySelector<HTMLElement>("main");
    if (target) {
      let origTabIndex = target.tabIndex;
      target.tabIndex = -1;
      target.focus();
      target.tabIndex = origTabIndex;
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  isFocusable(el) {
    if (
      el.tabIndex > 0 ||
      (el.tabIndex === 0 && el.getAttribute("tabIndex") !== null)
    ) {
      return true;
    }
    if (el.disabled) {
      return false;
    }

    switch (el.nodeName) {
      case "A":
        return !!el.href && el.rel !== "ignore";
      case "INPUT":
        return el.type != "hidden" && el.type !== "file";
      case "BUTTON":
      case "SELECT":
      case "TEXTAREA":
        return true;
      default:
        return false;
    }
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  attemptFocus(el) {
    if (!el) {
      return;
    }
    if (!this.isFocusable(el)) {
      return false;
    }
    try {
      el.focus();
    } catch (e) {}

    return document.activeElement === el;
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusFirstDescendant(el) {
    for (let i = 0; i < el.childNodes.length; i++) {
      let child = el.childNodes[i];
      if (this.attemptFocus(child) || this.focusFirstDescendant(child)) {
        return true;
      }
    }
    return false;
  },
  // Subject to the W3C Software License at https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
  focusLastDescendant(element) {
    for (let i = element.childNodes.length - 1; i >= 0; i--) {
      let child = element.childNodes[i];
      if (this.attemptFocus(child) || this.focusLastDescendant(child)) {
        return true;
      }
    }
    return false;
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")!
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
  dom: {
    onNodeAdded(node) {
      if (node instanceof HTMLElement && node.autofocus) {
        node.focus();
      }
      return node;
    },
  },
});

let routeUpdated = () => {
  // TODO: uncomment
  // Focus.focusMain();
};

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: "rgba(79, 70, 229, 1)" },
  shadowColor: "rgba(0, 0, 0, .3)",
});
window.addEventListener("phx:page-loading-start", (info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// Accessible routing
window.addEventListener("phx:page-loading-stop", routeUpdated);

window.addEventListener("phx:js-exec", ({ detail }) => {
  document.querySelectorAll(detail.to).forEach((el) => {
    liveSocket.execJS(el, el.getAttribute(detail.attr));
  });
});

window.addEventListener("js:exec", (e) =>
  e.target[e.detail.call](...e.detail.args)
);
window.addEventListener("js:focus", (e) => {
  let parent = document.querySelector(e.detail.parent);
  if (parent && isVisible(parent)) {
    (e.target as any).focus();
  }
});
window.addEventListener("js:focus-closest", (e) => {
  let el = e.target;
  let sibling = el.nextElementSibling;
  while (sibling) {
    if (isVisible(sibling) && Focus.attemptFocus(sibling)) {
      return;
    }
    sibling = sibling.nextElementSibling;
  }
  sibling = el.previousElementSibling;
  while (sibling) {
    if (isVisible(sibling) && Focus.attemptFocus(sibling)) {
      return;
    }
    sibling = sibling.previousElementSibling;
  }
  Focus.attemptFocus((el as any).parent) || Focus.focusMain();
});
window.addEventListener("phx:remove-el", (e) =>
  document.getElementById(e.detail.id)?.remove()
);

// connect if there are any LiveViews on the page
liveSocket.getSocket().onOpen(() => execJS("#connection-status", "js-hide"));
liveSocket.getSocket().onError(() => execJS("#connection-status", "js-show"));
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
