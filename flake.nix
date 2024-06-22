{
	description = "";
	inputs = { 
		nixpkgs.url = "nixpkgs/nixos-24.05";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { self, nixpkgs, flake-utils }:
		flake-utils.lib.eachDefaultSystem (system: 
			let 
				overlays = [];
				lib = import ./lib.nix { inherit pkgs; };
				pkgs = import nixpkgs { inherit system overlays; };
				
				apiHandlers = import ./api { inherit pkgs lib; };
				frontend = import ./frontend { inherit pkgs lib; };

				buildArtifact = pkgs.runCommand "build-artifact" {} ''
					mkdir $out
					${pkgs.rsync}/bin/rsync --mkpath -a ${frontend}/lib/node_modules/frontend/dist/ $out/frontend

					${builtins.concatStringsSep "\n" (builtins.map (handler: ''
							HANDLERNAME="$(echo '${handler.modulePath}' | xargs)"
							HANDLERDIR="$(echo $HANDLERNAME | sed 's/\/[^/]*$//')"
							FILENAME="$(${pkgs.findutils}/bin/find ${handler.package}/bin/linux_arm64/ -mindepth 1 -printf "%f" -quit)"

							cp "${handler.package}/bin/linux_arm64/$FILENAME" bootstrap
							mkdir -p "$out/api/$HANDLERDIR"
							${pkgs.zip}/bin/zip "$out/api/$HANDLERNAME.zip" bootstrap
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
