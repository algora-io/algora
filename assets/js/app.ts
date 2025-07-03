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
  document
    .querySelectorAll(selector)
    .forEach((el) => liveSocket.execJS(el, el.getAttribute(attr)));
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
  CopyToClipboard: {
    value() {
      return this.el.dataset.value;
    },

    mounted() {
      this.el.addEventListener("click", () => {
        navigator.clipboard.writeText(this.value());
      });
    },
  },
  ScrollToBottom: {
    mounted() {
      this.el.classList.add("js-scroll");
      this.el.scrollTop = this.el.scrollHeight;
      this.handleEvent("scroll-to-bottom", () => {
        this.el.scrollTop = this.el.scrollHeight;
      });
    },
    updated() {
      this.el.scrollTop = this.el.scrollHeight;
    },
  },
  AnimatedTooltip: {
    mounted() {
      const springConfig = { stiffness: 100, damping: 5 };
      let hoveredTooltip: HTMLElement | null = null;
      let currentX = 0;

      const handleMouseEnter = (event: MouseEvent) => {
        const target = event.currentTarget as HTMLElement;
        const tooltip = target.querySelector("[data-tooltip]") as HTMLElement;
        if (tooltip) {
          hoveredTooltip = tooltip;
          tooltip.classList.remove("hidden");
          tooltip.style.opacity = "1";
          tooltip.style.transform = "translateY(0) scale(1)";
        }
      };

      const handleMouseLeave = (event: MouseEvent) => {
        const target = event.currentTarget as HTMLElement;
        const tooltip = target.querySelector("[data-tooltip]") as HTMLElement;
        if (tooltip) {
          tooltip.classList.add("hidden");
          tooltip.style.opacity = "0";
          tooltip.style.transform = "translateY(20px) scale(0.6)";
          hoveredTooltip = null;
        }
      };

      const handleMouseMove = (event: MouseEvent) => {
        if (!hoveredTooltip) return;

        const target = event.currentTarget as HTMLElement;
        const halfWidth = target.offsetWidth / 2;
        currentX = event.offsetX - halfWidth;

        // Calculate rotation and translation based on mouse position
        const rotateRange = [-45, 45];
        const translateRange = [-50, 50];
        const progress = (currentX + 100) / 200; // Normalize to 0-1

        const rotation =
          rotateRange[0] + (rotateRange[1] - rotateRange[0]) * progress;
        const translation =
          translateRange[0] +
          (translateRange[1] - translateRange[0]) * progress;

        hoveredTooltip.style.transform = `translateX(${translation}px) rotate(${rotation}deg)`;
      };

      // Set up event listeners for all tooltip items
      this.el.querySelectorAll("[data-tooltip-trigger]").forEach((trigger) => {
        trigger.addEventListener("mouseenter", handleMouseEnter);
        trigger.addEventListener("mouseleave", handleMouseLeave);
        trigger.addEventListener("mousemove", handleMouseMove);
      });
    },

    destroyed() {
      // Clean up event listeners if needed
      this.el.querySelectorAll("[data-tooltip-trigger]").forEach((trigger) => {
        trigger.removeEventListener("mouseenter", this.handleMouseEnter);
        trigger.removeEventListener("mouseleave", this.handleMouseLeave);
        trigger.removeEventListener("mousemove", this.handleMouseMove);
      });
    },
  },
  DeriveHandle: {
    mounted() {
      const handleInput = document.querySelector("[data-handle-target]");
      let shouldDerive = true;

      // Listen for manual edits to the handle field
      handleInput?.addEventListener("input", () => {
        shouldDerive = false;
      });

      // Listen for changes to the name field
      this.el.addEventListener("input", (e) => {
        if (!shouldDerive) return;

        const handle = e.target.value
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "-")
          .replace(/^-+|-+$/g, "");

        if (handleInput) {
          (handleInput as HTMLInputElement).value = handle;
          // Trigger the blur event to update the server state
          handleInput.dispatchEvent(new Event("blur"));
        }
      });
    },
  },
  ClearInput: {
    mounted() {
      this.handleEvent("clear-input", ({ selector }) => {
        document.querySelector(selector).value = "";
      });
    },
  },
  DeriveDomain: {
    mounted() {
      const domainInput = (this.el.closest("form") || document).querySelector(
        "[data-domain-source]"
      );
      let shouldDerive = true;

      // Listen for manual edits to the domain field
      domainInput?.addEventListener("input", () => {
        shouldDerive = false;
      });

      // Listen for changes to the email field
      this.el.addEventListener("input", (e) => {
        if (!shouldDerive) return;

        const email = (e.target as HTMLInputElement).value;
        const domain = email.split("@")[1] || "";

        if (domainInput) {
          (domainInput as HTMLInputElement).value = domain;
          // Trigger the change event to update the server state
          domainInput.dispatchEvent(new Event("change"));
        }
      });
    },
  },

  EmojiPicker: {
    mounted() {
      const button = this.el;
      const container = document.getElementById("emoji-picker-container");
      const input = document.getElementById(
        "message-input"
      ) as HTMLInputElement;
      const picker = container?.querySelector("emoji-picker");
      let isVisible = false;

      // Toggle picker visibility
      button.addEventListener("click", () => {
        isVisible = !isVisible;
        if (isVisible) {
          container?.classList.remove("hidden");
        } else {
          container?.classList.add("hidden");
        }
      });

      // Handle emoji selection
      picker?.addEventListener("emoji-click", (event: any) => {
        const emoji = event.detail.unicode;
        const cursorPosition = input.selectionStart || 0;

        // Insert emoji at cursor position
        const currentValue = input.value;
        input.value =
          currentValue.slice(0, cursorPosition) +
          emoji +
          currentValue.slice(cursorPosition);

        // Move cursor after emoji
        input.setSelectionRange(
          cursorPosition + emoji.length,
          cursorPosition + emoji.length
        );

        // Hide picker after selection
        container?.classList.add("hidden");
        isVisible = false;

        // Focus back on input
        input.focus();
      });

      // Close picker when clicking outside
      document.addEventListener("click", (event) => {
        if (
          !container?.contains(event.target as Node) &&
          !button.contains(event.target as Node)
        ) {
          container?.classList.add("hidden");
          isVisible = false;
        }
      });
    },
  },
  InfiniteScroll: {
    mounted() {
      this.setupObserver();
    },

    updated() {
      // Disconnect previous observer before creating a new one
      if (this.observer) {
        this.observer.disconnect();
      }
      this.setupObserver();
    },

    setupObserver() {
      this.observer = new IntersectionObserver(
        (entries) => {
          const entry = entries[0];
          if (entry.isIntersecting) {
            this.pushEvent("load_more");
          }
        },
        {
          root: null, // viewport
          rootMargin: "0px 0px 400px 0px", // trigger when indicator is 400px from viewport
          threshold: 0.1,
        }
      );

      // Look for the indicator inside this.el rather than document-wide
      const loadMoreIndicator = this.el.querySelector(
        "[data-load-more-indicator]"
      );
      if (loadMoreIndicator) {
        this.observer.observe(loadMoreIndicator);
      }
    },

    destroyed() {
      if (this.observer) {
        this.observer.disconnect();
      }
    },
  },
  AvatarImage: {
    mounted() {
      this.handleError = () => {
        this.errored = true;
        this.el.style.display = "none";
      };
      this.el.addEventListener("error", this.handleError);
    },
    updated() {
      if (this.errored) {
        this.el.style.display = "none";
      }
    },
    destroyed() {
      this.el.removeEventListener("error", this.handleError);
    },
  },
  LocalStateStore: {
    getStorage() {
      const storage = this.el.getAttribute("data-storage");
      return storage === "localStorage" ? localStorage : sessionStorage;
    },

    mounted() {
      this.storage = this.getStorage();
      this.handleEvent("store", (obj) => this.store(obj));
      this.handleEvent("clear", (obj) => this.clear(obj));
      this.handleEvent("restore", (obj) => this.restore(obj));
    },

    store(obj) {
      this.storage.setItem(obj.key, obj.data);
    },

    restore(obj) {
      const data = this.storage.getItem(obj.key);
      this.pushEvent(obj.event, data);
    },

    clear(obj) {
      this.storage.removeItem(obj.key);
    },
  },
  CtrlEnterSubmit: {
    mounted() {
      this.el.addEventListener("keydown", (e) => {
        if (e.key == "Enter" && e.ctrlKey) {
          this.el.form.dispatchEvent(
            new Event("submit", { bubbles: true, cancelable: true })
          );
        }
      });
    },
  },
  EnterSubmit: {
    mounted() {
      this.el.addEventListener("keydown", (e) => {
        if (e.key == "Enter") {
          this.el.form.dispatchEvent(
            new Event("submit", { bubbles: true, cancelable: true })
          );
        }
      });
    },
  },
  ExpandableText: {
    mounted() {
      const button = document.querySelector(`#${this.el.dataset.expandId}`);

      // Check if content is truncated
      const isTruncated = this.el.scrollHeight > this.el.clientHeight;

      if (isTruncated && button) {
        button.classList.remove("hidden");
      }
    },
  },

  ExpandableTextButton: {
    mounted() {
      this.el.addEventListener("click", () => {
        const content = document.querySelector<HTMLElement>(
          `#${this.el.dataset.contentId}`
        );
        if (!content) return;

        const className = content.dataset.class;

        if (content.classList.contains(className)) {
          // Expand
          content.classList.remove(className);
          this.el.classList.add("hidden");
        } else {
          // Collapse
          content.classList.add(className);
          this.el.classList.remove("hidden");
        }
      });
    },
  },
  ScrollToTop: {
    mounted() {
      this.el.addEventListener("click", () => {
        window.scrollTo({ top: 0, behavior: "smooth" });
      });
    },
  },
  CompensationStrengthIndicator: {
    mounted() {
      const input = this.el.querySelector("input[type='text']");
      const strengthBar = this.el.querySelector("[data-strength-bar]");
      const strengthLabel = this.el.querySelector("[data-strength-label]");
      
      if (!input || !strengthBar || !strengthLabel) return;
      
      const updateStrength = () => {
        const value = input.value.replace(/[^0-9]/g, "");
        const amount = parseInt(value) || 0;
        
        let strength = 0;
        let label = "";
        let color = "bg-gray-200";
        
        if (amount >= 500000) {
          strength = 100;
          label = "Big D Energy 💪";
          color = "bg-purple-500";
        } else if (amount >= 400000) {
          strength = 90;
          label = "Baller Status 🔥";
          color = "bg-indigo-500";
        } else if (amount >= 300000) {
          strength = 80;
          label = "High Roller 🎯";
          color = "bg-blue-500";
        } else if (amount >= 200000) {
          strength = 70;
          label = "Big League 🚀";
          color = "bg-green-500";
        } else if (amount >= 150000) {
          strength = 60;
          label = "Major League 💰";
          color = "bg-yellow-500";
        } else if (amount >= 100000) {
          strength = 50;
          label = "Six Figures 📈";
          color = "bg-orange-500";
        } else if (amount >= 75000) {
          strength = 40;
          label = "Solid Pay 💼";
          color = "bg-red-400";
        } else if (amount >= 50000) {
          strength = 30;
          label = "Decent 👍";
          color = "bg-pink-400";
        } else if (amount >= 25000) {
          strength = 20;
          label = "Getting There 🌱";
          color = "bg-cyan-400";
        } else if (amount > 0) {
          strength = 10;
          label = "Starting Out 🌟";
          color = "bg-gray-400";
        }
        
        // Update strength bar
        strengthBar.style.width = `${strength}%`;
        strengthBar.className = `h-2 rounded-full transition-all duration-300 ${color}`;
        
        // Show/hide the entire indicator section
        const indicatorSection = strengthBar.closest('.mt-2');
        if (amount > 0) {
          indicatorSection.style.display = 'block';
        } else {
          indicatorSection.style.display = 'none';
        }
        
        // Update label
        strengthLabel.textContent = label;
        strengthLabel.className = `text-sm font-medium transition-colors duration-300 ${
          strength >= 80 ? "text-purple-600" : 
          strength >= 60 ? "text-blue-600" : 
          strength >= 40 ? "text-green-600" : 
          strength >= 20 ? "text-yellow-600" : 
          "text-gray-600"
        }`;
      };
      
      input.addEventListener("input", updateStrength);
      input.addEventListener("keyup", updateStrength);
      
      // Initial update
      updateStrength();
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
  ...{ disconnectedTimeout: 3000 },
  hooks: { ...Hooks, ...getHooks(Components) },
  params: {
    _csrf_token: csrfToken,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  },
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

let topBarScheduled = undefined;

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: "rgba(5, 150, 105, 1)" },
  shadowColor: "rgba(0, 0, 0, .3)",
});
window.addEventListener("phx:page-loading-start", (info) => {
  if (topBarScheduled || window.location.search.includes("screenshot")) {
    return;
  }
  topBarScheduled = setTimeout(() => topbar.show(), 500);
});
window.addEventListener("phx:page-loading-stop", (info) => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

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

// Allows to execute JS commands from the server
window.addEventListener("phx:js-exec", ({ detail }) => {
  document.querySelectorAll(detail.to).forEach((el) => {
    liveSocket.execJS(el, el.getAttribute(detail.attr));
  });
});

window.addEventListener("phx:open_popup", (e: CustomEvent) => {
  const url = e.detail.url;
  if (!url) return;

  const width = e.detail.width || 600;
  const height = e.detail.height || 600;
  const left = e.detail.left || window.screen.width / 2 - width / 2;
  const top = e.detail.top || window.screen.height / 2 - height / 2;

  const newWindow = window.open(
    url,
    "oauth",
    `width=${width},height=${height},left=${left},top=${top},toolbar=0,scrollbars=1,status=1`
  );

  if (window.focus && newWindow) {
    newWindow.focus();
  }
});

// Add event listener for storing session values
window.addEventListener("phx:store-session", (event) => {
  const token = document
    .querySelector('meta[name="csrf-token"]')
    .getAttribute("content");

  fetch("/api/store_session", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": token,
    },
    body: JSON.stringify(event.detail),
  });
});

export default Hooks;
