# Documentation style guide

This guide defines the writing and formatting standards for documentation in the
`small-data-cluster` project. Follow it when adding, reviewing, or updating
files under `docs/`.

The documentation is written in Markdown and rendered to PDF with Pandoc and
LuaLaTeX. Write for both the Markdown source and the generated document.

## Audience and purpose

Write for administrators and users who understand very basic Linux concepts but
may not be familiar with Nix, NixOS, high-performance computing, or this
project.

The documentation for developers targets an audience fammiliar with linux and
already informed about nix in general.

Documentation should help readers complete a task safely and understand:

- What they are about to do
- Why the step is required
- What prerequisites apply
- What command or configuration they must use
- What result they should expect
- What risks, limitations, or recovery steps apply

Do not assume that readers know project-specific terminology or undocumented
operational details.

## Language and tone

Use clear American English. Prefer short, direct sentences and familiar words.
Use the active voice when it identifies who or what performs an action.

Address the reader as “you” in procedures. Use “we” only when referring to a
deliberate decision or activity of the project team.

Use a professional, factual, and calm tone:

- State requirements directly.
- Explain consequences without exaggeration.
- Avoid jokes, slang, rhetorical questions, and conversational filler.
- Avoid unnecessary exclamation marks.
- Do not describe a task as easy, simple, obvious, or trivial.
- Do not promise universal compatibility, security, performance, or support.
- Distinguish tested behavior from expectations and possibilities.

Use contractions sparingly. Prefer forms such as “do not” and “cannot” in
warnings and formal instructions.

## Project terminology

Use project terms consistently.

| Term                 | Usage                                                                               |
| -------------------- | ----------------------------------------------------------------------------------- |
| `small-data-cluster` | Use the lowercase, hyphenated project name. Format it as code in prose.             |
| SDC                  | Use only after the project has been identified or when the abbreviation is clearer. |
| headnode             | Always one word. There is one headnode in a cluster.                                |
| worker               | Use when the shorter role name is unambiguous.                                      |
| worker node          | Use as two words when referring to a machine or node.                               |
| worker nodes         | Use as two words in the plural. Never write “workernode” or “workernodes” in prose. |
| Nix                  | The package manager, language, or command ecosystem.                                |
| NixOS                | The operating system. Do not write “Nixos.”                                         |
| filesystem           | One word.                                                                           |
| command line         | Two words as a noun; use `command-line` as an adjective.                            |
| runtime              | One word.                                                                           |
| setup                | A noun or adjective. Use “set up” as a verb.                                        |
| internet             | Lowercase except at the beginning of a sentence.                                    |

Literal names are exempt from prose terminology rules. Preserve identifiers
exactly, including names such as `vm_workernode`, `workernode.iso`,
`awaitHeadnode`, and `packages.x86_64-linux.workernode`.

Introduce uncommon abbreviations and technical terms on first use. Do not use
different terms for the same component merely for variety.

## Headings and document structure

Use sentence case for every heading. Capitalize only the first word and proper
nouns:

```markdown
# Getting started

## Enable experimental Nix features

### On NixOS
```

Prefer task-oriented headings for procedures:

- “Build the images,” not “Building the Images”
- “Configure the flash tool,” not “Flash Tool Configuration”
- “Troubleshoot boot problems,” not “Troubleshooting Boot Problems”

Descriptive headings are appropriate for conceptual and reference material, such
as “Security considerations” or “Configuration options.”

Follow these structural rules:

- Use one level-one heading for each chapter.
- A file may begin at level two when it deliberately continues the chapter in
  the preceding file, as with split chapters.
- Do not skip heading levels.
- Use as many heading levels as the document structure requires. Do not add
  depth merely to style or emphasize a heading.
- Do not create a heading for a single short paragraph.
- Keep headings concise and unique within a rendered document.
- Do not end headings with a colon or semicolon.
- Use a question as a heading only when the section directly answers it.

Files that belong to one rendered document are processed in filename order. Use
numeric filename prefixes to make that order explicit, for example:

```text
01-welcome.md
02-prerequisites.md
03-01-getting-started.md
03-02-configuration.md
```

When splitting a chapter across files, ensure that the heading levels continue
correctly across the file boundary.

