#!/usr/bin/env node

"use strict";

// This script replaces hardcoded, org-specific values (IDs, agent usernames, org domain URLs)
// by placeholders that are restored during the next install.

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const SALESFORCE_ID_REGEX = /[>'"]([a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?)[<'"]/g;
const ID_PLACEHOLDERS_BY_KEY_PREFIX = {
  "00D": "%%PRONTO_PLACEHOLDER_ORG_ID%%",
  "00G": "%%PRONTO_PLACEHOLDER_QUEUE_ID%%",
  "005": "%%PRONTO_PLACEHOLDER_AGENT_USER_ID%%"
};

const AGENT_USERNAME_REGEX = /agent\.user\.[a-zA-Z0-9]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-]+/g;
const AGENT_USERNAME_PLACEHOLDER = "%%PRONTO_PLACEHOLDER_AGENT_USERNAME%%";

const ORG_DOMAIN_URL_REGEX = /(https:\/\/[a-z0-9\-]+(?:\.scratch)?)\.my\./g;
const ORG_DOMAIN_PLACEHOLDER = "%%PRONTO_PLACEHOLDER_ORG_DOMAIN%%";

const SITE_USER_TAGS_TO_REMOVE = ["siteAdmin", "siteGuestRecordDefaultOwner"];

// Sub-cleanup logic. Each takes the file content and returns the updated content,
// or null when nothing needed to change.

function cleanHardcodedIds(content) {
  let replaced = false;
  const updated = content.replace(SALESFORCE_ID_REGEX, (match, id) => {
    const placeholder = ID_PLACEHOLDERS_BY_KEY_PREFIX[id.substring(0, 3)];
    if (!placeholder) {
      return match;
    }
    replaced = true;
    return match.replace(id, placeholder);
  });
  return replaced ? updated : null;
}

function cleanHardcodedUsernames(content) {
  const updated = content.replace(AGENT_USERNAME_REGEX, AGENT_USERNAME_PLACEHOLDER);
  return updated !== content ? updated : null;
}

function cleanHardcodedOrgDomainUrls(content) {
  const updated = content.replace(ORG_DOMAIN_URL_REGEX, (match, domain) =>
    match.replace(domain, ORG_DOMAIN_PLACEHOLDER)
  );
  return updated !== content ? updated : null;
}

function removeSiteUserTags(content) {
  let updated = content;
  for (const tag of SITE_USER_TAGS_TO_REMOVE) {
    const tagRegex = new RegExp(`[ \\t]*<${tag}>.*</${tag}>\\r?\\n`, "g");
    updated = updated.replace(tagRegex, "");
  }
  return updated !== content ? updated : null;
}

// File-type routing: picks the sub-cleanup(s) to run for a given file
const ROUTES = [
  { test: (filePath) => /\.agent\.xml$/.test(filePath), cleaners: [cleanHardcodedUsernames] },
  { test: (filePath) => /\.flow-meta\.xml$/.test(filePath), cleaners: [cleanHardcodedIds] },
  { test: (filePath) => /\.page$/.test(filePath), cleaners: [cleanHardcodedIds, cleanHardcodedOrgDomainUrls] },
  {
    test: (filePath) => /(^|[/\\])digitalExperiences[/\\]site[/\\].*\.json$/.test(filePath),
    cleaners: [cleanHardcodedOrgDomainUrls]
  },
  { test: (filePath) => /\.site-meta\.xml$/.test(filePath), cleaners: [removeSiteUserTags] }
];

// Get files from command arguments, expanding any glob patterns
const GLOB_CHARS_REGEX = /[*?[{]/;
const args = process.argv.slice(2);
if (args.length === 0) {
  console.log(`ERROR: Expected at least one file to be passed as a parameter.`);
  process.exit(-1);
}

const files = args.flatMap((arg) => (GLOB_CHARS_REGEX.test(arg) ? fs.globSync(arg) : arg));

for (const filePath of files) {
  const cleaners = ROUTES.filter((route) => route.test(filePath)).flatMap((route) => route.cleaners);
  if (cleaners.length === 0) {
    continue;
  }

  let content = fs.readFileSync(filePath, "utf8");
  let changed = false;
  for (const clean of cleaners) {
    const updated = clean(content);
    if (updated !== null) {
      content = updated;
      changed = true;
    }
  }

  if (changed) {
    fs.writeFileSync(filePath, content, "utf8");
    execSync(`git add "${filePath}"`);
    console.log(`Restored hardcoded value placeholder(s) in: ${path.basename(filePath)}`);
  }
}
