# amnezia-wg-proxy
Dockerized wireguard proxy for amneziawg, for that projects and devices that do not support amnezia.

### Setup

1. Install Docker if you haven't yet:
   ```bash
   curl -sSL https://get.docker.com | sh
   sudo usermod -aG docker $USER
   ```
2. Get both of AmneziaWG and Wireguard configs

   Generate a `amnezia.conf` and `wireguard.conf` files and place it in a new directory somewhere on the host.

3. Run the container

   To run it on a separate Docker network:

   ```bash
   docker run -it \
    --name=amnezia-wg-proxy \
    -v /path/to/dir/with/configs:/config \
    --device=/dev/net/tun:/dev/net/tun \
    --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
    --sysctl="net.ipv4.ip_forward=1" \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --restart always \
    ghcr.io/morgan55555/amnezia-wg-proxy
   ```

4. Connect to your wireguard proxy server (`wireguard.conf`) and verify that it's works as intended.