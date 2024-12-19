# A first approach to the implementation of Machine Learning Algorithms on Programmable Switches

Note: The ideas of this example are based on [1].

## Introduction

The pipeline in reference switching architectures (e.g. PSA) includes a block of Match/Action tables. These tables define a series of matching fields, and a corresponding action to be executed whenever a matching occurs. 
Different works in literature have proposed alternatives to leverage Match/Action tables to implement some classical Machine Learning algorithms within programmable switches. One of these works is the paper by Xiong and Zilberman [1], which describes this implementation of Decision Trees, Support Vector Machines, K-Means and Naive-Bayes algorithms in P4-Programmable Switches. 

In the following exercise, we will focus on the implementation of a Decision Tree based on tree basic features: The IP Protocol, the Transport Layer Source Port and the Transport Layer Destination Port. Although the specific details provided here are for Decision Trees, a similar approach can be followed for the implementation of the other algorithms. Take a look on the paper for further details.

## Data Set Generation

For the development of this exercise, we used the data indicated on [2], which is actually the reference [48] of [1]. That data corresponds to different traffic traces obtained from an IoT network. The previously indicated features were extracted to individual files, which were lately combined to create 12 decision trees. 

## Example: Translating a decision tree to Match/Action tables

Next, we present a decision tree generated following the procedure previously indicated:
```
proto = [];
src = [11, 22157, 23505, 43174, 49930];
dst = [6039, 9144, 22157];
 when src<=11.0  then 2;
 when src>11.0 and dst<=6039.0 and src<=23505.5  then 0;
 when src>11.0 and dst<=6039.0 and src>23505.5 and src<=49930.0  then 4;
 when src>11.0 and dst<=6039.0 and src>23505.5 and src>49930.0  then 3;
 when src>11.0 and dst>6039.0 and src<=43174.5 and dst<=22157.5 and dst<=9144.0  then 4;
 when src>11.0 and dst>6039.0 and src<=43174.5 and dst<=22157.5 and dst>9144.0  then 1;
 when src>11.0 and dst>6039.0 and src<=43174.5 and dst>22157.5 and src<=22157.5  then 1;
 when src>11.0 and dst>6039.0 and src<=43174.5 and dst>22157.5 and src>22157.5  then 3;
 when src>11.0 and dst>6039.0 and src>43174.5  then 4;
```
Consider also the following class matching guide:

```
Action 0 => Drop
Action 2 => Forward to port 2: 2
Action 3 => Forward to port 3: 3
Action 4 => Forward to port 4: 4

If class 0 => Action 2
If class 1 => Action 3
If class 2 => Action 2
If class 3 => Action 3
If class 4 => Action 4
```

Following the approach proposed on [1], we require three tables, one per feature, and one for the final decision process, which in this case is choosing the IP address of a given host to forward the traffic to it. Next we present the table structure for the features considered in the example:

```
table feature1_exact{
        key = {
            hdr.ipv4.protocol : range ;
        }
        actions = {
           NoAction;
            set_actionselect1;
        }
        size = 1024;
        @name("feature1_table_counter")
        counters = direct_counter(CounterType.packets_and_bytes);

}

table feature2_exact{
        key = {
            hdr.tcp.srcPort : range ;
        }
        actions = {
           NoAction;
            set_actionselect2;
        }
       size = 1024;
        @name("feature2_table_counter")
        counters = direct_counter(CounterType.packets_and_bytes);

}

table feature3_exact{
        key = {
            hdr.tcp.dstPort : range ;
        }
        actions = {
           NoAction;
            set_actionselect3;
        }
        size = 1024;
        @name("feature3_table_counter")
        counters = direct_counter(CounterType.packets_and_bytes);

}

```

It is important to remark that for the matching type in the key we use **range**, since for the translation we need to specify the matching criteria as minimum and maximum values for the feature.

For the example, let us consider IP Protocol to be Feature 1, Transport Layer Source Port as Feature 2 and Transport Layer Destination Port as Feature 3.

Next, take a look on the approach for the translation. For instance, consider the following lines of the decision tree:

