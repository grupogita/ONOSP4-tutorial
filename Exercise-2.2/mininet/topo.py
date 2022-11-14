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


        # Exercise 2.2 TO-DO:
        # Set the name of the switch, the path to the JSON file (the output of
        # the p4c compiler), and set the loglevel to trace to make easier to debug
        # possible issues with the switch.
        
        s1 = self.addSwitch(name='<FIX ME>', cls=StratumBmv2Switch, cpuport=CPU_PORT, 
                onosdevid="1", json="<FIX ME>", loglevel="<FIX ME>")
        
        """
        Exercise 2.2 TO-DO
        Add two hosts and create links between the SW and them. h1 should have
        the mac address 00:00:00:00:00:01 and IP 10.0.0.1/24. For h2 use
        00:00:00:00:00:02 and 10.0.0.2/24 for the mac address and ip addres respectively.        
        """        

def main():
        net = Mininet(topo=TutorialTopo(), controller=None, link=TCLink)
        #net.staticArp() #Avoid ARP process

        for h in net.hosts:
            print "disable ipv6"
            h.cmd("sysctl -w net.ipv6.conf.all.disable_ipv6=1")
            h.cmd("sysctl -w net.ipv6.conf.default.disable_ipv6=1")
            h.cmd("sysctl -w net.ipv6.conf.lo.disable_ipv6=1")

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
