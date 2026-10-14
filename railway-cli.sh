#!/data/data/com.termux/files/usr/bin/bash

BASE_PROJECT_DIR="$HOME/railway-projek"
CONFIG_FILE="$HOME/.railway/config.json"

mkdir -p "$BASE_PROJECT_DIR"

# Definisi Warna ANSI
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[1;34m"
C_MAGENTA="\033[1;35m"
C_RED="\033[1;31m"
C_WHITE="\033[1;37m"

clear_screen() {
    clear
    echo -e "${C_CYAN}${C_BOLD}"
    cat << "EOF"
  ____       _ _                         
 |  _ \ __ _(_) |_      ____ _ _   _     
 | |_) / _` | | \ \ /\ / / _` | | | |    
 |  _ < (_| | | |\ V  V / (_| | |_| |    
 |_| \_\__,_|_|_| \_/\_/ \__,_|\__, |    
                               |___/     
    A U T O M A T I O N   T O O L        
EOF
    echo -e "${C_BLUE}==========================================${C_RESET}"
}

get_token() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo ""
        return
    fi
    jq -r '.user.accessToken // empty' "$CONFIG_FILE"
}

select_local_project() {
    clear_screen
    echo -e "${C_YELLOW}${C_BOLD}[ FOLDER PROJEK LOKAL ]${C_RESET}"
    echo -e "Lokasi: ${C_WHITE}$BASE_PROJECT_DIR${C_RESET}"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    
    projects=($(find "$BASE_PROJECT_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))
    
    if [ ${#projects[@]} -eq 0 ]; then
        echo -e "${C_RED}Belum ada folder project di $BASE_PROJECT_DIR!${C_RESET}"
        echo -e "Silakan clone repo via menu [3] terlebih dahulu."
        read -p "Tekan Enter untuk kembali..."
        return 1
    fi

    for i in "${!projects[@]}"; do
        echo -e "${C_GREEN}$((i+1)).${C_RESET} ${C_WHITE}${projects[$i]}${C_RESET}"
    done
    echo -e "${C_RED}0. Batal / Kembali${C_RESET}"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    read -p "Pilih nomor project [0-${#projects[@]}]: " p_choice

    if [ "$p_choice" = "0" ] || [ -z "$p_choice" ]; then
        return 1
    fi

    idx=$((p_choice-1))
    if [ -n "${projects[$idx]}" ]; then
        TARGET_DIR="$BASE_PROJECT_DIR/${projects[$idx]}"
        return 0
    else
        echo -e "${C_RED}Pilihan tidak valid!${C_RESET}"
        sleep 1
        return 1
    fi
}

menu_install_deps() {
    clear_screen
    echo -e "${C_YELLOW}${C_BOLD}[1] INSTALL DEPENDENCIES${C_RESET}"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}1.${C_RESET} Mulai Install (curl, jq, git, railway)"
    echo -e "${C_RED}0.${C_RESET} Batal / Kembali"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    read -p "Pilih opsi [0-1]: " ins_opt
    if [ "$ins_opt" != "1" ]; then
        return
    fi

    echo -e "\n${C_CYAN}[*] Menginstal paket dasar...${C_RESET}"
    pkg update -y
    pkg install curl jq git dnsutils -y
    
    if ! pkg install railway-cli -y 2>/dev/null; then
        echo -e "${C_YELLOW}[*] Mencoba install Railway CLI via npm...${C_RESET}"
        pkg install nodejs -y
        npm install -g @railway/cli
    fi
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}✓ Semua dependensi berhasil dipasang!${C_RESET}"
    read -p "Tekan Enter untuk kembali..."
}

menu_login() {
    clear_screen
    echo -e "${C_YELLOW}${C_BOLD}[2] LOGIN KE AKUN RAILWAY${C_RESET}"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}1.${C_RESET} Login(Link Browser percobaan daftar)"
    echo -e "${C_GREEN}2.${C_RESET} login dengan personal api token"
    echo -e "${C_GREEN}3.${C_RESET} login cepat tinggal klik tombol auth"
    echo -e "${C_RED}0.${C_RESET} Batal / Kembali"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    read -p "Pilih opsi [0-3]: " log_opt

    case $log_opt in
        1)
            echo -e "\n${C_CYAN}[*] Menjalankan login cepat...${C_RESET}"
            railway login --browserless
            read -p "Tekan Enter untuk kembali..."
            ;;
        2)
            clear_screen
            echo -e "${C_YELLOW}${C_BOLD}INPUT PERSONAL API TOKEN${C_RESET}"
            echo -e "Ambil token di: ${C_CYAN}https://railway.com/account/tokens${C_RESET}"
            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
            read -p "Masukkan API Token: " RAW_TOKEN
            if [ "$RAW_TOKEN" != "0" ] && [ -n "$RAW_TOKEN" ]; then
                mkdir -p "$HOME/.railway"
                if [ -f "$CONFIG_FILE" ]; then
                    jq --arg tok "$RAW_TOKEN" '.user.accessToken = $tok' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                else
                    echo "{\"user\":{\"accessToken\":\"$RAW_TOKEN\"}}" > "$CONFIG_FILE"
                fi
                echo -e "${C_GREEN}✓ Token berhasil disimpan!${C_RESET}"
            fi
            read -p "Tekan Enter untuk kembali..."
            ;;
        3)
            railway login
            read -p "Tekan Enter untuk kembali..."
            ;;
        *)
            ;;
    esac
}

