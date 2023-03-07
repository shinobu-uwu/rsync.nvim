local M = {}

M.config = nil

function M.setup()
	M.load_config()
	vim.api.nvim_create_user_command("RsyncCurrentFile", M.deploy, {})
	vim.api.nvim_create_user_command("RsyncReloadConfig", M.load_config, {})
end

function M.load_config()
	local f = io.open(vim.fn.getcwd() .. "/.mapping.json", "r")

	if f == nil then
		print("Couldn't find .mapping.json")
		return
	end

	M.config = vim.json.decode(f:read("*all"))
	f:close()
end

local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

function M.deploy()
	local os = require("os")

	if M.config.password == nil then
		M.config.password = vim.fn.input("Insert your password: ")
	end

	local current_file = vim.fn.expand("%:p")

	if deploy_path == nil then
		for local_path, remote_path in pairs(M.config.mapping) do
			print(local_path)
			print(remote_path)
			print(current_file)

			if string.match(current_file, local_path) ~= nil then
				local deploy_path = current_file:gsub(local_path, M.config.root_path .. remote_path)
				print(deploy_path)
				local command = string.format(
					"sshpass -p %s rsync --mkpath -rvz -e 'ssh -p %s' %s %s@%s:%s",
					M.config.password,
					M.config.port,
					current_file,
					M.config.user,
					M.config.ip,
					deploy_path
				)

				local result = os.execute(command)
				print("File uploaded to" .. deploy_path)
				return
			end
		end
		print("Can't find mapping")
	end
end

return M
