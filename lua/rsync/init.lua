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

function M.deploy(file_path)
	local os = require("os")

	if M.config.password == nil then
		M.config.password = vim.fn.input("Insert your password: ")
	end

	local current_file = vim.fn.expand("%:p")

	for _, mapping in pairs(M.config.mapping) do
		if string.match(current_file, mapping.local_path) ~= nil then
			local deploy_path = current_file:gsub(mapping.local_path, M.config.root_path .. mapping.remote_path)
			local deploy_dir = deploy_path:gsub("(.*/).*", "%1")
			local mkdir_command = string.format(
				"sshpass -p %s ssh -p %s %s@%s mkdir -p %s > /dev/null",
				M.config.password,
				M.config.port,
				M.config.user,
				M.config.ip,
				deploy_dir
			)
			local command = string.format(
				"sshpass -p %s rsync -rz -e 'ssh -p %s' %s %s@%s:%s > /dev/null",
				M.config.password,
				M.config.port,
				current_file,
				M.config.user,
				M.config.ip,
				deploy_path
			)

			os.execute(mkdir_command)
			os.execute(command)
			print("File uploaded to" .. deploy_path)
			return
		end
		print("Can't find mapping")
	end
end

return M
