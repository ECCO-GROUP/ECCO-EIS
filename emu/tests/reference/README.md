# EMU 1.2a reference examples

`answers/` holds the canned answers that `emu/misc_test_indiv.sh` feeds to
`emu.sh` (and, for example 7, to helper scripts) through heredocs. One file
per heredoc, byte-for-byte identical to the script. Blank lines are
answers too (pressing ENTER to accept a default).

| # | Tool | Example | Answer file(s) |
|---|------|---------|----------------|
| 1 | samp | Monthly-mean ocean bottom pressure at the North Pole relative to its global mean | `1_samp.answers` |
| 2 | fgrd | Forward gradient of the 1992 state with respect to eastward wind at 180E 0N in week 5 | `2_fgrd.answers` |
| 3 | adj  | Adjoint gradient of example 1 for month 6 (June 1992) | `3_adj.answers` |
| 4 | conv | Convolution of V4r4 forcing with example 3's adjoint gradients (needs example 3's output) | `4_conv.answers` |
| 5 | trc  | Tracer released from the top 10 m at 180E 0N on day 30, run for 396 days | `5_trc.answers` |
| 6 | budg | Temperature budget of the top 10 m of the Nino3.4 region | `6_budg.answers` |
| 7 | msim | Modified simulation with time-mean wind stress (1-year run) | `7_msim.misc_msim_data.answers`, `7_msim.misc_msim_forcing_oceTAUX.answers`, `7_msim.misc_msim_forcing_oceTAUY.answers`, then `7_msim.answers` |
| 8 | atrb | Attribution of example 1's temporal changes (needs example 1's output) | `8_atrb.answers` |

The answers belong to the **EMU 1.2a** prompts (git tag `v1.2a`). If a
prompt is added, removed or reordered, update both `misc_test_indiv.sh` and
the matching answer file. `python/tests/test_reference_answers.py` checks
that the two stay identical.

Reference outputs from running these examples with 1.2a on penguin
(nproc=48) are recorded separately (see the `emu_claude` project,
`docs/reference/`). Outputs are kept on the shared EMU disk, not in git.
