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
  
  -- Устанавливаем highlight группы
  for group, colors in pairs(M.config.colors) do
    vim.api.nvim_set_hl(0, "Status"..group:gsub("^%l", string.upper), {
      fg = colors.fg,
      bg = colors.bg,
      bold = true
    })
  end
  
  -- Настройка статусной строки
  vim.opt.laststatus = 2
  vim.opt.statusline = "%!v:lua.require('myline').statusline()"
  
  -- Подавление системных сообщений
  if M.config.suppress_messages then
    vim.opt.showmode = false
    vim.opt.shortmess:append("sIc")
  end
end

-- Получение информации о буфере
local function get_buffer_info(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  filename = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"
  local modified = vim.api.nvim_buf_get_option(bufnr, "modified") and "+" or ""
  return filename, modified
end

-- Получение информации о позиции для конкретного окна
local function get_position_info(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local line = vim.api.nvim_win_get_cursor(winid)[1]
  local col = vim.api.nvim_win_get_cursor(winid)[2] + 1
  local total_lines = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(winid))
  return string.format("%d:%d/%d", line, col, total_lines)
end

-- Получение режима для конкретного окна
local function get_window_mode(winid)
  -- Для получения режима конкретного окна используем глобальную переменную
  -- которая обновляется через autocommand
  local mode = vim.w[winid].statusline_mode or "n"
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
  -- Получаем ID окна, для которого строится статусная строка
  local winid = tonumber(vim.g.actual_curwin) or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  
  -- Получаем информацию для конкретного окна/буфера
  local mode, mode_key = get_window_mode(winid)
  local filename, modified = get_buffer_info(bufnr)
  local position = get_position_info(winid)
  
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

-- Autocommands для отслеживания изменений
local function setup_autocommands()
  vim.api.nvim_create_autocmd({"ModeChanged", "WinEnter", "BufEnter", "CursorMoved"}, {
    callback = function()
      -- Сохраняем текущий режим для всех окон
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local mode = vim.api.nvim_get_mode().mode
          vim.w[win].statusline_mode = mode
        end
      end
      -- Устанавливаем глобальную переменную с текущим окном
      vim.g.actual_curwin = vim.api.nvim_get_current_win()
      vim.cmd("redrawstatus")
    end
  })
end

-- Инициализация autocommands при загрузке
setup_autocommands()

return M
