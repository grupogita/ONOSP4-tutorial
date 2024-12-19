simple_switch_CLI --thrift-port 9090 <<<  "table_add MyIngress.feature1_exact MyIngress.set_actionselect1 0->32 => 1 1";
simple_switch_CLI --thrift-port 9090 <<<  "table_add MyIngress.feature2_exact MyIngress.set_actionselect2 0->11 => 1 1";


simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature2_exact MyIngress.set_actionselect2 0->11 => 1 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature2_exact MyIngress.set_actionselect2 0xc->0x568d => 2 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature2_exact MyIngress.set_actionselect2 0x568e->0x5bd1 => 3 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature2_exact MyIngress.set_actionselect2 0x5bd2->0xa8a6 => 4 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature2_exact MyIngress.set_actionselect2 0xa8a7->0xc30a => 5 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature2_exact MyIngress.set_actionselect2 0xc30b->0xffff => 6 1";

simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature3_exact MyIngress.set_actionselect3 0x0->0x1797 => 1 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature3_exact MyIngress.set_actionselect3 0x1798->0x23b8 => 2 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature3_exact MyIngress.set_actionselect3 0x23b9->0x568d => 3 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.feature3_exact MyIngress.set_actionselect3 0x568e->0xffff => 4 1";



simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.ipv4_exact MyIngress.ipv4_forward 1->1 1->1 1->4 => 0x0a000102 2 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.ipv4_exact MyIngress.ipv4_forward 1->1 2->3 1->1 => 0x0a000102 2 1";
simple_switch_CLI --thrift-port 9090 <<< "table_add MyIngress.ipv4_exact MyIngress.ipv4_forward 1->1 6->6 1->1 => 0x0a000103 3 1";
