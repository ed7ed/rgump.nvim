# dumb-jump.nvim (POC)

A Neovim port of the Emacs `dumb-jump` package. It provides "jump to definition" functionality for programming languages using regex-based search with `rg`.

## Installation

This is an initial POC and is installed locally in your Neovim config at:
`~/.config/nvim/pack/dumb-jump/start/dumb-jump.nvim`

## Usage

**Method 1: Native LSP Fallback (Recommended)**
Add the following to your `init.lua` to override the native LSP handler. If LSP fails to find a definition, `dumb-jump.nvim` will automatically take over!

```lua
require("dumb-jump").setup()
```

Now, just use your normal jump to definition mapping (e.g. `gd` or `<C-]>` mapped to `vim.lsp.buf.definition()`).

**Method 2: Manual Trigger**
You can also run the command manually:
```vim
:DumbJump
```

## Supported Languages (POC)
- Elixir
- Erlang