menu_clone_repo() {
    clear_screen
    echo -e "${C_YELLOW}${C_BOLD}[3] CLONE REPOSITORY GITHUB${C_RESET}"
    echo -e "Folder Tujuan: ${C_WHITE}$BASE_PROJECT_DIR${C_RESET}"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    read -p "Masukkan URL Repository: " REPO_URL

    if [ "$REPO_URL" = "0" ] || [ -z "$REPO_URL" ]; then
        return
    fi

    echo -e "\n${C_CYAN}[*] Meng-clone repository...${C_RESET}"
    cd "$BASE_PROJECT_DIR" || return
    git clone "$REPO_URL"

    if [ $? -eq 0 ]; then
        echo -e "${C_GREEN}✓ Repository berhasil di-clone!${C_RESET}"
    else
        echo -e "${C_RED}✕ Gagal meng-clone repository.${C_RESET}"
    fi
    read -p "Tekan Enter untuk kembali..."
}

menu_list_and_link() {
    TOKEN=$(get_token)
    clear_screen
    echo -e "${C_YELLOW}${C_BOLD}[4] DAFTAR PROJECT AKUN & LINK${C_RESET}"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"

    if [ -z "$TOKEN" ]; then
        echo -e "${C_RED}Error: Belum login ke akun Railway!${C_RESET}"
        read -p "Tekan Enter..."
        return
    fi

    echo -e "${C_CYAN}[*] Mengambil daftar project dari akun Railway...${C_RESET}"
    
    PRJ_RES=$(curl -s -X POST https://backboard.railway.com/graphql/v2 \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "query": "query { me { projects { edges { node { id name } } } workspaces { projects { edges { node { id name } } } } } }"
      }')

    PARSED_PRJS=$(echo "$PRJ_RES" | jq -c '[
      (.data.me.projects.edges[]?.node // empty),
      (.data.me.workspaces[]?.projects.edges[]?.node // empty)
    ] | unique_by(.id)')

    PRJ_COUNT=$(echo "$PARSED_PRJS" | jq 'length // 0')

    if [ "$PRJ_COUNT" -eq 0 ]; then
        CLI_JSON=$(railway list --json 2>/dev/null)
        if [ -n "$CLI_JSON" ] && [ "$CLI_JSON" != "null" ]; then
            PARSED_PRJS=$(echo "$CLI_JSON" | jq -c '[.[]? | {id: .id, name: .name}]')
            PRJ_COUNT=$(echo "$PARSED_PRJS" | jq 'length // 0')
        fi
    fi

    if [ "$PRJ_COUNT" -eq 0 ]; then
        echo -e "${C_RED}Tidak ada project yang ditemukan pada akun ini.${C_RESET}"
        read -p "Tekan Enter..."
        return
    fi

    echo -e "${C_WHITE}Project Ditemukan:${C_RESET}"
    for i in $(seq 0 $((PRJ_COUNT - 1))); do
        P_NAME=$(echo "$PARSED_PRJS" | jq -r ".[$i].name")
        P_ID=$(echo "$PARSED_PRJS" | jq -r ".[$i].id")
        echo -e "${C_GREEN}$((i+1)).${C_RESET} ${C_BOLD}$P_NAME${C_RESET}"
        echo -e "    ID: ${C_CYAN}$P_ID${C_RESET}"
    done
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}1.${C_RESET} Hubungkan (Link) Project ke Folder Lokal"
    echo -e "${C_RED}0.${C_RESET} Kembali ke Menu Utama"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    read -p "Pilih opsi [0-1]: " link_opt

    if [ "$link_opt" = "1" ]; then
        read -p "Pilih nomor project [1-$PRJ_COUNT]: " sel_p
        if [ -z "$sel_p" ] || [ "$sel_p" -lt 1 ] || [ "$sel_p" -gt "$PRJ_COUNT" ]; then
            echo -e "${C_RED}Pilihan tidak valid!${C_RESET}"
            read -p "Tekan Enter..."
            return
        fi

        CHOSEN_ID=$(echo "$PARSED_PRJS" | jq -r ".[$((sel_p - 1))].id")
        CHOSEN_NAME=$(echo "$PARSED_PRJS" | jq -r ".[$((sel_p - 1))].name")

        echo -e "\nPilih folder tujuan di lokal:"
        if select_local_project; then
            cd "$TARGET_DIR" || return
            echo -e "${C_CYAN}[*] Menghubungkan folder ke $CHOSEN_NAME...${C_RESET}"
            railway link --project "$CHOSEN_ID"
            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
            echo -e "${C_GREEN}✓ Sukses terhubung ke project: $CHOSEN_NAME!${C_RESET}"
            read -p "Tekan Enter untuk kembali..."
        fi
    fi
}

menu_unlink_clean() {
    clear_screen
    echo -e "${C_YELLOW}${C_BOLD}[5] UNLINK & RESET CACHE FOLDER${C_RESET}"
    echo -e "Gunakan opsi ini saat ingin berganti akun di project yang sama."
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    if select_local_project; then
        cd "$TARGET_DIR" || return
        echo -e "\nFolder target: ${C_WHITE}$TARGET_DIR${C_RESET}"
        echo -e "${C_RED}Yakin ingin unlink dan menghapus cache link di folder ini?${C_RESET}"
        read -p "Ketik 'y' untuk konfirmasi [y/N]: " confirm_unlink

        if [ "$confirm_unlink" = "y" ] || [ "$confirm_unlink" = "Y" ]; then
            echo -e "${C_CYAN}[*] Menjalankan railway unlink...${C_RESET}"
            railway unlink 2>/dev/null
            
            echo -e "${C_CYAN}[*] Menghapus folder cache lokal (.railway)...${C_RESET}"
            rm -rf .railway
            
            echo -e "${C_CYAN}[*] Membersihkan cache mapping dari config.json...${C_RESET}"
            if [ -f "$CONFIG_FILE" ]; then
                jq --arg dir "$TARGET_DIR" 'del(.projects[$dir])' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
            fi
            
            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
            echo -e "${C_GREEN}✓ Berhasil di-unlink & riwayat folder dibersihkan total!${C_RESET}"
            echo -e "Folder sekarang bebas di-link ke akun Railway mana saja."
        else
            echo -e "${C_YELLOW}Operasi dibatalkan.${C_RESET}"
        fi
        read -p "Tekan Enter untuk kembali..."
    fi
}

menu_deploy() {
    if select_local_project; then
        cd "$TARGET_DIR" || return
        clear_screen
        echo -e "${C_YELLOW}${C_BOLD}[6] DEPLOY / REDEPLOY PROJECT${C_RESET}"
        echo -e "Folder: ${C_WHITE}$TARGET_DIR${C_RESET}"
        echo -e "${C_BLUE}------------------------------------------${C_RESET}"
        echo -e "${C_GREEN}1.${C_RESET} Eksekusi Deploy + Pantau Log Langsung (railway up)"
        echo -e "${C_GREEN}2.${C_RESET} Eksekusi Deploy di Background (railway up --detach)"
        echo -e "${C_RED}0.${C_RESET} Batal / Kembali"
        echo -e "${C_BLUE}------------------------------------------${C_RESET}"
        read -p "Pilih opsi [0-2]: " dep_opt

        case $dep_opt in
            1)
                echo -e "\n${C_CYAN}[*] Mengupload & memantau proses build/deploy...${C_RESET}"
                echo -e "${C_YELLOW}(Tekan Ctrl + C jika ingin keluar dari streaming log)${C_RESET}\n"
                railway up
                echo -e "\n${C_GREEN}✓ Proses deploy selesai / terputus dari stream.${C_RESET}"
                read -p "Tekan Enter untuk kembali..."
                ;;
            2)
                echo -e "\n${C_CYAN}[*] Menjalankan deploy di background...${C_RESET}"
                railway up --detach
                echo -e "${C_GREEN}✓ Deploy berhasil dikirim ke server!${C_RESET}"
                read -p "Tekan Enter untuk kembali..."
                ;;
            *)
                return
                ;;
        esac
    fi
}

