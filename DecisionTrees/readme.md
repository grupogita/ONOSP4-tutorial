### Implementation of Decision Trees within P4-Programmable Switches

This exercise presents the implementation of a Decision Tree within a P4-Programmable Switch. This scenario has been tested withe the BMv2 reference switch.

## Tasks to complete:

0. Read the detailed description contained [here](https://github.com/grupogita/ONOSP4-tutorial/wiki/decision_trees_on_programmable_switches_v1)
1. Pick one of the pre-trained decision trees contained in the L3 or L4 subfolders. The trained trees in L3 are three-depth level trees whereas those contained in L4 are four-depth level trees.
2. Analyze the definition of rules which apply for your tree, according to the values of the features.
3. Customize whatever required in the p4src/switch_gita.p4 file. See the TO-DO comments and the corresponding hints.
4. Customize and create in the flow.json file the flow entries according to the configuration of your tree. Use as reference the templates indicated and duplicate them as many times as you need.
5. Compile your p4 program.
  
```
$ cd p4src
$ p4c -b bmv2 --p4runtime-files sw_gita.p4info.txt sw_gita.p4
```
6. Copy the output files of the compilation process to the corresponding folder in the java application source directory.
```
$ cd p4src
$ cp sw_gita.json ../app/src/main/resources
$ cp sw_gita.p4info.txt ../app/src/main/resources
```
 
7. Compile the JAVA application.
```
$ cd app
$ /opt/maven/bin/mvn clean package
```
8. Deploy the JAVA application into ONOS. Execute the following command from the app subdirectory.
```
$ curl --fail -sSL --user onos:rocks --noproxy localhost -X POST -HContent-Type:application/octet-stream \
                'http://A.B.C.D:8181/onos/v1/applications?activate=true' \
                --data-binary @target/gita-p4-tutorial-1.0-SNAPSHOT.oar
```
9. Deploy the network configuration file into ONOS

```
$ curl --fail -sSL --user onos:rocks --noproxy localhost -X POST -H 'Content-Type:application/json' \
                http://A.B.C.D:8181/onos/v1/network/configuration -d@./mininet/netcfg.json
```
10. Deploy the flow entries with the json file customized in step 4 and using the commandFlows.sh shell script.
```
$ chmod +x commandFlows.sh
$ ./commandFlows.sh
```
  
11. If not installed, install xterm in your virtual machine
12. Connect via SSH to your virtual machine taking care of enabling X11 forwarding with your SSH client passing the -x command line option (If you are using Windows, you might need to install an X11 server. For example you can try [Freexer](https://sourceforge.net/projects/freexer/)
13. Start your topology taking care of preserving environmental variables when invoking sudo passing the -E command line option.
```
$ cd mininet
$ sudo -E python3 topo.py
```
14. Start xterm on all the nodes of your topology. Hosts 1 and 4 can be used to generate traffic by running the send_packets.py script. On the other hand, hosts 2 and 3 can be used to receive traffic with tcpdump in order to verify the operation of the switch.
```
mininet> xterm h1 h2 h3 h4
```

