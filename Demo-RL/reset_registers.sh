# This script calls the register_reset command of the Switch S1 to clear the registers
# It is called after applying an address blocking action.
simple_switch_CLI --thrift-port 9090 <<< 'register_reset MyIngress.synReg'> /dev/null
simple_switch_CLI --thrift-port 9090 <<< 'register_reset MyIngress.synAckRstReg'> /dev/null
simple_switch_CLI --thrift-port 9090 <<< 'register_reset MyEgress.synReg'> /dev/null
simple_switch_CLI --thrift-port 9090 <<< 'register_reset MyEgress.synAckRstReg'> /dev/null

