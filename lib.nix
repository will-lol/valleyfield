{ pkgs, ... }: {
  getGoModulePath = src: (
    let 
      drv = pkgs.stdenv.mkDerivation {
	inherit src;
	name = "goModulePath";
	buildInputs = [pkgs.go pkgs.jq];
	buildPhase = ''
	  go mod edit --json | jq -r .Module.Path > modulePath
	'';
	installPhase = ''
	  cp modulePath $out
	'';
      };
    in 
      builtins.readFile drv
  );
}
