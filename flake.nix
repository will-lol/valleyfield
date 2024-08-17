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
        overlays = [
          (final: prev: {
            # https://github.com/NixOS/nixpkgs/issues/267864
            awscli2 = prev.awscli2.overrideAttrs (oldAttrs: {
              nativeBuildInputs = oldAttrs.nativeBuildInputs
                ++ [ pkgs.makeWrapper ];

              doCheck = false;

              postInstall =
                "	${oldAttrs.postInstall}\n	wrapProgram $out/bin/aws --set PYTHONPATH=\n";
            });
          })
        ];
        pkgs = import nixpkgs { inherit system overlays; };
        lib = import ./lib.nix { inherit pkgs; };
        targetPkgsCross = pkgs.pkgsCross.aarch64-multiplatform;
        targetPkgs = import nixpkgs {
          inherit overlays;
          system = "aarch64-linux";
        };

        apiHandlers = import ./lambda { inherit pkgs lib targetPkgsCross; };
        frontend = import ./frontend { inherit pkgs lib; };
        codebuild = import ./infra/pipeline {
          inherit pkgs lib targetPkgs targetPkgsCross nix;
        };
        goCdkBinary = import ./infra { inherit pkgs; };

        artifact = pkgs.runCommand "build-artifact" { }
          "	mkdir $out\n	${pkgs.rsync}/bin/rsync --mkpath -a ${frontend}/lib/node_modules/frontend/dist/ $out/frontend\n\n	${
             builtins.concatStringsSep "\n" (builtins.map (handler:
               "	FILENAME=\"$(${pkgs.findutils}/bin/find ${handler}/bin/ -mindepth 1 -printf \"%f\" -quit)\"\n	\n	cp \"${handler}/bin/$FILENAME\" bootstrap\n	mkdir -p \"$out/lambda\"\n	${pkgs.zip}/bin/zip \"$out/lambda/$FILENAME.zip\" bootstrap\n	rm bootstrap\n")
               apiHandlers)
           }\n";

        cdk = pkgs.buildNpmPackage {
          pname = "cdk";
          version = "0.0.1";
          src = ./.;
          npmDepsHash = "sha256-NgIUI7Ik1yr24rgh5Iz574vRCVQaFIHsnWjApXgRaDY=";
          npmPackFlags = [ "--ignore-scripts" ];
          nativeBuildInputs = [ goCdkBinary ];
          buildPhase =
            "	ln -s ${goCdkBinary} goCdkBinary\n	ln -s ${artifact} artifact\n	npm run build\n";
          installPhase = "	mkdir -p $out\n	cp -r cdk.out/* $out\n";
        };
      in {
        packages = {
          default = cdk;
          cdk = cdk;
          codebuild = codebuild;
          artifact = artifact;
          goCdkBinary = goCdkBinary;
        };
        # defaultPackage = example;
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go
              gopls
              nodePackages.nodejs
              nodePackages.typescript-language-server
              opentofu
              terraform-ls
              aws-sam-cli
              awscli2
            ];
            shellHook = "	export AWS_DEFAULT_PROFILE=Valleyfield\n";
          };
          buildShell =
            pkgs.mkShell { packages = with pkgs; [ nodePackages.nodejs ]; };
        };
      });
}
