{inputs, ...}: {
  imports =
    [
      ./devshell.nix
    ]
    ++ (
      if inputs.pre-commit-hooks ? flakeModule
      then [inputs.pre-commit-hooks.flakeModule]
      else []
    );

  perSystem = {
    pkgs,
    lib,
    ...
  }:
    {
      formatter = pkgs.alejandra;
    }
    // lib.optionalAttrs (inputs.pre-commit-hooks ? flakeModule) {
      pre-commit = {
        settings.hooks = {
          alejandra.enable = true;
          statix = {
            enable = true;
            excludes = [
              "plugins/lsp/language-servers/rust-analyzer-config.nix"
            ];
          };
          typos.enable = true;
        };
      };
    };
}
