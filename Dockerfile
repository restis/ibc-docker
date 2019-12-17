FROM openjdk:13-buster

LABEL author="antmanler(AT)gmail.com"

# install easy-novnc
COPY --from=restis/easy-novnc:latest /easy-novnc /usr/bin/

# config vnc, ref  https://github.com/accetto/ubuntu-vnc-xfce/tree/cb02506d13da39bd3ff17b72bec00fb57da6acd5
RUN apt-get update && apt-get install -y \
    mousepad \
    supervisor \
    xfce4 \
    xfce4-terminal \
    gettext \
    libnss-wrapper \
    && apt-get purge -y \
    pm-utils \
    xscreensaver* \
    && rm -rf /var/lib/apt/lists/*

# installed into '/usr/share/usr/local/share/vnc'
RUN apt-get update && apt-get install -y \
    wget \
    && wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.9.0.x86_64.tar.gz | tar xz --strip 1 -C / \
    && rm -rf /var/lib/apt/lists/*

# Arguments can be provided during build
ARG ARG_HOME
ARG ARG_VNC_BLACKLIST_THRESHOLD
ARG ARG_VNC_BLACKLIST_TIMEOUT
ARG ARG_VNC_PW
ARG ARG_VNC_RESOLUTION

ENV \
    DISPLAY=:1 \
    HOME=${ARG_HOME:-/root} \
    NO_VNC_PORT="8087" \
    VNC_BLACKLIST_THRESHOLD=${ARG_VNC_BLACKLIST_THRESHOLD:-20} \
    VNC_BLACKLIST_TIMEOUT=${ARG_VNC_BLACKLIST_TIMEOUT:-0} \
    VNC_COL_DEPTH=24 \
    VNC_PORT="5901" \
    VNC_PW=${ARG_VNC_PW:-headless} \
    VNC_RESOLUTION=${ARG_VNC_RESOLUTION:-1440x900} \
    VNC_VIEW_ONLY=false

### Creates home folder
WORKDIR ${HOME}

# Install IB
# download installation script
RUN cd ${HOME} \
    && wget https://download2.interactivebrokers.com/installers/ibgateway/latest-standalone/ibgateway-latest-standalone-linux-x64.sh \
    && chmod a+x ibgateway-latest-standalone-linux-x64.sh \
    && echo 'n\r' | ./ibgateway-latest-standalone-linux-x64.sh -c \
    && rm ibgateway-latest-standalone-linux-x64.sh

# Install IBC
RUN cd /tmp \
    && wget https://github.com/IbcAlpha/IBC/releases/download/3.8.1/IBCLinux-3.8.1.zip \
    && unzip IBCLinux-3.8.1.zip -d /opt/ibc \
    && cd /opt/ibc; chmod o+x *.sh */*.sh

COPY ./vnc/startup /dockerstartup/
### Preconfigure Xfce
COPY ./vnc/home/config/xfce4/panel ./.config/xfce4/panel/
COPY ./vnc/home/config/xfce4/xfconf/xfce-perchannel-xml ./.config/xfce4/xfconf/xfce-perchannel-xml/

### 'generate_container_user' has to be sourced to hold all env vars correctly
RUN echo 'source /dockerstartup/generate_container_user' >> ${HOME}/.bashrc

RUN chmod +x /dockerstartup/set_user_permissions.sh \
    && /dockerstartup/set_user_permissions.sh /dockerstartup $HOME \
    && gtk-update-icon-cache -f /usr/share/icons/hicolor

EXPOSE ${VNC_PORT} ${NO_VNC_PORT}

ENV REFRESHED_AT 2019-06-20

### Issue #7: Mitigating problems with foreground mode
# ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
# CMD [ "--wait" ]

COPY entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]
