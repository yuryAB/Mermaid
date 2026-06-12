#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");

const apiBase = "https://freesound.org/apiv2";
const projectRoot = path.resolve(__dirname, "..");

const defaultFields = [
  "id",
  "name",
  "username",
  "license",
  "duration",
  "previews",
  "url",
  "tags",
  "avg_rating",
  "num_downloads",
].join(",");

const previewPreference = [
  "preview-hq-mp3",
  "preview-hq-ogg",
  "preview-lq-mp3",
  "preview-lq-ogg",
];

const usage = () => {
  console.log(`Freesound SFX helper for Mermaid

Setup:
  1. Create a Freesound API key at https://freesound.org/apiv2/apply
  2. Put it in .env.local as FREESOUND_API_KEY=...

Commands:
  node Tools/freesound.cjs search "underwater bubble pop" [--page-size 8]
  node Tools/freesound.cjs pick "soft water swish" --index 0 --out Ester/Audio/water-swish
  node Tools/freesound.cjs download 123456 --out Ester/Audio/shell-click
  node Tools/freesound.cjs batch Ester/Audio/freesound-plan.json [--dry-run]
  node Tools/freesound.cjs verify Ester/Audio/freesound-plan.json [--report Ester/Audio/AUDIO_ASSET_REPORT.md]

Useful options:
  --duration-min 0.04
  --duration-max 1.2
  --license cc0 | attribution | cc0-or-attribution | any
  --sort score | rating_desc | downloads_desc | duration_asc
  --preview preview-hq-mp3
  --json

Output:
  Audio is saved to Ester/Audio/ by default.
  Attribution and license metadata is saved as a .freesound.json sidecar.
`);
};

