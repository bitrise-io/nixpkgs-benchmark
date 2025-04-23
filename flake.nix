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
                    mocket = python-prev.mocket.overrideAttrs (mocket-prev: {
                      # disabledTests = mocket-prev.disabledTests ++ [ "test_httprettish_httpx_session" ];

                    });
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
          stdenv = pkgs.stdenv;

          default = pkgs.buildEnv {
            name = "regression-pkg-set";
            ignoreCollisions = true;
            paths =
              with pkgs;
              [
                ansible
                ansible-language-server
                ansible-lint
                aria
                awscli2
                bash-language-server
                bazelisk
                bitrise
                broot
                btop
                bundler
                cmake
                curl
                dart
                dua
                fastlane
                fd
                firebase-tools
                flow
                gh
                git
                git-lfs
                gnupg
                go
                go_1_23
                go_1_24
                google-cloud-sdk
                hadolint
                hugo
                imagemagick
                jdk17_headless
                jq
                just
                kotlin
                lokalise2-cli
                mercurial
                openconnect
                openvpn
                packer
                parallel
                php83
                pipx
                pnpm
                poetry
                protobuf
                pyenv
                pylint
                python311
                python312
                python313
                qemu
                rbenv
                readline
                screen
                shellcheck
                sonar-scanner-cli
                tailscale
                tree
                watchman
                wget
                xcpretty
                yamllint
                zeromq
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

