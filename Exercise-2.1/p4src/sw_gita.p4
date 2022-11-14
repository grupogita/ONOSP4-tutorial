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
const bit<16> ETHERTYPE_IPV4 = <SET ME>;
const bit<16> ETHERTYPE_ARP = <SET ME>;

/*
    Exercise 2.1 TO-DO: Define symbolic constants for different ARP fields.
    Refer to RFC 826 for the sizes and reference values.
*/
//const bit<16> ARP_HTYPE = <SET ME>; //Ethernet Hardware
//const bit<16> ARP_PTYPE = <SET ME>; //Protocol used for ARP
//const bit<8>  ARP_HLEN  = <SET ME>; //Ethernet address size
//const bit<8>  ARP_PLEN  = <SET ME>; //IP address size
//const bit<16> ARP_REQ = <SET ME>; //Operation Code for Request
//const bit<16> ARP_REPLY = <SET ME>; //Operation Code for Reply



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
/*
header arp_t {

}
*/


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
    headers recognized by this switch
*/

    ipv4_t ipv4;
}

struct local_metadata_t {
	@field_list(1)
	port_num_t ingress_port;
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
	transition parse_ipv4;
        }
    }

        /*
                Exercise 2.1 TO-DO: Define the parse_arp state which should
                perform the following two things:
                1. Extract the arp header from the packet
                2. Create a transition selection based on the ARP Operation
                   code in such a way that only ARP requestes get accepted
        */

/*
        state parse_arp {

                }
        }
*/


    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            default: accept;
        }
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

/*
        action arp_reply(mac_addr_t request_mac) {

	}
*/



        /*
                Exercise 2.1 TO-DO: Define the arp_exact table. This table
                will be composed of a key to match the Target Protocol Address
                field of the ARP header, in exact way. The actions for this
                table will be the arp_reply, and the drop action. The drop
                action will be the default action. Optionally, you might want
                to add a counter to the table to make easier the debugging. You
                can use as example the counter defined for the acl_table.
        */

/*
        table arp_exact {
                key = {

                }
                actions = {
                }
                size = 1024;
                default_action = drop;
        }
*/

                                                   

    apply {

        if (hdr.cpu_out.isValid()) {
            standard_metadata.egress_spec = hdr.cpu_out.egress_port;
            hdr.cpu_out.setInvalid();
            exit;
        }

        /*
                Exercise 2.1 TO-DO: Modify the apply block according to the
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

        packet.emit(hdr.ipv4);
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
