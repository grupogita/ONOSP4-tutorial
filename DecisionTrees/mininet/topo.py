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

sys.path.insert(0, '/home/p4/ONOSP4-tutorial/mininet')
#from stratum_new import StratumBmv2Switch
from stratum2 import StratumBmv2Switch
from stratum2 import NoOffloadHost

CPU_PORT = 255


class TutorialTopo(Topo):
    """2x2 fabric topology with IPv4 hosts"""

    def __init__(self, *args, **kwargs):
        Topo.__init__(self, *args, **kwargs)

        # Leaves


        # gRPC port 50001
        s1 = self.addSwitch(name='s1', cls=StratumBmv2Switch, cpuport=CPU_PORT,
                onosdevid="1", json="/home/p4/demo1/p4src/sw_gita.json", loglevel="trace")

        self.addHost('h1', ip='10.0.1.1/24', mac='00:00:00:00:01:01')
        self.addHost('h2', ip='10.0.1.2/24', mac='00:00:00:00:01:02')
        self.addHost('h3', ip='10.0.1.3/24', mac='00:00:00:00:01:03')
        self.addHost('h4', ip='10.0.1.4/24', mac='00:00:00:00:01:03')

        self.addLink('h1', 's1')
        self.addLink('h2', 's1')
        self.addLink('h3', 's1')
        self.addLink('h4', 's1')

        """
        TO-DO
        Add two hosts and create links between the SW and them. h1 should have
        the mac address 00:00:00:00:00:01 and IP 10.0.0.1/24. For h2 use
        00:00:00:00:00:02 and 10.0.0.2/24 for the mac address and ip addres respectively.
        Besides, the first link (h1-s1) should have the following specifications:
                        Bandwidth of 2 Mbps, delay of 10000us and loss of 5%.
        The second link (h2-s2) should have the following specifications:
                        Bandwidth of 5 Mbps, delay of 1ms and loss of 2%.


                        HINT: search on google -> self.addlink use_htb=True
        """


def main():
	net = Mininet(topo=TutorialTopo(), controller=None, link=TCLink)
	net.staticArp() #Avoid ARP process
	net.start()
	CLI(net)
	net.stop()
	print('#' * 80)
	print('ATTENTION: Mininet was stopped! Perhaps accidentally?')
	print('No worries, it will restart automatically in a few seconds...')
	print('To access again the Mininet CLI, use `make mn-cli`')
	print('To detach from the CLI (without stopping), press Ctrl-D')
	print('To permanently quit Mininet, use `make stop`')
	print('#' * 80)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Mininet topology script for 2x2 fabric with stratum_bmv2 and IPv4 hosts')
    args = parser.parse_args()
    setLogLevel('info')

    main()
