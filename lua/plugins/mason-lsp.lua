return {
    -- 1. Движок автодополнения и его источники
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
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<Esc>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.abort()
                        else
                            fallback()
                        end
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

    -- 2. Менеджер внешних пакетов Mason
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },

    -- 3. Настройка интеграции Neovim с LSP серверами
    {
        "neovim/nvim-lspconfig",
        config = function()
            -- Только DevOps инструменты
            local servers = {
                "dockerls",         -- Dockerfile
                "docker_compose_language_service", -- Docker Compose
                "ansiblels",        -- Ansible
                "terraformls",      -- Terraform (.tf файлы)
                "yamlls",           -- Общий YAML (K8s, CI/CD)
                "bashls",           -- Баш-скрипты
                "lua_ls",           -- Для редактирования конфигов самого Neovim
            }

            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            for _, server in ipairs(servers) do
                local configs = { capabilities = capabilities }

                -- Чтобы yamlls не ругался на отсутствие схем в кастомных YAML
                if server == "yamlls" then
                    configs.settings = {
                        yaml = {
                            validate = true,
                            schemaStore = { enable = true },
                        },
                    }
                end

                -- Чтобы lua_ls знал про глобальный объект vim
                if server == "lua_ls" then
                    configs.settings = {
                        Lua = {
                            diagnostics = { globals = { "vim" } },
                            workspace = {
                                library = vim.api.nvim_get_runtime_file("", true),
                                checkThirdParty = false,
                            },
                            telemetry = { enable = false },
                        },
                    }
                end

                vim.lsp.config(server, configs)
                vim.lsp.enable(server)
            end

            -- Горячие клавиши для работы в файлах
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    local opts = { buffer = args.buf }
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)       -- Прыгнуть к определению
                    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)             -- Документация под курсором
                    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)   -- Переименовать
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts) -- Быстрые исправления ошибок

                    -- Подсветка одинаковых слов в файле при наведении
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.server_capabilities.documentHighlightProvider then
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = args.buf,
                            callback = vim.lsp.buf.document_highlight,
                        })
                        vim.api.nvim_create_autocmd({ "CursorMoved" }, {
                            buffer = args.buf,
                            callback = vim.lsp.buf.clear_references,
                        })
                    end
                end,
            })
        end,
    }
}
