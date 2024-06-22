{
	description = "";
	inputs = { 
		nixpkgs.url = "nixpkgs/nixos-24.05";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { self, nixpkgs, flake-utils, }:
		flake-utils.lib.eachDefaultSystem (system: 
			let 
				overlays = [];
				lib = nixpkgs.lib;
				pkgs = import nixpkgs { inherit system overlays; };
				
				apiHandlers = import ./api;
				frontend = import ./frontend;
				buildArtifact = pkgs.runCommand "build-artifact" {} ''
					mkdir $out
					${pkgs.rsync}/bin/rsync -a ${frontend} $out/frontend
					${builtins.concatStringsSep "\n" (builtins.map (handler: "${pkgs.rsync}/bin/rsync -a ${handler}/bin/linux_arm64 $out/api/$(${pkgs.findutils}/bin/find ${handler}/bin/linux_arm64/ -mindepth 1 -printf \"%f\" -quit)") apiHandlers) }
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
						packages = with pkgs; [ hugo go gopls jq zip bun nodePackages.typescript-language-server opentofu terraform-ls ];
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
