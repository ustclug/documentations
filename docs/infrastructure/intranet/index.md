# Servers Intranet

Servers Intranet connects all the servers together, including physical servers and virtual machines.

## Network Topology

<iframe frameborder="0" style="width:100%;height:500px;" src="https://viewer.diagrams.net/?lightbox=1&highlight=0000ff&edit=_blank&layers=1&nav=1&title=LUG%20Network#Uhttps%3A%2F%2Fdocs.ustclug.org%2Finfrastructure%2Fintranet%2Fimg%2Fnetwork.html"></iframe>

以上架构图由 iBug 在 2023 年 11 月更新。

??? warning "以下是一些过时的信息，也许还有点参考价值"

    The network contains three parts:

    - Physical Switch in East Library Data Center
    - Virtual Switch on vSphere host machine
    - tincVPN

    tincVPN is a mesh VPN, which can be abstracted as a virtual Switch.

    vm-nfs.s.ustclug.org runs a layer 2 bridge, connecting tincVPN and SRW2024 (physical switch).

    It is obvious that vm-nfs is a single point of failure of communicating between tinc host and vSphere virtual machine. I had tried to add another bridge node, but resulted in a broadcast storm. Maybe we can fix it by MPLS (merged in mainline kernel 4.3). But it isn't a right timing at this time.

## Network information

The network contains one single subnet: 10.254.0.0/21

Every server and service binds to one and only one IP address, used to communicate with each other.

### Address planning

- 10.254.0.0/24: Physical servers and virtual machines
- 10.254.1.0/24: Docker containers
- 10.254.6.0/24: LUGi emergency entrypoint (via vpnstv.s, managed by yzf)
- 10.254.7.0/24: LUGi entrypoint (via board.s)
- Others: not used yet.
