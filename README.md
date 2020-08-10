# mikenye/adsb-to-mqtt

This container publishes basic statistics regarding ADS-B reception & container health to a mobile device via MQTT.

Based on: <https://www.adsbexchange.com/forum/threads/how-to-monitor-your-feeds-from-mobile-device.621696/>

## A Word About Security

The container health checks require that the container has access to the host's docker socket: `/var/run/docker.sock`. 

Mounting `/var/run/docker.sock` inside a container effectively gives the container and anything running within it root privileges on the underlying host, since now you can do anything that a root user with group membership of docker can.

For example, you could create a container, mount the host's `/etc`, modify configurations to open an attack vector to take over the host.

Accordingly, while I make every effort to ensure my code is trustworthy, if you decide to give this container access to the host's `/var/run/docker.sock`, you do so at your own risk.

## Environment Variables

| Environment Variable | Description |
|-----|-----|
| `AIRCRAFT_JSON_URL` | Required. URL for an `aircraft.json` file provided by readsb/dump1090. |
| `STATION_NAME` | Required. |
| `MQTT_HOST` | Required. MQTT broker. For a list of free public servers, check <https://github.com/mqtt/mqtt.github.io/wiki/public_brokers> |
| `MQTT_PREFIX` | Required. |

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
