return {
  "smoka7/hop.nvim",
  version = "*",
  config = function()
    local hop = require("hop")
    
    -- Инициализация с оптимальным набором клавиш для подсказок
    hop.setup({ keys = "etovxqpdygfblzhckisuran" })

    -- Шорткаты для нормального (n) и визуального (v) режимов
    -- В качестве префикса используется <leader> (по умолчанию Пробел)

    -- 1. Прыжок к ЛЮБОМУ слову на экране
    vim.keymap.set({ "n", "v" }, "<leader>hw", function()
      hop.hint_words()
    end, { desc = "Hop to words" })

    -- 2. Прыжок по первому символу (вводите 1 букву -> прыгаете к ней)
    vim.keymap.set({ "n", "v" }, "<leader>hc", function()
      hop.hint_char1()
    end, { desc = "Hop to character" })

    -- 3. Прыжок на любую строку (очень удобно для вертикальной навигации)
    vim.keymap.set({ "n", "v" }, "<leader>hl", function()
      hop.hint_lines()
    end, { desc = "Hop to lines" })

    -- 4. Прыжок к любому символу во ВСЕМ файле (глобальный поиск-прыжок)
    vim.keymap.set({ "n", "v" }, "<leader>hs", function()
      hop.hint_patterns()
    end, { desc = "Hop by pattern/search" })

    -- 5. Замена стандартных f и F (быстрый прыжок внутри текущей строки)
    vim.keymap.set({ "n", "v" }, "f", function()
      hop.hint_char1({ direction = require("hop.hint").HintDirection.AFTER_CURSOR, current_line_only = true })
    end, { desc = "Hop forward on line" })

    vim.keymap.set({ "n", "v" }, "F", function()
      hop.hint_char1({ direction = require("hop.hint").HintDirection.BEFORE_CURSOR, current_line_only = true })
    end, { desc = "Hop backward on line" })
  end,
}
