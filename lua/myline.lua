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

    position = { bg = "#665c54", fg = "#ebdbb2" }
  },
  separator = " "
}

-- Инициализация плагина
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", defaults, opts)

  vim.opt.statusline = "%!v:lua.require('myline').build()"
  vim.opt.laststatus = 2
end

-- Форматирование блока с цветами
local function format_block(text, color)
  return string.format("%%#%s# %s %%*", color, text)
end

-- Получение текущего режима
local function get_mode()
  local mode = vim.api.nvim_get_mode().mode
  local modes = {
    n = "NORMAL",
    v = "VISUAL",
    V = "V-LINE",
    ['\22'] = "V-BLOCK",
    i = "INSERT",
    R = "REPLACE",
    c = "COMMAND",
    s = "SELECT",
    t = "TERMINAL"
  }
  return modes[mode] or mode
end

-- Сборка статусной строки
function M.build()
  local mode = get_mode()
  local mode_color = mode:lower()

  -- Блок режима
  local mode_block = format_block(mode, mode_color)

  -- Блок файла
  local filename = vim.fn.expand("%:t")
  if filename == "" then filename = "[No Name]" end
  local modified = vim.bo.modified and "[+]" or ""
  local file_block = format_block(filename .. modified, "file")

  -- Блок позиции
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local total_lines = vim.fn.line("$")
  local position_block = format_block(string.format("%d:%d/%d", line, col, total_lines), "position")

  return table.concat({ mode_block, file_block, position_block }, M.config.separator)
end

-- Определяем highlight группы
function M.setup_highlights()
  for group, colors in pairs(M.config.colors) do
    vim.api.nvim_set_hl(0, group, {
      fg = colors.fg,
      bg = colors.bg,
      bold = true
    })
  end
end

-- Вызываем setup_highlights при инициализации
M.setup_highlights()

return M
