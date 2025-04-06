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

-- Таблица для хранения состояний окон
local window_data = setmetatable({}, {
  __index = function(t, winid)
    rawset(t, winid, {
      mode = "n",
      bufnr = -1,
      filename = "[No Name]",
      modified = false,
      cursor = {1, 0},
      linecount = 1
    })
    return rawget(t, winid)
  end
})

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

  vim.opt.laststatus = 2
  vim.opt.statusline = "%!v:lua.require('myline').build_statusline()"

  if M.config.suppress_messages then
    vim.opt.showmode = false
    vim.opt.shortmess:append("sIc")
  end

  -- Инициализация существующих окон
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    M.update_window_data(win)
  end

  -- Автокоманды для обновления данных
  local group = vim.api.nvim_create_augroup("StatuslineUpdater", {})
  
  vim.api.nvim_create_autocmd({"ModeChanged", "WinEnter", "BufEnter", "CursorMoved", "CursorMovedI", "BufModifiedSet"}, {
    group = group,
    callback = function(args)
      M.update_window_data(vim.api.nvim_get_current_win())
      vim.cmd("redrawstatus")
    end
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      window_data[tonumber(args.match)] = nil
    end
  })
end

function M.update_window_data(winid)
  local data = window_data[winid]
  data.mode = vim.api.nvim_get_mode().mode
  data.bufnr = vim.api.nvim_win_get_buf(winid)
  data.filename = M.get_filename(data.bufnr)
  data.modified = vim.api.nvim_buf_get_option(data.bufnr, "modified")
  data.cursor = vim.api.nvim_win_get_cursor(winid)
  data.linecount = vim.api.nvim_buf_line_count(data.bufnr)
end

function M.get_filename(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
end

function M.build_statusline()
  local winid = vim.api.nvim_get_current_win()
  local data = window_data[winid]
  
  -- Преобразование режима
  local mode_map = {
    n = "NORMAL", v = "VISUAL", V = "V-LINE", ['\22'] = "V-BLOCK",
    i = "INSERT", R = "REPLACE", c = "COMMAND", s = "SELECT", t = "TERMINAL"
  }
  local mode_text = mode_map[data.mode] or data.mode
  local mode_color = data.mode == "n" and "normal" or data.mode

  -- Форматирование блоков
  local function format_block(text, color)
    return string.format("%%#Status%s# %s %%*", color:sub(1,1):upper()..color:sub(2), text)
  end

  local mode_block = format_block(mode_text, mode_color)
  local file_block = format_block(data.filename .. (data.modified and "[+]" or ""), "file")
  local position = string.format("%d:%d/%d", data.cursor[1], data.cursor[2]+1, data.linecount)
  local position_block = string.format("%%=%%#StatusPosition# %s %%*", position)

  return table.concat({mode_block, file_block, position_block}, M.config.separator)
end

return M
