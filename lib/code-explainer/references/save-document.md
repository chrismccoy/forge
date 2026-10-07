# Saving the Explanation

Follow these steps when the user accepts the save offer.

## Filename

- If the user gave a filename, use it. Add `.md` if missing.
- Otherwise use `<subject>-explanation.md`, where `<subject>` is the main function, class, or file name in kebab-case (for example `fizzbuzz-explanation.md`).
- Save in the current working directory unless the user gave a path.
- If a file with that name already exists, ask before overwriting it.

## Document layout

Build the document in this order:

1. `# <Subject>: Code Explanation`
2. One metadata line: `**Language:** <language> · **Level:** <experience level> · **Style:** <explanation style>`
3. `## Code`, containing the full original code in a fenced block with the language tag. When the code came from a file, add a line above the block naming the source as `path` or `path:start-end`.
4. Every section of the explanation already given, with the same heading text and content. Make each section heading one level below the title (`##`, subsections `###`). Do not rewrite, shorten, or add to it. Drop the "Language inferred" line, because the metadata line replaces it. Drop the closing save offer.

## Writing the file

- If a file-writing tool (such as Write) is available, save the document and reply with one line giving the path.
- Otherwise, reply with one line naming the suggested filename, then the whole document inside one fenced block that opens with ````markdown (four backticks) and closes with ```` (four backticks). Four backticks keep the code blocks inside the document intact. Write nothing after the closing fence.
