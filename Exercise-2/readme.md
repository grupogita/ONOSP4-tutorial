## Exercise 2: A Switch with a built in ARP responder

In this exercise, you will go one step further by implementing a network function within the switch. In this case, you will make your switch capable to respond ARP requests by itself, provided that it contains static information to proceed.

Address Resolution Protocol is a network protocol which allows a host to determine the physical (e.g. MAC) address of a device given its logical or protocol (e.g. IPv4) address. This step is required in order to provide the values for the destination and source MAC addresses in the Ethernet frame header. Hence, a device must be able to map the logical address with a phyisical address. This mapping can be done either statically (manually configured in the Operating System) or dynamically by querying other devices in the same broadcast domain.
When a device does not know the physical address of other device, and assuming that no static mapping exists in the Operating System, then it proceeds to generate an ARP request message, which is sent to the physical broadcast address (i.e. A message asking: What is the Phyisical Address of the device identified with the IP address X.X.X.X?). Thus, it is expected that if the device with the given IP address is connected, it will reply with its physical (MAC) address with an ARP reply message, sent as an unicast message.

In SDN environments, it is common that ARP query messages be sent to the controller so that it determines the corresponding physical address. In this exercise, and with the goal of demonstrating part of the development process of P4 programs, we will develop a switch capable to respond to ARP requests assuming that it contains the information of the mapping between IP addresses and MAC addresses.

Hence, the switch will have to be extended to parse ARP packets, distinguishing ARP requests and building and transmitting ARP replies to the requesting host. In order to provide this functionality, the switch will have a table with a key consisting in the IP address and a value containing the corresponding MAC address. These values will have to be provided in advance.

### Topology and Mininet
The exercise requires the creation of two links between two devices (H1 - H2) and one switch (SW). The following diagram shows the resulting topology:

<p align="center">
  <img src="https://github.com/grupogita/ONOSP4-tutorial/blob/main/wiki-images/Topology_1.png" />
</p>

The first task to perform is to edit the file “topo.py” by addressing the tasks indicated with the _”TO-DO”_ comments within the code. Particularly for this exercise, and in case of being using the same file after completing the Exercise 1, you must peform the change suggested at the _"Exercise 2 TO-DO"_ comment to disable the static ARP mapping.

## Previous configuration of ONOS

In order to implement the topology for this exercise, some previous steps will have to be done in the ONOS environment. We will use the Command Line Interface (CLI) to apply these changes.

* Access the ONOS CLI. Remember that the default password is rocks.

`ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "HostKeyAlgorithms=+ssh-rsa" -o LogLevel=ERROR -p 8101 onos@localhost`


* Check the installed applications:

`onos@root> apps -s`


* Enable the applications Stratum Drivers, BMV2 Drivers, HostLocationProvider and NetConf Provider.

```
onos@root> app activate org.onosproject.drivers.stratum
onos@root> app activate org.onosproject.drivers.bmv2
onos@root> app activate org.onosproject.hostprovider
onos@root> app activate org.onosproject.netconf
```

* List the configuration variables for the implementing class of the HostLocationProviderApplication (i.e. org.onosproject.provider.host.impl.HostLocationProvider). Make sure that only the requestArp parameter has value true. In case it does not, modify it with the cfg set subcommand.

`onos@root > cfg get org.onosproject.provider.host.impl.HostLocationProvider`

For example, to modify the requestIpv6ND variable, you can use the following command:

`onos@root > cfg set org.onosproject.provider.host.impl.HostLocationProvider requestIpv6ND false`

## Compilation of the P4 program

After performing the required modifications, you should compile the P4 program. In this step, you will generate both the "executable" for 
the switch and the representation of its pipeline (The runtime configuration file). Since you are working in a simulated environment, you do not 
actually generate an executable file for the switch but a JSON file which stratum_bmv2 uses as configuration file.

For the compilation of the P4 program, execute the following commands:

```
$ cd p4src
$ p4c -b bmv2 --p4runtime-files p4info.txt main.p4
```

With this command, you indicate that you will be compiling a program for the stratum_bmv2 switch, you will generate the runtime file in format txt, 
and you will pass the name of your P4 source file.


