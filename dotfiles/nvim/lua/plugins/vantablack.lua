return {
  -- 1. Base Setup & The Assassination of Tokyonight
  { "LazyVim/LazyVim", opts = { colorscheme = "habamax" } },
  { "folke/tokyonight.nvim", enabled = false },
  { "scottmckendry/cyberdream.nvim", enabled = false },

  -- 2. THE VANTABLACK ENFORCER + TRANSPARENCY
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("transparent").setup({
        extra_groups = {
          "NormalFloat",
          "FloatBorder",
          "NeoTreeNormal",
          "NeoTreeNormalNC",
          "TelescopeNormal",
          "TelescopeBorder",
          "WhichKeyFloat",
          "WhichKeyNormal",
          "SnacksDashboardNormal",
        },
        exclude_groups = {},
      })

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          local hl = function(group, opts)
            vim.api.nvim_set_hl(0, group, opts)
          end

          -- CORE UI
          hl("Normal", { fg = "#E5E7EB" })
          hl("FloatBorder", { fg = "#555659" })
          hl("LineNr", { fg = "#47474A" })
          hl("CursorLineNr", { fg = "#E5E7EB", bold = true })
          hl("Directory", { fg = "#E5E7EB", bold = true })
          hl("Title", { fg = "#E5E7EB", bold = true })

          -- THE NEW HIGHLIGHTS
          hl("Visual", { bg = "#2C2C32" }) -- Your custom selection highlight
          hl("MatchParen", { fg = "#FFFFFF", bg = "NONE", bold = true }) -- Your custom bracket highlight

          -- BASE SYNTAX (Kills neon bleed everywhere)
          hl("Comment", { fg = "#555659", italic = true })
          hl("String", { fg = "#9B9DA0" })
          hl("Number", { fg = "#B0B1B5" })
          hl("Boolean", { fg = "#B0B1B5" })
          hl("Function", { fg = "#D2D3D7" })
          hl("Keyword", { fg = "#BDBFC3" })
          hl("Statement", { fg = "#BDBFC3" })
          hl("Type", { fg = "#A9AAAE" })
          hl("Identifier", { fg = "#87888C" })
          hl("Constant", { fg = "#B0B1B5" })
          hl("Operator", { fg = "#6C6D70" })
          hl("Special", { fg = "#A9AAAE" })
          hl("PreProc", { fg = "#BDBFC3" })
          hl("Error", { fg = "#98999D", bold = true })
          hl("WarningMsg", { fg = "#BBBDC1" })
          hl("MoreMsg", { fg = "#E5E7EB" })

          -- SNACKS DASHBOARD OVERRIDES
          hl("SnacksDashboardHeader", { fg = "#D2D3D7" })
          hl("SnacksDashboardDesc", { fg = "#A9AAAE" })
          hl("SnacksDashboardIcon", { fg = "#87888C" })
          hl("SnacksDashboardKey", { fg = "#BDBFC3", bold = true })
          hl("SnacksDashboardFooter", { fg = "#555659" })
          hl("SnacksDashboardDir", { fg = "#555659" })

          -- WHICH-KEY OVERRIDES
          hl("WhichKey", { fg = "#E5E7EB" })
          hl("WhichKeyGroup", { fg = "#BDBFC3" })
          hl("WhichKeyDesc", { fg = "#87888C" })
          hl("WhichKeySeparator", { fg = "#47474A" })
          hl("WhichKeyIcon", { fg = "#555659" })

          -- NEO-TREE OVERRIDES
          hl("NeoTreeFileName", { fg = "#E5E7EB" })
          hl("NeoTreeRootName", { fg = "#BDBFC3", bold = true })
          hl("NeoTreeDirName", { fg = "#A9AAAE" })
          hl("NeoTreeGitAdded", { fg = "#B0B1B5" })
          hl("NeoTreeGitModified", { fg = "#87888C" })
          hl("NeoTreeGitDeleted", { fg = "#555659" })

          -- SAFE BACKGROUND CLEARING (Using foolproof Vimscript)
          vim.cmd([[
            hi NormalFloat guibg=NONE ctermbg=NONE
            hi FloatBorder guibg=NONE ctermbg=NONE
            hi CursorLine guibg=NONE ctermbg=NONE
            hi SignColumn guibg=NONE ctermbg=NONE
            hi NeoTreeNormal guibg=NONE ctermbg=NONE
            hi NeoTreeNormalNC guibg=NONE ctermbg=NONE
            hi StatusLine guibg=NONE ctermbg=NONE
            hi StatusLineNC guibg=NONE ctermbg=NONE
            hi WinSeparator guibg=NONE ctermbg=NONE guifg=#47474A
            hi VertSplit guibg=NONE ctermbg=NONE guifg=#47474A
            ]])
        end,
      })

      -- Trigger the autocmd above
      vim.cmd([[colorscheme habamax]])
    end,
  },

  -- 3. KILL ICON COLORS
  {
    "nvim-mini/mini.icons",
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.cmd([[
            hi! link MiniIconsAzure Normal
            hi! link MiniIconsBlue Normal
            hi! link MiniIconsCyan Normal
            hi! link MiniIconsGreen Normal
            hi! link MiniIconsGrey Normal
            hi! link MiniIconsOrange Normal
            hi! link MiniIconsPurple Normal
            hi! link MiniIconsRed Normal
            hi! link MiniIconsYellow Normal
          ]])
        end,
      })
    end,
  },

  -- 4. LUALINE (Grayscale)
  -- 4. LUALINE (LazyVim Defaults + Vantablack Monochrome)
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local colors = {
        void = "NONE", -- Keeps the middle section transparent
        solid_bg = "#18181B", -- Used for the text color on light blocks
        fg = "#E5E7EB", -- Bright text / Light block
        dark_grey = "#18181B", -- Secondary block
        muted = "#555659", -- Inactive text
      }

      -- We ONLY inject the theme. By NOT overriding opts.sections or
      -- opts.options.separators, LazyVim keeps all its default goodies!
      opts.options.theme = {
        normal = {
          a = { bg = colors.fg, fg = colors.solid_bg, gui = "bold" },
          b = { bg = colors.dark_grey, fg = colors.fg },
          c = { bg = colors.void, fg = colors.fg },
        },
        insert = {
          a = { bg = colors.solid_bg, fg = colors.fg, gui = "bold" },
          b = { bg = colors.dark_grey, fg = colors.fg },
          c = { bg = colors.void, fg = colors.fg },
        },
        visual = {
          a = { bg = colors.muted, fg = colors.fg, gui = "bold" },
          b = { bg = colors.dark_grey, fg = colors.fg },
          c = { bg = colors.void, fg = colors.fg },
        },
        command = {
          a = { bg = colors.dark_grey, fg = colors.fg, gui = "bold" },
          b = { bg = colors.dark_grey, fg = colors.fg },
          c = { bg = colors.void, fg = colors.fg },
        },
        inactive = {
          a = { bg = colors.void, fg = colors.muted, gui = "bold" },
          b = { bg = colors.void, fg = colors.muted },
          c = { bg = colors.void, fg = colors.muted },
        },
      }
    end,
  },
}
