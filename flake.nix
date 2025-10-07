{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.mcrl2
        (pkgs.writeShellScriptBin "mcrl2" ''
          QT_QPA_PLATFORM=xcb ${pkgs.mcrl2}/bin/mcrl2ide
        '')
        (pkgs.writeShellScriptBin "wayland-start" ''
          QT_QPA_PLATFORM=xcb $1
        '')
      ];
    };
  };
}
