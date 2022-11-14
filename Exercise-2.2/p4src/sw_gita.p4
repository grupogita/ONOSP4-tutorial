#include <core.p4>
#include <v1model.p4>

// Description taken from NGSDN-TUTORIAL
// CPU_PORT specifies the P4 port number associated to controller packet-in and
// packet-out. All packets forwarded via this port will be delivered to the
// controller as P4Runtime PacketIn messages. Similarly, PacketOut messages from
// the controller will be seen by the P4 pipeline as coming from the CPU_PORT.
#define CPU_PORT 255

// Description taken from NGSDN-TUTORIAL
// CPU_CLONE_SESSION_ID specifies the mirroring session for packets to be cloned
// to the CPU port. Packets associated with this session ID will be cloned to
// the CPU_PORT as well as being transmitted via their egress port (set by the
// bridging/routing/acl table). For cloning to work, the P4Runtime controller
// needs first to insert a CloneSessionEntry that maps this session ID to the
// CPU_PORT.
#define CPU_CLONE_SESSION_ID 99

// Type aliases defined for convenience
typedef bit<9>   port_num_t;
typedef bit<48>  mac_addr_t;
typedef bit<32>  ipv4_addr_t;
typedef bit<16>  l4_port_t;


// Exercise 2.1 TO-DO: Define values for these constants representing
// the Ethertype codes
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_ARP = 0x0806;

const bit<8> IP_PROTO_TCP    = 6;

/*
    Exercise 2.1 TO-DO: Define symbolic constants for different ARP fields.
    Refer to RFC 826 for the sizes and reference values.
*/
const bit<16> ARP_HTYPE = 0x0001; //Ethernet Hardware type is 1
const bit<16> ARP_PTYPE = ETHERTYPE_IPV4; //Protocol used for ARP is IPV4
const bit<8>  ARP_HLEN  = 6; //Ethernet address size is 6 bytes
const bit<8>  ARP_PLEN  = 4; //IP address size is 4 bytes
const bit<16> ARP_REQ = 1; //Operation 1 is request
const bit<16> ARP_REPLY = 2; //Operation 2 is reply


// Type definition for convenience. Counters are defined as 32 bits
typedef bit<32> PacketCounter_t;

const bit<4> MAX_PORT = 15;


//------------------------------------------------------------------------------
// HEADER DEFINITIONS
//------------------------------------------------------------------------------

header ethernet_t {
    mac_addr_t  dst_addr;
    mac_addr_t  src_addr;
    bit<16>     ether_type;
}


/*
  Exercise 2.1 TO-DO: Define a type for the header of an ARP packet.
  Remember that an ARP packet contains the following fields:
  Hardware Type, Prtocol Type, Hardware Length, Protocol Length,
  Operation Code, Source Hardware Address, Source Protocol Address,
  Target Hardware Address and Target Potocol Address.
  Refer to RFC 826 for the details on each of these fields
*/

header arp_t {
  bit<16>   h_type;
  bit<16>   p_type;
  bit<8>    h_len;
  bit<8>    p_len;
  bit<16>   op_code;
  mac_addr_t src_mac;
  bit<32> src_ip;
  mac_addr_t dst_mac;
  bit<32> dst_ip;
  }


header ipv4_t {
    bit<4>   version;
    bit<4>   ihl;
    bit<6>   dscp;
    bit<2>   ecn;
    bit<16>  total_len;
    bit<16>  identification;
    bit<3>   flags;
    bit<13>  frag_offset;
    bit<8>   ttl;
    bit<8>   protocol;
    bit<16>  hdr_checksum;
    bit<32>  src_addr;
    bit<32>  dst_addr;
}

/*
    Exercise 2.2 TO-DO: Define the TCP header according RFC 793. 
    For the definition of this header, you might omit the options
    fields since it is considered for this exercise. Also, it is
    recommended to create individual fields for the six operation
    bits of the protocol. Keep in mind that these fields must be
    defined in order.
*/
header tcp_t {

}

// Description taken from NGSDN-TUTORIAL
// Packet-in header. Prepended to packets sent to the CPU_PORT and used by the
// P4Runtime server (Stratum) to populate the PacketIn message metadata fields.
// Here we use it to carry the original ingress port where the packet was
// received.
@controller_header("packet_in")
header cpu_in_header_t {
    port_num_t  ingress_port;
    bit<7>      _pad;
}

// Description taken from NGSDN-TUTORIAL
// Packet-out header. Prepended to packets received from the CPU_PORT. Fields of
// this header are populated by the P4Runtime server based on the P4Runtime
// PacketOut metadata fields. Here we use it to inform the P4 pipeline on which
// port this packet-out should be transmitted.
@controller_header("packet_out")
header cpu_out_header_t {
    port_num_t  egress_port;
    bit<7>      _pad;
}

