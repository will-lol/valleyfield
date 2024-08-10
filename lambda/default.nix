{ pkgs, lib, targetPkgsCross }: [
	(import ./contact { inherit pkgs lib targetPkgsCross; })
	(import ./test { inherit pkgs lib targetPkgsCross; })
]
