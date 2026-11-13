-- Clipboard for WSL and remote sessions.
--
-- Inside tmux: use tmux's buffer as the clipboard provider. tmux is configured
-- with `set-clipboard on`, so `load-buffer -w` also updates the outer terminal
-- clipboard (Windows Terminal via OSC 52), and `save-buffer -` reads whatever
-- tmux last copied.
--
-- Outside tmux on WSL: use clip.exe / powershell.exe, which talk to the Windows
-- clipboard directly.
--
-- Anywhere else (SSH): fall back to OSC 52 for copy and to Neovim's own
-- register for paste, because most terminals do not implement OSC 52 reads.
local M = {}

local function tmux_provider()
  local copy = { "tmux", "load-buffer", "-w", "-" }
  local paste = { "tmux", "save-buffer", "-" }
  vim.g.clipboard = {
    name = "tmux",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = 0,
  }
end

local function wsl_provider()
  local copy = { "clip.exe" }
  local paste = { "powershell.exe", "-NoLogo", "-NoProfile", "-Command", "Get-Clipboard" }
  vim.g.clipboard = {
    name = "WSL",
    copy = { ["+"] = copy, ["*"] = copy },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = 0,
  }
end

local function osc52_provider()
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste_own(register)
    return function()
      return vim.split(vim.fn.getreg(register), "\n")
    end
  end
  vim.g.clipboard = {
    name = "OSC52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste_own("+"), ["*"] = paste_own("*") },
    cache_enabled = 0,
  }
end

function M.setup()
  if vim.env.TMUX ~= nil then
    tmux_provider()
    return
  end

  if vim.fn.executable("clip.exe") == 1 then
    wsl_provider()
    return
  end

  if vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil then
    osc52_provider()
  end
end

return M