## Compilation of the ONOS application

You must install the java application which will enable the communication between the controller (ONOS) and the switch in order to manage the flow rules.

For the compilation, you need to copy the two output files generated in the compilation step:

``` 
$ cp p4src/main.json app/src/main/resources 
$ cp p4src/p4info.txt app/src/main/resources
$ mvn clean package
```



Finally, you can compile the java application by using maven:



If the compilation is succesfull, you will find the gita-p4-tutorial-1.0-SNAPSHOT.oar file in the target subdirectory.



## Deploy the application

After compiling the ONOS application, it can be deployed through the web interface of the controller. You can use the following command to perform this deployment. The command should be executed in the app subdirectory of the tutorial exercise:

```
$ curl --fail -sSL --user onos:rocks --noproxy localhost -X POST -HContent-Type:application/octet-stream \
                'http://A.B.C.D:8181/onos/v1/applications?activate=true' \
                --data-binary @target/gita-p4-tutorial-1.0-SNAPSHOT.oar
```
where A.B.C.D is the IP of the controller. If you are running the commands directly on the Operating System where you installed ONOS, 
this IP address can be replaced with localhost. 

You can confirm the deployment by inspecting the ONOS log:

` $ tail -f /opt/onos/logs/karaf.log`

## Load the Network Configuration file in ONOS

As previously mentioned, ONOS must be aware of the devices contained in the topology. After deploying the pipeconf application, then a network 
configuration file must be installed within ONOS. In the mininet subdirectory you can find the netcfg.json file supplies to the controller 
information of the topology that will be executed later. In particular, take a look in the information associated to the switch, which is 
contained in the devices section. The key elements here are the managementAddress and the pipeconf. The managementAddress defines the management 
address and port of the stratum_bmv2 switch that will be included in the topology. The pipeconf field refers to the name of the piepconf 
application deployed in the previous step.

In the repository we provide a template for the network configuration file. This template can be loaded to ONOS through the REST interface with the following command:

```
$ curl --fail -sSL --user onos:rocks --noproxy localhost -X POST -H 'Content-Type:application/json' \
                http://A.B.C.D:8181/onos/v1/network/configuration -d@./mininet/netcfg.json
```

where A.B.C.D is the IP of the controller. If you are running the commands directly on the Operating System where you installed ONOS, this IP address can be replaced with localhost.

## Run the mininet topology

In the subdirectory mininet you will find two files topo.py and stratum2.py. topo.py contains the topology file. In this file you will 
create a basic topology based on two hosts connected to a single switch, which will be implemented as a stratum_bmv2 switch. 
Follow the TO-DO comments. On the other hand, stratum2.py is a wrapper class which performs the invocation of a stratum_bmv2 and includes 
it in the mininet topology. Take a look on this file and adjust the parameters indicated with the TO-DO comments.


### Interacting with the ONOS controller through the REST API

The documentation page of ONOS provide a REST API that allows to provide information to the devices under control. The json templates to create the entries in the switch that will provide the mapping between IP address and MAC address are contained in the `p4src/flows` file. In order to provide this information to the controller, you can either use Postman as described [in this page of Exercise 1](https://github.com/grupogita/ONOSP4-tutorial/wiki/Exercise-1:-First-approach-to-the-P4-development-process#interacting-with-the-onos-controller-through-the-rest-api), or by using curl command as show in the following example:

`$ curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d 'XXXXX' 'http://A.B.C.D:8181/onos/v1/flows/device%3As1?appId=YY'`

where: XXXXX corresponds to one of the flow entry templates available in the flows file, A.B.C.D is the IP address of the controller, and YY is the application id, which for our case can be set to the value **0**.

Note: If you restarted the environment, you will need to provide the corresponding entries that were used in the Exercise 1 (i.e., those entries that populate the l2_exact_table). That means that after applying the flow entries, the switch must have four flow entries associated to the application id 0.

After applying the changes, the ping between hosts should function correctly.

If you arrive sucessfully to this point, congratulations for completing exercise 2.

