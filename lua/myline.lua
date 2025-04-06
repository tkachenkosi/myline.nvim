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
  separator = " ",
  suppress_messages = true
}

M.config = vim.deepcopy(defaults)

-- Инициализация плагина
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  
  -- Устанавливаем только наши highlight группы
  for group, colors in pairs(M.config.colors) do
    if not string.match(group, "_hl$") then -- Пропускаем группы для выделения
      vim.api.nvim_set_hl(0, "Status"..group:gsub("^%l", string.upper), {
        fg = colors.fg,
        bg = colors.bg,
        bold = true
      })
    end
  end
  
  -- Настройка статусной строки
  vim.opt.laststatus = 2
  vim.opt.statusline = "%!v:lua.require('myline').statusline()"
  
  -- Подавление системных сообщений
  if M.config.suppress_messages then
    vim.opt.showmode = false
    vim.opt.shortmess:append("sIc")
  end
  
  -- Автокоманда для обновления статуса при смене буфера
  vim.api.nvim_create_autocmd({"BufEnter", "ModeChanged", "CursorMoved"}, {
    callback = function()
      vim.cmd("redrawstatus")
    end
  })
end

-- Получение информации о текущем буфере
local function get_buffer_info(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"
  local modified = vim.api.nvim_buf_get_option(bufnr, "modified") and "[+]" or ""
  return filename, modified
end

-- Получение информации о позиции
local function get_position_info()
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local total_lines = vim.fn.line("$")
  return string.format("%d:%d/%d", line, col, total_lines)
end

-- Получение текущего режима для конкретного окна
local function get_window_mode(winid)
  winid = winid or vim.api.nvim_get_current_win()
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
  return modes[mode] or mode, mode
end

-- Форматирование блока с цветами
local function format_block(text, color)
  return string.format("%%#Status%s# %s %%*", color:gsub("^%l", string.upper), text)
end

-- Основная функция построения статусной строки
function M.statusline()
  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  
  -- Получаем информацию для текущего окна/буфера
  local mode, mode_key = get_window_mode(winid)
  local filename, modified = get_buffer_info(bufnr)
  local position = get_position_info()
  
  -- Формируем блоки
  local mode_block = format_block(mode, mode_key)
  local file_block = format_block(filename .. modified, "file")
  local position_block = string.format("%%=%%#StatusPosition# %s %%*", position)
  
  -- Собираем статусную строку
  return table.concat({
    mode_block,
    file_block,
    position_block
  }, M.config.separator)
end

return M
