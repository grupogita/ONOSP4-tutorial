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


@Component(immediate = true)
public class ArpResponder {

    private static Logger log = LoggerFactory.getLogger(ArpResponder.class);

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
    private final PacketProcessor packetProcessor = new ArpProcessor();
    private final FlowRuleListener flowListener = new InternalFlowListener();

    // Exercise 2.0 TO-DO: Configure a match for the traffic selector in such
    // a way that it intercepts ARP Packets 
    private final TrafficSelector intercept = DefaultTrafficSelector.builder()
            .matchEthType(<SET ME>)
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

    // Exercise 2.0 TO-DO: process the intercepted ARP packets:
    // 1. Retrieve the ARP Packet from the Ethernet frame payloada
    // 2. Retrieve the physical address of the Sender
    // 3. Retrieve the logical address of the Sender
    // 4. Retrieve the Operation Code of the ARP Packet.
    // 5. For ARP requests, call the recordArp method to create the
    //    corresponding flow rule.
    // Hint: For this exercise, physical addresses are Mac Addresses
    // and logical addresses are IPv4 Addresses. Check the ONOS API
    // documentation to find out the appropriate classes. Check also the
    // prototype of the recordArp() method.
    private void processArp(PacketContext context, Ethernet eth) {

    }

    // The method recordArp creates an entry into the arp_exact table so that the switch
    // can respond ARP requests by itself.
    private void recordArp(DeviceId deviceId, MacAddress senderMac, Ip4Address senderIp) {

	    // Exercise 2.0 TO-DO: Set the fully qualified name of the match field 
	    // of the acl_exact table
	    // Hint: Refer to the P4 program code.
            final PiCriterion hostMacCriterion = PiCriterion.builder()
                        .matchExact(PiMatchFieldId.of("<SET ME>"),
                                senderIp.toOctets())
                        .build();


		// Exercise 2.0 TO-DO: Set the fully qualified names of the
		// action and its parameter which are associated to the corresponding table
                final PiAction l2UnicastAction = PiAction.builder()
                        .withId(PiActionId.of("<SET ME>"))
                        .withParameter(new PiActionParam(
                                PiActionParamId.of("<SET ME>"),
                                senderMac.toBytes()))
                        .build();

		// Exercise 2.0 TO-DO: Finally, set the fully qualified name of the table
                final FlowRule rule = Utils.buildFlowRule(
                        deviceId, appId, "<SET ME>", hostMacCriterion, l2UnicastAction);

                // Insert.
                flowRuleService.applyFlowRules(rule);
    }


    // Intercepts ARP packets
    private class ArpProcessor implements PacketProcessor {
        @Override
        public void process(PacketContext context) {
            Ethernet eth = context.inPacket().parsed();

            if (eth.getEtherType() == Ethernet.TYPE_ARP) {
                processArp(context, eth);
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
