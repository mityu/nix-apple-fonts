{
  description = "Fonts distributed by Apple Inc.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      lockfile = ./lock.json;
      version = lockfile.version;
      srcs = map (
        v: v // { pname = v.pname or (lib.removeSuffix ".dmg" (baseNameOf v.url)); }
      ) lockfile.srcs;
      genPkgDef =
        {
          pname,
          url,
          hash,
        }:
        {
          pkgs,
          lib,
          stdenvNoCC,
          fetchurl,
        }:
        stdenvNoCC.mkDerivation {
          inherit pname version;

          src = fetchurl {
            inherit url hash;
          };

          nativeBuildInputs = with pkgs; [
            p7zip
            installFonts
          ];

          sourceRoot = "./";

          unpackCmd = ''
            runHook preUnpack
            7z x $curSrc
            find . -type f -name '*.pkg' -exec mv {} ./ \;
            7z x *.pkg
            7z x 'Payload~'
            runHook postUnpack
          '';

          meta = with lib; {
            license = licenses.unfree;
            homepage = "https://developer.apple.com/fonts/";
            platforms = platforms.all;
          };
        };
      packages =
        pkgs:
        let
          mergePkgs =
            { targetPkgs, pname }:
            {
              pkgs,
              lib,
              stdenvNoCC,
              ...
            }:
            stdenvNoCC.mkDerivation rec {
              inherit pname version;
              buildInputs = targetPkgs;
              nativeBuildInputs = [ pkgs.rsync ];

              dontUnpack = true;
              dontPatch = true;
              dontConfigure = true;
              dontBuild = true;

              installPhase =
                let
                  installers = map (v: "${lib.getExe pkgs.rsync} -av \"${v}/\" \"$out/\"") buildInputs;
                in
                ''
                  runHook preInstall
                  mkdir -p $out
                  ${lib.join "\n" installers}
                  runHook postInstall
                '';
            };
          fontpkgs = lib.pipe srcs [
            (map (v: {
              name = lib.toLower (v.pname);
              value = pkgs.callPackage (genPkgDef v) { };
            }))
          ];
        in
        (builtins.listToAttrs fontpkgs)
        // rec {
          full = pkgs.callPackage (mergePkgs {
            pname = "full";
            targetPkgs = map (v: v.value) fontpkgs;
          }) { };
          default = full;
        };
    in
    {
      packages = forAllSystems (system: packages (import nixpkgs { inherit system; }));
    };
}
