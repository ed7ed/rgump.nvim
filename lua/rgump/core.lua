local rules_def = require("rgump.rules")

local M = {}

local function default_close(qf_buf)
  vim.keymap.set("n", "<CR>", "<CR><cmd>cclose<CR>", { buffer = qf_buf, silent = true })
end

local function default_on_list(results, word)
  if #results == 0 then
    vim.notify("RGump: No definitions found for " .. (word or ""), vim.log.levels.WARN)
    return
  elseif #results == 1 then
    local r = results[1]
    vim.cmd("edit " .. vim.fn.fnameescape(r.filename))
    vim.api.nvim_win_set_cursor(0, { r.lnum, r.col - 1 })
  else
    local qfl = {}
    for _, r in ipairs(results) do
      table.insert(qfl, {
        filename = r.filename,
        lnum = r.lnum,
        col = r.col,
        text = r.text,
      })
    end
    vim.fn.setqflist(qfl, "r")
    vim.cmd("copen")

    if type(M.config.close_on_first_jump) == "function" then
      M.config.close_on_first_jump(vim.api.nvim_get_current_buf())
    elseif M.config.close_on_first_jump then
      default_close(vim.api.nvim_get_current_buf())
    end
  end
end

M.config = {
  close_on_first_jump = default_close,
  on_list = default_on_list,
}

local function get_lang(path)
  local ext = vim.fn.fnamemodify(path, ":e")
  local lang = rules_def.filetypes[ext]
  if not lang then
    local filename = vim.fn.fnamemodify(path, ":t")
    lang = rules_def.filetypes[filename]
  end
  return lang, ext
end

local function is_comment(line, lang)
  local prefixes = rules_def.comments and rules_def.comments[lang]
  if not prefixes then
    return false
  end

  -- trim leading whitespace
  local trimmed = line:match("^%s*(.-)$")
  for _, prefix in ipairs(prefixes) do
    if vim.startswith(trimmed, prefix) then
      return true
    end
  end
  return false
end

local function rg(re, path, root, rgtype, lang)
  local cmd = {
    "rg",
    "--line-number",
    "--column",
    "--color=never",
    "--no-heading",
    "--pcre2",
    "-t",
    rgtype,
    re,
    root,
  }

  local obj = vim.system(cmd, { text = true }):wait()
  if obj.code == 0 and obj.stdout then
    local results = {}
    for line in obj.stdout:gmatch("[^\r\n]+") do
      local file, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
      if file and lnum and col then
        -- filter out results that are inside comments
        if not is_comment(text, lang) then
          table.insert(results, {
            filename = file,
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = text,
          })
        end
      end
    end
    return results
  end
  return {}
end

local function ts_ctx(lang)
  local ok, ts = pcall(require, "vim.treesitter")
  if not ok then
    return nil
  end

  local ok_node, node = pcall(ts.get_node)
  if not ok_node or not node then
    return nil
  end

  local ts_rules = rules_def.treesitter and rules_def.treesitter[lang]
  if not ts_rules then
    return nil
  end

  local ntype = node:type()
  local parent = node:parent()
  local ptype = parent and parent:type() or ""

  for _, ts_rule in ipairs(ts_rules) do
    if ts_rule.node and ts_rule.node == ntype then
      return ts_rule.type
    end
    if ts_rule.parent and ts_rule.parent == ptype then
      return ts_rule.type
    end
  end

  return nil
end

function M.find(word, path, root, lnum)
  local lang = get_lang(path)
  if not lang then
    return {}
  end

  local rules = rules_def.rules[lang]
  if not rules then
    return {}
  end

  local tsc = ts_ctx(lang)
  local out = {}

  local req_abs = vim.fn.fnamemodify(path, ":p")

  local esc_w = word:gsub("([^%w])", "\\%1"):gsub("%%", "%%%%")
  local ext = vim.fn.fnamemodify(path, ":e")
  local rgtype = rules_def.rgtypes[ext] or lang

  for _, rule in ipairs(rules) do
    if not tsc or tsc == rule.type then
      local re = rule.regex:gsub("JJJ", esc_w):gsub("\\j", "($|[^a-zA-Z0-9\\?\\*-])")
      local results = rg(re, path, root, rgtype, lang)
      for _, r in ipairs(results) do
        local res_abs = vim.fn.fnamemodify(r.filename, ":p")
        if not (res_abs == req_abs and r.lnum == lnum) then
          table.insert(out, r)
        end
      end
    end
  end

  return out
end

function M.ctx(bufnr, win)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  win = win or vim.api.nvim_get_current_win()

  local path = vim.api.nvim_buf_get_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local word = vim.fn.expand("<cword>")
  local root = vim.fn.getcwd()

  return word, path, root, cursor[1]
end

function M.jump()
  local word, path, root, lnum = M.ctx()

  if not word or word == "" then
    vim.notify("RGump: No word under cursor", vim.log.levels.WARN)
    return
  end

  local results = M.find(word, path, root, lnum)

  if M.config.on_list then
    M.config.on_list(results, word)
  else
    default_on_list(results, word)
  end
end

return M
