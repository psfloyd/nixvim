{ pkgs, ... }:
{
  # Empty configuration
  empty = {
    plugins.lz-n.enable = true;
  };

  # Settings
  example = {
    plugins.lz-n = {
      enable = true;
      settings = {
        load = "vim.cmd.packadd";
      };
    };

  };

  test = {
    extraPlugins = with pkgs.vimPlugins; [
      neo-tree-nvim
      vimtex
      telescope-nvim
      nvim-biscuits
      onedarker-nvim
    ];
    plugins.treesitter.enable = true;
    plugins.lz-n = {
      enable = true;
      plugins = [
        # enabledInSpec, on keys
        {
          name = "neo-tree.nvim";
          enabledInSpec = ''
            function()
            return false
            end
          '';
          keys = [
            {
              mode = [ "n" ];
              key = "<leader>ft";
              action = "<CMD>Neotree toggle<CR>";
              options = {
                desc = "NeoTree toggle";
              };
            }
            {
              mode = [
                "n"
                "v"
              ];
              key = "gft";
              action = "<CMD>Neotree toggle<CR>";
              options = {
                desc = "NeoTree toggle";
              };
            }
          ];
          after = # lua
            ''
              function()
                require("neo-tree").setup()
              end
            '';
        }
        # beforeAll, before, on filetype
        {
          name = "vimtex";
          ft = [ "plaintex" ];
          beforeAll = # lua
            ''
              function()
                vim.g.vimtex_compiler_method = "latexrun"
              end
            '';
          before = # lua
            ''
              function()
                vim.g.vimtex_compiler_method = "latexmk"
              end
            '';
        }
        # On event
        {
          name = "nvim-biscuits";
          event = [ "BufEnter *.lua" ];
          after = ''
            function()
            require('nvim-biscuits').setup({})
            end
          '';
        }
        # On command no setup function, priority
        {
          name = "telescope.nvim";
          cmd = [ "Telescope" ];
          priority = 500;
        }
        # On colorschme
        {
          name = "onedarker.nvim";
          colorscheme = [ "onedarker" ];
        }
      ];
    };
  };

}
