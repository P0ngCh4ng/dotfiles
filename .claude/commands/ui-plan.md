# ui-plan

## Purpose

This command analyzes your existing UI implementation (for any framework or platform) in order to:

- Understand the current screen structure and user flows
- Discover potential feature additions, page transitions, and new actions (buttons, links, menus)
- Convert those ideas into an implementation-ready task list

It is intentionally **stack-agnostic**.  
You can use it with HTML, component-based frameworks, server-side rendering, mobile UI definitions, and more  
(e.g. React, Vue, Svelte, Next.js, Nuxt, Blade/EJS templates, native/mobile UI).

---

## Usage Example

### Simple invocation

/ui-plan

### With a scoped request

/ui-plan "Focus only on the learner management screens and propose additional UI actions"

Additional instructions you can give to Claude:

- First, scan the project for files that define screens, pages, components, or navigation, and output a list of them.
- Include not only raw UI code but also routing/navigation definitions wherever possible.

---

## Tasks

This command asks Claude to perform the following steps:

1. Collect UI / screens

   - Identify files in the project related to screens, pages, components, and navigation.
   - Output a list of existing screens with their file paths and rough descriptions.
   - Do not assume a specific framework; just describe what each file represents.

2. Summarize each screen

   For each screen, provide a short summary with:

   - The main purpose of the screen (what the user is trying to accomplish here)
   - Key information and components visible on the screen
   - Existing user actions (buttons, links, forms, menus, etc.)

3. Map user flows

   - Infer typical user flows, such as:  
     list → detail → create/edit → confirmation → back to list.
   - Use routing definitions, links, buttons, and navigation elements to describe several main flows in plain language.

4. Generate UI improvement and feature ideas

   For each screen and flow, list potential improvements such as:

   - Missing actions (e.g. view details, edit, delete, export, filter, search)
   - Missing transitions (e.g. shortcuts from list to create, “back to list” navigation, links to related resources)
   - UX issues (e.g. dead-end screens, hard-to-return paths, inconsistent labels)

   Prefer extending **existing** screens over creating entirely new ones.  
   Only propose new screens when clearly necessary.

5. Confirm with the user

   - Group ideas into:
     - High-priority (strongly recommended)
     - Nice-to-have (optional, lower priority)
   - Ask the user which ideas should move forward to implementation.
   - Only selected ideas should be converted into concrete tasks.

6. Produce an implementation task list

   - For the selected ideas, produce a task list that can be handed to a human developer or other commands (like /multi-plan or /multi-frontend).
   - Keep the task descriptions as stack-agnostic as possible, focusing on UI behavior and intent, for example:
     - “Add a ‘Details’ button at the end of each row in the learner list table, navigating to the corresponding detail screen.”
     - “Add a status dropdown filter at the top of the list screen.”
   - If it is helpful to assume a specific technology (React, Vue, native mobile, etc.), explicitly mention that assumption in the task.

---

## Output

### Expected final output

1. Screen list with brief descriptions

   - A table or list including: screen name, file path, and role.

2. Main user flows in text form

   - Example: “Learner list → learner detail → edit → save → back to list”.

3. UI improvement and feature ideas

   - A structured list grouped by screen / flow.
   - Include priority (high / medium / low) and type (new action, new transition, new information, etc.).

4. Implementation-ready task list

   - A checklist-style list that other commands or developers can use directly, e.g.:

     - [ ] Add a “Details” button to each row in the learner list table, navigating to `/students/:id`.
     - [ ] Add a “Back to list” button in the header of the detail screen.
     - [ ] Add a “Status” dropdown filter above the learner list table.

The output should be ready to paste into /plan, /multi-plan, /multi-frontend, or similar implementation-focused commands.
