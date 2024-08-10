{ targetPkgsCross, ... }: targetPkgsCross.buildGoModule {
	name = "test";
	src = ./.;
	CGO_ENABLED = 0;
	vendorHash = "sha256-gl5XiZO6bpdP1jFt+gn7Vo5ssEgQiviJ2HzH+nvdlUM=";
}
