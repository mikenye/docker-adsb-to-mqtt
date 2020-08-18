#!/usr/bin/env bash
#shellcheck shell=bash

nowold=0
messagesold=0

while true

    do

        NOW=$(curl --silent "$AIRCRAFT_JSON_URL" | jq '.now' | awk '{print int($0)}')
        MESSAGES=$(curl --silent "$AIRCRAFT_JSON_URL" | jq '.messages')

        nowdelta=$((NOW - nowold))
        messagesdelta=$((MESSAGES - messagesold))

        if [[ "$nowdelta" -gt "0" ]]; then
            RATE=$(echo "$messagesdelta $nowdelta /p" | dc)
        else
            RATE=0
        fi
        AC_POS=$(curl --silent "$AIRCRAFT_JSON_URL" | jq '[.aircraft[] | select(.seen_pos)] | length')
        AC_TOT=$(curl --silent "$AIRCRAFT_JSON_URL" | jq '[.aircraft[] | select(.seen < 60)] | length')

        nowold=$NOW
        messagesold=$MESSAGES

        # Start building output JSON
        OUTPUT_JSON="{ \"aircraft\" : \"$AC_TOT\""
        OUTPUT_JSON+=", \"positions\" : \"$AC_POS\""
        OUTPUT_JSON+=", \"msgs_per_sec\" : \"$RATE\""
        OUTPUT_JSON+=", \"timestamp\" : \"$TIMESTAMP\""
        
        # FlightAware PiAware Stats
        if [[ -n "$FA_JSON_URL" ]]; then
            FA_SITE_URL=$(curl --silent "$FA_JSON_URL" | jq '.site_url')
            FA_PIAWARE_STATUS=$(curl --silent "$FA_JSON_URL" | jq '.piaware.status')
            FA_PIAWARE_MESSAGE=$(curl --silent "$FA_JSON_URL" | jq '.piaware.message')
            FA_MLAT_STATUS=$(curl --silent "$FA_JSON_URL" | jq '.mlat.status')
            FA_MLAT_MESSAGE=$(curl --silent "$FA_JSON_URL" | jq '.mlat.message')
            FA_CONNECT_STATUS=$(curl --silent "$FA_JSON_URL" | jq '.adept.status')
            FA_CONNECT_MESSAGE=$(curl --silent "$FA_JSON_URL" | jq '.adept.message')
            FA_RADIO_STATUS=$(curl --silent "$FA_JSON_URL" | jq '.radio.status')
            FA_RADIO_MESSAGE=$(curl --silent "$FA_JSON_URL" | jq '.radio.message')

            OUTPUT_JSON+=", \"piaware\" : {"
            OUTPUT_JSON+=" \"flightaware_site_url\" : $FA_SITE_URL"
            OUTPUT_JSON+=", \"piaware_status\" : $FA_PIAWARE_STATUS"
            OUTPUT_JSON+=", \"piaware_message\" : $FA_PIAWARE_MESSAGE"
            OUTPUT_JSON+=", \"mlat_status\" : $FA_MLAT_STATUS"
            OUTPUT_JSON+=", \"mlat_message\" : $FA_MLAT_MESSAGE"
            OUTPUT_JSON+=", \"connect_status\" : $FA_CONNECT_STATUS"
            OUTPUT_JSON+=", \"connect_message\" : $FA_CONNECT_MESSAGE"
            OUTPUT_JSON+=", \"radio_status\" : $FA_RADIO_STATUS"
            OUTPUT_JSON+=", \"radio_message\" : $FA_RADIO_MESSAGE"
            OUTPUT_JSON+="}"
        fi

        # FlightRadar24 Stats
        if [[ -n "$FR_JSON_URL" ]]; then
            FR_FEED_ALIAS=$(curl --silent "$FR_JSON_URL" | jq '.feed_alias')
            FR_BUILD_VERSION=$(curl --silent "$FR_JSON_URL" | jq '.build_version')
            FR_CONNECT_STATUS=$(curl --silent "$FR_JSON_URL" | jq '.feed_status')
            FR_CONNECT_MODE=$(curl --silent "$FR_JSON_URL" | jq '.feed_current_mode')
            FR_CONNECT_LAST_CONFIG=$(curl --silent "$FR_JSON_URL" | jq '.feed_last_config_info')
            FR_AIRCRAFT_TRACKED=$(curl --silent "$FR_JSON_URL" | jq '.d11_map_size')
            FR_AIRCRAFT_UPLOADED=$(curl --silent "$FR_JSON_URL" | jq '.feed_num_ac_tracked')

            OUTPUT_JSON+=", \"flightradar24\" : {"
            if [[ $FR_CONNECT_STATUS == "\"connected\"" ]]; then
                OUTPUT_JSON+=" \"connected\" : \"Yes\""
                OUTPUT_JSON+=", \"connect_mode\" : $FR_CONNECT_MODE"
            else
                OUTPUT_JSON+=" \"connected\" : \"No\""
                OUTPUT_JSON+=", \"connect_mode\" : \"N/A\""
                OUTPUT_JSON+=", \"connect_error\" : $FR_CONNECT_LAST_CONFIG"
            fi
            OUTPUT_JSON+=", \"version\" : $FR_BUILD_VERSION"
            OUTPUT_JSON+=", \"feed_alias\" : $FR_FEED_ALIAS"
            OUTPUT_JSON+=", \"aircraft_tracked\" : $FR_AIRCRAFT_TRACKED"
            OUTPUT_JSON+=", \"aircraft_uploaded\" : $FR_AIRCRAFT_UPLOADED"
            OUTPUT_JSON+="}"
        fi

        # Planefinder Stats
        if [[ -n "$PF_JSON_URL" ]]; then
            PF_BUILD_VERSION=$(curl --silent "$PF_JSON_URL" | jq '.client_version')
            PF_UPLOAD_TODAY=$(curl --silent "$PF_JSON_URL" | jq '.master_server_bytes_out')
            PF_UPLOAD_PREV=$(curl --silent "$PF_JSON_URL" | jq '.prev_master_server_bytes_out')
            PF_START_TIME=$(curl --silent "$PF_JSON_URL" | jq '.executable_start_time')
            PF_MODES_TODAY=$(curl --silent "$PF_JSON_URL" | jq '.total_modes_packets')
            PF_MODES_PREV=$(curl --silent "$PF_JSON_URL" | jq '.prev_total_modes_packets')
            PF_MODEAC_TODAY=$(curl --silent "$PF_JSON_URL" | jq '.total_modeac_packets')
            PF_MODEAC_PREV=$(curl --silent "$PF_JSON_URL" | jq '.prev_total_modeac_packets')

            OUTPUT_JSON+=", \"planefinder\" : {"
            OUTPUT_JSON+=" \"version\" : $PF_BUILD_VERSION"
            OUTPUT_JSON+=", \"start_time\" : $PF_START_TIME"
            OUTPUT_JSON+=", \"data_upload_today_bytes\" : $PF_UPLOAD_TODAY"
            OUTPUT_JSON+=", \"data_upload_prev_bytes\" : $PF_UPLOAD_PREV"
            OUTPUT_JSON+=", \"modes_today_packets\" : $PF_MODES_TODAY"
            OUTPUT_JSON+=", \"modes_prev_packets\" : $PF_MODES_PREV"
            OUTPUT_JSON+=", \"modeac_today_packets\" : $PF_MODEAC_TODAY"
            OUTPUT_JSON+=", \"modeac_prev_packets\" : $PF_MODEAC_PREV"
            OUTPUT_JSON+="}"
        fi        

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

        # Finalise output JSON
        OUTPUT_JSON+=" }"

        if [[ -n "$MQTT_USER" ]];
        then
            /usr/bin/mosquitto_pub -h "$MQTT_HOST" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$MQTT_TOPIC" -m "$OUTPUT_JSON"
        else
            /usr/bin/mosquitto_pub -h "$MQTT_HOST" -t "$MQTT_TOPIC" -m "$OUTPUT_JSON"
        fi

        sleep "$MQTT_INTERVAL"

    done
