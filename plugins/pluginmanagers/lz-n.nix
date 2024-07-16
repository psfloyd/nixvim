{
  lib,
  helpers,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption;
  inherit (helpers)
    mkNullOrLuaFn'
    nixvimTypes
    keymaps
    defaultNullOpts
    ;

  name = "lz-n";
  originalName = "lz.n";

  mkLazyLoadOption =
    {
      originalName ? "this plugin",
    }:
    let
      pluginDefault = {
        name = originalName;
      };
    in
    mkOption {
      description = "Lazy-load settings for ${originalName}.";
      type =
        with nixvimTypes;
        submodule {
          options = with defaultNullOpts; {
            name = mkOption {
              type = str;
              default = pluginDefault.name;
              description = "The plugin's name (not the module name). This is what is passed to the load(name) function.";
            };
            enabledInSpec = mkStrLuaFnOr bool pluginDefault.enabledInSpec or null ''
              When false, or if the function returns false, then ${originalName} will not be included in the spec.
              This option corresponds to the `enabled` property of lz.n.
            '';
            beforeAll = mkLuaFn pluginDefault.beforeAll
              or null "Always executed before any plugins are loaded.";
            before = mkLuaFn pluginDefault.before or null "Executed before ${originalName} is loaded.";
            after = mkLuaFn pluginDefault.after or null "Executed after ${originalName} is loaded.";
            event =
              mkNullable (listOf str) pluginDefault.event or null
                "Lazy-load on event. Events can be specified as BufEnter or with a pattern like BufEnter *.lua";
            cmd = mkNullable (listOf str) pluginDefault.cmd or null "Lazy-load on command.";
            ft = mkNullable (listOf str) pluginDefault.ft or null "Lazy-load on filetype.";
            keys = mkNullable (listOf keymaps.mapOptionSubmodule) pluginDefault.keys
              or null "Lazy-load on key mapping. Use the same format as `config.keymaps`.";
            colorscheme = mkNullable (listOf str) pluginDefault.colorscheme or null "Lazy-load on colorscheme.";
            priority = mkNullable number pluginDefault.priority or null ''
              Only useful for start plugins (not lazy-loaded) to force loading certain plugins first. 
              Default priority is 50 (or 1000 if colorscheme is set).
            '';
            load = mkLuaFn pluginDefault.load
              or null "Can be used to override the vim.g.lz_n.load() function for ${originalName}.";
          };
        };
      default = pluginDefault;
    };
in
with lib;
helpers.neovim-plugin.mkNeovimPlugin config {
  inherit name originalName;
  maintainers = with helpers.maintainers; [ psfloyd ];
  defaultPackage = pkgs.vimPlugins.lz-n;

  settingsDescription = ''
    The configuration options for **${originalName}** using `vim.g.lz_n`.

    `{ load = "fun"; }` -> `vim.g.lz_n = { load = fun, }`
  '';

  settingsOptions = {
    load = mkNullOrLuaFn' {
      description = ''
        Function used by `lz.n` to load plugins.
      '';
      default = null;
      pluginDefault = "vim.cmd.packadd";
    };
  };

  settingsExample = {
    load = "vim.cmd.packadd";
  };

  callSetup = false; # Does not use setup

  extraOptions = with nixvimTypes; {
    plugins = mkOption {
      description = "List of plugins processed by lz.n";
      default = [ ];
      type = listOf (mkLazyLoadOption { }).type;
    };
  };

  extraConfig = cfg: {
    globals.lz_n = cfg.settings;
    extraConfigLua =
      let
        processKeymap =
          keymaps:
          if keymaps == null then
            null
          else
            map (
              keymap:
              {
                __unkeyed_1 = keymap.key;
                __unkeyed_2 = keymap.action;
                inherit (keymap) mode;
              }
              // keymap.options
            ) keymaps;
        pluginToLua = plugin: {
          "__unkeyed" = plugin.name;
          inherit (plugin)
            beforeAll
            before
            after
            event
            cmd
            ft
            colorscheme
            priority
            load
            ;
          enabled = plugin.enabledInSpec;
          keys = processKeymap plugin.keys;
        };
        pluginListToLua = map pluginToLua;
        plugins = pluginListToLua cfg.plugins;
        pluginSpecs = if length plugins == 1 then head plugins else plugins;
      in
      mkIf (cfg.plugins != [ ]) ''
        require('lz.n').load(
            ${helpers.toLuaObject pluginSpecs}
        )
      '';
  };
}
