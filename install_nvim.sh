#!/bin/bash

# Останавливать скрипт при любых ошибках
set -e

echo "=== 1. Обновление пакетного менеджера и установка базовых системных утилит ==="
sudo apt update
sudo apt install -y curl git build-essential ripgrep wl-clipboard unzip nodejs npm

echo "=== 2. Скачивание и чистая установка Neovim v0.12.2 из GitHub бинарников ==="
# Удаляем старые следы, если они были
sudo rm -rf /opt/nvim-linux-x86_64 /usr/local/bin/nvim
# Скачиваем архив напрямую из релизов Neovim
curl -LO https://github.com/neovim/neovim/releases/download/v0.12.2/nvim-linux-x86_64.tar.gz
# Распаковываем в /opt
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm nvim-linux-x86_64.tar.gz
# Создаем глобальный симлинк
sudo ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

echo "=== 3. Установка Rust и Cargo ==="
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Cargo уже установлен."
fi

echo "=== 4. Установка cargo-binstall ==="
if ! cargo binstall --version &> /dev/null; then
    echo "Установка cargo-binstall через cargo install..."
    cargo install cargo-binstall --locked
else
    echo "cargo-binstall уже установлен."
fi

echo "=== 5. Установка tree-sitter-cli через cargo binstall ==="
cargo binstall -y tree-sitter-cli

echo "=== 6. Создание структуры директорий конфигурации Neovim ==="
mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins

echo "=== 7. Генерация файлов конфигурации ==="

# --- 7.1 INIT.LUA ---
cat << 'EOF' > ~/.config/nvim/init.lua
require("config.lazy")

vim.filetype.add({
    extension = {
        tf = "terraform",
        tfvars = "terraform-vars",
    },
    filename = {
        ["Dockerfile"] = "dockerfile",
        ["docker-compose.yml"] = "yaml.docker-compose",
        ["docker-compose.yaml"] = "yaml.docker-compose",
        ["compose.yml"] = "yaml.docker-compose",
        ["compose.yaml"] = "yaml.docker-compose",
    },
    pattern = {
        [".*/defaults/.*%.yml"] = "yaml.ansible",
        [".*/tasks/.*%.yml"] = "yaml.ansible",
        [".*/playbooks/.*%.yml"] = "yaml.ansible",
        [".*gitlab-ci%.yml"] = "yaml.gitlab",
        ["values%.yaml"] = "yaml.helm-values",
        [".*/templates/.*%.yaml"] = "yaml.helm-values",
        [".*/templates/.*%.tpl"] = "yaml.helm-values",
    },
})

