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

# Bersihkan ref rusak sisa penyalinan folder .git pakai file manager,
# contohnya file bernama "main (1)" di .git/refs/heads/ yang bikin
# git fetch gagal dengan pesan: fatal: bad object refs/heads/main (1)
repair_git_refs() {
    if [ -d ".git/refs" ]; then
        find .git/refs -type f -name "*(*)*" 2>/dev/null | while read -r badref; do
            echo -e "${C_YELLOW}[!] Ref rusak dibersihkan: $badref${C_RESET}"
            rm -f "$badref"
        done
    fi
    if [ -f ".git/packed-refs" ] && grep -q " (" .git/packed-refs 2>/dev/null; then
        grep -v " (" .git/packed-refs > .git/packed-refs.tmp 2>/dev/null && mv .git/packed-refs.tmp .git/packed-refs
        echo -e "${C_YELLOW}[!] Entri ref rusak di packed-refs dibersihkan.${C_RESET}"
    fi
}

menu_gitfull() {
    if select_local_project; then
        cd "$TARGET_DIR" || return
        clear_screen
        echo -e "${C_YELLOW}${C_BOLD}[12] GITFULL - SINKRON DARI GITHUB (PULL AMAN)${C_RESET}"
        echo -e "Folder: ${C_WHITE}$TARGET_DIR${C_RESET}"
        echo -e "${C_BLUE}------------------------------------------${C_RESET}"

        git config user.name "Ddfathu" 2>/dev/null
        git config user.email "Ddfathu@users.noreply.github.com" 2>/dev/null

        # Folder belum jadi repo git: tawarkan sambungkan ke GitHub
        if [ ! -d ".git" ]; then
            echo -e "${C_YELLOW}[!] Folder ini belum terhubung ke Git (tidak ada .git).${C_RESET}"
            read -p "Masukkan URL repo GitHub untuk disambungkan (Enter untuk batal): " NEW_REPO_URL
            if [ -z "$NEW_REPO_URL" ]; then
                echo -e "${C_YELLOW}Operasi dibatalkan.${C_RESET}"
                read -p "Tekan Enter untuk kembali..."
                return
            fi
            git init -q
            git remote add origin "$NEW_REPO_URL"
            echo -e "${C_GREEN}✓ Repo tersambung ke $NEW_REPO_URL${C_RESET}"
        fi

        # Bereskan dulu ref lokal yang rusak (sisa salinan file manager)
        repair_git_refs

        # Pastikan remote origin ada
        if ! git remote get-url origin >/dev/null 2>&1; then
            echo -e "${C_YELLOW}[!] Remote 'origin' belum ada di folder ini.${C_RESET}"
            read -p "Masukkan URL repo GitHub: " NEW_REPO_URL
            if [ -z "$NEW_REPO_URL" ]; then
                echo -e "${C_YELLOW}Operasi dibatalkan.${C_RESET}"
                read -p "Tekan Enter untuk kembali..."
                return
            fi
            git remote add origin "$NEW_REPO_URL"
        fi
        echo -e "Remote origin : ${C_CYAN}$(git remote get-url origin)${C_RESET}"

        # Branch yang disinkronkan: default branch aktif saat ini
        CUR_BRANCH=$(git branch --show-current 2>/dev/null)
        [ -z "$CUR_BRANCH" ] && CUR_BRANCH="main"
        read -p "Branch yang mau disinkronkan [$CUR_BRANCH]: " IN_BRANCH
        GF_BRANCH="${IN_BRANCH:-$CUR_BRANCH}"

        echo -e "${C_CYAN}[*] Mengambil data terbaru dari GitHub (fetch)...${C_RESET}"
        if ! git fetch origin "$GF_BRANCH"; then
            echo -e "${C_YELLOW}[!] Fetch pertama gagal, mencoba perbaiki ref lokal lalu ulangi...${C_RESET}"
            repair_git_refs
            if ! git fetch origin "$GF_BRANCH"; then
                echo -e "${C_RED}✕ Fetch tetap gagal. Cek koneksi / URL repo / akses repo (repo private butuh token di URL).${C_RESET}"
                read -p "Tekan Enter untuk kembali..."
                return
            fi
        fi

        if ! git rev-parse --verify "origin/$GF_BRANCH" >/dev/null 2>&1; then
            echo -e "${C_RED}✕ Branch '$GF_BRANCH' tidak ditemukan di GitHub.${C_RESET}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi

        # Belum ada commit lokal sama sekali: langsung samakan dengan GitHub
        if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
            git checkout -q -B "$GF_BRANCH" "origin/$GF_BRANCH"
            echo -e "${C_GREEN}✓ Folder disamakan dengan GitHub (branch $GF_BRANCH).${C_RESET}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi

        # Pastikan branch lokalnya ada & aktif
        if [ "$(git branch --show-current)" != "$GF_BRANCH" ]; then
            git checkout -q -B "$GF_BRANCH" "origin/$GF_BRANCH" 2>/dev/null || git checkout -q "$GF_BRANCH"
        fi

        # Hitung posisi lokal vs GitHub
        COUNTS=$(git rev-list --left-right --count "HEAD...origin/$GF_BRANCH" 2>/dev/null)
        AHEAD=$(echo "$COUNTS" | awk '{print $1}')
        BEHIND=$(echo "$COUNTS" | awk '{print $2}')
        AHEAD=${AHEAD:-0}
        BEHIND=${BEHIND:-0}

        echo -e "${C_BLUE}------------------------------------------${C_RESET}"
        echo -e "Status sinkron branch ${C_BOLD}$GF_BRANCH${C_RESET}: lokal ${C_YELLOW}$AHEAD commit di depan${C_RESET}, ${C_YELLOW}$BEHIND commit tertinggal${C_RESET} dari GitHub."

        if [ "$BEHIND" -gt 0 ]; then
            echo -e "${C_WHITE}Commit baru yang akan masuk:${C_RESET}"
            git log --oneline "HEAD..origin/$GF_BRANCH" | head -10 | sed 's/^/  - /'
        fi

        if [ "$BEHIND" -eq 0 ]; then
            echo -e "${C_GREEN}✓ Sudah paling baru, tidak ada yang perlu ditarik.${C_RESET}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi

        # Ada perubahan lokal yang belum ter-commit?
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "${C_YELLOW}[!] Ada perubahan lokal yang belum ter-commit.${C_RESET}"
            echo -e "${C_GREEN}1.${C_RESET} Amankan dulu (stash), tarik, lalu kembalikan ${C_YELLOW}[default]${C_RESET}"
            echo -e "${C_GREEN}2.${C_RESET} Commit perubahan lokal dulu, baru tarik"
            echo -e "${C_RED}3.${C_RESET} Timpa paksa samakan persis GitHub (perubahan lokal HILANG)"
            echo -e "${C_RED}0.${C_RESET} Batal"
            read -p "Pilih cara [1]: " GF_MODE
            GF_MODE=${GF_MODE:-1}

            case $GF_MODE in
                1)
                    echo -e "${C_CYAN}[*] Mengamankan perubahan lokal (stash)...${C_RESET}"
                    git stash push -u -m "gitfull-otomatis" >/dev/null 2>&1
                    if git pull origin "$GF_BRANCH"; then
                        echo -e "${C_CYAN}[*] Mengembalikan perubahan lokal...${C_RESET}"
                        if git stash pop; then
                            echo -e "${C_GREEN}✓ Sinkron selesai, perubahan lokal utuh.${C_RESET}"
                        else
                            echo -e "${C_RED}[!] Ada konflik saat mengembalikan perubahan lokal.${C_RESET}"
                            echo -e "${C_YELLOW}Perubahanmu tetap aman tersimpan di 'git stash list' (stash gitfull-otomatis), selesaikan konfliknya manual ya.${C_RESET}"
                        fi
                    else
                        git stash pop >/dev/null 2>&1
                        echo -e "${C_RED}✕ Pull gagal, perubahan lokal sudah dikembalikan seperti semula.${C_RESET}"
                    fi
                    ;;
                2)
                    read -p "Pesan commit untuk perubahan lokal: " GF_MSG
                    GF_MSG=${GF_MSG:-"update lokal sebelum sinkron"}
                    git add -A
                    git commit -q -m "$GF_MSG"
                    if git pull origin "$GF_BRANCH"; then
                        echo -e "${C_GREEN}✓ Sinkron selesai.${C_RESET}"
                    else
                        echo -e "${C_RED}✕ Pull gagal / ada konflik. Cek pesan git di atas.${C_RESET}"
                    fi
                    ;;
                3)
                    read -p "Yakin timpa paksa? Semua perubahan lokal HILANG [y/N]: " GF_FORCE
                    if [ "$GF_FORCE" = "y" ] || [ "$GF_FORCE" = "Y" ]; then
                        git reset --hard "origin/$GF_BRANCH"
                        git clean -fd
                        echo -e "${C_GREEN}✓ Folder sekarang persis sama dengan GitHub.${C_RESET}"
                    else
                        echo -e "${C_YELLOW}Operasi dibatalkan.${C_RESET}"
                    fi
                    ;;
                *)
                    echo -e "${C_YELLOW}Operasi dibatalkan.${C_RESET}"
                    ;;
            esac
        else
            if [ "$AHEAD" -gt 0 ]; then
                echo -e "${C_YELLOW}[!] Lokal punya $AHEAD commit yang belum ada di GitHub, pull akan menggabungkan (merge).${C_RESET}"
            fi
            echo -e "${C_CYAN}[*] Menarik kode terbaru...${C_RESET}"
            if git pull origin "$GF_BRANCH"; then
                echo -e "${C_GREEN}✓ Sinkron selesai. Commit terbaru: $(git log -1 --oneline)${C_RESET}"
            else
                echo -e "${C_RED}✕ Pull gagal / ada konflik. Cek pesan git di atas.${C_RESET}"
            fi
        fi
        read -p "Tekan Enter untuk kembali..."
    fi
}