menu_change_region() {
    TOKEN=$(get_token)
    clear_screen
    echo -e "${C_YELLOW}${C_BOLD}[7] DEFAULT REGION AKUN (WORKSPACE)${C_RESET}"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"

    if [ -z "$TOKEN" ]; then
        echo -e "${C_RED}Error: Belum login!${C_RESET}"
        read -p "Tekan Enter..."
        return
    fi

    echo -e "${C_CYAN}[*] Mengambil data region akun...${C_RESET}"
    WS_RES=$(curl -s -X POST https://backboard.railway.com/graphql/v2 \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"query": "query { me { workspaces { id name preferredRegion } } }"}')

    WS_ID=$(echo "$WS_RES" | jq -r '.data.me.workspaces[0].id // empty')
    WS_NAME=$(echo "$WS_RES" | jq -r '.data.me.workspaces[0].name // empty')
    CURRENT_REG=$(echo "$WS_RES" | jq -r '.data.me.workspaces[0].preferredRegion // "Belum diset"')

    REGION_LABEL="$CURRENT_REG"
    case $CURRENT_REG in
        sin) REGION_LABEL="Singapore (sin)" ;;
        iad) REGION_LABEL="US East / Virginia (iad)" ;;
        pdx) REGION_LABEL="US West / Oregon (pdx)" ;;
        ams) REGION_LABEL="Europe / Netherlands (ams)" ;;
    esac

    echo -e "Workspace    : ${C_BOLD}$WS_NAME${C_RESET}"
    echo -e "Region Aktif : ${C_GREEN}${C_BOLD}$REGION_LABEL${C_RESET}"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    echo -e "${C_GREEN}1.${C_RESET} Singapore (sin) ${C_YELLOW}[Rekomendasi Tercepat]${C_RESET}"
    echo -e "${C_GREEN}2.${C_RESET} US East / Virginia (iad)"
    echo -e "${C_GREEN}3.${C_RESET} US West / Oregon (pdx)"
    echo -e "${C_GREEN}4.${C_RESET} Europe / Netherlands (ams)"
    echo -e "${C_RED}0.${C_RESET} Batal / Kembali"
    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
    read -p "Pilih opsi [0-4]: " reg_opt

    TARGET_REG=""
    case $reg_opt in
        1) TARGET_REG="sin" ;;
        2) TARGET_REG="iad" ;;
        3) TARGET_REG="pdx" ;;
        4) TARGET_REG="ams" ;;
        *) return ;;
    esac

    echo -e "\n${C_CYAN}[*] Mengubah default region ke $TARGET_REG...${C_RESET}"
    RES=$(jq -n \
      --arg id "$WS_ID" \
      --arg reg "$TARGET_REG" \
      '{
        query: "mutation workspaceUpdate($id: String!, $input: WorkspaceUpdateInput!) { workspaceUpdate(id: $id, input: $input) }",
        variables: { id: $id, input: { preferredRegion: $reg } }
      }' | curl -s -X POST https://backboard.railway.com/graphql/v2 \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d @-)

    SUCCESS=$(echo "$RES" | jq -r '.data.workspaceUpdate // empty')
    if [ "$SUCCESS" = "true" ]; then
        echo -e "${C_GREEN}✓ Berhasil memperbarui region ke: $TARGET_REG${C_RESET}"
    else
        echo -e "${C_RED}✕ Gagal: $(echo "$RES" | jq -r '.errors[0].message // "Error"')${C_RESET}"
    fi
    read -p "Tekan Enter untuk kembali..."
}

