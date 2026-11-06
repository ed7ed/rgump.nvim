local core = require("rgump.core")

local M = {}

M.setup = function(opts)
  core.config = vim.tbl_deep_extend("force", core.config, opts or {})

  -- Apply close_on_first_jump to all quickfix windows if enabled
  if core.config.close_on_first_jump then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("RGumpQf", { clear = true }),
      pattern = "qf",
      callback = function(args)
        if type(core.config.close_on_first_jump) == "function" then
          core.config.close_on_first_jump(args.buf)
        else
          vim.keymap.set("n", "<CR>", "<CR><cmd>cclose<CR>", { buffer = args.buf, silent = true })
        end
      end,
    })
  end

  -- Override native LSP definition handler
  local original_handler = vim.lsp.handlers["textDocument/definition"]

  vim.lsp.handlers["textDocument/definition"] = function(err, result, ctx, config)
    -- If LSP returns valid results, use them
    if result and not vim.tbl_isempty(result) then
      if original_handler then
        return original_handler(err, result, ctx, config)
      else
        vim.notify("RGump: No original LSP handler found", vim.log.levels.WARN)
        return
      end
    end

    -- If no results or error, fallback to RGump
    local word, path, root, lnum = core.ctx(ctx.bufnr)

    if not word or word == "" then
      vim.notify("RGump: No word under cursor", vim.log.levels.WARN)
      if original_handler then
        return original_handler(err, result, ctx, config)
      end
      return
    end

    local dumb_results = core.find(word, path, root, lnum)

    if #dumb_results == 0 then
      -- Still nothing, let original handler show "No definition found" or similar
      if original_handler then
        return original_handler(err, result, ctx, config)
      end
      return
    end

    -- Convert RGump results to LSP Locations
    local lsp_locations = {}
    for _, res in ipairs(dumb_results) do
      table.insert(lsp_locations, {
        uri = vim.uri_from_fname(res.filename),
        range = {
          start = { line = res.lnum - 1, character = res.col - 1 },
          ["end"] = { line = res.lnum - 1, character = res.col - 1 },
        },
      })
    end

    -- Pass fabricated results to original handler
    if original_handler then
      return original_handler(nil, lsp_locations, ctx, config)
    end
  end

  -- Expose user command for manual jump
  vim.api.nvim_create_user_command("RGump", function()
    core.jump()
  end, {})
end

return M
