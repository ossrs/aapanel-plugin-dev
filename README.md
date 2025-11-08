# aapanel-plugin-dev

**IMPORTANT NOTE**: This repository is depreacated and archived, please use [srs-cdk](https://github.com/ossrs/srs-cdk) instead. CDK is the future of default and recommended deployment for SRS and Oryx.

Plugin develop environment for [aaPanel](https://www.aapanel.com)

## Usage

Install venv:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r www/server/panel/requirements.txt
```

For PyCharm, add `class` to path, then run `test.py` in PyCharm:

* Open `PyCharm > Settings > Project > Python Interpreter` tab.
* Click the list of interpreters, then click `Show All` item.
* Choose the `venv` and click `Show Interpreter Paths` icon.
* Click `+` and add the `www/server/panel/class` to path.

For CLI, setup the `PYTHONPATH` and run `test.py` in CLI:

```bash
export PYTHONPATH=$(pwd)/www/server/panel/class
python test.py
#setup path: /www/server
```

Now you are able to develop the `example` plugin, or link srs-stack and develop it:

```bash
ln -sf ~/git/srs-stack/scripts/setup-bt
ln -sf ~/git/srs-stack/scripts/setup-aapanel
```

Then, run aaPanel docker and mount the plugin to the container.

## Docker

Create a docker container in daemon:

```bash
docker rm -f aapanel 2>/dev/null || echo 'OK' &&
docker run -p 7800:7800 -v $(pwd)/example:/www/server/panel/plugin/example \
    --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:rw --cgroupns=host \
    -d --rm -it -v $(pwd):/g -w /g --name=aapanel ossrs/aapanel-plugin-dev:1
```

> Note: For user in China, you can use `registry.cn-hangzhou.aliyuncs.com/ossrs/aapanel-plugin-dev:1` instead.

Open [http://localhost:7800/srsstack](http://localhost:7800/srsstack) and login:

* Username: `ossrs`
* Password: `12345678`

> Note: Or you can use `docker exec -it aapanel bt default` to show the login info.

In the application store, there is a example plugin.

## Update Library

Build a image from the latest aaPanel:

```bash
docker build --progress=plain -f Dockerfile -t aapanel .
```

Copy the `/www/server` from the docker:

```bash
docker run --rm -it -v $(pwd):/g -w /g --name=aapanel aapanel top
```

Then, copy the `/www/server` to the host:

```bash
rm -rf www && mkdir www &&
docker exec -it aapanel cp -rf /www/server /g/www/
```

Update the permission of files:

```bash
for ((i=0;i<8;i++)); do find www -type d -exec chmod 755 "{}" \; ; done &&
find www -type f -exec chmod u+rw "{}" \; &&
find www -type f -exec chmod g+r "{}" \; &&
find www -type f -exec chmod o+r "{}" \; &&
echo OK
```