const readEnvFile = (filePath) => {
  if (!fs.existsSync(filePath)) {
    return;
  }

  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      continue;
    }

    const separator = trimmed.indexOf("=");
    if (separator === -1) {
      continue;
    }

    const key = trimmed.slice(0, separator).trim();
    let value = trimmed.slice(separator + 1).trim();
    value = value.replace(/^['"]|['"]$/g, "");

    if (key && process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
};

const loadEnv = () => {
  readEnvFile(path.join(projectRoot, ".env.local"));
  readEnvFile(path.join(projectRoot, ".env"));
};

const parseArgs = (args) => {
  const positional = [];
  const options = {};

  for (let index = 0; index < args.length; index += 1) {
    const value = args[index];
    if (!value.startsWith("--")) {
      positional.push(value);
      continue;
    }

    const key = value.slice(2);
    const next = args[index + 1];
    if (!next || next.startsWith("--")) {
      options[key] = true;
      continue;
    }

    options[key] = next;
    index += 1;
  }

  return { positional, options };
};

const requireToken = () => {
  const token = process.env.FREESOUND_API_KEY || process.env.FREESOUND_TOKEN;
  if (!token) {
    throw new Error("Missing FREESOUND_API_KEY. Add it to .env.local. See .env.example.");
  }

  return token;
};

const authHeaders = () => ({
  Authorization: `Token ${requireToken()}`,
  "User-Agent": "mermaid-game-sfx/1.0",
});

const requestJson = async (url) => {
  const response = await fetch(url, { headers: authHeaders() });
  const text = await response.text();

  if (!response.ok) {
    throw new Error(`Freesound API error ${response.status}: ${text}`);
  }

  return JSON.parse(text);
};

const licenseFilterFor = (license) => {
  switch (license) {
    case "cc0":
      return 'license:"Creative Commons 0"';
    case "attribution":
      return 'license:"Attribution"';
    case "cc0-or-attribution":
      return '(license:"Creative Commons 0" OR license:"Attribution")';
    case "any":
    case undefined:
      return null;
    default:
      throw new Error(
        `Unsupported --license "${license}". Use cc0, attribution, cc0-or-attribution, or any.`,
      );
  }
};

const buildFilter = (options, defaults = {}) => {
  const durationMin = options["duration-min"] ?? defaults.durationMin;
  const durationMax = options["duration-max"] ?? defaults.durationMax;
  const filters = [];

  if (durationMin !== undefined || durationMax !== undefined) {
    filters.push(`duration:[${durationMin ?? "*"} TO ${durationMax ?? "*"}]`);
  }

  const license = licenseFilterFor(options.license ?? defaults.license);
  if (license) {
    filters.push(license);
  }

  if (options.filter) {
    filters.push(options.filter);
  }

  return filters.join(" ");
};

const searchSounds = async (query, options = {}, defaults = {}) => {
  const url = new URL(`${apiBase}/search/`);
  const filter = buildFilter(options, defaults);

  url.searchParams.set("query", query);
  url.searchParams.set("fields", options.fields || defaultFields);
  url.searchParams.set("page_size", options["page-size"] || defaults.pageSize || "8");
  url.searchParams.set("sort", options.sort || defaults.sort || "score");

  if (filter) {
    url.searchParams.set("filter", filter);
  }

  return requestJson(url);
};

const getSound = async (soundId) => {
  const url = new URL(`${apiBase}/sounds/${soundId}/`);
  url.searchParams.set("fields", defaultFields);
  return requestJson(url);
};

const printResults = (data) => {
  console.log(`Found ${data.count} result(s). Showing ${data.results.length}:\n`);

  data.results.forEach((sound, index) => {
    const duration = Number(sound.duration || 0).toFixed(2);
    const tags = Array.isArray(sound.tags) ? sound.tags.slice(0, 8).join(", ") : "";
    console.log(`${index}. ${sound.id} | ${duration}s | ${sound.license} | ${sound.name}`);
    console.log(`   by ${sound.username} | ${sound.url}`);
    if (tags) {
      console.log(`   tags: ${tags}`);
    }
  });
};

const pickPreview = (sound, preferredPreview) => {
  const previews = sound.previews || {};
  const key = preferredPreview || previewPreference.find((item) => previews[item]);

  if (!key || !previews[key]) {
    throw new Error(`No usable preview found for sound ${sound.id}.`);
  }

  return { key, url: previews[key] };
};

const extensionForPreview = (previewKey, previewUrl) => {
  const fromKey = previewKey.split("-").pop();
  if (fromKey === "mp3" || fromKey === "ogg") {
    return fromKey;
  }

  const match = new URL(previewUrl).pathname.match(/\.([a-z0-9]+)$/i);
  return match ? match[1] : "mp3";
};

const resolveOutputPath = (outArg, extension) => {
  const requested = outArg || "Ester/Audio/sfx";
  const absolute = path.resolve(projectRoot, requested);
  const hasExtension = Boolean(path.extname(absolute));
  return hasExtension ? absolute : `${absolute}.${extension}`;
};

const downloadPreview = async (sound, options = {}, context = {}) => {
  const preview = pickPreview(sound, options.preview);
  const extension = extensionForPreview(preview.key, preview.url);
  const outputPath = resolveOutputPath(options.out, extension);

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });

  const response = await fetch(preview.url, { headers: authHeaders() });
  if (!response.ok) {
    throw new Error(`Preview download failed ${response.status}: ${await response.text()}`);
  }

  const bytes = Buffer.from(await response.arrayBuffer());
  fs.writeFileSync(outputPath, bytes);

  const metadataPath = outputPath.replace(/\.[^.]+$/, ".freesound.json");
  const metadata = {
    source: "Freesound",
    downloadedAt: new Date().toISOString(),
    query: context.query || null,
    previewKey: preview.key,
    file: path.relative(projectRoot, outputPath),
    sound: {
      id: sound.id,
      name: sound.name,
      username: sound.username,
      license: sound.license,
      duration: sound.duration,
      url: sound.url,
      tags: sound.tags || [],
    },
  };
  fs.writeFileSync(metadataPath, `${JSON.stringify(metadata, null, 2)}\n`);

  console.log(`Saved ${path.relative(projectRoot, outputPath)}`);
  console.log(`Saved ${path.relative(projectRoot, metadataPath)}`);
};

const readPlan = (planPath) => {
  const absolute = path.resolve(projectRoot, planPath || "Ester/Audio/freesound-plan.json");
  const data = JSON.parse(fs.readFileSync(absolute, "utf8"));
  if (!Array.isArray(data.items)) {
    throw new Error(`Plan ${planPath} must contain an items array.`);
  }
  return data.items;
};

const candidateOutputPaths = (outArg) => {
  const absolute = path.resolve(projectRoot, outArg);
  if (path.extname(absolute)) {
    return [absolute];
  }
  return ["mp3", "ogg"].map((extension) => `${absolute}.${extension}`);
};

const sidecarPathFor = (audioPath) => audioPath.replace(/\.[^.]+$/, ".freesound.json");

const existingAudioFor = (outArg) => candidateOutputPaths(outArg).find((item) => fs.existsSync(item));

