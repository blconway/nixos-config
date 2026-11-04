{ pkgs, hosts }:

# Settings that a decision in docs/DECISIONS.md depends on. Evaluating this
# fails, naming every broken invariant, if an edit undoes one; `nix flake
# check --no-build` is enough to run it. Change an invariant only together
# with the decision it cites.
let
  inherit (pkgs) lib;
  ai = hosts.ai-fw.config;
  ws = hosts.bc-ws.config;

  both = f: [
    (f "ai-fw" ai)
    (f "bc-ws" ws)
  ];

  invariants = [
    # ai-fw
    {
      d = "D12";
      what = "ai-fw's root has no password; brandon and sudo are the way in";
      ok =
        let
          r = ai.users.users.root;
        in
        r.hashedPassword == null
        && r.password == null
        && r.hashedPasswordFile == null
        && r.initialPassword == null
        && lib.elem r.initialHashedPassword [
          null
          "!"
        ];
    }
    {
      d = "D1/D3";
      what = "ai-fw opens only SSH on the LAN";
      ok = ai.networking.firewall.allowedTCPPorts == [ 22 ];
    }
    {
      d = "D3";
      what = "ai-fw trusts tailscale0, where the API is reached";
      ok = lib.elem "tailscale0" ai.networking.firewall.trustedInterfaces;
    }
    {
      d = "D3";
      what = "llama-cpp does not open its own firewall port";
      ok = !ai.services.llama-cpp.openFirewall;
    }
    {
      d = "D8";
      what = "ai-fw has no nomodeset (it would disable amdgpu)";
      ok = !lib.elem "nomodeset" ai.boot.kernelParams;
    }
    {
      d = "D4";
      what = "ai-fw raises the GTT limit so the ~94 GB model fits";
      ok = lib.any (lib.hasPrefix "ttm.pages_limit=") ai.boot.kernelParams;
    }
    {
      d = "D5";
      what = "ai-fw upgrades at 04:10 and may reboot only in its window";
      ok =
        ai.system.autoUpgrade.dates == "04:10"
        && ai.system.autoUpgrade.allowReboot
        && ai.system.autoUpgrade.rebootWindow.lower <= "04:10";
    }

    # bc-ws
    {
      d = "D10";
      what = "bc-ws stages upgrades for the next boot";
      ok = ws.system.autoUpgrade.operation == "boot";
    }
    {
      d = "D10";
      what = "bc-ws uses NVIDIA's open kernel modules";
      ok = ws.hardware.nvidia.open;
    }
  ]
  ++ both (
    name: c: {
      d = "D5/D7";
      what = "${name} upgrades from main's lock on GitHub, never updating it locally";
      ok =
        c.system.autoUpgrade.flake == "github:blconway/nixos-config#${name}"
        && !lib.any (lib.hasInfix "--update-input") c.system.autoUpgrade.flags;
    }
  )
  ++ both (
    name: c: {
      d = "D5";
      what = "${name} has boot counting and 10 generations";
      ok =
        c.boot.loader.systemd-boot.bootCounting.enable
        && c.boot.loader.systemd-boot.configurationLimit == 10;
    }
  )
  ++ both (
    name: c: {
      d = "D8";
      what = "${name} allows SSH keys only, if it runs sshd (D8 dropped fail2ban on this)";
      ok =
        !c.services.openssh.enable
        || (
          !c.services.openssh.settings.PasswordAuthentication
          && !c.services.openssh.settings.KbdInteractiveAuthentication
        );
    }
  );

  broken = lib.filter (i: !i.ok) invariants;
in
if broken == [ ] then
  pkgs.runCommand "invariants" { } ''
    echo "${toString (lib.length invariants)} invariants hold" > $out
  ''
else
  throw (
    "Broken invariants (docs/DECISIONS.md):\n"
    + lib.concatMapStrings (i: "  ${i.d}: ${i.what}\n") broken
  )
