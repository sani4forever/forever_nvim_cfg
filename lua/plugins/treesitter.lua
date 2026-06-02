return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  priority = 1000,
  build = ":TSUpdate",
  config = function()
    -- 1. Сворачивание (Folds)
    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt.foldenable = false

    -- Настройка новой директории под парсеры (для совместимости с v0.12+)
    require('nvim-treesitter').setup {
      install_dir = vim.fn.stdpath('data') .. '/site'
    }

    -- 2. Настройка парсеров
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if ok then
      configs.setup({
        ensure_installed = {
          "lua", "markdown", "markdown_inline",
          "bash", "dockerfile", "python", "yaml"
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      })
    end

    -- 3. УНИВЕРСАЛЬНЫЙ ФИКС ИНЖЕКШЕНОВ
    local function fix_all_injections()
      local docker_fix = [[
        ((run_instruction (shell_command (shell_fragment) @injection.content))
        (#set! injection.language "bash"))
      ]]
      pcall(vim.treesitter.query.set, "dockerfile", "injections", docker_fix)
    end

    -- Вызываем фикс один раз при загрузке
    fix_all_injections()

    vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
      callback = function(args)
        local bufnr = args.buf
        local ft = vim.bo[bufnr].filetype

        if ft == "" or ft == "lazy" then return end

        -- Применяем фикс Dockerfile
        if ft == "dockerfile" or ft == "markdown" then
          fix_all_injections()
        end

        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(bufnr) then
            vim.bo[bufnr].syntax = ""
            local lang = vim.treesitter.language.get_lang(ft) or ft
            pcall(vim.treesitter.start, bufnr, lang)
          end
        end)
      end,
    })
  end,
}
