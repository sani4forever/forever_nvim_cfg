require("config.lazy")

-- Сопоставление типов файлов (объединено и очищено от дубликатов)
vim.filetype.add({
    extension = {
        tf = "terraform",
        tfvars = "terraform", -- lspconfig и treesitter лучше понимают стандартный "terraform"
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
    },
})

-- Направляем кастомные подтипы файлов в базовый Treesitter-парсер YAML
vim.treesitter.language.register("yaml", "yaml.ansible")
vim.treesitter.language.register("yaml", "yaml.docker-compose")
vim.treesitter.language.register("yaml", "yaml.gitlab")

-- Автокоманда для Ansible-плейбуков
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*/playbooks/*.yml", "*/playbooks/*.yaml", "site.yml", "main.yml" },
    callback = function()
        vim.bo.filetype = "yaml.ansible"
    end,
})

-- Регистрация нестандартных и составных типов файлов
vim.filetype.add({
    extension = {
        tfvars = "terraform-vars",
        tf = "terraform",
    },
    pattern = {
        -- Если имя файла values.yaml или он лежит в папке templates/ -> это Helm
        ["values%.yaml"] = "yaml.helm-values",
        [".*/templates/.*%.yaml"] = "yaml.helm-values",
        [".*/templates/.*%.tpl"] = "yaml.helm-values",
    },
})

-- Прокидываем кастомные подтипы в базовые парсеры Treesitter для правильной подсветки
vim.treesitter.language.register("hcl", "terraform-vars")
vim.treesitter.language.register("yaml", "yaml.helm-values")

vim.opt.clipboard = "unnamedplus"
