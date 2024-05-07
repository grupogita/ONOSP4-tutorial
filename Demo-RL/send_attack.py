# This file is part of the Planter extend project: QCMP.
# This program is a free software tool, which does ensemble in-network reinforcement learning for load balancing.
# licensed under Apache-2.0
#
# Utility: This file is used to send traffic
#
# Copyright (c) 2022-2023 Benjamin Rienecker Modified by Changgang Zheng
# Copyright (c) Computing Infrastructure Group, Department of Engineering Science, University of Oxford

#!/usr/bin/env python3
import random
import socket
import sys
from multiprocessing import Process

from scapy.all import *
from scapy.layers.inet import _IPOption_HDR

def send_packets(packets):
    #sendpfast(packets, pps=450, loop=40, iface='eth0')
    sendpfast(packets, pps=150, loop=30, iface='eth0')

def main():

    iface = 'eth0'

    print("sending on interface %s" % (iface))

    #pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff') / IP(dst='10.0.6.11', options = IPOption_MRI(count=0, swtraces=[]))
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff') / IP(dst='10.0.6.11')
    pkts = [pkt / TCP(dport=1234, sport=random.randint(49152,65535)) for i in range(5000)]

    p = Process(target=send_packets, args=(pkts,))
    print('Packets made')
    p.start()
    # Wait for the process to finish
    p.join()

    # pkt.show2()
    # sendp(pkt, iface=iface, verbose=False)


if __name__ == '__main__':
    main()
