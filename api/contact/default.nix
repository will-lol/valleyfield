{ pkgs, lib, ... }: ((pkgs.buildGoModule {
	name = "test";
	src = ./.;
	CGO_ENABLED = 0;
	vendorHash = null;
}).overrideAttrs (old: old // {GOOS = "linux"; GOARCH = "arm64";}))
