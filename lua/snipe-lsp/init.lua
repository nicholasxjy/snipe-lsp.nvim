local function get_document_symbols()
	local params = { textDocument = vim.lsp.util.make_text_document_params() }
	local symbols = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
	if not symbols or vim.tbl_isempty(symbols) then
		vim.notify("No symbols found", vim.log.levels.INFO)
		return {}
	end
	local items = {}
	for _, result in pairs(symbols) do
		for _, symbol in ipairs(result.result or {}) do
			table.insert(items, {
				name = symbol.name,
				kind = vim.lsp.protocol.SymbolKind[symbol.kind] or "Unknown",
				range = symbol.range,
			})
		end
	end
	return items
end

--- get the position of a given symbol
--- @param symbol table
--- @param buf number
--- @return table
local function get_symbol_pos(symbol, buf)
	local range = symbol.range
	local line_count = vim.api.nvim_buf_line_count(buf)
	local start_line = math.min(range.start.line + 1, line_count)
	local line_length = #vim.api.nvim_buf_get_lines(buf, start_line - 1, start_line, false)[1] or 0
	local start_char = math.min(range.start.character, line_length)
	return { start_line, start_char }
end

---icons used within our display format
local kind_icons = {
	Array = " ",
	Boolean = "󰨙 ",
	Class = " ",
	Codeium = "󰘦 ",
	Color = " ",
	Control = " ",
	Collapsed = " ",
	Constant = "󰏿 ",
	Constructor = " ",
	Copilot = " ",
	Enum = " ",
	EnumMember = " ",
	Event = " ",
	Field = " ",
	File = " ",
	Folder = " ",
	Function = "󰊕 ",
	Interface = " ",
	Key = " ",
	Keyword = " ",
	Method = "󰊕 ",
	Module = " ",
	Namespace = "󰦮 ",
	Null = " ",
	Number = "󰎠 ",
	Object = " ",
	Operator = " ",
	Package = " ",
	Property = " ",
	Reference = " ",
	Snippet = " ",
	String = " ",
	Struct = "󰆼 ",
	Supermaven = " ",
	TabNine = "󰏚 ",
	Text = " ",
	TypeParameter = " ",
	Unit = " ",
	Value = " ",
	Variable = "󰀫 ",
}

---format a symbol for display within the menu window
---@param symbol any
---@return string
local function format_symbol_for_display(symbol)
	return string.format("%s %s", kind_icons[symbol.kind] or "-", symbol.name)
end

local Menu = require("snipe.menu")

---open the symbols menu and navigate to the selected symbol
local function open_symbols_menu()
	local symbols = get_document_symbols()
	if vim.tbl_isempty(symbols) then
		return
	end

	local main_buf = vim.api.nvim_get_current_buf()
	local main_win = vim.api.nvim_get_current_win()

	local menu = Menu:new({ position = "cursor", open_win_override = { title = "LSP Document Symbols" } })

	-- exit
	menu:add_new_buffer_callback(function(m)
		vim.keymap.set("n", "<esc>", function()
			m:close()
		end, { nowait = true, buffer = m.buf })

		vim.keymap.set("n", "<cr>", function()
			local hovered = m:hovered()
			m:close()
			print(m.items[hovered])
			local pos = get_symbol_pos(m.items[hovered], main_buf)
			vim.api.nvim_win_set_cursor(main_win, { pos[1], pos[2] })
		end, { nowait = true, buffer = m.buf })
	end)

	menu:open(symbols, function(m, i)
		local pos = get_symbol_pos(symbols[i], main_buf)
		vim.api.nvim_win_set_cursor(main_win, { pos[1], pos[2] })
		m:close()
	end, format_symbol_for_display)
end

return {
	setup = function()
		vim.keymap.set("n", "<leader>n", open_symbols_menu, { desc = "Navigate LSP Symbols" })
	end,
}