menu_http_domain() {
    if select_local_project; then
        cd "$TARGET_DIR" || return
        
        while true; do
            clear_screen
            echo -e "${C_YELLOW}${C_BOLD}[8] KELOLA PUBLIC DOMAIN & TARGET PORT${C_RESET}"
            echo -e "Folder: ${C_WHITE}$TARGET_DIR${C_RESET}"
            echo -e "${C_BLUE}------------------------------------------${C_RESET}"

            TOKEN=$(get_token)
            if [ -z "$TOKEN" ]; then
                echo -e "${C_RED}Error: Belum login!${C_RESET}"
                read -p "Tekan Enter..."
                return
            fi

            echo -e "${C_CYAN}[*] Mengambil data project dari Railway...${C_RESET}"
            STATUS_JSON=$(railway status --json 2>/dev/null)

            PRJ_ID=$(echo "$STATUS_JSON" | jq -r '.id // empty')
            ENV_ID=$(echo "$STATUS_JSON" | jq -r '.environments.edges[0].node.id // empty')
            SRV_ID=$(echo "$STATUS_JSON" | jq -r '.services.edges[0].node.id // empty')

            if [ -z "$PRJ_ID" ]; then
                echo -e "${C_RED}Folder belum ter-link ke Railway. Jalankan menu [4] dahulu!${C_RESET}"
                read -p "Tekan Enter..."
                return
            fi

            DOMAINS_COUNT=$(echo "$STATUS_JSON" | jq -r '.environments.edges[0].node.serviceInstances.edges[0].node.domains.serviceDomains | length // 0')

            echo -e "Project : ${C_BOLD}$(echo "$STATUS_JSON" | jq -r '.name')${C_RESET}"
            echo -e "Service : ${C_BOLD}$(echo "$STATUS_JSON" | jq -r '.services.edges[0].node.name')${C_RESET}"
            echo -e "${C_BLUE}------------------------------------------${C_RESET}"

            if [ "$DOMAINS_COUNT" -gt 0 ]; then
                echo -e "${C_WHITE}Daftar Domain Aktif:${C_RESET}"
                for i in $(seq 0 $((DOMAINS_COUNT - 1))); do
                    D_NAME=$(echo "$STATUS_JSON" | jq -r ".environments.edges[0].node.serviceInstances.edges[0].node.domains.serviceDomains[$i].domain")
                    D_PORT=$(echo "$STATUS_JSON" | jq -r ".environments.edges[0].node.serviceInstances.edges[0].node.domains.serviceDomains[$i].targetPort // \"Default\"")
                    echo -e "${C_GREEN}$((i+1)).${C_RESET} ${C_CYAN}https://$D_NAME${C_RESET} (Port: ${C_YELLOW}$D_PORT${C_RESET})"
                done
            else
                echo -e "${C_RED}Belum ada domain terpasang pada service ini.${C_RESET}"
            fi

            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
            echo -e "${C_GREEN}1.${C_RESET} Edit Domain & Port"
            echo -e "${C_GREEN}2.${C_RESET} Buat Domain Baru (Generate Railway)"
            echo -e "${C_RED}0.${C_RESET} Batal / Kembali ke Menu Utama"
            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
            read -p "Pilih menu [0-2]: " d_act

            case $d_act in
                1)
                    if [ "$DOMAINS_COUNT" -eq 0 ]; then
                        echo -e "${C_RED}Belum ada domain untuk diedit. Buat baru lewat opsi [2]!${C_RESET}"
                        read -p "Tekan Enter..."
                        continue
                    fi

                    clear_screen
                    echo -e "${C_YELLOW}${C_BOLD}PILIH DOMAIN YANG INGIN DIEDIT${C_RESET}"
                    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
                    for i in $(seq 0 $((DOMAINS_COUNT - 1))); do
                        D_NAME=$(echo "$STATUS_JSON" | jq -r ".environments.edges[0].node.serviceInstances.edges[0].node.domains.serviceDomains[$i].domain")
                        D_PORT=$(echo "$STATUS_JSON" | jq -r ".environments.edges[0].node.serviceInstances.edges[0].node.domains.serviceDomains[$i].targetPort // \"Default\"")
                        echo -e "${C_GREEN}$((i+1)).${C_RESET} ${C_CYAN}https://$D_NAME${C_RESET} (Port: ${C_YELLOW}$D_PORT${C_RESET})"
                    done
                    echo -e "${C_RED}0. Batal${C_RESET}"
                    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
                    read -p "Pilih nomor domain [1-$DOMAINS_COUNT, 0 batal]: " pick_num

                    if [ "$pick_num" = "0" ] || [ -z "$pick_num" ]; then
                        continue
                    fi

                    if [ "$pick_num" -lt 1 ] || [ "$pick_num" -gt "$DOMAINS_COUNT" ]; then
                        echo -e "${C_RED}Pilihan tidak valid!${C_RESET}"
                        read -p "Tekan Enter..."
                        continue
                    fi

                    SEL_INDEX=$((pick_num - 1))
                    CURR_DOM_ID=$(echo "$STATUS_JSON" | jq -r ".environments.edges[0].node.serviceInstances.edges[0].node.domains.serviceDomains[$SEL_INDEX].id")
                    CURR_DOM_NAME=$(echo "$STATUS_JSON" | jq -r ".environments.edges[0].node.serviceInstances.edges[0].node.domains.serviceDomains[$SEL_INDEX].domain")
                    CURR_PORT=$(echo "$STATUS_JSON" | jq -r ".environments.edges[0].node.serviceInstances.edges[0].node.domains.serviceDomains[$SEL_INDEX].targetPort // \"Default\"")

                    echo -e "\nDomain Terpilih : ${C_CYAN}https://$CURR_DOM_NAME${C_RESET}"
                    echo -e "Port Saat Ini   : ${C_YELLOW}$CURR_PORT${C_RESET}"
                    echo -e "${C_BLUE}------------------------------------------${C_RESET}"

                    while true; do
                        read -p "Ketik subdomain baru (Enter jika tetap, 0 batal): " RAW_SUB

                        if [ "$RAW_SUB" = "0" ]; then
                            break
                        fi

                        TARGET_DOMAIN="$CURR_DOM_NAME"

                        if [ -n "$RAW_SUB" ]; then
                            SUB_NAME=$(echo "$RAW_SUB" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
                            if [ -z "$SUB_NAME" ]; then
                                echo -e "${C_RED}Karakter tidak valid! Gunakan hanya a-z, 0-9, atau dash (-).${C_RESET}"
                                continue
                            fi
                            TARGET_DOMAIN="$SUB_NAME.up.railway.app"
                        fi

                        echo ""
                        read -p "Masukkan Port Container Target (misal: 8080, Enter jika tetap): " INPUT_PORT

                        FINAL_PORT=null
                        if [ -n "$INPUT_PORT" ]; then
                            FINAL_PORT=$INPUT_PORT
                        elif [ "$CURR_PORT" != "Default" ] && [ -n "$CURR_PORT" ]; then
                            FINAL_PORT=$CURR_PORT
                        fi

                        echo -e "\n${C_CYAN}[*] Menerapkan perubahan ke server Railway...${C_RESET}"

                        PAYLOAD=$(jq -n \
                          --arg did "$CURR_DOM_ID" \
                          --arg eid "$ENV_ID" \
                          --arg sid "$SRV_ID" \
                          --arg dom "$TARGET_DOMAIN" \
                          --argjson port "$FINAL_PORT" \
                          '{
                            query: "mutation updateDomain($input: ServiceDomainUpdateInput!) { serviceDomainUpdate(input: $input) }",
                            variables: {
                              input: {
                                serviceDomainId: $did,
                                environmentId: $eid,
                                serviceId: $sid,
                                domain: $dom,
                                targetPort: $port
                              }
                            }
                          }')

                        MUT_RES=$(echo "$PAYLOAD" | curl -s -X POST https://backboard.railway.com/graphql/v2 \
                          -H "Authorization: Bearer $TOKEN" \
                          -H "Content-Type: application/json" \
                          -d @-)

                        IS_SUCCESS=$(echo "$MUT_RES" | jq -r '.data.serviceDomainUpdate // false')
                        ERR=$(echo "$MUT_RES" | jq -r '.errors[0].message // empty')

                        if [ "$IS_SUCCESS" = "true" ]; then
                            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
                            echo -e "${C_GREEN}✓ Pengaturan Berhasil Disimpan!${C_RESET}"
                            echo -e "Domain Aktif : ${C_CYAN}https://$TARGET_DOMAIN${C_RESET}"
                            echo -e "Target Port  : ${C_YELLOW}${FINAL_PORT:-Default}${C_RESET}"
                            read -p "Tekan Enter untuk lanjut..."
                            break
                        else
                            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
                            echo -e "${C_RED}✕ Gagal memperbarui domain/port!${C_RESET}"
                            if [ -n "$ERR" ]; then
                                echo -e "Pesan server: $ERR"
                            else
                                echo -e "Alasan: Subdomain '$TARGET_DOMAIN' SUDAH TERPAKAI atau ditolak server."
                            fi
                            echo -e "Silakan coba masukkan nama lain di bawah:\n"
                        fi
                    done
                    ;;

                2)
                    echo ""
                    read -p "Masukkan Target Port Container (Enter jika default): " N_PORT
                    N_PORT=${N_PORT:-null}

                    echo -e "\n${C_CYAN}[*] Mendaftarkan domain baru...${C_RESET}"
                    PAYLOAD=$(jq -n \
                      --arg env "$ENV_ID" \
                      --arg srv "$SRV_ID" \
                      --argjson port "$N_PORT" \
                      '{
                        query: "mutation createDomain($input: ServiceDomainCreateInput!) { serviceDomainCreate(input: $input) { id domain targetPort } }",
                        variables: {
                          input: (if $port == null then { environmentId:$env, serviceId: $srv } else { environmentId:$env, serviceId: $srv, targetPort:$port } end)
                        }
                      }')

                    RES=$(echo "$PAYLOAD" | curl -s -X POST https://backboard.railway.com/graphql/v2 \
                      -H "Authorization: Bearer $TOKEN" \
                      -H "Content-Type: application/json" \
                      -d @-)

                    ERR=$(echo "$RES" | jq -r '.errors[0].message // empty')
                    if [ -n "$ERR" ]; then
                        echo -e "${C_RED}Gagal: $ERR${C_RESET}"
                    else
                        NEW_DOM=$(echo "$RES" | jq -r '.data.serviceDomainCreate.domain')
                        echo -e "${C_GREEN}✓ Berhasil dibuat: https://$NEW_DOM${C_RESET}"
                    fi
                    read -p "Tekan Enter untuk lanjut..."
                    ;;

                0)
                    return
                    ;;

                *)
                    ;;
            esac
        done
    fi
}

