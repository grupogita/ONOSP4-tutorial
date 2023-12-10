curl --fail -sSL --user onos:rocks --noproxy localhost -X POST -H 'Content-Type:application/json' http://localhost:8181/onos/v1/flows?appId=co.edu.udea.gita.p4-tutorial  -d@./flow.json
