# Recovery Builder

Manual GitHub Actions builder for OrangeFox and TWRP device trees.

> **No automatic recovery builds.** The user-facing workflows are `workflow_dispatch` only. Pushing commits to this repository does not start a recovery compile or consume build minutes.

## Architecture

The repository keeps the two user-facing workflows intentionally small:

| Workflow | Source | Manifest | Lunch suffix |
| --- | --- | --- | --- |
| `Recovery Build` | OrangeFox sync | `14.1` | `ap2a-eng` |
| `TWRP Build` | TWRP AOSP manifest | `twrp-16.0` | `bp2a-eng` |

Both call `.github/workflows/_build-core.yml`, which owns the common build pipeline. Shared shell/Python helpers live under `scripts/`.

This replaces the old layout where two ~18 KB workflow files carried separate copies of the same Telegram, clone, checksum, artifact, and release logic.

## Security model

Credentials are **Actions secrets only**. They are not accepted as plain `workflow_dispatch` inputs.

Configure these under **Settings → Secrets and variables → Actions**:

| Secret | Purpose |
| --- | --- |
| `DT_TOKEN` | Optional read-only token for a private GitHub/GitLab device tree |
| `TELEGRAM_BOT_TOKEN` | Telegram Bot API token from BotFather |
| `TELEGRAM_CHAT_ID` | Telegram destination: numeric chat/channel ID (for example `-100...`) or a public `@channelusername` |

The device-tree clone helper masks `DT_TOKEN`, uses it only for the authenticated fetch, and then rewrites the cloned repository's `origin` back to the clean URL so the credential is not left in `.git/config`.

GitHub-hosted Actions are pinned to immutable commit SHAs. The builder also no longer downloads a moving OrangeFox `android_build_env.sh` and executes it as root; the CI package set is maintained locally in `scripts/setup-build-env.sh`.

## Running a build

Open **Actions**, choose `Recovery Build` or `TWRP Build`, and select **Run workflow**.

| Input | Meaning |
| --- | --- |
| `device_tree_url` | HTTPS GitHub/GitLab device-tree URL |
| `device_tree_branch` | Branch to clone |
| `device_path` | Android source destination, e.g. `device/xiaomi/zorn` |
| `device_name` | Device codename used by the output tree |
| `makefile_name` | Lunch product, e.g. `twrp_zorn` |
| `build_target` | `recovery`, `boot`, or `vendorboot` |
| `create_release` | Publish a public GitHub Release instead of private Actions artifacts |

A preflight validates URL, device path, names, and target before the expensive source sync starts.

## Quota behavior

The builder is deliberately conservative with Actions minutes:

- there are no `push`, `pull_request`, `schedule`, or polling build triggers;
- each dispatch performs one build and exits;
- concurrent duplicate runs for the same recovery/device/tree branch/target cancel the older run;
- failure logs are retained for 7 days;
- private successful artifacts are retained for 14 days;
- there is no giant Android source cache by default. Source trees are too large for a useful general-purpose Actions cache and can spend substantial time uploading/downloading stale data.

Dependabot may open maintenance PRs for GitHub Actions versions, but those PRs do **not** trigger recovery builds.

## Build flow

The common workflow performs:

1. runner disk cleanup;
2. checkout of the tiny builder/helper repository;
3. input validation and CI dependency setup;
4. OrangeFox or TWRP source sync;
5. authenticated device-tree clone when `DT_TOKEN` is configured;
6. swap setup;
7. `lunch` and `mka adbd <target>image`;
8. image validation, SHA-256 generation, summary, and artifact/release publishing.

The full compiler output is captured in `$RUNNER_TEMP/recovery-build.log`. On failure, that log is uploaded and the final 200 lines are also copied into the Actions job summary.

## Outputs

Every successful build verifies that the requested image exists and produces `SHA256SUMS`.

For TWRP recovery builds, `recovery.img` is copied to a friendly `twrp-<version>-<device>.img` filename. OrangeFox keeps the image produced by the build system and also publishes the OrangeFox installer ZIP when one exists.

## Telegram

Telegram is optional. If both Telegram secrets are present, one dashboard message is created and edited through the build. Notification errors are warnings only and never turn a successful recovery compile into a failed job.

For a channel, add the bot to the channel as an administrator with permission to post messages. Use `@channelusername` for a public channel, or the numeric `-100...` channel ID for a private channel. Never put the bot token in a workflow input, repository file, commit, or device-tree URL.

For a private GitHub device tree, prefer a fine-grained personal access token scoped only to that repository with **Contents: Read-only** access. Store it as `DT_TOKEN`. A token is only injected into the authenticated clone URL in memory; the clone helper masks it and immediately restores the clean remote URL afterwards.


The notification engine lives in `scripts/notify.py`, uses Telegram HTML formatting (so underscores/branch names do not randomly break Markdown), and is shared by both builders.

## Reproducibility notes

The builder deliberately separates things that are known to differ between OrangeFox 14.1 and TWRP 16:

- manifest/source sync method;
- manifest branch;
- lunch suffix;
- output naming.

Common behavior lives in the reusable workflow and helper scripts. Do not copy the core workflow back into both frontends.

The Android build environment is installed from a repository-controlled package list. If upstream requirements change, update that script in a normal reviewed commit rather than silently executing a new remote root script.

## zorn

For the POCO F7 Pro / Redmi K80 (`zorn`) recovery work, point `Recovery Build` at the current test device tree when Actions quota is available.

Maintenance commits to this builder are safe to make while quota is exhausted because they do not trigger builds.

## Credits

Based on the original Action Recovery Builder workflow and the upstream OrangeFox/TWRP projects.
