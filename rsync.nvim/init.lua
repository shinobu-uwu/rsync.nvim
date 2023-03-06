local M = {}

M.config = nil

function M.setup()
	vim.api.nvim_create_user_command("UploadFile", M.deploy, { n_args = 0 })
end

function M.deploy()
	local os = require("os")
	M.config = require(vim.fn.getcwd() .. "/.mapping.lua")

	if M.config == nil then
		print("No config file provided")
		return
	end

	if M.config.password == nil then
		M.config.password = vim.fn.input("Insert your password: ")
	end

	local current_file = vim.fn.expand("%:p")

	for _, value in pairs(config.mapping) do
		if string.match(current_file, value.local_path) then
			local deploy_path = current_file:gsub(value.local_path, config.root_path .. value.remote_path)
			local command = string.format(
				"sshpass -p %s rsync -rvz -e 'ssh -p %s' %s %s@%s:%s",
				M.config.password,
				M.config.port,
				M.current_file,
				M.config.user,
				M.config.ip,
				deploy_path
			)

			os.execute(command)
			print("File uploaded to" .. deploy_path)
			return
		end
	end
	print("Can't find mapping")
end

return M