# --- Helper Custom Domain (dipakai menu 13) ---
# Semua call memakai GraphQL API yang sama dengan dashboard Railway:
# backboard.railway.com/graphql/v2 (customDomainAvailable / customDomainCreate /
# domains / customDomainDelete). Token diambil dari variabel global TOKEN.
railway_gql() {
    curl -s -X POST https://backboard.railway.com/graphql/v2 \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$1"
}

# Ambil daftar custom domain service ter-link. Hasil:
#   CD_JSON        = array JSON customDomains
#   CD_WITH_STATUS = 1 kalau status DNS/sertifikat ikut kebaca, 0 kalau fallback polos
fetch_custom_domains() {
    CD_WITH_STATUS=1
    local payload res err
    payload=$(jq -n \
      --arg pid "$PRJ_ID" --arg eid "$ENV_ID" --arg sid "$SRV_ID" \
      '{
        query: "query domains($projectId: String!, $environmentId: String!, $serviceId: String!) { domains(projectId: $projectId, environmentId: $environmentId, serviceId: $serviceId) { customDomains { id domain targetPort status { verificationToken certificateStatus dnsRecords { hostlabel recordType requiredValue currentValue status fqdn } } } } }",
        variables: { projectId: $pid, environmentId: $eid, serviceId: $sid }
      }')
    res=$(railway_gql "$payload")
    if ! echo "$res" | jq -e '.data.domains.customDomains' >/dev/null 2>&1; then
        # Fallback: kalau sub-seleksi status ditolak API, ambil daftar polos tanpa status
        CD_WITH_STATUS=0
        payload=$(jq -n \
          --arg pid "$PRJ_ID" --arg eid "$ENV_ID" --arg sid "$SRV_ID" \
          '{
            query: "query domains($projectId: String!, $environmentId: String!, $serviceId: String!) { domains(projectId: $projectId, environmentId: $environmentId, serviceId: $serviceId) { customDomains { id domain targetPort } } }",
            variables: { projectId: $pid, environmentId: $eid, serviceId: $sid }
          }')
        res=$(railway_gql "$payload")
    fi
    CD_JSON=$(echo "$res" | jq -c '.data.domains.customDomains // []' 2>/dev/null)
    [ -z "$CD_JSON" ] && CD_JSON="[]"
}

