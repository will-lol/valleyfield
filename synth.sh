nix build .#goCdkBinary -o goCdkBinary
nix build .#artifact -o artifact
npm run build
