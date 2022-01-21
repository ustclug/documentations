# Neat DNS

Services: neatdns.ustclug.org (UDP, TCP, HTTPS, DNSCrypt)

Server: [docker2](docker2.md)

Deploy: [:fontawesome-solid-lock: docker-run-script/neatdns](https://github.com/ustclug/docker-run-script/tree/master/neatdns)

## Notes

Previously all containers on docker2 had gateway-el as their gateway, which generated heavy load on the [Tinc](../infrastructure/tinc.md) network. Docker2 has since been updated to use gateway-nic as gateway for containers, bypassing Tinc for most of the traffic. This, however, broke NAT-based service like Neat DNS, which required that reply traffic goes back through gateway-el (but now gateway-nic).

What's worse, Docker doesn't support setting gateways for individual containers, *nor* can network config be changed from within the container (default setup). So we chose to *selectively* route traffic back to gateway-el on gateway-nic. This is accomplished with two parts:

- Routing tables and routing rules:

    ```ini title="/etc/systemd/network/11-Policy.network"
    [RoutingPolicyRule]
    From=0.0.0.0/0
    FirewallMark=0x101/0x1ff
    Table=1101  # Ustclug_override
    Priority=1

    [Route]
    Gateway=10.254.0.254  # gateway-el
    Table=1011
    ```

    Using iproute2 `ip` command, this would be:

    ```sh
    ip rule add fwmark 0x101/0x1ff table Ustclug_override prio 1
    ip route replace default via 10.254.0.254 table Ustclug_override
    ```

- And then we select traffic to redirect to gateway-el using iptables marks:

    ```sh title="iptables -t mangle -S"
    -A PREROUTING -s 10.254.1.5/32 -i Policy -p tcp -m multiport --sports 53,53443 -j MARK --set-xmark 0x101/0x1ff
    -A PREROUTING -s 10.254.1.5/32 -i Policy -p udp -m multiport --sports 53,53443 -j MARK --set-xmark 0x101/0x1ff
    ```

    These two lines of iptables rules selects replying traffic originating from the neat-dns container and marks it appropriately, so it will be routed to gateway-el instead of exiting the intranet right from gateway-nic.
