package co.edu.udea.gita.tutorial;

import com.google.common.collect.HashMultimap;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Deactivate;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.onlab.packet.Ethernet;
import org.onlab.packet.ARP;
import org.onlab.packet.IPv4;
import org.onlab.packet.TCP;
import org.onlab.packet.Ip4Address;
import org.onlab.packet.MacAddress;
import org.onosproject.core.ApplicationId;
import org.onosproject.core.DefaultApplicationId;
import org.onosproject.core.CoreService;
import org.onosproject.net.DeviceId;
import org.onosproject.net.flow.DefaultTrafficSelector;
import org.onosproject.net.flow.DefaultTrafficTreatment;
import org.onosproject.net.flow.FlowRule;
import org.onosproject.net.flow.FlowRuleEvent;
import org.onosproject.net.flow.FlowRuleListener;
import org.onosproject.net.flow.FlowRuleService;
import org.onosproject.net.flow.TrafficSelector;
import org.onosproject.net.flow.TrafficTreatment;
import org.onosproject.net.flow.criteria.Criterion;
import org.onosproject.net.flow.criteria.EthCriterion;
import org.onosproject.net.flowobjective.DefaultForwardingObjective;
import org.onosproject.net.flowobjective.FlowObjectiveService;
import org.onosproject.net.flowobjective.ForwardingObjective;
import org.onosproject.net.packet.PacketContext;
import org.onosproject.net.packet.PacketPriority;
import org.onosproject.net.packet.PacketProcessor;
import org.onosproject.net.packet.PacketService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Objects;
import java.util.Optional;
import java.util.Timer;
import java.util.TimerTask;

import static org.onosproject.net.flow.FlowRuleEvent.Type.RULE_REMOVED;
import static org.onosproject.net.flow.criteria.Criterion.Type.ETH_SRC;
import co.edu.udea.gita.tutorial.common.Utils;
import org.onosproject.net.flow.criteria.PiCriterion;
import org.onosproject.net.pi.model.PiActionId;
import org.onosproject.net.pi.model.PiActionParamId;
import org.onosproject.net.pi.model.PiMatchFieldId;
import org.onosproject.net.pi.runtime.PiAction;
import org.onosproject.net.pi.runtime.PiActionParam;


import java.lang.Iterable;
import java.util.Iterator;
import org.onosproject.net.flow.FlowEntry;



@Component(immediate = true)
public class TCPSessionManager {

    private static Logger log = LoggerFactory.getLogger(TCPSessionManager.class);

    private static final int PRIORITY = 128;
    private static final int DROP_PRIORITY = 129;
    private static final int TIMEOUT_SEC = 60; // seconds

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected CoreService coreService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected FlowObjectiveService flowObjectiveService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected FlowRuleService flowRuleService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected PacketService packetService;

    private ApplicationId appId;
    private final PacketProcessor packetProcessor = new TCPSessionProcessor();
    private final FlowRuleListener flowListener = new InternalFlowListener();

    /* 
        Exercise 2.2 TO:DO: Configure the Selector for TCP Traffic: 
        Packet must be IP and must contain a TCP packet.
        Hint: Check the ONOS javadoc of the org.onlab.packet.* package
    */ 
    private final TrafficSelector intercept = DefaultTrafficSelector.builder()
            .matchEthType(<FIX ME>)
            .matchIPProtocol(<FIX ME>)
            .build();

    @Activate
    public void activate() {
        appId = coreService.registerApplication("co.edu.udea.gita.p4-tutorial",
                                                () -> log.info("Registered."));
        packetService.addProcessor(packetProcessor, PRIORITY);
        flowRuleService.addListener(flowListener);
        packetService.requestPackets(intercept, PacketPriority.CONTROL, appId,
                                     Optional.empty());
        log.info("Started");
    }

    @Deactivate
    public void deactivate() {
        packetService.removeProcessor(packetProcessor);
        flowRuleService.removeFlowRulesById(appId);
        flowRuleService.removeListener(flowListener);
        log.info("Stopped");
    }

    // Processes the intercepted TCP SYN Packet.
    private void processTCPSyn(PacketContext context, Ethernet eth) {

        // Gets the deviceId from the Incoming PACKET_IN
        DeviceId deviceId = context.inPacket().receivedFrom().deviceId();

        // Exercise 2.2 TO-DO: 
        // Get the IPv4 packet form the Ethernet Frame Payload

        // Exercise 2.2 TO-DO:
        // Get the TCP segment from the IP Datagram Payload

        // Exercise 2.2 TO-DO:
        // Read the Source Address and Destination address from the IP Datagram

        // Exercise 2.2 TO-DO:
        // Read the Source Port and Destination Port from the TCP segment

        // Calls the recortTCPSession() method to create the flow rules
        recordTCPSession(deviceId, senderIp, destinationIp, sourcePort, destinationPort);
    }

