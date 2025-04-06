local M = {}

-- Конфигурация по умолчанию
local defaults = {
  colors = {
    normal = { bg = "#3c3836", fg = "#ebdbb2" },
    visual = { bg = "#3c3836", fg = "#fabd2f" },
    insert = { bg = "#3c3836", fg = "#83a598" },
    replace = { bg = "#3c3836", fg = "#fb4934" },
    command = { bg = "#3c3836", fg = "#8ec07c" },
    file = { bg = "#504945", fg = "#ebdbb2" },
    modified = { bg = "#504945", fg = "#fb4934" },
    position = { bg = "#665c54", fg = "#ebdbb2" },
    separator = { bg = "#1d2021", fg = "#665c54" } -- Цвет для разделителя
  },
  separator = " ",
  suppress_messages = true,
  active_only = true -- Показывать статус только в активном окне
}

M.config = vim.deepcopy(defaults)

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Установка highlight групп
  for group, colors in pairs(M.config.colors) do
    vim.api.nvim_set_hl(0, "Status"..group:sub(1,1):upper()..group:sub(2), {
      fg = colors.fg,
      bg = colors.bg,
      bold = true
    })
  end

  -- Highlight для разделителя
  vim.api.nvim_set_hl(0, "StatusSeparator", {
    fg = M.config.colors.separator.fg,
    bg = M.config.colors.separator.bg
  })

  vim.opt.laststatus = 2
  vim.opt.statusline = "%!v:lua.require('myline').build_statusline()"

  if M.config.suppress_messages then
    vim.opt.showmode = false
    vim.opt.shortmess:append("sIc")
  end

  -- Автокоманда для обновления при смене активного окна
  vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {
    callback = function()
      vim.cmd("redrawstatus")
    end
  })
end

function M.build_statusline()
  local is_active = vim.api.nvim_get_current_win() == vim.api.nvim_tabpage_get_win(0)

  if not is_active and M.config.active_only then
    -- Для неактивных окон - только разделитель
    return "%#StatusSeparator#%=%*"
  end

  -- Для активного окна - полная статусная строка
  local mode = vim.api.nvim_get_mode().mode
  local mode_map = {
    n = "NORMAL", v = "VISUAL", V = "V-LINE", ['\22'] = "V-BLOCK",
    i = "INSERT", R = "REPLACE", c = "COMMAND", s = "SELECT", t = "TERMINAL"
  }
  local mode_text = mode_map[mode] or mode
  local mode_color = mode == "n" and "normal" or mode

  local filename = vim.fn.expand("%:t")
  if filename == "" then filename = "[No Name]" end
  local modified = vim.bo.modified and "[+]" or ""

  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local total_lines = vim.fn.line("$")

  -- Форматирование блоков
  local function format_block(text, color)
    return string.format("%%#Status%s# %s %%*", color:sub(1,1):upper()..color:sub(2), text)
  end

  local mode_block = format_block(mode_text, mode_color)
  local file_block = format_block(filename .. modified, "file")
  local position_block = string.format("%%=%%#StatusPosition# %d:%d/%d %%*", line, col, total_lines)

  return table.concat({mode_block, file_block, position_block}, M.config.separator)
end

return M
