---
name: publish-ruby-gem
description: Publishes the piggly-nsd Ruby gem to RubyGems.org. Use when releasing a new gem version, running gem push, bumping version, or when the user asks to publish or release the gem.
---

# Publish piggly-nsd Ruby Gem

## Prerequisites

Ensure RubyGems credentials are configured with **push** scope:

```bash
gem signin
```

When prompted:

1. Enter RubyGems.org username/email and password (never store these in code or commits).
2. Set API key name: `Main`
3. Choose **y** to customise scopes.
4. Enable only what is needed for publishing:
   - `show_dashboard` → **n**
   - `index_rubygems` → **n**
   - `push_rubygem` → **y**
   - `yank_rubygem` → **n**
   - `add_owner` → **n**
   - `remove_owner` → **n**
   - `access_webhooks` → **n**

Confirm: `Signed in with API key: <name>.`

## Release checklist

Copy and track progress:

```
Task Progress:
- [ ] Run tests: bundle exec rake spec
- [ ] Build gem: gem build piggly.gemspec
- [ ] Local install test: gem install piggly-nsd-<version>.gem
- [ ] Push to RubyGems: gem push piggly-nsd-<version>.gem
```

## Step-by-step

### 1. Run tests

```bash
bundle exec rake spec
```

**Success criteria:** `0 failures`. Pending examples are expected and do not block release.

### 2. Build the gem

```bash
gem build piggly.gemspec
```

Expected output:

```
Successfully built RubyGem
  Name: piggly-nsd
  Version: <version>
  File: piggly-nsd-<version>.gem
```

Build warnings (open-ended dependencies, `has_rdoc=`, missing `required_ruby_version`) are informational — do not block release unless the user asks to fix them.

### 3. Local install test

```bash
gem install piggly-nsd-<version>.gem
```

Use `gem install`, **not** `git install`.

On Windows with Kaspersky Endpoint Security, an SSL verification warning may appear (`self-signed certificate in certificate chain`). The install can still succeed — verify the gem name appears in the success line.

### 5. Push to RubyGems.org

```bash
gem push piggly-nsd-<version>.gem
```

Expected output:

```
Pushing gem to https://rubygems.org...
Successfully registered gem: piggly-nsd (<version>)
```
