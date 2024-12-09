#!/bin/sh

# 配置部分
URL="https://pan.v1.mk/api/fs/list"
DATA='{"path": "/每期视频中用到的文件分享/allinone二进制文件/"}'
TMP_DIR="/tmp/allinone-update"
LOG_FILE="/var/log/allinone_update.log"
SERVICE_NAME="allinone"
TARGET_DIR="/allinone"
TARGET_FILE="$TARGET_DIR/allinone_linux_arm64"
LAST_VERSION_FILE="/tmp/last_version.txt"  # 记录上次下载版本号的文件

# 创建日志文件（如不存在）
touch "$LOG_FILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

clean_up() {
    log "清理临时文件..."
    rm -rf "$TMP_DIR"
}
trap clean_up EXIT

log "开始请求文件列表..."
response=$(curl -s -X POST -H "Content-Type: application/json" -d "$DATA" "$URL")

if [ $? -ne 0 ]; then
    log "请求失败，请检查网络连接或URL配置！"
    exit 1
fi

if echo "$response" | grep -q '"code":200'; then
    log "请求成功，解析文件信息..."
    # 提取文件名并根据文件名提取日期和时间戳
    file_info=$(echo "$response" | jq -r '.data.content[] | select(.name | contains("allinone_linux_arm64") and endswith(".zip")) | .name')

    if [ -n "$file_info" ]; then
        log "找到符合条件的文件: $file_info"

        # 提取版本号（日期+时间戳）
        new_version=$(echo "$file_info" | grep -oE '[0-9]{14}')

        log "提取的版本号/日期时间戳: $new_version"

        # 检查是否为新版本
        if [ -f "$LAST_VERSION_FILE" ]; then
            last_version=$(cat "$LAST_VERSION_FILE")
            if [ "$new_version" == "$last_version" ]; then
                log "版本号未更新（$new_version），跳过更新操作。"
                exit 0
            else
                log "检测到新版本（$new_version），开始更新..."
            fi
        else
            log "首次更新，开始更新..."
        fi

        # URL编码文件名
        encoded_file=$(echo "$file_info" | jq -R -r @uri)
        download_url="https://pan.v1.mk/p/每期视频中用到的文件分享/allinone二进制文件/$encoded_file"

        log "下载文件: $download_url"
        mkdir -p "$TMP_DIR"

        if curl -o "$TMP_DIR/$file_info" "$download_url"; then
            log "文件下载完成，准备停止服务..."

            if /etc/init.d/$SERVICE_NAME stop; then
                log "服务已停止，开始解压..."

                if unzip -o "$TMP_DIR/$file_info" -d "$TARGET_DIR"; then
                    log "解压完成，设置文件权限..."
                    chmod 755 "$TARGET_FILE"

                    log "重启服务..."
                    if /etc/init.d/$SERVICE_NAME start; then
                        log "服务已成功重启！"
                        echo "$new_version" > "$LAST_VERSION_FILE"  # 更新版本号
                    else
                        log "服务启动失败！"
                        exit 1
                    fi
                else
                    log "解压失败，请检查文件格式！"
                    exit 1
                fi
            else
                log "服务停止失败，请检查服务状态！"
                exit 1
            fi
        else
            log "文件下载失败，请检查下载链接！"
            exit 1
        fi
    else
        log "未找到符合条件的文件，请检查文件命名规则！"
        exit 1
    fi
else
    log "请求失败，响应内容: $response"
    exit 1
fi
