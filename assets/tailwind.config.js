// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const colors = require("tailwindcss/colors");
const path = require("path");
const fs = require("fs");

const gray = {
  50: "#f8f9fc",
  100: "#f1f2f9",
  200: "#e1e2ef",
  300: "#cbcee1",
  400: "#9497b8",
  500: "#65688b",
  600: "#484b6a",
  700: "#343756",
  800: "#1d1e3a",
  900: "#100f29",
  950: "#050217",
};

module.exports = {
  content: [
    "./js/**/*.js",
    "./js/**/*.ts",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
  ],
  theme: {
    extend: {
      colors: {
        gray,
        green: colors.emerald,
        purple: colors.indigo,
        yellow: colors.amber,
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),
    // Embeds Tabler Icons (https://tabler.io/icons) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      const iconsDir = path.join(__dirname, "../deps/tabler_icons/icons");
      const values = {};
      const icons = [
        ["", "/outline"],
        ["-filled", "/filled"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          const name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          tabler: ({ name, fullPath }) => {
            const content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "")
              .replace(/width="[^"]*"/, "")
              .replace(/height="[^"]*"/, "");

            return {
              [`--tabler-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--tabler-${name})`,
              mask: `var(--tabler-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.6"),
              height: theme("spacing.6"),
            };
          },
        },
        { values }
      );
    }),
  ],
};
