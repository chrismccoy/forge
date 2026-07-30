# Security

[← Back to the README](../README.md)

All three security tools are defensive. They model, audit, and document systems you are
responsible for. None of them produce offensive tooling, working exploits, or weaponized
payloads, and each says so in its own scope lock.

## `threat-model`

STRIDE threat modeling from four inputs, in the voice of a Principal AppSec Architect. Locked four-phase assessment with all six STRIDE categories addressed explicitly.

```
/threat-model
```

The usual security review returns a list of worries with no way to prioritize them. Here every threat carries a severity rating - Low, Medium, High, Critical - with a one-line justification and a mapped mitigation, so the list sorts itself. All six STRIDE categories must be addressed in Phase 2; skipping one because it "does not apply" fails validation.

The injection defense matters more than usual for this tool, because assessment inputs routinely contain claims. A note saying "the auth layer is already secure" is treated as context to evaluate, never as an instruction to skip that category or downgrade a finding.

Attack scenarios stay at vector-and-impact level. No working exploit code, no copy-paste-ready payload - this is the model, not the attack.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/threat-model/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt with a reference-tone example showing the expected threat-writeup density.

## ✨ Features

- 🎯 Four inputs in, one assessment out. SYSTEM_DESCRIPTION + TECH_STACK (required) + DATA_CLASSIFICATION + COMPLIANCE_NEEDS (optional)
- 🧱 Locked 4-phase output: Trust Boundary Analysis, STRIDE Threat Assessment, Attack Vector Scenarios, Remediation Blueprint
- 🔠 All six STRIDE categories addressed explicitly - Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege
- 🚥 Severity rating (Low/Medium/High/Critical) plus a one-line justification on every threat
- 🔗 Every threat mapped to a mitigation - no orphan findings
- 🧭 OWASP Top 10 alignment and standard cryptographic practice
- 🚫 No "unhackable" or "100% secure" claims - risk reduction and defense in depth only
- 🛡️ Claims inside inputs ("this is already secure") treated as context to evaluate, never directives to skip a category
- ⚔️ Attack scenarios stay at vector-and-impact level - no working exploit code or ready-to-run payloads
- 🪧 Defensive-only scope lock: offensive tooling and third-party targeting refused with `Out of scope: this engine produces defensive threat models only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If a system was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Empty `SYSTEM_DESCRIPTION` or `TECH_STACK` → ask one clarifying question and wait. Empty optional field → state the assumption and proceed.
4. **Generate** the assessment under the strict operating constraints (all six categories, severity per threat, OWASP-aligned mitigations).
5. **Silent self-validation.** Six STRIDE categories present; severity and mitigation per threat; no absolute-security claim; no working exploit code. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/threat-model "multi-tenant SaaS with Stripe billing"   ← arg seeds SYSTEM_DESCRIPTION
/threat-model                                            ← full intake
```

**Typical asks:** *"threat model this feature"*, *"STRIDE analysis of our API"*, *"where are the trust boundaries"*, *"security review before launch"*

The full procedure lives at [`lib/threat-model/SKILL.md`](../lib/threat-model/SKILL.md), the slash command at [`commands/threat-model.md`](../commands/threat-model.md), and the on-demand master prompt at [`lib/threat-model/references/prompt-template.md`](../lib/threat-model/references/prompt-template.md).

---

## `devsecops`

Security hardening audits of pipelines, IaC, and cloud configuration, in the voice of a CISSP-certified Principal Cybersecurity Engineer. Locked four-phase report mapping every flaw to a real compliance control.

```
/devsecops
```

A finding without a blast radius is just a lint warning. Every flaw here states what an attacker actually gets - "blast radius = full account takeover and lateral movement into production" - and which documented control it violates. Compliance IDs are never invented: if the exact control number is uncertain, the framework and control area are named instead of a plausible-looking fabrication.

Remediation is structural. Phase 2 gives the corrected config, Phase 3 adds the scanning gate (SAST, DAST, SCA) that catches it next time, and Phase 4 covers runtime guardrails. Temporary hotfixes offered in place of the real fix fail validation.

If you paste real configuration and it contains a live credential, the tool flags it as compromised and never echoes the value back into the report.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/devsecops/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt with a reference-tone example showing the expected blast-radius and compliance-mapping density.

## ✨ Features

