from scapy.all import *
import sys, os

TYPE_MYSEC = 0x6174

class MySec(Packet):
	name = "MySec"
	fields_desc = [
		BitField("inpo",0,4),   #Ingress Port
		BitField("egpo",0,4),   #Egress Port
		BitField("dsw1",0,48),  #Delta Switch1 (Egress_1 - Ingress_1)
		BitField("dsw2",0,48),  #Delta Switch2 (Egress_2 - Ingress_2)
		BitField("esw1",0,48),  #Time Egress Switch1 (Egress_1)
		BitField("ibsw1",0,48), #Time Ingress Back Switch1 (Ingress_1B)
		BitField("th",0,48)     #Thershold
	]


def main():
	pkt = Ether(src="00:00:00:00:00:01", dst="00:00:00:00:00:02", type=24954) / IP(dst="10.0.0.2", src="10.0.0.1", proto=169) / MySec(inpo=0)

	pkt.show()

	sendp(pkt, iface="s1-eth2")

if __name__ == '__main__':
	main()
