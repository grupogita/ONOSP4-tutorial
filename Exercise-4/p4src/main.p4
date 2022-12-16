#include <core.p4>
#include <v1model.p4>

#define CPU_PORT 255
#define CPU_CLONE_SESSION_ID 99

typedef bit<9>   port_num_t;
typedef bit<48>  mac_addr_t;
typedef bit<32>  ipv4_addr_t;

const bit<16> ETHERTYPE_IPV4    = 0x0800;
const bit<16> ETHERTYPE_VLAN    = 0x8100;

const bit<12> VLAN_10 = 0x00a;  //VLAN ID. Must be in hexadecimal
const bit<12> VLAN_20 = 0x014; //VLAN ID. Must be in hexadecimal

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++ HEADER DEFINITIONS ++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

header ethernet_t {
        mac_addr_t  dst_addr;
        mac_addr_t  src_addr;
        bit<16>    ether_type;
}

header ipv4_t {
        bit<4>    version;
        bit<4>    ihl;
        bit<6>    dscp;
        bit<2>    ecn;
        bit<16>   total_len;
        bit<16>   identification;
        bit<3>    flags;
        bit<13>   frag_offset;
        bit<8>    ttl;
        bit<8>    protocol;
        bit<16>   hdr_checksum;
        ipv4_addr_t src_addr;
        ipv4_addr_t dst_addr;
}

header vlan_802_1q_t {
        bit<3>  pri;
        bit<1>  cfi;
        bit<12> vid;
	bit<16> ether_type;
}

@controller_header("packet_in")
header cpu_in_header_t {
        port_num_t  ingress_port;
        bit<7>      _pad;
}

@controller_header("packet_out")
header cpu_out_header_t {
        port_num_t  egress_port;
        bit<7>      _pad;
}

struct parsed_headers_t {
        ethernet_t ethernet;
        ipv4_t ipv4;
        vlan_802_1q_t vlan_802_1q;
        cpu_out_header_t cpu_out;
        cpu_in_header_t cpu_in;
}


struct local_metadata_t {
        bit<9>    port1;
        bit<9>    port2;
}


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++ PARSER ++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


