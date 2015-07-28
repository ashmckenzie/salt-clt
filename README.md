# salt CLT

## Installation

There is no gem as yet so for now:

```shell
cd /tmp
git clone https://github.com/ashmckenzie/salt-clt.git
cd salt-clt
bundle install
bundle exec rake install
```

## Setup

You need a `${HOME}/.salt_env` setup like:

```
SALT_URL='https://<FILL_ME_IN>:<FILL_ME_IN>'
SALT_USERNAME='<FILL_ME_IN>'
SALT_PASSWORD='<FILL_ME_IN>'
```

## Usage

```shell
$ salt-clt --help
Usage:
    salt-clt [OPTIONS] SUBCOMMAND [ARG] ...

Parameters:
    SUBCOMMAND                    subcommand
    [ARG] ...                     subcommand arguments

Subcommands:
    c, console                    Run a console
    e, exec                       Execute a command

Options:
    -h, --help                    print help
    -c, --config_file CONFIG      Config file (default: "/Users/ash/.salt_env")
    --version                     show version
```

## Examples

### Return the version of SaltStack for all minions

```bash
salt-clt exec test.version
```

### Upgrade all packages for Linux minions

```bash
salt-clt exec --target 'G@kernel:Linux' pkg.upgrade 'refresh=True,dist_upgrade=True'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ashmckenzie/salt-clt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
