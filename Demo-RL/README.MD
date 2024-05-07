# A first demo of Reinforcement Learning with P4
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![GitHub release](https://img.shields.io/badge/pre--release%20tag-v0.2.0-orange)

## Introduction

The present code is a preliminary implementaiton of a solution that combines P4 programmable switches and Reinforcement Learning applied to the mitigation of a Syn Flood attack.

The scenario herein presented is based on the code available for the paper the paper "QCMP: Load Balancing via In-Network Reinforcement Learning" [PDF](./images/Zheng_et_al_2023_QCMP_load_balancing.pdf) in 2nd ACM SIGCOMM Workshop on FIRA '23. Some aparts of the code and modified and adapted to product the present scenario. 

This code is executed in an instance of the P4.org virtual machine. In particular, we started to work with the release of July 1st 20234, were we installed and deployed the code. An image of the virtual machine can be downloaded from [here](xxxxxx).

## Getting started
If you would like to start from scratch on a clean virtual machine instance, in order to run the scenario, clone the repository ```git clone https://github.com/grupogita/ONOSP4-tutorial/Demo-RL.git``` to a local directory in the folder tutorials and run the following 7 steps:

1. In terminal:
```bash
make run
mininet> xterm h1 h2 h4 h6 s1 
```

2. In s1 terminal:
```bash
python3 ./receive_counters.py
```

3. In another s1 terminal:
```bash
wireshark
```
, monitoring port ```s6-eth1```, open ```I/O Graph``` under ```Statistics``` bar. Add a two graphics, with the view filters ip.src == 10.0.1.11 and ip.src == 10.0.1.82

4. In h4 terminal:
```bash
python3 get_counters.py
```

5. In h6 terminal:
```bash
python3 -m http.server 80
```

6. In h1 terminal:
```bash
while [ 1 -eq 1]; do wget -O - http://10.0.6.11:80; sleep 1; done
```

7. In h2 terminal:
```bash
python3 send_attack.py
```

After these 7 steps, wait a few seconds and you will see how the Syn Flood attack generated from IP address 10.0.1.82 is eventually stopped. The logic of the implemented scenario is as follows:

- The "controller" script executed at S1 (receive\_counters.py) receives the packets sent from H4, which collects the valus of the counters calculated in switches. This script calculates the ratio between SYN and SYN+ACK packets. If this ratio is higher than 1, then it is considered as a possible SYN flood attack. Hence, the agent starts the RL algorithm and attempts to block different ranges of IP addresses. If it blocks the 10.0.1.0/26 range, then it causes that the ratio doesn't change, which indicates that all the traffic, including the legitimitate was blocked. Hence, the agent receives a negative reward. Otherwise, of the 10.0.1.64/26 range is blocked, where the attacker is located, the agent receives a positive high reward, because it successfully blocked the attack. 



## Used topology
The topology used for this evaluation is the same displayed for the QCMP paper. In our case, the topology is configured with static routing, which is defined in the runtime files located at the pod\_topo subfolder:

<img src="./images/topology.jpg" width = "500"  align= left/>

In this preliminary version, the RL agent only operates in the S1 switch.

## Reporting a Bug
If you find any problem trying to execute this code, please send a mail to [sergio.gutierrezb@udea.edu.co](mailto: sergio.gutierrezb@udea.edu.co)
## License

The files are licensed under Apache License: [LICENSE](./LICENSE). The text of the license can also be found in the LICENSE file.

## Citation
The code herein contained comes from the QCMP paper which can be found [here](https://dl.acm.org/doi/abs/10.1145/3607504.3609291):

```
@inproceedings{zheng2023qcmp,
  title={{QCMP: Load Balancing via In-Network Reinforcement Learning}},
  author={Zheng, Changgang and Rienecker, Benjamin and Zilberman, Noa},
  booktitle={Proceedings of the 2nd ACM SIGCOMM Workshop on Future of Internet Routing \& Addressing},
  pages={35--40},
  year={2023}
}
```
