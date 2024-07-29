{ pkgs, nix, targetPkgs, ... }: targetPkgs.dockerTools.buildLayeredImage {
	name = "codebuild";
	tag = "latest";
	maxLayers = 125;
	# grab the image tarball from the nix hydrajob rather than pullImage so that the nix repo version (and thus image version) is pinned to flake.lock
	fromImage = targetPkgs.runCommand "transform-hydraJobs-output" {} ''
		cp ${nix.hydraJobs.dockerImage.aarch64-linux}/image.tar.gz $out
	'';
	contents = [
		# enable flakes
		(targetPkgs.writeTextFile {
			name = "nix.conf";
			destination = "/etc/nix/nix.conf";
			text = ''
				accept-flake-config = true
				experimental-features = nix-command flakes
				filter-syscalls = false
			'';
		})
		targetPkgs.bashInteractive
	];
}
