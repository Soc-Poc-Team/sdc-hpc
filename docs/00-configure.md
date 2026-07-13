# Configure your cluster

The only file you have to adjust to run your own cluster is the
[config.toml](../config.toml). The file provided by this repo serves as an
example and can be adjusted to your needs.

## Tailscale

This project uses tailscale to allow nodes to communicate with each other. Enter
your tailscale authentication-key (to get access to your tailnet), your API-key
(to manage the tailnet) and your tailscale domain into the config file.

Before creating an auth key, you should modify your access control policy file
under `Access controls` in the web ui.

```json
// Example/default ACLs for unrestricted connections.
{
  // Define the tags which can be applied to devices and by which users.
  "tagOwners": {
    "tag:cluster": ["autogroup:admin"]
  },

  // Define access control lists for users, groups, autogroups, tags,
  // Tailscale IP addresses, and subnet ranges.
  "acls": [
    // Allow user1 and user2 to connect to every port in our cluster network.
    // Also allow all cluster nodes to connect to eachother
    {
      "action": "accept",
      "src": ["user1@github", "user2@github", "tag:cluster"],
      "dst": ["100.81.0.0/24:*"]
    }
  ],
  "ssh": [
    // The default SSH policy, which lets users SSH into devices they own.
    // Learn more at https://tailscale.com/kb/1193/tailscale-ssh/
    {
      "action": "accept",
      "src": ["user1@github"],
      "dst": ["autogroup:self"],
      "users": ["root,user1,user_on_the_cluster_from_toml"]
    }
  ],
  "nodeAttrs": [
    // All nodes with our tag "cluster" get an ip from the pool 100.81.0.0/24
    {
      "target": ["tag:cluster"],
      "ipPool": ["100.81.0.0/24"]
    }
  ]
}
```

After this the tag "cluster" is available to attach to an auth key. To create an
auth key go to `Settings` > `Keys` > `generate auth key...` Key must be:

    1. Reusable
    2. Ephemeral
    3. have tag:cluster

Now get your Tailscale Tailnet Name from `DNS` > `Tailnet Name`

## Users

You can create users by adding them to the [config.toml](/config.toml). They
require a username, password-hash and a uid. Set the uid high (>5000) to not get
in conflict with existing UIDs. These users will be able to login to jupyter hub
and have a linux users with these credentials.

This is how you generate your password-hashes

```bash
mkpasswd -m sha-512
```
