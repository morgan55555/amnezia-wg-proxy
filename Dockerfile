ARG AMNEZIAWG_GO_VERSION=0.2.17

FROM amneziavpn/amneziawg-go:${AMNEZIAWG_GO_VERSION}

# Why it's not by default in amneziawg-go?
RUN apk --no-cache add openresolv
RUN mkdir -p /etc/amnezia/amneziawg

# Fix for net.ipv4.conf.all.src_valid_mark error. There must be set net.ipv4.conf.all.src_valid_mark=1 in docker.
RUN sed -i 's|\[\[ $proto == -4 \]\] && cmd sysctl -q net\.ipv4\.conf\.all\.src_valid_mark=1|[[ $proto == -4 ]] \&\& [[ $(sysctl -n net.ipv4.conf.all.src_valid_mark) != 1 ]] \&\& cmd sysctl -q net.ipv4.conf.all.src_valid_mark=1|' /usr/bin/awg-quick

# Copy launch script
COPY init.sh /init.sh
RUN chmod +x /init.sh

# Healthcheck
HEALTHCHECK --interval=1m --timeout=5s --retries=3 \
    CMD /usr/bin/timeout 5s /bin/sh -c "awg show | grep interface || exit 1"

# Launch!
ENTRYPOINT ["/bin/sh", "/init.sh"]