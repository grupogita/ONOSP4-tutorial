// This file is part of the Planter extend project: QCMP.
// This program is a free software tool, which does ensemble in-network reinforcement learning for load balancing.
// licensed under Apache-2.0
// Copyright (c) 2022-2023 Benjamin Rienecker Modified by Changgang Zheng
// Copyright (c) Computing Infrastructure Group, Department of Engineering Science, University of Oxford

/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<5>  IPV4_OPTION_MRI = 31;
const bit<16> TYPE_IPV4 = 0x800;

#define MAX_HOPS 9

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<32> myCounter;
typedef bit<32> myCounter2;

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header ipv4_option_t {
    bit<1> copyFlag;
    bit<2> optClass;
    bit<5> option;
    bit<8> optionLength;
}

header mri_t {
    bit<16>  count;
}

header switch_t {
    myCounter  swid;
    myCounter2    synCnt;
    myCounter2    synAckCnt;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct metadata {
    bit<14>  ecmp_select;
    bit<16>  count;
    bit<16>  remaining;
    bit<32>  cntSyn;
    bit<32>  cntSynAck;
    bit<32>  cntSynAckRst;
    bit<1>   toBlock;
}

struct headers {
    ethernet_t              ethernet;
    ipv4_t                  ipv4;
    ipv4_option_t           ipv4_option;
    mri_t                   mri;
    switch_t[MAX_HOPS]      swtraces;
    tcp_t                   tcp;
}

error { IPHeaderTooShort }

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);

	// This is an example of an assertion
        verify(hdr.ipv4.ihl >= 5, error.IPHeaderTooShort);
        transition select(hdr.ipv4.ihl) {
            5             : parse_tcp;
            default       : parse_ipv4_option;
        }
    }

    state parse_ipv4_option {
        packet.extract(hdr.ipv4_option);
        transition select(hdr.ipv4_option.option) {
            IPV4_OPTION_MRI: parse_mri;
            default: accept;
        }
    }

  state parse_mri {
      packet.extract(hdr.mri);
      meta.remaining = hdr.mri.count;
      transition select(meta.remaining) {
          0 : parse_tcp;
          default: parse_swtrace;
      }
  }

  state parse_swtrace {
      packet.extract(hdr.swtraces.next);
      meta.remaining = meta.remaining  - 1;
      transition select(meta.remaining) {
          0 : parse_tcp;
          default: parse_swtrace;
      }
  }

  state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {


    register<bit<32>>(2) synReg;
    register<bit<32>>(2) synAckRstReg;

    action drop() {
        mark_to_drop(standard_metadata);
    }


    action block(bit<1> enabled){
	meta.toBlock = enabled;
    }


    action update_ttl(){
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }


    action forward(bit<9> port, bit<48>dstMac) {

		/* Force the destination address to be broadcast,
	   	so that other switches can accept and process
	   	the frame.
		*/
		hdr.ethernet.dstAddr = dstMac;
		standard_metadata.egress_spec = port;
    }


    table firewall {

	key = {
		hdr.ipv4.srcAddr: lpm;
	}

	actions = {
		block;
	}
    }


    table ip_forward{

	key={
		hdr.ipv4.dstAddr: exact;

	}
	actions={
		forward;
		drop;
	}
    }


    table debug_flow {
	key = {
		hdr.tcp.syn: exact;
		hdr.tcp.ack: exact;
		hdr.tcp.rst: exact;
		hdr.tcp.fin: exact;
		standard_metadata.egress_spec: exact;
        }
	actions = {


	}
    }
	


    apply {

	    firewall.apply();

	    if(meta.toBlock == 1) {

			mark_to_drop(standard_metadata);


	    } else {
	            if (hdr.ipv4.isValid()){
	                update_ttl();

					ip_forward.apply();
	            }

		    if(hdr.tcp.isValid()){
		    // Syn Packet
			    if (hdr.tcp.syn == 1) {
				synReg.read(meta.cntSyn, (bit<32>)1);
				meta.cntSyn = meta.cntSyn + 1;
				synReg.write((bit<32>)1, meta.cntSyn);
			    } else {

				debug_flow.apply();

					if(
						(hdr.tcp.syn == 1 && hdr.tcp.ack == 1) || 
						(hdr.tcp.ack == 1 && hdr.tcp.rst == 1) || 
						hdr.tcp.ack == 1
					) {
						synAckRstReg.read(meta.cntSynAckRst, (bit<32>)1);
						meta.cntSynAckRst = meta.cntSynAckRst + 1;
						synAckRstReg.write((bit<32>)1, meta.cntSynAckRst);
					}
			    }
		        }
		}
	}

}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    register<bit<32>>(2) synReg;
    register<bit<32>>(2) synAckRstReg;

    action add_swtrace(myCounter swid) {
	log_msg("At add_swtrace");
        hdr.mri.count = hdr.mri.count + 1;
        hdr.swtraces.push_front(1);
        // According to the P4_16 spec, pushed elements are invalid, so we need
        // to call setValid(). Older bmv2 versions would mark the new header(s)
        // valid automatically (P4_14 behavior), but starting with version 1.11,
        // bmv2 conforms with the P4_16 spec.
        hdr.swtraces[0].setValid();
        hdr.swtraces[0].swid = swid;

	synReg.read(meta.cntSyn, (bit<32>)1);
	synAckRstReg.read(meta.cntSynAckRst, (bit<32>)1);
        hdr.swtraces[0].synCnt = meta.cntSyn;
	hdr.swtraces[0].synAckCnt = meta.cntSynAckRst;

        hdr.ipv4.ihl = hdr.ipv4.ihl + 3;
        hdr.ipv4_option.optionLength = hdr.ipv4_option.optionLength + 12;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + 12;
    }

    action update_ttl(){
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }


    action forward(bit<9> port, bit<48>dstMac) {

        hdr.ethernet.dstAddr = dstMac;
        standard_metadata.egress_spec = port;
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    table debug_flow {
        key = { 
                meta.cntSyn: exact;
                meta.cntSynAckRst: exact;
                hdr.swtraces[0].swid: exact;
		hdr.mri.count: exact;
        }
        actions = {


        }
    }




    table ip_forward{


        key={   
                hdr.ipv4.dstAddr: exact;
        
        }
        actions={
                forward;
                drop;
        }
    }

    table swtrace {
        actions = {
            add_swtrace;
            NoAction;
        }
        default_action = NoAction();
    }

    apply {

            // Syn Packet

	    if(hdr.tcp.isValid()) {
	            if (hdr.tcp.syn == 1) {
       		        synReg.read(meta.cntSyn, (bit<32>)1);
                	meta.cntSyn = meta.cntSyn + 1;
                	synReg.write((bit<32>)1, meta.cntSyn);
            	    } else {

                	if((hdr.tcp.syn == 1 && hdr.tcp.ack == 1) || (hdr.tcp.ack == 1 && hdr.tcp.rst == 1) || hdr.tcp.ack == 1) {
                        	synAckRstReg.read(meta.cntSynAckRst, (bit<32>)1);
                        	meta.cntSynAckRst = meta.cntSynAckRst + 1;
                        	synAckRstReg.write((bit<32>)1, meta.cntSynAckRst);
                	}
            	    }
	     }

	debug_flow.apply();

        if (hdr.mri.isValid()) {
            swtrace.apply();
        }
        ip_forward.apply();
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
        update_checksum(
            hdr.ipv4.isValid(),
            { hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv4_option);
        packet.emit(hdr.mri);
        packet.emit(hdr.swtraces);
        packet.emit(hdr.tcp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