```
proto = [];
src = [11, 22157, 23505, 43174, 49930];
dst = [6039, 9144, 22157];

```


These are the reference values of the decision tree branches. As it can be seen, this decision tree does not include an explicit condition associated to the IP protocol feature. Hence, we can create a single rule which encompasses the values contained in the data set. For example, let us use 32 (0x20) as the max value for the rule. Keep in mind that the values in the switch tables must be expressed in hexadecimal. The rule for Table 1 would be as follows:


| Min Val | Max Val   | Action   |  
|---|---|---|
| 00  | 20  | set_action_select1=0000000000000001  | 


Table 2, which defines the values for Feature 2 (Transport Layer Source Port), would contain the following entries:


| Min Val | Max Val   | Action   |  
|---|---|---|
| 00  | 0B  | set_action_select2=0000000000000001  |
| 0C  | 568D  | set_action_select2=0000000000000002  | 
| 568E  | 5BD1  | set_action_select2=0000000000000003  | 
| 5BD2  | A8A6  | set_action_select2=0000000000000004  | 
| A8A7  | C30A  | set_action_select2=0000000000000005  | 
| C30B  | FFFF  | set_action_select2=0000000000000006  | 


Finally, Table 3 will contain the following values for Feature 3 (Transport Layer Destination Protocol)

| Min Val | Max Val   | Action   |  
|---|---|---|
| 00  | 1797  | set_action_select3=0000000000000001  |
| 1798  | 23B8  | set_action_select3=0000000000000002  | 
| 23B9  | 568D  | set_action_select3=0000000000000003  | 
| 568E  | FFFF  | set_action_select3=0000000000000004  | 

Afterwards, we can create the representation of the forwarding decision of the switch by using the codified values of the features. 

The forwarding table of the switch has the following structure:

```
    table ipv4_exact {
        key = {
            meta.action_select1: range;
            meta.action_select2: range;
            meta.action_select3: range;
  }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
        @name("ipv4_exact_table_counter")
        counters = direct_counter(CounterType.packets_and_bytes);
    }

```

Let us consider for illustration purposes the following three rules from the example decision tree:

```
 when src<=11.0  then 2;
 when src>11.0 and dst<=6039.0 and src<=23505.5  then 0;
 when src>11.0 and dst<=6039.0 and src>23505.5 and src>49930.0  then 3;
```

The values for the forwarding table, using the codified values for the feature, are as follows:

| Action select 1 | Action Select 2   | ActionSelect 3   | Class | Action | 
|---|---|---|---|---|
| Min=1,Max=1  | Min=1,Max=1  | Min=1,Max=4  | 2  | Forward to port 2, Host 2 |
| Min=1,Max=1  | Min=2,Max=3  | Min=1,Max=1  | 0  | Forward to port 2, Host 2 |
| Min=1,Max=1  | Min=6,Max=6  | Min=1,Max=1  | 3  | Forward to port 3, Host 3 |


## Exercise

Consider the files defined in the Decision Tree folder of the GIT repository. There you will find the following subfolders:

* trees: This subfolder contains two versions of the decision trees: L3 contains the trees with three depth levels whereas L4 contains the trees with four depth levels. Use the version indicated by your professor.
* send_packets.py: It is a simple python script which you can use to generate packets from one of the hosts of your mininet topology in order to validate the operation of your scenario.
* simple_switch.p4-TODO contains the template of the P4 program you must complete. Follow the TODO comments within the code, and when you complete these modifications, rename this file as simple_switch.p4 so that the make command finds it and starts the topology.

 

### References

[1] Xiong, Z., & Zilberman, N. (2019, November). Do switches dream of machine learning? toward in-network classification. In Proceedings of the 18th ACM workshop on hot topics in networks (pp. 25-33).

[2] Sivanathan, A., Gharakheili, H. H., Loi, F., Radford, A., Wijenayake, C., Vishwanath, A., & Sivaraman, V. (2018). Classifying IoT devices in smart environments using network traffic characteristics. IEEE Transactions on Mobile Computing, 18(8), 1745-1759.
