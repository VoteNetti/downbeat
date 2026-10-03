# New Spec

Creates a new spec document from the template and registers it in the index.

## Usage

/new-spec [slug] [short title]

Example: `/new-spec athlete-registration "Athlete Registration and Profile"`

## Steps

1. Read `specs/_index.md`. Find the highest existing spec number. Increment by 1. Zero-pad to 3 digits (e.g. 001, 002, 042).
2. Copy `specs/_template.md` to `specs/active/NNN-[slug].md` with the spec number and title filled into the header.
3. Set **Created** to today's date and **Status** to `draft`.
4. Add a new row to `specs/_index.md`: `| NNN | [title] | draft | active/NNN-[slug].md |`
5. Return the filename of the new spec. Tell the user to fill in **Seed** and **Scenarios** before build begins.

Do not pre-fill the Seed or Scenarios. Those come from the user.