struct parsed_headers_t {
    cpu_out_header_t cpu_out;
    cpu_in_header_t cpu_in;
    ethernet_t ethernet;
    /*
        Exercise 2.1 TO-DO: Include the ARP header in the set of
        headers recognized by this switch.
    */
    arp_t arp;
    ipv4_t ipv4;

    /*
        Exercise 2.2 TO-DO: Include the TCP header in the set of
        headers recognized by this switch.
}

struct local_metadata_t {
        @field_list(1)
        port_num_t ingress_port;


        /*
            Exercise 2.2 TO-DO: Include the following fields in the
            local_metadata struct, considering the indicated field lengths:

            1. A flag to identify if the packet is a TCP SYN segment (1 bit)
            2. A field to save the TCP Source Port (2 bytes)
            3. A field to save the TCP destination Port (2 bytes)
            4. A field to save the IP Source Address (4 bytes)
            5. A field to save the IP Destination Address (4 bytes)
            6. A field to save the Ethernet Source Address (6 bytes)
            7. A field to save the Ethernet Destination Address (6 bytes)
            8. A field to save the TCP Sequence Number (4 bytes)
            9. A field to save the length of the TCP Payload (2 bytes)
        */
}


//------------------------------------------------------------------------------
// INGRESS PIPELINE
//------------------------------------------------------------------------------

parser ParserImpl (packet_in packet,
                   out parsed_headers_t hdr,
                   inout local_metadata_t local_metadata,
                   inout standard_metadata_t standard_metadata)
{
    state start {
        local_metadata.ingress_port = standard_metadata.ingress_port;
        transition select(standard_metadata.ingress_port) {
            CPU_PORT: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.cpu_out);
        transition parse_ethernet;
    }

    /*
        Exercise 2.1 TO-DO: Perform three changes to the parse_ethernet
        state:
             1. Create a transition selection based on the ether_type field
                of the ethernet header. (Hint: use the P4 transition select
                construct)
             2. For IPv4 packets, transition to the parse_ipv4 state
             3. For ARP packets, trasition to the parse_arp state.
             Note: Leave the parse_ipv4 state as default transition
    */
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type){
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_ARP: parse_arp;
            default: accept;
        }
    }

    /*
        Exercise 2.1 TO-DO: Define the parse_arp state which should
        perform the following two things:
        1. Extract the arp header from the packet
        2. Create a transition selection based on the ARP Operation
           code in such a way that only ARP requestes get accepted
    */
    state parse_arp {
        packet.extract(hdr.arp);
        transition select(hdr.arp.op_code) {
                ARP_REQ: accept;
        }
    }

    /* 
        Exercise 2.2 TO-DO: Modify the parse_ipv4 to consider the following things:
        1. Do a transition on the protocol field of the IPv4 header
        2. If the datagram contans a TCP packet, transition to a state to parse it.
        3. By default, all the remaining IPv4 traffic should be accepted
    */

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        /*
            Exercise 2.2 TO-DO: Fix the calculation of the size of the IP payload
            Hint 1: The total length in the IPv4 header is expressed in bytes.
            Hint 2: The length of the IPv4 header is expressed in words of 32 bytes.
            Hint 3: The IPv4 header length must be casted to a 16-bits value
        */
        local_metadata.l4Len = <FIX ME>;
        transition select(hdr.ipv4.protocol) {

        }

    }

    /*
        Exercise 2.2 TO-DO: Create a state to parse the TCP packets
        1. Extract the TCP header
        2. Verify whether the TCP header is valid indeed.
        3. Save the following fields to the local metadata struct:
           3.1 If the packet is a TCP Syn, set a flag to indicate this
           3.2 The TCP source and destination ports
           3.3 The TCP sequence number
           3.4 The IP source and destination addresses
           3.5 The Ethernet source and destination addresses

        4. Finally, accept the packet.
    */

    state parse_tcp {
    }


}


control VerifyChecksumImpl(inout parsed_headers_t hdr,
                           inout local_metadata_t meta)
{
    // Description taken from NGSDN-TUTORIAL
    // Not used here. We assume all packets have valid checksum, if not, we let
    // the end hosts detect errors.
    apply { /* EMPTY */ }
}