# Tampilkan record DNS yang wajib dipasang untuk satu custom domain.
# $1 = object JSON satu custom domain (boleh tanpa .status)
print_custom_domain_dns() {
    local node="$1"
    local dom vtok cert n i rtype host req cur st has_txt
    dom=$(echo "$node" | jq -r '.domain // empty')
    vtok=$(echo "$node" | jq -r '.status.verificationToken // empty')
    cert=$(echo "$node" | jq -r '.status.certificateStatus // empty')
    echo -e "${C_WHITE}Record DNS yang WAJIB dipasang di penyedia domain (Cloudflare / registrar):${C_RESET}"
    n=$(echo "$node" | jq -r '.status.dnsRecords | length // 0')
    has_txt=0
    if [ "$n" -gt 0 ]; then
        for i in $(seq 0 $((n - 1))); do
            rtype=$(echo "$node" | jq -r ".status.dnsRecords[$i].recordType // \"CNAME\"")
            host=$(echo "$node" | jq -r ".status.dnsRecords[$i].hostlabel // empty")
            req=$(echo "$node" | jq -r ".status.dnsRecords[$i].requiredValue // empty")
            cur=$(echo "$node" | jq -r ".status.dnsRecords[$i].currentValue // empty")
            st=$(echo "$node" | jq -r ".status.dnsRecords[$i].status // empty")
            [ "$rtype" = "TXT" ] && has_txt=1
            echo -e "  ${C_CYAN}$rtype${C_RESET}  Name: ${C_YELLOW}${host:-@}${C_RESET}  ->  Value: ${C_GREEN}$req${C_RESET}  [Status: $st]"
            if [ -n "$cur" ]; then
                echo -e "         Terbaca di DNS sekarang: $cur"
            fi
        done
    fi
    if [ -n "$vtok" ] && [ "$has_txt" -eq 0 ]; then
        echo -e "  ${C_CYAN}TXT${C_RESET}  Name: ${C_YELLOW}_railway-verify.$dom${C_RESET}  ->  Value: ${C_GREEN}$vtok${C_RESET}"
    fi
    if [ "$n" -eq 0 ] && [ -z "$vtok" ]; then
        echo -e "  ${C_YELLOW}(Detail DNS belum kebaca dari API - cek dashboard Railway > Networking untuk record-nya.)${C_RESET}"
    fi
    if [ -n "$cert" ]; then
        echo -e "Status Sertifikat SSL: ${C_YELLOW}$cert${C_RESET} (berubah jadi ISSUED setelah DNS valid, bisa makan waktu)"
    fi
    echo -e "${C_YELLOW}Catatan Cloudflare:${C_RESET} pasang record persis seperti di atas, dan CNAME set ${C_BOLD}DNS only (awan abu-abu)${C_RESET}; kalau tetap Proxied (awan oranye), sertifikat Railway tidak akan terbit."
}

