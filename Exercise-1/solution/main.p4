#include <core.p4>
#include <v1model.p4>

#define CPU_PORT 255
#define CPU_CLONE_SESSION_ID 99

typedef bit<9>   port_num_t;
typedef bit<9>   mitm_num_t;
typedef bit<1>   is_mitm_t;
typedef bit<48>  macAddr_t;
typedef bit<32>  ip4Addr_t;
typedef bit<16>  mcast_group_id_t;



const bit<16> ETHERTYPE_IPV4    = 0x0800;


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++ HEADER DEFINITIONS ++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

header ethernet_t {
    macAddr_t  dst_addr;
    macAddr_t  src_addr;
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
    ip4Addr_t src_addr;
    ip4Addr_t dst_addr;
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
    cpu_out_header_t cpu_out;
    cpu_in_header_t cpu_in;
}


struct local_metadata_t {
    is_mitm_t mitm;
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
        transition parse_ipv4;
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

// --- DROP  ------------------------------------------------------------
    action drop() {
        mark_to_drop(standard_metadata);
    }

// --- CPU  ------------------------------------------------------------
    action send_to_cpu() {
        standard_metadata.egress_spec = CPU_PORT;
    }
    
    action clone_to_cpu() {
        clone3(CloneType.I2E, CPU_CLONE_SESSION_ID, { standard_metadata.ingress_port });
    }

// --- ACL TABLE  -------------------------------------------------------

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



// --- l2_exact_table ---------------------------------------------------
    action set_egress_port(port_num_t port_num){
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
    }


// --- APPLY ------------------------------------------------------------

    apply {


        if (hdr.cpu_out.isValid()) {
            standard_metadata.egress_spec = hdr.cpu_out.egress_port;
            hdr.cpu_out.setInvalid();
            exit;
        }
        
        l2_exact_table.apply();
        acl_table.apply();
        
        
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
            hdr.cpu_in.ingress_port = standard_metadata.ingress_port;
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
        packet.emit(hdr.ipv4);
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
