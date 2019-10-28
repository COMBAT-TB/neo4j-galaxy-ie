# Neo4j Galaxy IE

[![Docker Repository on Quay](https://quay.io/repository/sanbi-sa/neo_ie/status "Docker Repository on Quay")](https://quay.io/repository/sanbi-sa/neo_ie)

A modified version of the [Neo4j:3.1.9](https://github.com/neo4j/docker-neo4j) docker image to cater for [Galaxy port mapping](https://github.com/galaxyproject/galaxy/blob/dev/lib/galaxy/web/base/interactive_environments.py#L381).

## Build and run

### Build the image

```sh
docker build -t quay.io/sanbi-sa/neo_ie:3.1.9.1 .
```

> *OR*

### Pull the image

```sh
docker pull quay.io/sanbi-sa/neo_ie:3.1.9.1
```

### Run the image

```sh
docker run -d \
    -p 7474:7474 \
    -p 7687:7687 \
    -v /tmp/data:/data \
    -e NEO4J_AUTH=none -e USER_UID=$(id -u) -e USER_GID=$(id -g) \
    quay.io/sanbi-sa/neo_ie:3.1.9.1
```

### To disable Bolt

![disable_bolt](/img/disable_bolt.png)

## Galaxy Integration

*Make sure you have nodejs `v0.10.45` and that you can run `node` (you might have to set a symlink)*

### nodejs

```sh
apt-cache policy nodejs
nodejs:
  Installed: 0.10.45-1nodesource1~trusty1
  Candidate: 0.10.45-1nodesource1~trusty1
  Version table:
 *** 0.10.45-1nodesource1~trusty1 0
        500 https://deb.nodesource.com/node/ trusty/main amd64 Packages
        100 /var/lib/dpkg/status
```

```sh
node -v
v0.10.45
```

### Config

Set `interactive_environment_plugins_directory` to `config/plugins/interactive_environments` in `config/galaxy.ini`

Next, [follow](galaxy/README.md) in the `galaxy` folder to get the Neo4j IE installed.

### Proxy setup

Then, [setup](https://docs.galaxyproject.org/en/master/admin/interactive_environments.html#setting-up-the-proxy) your proxy accordingly.

Thanks to [@bgruening](https://github.com/bgruening) and [@erasche](https://github.com/erasche).
