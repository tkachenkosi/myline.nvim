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

		-- Добавляем цвета для выделения текста
		-- nil означает использовать тему по умолчанию
    visual_hl = { bg = nil, fg = nil }
  },
  separator = " ",
	suppress_messages = true
}

M.config = vim.deepcopy(defaults) -- Инициализируем config с дефолтными значениями

-- Инициализация плагина
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Устанавливаем highlight группы
  for group, colors in pairs(M.config.colors) do
		if not (group == "visual_hl" and colors.bg == nil and colors.fg == nil) then
			vim.api.nvim_set_hl(0, group, {
				fg = colors.fg,
				bg = colors.bg,
				bold = true
			})
		end
  end

	-- Восстанавливаем цвета выделения, если они не заданы
  if M.config.colors.visual_hl.bg == nil and M.config.colors.visual_hl.fg == nil then
    vim.cmd('hi link Visual Visual')
  else
    vim.api.nvim_set_hl(0, 'Visual', {
      fg = M.config.colors.visual_hl.fg,
      bg = M.config.colors.visual_hl.bg
    })
  end

  vim.opt.statusline = "%!v:lua.require('myline').build()"
  vim.opt.laststatus = 2

	-- Подавление системных сообщений
  if M.config.suppress_messages then
    vim.opt.showmode = false       -- Скрыть -- INSERT -- и подобные
    vim.opt.shortmess:append("s")  -- Скрыть сообщения о поиске
    vim.opt.shortmess:append("I")  -- Отключить вступительное сообщение
    vim.opt.shortmess:append("c")  -- Скрыть сообщения дополнения
  end
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

	-- Блок файла (используем буфер текущего окна)
  local buf = vim.api.nvim_win_get_buf(0)
  local filename = vim.api.nvim_buf_get_name(buf)
  filename = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "[No Name]"
  local modified = vim.api.nvim_buf_get_option(buf, "modified") and "[+]" or ""
  local file_block = format_block(filename .. modified, "file")

  -- Блок позиции (для текущего окна)
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local total_lines = vim.fn.line("$")
  local position_text = string.format("%d:%d/%d", line, col, total_lines)
  local position_block = string.format("%%=%%#position# %s %%*", position_text)

	-- Собираем статусную строку
  return table.concat({ mode_block, file_block, position_block }, M.config.separator)
end

return M