control IngressPipeImpl (inout parsed_headers_t    hdr,
                         inout local_metadata_t    local_metadata,
                         inout standard_metadata_t standard_metadata) {

    // Two counters are created: One for the match in the creation of
    // TCP sessions and other to account the rejections
    counter((bit<32>)MAX_PORT, CounterType.packets) session_counter;
    counter((bit<32>)1, CounterType.packets) rejects_counter;


    // Drop action shared by many tables.
    action drop() {
        mark_to_drop(standard_metadata);
    }


    // *** L2 BRIDGING
    //
    // --- l2_exact_table (for unicast entries) --------------------------------

    action set_egress_port(port_num_t port_num) {
        standard_metadata.egress_spec = port_num;
    }

    table l2_exact_table {
        key = {
            hdr.ethernet.dst_addr: exact;
        }
        actions = {
            set_egress_port;
            @defaultonly drop;
        }
        const default_action = drop;
        // The @name annotation is used here to provide a name to this table
        // counter, as it will be needed by the compiler to generate the
        // corresponding P4Info entity.
        @name("l2_exact_table_counter")
        counters = direct_counter(CounterType.packets_and_bytes);
    }

    // *** ACL
    //
    // Description taken from NGSDN-TUTORIAL
    // Provides ways to override a previous forwarding decision, for example
    // requiring that a packet is cloned/sent to the CPU, or dropped.
    //
    action send_to_cpu() {
        standard_metadata.egress_spec = CPU_PORT;
    }

    action clone_to_cpu() {
        clone_preserving_field_list(CloneType.I2E, CPU_CLONE_SESSION_ID,1);
    }

    table acl_table {
        key = {
            standard_metadata.ingress_port: ternary;
            hdr.ethernet.dst_addr:          ternary;
            hdr.ethernet.src_addr:          ternary;
            hdr.ethernet.ether_type:        ternary;
            hdr.ipv4.protocol:              ternary;
        }
        actions = {
            send_to_cpu;
            clone_to_cpu;
            drop;
        }
        @name("acl_table_counter")
        counters = direct_counter(CounterType.packets_and_bytes);
    }

    /*
        Exercise 2.1 TO-DO: Create an action to build an ARP reply.
        The name of this action will be arp_reply.
        This action will receive a MAC address provided by the
        table match. Keep in mind the following things for this
        action

        1. The operation code is the one corresponding to an ARP
           reply.
        2. The Target Hardware Address will be set to the source
           MAC address.
        3. The Source Hardware Address will be set to the MAC address
           provided by the table match (i.e. the parameter of the
           action).
        4. The Source Protocol Address will be set to the
           Target Protocol Address contained in the request
        5. The destination address of the Ethernet header will be set
           to its source address (to create a reply).
        6. The source address of the Ethernet header will be set to
           the MAC address provided by the table match (i.e. the
           parameter of the action).
        7. Return the reply to the same port where it came from by
           setting the egress_spec field of the standard_metadata
           structure. (Hint: The ingress port is available in the
           ingress_port field of these structure, and it has been set
           at the ParserImpl)
    */
    action arp_reply(mac_addr_t request_mac) {
      //update operation code from request to reply
      hdr.arp.op_code = ARP_REPLY;

      //reply's dst_mac is the request's src mac
      hdr.arp.dst_mac = hdr.arp.src_mac;

      //reply's dst_ip is the request's src ip
      hdr.arp.src_mac = request_mac;

      //reply's src ip is the request's dst ip
      hdr.arp.src_ip = hdr.arp.dst_ip;

      //update ethernet header
      hdr.ethernet.dst_addr = hdr.ethernet.src_addr;
      hdr.ethernet.src_addr = request_mac;

      //send it back to the same port
      standard_metadata.egress_spec = standard_metadata.ingress_port;

    }

    /*
        Exercise 2.1 TO-DO: Define the arp_exact table. This table
        will be composed of a key to match the Target Protocol Address
        field of the ARP header, in exact way. The actions for this
        table will be the arp_reply, and the drop action. The drop
        action will be the default action. Optionally, you might want
        to add a counter to the table to make easier the debugging. You
        can use as example the counter defined for the acl_table.
    */

    table arp_exact {
      key = {
        hdr.arp.dst_ip: exact;
      }
      actions = {
        arp_reply;
        drop;
      }
      size = 1024;
      default_action = drop;
    }


    /*
        Exercise 2.2 TO-DO: Create a table to record the TCP Sessions validated
        by the controller.
        1. The key of this table contains the IP addresses and the TCP ports. 
           These fields must be exactly matched.
        2. This table does not have an action. That is, it must include the special
           NoAction action.
    */
    table tcp_sessions {
    }


    apply {

        if (hdr.cpu_out.isValid()) {
            standard_metadata.egress_spec = hdr.cpu_out.egress_port;
            hdr.cpu_out.setInvalid();
            exit;
        }

        /*
                Exercise 2.0 TO-DO: Modify the apply block according to the
                following algorithm:
                1. If the packet contains valid Ethernet and IPv4 headers,
                   then apply the l2_exact_table which will forward packets
                   according the destination MAC address.
                2. Otherwise, if the packet contains an Ethernet frame,
                   apply the arp_exact table in order to reply ARP requests.
                Hint 1: You might want to comment out the non-conditioned
                application of l2_exact_table.
                Hint 2: For Step 2, you need to check the value of the field
                containing the type of content of the frame.

        */

        /* Exercise 2.2 TO-DO: Process the packets.
           Complete the instructions indicated below.
        */

        if(hdr.tcp.isValid()) {

                // Exercise 2.2 TO-DO: Check if a session was already created. 
                // In case it does, simply forward the packets.
                // Hint 1: A session exists if there is an entry in the tcp_sessions
                //         table that causes a hit.
                // Hint: You can use the l2_exact table, assuming there will be
                //       flow entries so that the switch knows how to process the
                //       traffic
                if(tcp_sessions.<FIX ME>) {
                        session_counter.count(0);
                        <FIX ME>
                } 
                else {

                        // Exercise 2.2 TO-DO: Check if the packet is not a syn and 
                        // it does not belong to an  existng session.
                        // Check also specific cases such syn+fin or syn+rst which are
                        // clearly invalid.
                        // If that is the case, the switch should reply with a RST packet
                        // Hint: remember the values recorded in the local_metadata struct.
                        if(<FIX ME> // Check it is not a SYN
                                || <FIX ME> // Check it is a SYN+FIN
                                || <FIX ME> // Check it is a SYN+RST) {


                                /* 
                                    Exercise 2.2 TO-DO: In case any of the previous condition
                                    is true, make the switch to reply a RST:
                                    1. Remove the TCP header and create a new one.
                                    2. Set the corresponding flags accordingly (SYN, RST, ACK)
                                    3. The TCP sequence may be 1
                                    4. Do an ACK of the SYN packet in the reset
                                    5. Set the Ports, IP addresses and Ethernet Addresses accordingly
                                    6. Finally, set the packet to be replied through the port where
                                       it was received,
                                    Keep in mind, you are replying the RST as generated by the
                                    intended destination host.
                                */
                                standard_metadata.egress_spec = local_metadata.ingress_port;

                                // Count an event of session rejection
                                rejects_counter.count(0);
                        }
                }


        /*
            Exercise 2.2 TO-DO: Process the IP traffic
            Hint: you can use the l2_exact_table assuming you will have the required
                  flow entries.
        */
        } else if (hdr.ethernet.isValid() && hdr.ipv4.isValid()){

          // Finally, check if the packet is an ARP packet and try to replace
          // it with the corresponding table. 
        } else if (hdr.ethernet.ether_type == ETHERTYPE_ARP) {
                arp_exact.apply();
        } else {

             // Otherwise, if the packet does not match anything, mark it to drop it.
             mark_to_drop(standard_metadata);
        }

        // Apply the exact table so that controller takes care
        acl_table.apply();
    }
}


