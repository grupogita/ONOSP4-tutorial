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

sys.path.insert(0, '~/ngsdn-tutorial/mininet')
from stratum_new import StratumBmv2Switch

CPU_PORT = 255

class VlanTopo(Topo):
    def __init__(self, *args, **kwargs):
        Topo.__init__(self, *args, **kwargs)

		#Switches
        s1 = self.addSwitch('s1', cls=StratumBmv2Switch, cpuport=CPU_PORT)
        s2 = self.addSwitch('s2', cls=StratumBmv2Switch, cpuport=CPU_PORT)

        """
        Exercise 4 TO-DO:
        Add four hosts and create links between the H1-SW1, H2-SW1, H3-SW2, 
        H4-SW2, and SW1-SW2.

        For the assignment of mac addresses, please support yourself on the  
        image shown in the approach of the exercise.

        All links must have the same parameters, which must be as follows:
            Bandwidth of 5 Mbps, delay of 5ms and loss of 1%.

            REMEMBER: search on google -> self.addlink use_htb=True
        """


def main():
    net = Mininet(topo=VlanTopo(), controller=None, link=TCLink)
    net.staticArp() #Avoid ARP process
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
