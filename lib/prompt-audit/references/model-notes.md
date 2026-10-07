# Model-Specific Notes

Last checked: 2026-10-06. Vendor parameter names change; when a note
looks out of date, say so in the report and skip it rather than guess.

Report only issues that apply to the target model, each tied to a
passage. When the target model is unknown, give cross-model notes only.

## Claude

- Reads instructions literally — vague asks ("be thorough") produce vague
  results. Spell out the wanted behavior.
- With extended thinking on, drop hand-written "think step by step"
  scaffolds and give high-level guidance.
- Responds well to XML-tagged sections (`<context>`, `<instructions>`);
  flag long unstructured walls of text.
- Heavy emphasis (all-caps, "CRITICAL", "you MUST") can cause
  over-compliance on current models — rules get applied too broadly.
  Flag it and suggest plain firm wording.

## GPT

- Map depth requests to `reasoning_effort` (low / medium / high) instead
  of "think carefully" text.
- Put durable rules in the system or developer message, not the first
  user turn.
- Lock format explicitly when plain text is required; markdown is the
  default tendency.

## Gemini

- Map depth requests to the thinking-level / thinking-budget setting, not
  prompt text.
- Confirm referenced tools (search, code execution) are enabled in the
  deployment; flag prompts that assume them.

## Cross-Model

Flag syntax that will not transfer:

- Claude-specific XML conventions or prefill tricks.
- Vendor parameter names written into the prompt (`reasoning_effort`,
  `thinking_level`, `budget_tokens`).
- One vendor's tool names or features.
- Persona lines naming a specific model ("As Claude, ...").
