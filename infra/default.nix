{ pkgs, ... } : pkgs.buildGoModule {
	name = "cdkapp";
	src = ./.;
	CGO_ENABLED = 0;
	vendorHash = "sha256-NDxcoQABmxrfMEAzavgiRIEdq6dP+dXba4ITzWPyg6g=";
}
