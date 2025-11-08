# m40fuscation

## What at is m40fuscation and how does it work?

This is a small Lua helper/loader used to **package** and **decompile** an obfuscated string representation of a Lua script.

* The source includes two important things: `obf_string` and `rev_mapping`.

  * `obf_string` is a sequence of tokens like `~01~02~03...` representing the original characters in order.
  * `rev_mapping` is a table that maps each token (e.g. `"~01"`) back to the original character.
* If `obf_string`/`rev_mapping` are missing or invalid, the script can **generate** them from a plaintext `src` and print / copy a pasteable block you can drop into other files.

Author / License / Repo notes are preserved from the original: `Author: sinsly`, `License: MIT`, `Github: https://github.com/sinsly`.

---

## How it works (high-level)

1. **Sanity check**: `has_valid_obf()` checks whether `obf_string` looks like a real obfuscated payload (string type, non-empty, length divisible by 3) and `rev_mapping` is a table.

2. **Generate**: If the check fails, `generate_from_src(src)` will:

   * Walk the plaintext `src` string, collect unique characters in the order they appear.
   * Assign tokens `~01`, `~02`, ... to each unique character.
   * Build `obf_string` by replacing each character in `src` with its token and build `rev_mapping` where the token points back to the character.

3. **Pasteable block**: `build_pasteable_block(obf, rev)` formats a ready-to-paste Lua snippet (with the comment header, `obf_string = "..."`, and `rev_mapping = {...}`) and prints it. Optionally attempts to copy it to clipboard using `setclipboard` or `syn.set_clipboard` where available.

4. **Decompile**: `decompile_to_string()` reads `obf_string` token-by-token (3 chars each: `~` + two hex digits), looks up each token in `rev_mapping`, and reconstructs the original plaintext. Unknown tokens are inserted as `<UNKNOWN:~XX>` placeholders to aid debugging.

5. **Execute**: `run_decompiled()` loads the reconstructed string as Lua code (via `load` or `loadstring`) and `pcall`s it. The script prints useful status messages along the way.

---

## Usage (quick)

1. Put your original script inside `src = [[ ... ]]` (or set `src` to a string).
2. Run this file in a Lua environment that supports `load`/`loadstring`.
3. If `obf_string`/`rev_mapping` are missing or invalid, the tool generates them and prints a pasteable block you can copy into another file.
4. To test decompilation, include `obf_string`/`rev_mapping` and run — the script attempts to decompile and `pcall` the resulting chunk.

Notes:

* The token format is fixed-length (3 chars: tilde + two hex digits), so the script uses `#obf_string % 3 == 0` as a quick sanity check.
* When decompiling, unknown tokens become `<UNKNOWN:~XX>` so you can spot missing mappings.

---

## Example (short)

1. Plain `src`:

```lua
local src = [[
print('hi this test worked')
]]
```

2. Run script -> it will emit something like:

```lua
obf_string = "~01~02~03..."
rev_mapping = {
  ["~01"] = "p",
  ["~02"] = "r",
  ...
}
```

3. Paste that into a loader file that uses `decompile_to_string()` to reconstruct + run.

---

## Final notes

This is intentionally simple. It's meant as a small conversion helper: build an obfuscated tokenized string + reverse table, copy/paste it around, and optionally reconstruct and run it.
