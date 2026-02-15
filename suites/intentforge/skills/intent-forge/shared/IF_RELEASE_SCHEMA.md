# IntentForge Release Schema

## Files
- .intent-forge/artifacts/050_release/deploy_plan.md
- .intent-forge/artifacts/050_release/deploy_manifest.yaml
- .intent-forge/artifacts/050_release/pr_body.md
- .intent-forge/artifacts/050_release/release_raw.txt

## deploy_manifest.yaml
See the required YAML structure in the intent-forge-release skill.
Unknown fields must be null or empty string.

## release_raw.txt
Must contain raw pasted CLI output verbatim from:
- vercel
- git remote -v
- gh pr create (optional)
If no raw data, include a note saying no CLI outputs were provided.
