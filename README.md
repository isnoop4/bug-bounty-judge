# Bug Bounty Judge

An Intelligent Contract on [GenLayer](https://genlayer.com) that judges bug bounty reports on-chain. Researchers submit a report, the contract reads the target code, and a panel of LLM validators decides whether the claim is real and how severe it is. The reward is recorded automatically.

**Deployed contract (GenLayer Studio):** [`0xc6e2D35cBe089e4154E057B703eBBa7AEF0D0058`](https://explorer-studio.genlayer.com/address/0xc6e2D35cBe089e4154E057B703eBBa7AEF0D0058)

## Why

Bug bounty programs depend on a human triager who decides what is valid, how severe it is, and what gets paid. That is slow, opaque, and easy to dispute. Judging a report is subjective and needs real-world evidence (code, PoC links), which a normal smart contract cannot do. GenLayer can: validators run LLMs, read web pages, and reach consensus on the verdict.

## How it works

1. The owner deploys the contract with a `program_name`, `scope`, and `rules`.
2. A researcher calls `submit_report(title, description, poc_url, target_code_url)`.
3. Each validator fetches the target code and PoC page, then asks an LLM to check the claim against the code and the program rules.
4. Validators reach consensus on `valid` and `severity` (`none`, `low`, `medium`, `high`, `critical`).
5. The contract applies evidence caps, stores the report, and credits the reward to the researcher.

## Design choices

- **Claims are checked against the code.** The judge reads `target_code_url` and rejects a report if the code contradicts it (for example, an "missing owner check" claim when the check exists). A convincing story alone is not enough.
- **Evidence caps are enforced in code, not in the prompt.** No `target_code_url` means severity is capped at `low`. No `poc_url` means severity is capped at `medium`. The prompt cannot talk its way past these limits. Capped reports are flagged with `capped_by_missing_evidence`.
- **Prompt injection resistance.** Report text and fetched pages are treated as untrusted data, and the prompt tells the judge to ignore instructions inside them.
- **Duplicate protection.** A report with an already used title is rejected.
- **Consensus.** Uses `gl.eq_principle.prompt_comparative`: validators re-run the judgment themselves and agree if `valid` matches and `severity` is the same or adjacent.

## Contract API

| Method | Type | Description |
| --- | --- | --- |
| `__init__(program_name, scope, rules)` | constructor | Sets program details; deployer becomes owner |
| `submit_report(title, description, poc_url, target_code_url)` | write | Judges a report and records the reward |
| `update_program(scope, rules)` | write | Owner only. Updates scope and rules |
| `get_program()` | view | Program info, reward table, and evidence caps |
| `get_report(report_id)` | view | Full stored report with verdict and reasoning |
| `get_reward(researcher_hex)` | view | Total reward credited to an address |

### Reward table

| Severity | Reward |
| --- | --- |
| none | 0 |
| low | 100 |
| medium | 500 |
| high | 2000 |
| critical | 5000 |

Rewards are recorded as on-chain points. The contract does not move tokens.

## Example

Deploy with:

```
program_name: GenLayer DApp Bug Bounty
scope:  In scope: smart contract logic bugs, access control flaws, reentrancy, ...
rules:  A report is valid only if it includes clear reproduction steps, ...
```

Submit a report:

```
title:           Unrestricted update_program lets anyone overwrite program rules
description:     The update_program function has no access control. Any wallet can ...
poc_url:         (empty)
target_code_url: https://gist.githubusercontent.com/.../update_program_vulnerable.py
```

## Tested behavior (GenLayer Studio)

| Case | Result |
| --- | --- |
| Report claims a missing owner check, but the target code has the check | Rejected (`valid: false`, severity `none`) |
| Same claim, target code really has no check, no PoC link | Accepted, severity capped at `medium` (`capped_by_missing_evidence: true`) |
| Non-security report ("button color is ugly") | Rejected as cosmetic and out of scope |

## Run it

1. Open [GenLayer Studio](https://studio.genlayer.com) and create a new contract.
2. Paste `bug_bounty_judge.py`.
3. Fill the constructor inputs and deploy.
4. Call `submit_report` with a report and a raw link to the target code, then read the result with `get_report`.

## Limitations

- The judge reads only the first 6000 characters of the target code and 3000 of the PoC page, so point `target_code_url` at the relevant file or snippet.
- Duplicate detection is an exact, case-insensitive title match, not semantic.
- Rewards are accounting entries, not token transfers.
- Currently tested on GenLayer Studio. Deploying to Bradbury Phase 2 requires the latest GenVM runners and fees support.

## Roadmap

- Semantic duplicate detection
- Researcher stake or deposit to discourage spam
- Real token payouts from a funded bounty pool
- Appeal flow with a second validator round

## Repository

https://github.com/isnoop4/bug-bounty-judge
