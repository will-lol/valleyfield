{ pkgs, lib, ... }: (pkgs.buildNpmPackage rec {
  pname = "frontend";
  version = "0.0.1";
  src = ./.;
  npmDepsHash = "sha256-ZD73j8YOK10RJ/DoAr9ECXBEao4nQrE9hHkVBFeKo+0=";
  npmPackFlags = [ "--ignore-scripts" ];
})