## Paragraphs and procedures

Keep paragraphs focused on one subject. Put prerequisite or explanatory
information before the instruction it affects.

Use numbered lists for ordered procedures and bullet lists for unordered sets.
Write procedural steps as complete imperative sentences:

```markdown
1. Insert the USB drive.
2. Verify the device identifier.
3. Run the flashing command.
```

Use parallel grammatical structure within a list. Include terminal punctuation
when list items are complete sentences. Short fragments may omit periods, but a
single list must use one convention consistently.

State expected results after commands when the result is not self-evident.
Explain placeholders immediately after the example in which they appear.

## Markdown conventions

Wrap ordinary prose at approximately 80 characters. Long URLs, tables, and
literal code may exceed this limit when wrapping them would damage readability
or correctness.

Use blank lines around headings, lists, block quotes, tables, and fenced code
blocks. Use spaces, not tabs, for indentation.

Use emphasis intentionally:

- Use backticks for commands, options, identifiers, filenames, paths,
  configuration keys, usernames, and short literal values.
- Use **bold** for interface labels, keys the reader must press, and short
  lead-ins that need emphasis.
- Use _italics_ for publication titles and occasional introduction of a term.
- Do not use all caps for emphasis.

Do not use inline HTML when standard Markdown can express the same result.

You can run `nix fmt` in the repo to ensure correct wrapping.

## Code, commands, and output

Use fenced code blocks and always specify the most accurate language:

````markdown
```bash
nix build .#worker
```

```bash
create-secret --user alice
```

```text
Expected unformatted output
```
````

Use:

- `bash` for Bash commands, scripts, and shell interactions
- `fish`, `nix`, `json`, `toml`, or `ini` for source or configuration in those
  languages
- `text` for paths, directory trees, messages, and unformatted output

Commands must be safe to copy. Do not include a shell prompt such as `$` unless
the prompt itself is necessary to explain an interaction. Use explicit,
descriptive placeholders in angle brackets, such as `<username>` or
`<USB_DEVICE>`, and explain them below the block.

Do not manually wrap a command in a way that changes its meaning. If a command
must span multiple lines, use syntax appropriate to its shell, such as a
trailing backslash in Bash.

Preserve literal capitalization, punctuation, and spelling in commands,
identifiers, paths, configuration keys, log messages, and quoted output.

Never put real credentials, private keys, password hashes used by an actual
deployment, or other secrets in documentation. Clearly mark example values as
examples or placeholders.

## Tables

Use tables for compact comparisons or repeated fields. Do not use a table when a
short list or sequence is easier to read.

Keep cells concise. Put the identifier or option in the first column and the
explanation in a later column. Format literal values as code.

Pandoc uses the lengths of the separator cells to calculate relative column
widths in the PDF. Allocate enough dashes to columns containing long,
nonbreaking identifiers; do not size columns merely to align the Markdown
source. For a three-column option table, start with approximately 25% for the
option, 18% for the type, and 57% for the description:

```markdown
| Option    | Type    | Description                               |
| --------- | ------- | ----------------------------------------- |
| `enabled` | Boolean | Enables or disables telemetry collection. |
```

Adjust those proportions for the longest nonbreaking value in each column. A
column containing identifiers such as `packages.x86_64-linux.vm_workernode`
needs substantially more width than a column containing `-y` or `String`.

Write descriptions as parallel phrases or sentences. Avoid embedding multiple
procedural steps, long code samples, or lists in a table cell. Wide tables must
remain readable on an A4 page; move extensive detail into prose when necessary.

## Notes, warnings, and limitations

Use block quotes with a bold label for information that must stand apart from
the surrounding text:

```markdown
> **Note:** This setting applies to all users on the build machine.

> **Important:** Rebuild every node image after changing shared credentials.

> **Warning:** Selecting the wrong device may destroy data.
```

Use labels consistently:

- **Note** for useful supplementary information
- **Advice** for a recommended practice
- **Important** for information required for success or consistency
- **Caution** for a recoverable risk or condition requiring care
- **Warning** for possible data loss, credential exposure, security compromise,
  or physical harm
- **Security warning** for security-specific consequences
- **Documentation limitation** when the guide does not yet cover a required
  topic