menu_custom_domain() {
    if select_local_project; then
        cd "$TARGET_DIR" || return

        TOKEN=$(get_token)
        if [ -z "$TOKEN" ]; then
            clear_screen
            echo -e "${C_RED}Error: Belum login ke akun Railway!${C_RESET}"
            read -p "Tekan Enter..."
            return
        fi

        STATUS_JSON=$(railway status --json 2>/dev/null)
        PRJ_ID=$(echo "$STATUS_JSON" | jq -r '.id // empty')
        ENV_ID=$(echo "$STATUS_JSON" | jq -r '.environments.edges[0].node.id // empty')
        SRV_ID=$(echo "$STATUS_JSON" | jq -r '.services.edges[0].node.id // empty')

        if [ -z "$PRJ_ID" ]; then
            clear_screen
            echo -e "${C_RED}Folder belum ter-link ke Railway. Jalankan menu [4] dahulu!${C_RESET}"
            read -p "Tekan Enter..."
            return
        fi

        PRJ_NAME=$(echo "$STATUS_JSON" | jq -r '.name // "-"')
        SRV_NAME=$(echo "$STATUS_JSON" | jq -r '.services.edges[0].node.name // "-"')

        while true; do
            clear_screen
            echo -e "${C_YELLOW}${C_BOLD}[13] CUSTOM DOMAIN (DOMAIN SENDIRI)${C_RESET}"
            echo -e "Folder : ${C_WHITE}$TARGET_DIR${C_RESET}"
            echo -e "Project: ${C_BOLD}$PRJ_NAME${C_RESET}  |  Service: ${C_BOLD}$SRV_NAME${C_RESET}"
            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
            echo -e "${C_CYAN}[*] Mengambil daftar custom domain...${C_RESET}"
            fetch_custom_domains
            CD_COUNT=$(echo "$CD_JSON" | jq 'length // 0')

            if [ "$CD_COUNT" -gt 0 ]; then
                echo -e "${C_WHITE}Custom Domain Terpasang:${C_RESET}"
                for i in $(seq 0 $((CD_COUNT - 1))); do
                    CD_D=$(echo "$CD_JSON" | jq -r ".[$i].domain")
                    CD_P=$(echo "$CD_JSON" | jq -r ".[$i].targetPort // \"Default\"")
                    CD_C=$(echo "$CD_JSON" | jq -r ".[$i].status.certificateStatus // \"-\"")
                    echo -e "${C_GREEN}$((i+1)).${C_RESET} ${C_CYAN}https://$CD_D${C_RESET} (Port: ${C_YELLOW}$CD_P${C_RESET}, SSL: ${C_YELLOW}$CD_C${C_RESET})"
                done
            else
                echo -e "${C_RED}Belum ada custom domain pada service ini.${C_RESET}"
            fi

            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
            echo -e "${C_GREEN}1.${C_RESET} Tambah Custom Domain Baru"
            echo -e "${C_GREEN}2.${C_RESET} Detail DNS & Cek Status (per domain)"
            echo -e "${C_GREEN}3.${C_RESET} Hapus Custom Domain"
            echo -e "${C_RED}0.${C_RESET} Kembali ke Menu Utama"
            echo -e "${C_BLUE}------------------------------------------${C_RESET}"
            read -p "Pilih menu [0-3]: " cd_act

            case $cd_act in
                1)
                    echo ""
                    read -p "Masukkan custom domain (contoh: rail.dfathu.com, 0 batal): " RAW_DOM
                    if [ "$RAW_DOM" = "0" ] || [ -z "$RAW_DOM" ]; then
                        continue
                    fi
                    CD_DOMAIN=$(echo "$RAW_DOM" | tr '[:upper:]' '[:lower:]' | sed -e 's|^https\?://||' -e 's|/.*$||' -e 's|\.$||')
                    if ! echo "$CD_DOMAIN" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$'; then
                        echo -e "${C_RED}Format domain tidak valid! Contoh yang benar: rail.dfathu.com${C_RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi

                    read -p "Target Port Container (contoh: 8082, Enter = default): " CD_PORT_IN
                    CD_PORT=null
                    if [ -n "$CD_PORT_IN" ]; then
                        if echo "$CD_PORT_IN" | grep -qE '^[0-9]+$'; then
                            CD_PORT=$CD_PORT_IN
                        else
                            echo -e "${C_RED}Port harus angka!${C_RESET}"
                            read -p "Tekan Enter untuk lanjut..."
                            continue
                        fi
                    fi

                    echo -e "\n${C_CYAN}[*] Mengecek ketersediaan domain $CD_DOMAIN...${C_RESET}"
                    AV_PAYLOAD=$(jq -n --arg dom "$CD_DOMAIN" \
                      '{
                        query: "query ($domain: String!) { customDomainAvailable(domain: $domain) { available message } }",
                        variables: { domain: $dom }
                      }')
                    AV_RES=$(railway_gql "$AV_PAYLOAD")
                    AV_OK=$(echo "$AV_RES" | jq -r '.data.customDomainAvailable.available // empty')
                    AV_MSG=$(echo "$AV_RES" | jq -r '.data.customDomainAvailable.message // .errors[0].message // empty')
                    if [ "$AV_OK" = "false" ]; then
                        echo -e "${C_RED}✕ Domain tidak bisa ditambahkan: $AV_MSG${C_RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi
                    if [ "$AV_OK" != "true" ] && [ -n "$AV_MSG" ]; then
                        echo -e "${C_YELLOW}[!] Cek ketersediaan tidak jelas ($AV_MSG), tetap dicoba daftarkan...${C_RESET}"
                    fi

                    echo -e "${C_CYAN}[*] Mendaftarkan custom domain ke Railway...${C_RESET}"
                    CR_PAYLOAD=$(jq -n \
                      --arg pid "$PRJ_ID" --arg eid "$ENV_ID" --arg sid "$SRV_ID" --arg dom "$CD_DOMAIN" --argjson port "$CD_PORT" \
                      '{
                        query: "mutation ($input: CustomDomainCreateInput!) { customDomainCreate(input: $input) { id domain targetPort status { verificationToken certificateStatus dnsRecords { hostlabel recordType requiredValue currentValue status fqdn } } } }",
                        variables: {
                          input: (
                            { projectId: $pid, environmentId: $eid, serviceId: $sid, domain: $dom }
                            + (if $port == null then {} else { targetPort: $port } end)
                          )
                        }
                      }')
                    CR_RES=$(railway_gql "$CR_PAYLOAD")
                    CR_ERR=$(echo "$CR_RES" | jq -r '.errors[0].message // empty')
                    CREATED_NODE=$(echo "$CR_RES" | jq -c '.data.customDomainCreate // empty')
                    NEW_ID=$(echo "$CR_RES" | jq -r '.data.customDomainCreate.id // empty')

                    if [ -z "$NEW_ID" ]; then
                        # Kadang domain sebenarnya berhasil dibuat tapi API menolak
                        # sub-seleksi status di respons create -> cek daftar dulu sebelum menyerah
                        fetch_custom_domains
                        CREATED_NODE=$(echo "$CD_JSON" | jq -c --arg d "$CD_DOMAIN" '(.[] | select(.domain == $d)) // empty')
                        NEW_ID=$(echo "$CREATED_NODE" | jq -r '.id // empty' 2>/dev/null)
                    fi

                    if [ -z "$NEW_ID" ]; then
                        echo -e "${C_RED}✕ Gagal menambahkan custom domain!${C_RESET}"
                        if [ -n "$CR_ERR" ]; then echo -e "Pesan server: $CR_ERR"; fi
                        echo -e "${C_YELLOW}Ingat: akun Trial cuma boleh 1 custom domain per service.${C_RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi

                    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
                    echo -e "${C_GREEN}✓ Custom domain berhasil ditambahkan: https://$CD_DOMAIN${C_RESET}"
                    echo -e "Target Port: ${C_YELLOW}${CD_PORT_IN:-Default}${C_RESET}"
                    # Utamakan node dari respons create (ada status DNS-nya); kalau kosong, ambil dari daftar
                    if ! echo "$CREATED_NODE" | jq -e '.status' >/dev/null 2>&1; then
                        fetch_custom_domains
                        FETCHED_NODE=$(echo "$CD_JSON" | jq -c --arg d "$CD_DOMAIN" '(.[] | select(.domain == $d)) // empty')
                        [ -n "$FETCHED_NODE" ] && CREATED_NODE="$FETCHED_NODE"
                    fi
                    print_custom_domain_dns "$CREATED_NODE"
                    echo -e "${C_BLUE}------------------------------------------${C_RESET}"
                    echo -e "Setelah 2 record DNS di atas dipasang, cek lagi lewat menu [2] sampai status DNS ${C_GREEN}VALID${C_RESET} dan SSL ${C_GREEN}ISSUED${C_RESET}."
                    read -p "Tekan Enter untuk lanjut..."
                    ;;

                2)
                    if [ "$CD_COUNT" -eq 0 ]; then
                        echo -e "${C_RED}Belum ada custom domain. Tambah dulu lewat opsi [1]!${C_RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi
                    echo ""
                    for i in $(seq 0 $((CD_COUNT - 1))); do
                        CD_D=$(echo "$CD_JSON" | jq -r ".[$i].domain")
                        echo -e "${C_GREEN}$((i+1)).${C_RESET} ${C_CYAN}$CD_D${C_RESET}"
                    done
                    echo -e "${C_RED}0. Batal${C_RESET}"
                    read -p "Pilih nomor domain [1-$CD_COUNT, 0 batal]: " pick_num
                    if [ "$pick_num" = "0" ] || [ -z "$pick_num" ]; then
                        continue
                    fi
                    if ! echo "$pick_num" | grep -qE '^[0-9]+$' || [ "$pick_num" -lt 1 ] || [ "$pick_num" -gt "$CD_COUNT" ]; then
                        echo -e "${C_RED}Pilihan tidak valid!${C_RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi
                    SEL_ID=$(echo "$CD_JSON" | jq -r ".[$((pick_num - 1))].id")
                    # Ambil status paling segar dari server
                    fetch_custom_domains
                    SEL_NODE=$(echo "$CD_JSON" | jq -c --arg id "$SEL_ID" '(.[] | select(.id == $id)) // empty')
                    if [ -z "$SEL_NODE" ]; then
                        echo -e "${C_RED}Domain tidak ditemukan lagi di server.${C_RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi
                    SEL_DOM=$(echo "$SEL_NODE" | jq -r '.domain')
                    SEL_PORT=$(echo "$SEL_NODE" | jq -r '.targetPort // "Default"')
                    echo -e "\n${C_BOLD}Domain : https://$SEL_DOM${C_RESET} (Port: ${C_YELLOW}$SEL_PORT${C_RESET})"
                    print_custom_domain_dns "$SEL_NODE"
                    read -p "Tekan Enter untuk lanjut..."
                    ;;

                3)
                    if [ "$CD_COUNT" -eq 0 ]; then
                        echo -e "${C_RED}Belum ada custom domain untuk dihapus.${C_RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi
                    echo ""
                    for i in $(seq 0 $((CD_COUNT - 1))); do
                        CD_D=$(echo "$CD_JSON" | jq -r ".[$i].domain")
                        echo -e "${C_GREEN}$((i+1)).${C_RESET} ${C_CYAN}$CD_D${C_RESET}"
                    done
                    echo -e "${C_RED}0. Batal${C_RESET}"
                    read -p "Pilih nomor domain [1-$CD_COUNT, 0 batal]: " pick_num
                    if [ "$pick_num" = "0" ] || [ -z "$pick_num" ]; then
                        continue
                    fi
                    if ! echo "$pick_num" | grep -qE '^[0-9]+$' || [ "$pick_num" -lt 1 ] || [ "$pick_num" -gt "$CD_COUNT" ]; then
                        echo -e "${C_RED}Pilihan tidak valid!${C_RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi
                    DEL_ID=$(echo "$CD_JSON" | jq -r ".[$((pick_num - 1))].id")
                    DEL_DOM=$(echo "$CD_JSON" | jq -r ".[$((pick_num - 1))].domain")
                    read -p "Yakin hapus custom domain $DEL_DOM? [y/N]: " confirm_del
                    if [ "$confirm_del" = "y" ] || [ "$confirm_del" = "Y" ]; then
                        echo -e "${C_CYAN}[*] Menghapus custom domain...${C_RESET}"
                        DEL_PAYLOAD=$(jq -n --arg id "$DEL_ID" \
                          '{
                            query: "mutation ($id: String!) { customDomainDelete(id: $id) }",
                            variables: { id: $id }
                          }')
                        DEL_RES=$(railway_gql "$DEL_PAYLOAD")
                        DEL_OK=$(echo "$DEL_RES" | jq -r '.data.customDomainDelete // false')
                        DEL_ERR=$(echo "$DEL_RES" | jq -r '.errors[0].message // empty')
                        if [ "$DEL_OK" = "true" ]; then
                            echo -e "${C_GREEN}✓ Custom domain $DEL_DOM berhasil dihapus!${C_RESET}"
                            echo -e "${C_YELLOW}Jangan lupa hapus juga record CNAME + TXT-nya di DNS penyedia domain.${C_RESET}"
                        else
                            echo -e "${C_RED}✕ Gagal menghapus: ${DEL_ERR:-Error tidak diketahui}${C_RESET}"
                        fi
                    else
                        echo -e "${C_YELLOW}Operasi dibatalkan.${C_RESET}"
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
    echo -e "${C_GREEN}12.${C_RESET} GitFull - Sinkron dari GitHub (Pull Aman)"
    echo -e "${C_GREEN}13.${C_RESET} Custom Domain (Tambah / DNS / Hapus Domain Sendiri)"
    echo -e "${C_RED} 0.${C_RESET} Keluar"
    echo -e "${C_BLUE}==========================================${C_RESET}"
    read -p "Pilih menu [0-13]: " main_choice

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
        12) menu_gitfull ;;
        13) menu_custom_domain ;;
        0) exit 0 ;;
        *) echo -e "${C_RED}Pilihan tidak valid!${C_RESET}"; sleep 1 ;;
    esac
done
