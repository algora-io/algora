import puppeteer from "puppeteer";

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    type: "png",
    path: null,
    width: "800",
    height: "600",
    scaleFactor: "1",
    x: null,
    y: null,
    clipWidth: null,
    clipHeight: null,
  };

  for (let i = 0; i < args.length; i++) {
    let arg = args[i];
    let value = null;

    [arg, value] = arg.split("=");

    switch (arg) {
      case "-t":
      case "--type":
        options.type = value;
        break;
      case "-p":
      case "--path":
        options.path = value;
        break;
      case "-w":
      case "--width":
        options.width = value;
        break;
      case "-h":
      case "--height":
        options.height = value;
        break;
      case "-s":
      case "--scale-factor":
        options.scaleFactor = value;
        break;
      case "-x":
      case "--x":
        options.x = value;
        break;
      case "-y":
      case "--y":
        options.y = value;
        break;
      case "--clip-width":
        options.clipWidth = value;
        break;
      case "--clip-height":
        options.clipHeight = value;
        break;
    }
  }

  // URL is the first non-option argument
  options.url = args.find((arg) => !arg.startsWith("-"));
  return options;
}

function _validateInteger(value) {
  const parsed = parseInt(value);
  if (value && !parsed) {
    process.stderr.write("Number values must be valid integer");
    return null;
  }
  return parsed;
}

(async () => {
  const options = parseArgs();
  let screenshotOptions = {};
  let viewportOptions = {};

  if (!options.url) {
    process.stderr.write("URL required");
    return;
  }

  viewportOptions.width = _validateInteger(options.width) || 800;
  viewportOptions.height = _validateInteger(options.height) || 600;
  viewportOptions.deviceScaleFactor =
    _validateInteger(options.scaleFactor) || 1;
  screenshotOptions.type = ["jpeg", "png"].includes(options.type)
    ? options.type
    : "png";
  screenshotOptions.path = options.path || `./image.${screenshotOptions.type}`;
  const clipParams = {
    x: options.x,
    y: options.y,
    width: options.clipWidth,
    height: options.clipHeight,
  };
  const hasClipParams = Object.values(clipParams).every((val) => val !== null);

  if (hasClipParams) {
    screenshotOptions.clip = {};
    for (const [key, value] of Object.entries(clipParams)) {
      screenshotOptions.clip[key] = _validateInteger(value);
    }
  }

  const browser = await puppeteer.launch({
    devtools: false,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--single-process"],
    ignoreHTTPSErrors: true,
  });

  try {
    const page = await browser.newPage();
    await page.setViewport(viewportOptions);
    await page.goto(options.url, { waitUntil: "networkidle2" });
    await page.focus("body");
    await page.screenshot(screenshotOptions);
    await page.close();
  } catch (e) {
    process.stderr.write(e.message);
  } finally {
    await browser.close();
  }
})();
