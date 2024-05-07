# This file is part of the Planter extend project: QCMP.
# This program is a free software tool, which does ensemble in-network reinforcement learning for load balancing.
# licensed under Apache-2.0
#
# Utility: This file is used to receive telemetry traffic and update q-table
#
# Copyright (c) 2022-2023 Benjamin Rienecker Modified by Changgang Zheng
# Copyright (c) Computing Infrastructure Group, Department of Engineering Science, University of Oxford

#!/usr/bin/env python3
import os
import sys
import grpc
import math
import numpy as np

from scapy.all import *
from scapy.layers.inet import _IPOption_HDR

sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
                 '../utils/'))
import p4runtime_lib.bmv2
import p4runtime_lib.helper

from q_table import (counter_stats,
                     q_table)

old_counters = [counter_stats([1, 1]), counter_stats([1, 1]), counter_stats([1, 1])]
global_state=[0,0]
trained=0

class SwitchTrace(Packet):
    fields_desc = [ IntField("swid", 0),
                  IntField("synCnt", 0),IntField("synAckCnt", 0)]
    def extract_padding(self, p):
                return "", p

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

def runthat2(switch_q_table, switch, mri, counter, index1, index2, index3, reset_params):
# index1 : index for where switch queue data is stored in path_dicts (list of dicts)
# index2 : which switch trace contains the queue length
# index3 : swid for path defining switch

	switch_q_table.update_parameters()
	synCnt = mri.swtraces[index2].synCnt
	synAckCnt = mri.swtraces[index2].synAckCnt


	global old_counters
	global global_state
	global trained



	if global_state[index1] < 12:
		currentstate = global_state[index1]
	else:
		global_state[index1]=0
		currentstate = global_state[index1]
		trained=1
		print("TRAINED COMPLETE")
		
		

	new_counters = counter_stats([synCnt, synAckCnt])
	new_counters.check_alarm()

	if new_counters.alarm == 1:
		action=new_counters.get_next_action(switch_q_table, currentstate, switch_q_table.parameters['epsilon'])
		print("We are under attack")
		newstate=currentstate+1

	
		reward=new_counters.get_reward(old_counters[index1], switch_q_table)


		if trained == 0:	
			switch_q_table.update_q_table(newstate,currentstate,action,reward,switch_q_table.parameters['learning_rate'], switch_q_table.parameters['discount'])

		print('s{0}'.format(index1+1), new_counters.counters, new_counters.action, new_counters.reward)


		p4info_file_path = os.path.join(os.getcwd(), 'build/syn_flood_filter.p4.p4info.txt')
		p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

		switch.MasterArbitrationUpdate()

		block = new_counters.get_block()

		print("Attempting blocking of ", block)
		new_counters.write_block(p4info_helper, switch, block)
		global_state[index1] = newstate
		switch.shutdown()
		switch_q_table.reset_parameters(new_counters, reset_params[index1])
		old_counters[index1] = new_counters
		for i in range(len(counter[index1])):
			counter[index1][i] = 0

	else:
		print("Attack seems mitigated")


# The format of this function is inherited from the Original QCMP code which operated
# on three switches. That is why the function receives three instances of the Q-Table
# to work on three different switches. However, this current implementation operates 
# only on S1 switch, despite it receives three tables
# TODO: Implementing the operation on three switches
def handle_pkt2(pkt, s1_q_table, s2_q_table, s3_q_table, counter, reset_params):

	#pkt.show2()
	if pkt[IP]:

		mri=pkt[IP][IPOption_MRI]
		count_len = len(mri.swtraces)
		print(count_len)

		s1 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
			name='s1',
			address='127.0.0.1:50051',
			device_id=0)

		runthat2(s1_q_table, s1, mri, counter, 0, 0, 0, reset_params)

		s2 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
			name='s2',
			address='127.0.0.1:50052',
			device_id=1)


		# TODO: We could implement the blocking in more than one switch. We
		# currently do the work only on S1.

		#runthat2(s2_q_table, s2, mri, counter, 1, 1, 1, reset_params)

	else:
		print("cannot find IP header in the packet")

	sys.stdout.flush()

# The format of this function is inherited from the Original QCMP code which operated
# on three switches. That is why the function creates three instances of the Q-Table
# to work on three different switches. However, this current implementation operates 
# only on S1 switch, despite it will pass three tables
# TODO: Implementing the operation on three switches
def main():
	s1_q_table = q_table()
	s2_q_table = q_table()
	s3_q_table = q_table()
	s1_path_dict = {}
	s2_path_dict = {}
	s3_path_dict = {}
	path_dicts = [s1_path_dict, s2_path_dict, s3_path_dict]
	counter = [[1, 1], [1, 1], [1, 1]]
	reset_params = [[],[],[]]
	state=0
	iface = 's1-eth3'
	print("sniffing on %s" % iface)
	sys.stdout.flush()
	sniff(filter="ip", iface = iface,
	prn = lambda x: handle_pkt2(x, s1_q_table, s2_q_table, s3_q_table, counter, reset_params))

if __name__ == '__main__':
	main()
