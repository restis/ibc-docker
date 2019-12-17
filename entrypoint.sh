#!/bin/bash

sed -i -e "s/TWS_MAJOR_VRSN=972/TWS_MAJOR_VRSN=978/g" /opt/ibc/gatewaystart.sh

if [[ -n "${IBC_INI}" ]]; then
    sed -i -e "s/IBC_INI=~\/ibc\/config\.ini/IBC_INI=${IBC_INI//\//\\/}/g" /opt/ibc/gatewaystart.sh
    head -n 30 /opt/ibc/gatewaystart.sh
fi

/dockerstartup/vnc_startup.sh /opt/ibc/gatewaystart.sh -inline
