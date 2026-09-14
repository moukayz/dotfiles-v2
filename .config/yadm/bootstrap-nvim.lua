local ok, err = pcall(function()
  local config = vim.fn.stdpath("config")
  local requested, normalize = {}, nil
  -- Install the actual profile's plugins and capture its own parser list.
  local pack_add = vim.pack.add
  vim.pack.add = function(specs, opts)
    local result = pack_add(specs, vim.tbl_extend("force", opts or {}, { confirm = false }))
    if not normalize then
      local ts = require("nvim-treesitter.config")
      normalize = ts.norm_languages
      ts.norm_languages = function(languages)
        requested = vim.deepcopy(languages)
        return {}
      end
    end
    return result
  end
  vim.env.MYVIMRC = config .. "/init.lua"
  dofile(vim.env.MYVIMRC)
  vim.pack.add = pack_add
  require("nvim-treesitter.config").norm_languages = normalize
  assert(#requested > 0, "Profile parser list was not captured")
  require("nvim-treesitter").install(requested):wait(300000)
  for _, lang in ipairs(requested) do
    assert(pcall(vim.treesitter.language.add, lang), "Missing or unusable parser: " .. lang)
  end
  -- A second setup verifies reload; the smoke test sources the profile again.
  dofile(vim.env.MYVIMRC)
  dofile(config .. "/tests/smoke.lua")
end)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit")
end
vim.cmd("qa!")