parser ParserImpl (packet_in packet,
                   out parsed_headers_t hdr,
                   inout local_metadata_t local_metadata,
                   inout standard_metadata_t standard_metadata){

        state start {
                transition select(standard_metadata.ingress_port) {
                        CPU_PORT: parse_packet_out;
                        default: parse_ethernet;
                }
        }       

        state parse_packet_out {
                packet.extract(hdr.cpu_out);
                transition parse_ethernet;
        }

        state parse_ethernet {
                packet.extract(hdr.ethernet);
                transition select(hdr.ethernet.ether_type){
                        ETHERTYPE_IPV4: parse_ipv4;
                        ETHERTYPE_VLAN: parse_vlan;
                        default: parse_ipv4;
                }
        }
        
        state parse_vlan {
                packet.extract(hdr.vlan_802_1q);
                transition select(hdr.vlan_802_1q.ether_type){
                        ETHERTYPE_IPV4: parse_ipv4;
                        default: accept;
                }
        }

        state parse_ipv4 {
                packet.extract(hdr.ipv4);
                transition accept;
        }
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++ CHECKSUM +++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

control VerifyChecksumImpl(inout parsed_headers_t hdr,
                           inout local_metadata_t local_metadata){

        apply { /* EMPTY */ }
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++ INGRESS PROCESSING ++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

control IngressPipeImpl(inout parsed_headers_t    hdr,
                        inout local_metadata_t    local_metadata,
                        inout standard_metadata_t standard_metadata){

        // --- DROP  -----------------------------------------------------------
        action drop() {
                mark_to_drop(standard_metadata);
        }

        // --- CPU  ------------------------------------------------------------
        action send_to_cpu() {
                standard_metadata.egress_spec = CPU_PORT;
        }

        action clone_to_cpu() {
                clone3(CloneType.I2E, CPU_CLONE_SESSION_ID, {
                        standard_metadata.ingress_port });
        }

        // --- ACL TABLE  ------------------------------------------------------

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


        // --- l2_exact_table --------------------------------------------------

        //Set the egress port after removing the vlan header to send the packet to the end host
        action set_egress_port(port_num_t port_num){
                standard_metadata.egress_spec = port_num;
        }

        //Checks the vlan header with the vlan id to set the packet forwarding
        table extract_vlan_tag {
                key = {
                        hdr.ethernet.dst_addr: exact; //destination mac address
                        hdr.vlan_802_1q.vid: exact; // vlan id
                }
                actions = {
                        set_egress_port; //packet forwarding
                        @defaultonly drop;
                }
        }

        action add_vlan_tag(port_num_t port_num){

                //Sets the vlan header valid to be included in the packet
                hdr.vlan_802_1q.setValid();
                //Assigns a vlan id to the field according to the indress port of the packet
                if (standard_metadata.ingress_port == 1){
                        hdr.vlan_802_1q.vid = VLAN_10;
                }else if (standard_metadata.ingress_port == 2){
                        hdr.vlan_802_1q.vid = VLAN_20;
                }
                hdr.vlan_802_1q.pri = 0; //Priority code point field
                hdr.vlan_802_1q.cfi = 0; //Drop eligible indicator field
                hdr.vlan_802_1q.ether_type = hdr.ethernet.ether_type; //Sets the ethertype from the ethernet frame to the ethertype filed inside the vlan header
                hdr.ethernet.ether_type = ETHERTYPE_VLAN; //Sets the ethernet ethertype with the vlan TPID 0x8100
                
                standard_metadata.egress_spec = port_num; //egress port
        }

        //Includes the vlan header in the packet
        table set_vlan_tag {
                key = {
                        hdr.ethernet.src_addr: exact;
                }
                actions = {
                        add_vlan_tag; //Includes the vlan header
                }
        }

        // --- APPLY -----------------------------------------------------------

        apply {

                if (hdr.cpu_out.isValid()) {
                        standard_metadata.egress_spec = hdr.cpu_out.egress_port;
                        hdr.cpu_out.setInvalid();
                        exit;
                }
                acl_table.apply();
        
                //Checks if the packet includes the vlan header
                if (hdr.ethernet.ether_type == ETHERTYPE_IPV4){
                        set_vlan_tag.apply(); //Includes the vlan header in the packet
                } else if (hdr.ethernet.ether_type == ETHERTYPE_VLAN) {
                        extract_vlan_tag.apply(); //Extracts the vlan tag and reads the vlan id to forward the packet
                        hdr.ethernet.ether_type = hdr.vlan_802_1q.ether_type; //Sets the ethertype from the vlan header to the ethertype in the ethernet frame 
                        hdr.vlan_802_1q.setInvalid(); //Removes the vlan header
                }else{
                        mark_to_drop(standard_metadata);
                }
        }
}


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++ EGRESS PROCESSING ++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


control EgressPipeImpl (inout parsed_headers_t hdr,
                        inout local_metadata_t local_metadata,
                        inout standard_metadata_t standard_metadata){


        // --- APPLY ---------------------------------------------------

        apply {

                if (standard_metadata.egress_port == CPU_PORT) {
                        hdr.cpu_in.setValid();
                        hdr.cpu_in.ingress_port=standard_metadata.ingress_port;
                        exit;
                }
        }

}


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++ CHECKSUM +++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


control ComputeChecksumImpl(inout parsed_headers_t hdr,
                            inout local_metadata_t local_metadata) {
        apply { /* EMPTY */ }
}


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++ DEPARSER +++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


control DeparserImpl(packet_out packet, in parsed_headers_t hdr) {
        apply {
                packet.emit(hdr.cpu_in);
                packet.emit(hdr.ethernet);
		packet.emit(hdr.vlan_802_1q);  //Include header vlan. Might be a TO DO?
                packet.emit(hdr.ipv4); //Include header ipv4
        }
}


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++ SWITCH ++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


V1Switch(
        ParserImpl(),
        VerifyChecksumImpl(),
        IngressPipeImpl(),
        EgressPipeImpl(),
        ComputeChecksumImpl(),
        DeparserImpl()
) main;
