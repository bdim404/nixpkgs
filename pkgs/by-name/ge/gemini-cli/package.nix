{
  lib,
  stdenvNoCC,
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  gitUpdater,
}:

let
  upstreamSrc = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    tag = "v0.1.17";
    hash = "sha256-4PnyJKAiRksiGac6/ibZ/DhFhCFsFn+hjEPqml2XVfk=";
  };

  patchedSrc = stdenvNoCC.mkDerivation {
    name = "gemini-cli-src-patched";
    src = upstreamSrc;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
      cp ${./package-lock.json} $out/package-lock.json
    '';
  };
in

buildNpmPackage (finalAttrs: {
  pname = "gemini-cli";
  version = "0.1.17";

  src = patchedSrc;

  npmDeps = fetchNpmDeps {
    src = patchedSrc;
    hash = "sha256-I7PiEiH8YPSydcltke38XC7vDP2M5SrG9ubBVsw3v3c=";
  };

  preConfigure = ''
    mkdir -p packages/generated
    echo "export const GIT_COMMIT_INFO = { commitHash: '${upstreamSrc.rev}' };" > packages/generated/git-commit.ts
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/gemini-cli}

    cp -r node_modules $out/share/gemini-cli/

    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    rm -f $out/share/gemini-cli/node_modules/gemini-cli-vscode-ide-companion
    cp -r packages/cli $out/share/gemini-cli/node_modules/@google/gemini-cli
    cp -r packages/core $out/share/gemini-cli/node_modules/@google/gemini-cli-core

    ln -s $out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js $out/bin/gemini
    runHook postInstall
  '';

  postInstall = ''
    chmod +x "$out/bin/gemini"
  '';

  passthru.updateScript = gitUpdater { };

  meta = {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ donteatoreo ];
    platforms = lib.platforms.all;
    mainProgram = "gemini";
  };
})