const formatBytes = (bytes) => {
  if (!Number.isFinite(bytes)) {
    return "0 B";
  }
  if (bytes < 1024) {
    return `${bytes} B`;
  }
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  }
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
};

const hasAllowedLicense = (license) => {
  const normalized = String(license || "").trim().toLowerCase();
  return [
    "creative commons 0",
    "attribution",
    "http://creativecommons.org/publicdomain/zero/1.0/",
    "https://creativecommons.org/publicdomain/zero/1.0/",
    "http://creativecommons.org/licenses/by/3.0/",
    "https://creativecommons.org/licenses/by/3.0/",
    "http://creativecommons.org/licenses/by/4.0/",
    "https://creativecommons.org/licenses/by/4.0/",
  ].includes(normalized);
};

const verifyPlan = (planPath, options = {}) => {
  const items = readPlan(planPath);
  const rows = [];
  let presentCount = 0;
  let sidecarCount = 0;
  let licenseIssueCount = 0;
  let durationIssueCount = 0;
  let totalBytes = 0;

  for (const item of items) {
    const audioPath = existingAudioFor(item.out);
    const relativeAudio = audioPath ? path.relative(projectRoot, audioPath) : `${item.out}.mp3`;
    const sidecarPath = audioPath ? sidecarPathFor(audioPath) : `${path.resolve(projectRoot, item.out)}.freesound.json`;
    const sidecarExists = fs.existsSync(sidecarPath);
    let metadata = null;
    let issues = [];

    if (!audioPath) {
      issues.push("missing audio");
    } else {
      presentCount += 1;
      totalBytes += fs.statSync(audioPath).size;
    }

    if (!sidecarExists) {
      issues.push("missing sidecar");
    } else {
      sidecarCount += 1;
      metadata = JSON.parse(fs.readFileSync(sidecarPath, "utf8"));
      const license = metadata.sound?.license || "";
      if (!hasAllowedLicense(license)) {
        issues.push(`license ${license || "unknown"}`);
        licenseIssueCount += 1;
      }
      const duration = Number(metadata.sound?.duration);
      if (Number.isFinite(duration) && item.durationMax !== undefined && duration > Number(item.durationMax) + 0.01) {
        issues.push(`duration ${duration.toFixed(2)}s > ${item.durationMax}s`);
        durationIssueCount += 1;
      }
    }

    rows.push({
      out: item.out,
      file: relativeAudio,
      query: item.query,
      license: metadata?.sound?.license || "",
      duration: metadata?.sound?.duration ?? "",
      source: metadata?.sound?.url || "",
      bytes: audioPath ? fs.statSync(audioPath).size : 0,
      issues,
    });
  }

  const reportPath = path.resolve(projectRoot, options.report || "Ester/Audio/AUDIO_ASSET_REPORT.md");
  const report = [
    "# Ester Audio Asset Report",
    "",
    `Generated: ${new Date().toISOString()}`,
    "",
    "## Summary",
    "",
    `- Planned sounds: ${items.length}`,
    `- Audio files present: ${presentCount}`,
    `- Freesound sidecars present: ${sidecarCount}`,
    `- Total audio size: ${formatBytes(totalBytes)}`,
    `- License issues: ${licenseIssueCount}`,
    `- Duration issues: ${durationIssueCount}`,
    `- Items with issues: ${rows.filter((row) => row.issues.length > 0).length}`,
    "",
    "## Assets",
    "",
    "| File | License | Duration | Size | Issues | Source |",
    "| --- | --- | ---: | ---: | --- | --- |",
    ...rows.map((row) => {
      const duration = row.duration === "" ? "" : Number(row.duration).toFixed(2);
      const source = row.source ? `[Freesound](${row.source})` : "";
      const issues = row.issues.length ? row.issues.join(", ") : "ok";
      return `| ${row.file} | ${row.license || ""} | ${duration} | ${formatBytes(row.bytes)} | ${issues} | ${source} |`;
    }),
    "",
    "## Missing Download Commands",
    "",
    ...rows
      .filter((row) => row.issues.includes("missing audio"))
      .map((row) => {
        const item = items.find((candidate) => candidate.out === row.out);
        return `- \`node Tools/freesound.cjs pick "${item.query}" --index ${item.index ?? 0} --out ${item.out} --duration-max ${item.durationMax ?? 1.2} --license ${item.license || "cc0-or-attribution"} --preview preview-hq-mp3\``;
      }),
    "",
  ].join("\n");

  fs.mkdirSync(path.dirname(reportPath), { recursive: true });
  fs.writeFileSync(reportPath, report);
  console.log(`Wrote ${path.relative(projectRoot, reportPath)}`);
  console.log(`Audio ${presentCount}/${items.length}; sidecars ${sidecarCount}/${items.length}; issues ${rows.filter((row) => row.issues.length > 0).length}.`);
};

