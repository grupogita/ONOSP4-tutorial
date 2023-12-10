### Implementation of Decision Trees within P4-Programmable Switches

This exercise presents the implementation of a Decision Tree within a P4-Programmable Switch. This scenario has been tested withe the BMv2 reference switch.

## Tasks to complete:

0. Read the detailed description contained [here](https://github.com/grupogita/ONOSP4-tutorial/wiki/decision_trees_on_programmable_switches_v1)
1. Pick one of the pre-trained decision trees contained in the L3 or L4 subfolders. The trained trees in L3 are three depth levels trees whereas those contained in L4 are four depth levels trees.
2. Analyze the definition of rules which apply for your tree, according to the values of the features
3. Customize whatever required in the p4src/switch_gita.p4 file
4. Customize and create the flow entries according to the configuration of your tree in the flows.json file. Use as reference the templates indicated and duplicate them as many times as you need.
5. Compile your p4 program
6. Copy the output files of the compilation process to the corresponding folder in the java application source directory.
7. Compile the java application.
8. Deploy the JAVA application into ONOS
9. Deploy the network configuration file into ONOS
10. Deploy the flow entries with the json file customized in step 4 and using the commandFlows.sh shell script.
11. If not installed, install xterm in your virtual machine
12. Connect via SSH to your virtual machine taking care of enabling X11 forwarding with your SSH client passing the -x command line option (If you are using Windows, you might need to install an X11 server. For example you can try [Freexer](https://sourceforge.net/projects/freexer/)
13. Start your topology taking care of preserving environmental variables when invoking sudo passing the -E command line option.
14. Start xterm on all the nodes of your topology. Hosts 1 and 4 can be used to generate traffic by running the send_packets.py script. On the other hand, hosts 2 and 3 can be used to receive traffic with tcpdumo in order to verify the operation of the switch. 
