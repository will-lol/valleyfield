{
	description = "";

	inputs = { 
		nixpkgs.url = "nixpkgs/nixos-24.05";
		flake-utils.url = "github:numtide/flake-utils";
		nix.url = "github:nixos/nix";
	};

	outputs = { self, nixpkgs, flake-utils, nix }:
		flake-utils.lib.eachDefaultSystem (system: 
			let 
				overlays = [];
				pkgs = import nixpkgs { inherit system overlays; };
				lib = import ./lib.nix { inherit pkgs; };
				
				targetPkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
				targetPkgs = import nixpkgs { inherit overlays; system = "aarch64-linux"; };
				apiHandlers = import ./lambda { inherit pkgs lib targetPkgsCross; };
				frontend = import ./frontend { inherit pkgs lib; };
				infra = import ./pipeline { inherit pkgs lib targetPkgs targetPkgsCross nix; };
				cdkGo = import ./infra { inherit pkgs; };

				buildArtifact = pkgs.runCommand "build-artifact" {} ''
					mkdir $out
					${pkgs.rsync}/bin/rsync --mkpath -a ${frontend}/lib/node_modules/frontend/dist/ $out/frontend

					${builtins.concatStringsSep "\n" (builtins.map (handler: ''
						FILENAME="$(${pkgs.findutils}/bin/find ${handler}/bin/ -mindepth 1 -printf "%f" -quit)"
						
						cp "${handler}/bin/$FILENAME" bootstrap
						mkdir -p "$out/lambda"
						${pkgs.zip}/bin/zip "$out/lambda/$FILENAME.zip" bootstrap
						rm bootstrap
					'') apiHandlers) }
				'';
			in
				{
					packages = {
						default = buildArtifact;
						artifact = buildArtifact;
						api = apiHandlers;
						frontend = frontend;
						codebuild = infra;
						cdkGo = cdkGo;
					};
					# defaultPackage = example;
					devShell = pkgs.mkShell {
						packages = with pkgs; [ go gopls nodePackages.nodejs nodePackages.typescript-language-server opentofu terraform-ls ];
						shellHook = ''
							export AWS_DEFAULT_PROFILE=Valleyfield
							set -a            
							source .env
							set +a
						'';
					};
				}
		);
}
