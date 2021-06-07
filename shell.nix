{ pkgs ? (import <nixpkgs> {}), ... }:

pkgs.mkShell {
  buildInputs = [
    # Install GNU Make for shorthands
    pkgs.gnumake

    # Install shellcheck
    pkgs.shellcheck

    # Install yaml lint
    pkgs.yamllint
  ];
}