const batchDownload = async (planPath, options = {}) => {
  const items = readPlan(planPath);
  const start = Number(options.start || 0);
  const limit = options.limit === undefined ? items.length : Number(options.limit);
  const selected = items.slice(start, start + limit);

  if (options["dry-run"]) {
    selected.forEach((item, index) => {
      console.log(`${start + index}. ${item.out} <- ${item.query}`);
    });
    return;
  }

  for (const [index, item] of selected.entries()) {
    if (!item.query || !item.out) {
      throw new Error(`Plan item ${start + index} needs query and out.`);
    }
    if (!options.force && existingAudioFor(item.out)) {
      console.log(`\n[${start + index + 1}/${items.length}] ${item.out}`);
      console.log("Already exists; use --force to replace.");
      continue;
    }
    const perItemOptions = {
      ...options,
      out: item.out,
      preview: item.preview || options.preview || "preview-hq-mp3",
      license: item.license || options.license || "cc0-or-attribution",
      "duration-min": item.durationMin ?? options["duration-min"],
      "duration-max": item.durationMax ?? options["duration-max"] ?? "1.2",
      "page-size": item.pageSize || options["page-size"] || "10",
      sort: item.sort || options.sort || "score",
    };
    delete perItemOptions.start;
    delete perItemOptions.limit;
    delete perItemOptions["dry-run"];
    delete perItemOptions.force;

    console.log(`\n[${start + index + 1}/${items.length}] ${item.out}`);
    const queries = [item.query, ...(item.fallbackQueries || [])];
    let data = null;
    let usedQuery = item.query;
    for (const query of queries) {
      data = await searchSounds(query, perItemOptions, {
        durationMin: "0.04",
        durationMax: perItemOptions["duration-max"],
        license: perItemOptions.license,
        pageSize: perItemOptions["page-size"],
        sort: perItemOptions.sort,
      });
      if (data.results.length > 0) {
        usedQuery = query;
        break;
      }
    }
    const sound = data.results[Number(item.index ?? options.index ?? 0)];
    if (!sound) {
      throw new Error(`No result for plan item ${start + index}: ${queries.join(" | ")}`);
    }
    await downloadPreview(sound, perItemOptions, { query: usedQuery });
  }
};

const run = async () => {
  loadEnv();

  const [command, ...rest] = process.argv.slice(2);
  const { positional, options } = parseArgs(rest);

  if (!command || command === "help" || command === "--help") {
    usage();
    return;
  }

  if (command === "search") {
    const query = positional.join(" ");
    if (!query) {
      throw new Error("Missing search query.");
    }

    const data = await searchSounds(query, options, {
      durationMin: "0.04",
      durationMax: "1.2",
      license: "cc0-or-attribution",
      pageSize: "8",
      sort: "score",
    });

    if (options.json) {
      console.log(JSON.stringify(data, null, 2));
    } else {
      printResults(data);
    }
    return;
  }

  if (command === "pick") {
    const query = positional.join(" ");
    if (!query) {
      throw new Error("Missing search query.");
    }

    const data = await searchSounds(query, options, {
      durationMin: "0.04",
      durationMax: "1.2",
      license: "cc0-or-attribution",
      pageSize: "10",
      sort: "score",
    });
    const index = Number(options.index || 0);
    const sound = data.results[index];
    if (!sound) {
      throw new Error(`No result at index ${index}.`);
    }

    await downloadPreview(sound, options, { query });
    return;
  }

  if (command === "download") {
    const soundId = positional[0];
    if (!soundId) {
      throw new Error("Missing Freesound sound id.");
    }

    const sound = await getSound(soundId);
    await downloadPreview(sound, options, { query: `sound:${soundId}` });
    return;
  }

  if (command === "batch") {
    await batchDownload(positional[0], options);
    return;
  }

  if (command === "verify") {
    verifyPlan(positional[0], options);
    return;
  }

  throw new Error(`Unknown command "${command}".`);
};

run().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
