{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  gitUpdater,
}:

buildNpmPackage (finalAttrs: {
  pname = "gemini-cli";
  version = "0.1.15";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "pull/5336/head";
    hash = "sha256-5Fs0LpimZsChFFM3r0ZezyYHxhMUUNfOqA6QYAuyek8=";
  };

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-I7PiEiH8YPSydcltke38XC7vDP2M5SrG9ubBVsw3v3c=";
  };

  preConfigure = ''
    mkdir -p packages/generated
    echo "export const GIT_COMMIT_INFO = { commitHash: '${finalAttrs.src.rev}' };" > packages/generated/git-commit.ts
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
