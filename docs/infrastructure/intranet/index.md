# Servers Intranet

Servers Intranet connect all the servers together, including physics servers and virtual machines.

## Network Topology

<iframe frameborder="0" style="width:100%;height:500px;" src="https://viewer.diagrams.net/?lightbox=1&highlight=0000ff&edit=_blank&layers=1&nav=1&title=LUG%20Network#Uhttps%3A%2F%2Fdocs.ustclug.org%2Finfrastructure%2Fintranet%2Fimg%2Fnetwork.html"></iframe>

以上架构图由 iBug 在 2023 年 11 月更新。以下信息是过时的，不过有参考价值。

The network contains three parts:

- Physical Switch in East Library Data Center
- Virtual Switch on vSphere host machine
- tincVPN

tincVPN is a mesh VPN, which can be abstracted as a virtual Switch.

vm-nfs.s.ustclug.org runs a layer 2 bridge, connecting tincVPN and SRW2024(physical switch).

It is obvious that vm-nfs is a single point of failure of communicating between tinc host and vSphere virtual machine. I had tried to add another bridge node, but resulted in a broadcast storm. Maybe we can fix it by MPLS (merged in mainland kernel 4.3). But it isn't a right timing at this time.

## Network information

The network contains two subnets:

* 10.254.0.0/21
* 10.254.10.0/24

Every server binds one and only one IP address in 10.254.0.0/21, used to communicate with each other.

10.254.10.0/24 is used for 1to1 IP mapping. At this time, it just used between linode(10.254.10.2) and blog(10.254.10.1).

### Address planning

* 10.254.0.0/24: physical server and virtual machine
* 10.254.1.0/24: docker container
* 10.254.6.0/24: LUGi emergency entrypoint (managed by yzf)
* 10.254.7.0/24: LUGi entrypoint (via board.s)
* other address: not used yet.
