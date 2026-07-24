{ userConfig, ... }:
{
  system.activationScripts.rootSSHKey.text = ''
        install -d -m700 /root/.ssh
        cat > /root/.ssh/id_ed25519 <<'EOF'
    ${userConfig.headnode.private_ssh_key}
    EOF
        chmod 600 /root/.ssh/id_ed25519

        cat > /root/.ssh/id_ed25519.pub <<'EOF'
    ${userConfig.worker.public_ssh_key}
    EOF
        chmod 644 /root/.ssh/id_ed25519.pub
  '';
}
