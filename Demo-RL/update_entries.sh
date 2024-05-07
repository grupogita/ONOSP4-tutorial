# This script changes the value of the enable field of the block action in
# the firewall table of S1
# The parameters are passed from the q_table script
simple_switch_CLI --thrift-port 9090 <<< "table_modify MyIngress.firewall block $1 => $2"  > /dev/null