State the risk, its consequence, and the action that avoids or mitigates it. Do
not hide important safety information in an ordinary paragraph.

## TODOs and open work

TODOs are intentional records of unfinished documentation work. Never remove,
rewrite, soften, disguise, or convert a TODO merely to make the document appear
complete.

Preserve existing TODOs exactly unless the requested work explicitly resolves
the TODO or the project maintainer asks for it to be changed. This includes
informal open-work markers that do not contain the word `TODO`.

Add a new TODO only when work is genuinely known to be incomplete. Make it
specific enough for a future author to act on:

```markdown
**TODO:** Add instructions for generating the Tailscale authentication key.
```

Do not invent instructions, sources, results, or supported behavior to replace
missing information.

## Links, references, and cross-references

Use descriptive link text:

```markdown
[Nix installation guide](https://nixos.org/download/)
```

Do not use “click here,” a bare URL in brackets, or a raw URL when descriptive
text is available. Link to the most authoritative source, preferably official
project documentation.

Use explicit Markdown links for internal cross-references:

```markdown
[Secure Boot](#secure-boot)
```

After changing a heading, verify and update links to its generated anchor. Avoid
relying on vague references such as “above,” “below,” or “the previous page,”
because pagination can change during rendering.

Use quotations only when exact wording matters. Identify the source and do not
present paraphrased text as a quotation.

## Accuracy, security, and scope

Verify commands, paths, configuration names, package attributes, defaults, and
supported behavior against the repository before documenting them.

Clearly distinguish among:

- Required behavior
- Recommended practice
- Current implementation
- Known limitation
- Untested possibility
- Planned or open work

Use “must” for requirements, “should” for recommendations, and “may” for
permission or possibility. Avoid “will” when the result depends on hardware,
network conditions, external services, or untested configurations.

Do not expand a documented security guarantee beyond what the implementation
provides. Never imply that encryption, authentication, network isolation,
permissions, or physical controls eliminate all risk.

For destructive commands, identify the exact target and provide a warning before
the command. Prefer stable device identifiers such as `/dev/disk/by-id/` over
transient names such as `/dev/sdb` when appropriate.

## Metadata and assets

Each rendered documentation set may contain a `metadata.yaml` file. Keep its
title, subtitle, description, subject, and keywords accurate and consistent with
the document’s audience.

Place shared document assets in `docs/` and set-specific assets in the relevant
subdirectory when practical. Use descriptive filenames and meaningful alt text
for images. Do not embed an image when text, a table, or a code block
communicates the information more accessibly.

The PDF appearance is controlled centrally by:

- `docs/defaults.yaml` for Pandoc and document variables
- `docs/header.tex` for LuaLaTeX styling and behavior
- `docs/render-docs.nix` for the rendering workflow

Do not add file-specific LaTeX styling unless the shared template cannot solve
the requirement cleanly.

## Review checklist

Before considering a documentation change complete, verify that:

- The content is accurate against the current repository.
- Headings use sentence case and do not skip levels.
- The document uses `headnode`, `worker`, and `worker node` consistently.
- Commands, options, paths, and identifiers are formatted as code.
- Procedures use ordered steps and imperative language.
- Risks and destructive operations have an appropriate warning.
- Existing TODOs and open-work markers remain intact unless explicitly resolved.
- Links use descriptive text and internal anchors still work.
- Tables and code blocks fit in the rendered PDF.
- The spelling, punctuation, and list structure are consistent.
- No secrets or deployment-specific credentials appear in the change.
- `git diff --check` reports no whitespace errors.

## Build and validation

Load the documentation environment and render the documentation before
submitting substantial changes. From the repository root, use:

```bash
nix develop .#docsshell --impure
```

Then render every documentation set:

```bash
render-docs
```

To render only the administration manual:

```bash
render-docs admin
```

To avoid overwriting files in `docs/`, use a temporary output directory:

```bash
OUTPUT_ROOT=/tmp/sdc-doc-preview DOCS_ROOT=docs render-docs admin
```

Review the command output for Pandoc and LaTeX warnings. Inspect the generated
PDF, including its title page, table of contents, page breaks, links, code
blocks, tables, headers, and footers. A successful process exit alone does not
guarantee that the document is visually correct.