vim.treesitter.language.register("yaml", "yaml.ansible")
vim.treesitter.language.register("yaml", "yaml.docker-compose")
vim.treesitter.language.register("yaml", "yaml.gitlab")
vim.treesitter.language.register("yaml", "yaml.helm-values")
vim.treesitter.language.register("hcl", "terraform-vars")

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*/playbooks/*.yml", "*/playbooks/*.yaml", "site.yml", "main.yml" },
    callback = function()
        vim.bo.filetype = "yaml.ansible"
    end,
})

vim.opt.clipboard = "unnamedplus"
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
EOF
echo "[OK] Создан: init.lua"


# --- 7.2 LUA/CONFIG/LAZY.LUA ---
cat << 'EOF' > ~/.config/nvim/lua/config/lazy.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})
EOF
echo "[OK] Создан: lua/config/lazy.lua"


# --- 7.3 LUA/PLUGINS/HOP.LUA ---
cat << 'EOF' > ~/.config/nvim/lua/plugins/hop.lua
return {
  "smoka7/hop.nvim",
  version = "*",
  config = function()
    local hop = require("hop")
    hop.setup({ keys = "etovxqpdygfblzhckisuran" })

    vim.keymap.set({ "n", "v" }, "<leader>hw", function() hop.hint_words() end, { desc = "Hop to words" })
    vim.keymap.set({ "n", "v" }, "<leader>hc", function() hop.hint_char1() end, { desc = "Hop to character" })
    vim.keymap.set({ "n", "v" }, "<leader>hl", function() hop.hint_lines() end, { desc = "Hop to lines" })
    vim.keymap.set({ "n", "v" }, "<leader>hs", function() hop.hint_patterns() end, { desc = "Hop by pattern/search" })
    vim.keymap.set({ "n", "v" }, "f", function() hop.hint_char1({ direction = require("hop.hint").HintDirection.AFTER_CURSOR, current_line_only = true }) end, { desc = "Hop forward on line" })
    vim.keymap.set({ "n", "v" }, "F", function() hop.hint_char1({ direction = require("hop.hint").HintDirection.BEFORE_CURSOR, current_line_only = true }) end, { desc = "Hop backward on line" })
  end,
}
EOF
echo "[OK] Создан: lua/plugins/hop.lua"


# --- 7.4 LUA/PLUGINS/TREESITTER.LUA ---
cat << 'EOF' > ~/.config/nvim/lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  priority = 1000,
  build = ":TSUpdate",
  config = function()
    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt.foldenable = false

    require('nvim-treesitter').setup {
      install_dir = vim.fn.stdpath('data') .. '/site'
    }

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

    local function fix_all_injections()
      local docker_fix = [[
        ((run_instruction (shell_command (shell_fragment) @injection.content))
        (#set! injection.language "bash"))
      ]]
      pcall(vim.treesitter.query.set, "dockerfile", "injections", docker_fix)
    end

    fix_all_injections()

    vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
      callback = function(args)
        local bufnr = args.buf
        local ft = vim.bo[bufnr].filetype
        if ft == "" or ft == "lazy" then return end
        if ft == "dockerfile" or ft == "markdown" then fix_all_injections() end

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
EOF
echo "[OK] Создан: lua/plugins/treesitter.lua"


# --- 7.5 LUA/PLUGINS/MASON-LSP.LUA ---
cat << 'EOF' > ~/.config/nvim/lua/plugins/mason-lsp.lua
return {
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args) require("luasnip").lsp_expand(args.body) end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<Esc>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.abort() else fallback() end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },
    {
        "williamboman/mason.nvim",
        config = function() require("mason").setup() end,
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local servers = {
                "dockerls", "docker_compose_language_service",
                "ansiblels", "terraformls", "yamlls", "bashls", "lua_ls"
            }
            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            for _, server in ipairs(servers) do
                local configs = { capabilities = capabilities }
                if server == "yamlls" then
                    configs.settings = { yaml = { validate = true, schemaStore = { enable = true } } }
                end
                if server == "lua_ls" then
                    configs.settings = {
                        Lua = {
                            diagnostics = { globals = { "vim" } },
                            workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
                            telemetry = { enable = false },
                        },
                    }
                end
                vim.lsp.config(server, configs)
                vim.lsp.enable(server)
            end

            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    local opts = { buffer = args.buf }
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)

                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.server_capabilities.documentHighlightProvider then
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, { buffer = args.buf, callback = vim.lsp.buf.document_highlight })
                        vim.api.nvim_create_autocmd({ "CursorMoved" }, { buffer = args.buf, callback = vim.lsp.buf.clear_references })
                    end
                end,
            })
        end,
    }
}
EOF
echo "[OK] Создан: lua/plugins/mason-lsp.lua"

echo "=== 8. Скачивание плагинов из GitHub через lazy.nvim ==="
# Просто подгружаем плагины, чтобы Neovim знал команды :Mason и :TSInstall
nvim --headless "+Lazy! sync" +qa

echo "=========================================================="
echo "Установка базовой конфигурации успешно завершена!"
echo "1. Путь к Neovim: $(which nvim)"
echo "2. Настройка путей Cargo: source ~/.cargo/env"
echo "3. Зайди в Neovim и накати нужные серверы / подсветки вручную."
echo "=========================================================="
