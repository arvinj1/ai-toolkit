# Token / agent costs (optional)
# Fill this in if you want the cost model section in the Team Composer output.
# Leave blank or delete this file to skip cost analysis.

## Human costs (fully loaded, i.e. salary + benefits + tooling + overhead)

| Role | Count | Monthly cost (est.) | Notes |
|---|---|---|---|
| Senior Engineer | N | $X | Fully loaded ~2–2.5x base |
| Mid Engineer | N | $X | |
| Junior Engineer | N | $X | |
| TL (you) | 1 | $X | |
| **Total** | | $X | |

## Agent / AI tool costs

| Tool | Billing model | Monthly cost | Notes |
|---|---|---|---|
| [e.g. GitHub Copilot] | $19/seat/mo × N devs | $X | |
| [e.g. Claude API] | Per token | $X | ~X million tokens/month |
| [e.g. OpenAI API] | Per token | $X | |
| [e.g. Custom infra] | Compute | $X | GPU/VM cost |
| **Total** | | $X | |

## Cost per output unit (optional — fill in if you can estimate)

| Task | Human cost per unit | Agent cost per unit | Breakeven volume |
|---|---|---|---|
| [e.g. Code review] | ~$X (N mins × hourly rate) | ~$X (tokens + oversight) | X reviews/week |
| [e.g. Test generation] | ~$X | ~$X | X test files/week |
| [e.g. Doc writing] | ~$X | ~$X | X pages/week |

## Notes

- Human costs are the dominant cost at any team size ≤ 20 engineers
- Agent costs scale with usage, not headcount — model this for different usage scenarios
- Do not optimise for agent cost at the expense of oversight quality