menu_tcp_proxy() {
    if select_local_project; then
        cd "$TARGET_DIR" || return
        clear_screen
        echo -e "${C_YELLOW}${C_BOLD}[9] BUAT TCP PROXY (PORT FORWARD)${C_RESET}"
        echo -e "Folder: ${C_WHITE}$TARGET_DIR${C_RESET}"
        echo -e "${C_BLUE}------------------------------------------${C_RESET}"
        
        TOKEN=$(get_token)
        if [ -z "$TOKEN" ]; then
            echo -e "${C_RED}Error: Belum login!${C_RESET}"
            read -p "Tekan Enter..."
            return
        fi

        STATUS_JSON=$(railway status --json 2>/dev/null)
        ENV_ID=$(echo "$STATUS_JSON" | jq -r '.environments.edges[0].node.id // empty')
        SRV_ID=$(echo "$STATUS_JSON" | jq -r '.services.edges[0].node.id // empty')

        echo -e "Project ID : $(echo "$STATUS_JSON" | jq -r '.id')"
        echo -e "Service ID : $SRV_ID"
        echo -e "${C_BLUE}------------------------------------------${C_RESET}"
        read -p "Masukkan Port Internal Container (contoh: 8881 / 22): " APP_PORT

        if [ "$APP_PORT" = "0" ] || [ -z "$APP_PORT" ]; then
            return
        fi

        echo -e "\n${C_CYAN}[*] Mengirim request ke Railway...${C_RESET}"
        RES=$(curl -s -X POST https://backboard.railway.com/graphql/v2 \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d "{
            \"query\": \"mutation tcpProxyCreate(\$input: TCPProxyCreateInput!) { tcpProxyCreate(input: \$input) { id domain proxyPort applicationPort } }\",
            \"variables\": {
              \"input\": {
                \"environmentId\": \"$ENV_ID\",
                \"serviceId\": \"$SRV_ID\",
                \"applicationPort\": $APP_PORT
              }
            }
          }")

        ERR=$(echo "$RES" | jq -r '.errors[0].message // empty')
        if [ -n "$ERR" ]; then
            echo -e "${C_RED}Gagal membuat TCP Proxy: $ERR${C_RESET}"
        else
            DOMAIN=$(echo "$RES" | jq -r '.data.tcpProxyCreate.domain // empty' | sed 's/\.$//')
            PROXY_PORT=$(echo "$RES" | jq -r '.data.tcpProxyCreate.proxyPort // empty')
            echo -e "${C_GREEN}✓ TCP Proxy Berhasil Dibuat!${C_RESET}"
            echo -e "Host / Domain : ${C_CYAN}$DOMAIN${C_RESET}"
            echo -e "Public Port   : ${C_YELLOW}$PROXY_PORT${C_RESET}"
            echo -e "Target Port   : $APP_PORT"
        fi
        read -p "Tekan Enter untuk kembali..."
    fi
}