    private void recordTCPSession(DeviceId deviceId, Ip4Address senderIp, 
                    Ip4Address destinationIp, int sourcePort, int destinationPort) {


            // Exercise 2.2 TO-DO: 
            // Creates the match criterion of the flow rule by
            // setting values for the table fields
            final PiCriterion tcpSession = PiCriterion.builder()
                        .matchExact(PiMatchFieldId.of("<FIX ME>"),
                                senderIp.toOctets())
                        .matchExact(PiMatchFieldId.of("<FIX ME>"),
                                sourcePort)
                        .matchExact(PiMatchFieldId.of("<FIX ME>"),
                                destinationIp.toOctets())
                        .matchExact(PiMatchFieldId.of("<FIX ME>"),
                                destinationPort)
                        .build();

                // Exercise 2.2 TO-DO;
                // Set the action for the corresponding entry
                // Hint: Take a look on the definition of the corresponding table
                // in the P4 program of your switch
                final PiAction tcpNoAction = PiAction.builder()
                        .withId(PiActionId.of("<FIX ME>"))
                        .build();

                // Exercise 2.2 TO-DO: Creates the forward Rule by indicating the i
                // fully qualified name of table, the match
                // fields and the action
                // Hint: Take a look on the definitions provided in the P4 program of
                // your switch
                final FlowRule rule = Utils.buildFlowRule(
                        deviceId, appId, "<FIX ME>", tcpSession, tcpNoAction);


                // Exercise 2.2 TO-DO: Do the same steps of the previous lines
                // but considering to create the backward traffic rule
                final PiCriterion tcpSessionRev = PiCriterion.builder()
                        .matchExact(PiMatchFieldId.of("<FIX ME>"),
                                senderIp.toOctets())
                        .matchExact(PiMatchFieldId.of("<FIX ME>"),
                                sourcePort)
                        .matchExact(PiMatchFieldId.of("<FIX ME>"),
                                destinationIp.toOctets())
                        .matchExact(PiMatchFieldId.of("<FIX ME>"),
                                destinationPort)
                        .build();

                final PiAction tcpNoActionRev = PiAction.builder()
                        .withId(PiActionId.of("NoAction"))
                        .build();

                final FlowRule ruleRev = Utils.buildFlowRule(
                        deviceId, appId, "<FIX ME>", tcpSessionRev, tcpNoActionRev);


                log.warn("*************************************************************");
                log.warn("Rule 1: " + rule.toString());
                log.warn("Rule 2: " + ruleRev.toString());



                // This is performed in order to avoid unnecesary flow rule
                // insertions. We get the flows already inserted and we check
                // whether the rule already exists. If it does, we skip the
                // insertion. Otherwise, we perform the insertion
                java.lang.Iterable<FlowEntry> listRules = flowRuleService.getFlowEntries(deviceId);
                Iterator<FlowEntry> it = listRules.iterator();
                boolean exists = false;

                while(it.hasNext() && !exists){
                        FlowEntry fr = it.next();

                        if(fr.exactMatch(rule) || fr.exactMatch(ruleRev))
                                exists = true;
                }

                if(!exists){
                        // Insert.
                        flowRuleService.applyFlowRules(rule);
                        flowRuleService.applyFlowRules(ruleRev);
                } else {
                        log.warn("One of the rules already exists");
                }

                // Insert.<F2>
    }


    // Intercepts TCP packets
    private class TCPSessionProcessor implements PacketProcessor {
        @Override
        public void process(PacketContext context) {


            Ethernet eth = context.inPacket().parsed();

            // Exercise 2.2 TO-DO: We check whether it is a frame containing an IP Datagram
            // containing a TCP Segment. If it is, we read it to check if the SYN flag is set.
            // Hint: Check the ONOS javadoc of the org.onlab.packet.* package
            if(eth.getEtherType() == <FIX ME> && <FIX ME> == IPv4.PROTOCOL_TCP){
                    IPv4 ipPkt = <FIX ME>;
                    TCP tcpPkt = <FIX ME>;

                    if (tcpPkt.getFlags() == <FIX ME>) {
                        processTCPSyn(context, eth);
                    }
            }
        }
    }

    // Listens for our removed flows.
    private class InternalFlowListener implements FlowRuleListener {
        @Override
        public void event(FlowRuleEvent event) {
            FlowRule flowRule = event.subject();
        }
    }
}
