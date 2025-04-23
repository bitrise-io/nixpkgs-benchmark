{
  description = "A very basic flake";

  inputs = {
    # Use staging branch because the stdenv is built daily by Hydra (so there is binary cache hit for stdenv itself),
    # while packages are not cached and must be built from source.
    nixpkgs.url = "github:nixos/nixpkgs?ref=staging";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              (final: prev: {
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                  (python-final: python-prev: {
                    anyio = python-prev.anyio.overrideAttrs (anyio-prev: {
                      disabledTests = anyio-prev.disabledTests ++ [
                        # These tests become flaky under heavy load
                        "test_asyncio_run_sync_called"
                        "test_handshake_fail"
                        "test_run_in_custom_limiter"
                        "test_cancel_from_shielded_scope"
                        "test_start_task_soon_cancel_later"
                      ];
                    });
                  })
                ];
              })
            ];
          };
        in
        {
          benchmarkSmall = pkgs.clang;

          benchmarkHuge = pkgs.buildEnv {
            name = "nixpkgs-benchmark-huge";
            ignoreCollisions = true;
            paths =
              with pkgs;
              [
                aria
                awscli2
                bazelisk
                bitrise
                btop
                bundler
                curl
                dart
                dua
                fastlane
                fd
                firebase-tools
                gh
                git
                git-lfs
                go
                go_1_23
                go_1_24
                google-cloud-sdk
                imagemagick
                jdk17_headless
                jq
                kotlin
                lokalise2-cli
                mercurial
                openconnect
                openvpn
                parallel
                php83
                pipx
                pnpm
                protobuf
                pyenv
                pylint
                rbenv
                readline
                screen
                shellcheck
                sonar-scanner-cli
                tree
                wget
                xcpretty
                yamllint
                zstd
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                cocoapods
                jazzy
                xcodes
                xcode-install
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [

              ];
          };
        }
      );
    };
}
