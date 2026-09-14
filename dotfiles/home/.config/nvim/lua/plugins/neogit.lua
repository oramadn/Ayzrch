return {
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("neogit").setup({
                disable_builtin_notifications = false,
                graph_style = "unicode",
                integrations = {
                    diffview = true,
                    telescope = true,
                },
            })

            vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<CR>", { desc = "Show Neogit UI" })
        end,
    },
}
