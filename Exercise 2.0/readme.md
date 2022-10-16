# Programming of a Switch with built-in ARP Responder

In this exercise, you will program a switch capable to responde to ARP requests by itself. This exercise is similar to the exercise 2 based on the docker infrastructure. A main difference of this exercise is that you will have to implement an ONOS application which will discover the MAC addresses and will populate the switch table containing the mapping between MAC and IP addresses.

## Previous configuration of ONOS

In order to implement the topology for this exercise, some previous steps will have to be done in the ONOS environment. We will use the Command Line Interface (CLI) to apply these changes.

* Access the ONOS CLI. Remember that the default password is rocks

`ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "HostKeyAlgorithms=+ssh-rsa" -o LogLevel=ERROR -p 8101 onos@localhost`



* Check the installed applications:

`onos@root> apps -s`


* Enable the applications Stratum Drivers, BMV2 Drivers, HostLocationProvider and NetConf Provider

```
onos@root> app activate org.onosproject.drivers.stratum
onos@root> app activate org.onosproject.drivers.bmv2
onos@root> app activate org.onosproject.hostprovider
onos@root> app activate org.onosproject.netconf
```


* List the configuration variables for the implementing class of the HostLocationProviderApplication (i.e. org.onosproject.provider.host.impl.HostLocationProvider). Make sure that only the requestArp parameter has value true. In case it does not, modify it with the cfg set subcommand

`onos@root > cfg get org.onosproject.provider.host.impl.HostLocationProvider`


## Create the P4 program file

The first step to implement a functionality within a programmable switch is to create the P4 program defining its behavior. In the directory p4src you will find the file sw_gita.json, which contains a skeleton of the program required to define the intended functionality for the switch. You must complete the tasks indicated in the TO-DO comments.

## Compilation of the P4 program

After performing the required modifications, you should compile the P4 program. In this step, you will generate both the "executable" for the switch and the representation of its pipeline (The runtime configuration file). Since you are working in a simulated environment, you do not actually generate an executable switch but a JSON file which stratum_bmv2 uses as configuration file.

For the compilation of the P4 program, execute the following commands:

```
$ cd p4src
$ p4c -b bmv2 --p4runtime-files sw_gita.p4info.txt sw_gita.p4
```

With this command, you indicate that you will be compiling a program for the stratum_bmv2 switch, you will generate the runtime file in format txt, and you will pass the name of your P4 source file.


## Modification of the Pipeconf application

In order to integrate stratum_bmv2 switches with ONOS, the controller needs to be aware of the presence of the switch and its pipeline configuration. ONOS does this through an application that takes as input the "executable" of the switch and its runtime file. In the app subdirectory, you will find this application. Modify the following files to reflect the required changes

* app/src/main/java/co/edu/udea/gita/tutorial/pipeconf/InterpreterImpl.java

In this file you must modify the CRITERION_MAP Builder constructor in order to reflect the columns of the acl_table of the switch. Also, you must modify the corresponding metadata fields in the mapInboudPacket() and buildPacketOut() methods. Follow the TO-DO comments contained in the code in order to complete these modifications.

* app/src/main/java/co/edu/udea/gita/tutorial/pipeconf/PipeconfLoader.java

In this file, you must adjust the path names of the "executable" and runtime switch files. These path names are expressed as absolute paths related to the app/src/main/resources directory. Follow the TO-DO comments contained in the code in order to complete these modifications.

After completing these modifications, you must copy the switch associated files ("executable" and runtime file) to the app/src/main/resources directory.

Then, you must procede to the modification of the ArpResponder application.

## Modification of the ArpResponder application

This switch is intended to reply ARP Requests by itself. For the implementation of this functionality, the switch will have to forward ARP packets to the controller in such a way that it can intercept and process them. This is done by the HostProvider application which was initially activated. This application inserts an entry into the acl_table of the switch, which in the P4 program causes that the switch forward the packets to the controller. See the switch code for further details.

The ArpResponder application connects with several applications running in ONOS and installs an interceptor for the ARP packets. Actually, due to the configuration of the switch, only ARP packets are sent to the controller. However, for other applications, a different type of packet might be also forwarded. That is why the interceptor is a key point.

This application is defined in the file app/src/main/java/co/edu/udea/gita/tutorial/ArpResponder.java

You must follow the TO-DO comments in order to make functional this application. In particular, you will adjust the traffic interceptor and the creation of the entry that will be inserted in the corresponding table. Take a look in the code of the application and in the P4 program to better understand the required changes.

## Compilation of the ONOS application

Finally, you can compile the java application by using maven:

``` 
$ cd app 
$ mvn clean package
```

If the compilation is succesfull, you will find the gita-p4-tutorial-1.0-SNAPSHOT.oar file in the target directory

## Deploy the application

After compiling the ONOS application, it can be deployed through the web interface of the controller. You can use the following command to perform this deployment. The command should executed in the app subdirectory of the tutorial exercise:

```
$ curl --fail -sSL --user onos:rocks --noproxy localhost -X POST -HContent-Type:application/octet-stream \
                'http://localhost:8181/onos/v1/applications?activate=true' \
                --data-binary @target/gita-p4-tutorial-1.0-SNAPSHOT.oar
```

You can confirm the deployment by inspecting the ONOS log:

` $ tail -f /opt/onos/logs/karaf.log`

## Load the Network Configuration file in ONOS

As previously mentioned, ONOS must be aware of the devices contained in the topology. After deploying the pipeconf application, then a network configuration file must be installed within ONOS. In the mininet subdirectory you can find the netcfg.json file supplies to the controller information of the topology that will be executed later. In particular, take a look in the information associated to the switch, which is contained in the devices section. The key elements here are the managementAddress and the pipeconf

