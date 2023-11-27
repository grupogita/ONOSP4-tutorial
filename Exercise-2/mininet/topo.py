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

sys.path.insert(0, '~/ONOS-P4TUTORIAL/Exercise-2/mininet')
from stratum_new import StratumBmv2Switch

CPU_PORT = 255


class TutorialTopo(Topo):
    def __init__(self, *args, **kwargs):
        Topo.__init__(self, *args, **kwargs)

        #Switch
	""" Exercise 1 TO-DO
 	Set the path to the json file which is output of the P4 compilation step
  	"""
        s1 = self.addSwitch('s1', cls=StratumBmv2Switch, cpuport=CPU_PORT, onosdevid="1", json="<TODO>")


        """
        Exercise 1 TO-DO:
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
