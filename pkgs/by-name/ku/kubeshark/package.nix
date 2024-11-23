{ stdenv, lib, buildGoModule, fetchFromGitHub, installShellFiles, testers, kubeshark, nix-update-script }:

buildGoModule rec {
  pname = "kubeshark";
  version = "52.3.89";

  src = fetchFromGitHub {
    owner = "kubeshark";
    repo = "kubeshark";
    rev = "v${version}";
    hash = "sha256-v5XxvY3omO9h1xtm+VSVP/zrU8uRJXvwSdxScAujWOU=";
  };

  vendorHash = "sha256-kzyQW4bVE7oMOlHVG7LKG1AMTRYa5GLiiEhdarIhMSo=";

  ldflags = let t = "github.com/kubeshark/kubeshark"; in [
   "-s" "-w"
   "-X ${t}/misc.GitCommitHash=${src.rev}"
   "-X ${t}/misc.Branch=master"
   "-X ${t}/misc.BuildTimestamp=0"
   "-X ${t}/misc.Platform=unknown"
   "-X ${t}/misc.Ver=${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  checkPhase = ''
    go test ./...
  '';
  doCheck = true;

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd kubeshark \
      --bash <($out/bin/kubeshark completion bash) \
      --fish <($out/bin/kubeshark completion fish) \
      --zsh <($out/bin/kubeshark completion zsh)
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = kubeshark;
      command = "kubeshark version";
      inherit version;
    };
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    changelog = "https://github.com/kubeshark/kubeshark/releases/tag/${version}";
    description = "API Traffic Viewer for Kubernetes";
    mainProgram = "kubeshark";
    homepage = "https://kubeshark.co/";
    license = licenses.asl20;
    longDescription = ''
      The API traffic viewer for Kubernetes providing real-time, protocol-aware visibility into Kubernetes’ internal network,
      Think TCPDump and Wireshark re-invented for Kubernetes
      capturing, dissecting and monitoring all traffic and payloads going in, out and across containers, pods, nodes and clusters.
    '';
    maintainers = with maintainers; [ bryanasdev000 qjoly ];
  };
}
