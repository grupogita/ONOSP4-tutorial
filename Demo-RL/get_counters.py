# This file is part of the Planter extend project: QCMP.
# This program is a free software tool, which does ensemble in-network reinforcement learning for load balancing.
# licensed under Apache-2.0
#
# Utility: This file is used to send telemetry traffic
#
# Copyright (c) 2022-2023 Benjamin Rienecker Modified by Changgang Zheng
# Copyright (c) Computing Infrastructure Group, Department of Engineering Science, University of Oxford
#
# This script has been adapted for the tutorial presented in NOMS 2024 on Reinforcement Learning with P4
# by Sergio Gutierrez <sergio.gutierrezb@udea.edu.co>

#!/usr/bin/env python3
import random
import socket
import sys
from time import sleep

from scapy.all import *
from scapy.layers.inet import _IPOption_HDR

# This class represents the content of the IP option used to store the counters used for the SynFlood
# detection
class SwitchTrace(Packet):
    fields_desc = [ IntField("swid", 0),
                  IntField("synCnt", 0),IntField("synAckCnt",0)]
    def extract_padding(self, p):
                return "", p

# We reuse the MRI IP option to store the information of the counters of SYN and SYN+ACK packets used
# for our detection scheme.
class IPOption_MRI(IPOption):
    name = "MRI"
    option = 31
    fields_desc = [ _IPOption_HDR,
                    FieldLenField("length", None, fmt="B",
                                  length_of="swtraces",
                                  adjust=lambda pkt,l:l*3+4),
                    ShortField("count", 0),
                    PacketListField("swtraces",
                                   [],
                                   SwitchTrace,
                                   count_from=lambda pkt:(pkt.count*1)) ]

def main():

    iface = 'eth0'

    print("sending on interface %s" % (iface))

    while True:
	# We build telemetry packets that will contain the counter values of
	# each switch. The IP 10.0.1.254 will be statically routed towards 
	# the eth3 of S1, where we will have a script implementing a pseudo
	# control plane that will receive these telemetry packets and will
	# execute the RL algorithm.
        pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff');
        pkt = pkt /IP(dst='10.0.1.254', options = IPOption_MRI(count=0,
                swtraces=[]))
        #pkt = pkt /IP(dst='10.0.1.254');
        pkt.show2()
        sendp(pkt, iface=iface, verbose=False)
        #sleep(0.5)
        sleep(2.5)
        #sleep(1)


if __name__ == '__main__':
    main()
