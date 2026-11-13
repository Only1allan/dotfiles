-- Odyssey debug session.
--
-- The real configuration lives in the project, at debug/nvim/odyssey-dap.lua, so one project's
-- inspector ports do not leak into this config. This stub loads it when nvim is opened inside
-- that repo, and adds the three keymaps LazyVim's dap extra does not provide.
--
-- Everything else comes from the extras in lazyvim.json:
--   dap.core         nvim-dap, dap-ui, virtual text, mason-nvim-dap, the <leader>d* keymaps
--   lang.typescript  vtsls, and the js-debug-adapter + pwa-node registration
--   lang.sql         vim-dadbod + dadbod-ui, <leader>D

local function project()
  local root = vim.fs.root(vim.uv.cwd() or ".", { "pnpm-lock.yaml", ".git" })
  if not root then
    return nil
  end
  if vim.fn.isdirectory(root .. "/debug/nvim") == 0 then
    return nil
  end
  return root
end

local function load(name)
  local root = project()
  if not root then
    return nil
  end
  local chunk = loadfile(root .. "/debug/nvim/" .. name .. ".lua")
  if not chunk then
    return nil
  end
  local ok, mod = pcall(chunk)
  return ok and mod or nil
end

-- :Trace / :TraceQf / :TraceClear are registered here, at startup, rather than from the
-- nvim-dap hook below -- reading the trace streams has nothing to do with having a debugger
-- attached, and is often the FIRST thing you want after a run.
do
  local trace = load("trace")
  if trace then
    trace.setup()
  end
end

return {
  -- The sql extra adds `sqlfluff` to Mason's ensure_installed, but it is a pip package and
  -- there is no pip3 on PATH -- so it fails on every startup. It is a SQL linter/formatter,
  -- which this session does not need: debug/probes.sql is read and executed, never linted.
  -- Drop it so startup stays quiet. Remove this block if you ever want SQL linting.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(pkg)
        return pkg ~= "sqlfluff"
      end, opts.ensure_installed or {})
      return opts
    end,
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    -- stylua: ignore
    keys = {
      -- The headline. A logpoint prints an interpolated message -- `setDue {enrollmentId} -> {at}`
      -- -- WITHOUT editing a file and WITHOUT restarting the process. It is gdb's dprintf, and it
      -- is the whole console.log session done from the editor against a running worker.
      { "<leader>dL", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end, desc = "Log Point" },
      { "<leader>dN", function() local m = load("odyssey-dap"); if m then m.pick() else vim.notify("not in the Odyssey project", vim.log.levels.WARN) end end, desc = "Attach to Odyssey process" },
      -- F-keys: the tmux config binds many prefix-less M-* and C-M-* combos, but leaves the
      -- F-row alone, so muscle memory from every other debugger works here.
      { "<F5>",  function() require("dap").continue() end,  desc = "Debug: Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end,  desc = "Debug: Step Out" },
    },
    -- `opts`, not `config`. lazy.nvim merges `keys` across duplicate specs but NOT `config` --
    -- defining one here would silently replace LazyVim's dap.core config (signs, highlights,
    -- launch.json decoding). `opts` functions chain, each receiving the previous result, which
    -- is the slot LazyVim's own extras use as a side-effecting hook.
    --
    -- lua/plugins is imported after lazyvim.plugins (see config/lazy.lua), so this runs after
    -- lang.typescript has registered the pwa-node adapter and its generic configs -- which is
    -- what lets M.setup() prepend the Odyssey entries above them.
    opts = function(_, opts)
      local dap = load("odyssey-dap")
      if dap then
        dap.setup()
      end
      return opts
    end,
  },
}
