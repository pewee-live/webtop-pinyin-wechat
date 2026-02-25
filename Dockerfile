FROM lscr.io/linuxserver/webtop:ubuntu-mate

# 保持默认用户机制 (PUID/PGID)，不要手动 USER 切换
USER root

RUN apt update && \
    apt install -y \
    wget \
    curl \
    locales \
    im-config \
    fcitx5 \
    fcitx5-pinyin \
    fcitx5-chinese-addons \
    fcitx5-config-qt \
    fcitx5-configtool \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    fonts-noto-cjk \
    && locale-gen zh_CN.UTF-8 en_US.UTF-8 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /usr/share/dbus-1/system-services/org.freedesktop.PackageKit.service

ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XMODIFIERS="@im=fcitx"

# 解决应用长时间运行后 dbus 导致的内存和性能卡顿问题
ENV NO_AT_BRIDGE=1

# 在容器启动后由 s6 以 abc 用户执行，不需要再 USER abc
RUN mkdir -p /defaults/root/.config/fcitx5 && \
    echo "[Groups/0]" > /defaults/root/.config/fcitx5/profile && \
    echo "Name=Default" >> /defaults/root/.config/fcitx5/profile && \
    echo "Default Layout=us" >> /defaults/root/.config/fcitx5/profile && \
    echo "DefaultIM=fcitx-keyboard-us" >> /defaults/root/.config/fcitx5/profile && \
    echo "" >> /defaults/root/.config/fcitx5/profile && \
    echo "[Groups/0/Items/0]" >> /defaults/root/.config/fcitx5/profile && \
    echo "Name=fcitx-keyboard-us" >> /defaults/root/.config/fcitx5/profile && \
    echo "Layout=" >> /defaults/root/.config/fcitx5/profile && \
    echo "" >> /defaults/root/.config/fcitx5/profile && \
    echo "[Groups/0/Items/1]" >> /defaults/root/.config/fcitx5/profile && \
    echo "Name=pinyin" >> /defaults/root/.config/fcitx5/profile && \
    echo "Layout=" >> /defaults/root/.config/fcitx5/profile && \
    echo "" >> /defaults/root/.config/fcitx5/profile && \
    echo "[GroupOrder]" >> /defaults/root/.config/fcitx5/profile && \
    echo "0=Default" >> /defaults/root/.config/fcitx5/profile


# 复 installWc.sh 到镜像
COPY installWc.sh /tmp/installWc.sh

# 安装依赖 & 微信
RUN chmod +x /tmp/installWc.sh && \
    bash /tmp/installWc.sh && \
    rm -f /tmp/installWc.sh

# 根据架构从 GitHub Release 下载 WeChat
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
    amd64)  URL="https://github.com/pewee-live/webtop-pinyin/releases/download/20250819/WeChatLinux_x86_64.deb" ;; \
    arm64)  URL="https://github.com/pewee-live/webtop-pinyin/releases/download/20250819/WeChatLinux_arm64.deb" ;; \
    *)      echo "❌ Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    wget -O /tmp/wechat.deb "$URL" && \
    apt install -y /tmp/wechat.deb && \
    rm -f /tmp/wechat.deb