menu_env_vars() {
    if select_local_project; then
        cd "$TARGET_DIR" || return
        clear_screen
        echo -e "${C_YELLOW}${C_BOLD}[10] KELOLA ENVIRONMENT VARIABLES${C_RESET}"
        echo -e "Folder: ${C_WHITE}$TARGET_DIR${C_RESET}"
        echo -e "${C_BLUE}------------------------------------------${C_RESET}"
        echo -e "${C_GREEN}1.${C_RESET} Lihat Semua Variables"
        echo -e "${C_GREEN}2.${C_RESET} Set Variable Baru (contoh: PORT=8081)"
        echo -e "${C_RED}0.${C_RESET} Batal / Kembali"
        echo -e "${C_BLUE}------------------------------------------${C_RESET}"
        read -p "Pilih menu [0-2]: " ev_opt

        case $ev_opt in
            1)
                railway variables
                read -p "Tekan Enter untuk kembali..."
                ;;
            2)
                read -p "Masukkan KEY=VALUE: " VAR_PAIR
                if [ "$VAR_PAIR" != "0" ] && [ -n "$VAR_PAIR" ]; then
                    railway variables --set "$VAR_PAIR"
                fi
                read -p "Tekan Enter untuk kembali..."
                ;;
            *)
                ;;
        esac
    fi
}