control EgressPipeImpl (inout parsed_headers_t hdr,
                        inout local_metadata_t local_metadata,
                        inout standard_metadata_t standard_metadata) {
    apply {

        if (standard_metadata.egress_port == CPU_PORT) {
            hdr.cpu_in.setValid();
            hdr.cpu_in.ingress_port = local_metadata.ingress_port;
            exit;
        }

    }
}


control ComputeChecksumImpl(inout parsed_headers_t hdr,
                            inout local_metadata_t local_metadata)
{
    apply {

        update_checksum(
            hdr.ipv4.isValid(),
            { 
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.dscp,
                hdr.ipv4.ecn,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr 
            },
            hdr.ipv4.hdr_checksum,
            HashAlgorithm.csum16);

        update_checksum_with_payload(
            hdr.tcp.isValid(),
            { 
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                8w0,
                hdr.ipv4.protocol,
                local_metadata.l4Len,
                hdr.tcp.src_port,
                hdr.tcp.dst_port,
                hdr.tcp.seq_no,
                hdr.tcp.ack_no,
                hdr.tcp.data_offset,
                hdr.tcp.res,
                hdr.tcp.ecn,
                hdr.tcp.urg,
                hdr.tcp.ack,
                hdr.tcp.psh,
                hdr.tcp.rst,
                hdr.tcp.syn,
                hdr.tcp.fin,
                hdr.tcp.window,
                hdr.tcp.urgent_ptr
            },
            hdr.tcp.checksum, HashAlgorithm.csum16);      

    }
}


control DeparserImpl(packet_out packet, in parsed_headers_t hdr) {
    apply {
        packet.emit(hdr.cpu_in);
        packet.emit(hdr.ethernet);
        /*
                Exercise 2.1 TO-DO: Include the ARP header in outgoing packets
                where applicable
        */
        packet.emit(hdr.arp);
        packet.emit(hdr.ipv4);
        /*
                Exercise 2.2 TO-DO: Include the TCP hader in outgoing packets
                where applicable
        */
    }
}


V1Switch(
    ParserImpl(),
    VerifyChecksumImpl(),
    IngressPipeImpl(),
    EgressPipeImpl(),
    ComputeChecksumImpl(),
    DeparserImpl()
) main;
