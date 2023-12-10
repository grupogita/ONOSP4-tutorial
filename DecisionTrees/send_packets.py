from scapy.all import *
import random

for x in range(100):

    srchost=random.randint(1,254)
    dsthost=random.randint(1,254)
    ip = IP(src="10.0.1."+str(srchost), dst="10.0.1."+str(dsthost))
    srcport=random.randint(0, 65535)
    dstport=random.randint(0, 65535)
    tcp = TCP(sport=srcport, dport=dstport, flags="S", seq=13579, ack=24680)
    pkt = ip/tcp
    #ls(pkt)
    send(pkt,verbose=1)

    srcport=random.randint(0, 10)
    dstport=random.randint(0, 65535)
    tcp = TCP(sport=srcport, dport=dstport, flags="S", seq=13579, ack=24680)
    pkt = ip/tcp
    #ls(pkt)
    send(pkt,verbose=1)
