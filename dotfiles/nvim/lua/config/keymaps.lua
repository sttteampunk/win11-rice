-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- The Ultimate VS Code-Style Terminal Toggle (Anchored & No Title Bar)
local function toggle_bash()
  local file_dir = vim.fn.expand("%:p:h")
  
  if file_dir == "" or vim.bo.filetype == "neo-tree" then
    file_dir = vim.fn.getcwd()
  end
  
  Snacks.terminal.toggle([["C:\Program Files\Git\bin\bash.exe"]], {
    cwd = file_dir,
    id = "my_bash_terminal", 
    win = { 
      position = "bottom",
      wo = { winbar = "" } -- THIS KILLS THE UGLY CMD.EXE TITLE BAR!
    }, 
  })
end

-- Bind it to Ctrl + /
vim.keymap.set({ "n", "t" }, "<C-/>", toggle_bash, { desc = "Toggle Git Bash" })
vim.keymap.set({ "n", "t" }, "<C-_>", toggle_bash, { desc = "which_key_ignore" })