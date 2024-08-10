{ pkgs, ... } : pkgs.buildGoModule {
	name = "cdkapp";
	src = ./.;
	CGO_ENABLED = 0;
	vendorHash = "sha256-wFJJaKopcICdIW51Lhno5z0nhI930YNtIxkC2akGyvg=";
}
