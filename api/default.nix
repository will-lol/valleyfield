{ pkgs, lib }: [
	{
		package = (import ./contact { inherit pkgs lib; });
		modulePath = lib.getGoModulePath ./contact;
	}
	{
		package = (import ./test { inherit pkgs lib; });
		modulePath = lib.getGoModulePath ./test;
	}
]
