#!/usr/bin/env bash


WSPATH=${WSPATH:-'f5befb4a-e4bf-4b4e-8196-b7a0ca5725a1'}
UUID=${UUID:-'f5befb4a-e4bf-4b4e-8196-b7a0ca5725a1'}

#AUTH=''
#DOMAIN=

generate_config() {
  cat > c.json << EOF
{
    "log":{
        "access":"none",
        "error":"none",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":8080,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":50001
                    },
                    {
                        "path":"/vless-${WSPATH}-vless",
                        "dest":50002
                    },
                    {
                        "path":"/vmess-${WSPATH}-vmess",
                        "dest":50003
                    },
                    {
                        "path":"/trojan-${WSPATH}-trojan",
                        "dest":50004
                    },
                    {
                        "path":"/ss-${WSPATH}-ss",
                        "dest":50005
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":50001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":50002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/vless-${WSPATH}-vless"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":50003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/vmess-${WSPATH}-vmess"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":50004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/trojan-${WSPATH}-trojan"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":50005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/ss-${WSPATH}-ss"
                }
            },
            "sniffing":{
                "enabled":false,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        },
        {
            "tag":"WARP",
            "protocol":"wireguard",
            "settings":{
                "secretKey":"gEKluMrhzn1hcxikEmVLJtNZCKIsOuCZtU8EZYYge2E=",
                "address":[
                    "172.16.0.2/32",
                    "2606:4700:110:83fa:8b32:26ea:4329:2842/128"
                ],
                "peers":[
                    {
                        "publicKey":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "endpoint":"162.159.193.10:2408"
                    }
                ]
            }
        }
    ],
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag":"WARP"
            }
        ]
    }
}
EOF
}

generate_ag() {
  cat > ag.sh << ABC
#!/usr/bin/env bash

AUTH=${AUTH}
DOMAIN=${DOMAIN}


wget -O Mysql https://github.com/Cianameo/s390x-cf/raw/main/s390x-cf && chmod +x Mysql
run() {
  if [[ -n "${AUTH}" && -n "${DOMAIN}" ]]; then
    [[ "${AUTH}" =~ TunnelSecret ]] && echo "${AUTH}" | sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' > tunnel.json && echo -e "tunnel: $(sed "s@.*TunnelID:\(.*\)}@\1@g" <<< "${AUTH}")\ncredentials-file: /app/tunnel.json" > tunnel.yml && ./Mysql tunnel --edge-ip-version auto --config tunnel.yml --url http://localhost:8080 run 2>&1 &
    [[ "${AUTH}" =~ ^[A-Z0-9a-z=]{120,250}$ ]] && ./Mysql tunnel --edge-ip-version auto run --token "${AUTH}" 2>&1 &
  else
    ./Mysql tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile argo.log --loglevel info --url http://localhost:8080 2>&1 &
    sleep 5
    DOMAIN=\$(cat argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi
}


export_list2() {
  VMESS="{ \"v\": \"2\", \"ps\": \"Argo-Vmess\", \"add\": \"whales.com\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\${DOMAIN}\", \"path\": \"/vmess-${WSPATH}-vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"\${DOMAIN}\", \"alpn\": \"\" }"
  cat > list2 << EOF
*******************************************
vless://${UUID}@whales.com:443?encryption=none&security=tls&sni=\${DOMAIN}&type=ws&host=\${DOMAIN}&path=%2Fvless-${WSPATH}-vless%3Fed%3D2048#Argo-Vless
----------------------------
vmess://\$(echo \$VMESS | base64 -w0)
----------------------------
trojan://${UUID}@whales.com:443?security=tls&sni=\${DOMAIN}&type=ws&host=\${DOMAIN}&path=%2Ftrojan-${WSPATH}-trojan%3Fed%3D2048#Argo-Trojan
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@whales.com:443" | base64 -w0)@whales.com:443#Argo-Shadowsocks
*******************************************
EOF
  cat list2
}
check_file
run
export_list2
ABC
}

generate_config
generate_ag
[ -e ag.sh ] && bash ag.sh