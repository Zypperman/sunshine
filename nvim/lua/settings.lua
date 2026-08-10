-- General Options
vim.opt.spell = false
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true

-- PowerShell Setup for Windows
if vim.fn.has("win32") == 1 then
	vim.opt.shell = "powershell.exe"
	vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.opt.shellquote = ""
	vim.opt.shellxquote = ""
end
