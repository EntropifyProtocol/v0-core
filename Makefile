KEY_STORE = ./starkli-wallet/keystore.json
ACCOUNT = ./starkli-wallet/account.json

ADMIN_ADDRESS = 0x0648c244af89e8254aab9da7a4f61a1412eb6c1bb257d8739fa0c82cbb260f40

RESERVOIR_ADDRESS = 0x07d18ef7b60b94036bcbc3b354ff977aad1c8f3bed0a87a8cb4f459d2d9d2998
RESERVOIR_CLASS_HASH = 0x02442afa06826598a5db0a9078c28fe82403284e6846fcbe7f294c6f986dc506

CONTRIBUTOR_HUB_ADDRESS = 0x071d3c3bae12f992dbc3dda582d7f597d6f617bd567c217575cb7be21e51130a
CONTRIBUTOR_HUB_CLASS_HASH = 0x02323347d434f2546b4dc1966a7bc3c6b72430c22b88ef32ad8e84a71a1dbaab

COLLECTOR_ADDRESS = 0x07d4457560a5f2d0c219d779ec7929f73ee02cfc9ff089f13536519711de4759
COLLECTOR_CLASS_HASH = 0x012fa6984298362ad815add3cd5eb454f45601ed25635748b68c8c8082924c11

PROVIDER_ADDRESS = 0x0648c244af89e8254aab9da7a4f61a1412eb6c1bb257d8739fa0c82cbb260f40
PROVIDER_CLASS_HASH = 0x0648c244af89e8254aab9da7a4f61a1412eb6c1bb257d8739fa0c82cbb260f40


.PHONY: build
build:
	scarb build

.PHONY: declare-contributor-hub
declare-contributor-hub:
	starkli declare \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  --watch ./target/dev/core_v0_ContributorHub.contract_class.json

.PHONY: deploy-contributor-hub
deploy-contributor-hub:
	starkli deploy \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(CONTRIBUTOR_HUB_CLASS_HASH) \
	  $(ADMIN_ADDRESS)

.PHONY: declare-reservoir
declare-reservoir:
	starkli declare \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  --watch ./target/dev/core_v0_Reservoir.contract_class.json

.PHONY: deploy-reservoir
deploy-reservoir:
	starkli deploy \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(RESERVOIR_CLASS_HASH) \
	  $(ADMIN_ADDRESS)

.PHONY: declare-collector
declare-collector:
	starkli declare \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  --watch ./target/dev/core_v0_Collector.contract_class.json

.PHONY: deploy-collector
deploy-collector:
	starkli deploy \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(COLLECTOR_CLASS_HASH) \
	  $(ADMIN_ADDRESS) $(CONTRIBUTOR_HUB_ADDRESS)
