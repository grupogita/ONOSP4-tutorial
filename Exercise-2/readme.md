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

After performing the previous step, you can check the topology was created correctly using the following commands:
* `make app-build` 
* `make start`
* `make mn-log`

As a quick reminder, the `make app-build` command will compile the P4 program and will compile the pipeconf application that needs to be installed in ONOS. `make start` command will start the ONOS instance and the Mininet instance, and `make mn-log` will display the last lines of the Mininet log. Look for any errors that might occur.
At this point, if you are working on the P4 program of the exercise 1, and if you correctly applied the change to the topology file, you will see that although you create the flow entries, you can not ping from h1 to h2 or from h2 to h1. This is because the originating host does not know the MAC address of the destination host, and the ARP request is issuing is not being responded.

To fix this, you will have to apply the changes indicated in the `p4src/main.p4` file, indicated with the **Exercise 2 TO-DO** notes.

After completing these changes, you should recompile the P4 program and the pipeconf application, reinstall the pipeconf application and recreate the network configuration. Although it should not be necessary, it is recommended that you restart onos before install the new application. It is advised to execute the following sequence of commands:
* `make stop`
* `make start`
* `make app-build` 
* `make app-install`
* `make netcfg`

After executing these commands, you could use `make onos-log` to check that the switch in the mininet topology connects to the controller. If any error appears, take a look on the message and apply the corresponding field.

### Interacting with the ONOS controller through the REST API

The documentation page of ONOS provide a REST API that allows to provide information to the devices under control. The json templates to create the entries in the switch that will provide the mapping between IP address and MAC address are contained in the `p4src/flows` file. In order to provide this information to the controller, you can either use Postman as described [in this page of Exercise 1](https://github.com/grupogita/ONOSP4-tutorial/wiki/Exercise-1:-First-approach-to-the-P4-development-process#interacting-with-the-onos-controller-through-the-rest-api), or by using curl command as show in the following example:

`$ curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d 'XXXXX' 'http://A.B.C.D:8181/onos/v1/flows/device%3As1?appId=YY'`

where: XXXXX corresponds to one of the flow entry templates available in the flows file, A.B.C.D is the IP address of the controller, and YY is the application id, which for our case can be set to the value **0**.

Note: If you restarted the environment, you will need to provide the corresponding entries that were used in the Exercise 1 (i.e., those entries that populate the l2_exact_table). That means that after applying the flow entries, the switch must have four flow entries associated to the application id 0.

After applying the changes, the ping between hosts should function correctly.

If you arrive sucessfully to this point, congratulations for completing exercise 2.

