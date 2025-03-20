#!/usr/bin/env sh

if [ -d /sys/class/net/tun_srsue ]; then
    echo "configuring ip tables"
    ip route del 172.22.0.0/24 && ip route add $SRS_ENB_IP dev eth0 proto kernel scope link src $SRS_UE_IP && \
    ip route del default && ip route add default via 192.168.100.1 dev tun_srsue
fi

pjsua \
    --log-level=6 \
    --registrar=sip:ims.mnc001.mcc001.3gppnetwork.org \
    --id=sip:$UE1_IMSI@ims.mnc001.mcc001.3gppnetwork.org \
    --nameserver=$DNS_IP \
    --proxy sip:pcscf.ims.mnc001.mcc001.3gppnetwork.org \
    --realm=ims.mnc001.mcc001.3gppnetwork.org \
    --username=$UE1_IMSI@ims.mnc001.mcc001.3gppnetwork.org \
    --password="$(echo $UE1_KI | xxd -r -p)" \
    --aka-op="$(echo $UE1_OP | xxd -r -p)" \
    --aka-amf="$(echo $UE1_AMF | xxd -r -p)" \
    --use-ims \
    $@
