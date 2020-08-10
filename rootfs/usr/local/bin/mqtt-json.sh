#!/usr/bin/env bash
#shellcheck shell=bash

nowold=0
messagesold=0

while true

    do

        NOW=$(curl --silent "$AIRCRAFT_JSON_URL" | jq '.now' | awk '{print int($0)}')
        MESSAGES=$(curl --silent "$AIRCRAFT_JSON_URL" | jq '.messages')

        nowdelta=$(expr $NOW - $nowold)
        messagesdelta=$(expr $MESSAGES - $messagesold)

        RATE=$(echo "$messagesdelta $nowdelta /p" | dc)
        AC_POS=$(curl --silent "$AIRCRAFT_JSON_URL" | jq '[.aircraft[] | select(.seen_pos)] | length')
        AC_TOT=$(curl --silent "$AIRCRAFT_JSON_URL" | jq '[.aircraft[] | select(.seen < 60)] | length')
        DUMP=$(echo "Aircraft:$AC_TOT\nPosition:$AC_POS\nMsg/s:$RATE")

        # echo $DUMP

        nowold=$NOW
        messagesold=$MESSAGES

        OUTPUT_JSON="{ \"dump\" : \"$DUMP\""

        if [[ -S /var/run/docker.sock ]]; then

            if [[ -n "$CONTAINERNAME_READSB" ]]; then
                CONTAINER_HEALTH="0"
                if docker inspect "$CONTAINERNAME_READSB" > /dev/null 2>&1; then
                    if [[ "$(docker inspect "$CONTAINERNAME_READSB" | jq '.[].State.Health.Status')" == "\"healthy\"" ]]; then
                        CONTAINER_HEALTH="1"
                    fi
                fi
                OUTPUT_JSON+=", \"$CONTAINERNAME_READSB\" : \"$CONTAINER_HEALTH\""
            fi

            if [[ -n "$CONTAINERNAME_PIAWARE" ]]; then
                CONTAINER_HEALTH="0"
                if docker inspect "$CONTAINERNAME_PIAWARE" > /dev/null 2>&1; then
                    if [[ "$(docker inspect "$CONTAINERNAME_PIAWARE" | jq '.[].State.Health.Status')" == "\"healthy\"" ]]; then
                        CONTAINER_HEALTH="1"
                    fi
                fi
                OUTPUT_JSON+=", \"$CONTAINERNAME_PIAWARE\" : \"$CONTAINER_HEALTH\""
            fi

            if [[ -n "$CONTAINERNAME_ADSBX" ]]; then
                CONTAINER_HEALTH="0"
                if docker inspect "$CONTAINERNAME_ADSBX" > /dev/null 2>&1; then
                    if [[ "$(docker inspect "$CONTAINERNAME_ADSBX" | jq '.[].State.Health.Status')" == "\"healthy\"" ]]; then
                        CONTAINER_HEALTH="1"
                    fi
                fi
                OUTPUT_JSON+=", \"$CONTAINERNAME_ADSBX\" : \"$CONTAINER_HEALTH\""
            fi

            if [[ -n "$CONTAINERNAME_OPENSKY" ]]; then
                CONTAINER_HEALTH="0"
                if docker inspect "$CONTAINERNAME_OPENSKY" > /dev/null 2>&1; then
                    if [[ "$(docker inspect "$CONTAINERNAME_OPENSKY" | jq '.[].State.Health.Status')" == "\"healthy\"" ]]; then
                        CONTAINER_HEALTH="1"
                    fi
                fi
                OUTPUT_JSON+=", \"$CONTAINERNAME_OPENSKY\" : \"$CONTAINER_HEALTH\""
            fi

            if [[ -n "$CONTAINERNAME_RADARBOX" ]]; then
                CONTAINER_HEALTH="0"
                if docker inspect "$CONTAINERNAME_RADARBOX" > /dev/null 2>&1; then
                    if [[ "$(docker inspect "$CONTAINERNAME_RADARBOX" | jq '.[].State.Health.Status')" == "\"healthy\"" ]]; then
                        CONTAINER_HEALTH="1"
                    fi
                fi
                OUTPUT_JSON+=", \"$CONTAINERNAME_RADARBOX\" : \"$CONTAINER_HEALTH\""
            fi

            if [[ -n "$CONTAINERNAME_FR24" ]]; then
                CONTAINER_HEALTH="0"
                if docker inspect "$CONTAINERNAME_FR24" > /dev/null 2>&1; then
                    if [[ "$(docker inspect "$CONTAINERNAME_FR24" | jq '.[].State.Health.Status')" == "\"healthy\"" ]]; then
                        CONTAINER_HEALTH="1"
                    fi
                fi
                OUTPUT_JSON+=", \"$CONTAINERNAME_FR24\" : \"$CONTAINER_HEALTH\""
            fi

        fi

        OUTPUT_JSON+=" }"

        /usr/bin/mosquitto_pub -h "$MQTT_HOST" -t "$MQTT_PREFIX/$STATION_NAME/ADSB" -m "$OUTPUT_JSON"

        sleep 5

    done