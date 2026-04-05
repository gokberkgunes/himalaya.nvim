local M = {}
M.executable = "himalaya"

function M.run(args, callback)
	-- Prepend 'env' to safely pass RUST_LOG without using a shell wrapper
	local cmd = { "env", "RUST_LOG=off", M.executable }
	for _, arg in ipairs(args) do
		table.insert(cmd, arg)
	end

	-- Run synchronously to HALT Neovim's UI thread.
	-- This guarantees mew gets Wayland focus and prevents PTY EOF hangs.
	local output = vim.fn.system(cmd)
	local code = vim.v.shell_error

	if code == 0 then
		callback(nil, output)
	else
		callback("CLI Error: " .. output, nil)
	end
end

function M.run_json(args, callback)
	M.run(args, function(err, output)
		if err then return callback(err, nil) end
		if not output or output == "" then
			return callback(nil, {})
		end

		local ok, data = pcall(vim.json.decode, output)
		if not ok then
			return callback("JSON Error: " .. tostring(data), nil)
		end

		local function clean_nil(obj)
			if type(obj) == "table" then
				for k, v in pairs(obj) do
					if v == vim.NIL then obj[k] = nil
					elseif type(v) == "table" then clean_nil(v) end
				end
			end
			return obj
		end
		callback(nil, clean_nil(data))
	end)
end

return M
