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
				
				targetPkgs = pkgs.pkgsCross.aarch64-multiplatform;
				apiHandlers = import ./lambda { inherit pkgs lib targetPkgs; };
				frontend = import ./frontend { inherit pkgs lib; };
				infra = import ./terraform/base-infra { inherit pkgs lib targetPkgs nix; };

				buildArtifact = pkgs.runCommand "build-artifact" {} ''
					mkdir $out
					${pkgs.rsync}/bin/rsync --mkpath -a ${frontend}/lib/node_modules/frontend/dist/ $out/frontend

					${builtins.concatStringsSep "\n" (builtins.map (handler: ''
						HANDLERNAME="$(echo '${handler.modulePath}' | xargs)"
						HANDLERDIR="$(echo $HANDLERNAME | sed 's/\/[^/]*$//')"
						FILENAME="$(${pkgs.findutils}/bin/find ${handler.package}/bin/ -mindepth 1 -printf "%f" -quit)"

						cp "${handler.package}/bin/$FILENAME" bootstrap
						mkdir -p "$out/lambda/$HANDLERDIR"
						${pkgs.zip}/bin/zip "$out/lambda/$HANDLERNAME.zip" bootstrap
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
					};
					# defaultPackage = example;
					devShell = pkgs.mkShell {
						packages = with pkgs; [ hugo go gopls jq zip nodejs_22 nodePackages.typescript-language-server opentofu terraform-ls ];
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
