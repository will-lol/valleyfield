{ pkgs, lib, ... }: (pkgs.buildNpmPackage rec {
	pname = "frontend";
	version = "0.0.1";
	src = ./.;
	npmDepsHash = lib.fakeHash;
  npmPackFlags = [ "--ignore-scripts" ];
})
