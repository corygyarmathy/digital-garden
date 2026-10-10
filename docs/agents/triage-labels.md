# Triage Labels

The skills speak in terms of six canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Canonical role    | Label in our tracker | Meaning                                                                                         |
| ----------------- | -------------------- | ----------------------------------------------------------------------------------------------- |
| `needs-triage`    | `needs-triage`       | Maintainer needs to evaluate this issue                                                         |
| `needs-info`      | `needs-info`         | Waiting on reporter for more information                                                        |
| `ready-for-agent` | `ready-for-agent`    | Fully specified, ready for an agent to implement once someone starts one                        |
| `ready-for-human` | `ready-for-human`    | Requires human implementation                                                                   |
| `recipe-ticket`   | `recipe-ticket`      | Fully specified but deliberately large; implemented only by an explicit `/implement`, as one PR |
| `wontfix`         | `wontfix`            | Will not be actioned                                                                            |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

No unattended agent watches this tracker. `ready-for-agent` says the ticket is ready to be handed to one; it does not queue it. On `corygyarmathy/dotfiles` the same label does queue work, so it means more there than here.

`nix` is a topic label, not a triage role.

## Choosing between `ready-for-agent` and `ready-for-human`

Being fully specified is necessary but not enough: the agent also has to be able to tell whether it succeeded. Ask it of each acceptance criterion, not of the ticket as a whole:

| Shape            | What it is                                                                      | Eligible?                    |
| ---------------- | ------------------------------------------------------------------------------- | ---------------------------- |
| **Gate**         | Machine-decidable. The agent runs something and reads the result.               | Yes                          |
| **Confirmation** | A human looks _after_ the gates have passed. The work is complete without them. | Yes, if marked as not a gate |
| **Judgement**    | A human decision that shapes the work _while it is being done_.                 | No                           |

The line between the last two is when the human acts: if the agent would have to stop and wait for a person, it is a judgement.

This bites hardest on visual work, where a ticket usually has a checkable half and a visual half fused into one criterion. Reshape it before relabelling: turn the checkable half into a check that fails before the change and passes after, mark the human half in the criterion itself as a confirmation (looking at `garden-preview -- --fixture`), and use `ready-for-human` only if a judgement is still left. [dotfiles#180](https://github.com/corygyarmathy/dotfiles/issues/180) is the worked example.
