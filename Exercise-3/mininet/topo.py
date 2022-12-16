#!/usr/bin/python

import argparse

from mininet.cli import CLI
from mininet.log import setLogLevel
from mininet.net import Mininet
from mininet.node import Host
from mininet.topo import Topo

from mininet.node import RemoteController
from mininet.link import TCLink
from mininet.node import CPULimitedHost

import sys

sys.path.insert(0, '/home/p4/ngsdn-tutorial/mininet')
from stratum_new import StratumBmv2Switch

CPU_PORT = 255


class TutorialTopo(Topo):

    def __init__(self, *args, **kwargs):
        Topo.__init__(self, *args, **kwargs)
        # gRPC port 50001
        s1 = self.addSwitch('s1', cls=StratumBmv2Switch, cpuport=CPU_PORT)

        # gRPC port 50002
        s2 = self.addSwitch('s2', cls=StratumBmv2Switch, cpuport=CPU_PORT)
        """
        Exercise 3 TO-DO:
        Add two hosts and create links between the H1-S1, S1-S2 and SW2-H2. 
        
        h1 should have the mac address 00:00:00:00:00:01 and IP 10.0.0.1/24. 
        
        For h2 use 00:00:00:00:00:02 and 10.0.0.2/24 for the mac address and ip 
        addres respectively.

        Remember that the parameters of the links are decided by you in such a 
        way as to allow you to demonstrate their effect on the time metrics 
        calculated at the end of the exercise.
        """






def main():
	net = Mininet(topo=TutorialTopo(), controller=None, link=TCLink)#, switch=OVSKernelSwitch)
	net.staticArp() #Avoiding ARP process
	net.start()
	CLI(net)
	net.stop()
	print '#' * 80
	print 'ATTENTION: Mininet was stopped! Perhaps accidentally?'
	print 'No worries, it will restart automatically in a few seconds...'
	print 'To access again the Mininet CLI, use `make mn-cli`'
	print 'To detach from the CLI (without stopping), press Ctrl-D'
	print 'To permanently quit Mininet, use `make stop`'
	print '#' * 80


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Mininet topology script for 2x2 fabric with stratum_bmv2 and IPv4 hosts')
    args = parser.parse_args()
    setLogLevel('info')

    main()
