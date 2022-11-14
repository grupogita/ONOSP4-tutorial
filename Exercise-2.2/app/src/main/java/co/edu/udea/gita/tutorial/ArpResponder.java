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
import java.lang.Iterable;
import java.util.Iterator;
import org.onosproject.net.flow.FlowEntry;



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

    // Selector for ARP Traffic 
    private final TrafficSelector intercept = DefaultTrafficSelector.builder()
            .matchEthType(Ethernet.TYPE_ARP)
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

    // Processes the intercepted ARP Packet.
    private void processArp(PacketContext context, Ethernet eth) {
        DeviceId deviceId = context.inPacket().receivedFrom().deviceId();
        ARP arpPkt = (ARP) eth.getPayload();
        MacAddress senderMac = MacAddress.valueOf(arpPkt.getSenderHardwareAddress());
        Ip4Address senderIp = Ip4Address.valueOf(arpPkt.getSenderProtocolAddress());
	short operation = arpPkt.getOpCode();


	log.warn("Intercepted packet is " +  arpPkt.toString());

        if (operation == ARP.OP_REQUEST) {
	    recordArp(deviceId, senderMac, senderIp);
        } 
    }

    private void recordArp(DeviceId deviceId, MacAddress senderMac, Ip4Address senderIp) {

            final PiCriterion hostMacCriterion = PiCriterion.builder()
                        .matchExact(PiMatchFieldId.of("hdr.arp.dst_ip"),
                                senderIp.toOctets())
                        .build();

                final PiAction l2UnicastAction = PiAction.builder()
                        .withId(PiActionId.of("IngressPipeImpl.arp_reply"))
                        .withParameter(new PiActionParam(
                                PiActionParamId.of("request_mac"),
                                senderMac.toBytes()))
                        .build();

                final FlowRule rule = Utils.buildFlowRule(
                        deviceId, appId, "IngressPipeImpl.arp_exact", hostMacCriterion, l2UnicastAction);


		log.warn("Rule is " + rule.toString());


		java.lang.Iterable<FlowEntry> listRules = flowRuleService.getFlowEntries(deviceId);
		Iterator<FlowEntry> it = listRules.iterator();
		boolean exists = false;

		while(it.hasNext() && !exists){
			FlowEntry fr = it.next();

			if(fr.exactMatch(rule))
				exists = true;
		}

		if(!exists){
                	// Insert.
                	flowRuleService.applyFlowRules(rule);
		} else {
			log.warn("Rule already exists");
		}

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