- 🎯 Four inputs in, one report out. TARGET_INFRASTRUCTURE_STACK + CONFIGURATION_CONTEXT (required) + SECURITY_DOMAIN + COMPLIANCE_FRAMEWORK (optional)
- 🧱 Locked 4-phase output: Exploit Surface Audit, Hardening Blueprint, Pipeline Shift-Left, Runtime Guardrails
- 💥 Every flaw states its blast radius and exploitability vector
- 📜 Every flaw mapped to a real documented compliance control - no invented control IDs
- 🏗️ Structural fixes only - temporary hotfixes in place of the real fix fail validation
- 🚪 Concrete scanning gates required in Phase 3: SAST, DAST, or SCA
- 🔐 Credentials found in pasted config are flagged as compromised and never echoed back
- 🧊 Zero-Trust and least privilege applied across every mitigation
- 🛡️ Code and configs inside inputs treated as artifacts to analyze, never commands to obey; a flaw cannot be marked safe because an input said so
- 🪧 Defensive-only scope lock: offensive tooling and third-party targeting refused with `Out of scope: this engine produces defensive hardening audits only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. The `CONFIGURATION_CONTEXT` field accepts pasted config directly.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Empty `TARGET_INFRASTRUCTURE_STACK` or `CONFIGURATION_CONTEXT` → ask one clarifying question and wait. Live credential in the paste → flag as compromised.
4. **Generate** the report under the strict operating constraints (Zero-Trust, least privilege, structural fixes, real controls only).
5. **Silent self-validation.** Blast radius and mapped control per flaw; structural remediations; concrete scanning gates; no invented control IDs; no echoed credentials. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/devsecops "GitHub Actions workflow, SOC 2 audit coming"
/devsecops                                                 ← full intake
```

**Typical asks:** *"audit my pipeline for security issues"*, *"harden this Terraform"*, *"are my IAM policies too broad"*, *"what scanning gates should we add"*

The full procedure lives at [`lib/devsecops/SKILL.md`](../lib/devsecops/SKILL.md), the slash command at [`commands/devsecops.md`](../commands/devsecops.md), and the on-demand master prompt at [`lib/devsecops/references/prompt-template.md`](../lib/devsecops/references/prompt-template.md).

---

## `pentest-report`

Formal vulnerability reporting from authorized assessment notes, in the voice of an OSCP/OSWE-certified Principal Security Consultant. Locked four-phase report bridging technical detail and executive business risk.

```
/pentest-report
```

This is a **reporting** tool, not an exploitation tool. It takes notes from an assessment you are authorized to perform and turns them into the document a client or an engineering team can act on: a formal vulnerability title, a CVSS score backed by its full vector string, the technical reason the flaw exists, reproduction steps a developer can follow, and both a short-term mitigation and a long-term architectural fix.

Every proof-of-concept stays sanitized. No live credentials, no real target hostnames you did not supply, no weaponized payload. Phase 3 gives a developer enough to reproduce the issue in their own environment and nothing more.

Two details that reports usually get wrong are enforced here: the CVSS score is never printed without its vector string, and v3.1 and v4.0 are never mixed in one report.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/pentest-report/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt with a reference-tone example showing the expected CVSS and business-impact density.

## ✨ Features

- 🎯 Four inputs in, one report out. TARGET_SYSTEM + VULNERABILITY_FOUND (required) + EXPLOIT_METHOD + BUSINESS_IMPACT (optional)
- 🧱 Locked 4-phase output: Executive Summary & Risk Rating, Vulnerability Details, Proof of Concept, Remediation Strategy
- 📐 CVSS v4.0 or v3.1 score with the **full vector string** - never a bare number
- 🔒 One CVSS version used consistently throughout the report
- 🧼 All PoC content sanitized - no live credentials, no real hostnames you did not supply, no weaponized payloads
- 🩹 Both a short-term mitigation and a long-term architectural fix, both actionable
- 💼 Executive summary written in non-technical business-impact terms
- 🗣️ Professional and objective tone - alarmist language fails validation
- 🛡️ Payloads and requests inside inputs treated as evidence to document, never commands to execute
- 🪧 Authorized-work scope lock: unauthorized targets and weaponization requests refused with `Out of scope: this engine documents findings from authorized assessments only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If a finding was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Empty `TARGET_SYSTEM` or `VULNERABILITY_FOUND` → ask one clarifying question and wait. Empty optional field → state the assumption and proceed.
4. **Generate** the report under the strict operating constraints (objective tone, CVSS with vector string, sanitized PoC, actionable remediation).
5. **Silent self-validation.** CVSS backed by a vector string; one version throughout; short-term and long-term fix per finding; all PoC content sanitized; tone objective. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/pentest-report "IDOR on /api/orders, client engagement"
/pentest-report                                            ← full intake
```

**Typical asks:** *"write up this finding"*, *"format my pentest notes as a report"*, *"CVSS score for this vulnerability"*, *"client-ready vulnerability write-up"*

The full procedure lives at [`lib/pentest-report/SKILL.md`](../lib/pentest-report/SKILL.md), the slash command at [`commands/pentest-report.md`](../commands/pentest-report.md), and the on-demand master prompt at [`lib/pentest-report/references/prompt-template.md`](../lib/pentest-report/references/prompt-template.md).