menu_logs() {
    if select_local_project; then
        cd "$TARGET_DIR" || return
        clear_screen
        echo -e "${C_YELLOW}Menampilkan Log (Tekan Ctrl + C untuk keluar)...${C_RESET}"
        sleep 1
        railway logs
    fi
}

while true; do
    clear_screen
    TOKEN_STATUS=$(get_token)
    if [ -n "$TOKEN_STATUS" ]; then
        echo -e "Status Login : ${C_GREEN}● Terhubung${C_RESET}"
    else
        echo -e "Status Login : ${C_RED}○ Belum Login${C_RESET}"
    fi
    echo -e "Folder Projek: ${C_CYAN}$BASE_PROJECT_DIR${C_RESET}"
    echo -e "${C_BLUE}==========================================${C_RESET}"
    echo -e "${C_GREEN} 1.${C_RESET} Install Dependencies (curl, jq, git, cli)"
    echo -e "${C_GREEN} 2.${C_RESET} Login ke Akun Railway"
    echo -e "${C_GREEN} 3.${C_RESET} Clone Repo GitHub ke Folder Projek"
    echo -e "${C_GREEN} 4.${C_RESET} Daftar Project Akun & Link ke Folder"
    echo -e "${C_GREEN} 5.${C_RESET} Unlink Project & Reset Cache (.railway)"
    echo -e "${C_GREEN} 6.${C_RESET} Deploy / Redeploy (Live Log / Background)"
    echo -e "${C_GREEN} 7.${C_RESET} Ubah Region Akun (Cek & Ubah)"
    echo -e "${C_GREEN} 8.${C_RESET} Buat / Edit Public Domain (Custom Domain & Port)"
    echo -e "${C_GREEN} 9.${C_RESET} Buat TCP Proxy (Auto Port Forward)"
    echo -e "${C_GREEN}10.${C_RESET} Tambah / Cek Variable (format VARIABEL=value)"
    echo -e "${C_GREEN}11.${C_RESET} Cek Log Realtime"
    echo -e "${C_RED} 0.${C_RESET} Keluar"
    echo -e "${C_BLUE}==========================================${C_RESET}"
    read -p "Pilih menu [0-11]: " main_choice

    case $main_choice in
        1) menu_install_deps ;;
        2) menu_login ;;
        3) menu_clone_repo ;;
        4) menu_list_and_link ;;
        5) menu_unlink_clean ;;
        6) menu_deploy ;;
        7) menu_change_region ;;
        8) menu_http_domain ;;
        9) menu_tcp_proxy ;;
        10) menu_env_vars ;;
        11) menu_logs ;;
        0) exit 0 ;;
        *) echo -e "${C_RED}Pilihan tidak valid!${C_RESET}"; sleep 1 ;;
    esac
done
