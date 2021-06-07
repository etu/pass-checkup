{ pkgs ? (import <nixpkgs> {}), ... }:

pkgs.mkShell {
  buildInputs = [
    # Install GNU Make for shorthands
    pkgs.gnumake

    # Install yaml lint
    pkgs.yamllint
  ];
}
