# Recovery Builder

Manual GitHub Actions builder for OrangeFox and TWRP device trees.

> Builds are **manual-only** (`workflow_dispatch`). Pushing commits to this repository does not start a recovery build.

## Workflows

| Workflow | Source | Default branch | Lunch suffix |
| --- | --- | --- | --- |
| `Recovery Build` | OrangeFox sync | `14.1` | `ap2a-eng` |
| `Twrp Build` | TWRP AOSP manifest | `twrp-16.0` | `bp2a-eng` |

Both workflows support `recovery`, `boot`, and `vendorboot` image targets.

## Cost / quota behavior

- A workflow run now performs **one build and exits**. It no longer keeps the runner alive for hours waiting for device-tree changes.
- Duplicate manual runs for the same workflow/device/tree branch/target share a concurrency group; a newer run cancels the older one.
- Private artifacts are retained for **14 days** instead of 90. Public releases remain available until manually removed.
- Failed compilations upload the captured build log for 7 days when available.

These defaults are intentional: if the device tree changes, dispatch a new run instead of keeping a paid runner idle.

## Secrets

Prefer repository **Actions secrets** instead of typing credentials into workflow inputs:

| Secret | Purpose |
| --- | --- |
| `DT_TOKEN` | Token used only when the device tree is private |
| `TELEGRAM_BOT_TOKEN` | Optional Telegram build notifications |
| `TELEGRAM_CHAT_ID` | Optional Telegram destination |

The old workflow inputs for these values remain as a compatibility fallback, but secrets are safer because workflow inputs become part of run metadata. GitHub masks supported secret values in logs.

## Running a build

Open **Actions**, choose either `Recovery Build` or `Twrp Build`, then choose **Run workflow**.

Important inputs:

| Input | Meaning |
| --- | --- |
| `device_tree_url` | GitHub/GitLab device-tree repository |
| `device_tree_branch` | Branch to clone |
| `device_path` | Android source-tree destination, e.g. `device/xiaomi/zorn` |
| `device_name` | Device codename used for the output path |
| `makefile_name` | Lunch product name, e.g. `twrp_zorn` |
| `build_target` | `recovery`, `boot`, or `vendorboot` |
| `create_release` | Publish a GitHub Release or keep outputs as private Actions artifacts |

## Outputs

A successful run validates that the expected image exists before publishing anything and creates a `SHA256SUMS` file. The run summary also records the device-tree commit and checksums.

Private mode uploads:

- the requested image plus `SHA256SUMS`
- the installer ZIP when one was produced

Release mode publishes the same build outputs through GitHub Releases.

## Reliability notes

- OrangeFox/TWRP source, Java version, lunch suffixes, and the proven build commands are intentionally kept separate per workflow.
- Third-party cleanup, swap, and release actions are pinned to commit SHAs so an upstream branch change cannot silently alter a build.
- The job has a 300-minute hard timeout to stop genuinely stuck runs.
- Telegram failures do not turn a successful recovery build into a failed build.

## zorn example

For the current POCO F7 Pro / Redmi K80 recovery work, use the test device tree and its `main` branch when you are ready to spend Actions quota. Do not use Actions merely to validate YAML changes; repository commits alone do not trigger these workflows.

## Credits

Based on the original Action Recovery Builder workflow and the upstream OrangeFox/TWRP projects.
