{ targetPkgsCross, ... }: targetPkgsCross.buildGoModule {
	name = "test";
	src = ./.;
	CGO_ENABLED = 0;
	vendorHash = null;
}
