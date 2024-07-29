{ pkgs, lib, targetPkgs }: [
	{
		package = (import ./contact { inherit pkgs lib targetPkgs; });
		modulePath = lib.getGoModulePath ./contact;
	}
	{
		package = (import ./test { inherit pkgs lib targetPkgs; });
		modulePath = lib.getGoModulePath ./test;
	}
]
