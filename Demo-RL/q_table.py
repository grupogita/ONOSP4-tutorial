# This file is part of the Planter extend project: QCMP.
# This program is a free software tool, which does ensemble in-network reinforcement learning for load balancing.
# licensed under Apache-2.0
#
# Utility: This file is used to adjust q-table
#
# Copyright (c) 2022-2023 Benjamin Rienecker Modified by Changgang Zheng
# Copyright (c) Computing Infrastructure Group, Department of Engineering Science, University of Oxford

#!/usr/bin/env python3
import numpy as np
import math
import subprocess as subp
import sys
from time import sleep
import os

class q_table():
    def __init__(self) -> None:
        self.q_table = self.init_q_table()
        self.parameters = {
            "learning_rate": 0.2, 
            "discount": 0.1,
            "epsilon": 0.4,
            "action_weight": 5,
            "pkt_counter": 0,
        }
    def init_q_table(self):
        actions = ('00', '01', '02', '03')

        np.random.seed(821029)		
        q_table = np.random.rand(13,len(actions)) * 0.1 - 0.05 
        
        q_table = np.round(q_table, decimals=3)
        return q_table

    def clear(self):
        #print("Clearing table due to attack stopped")
        self.q_table=self.init_q_table()
        #print(self.q_table)

    def update_q_table(self, newstate, prevstate, action, reward, learning_rate, discount):

	# HACK: We consider the segments 128/26 and 192/26 as sources of benign traffic. 
	# Therefore, we assume that blocking these address blocks should yield a negative
	# reward
        if action == 2 or action == 3:
            reward=-5

        max_future_q=max(self.q_table[newstate,:])
        current_q = self.q_table[prevstate, action]
        new_q=(1-learning_rate) * current_q + learning_rate * (reward) + discount * max_future_q 
        #new_q=np.round(max(-1, min(new_q,1)),decimals=3)
        self.q_table[prevstate, action]  = new_q
        return new_q

    def update_parameters(self):
        self.parameters['pkt_counter'] += 1
        #print("En update_parameters ", self.parameters['pkt_counter'])
        if self.parameters['pkt_counter'] % 80 == 0:
            if self.parameters['epsilon'] > 0.1:
                self.parameters['epsilon'] = np.round(self.parameters['epsilon'] - 0.1, decimals=1) # [0.4, 0.3, 0.2, 0.1]
            if self.parameters['learning_rate'] > 0.05:
                self.parameters['learning_rate'] *= 0.85
            if self.parameters['action_weight'] > 1:
                self.parameters['action_weight'] = math.ceil(self.parameters['action_weight'] * 0.5) # [5, 3, 2, 1]
            print(self.parameters)

    def reset_parameters(self, counters, reset_params):
        reset_params.append(counters.counters)
        if len(reset_params) == 4:
            if (all(lst[0] > 98 for lst in reset_params) and all(lst[1] < 2 for lst in reset_params)) or (all(lst[1] > 98 for lst in reset_params) and all(lst[0] < 2 for lst in reset_params)):
                self.parameters['learning_rate'] = 0.5
                self.parameters['epsilon'] = 0.2
                self.parameters['action_weight'] = 5
                self.parameters['pkt_counter'] = 0
                print('PARAMETERS HAVE BEEN RESET!!!')
                reset_params.clear()
        if len(reset_params) == 4:
            reset_params.pop(0)

class counter_stats():
	def __init__(self, counters):
		self.counters = counters
		self.action = 0
		self.reward = 0
		self.alarm = 0
		self.state=0

	def get_ratio(self):
		if self.counters[1] != 0:
			ratio = np.round(abs(self.counters[0] / self.counters[1]), decimals=3)
		else:
			ratio = 0


		return ratio

	def get_state(self):

		if self.state < 12:
			return self.state
		else:
			self.state=0

	def set_state(self, state):
		self.state=state

	def check_alarm(self):
		if self.counters[1] != 0:
			ratio = abs(self.counters[0] / self.counters[1])
		else:
			ratio = 0

		if ratio > 0.3:
			self.alarm = 1
		else:
			self.alarm = 0
		

	def get_next_action(self, table, state, epsilon):
		if np.random.random() < epsilon:
			self.action = np.random.choice(np.arange(4))
		else:
			self.action=np.argmax(table.q_table[state,:])


	def get_rewardX(self, old_counters, table):
		old_ratio = np.round(old_counters.get_ratio(), decimals=3)
		new_ratio = np.round(self.get_ratio(), decimals=3)

		if new_ratio > old_ratio:
			self.reward = -5
		elif new_ratio < old_ratio:
			self.reward = 1
		else:
			self.reward=5

		return self.reward
			


	def get_reward(self, old_counters, table):
		old_ratio = old_counters.get_ratio()
		new_ratio = self.get_ratio()

		if new_ratio > old_ratio:
			self.reward = -5
		else:
			if new_ratio - old_ratio > 0: 
				self.reward = 5
			else:
				self.reward=1

		if new_ratio < 0.5:
			self.reward = 10
			self.alarm=0


		return self.reward



	def get_block(self):

		if self.action == 0:
			return 0
		elif self.action == 1:
			return 64
		elif self.action == 2:
			return 128
		elif self.action:
			return 192


	def write_block(self, p4info_helper, sw, block):
		ena=0
		for i in (0,64,128,192):

			if i == block:
				if i == 0:
					ena=0
				elif i == 64:
					ena=1
				elif i == 128:
					ena=2
				elif i == 192:
					ena=3


		for i in (0,1,2,3):

			param=0
			if i == ena:
				param = 1

			# We trigger the blocking of the corresponding address blocks
			# by calling a bash script that changes the values in the 
			# switch table. We also reset the packet counting in the
			# registers
			# TODO: This should be done through the P4 switch interface
			os.system("bash update_entries.sh " + str(i) + " " + str(param))
			os.system("bash reset_registers.sh")
			

