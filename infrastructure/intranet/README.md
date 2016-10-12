# Servers Intranet

Servers Intranet connect all the servers together, including physics servers and virtual machines.

## Network Topology

![topology](img/topology.png)

The network contains three parts:

- Physical Switch in East Library Data Center
- Virtual Switch on vSphere host machine
- tincVPN

tincVPN is a mesh VPN, which can be abstructed as a virtual Switch.

vm-nfs.s.ustclug.org runs a layer 2 bridge, connecting tincVPN and SRW2024(physical switch).

It is obvious that vm-nfs is a single point of failure of communicating between tinc host and vSphere virtual machine. I had tried to add another bridge node, but resulted in a broadcast storm. Maybe we can fix it by MPLS (merged in mainland kernel 4.3). But it isn't a right timing at this time.

## Network information

The network contains two subnets:

* 10.254.0.0/24
* 10.254.10.0/24

Every server binds one and only one IP address in 10.254.0.0/24, used to communicate with each other.

10.254.10.0/24 is used for 1to1 IP mapping. At this time, it just used between linode(10.254.10.2) and blog(10.254.10.1).

