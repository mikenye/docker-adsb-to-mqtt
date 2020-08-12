# mikenye/adsb-to-mqtt

This container publishes basic statistics regarding ADS-B reception & container health to a mobile device via MQTT.

Based on: <https://www.adsbexchange.com/forum/threads/how-to-monitor-your-feeds-from-mobile-device.621696/>

## Work in Progress

As of August 2020, this container is currently a work-in-progress, and we hope to stabilise features/syntax by the end of the month. If you have any specific requirements or other input, please swing by our [Discord channel](https://discord.gg/sTf9uYF) and discuss! Thanks.

## A Word About Security

The container health checks require that the container has access to the host's docker socket: `/var/run/docker.sock`.

Mounting `/var/run/docker.sock` inside a container effectively gives the container and anything running within it root privileges on the underlying host, since now you can do anything that a root user with group membership of docker can.

For example, you could create a container, mount the host's `/etc`, modify configurations to open an attack vector to take over the host.

Accordingly, while I make every effort to ensure my code is trustworthy, if you decide to give this container access to the host's `/var/run/docker.sock`, you do so at your own risk.

## Up and Running with `docker run`

An example `docker run` syntax is as follows:

```shell
docker run \
    -d \
    -it \
    --name=adsb2mqtt \
    --restart=always \
    -e AIRCRAFT_JSON_URL="http://piaware.home.local:8080/data/aircraft.json" \
    -e MQTT_HOST="homeassistant.home.local" \
    -e MQTT_USER="kingroland" \
    -e MQTT_PASS="12345" \
    mikenye/adsb-to-mqtt
```

## Environment Variables

| Environment Variable | Description |
|-----|-----|
| `AIRCRAFT_JSON_URL` | Required. URL for an `aircraft.json` file provided by readsb/dump1090. |
| `MQTT_HOST` | Required. MQTT broker. For a list of free public servers, check <https://github.com/mqtt/mqtt.github.io/wiki/public_brokers>. |
| `MQTT_INTERVAL` | Optional. How many seconds between sending MQTT messages. Default: `5`. |
| `MQTT_USER` | Username for MQTT Host (if required). |
| `MQTT_PASS` | Password for MQTT Host (if required). |
| `MQTT_TOPIC` | Optional. Topic for MQTT messages. Defaults to `docker/adsb2mqtt`. |

The MQTT topic will be: `$MQTT_PREFIX/$STATION_NAME/ADSB`.

Regarding `AIRCRAFT_JSON_URL`, you need to specify a URL for an `aircraft.json` file provided by readsb/dump1090. Examples of `AIRCRAFT_JSON_URL` (pick one):

* If using a [mikenye/readsb](https://hub.docker.com/r/mikenye/readsb) container: `http://readsb:8080/data/aircraft.json`
* If using a [mikenye/piaware](https://hub.docker.com/r/mikenye/piaware) container: `http://piaware:8080/data/aircraft.json`
* If using a [mikenye/tar1090](https://hub.docker.com/r/mikenye/tar1090) container: `http://tar1090/data/aircraft.json`
* If using PiAware on a Raspberry Pi: `http://pi:8080/data/aircraft.json`

## Environment Variables for Container Healthcheck

| Environment Variable | Description |
|-----|-----|
| `CONTAINERNAME_READSB` | Optional. If using a [mikenye/readsb](https://hub.docker.com/r/mikenye/readsb) container, specify the container name. This will enable reporing the container health (as determined from the docker healthcheck status). |
| `CONTAINERNAME_PIAWARE` | Optional. If using a [mikenye/piaware](https://hub.docker.com/r/mikenye/piaware) container, specify the container name. This will enable reporing the container health (as determined from the docker healthcheck status). |
| `CONTAINERNAME_ADSBX`  | Optional. If using a [mikenye/adsbexchange](https://hub.docker.com/r/mikenye/adsbexchange) container, specify the container name. This will enable reporing the container health (as determined from the docker healthcheck status). |
| `CONTAINERNAME_OPENSKY`  | Optional. If using a [mikenye/opensky-network](https://hub.docker.com/r/mikenye/opensky-network) container, specify the container name. This will enable reporing the container health (as determined from the docker healthcheck status). |
| `CONTAINERNAME_RADARBOX`  | Optional. If using a [mikenye/radarbox](https://hub.docker.com/r/mikenye/radarbox) container, specify the container name. This will enable reporing the container health (as determined from the docker healthcheck status). |
| `CONTAINERNAME_FR24`  | Optional. If using a [mikenye/fr24feed](https://hub.docker.com/r/mikenye/fr24feed) container, specify the container name. This will enable reporing the container health (as determined from the docker healthcheck status). |

## Output JSON Format

Example JSON output is as follows:

```json
{
    "aircraft": "10",
    "positions": "9",
    "msgs_per_sec" : "120",
    "readsb": "1",
    "piaware": "1",
    "adsbx": "1",
    "opensky": "0",
    "fr24": "0"
}
```

Where:

* `aircraft` is the number of aircraft you are currently receiving ADS-B messages from
* `positions` is the number of aircraft reporting positions
* `msgs_per_sec` is the number of ADS-B messages per second you are receiving

If container monitoring is configured/enabled:

* `readsb` reports `1` if docker healthcheck reports the container is healthy, `0` for any other status
* `piaware` reports `1` if docker healthcheck reports the container is healthy, `0` for any other status
* `adsbx` reports `1` if docker healthcheck reports the container is healthy, `0` for any other status
* `opensky` reports `1` if docker healthcheck reports the container is healthy, `0` for any other status
* `radarbox` reports `1` if docker healthcheck reports the container is healthy, `0` for any other status
* `fr24` reports `1` if docker healthcheck reports the container is healthy, `0` for any other status

## Getting help

Please feel free to [open an issue on the project's GitHub](https://github.com/mikenye/docker-adsb-to-mqtt/issues).

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
