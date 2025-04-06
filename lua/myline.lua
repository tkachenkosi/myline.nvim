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

-- Таблица для хранения состояния каждого окна
local window_states = {}

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

  -- Инициализация состояний для существующих окон
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    M.update_window_state(win)
  end

  -- Установка автокоманд
  M.setup_autocommands()
end

-- Обновление состояния конкретного окна
function M.update_window_state(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  
  window_states[winid] = {
    mode = vim.api.nvim_get_mode().mode,
    bufnr = bufnr,
    filename = M.get_buffer_name(bufnr),
    modified = vim.api.nvim_buf_get_option(bufnr, "modified"),
    cursor = vim.api.nvim_win_get_cursor(winid),
    linecount = vim.api.nvim_buf_line_count(bufnr)
  }
end

-- Получение имени буфера
function M.get_buffer_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
end

-- Форматирование блока с цветами
local function format_block(text, color)
  return string.format("%%#Status%s# %s %%*", color:gsub("^%l", string.upper), text)
end

-- Основная функция построения статусной строки
function M.statusline()
  local winid = vim.api.nvim_get_current_win()
  local state = window_states[winid] or {}
  
  -- Получаем информацию для текущего окна
  local mode = state.mode or "n"
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
  local mode_text = modes[mode] or mode
  local mode_key = mode
  
  local filename = state.filename or "[No Name]"
  local modified = state.modified and "[+]" or ""
  
  local line = state.cursor and state.cursor[1] or 1
  local col = state.cursor and (state.cursor[2] + 1) or 1
  local total_lines = state.linecount or 1
  local position = string.format("%d:%d/%d", line, col, total_lines)
  
  -- Формируем блоки
  local mode_block = format_block(mode_text, mode_key)
  local file_block = format_block(filename .. modified, "file")
  local position_block = string.format("%%=%%#StatusPosition# %s %%*", position)
  
  -- Собираем статусную строку
  return table.concat({
    mode_block,
    file_block,
    position_block
  }, M.config.separator)
end

-- Установка автокоманд для отслеживания изменений
function M.setup_autocommands()
  local group = vim.api.nvim_create_augroup("Statusline", { clear = true })

  -- Обновление при изменении режима
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win == vim.api.nvim_get_current_win() then
          M.update_window_state(win)
        end
      end
      vim.cmd("redrawstatus")
    end
  })

  -- Обновление при переключении окон
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      M.update_window_state(vim.api.nvim_get_current_win())
      vim.cmd("redrawstatus")
    end
  })

  -- Обновление при изменении буфера
  vim.api.nvim_create_autocmd({"BufEnter", "BufModifiedSet"}, {
    group = group,
    callback = function()
      M.update_window_state(vim.api.nvim_get_current_win())
      vim.cmd("redrawstatus")
    end
  })

  -- Обновление при перемещении курсора
  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
    group = group,
    callback = function()
      M.update_window_state(vim.api.nvim_get_current_win())
      vim.cmd("redrawstatus")
    end
  })

  -- Очистка при закрытии окна
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      window_states[tonumber(args.match)] = nil
    end
  })
end

return M
