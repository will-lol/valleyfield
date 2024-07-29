{ pkgs, lib, targetPkgs }: [
	(import ./contact { inherit pkgs lib targetPkgs; })
	(import ./test { inherit pkgs lib targetPkgs; })
]
