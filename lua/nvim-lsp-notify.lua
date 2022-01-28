local M = {}

local options = {
	debug = false,
	messages = {
		start = 'Initializing...',
		finish = 'Started!',
		report = 'Loading...',
	}
}

local notifications = {}

local function format_err(err)
	local err_lines = {
		'Code: '..err.code,
		'Message:',
		err.message,
		'Data:',
		vim.inspect(err.data)
	}
	return table.concat(err_lines, '\n')
end

local function show_notification(key, title, message, level)
	if notifications[key] ~= nil then
		if notifications[key].close ~= nil then
			notifications[key].close()
		end
		notifications[key] = nil
	end
	local new_notification = vim.notify(message, level, {
		title = title
	})
	if new_notification ~= nil then 
		notifications[key] = new_notification
	end
end

local function on_progress(err, msg, info)

	local key = tostring(info.client_id)
	local lsp_name = vim.lsp.get_client_by_id(info.client_id).name

	if err then
		show_notification(key, lsp_name, format_err(err), vim.log.levels.ERROR)
		return
	end
	
	if options.debug then
		show_notification(key, lsp_name, vim.inspect(msg), vim.log.levels.DEBUG)
		show_notification(key, lsp_name, vim.inspect(info), vim.log.levels.DEBUG)
	end

	local task = msg.token
	local value = msg.value

	if not task then
		return
	end
	
	if value.kind == 'begin' then
		local message = nil
		if value.title then
			message = value.title
		end
		if value.message then
			if message then
				message = message..'\n'
			end
			message = message..value.message
		end
		show_notification(key, lsp_name, message or options.messages.start, vim.log.levels.INFO)
	elseif value.kind == 'report' then
		local message = value.message or options.messages.report
		show_notification(key, lsp_name, message, vim.log.levels.INFO)
	elseif value.kind == 'end' then
		show_notification(key, lsp_name, value.message or options.messages.finish, vim.log.levels.INFO)
	else	
		if value.done then
			show_notification(key, lsp_name, value.message or options.messages.finish, vim.log.levels.INFO)
		else
			show_notification(key, lsp_name, value.message or options.messages.report, vim.log.levels.INFO)
		end
	end
end

local function is_installed()
	return vim.lsp.handlers['$/progress'] == on_progress
end

function M.setup(opts)
	options = vim.tbl_deep_extend('force', options, opts or {})
	
	if not is_installed() then
		vim.lsp.handlers['$/progress'] = on_progress
	end
end

return M
