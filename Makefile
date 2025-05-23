KEY_STORE = ./starkli-wallet/keystore.json
ACCOUNT = ./starkli-wallet/account.json

ADMIN_ADDRESS = 0x0648c244af89e8254aab9da7a4f61a1412eb6c1bb257d8739fa0c82cbb260f40

RESERVOIR_ADDRESS = 0x06c301bcc487b175b559fa93d5e428506a9d53f52152a8f59449762ca56dd1d5
RESERVOIR_CLASS_HASH = 0x04a58899301ab6d93e8c5ada27a3f77e32556ea0e1f50be5b3eada3e66589927

CONTRIBUTOR_HUB_ADDRESS = 0x071d3c3bae12f992dbc3dda582d7f597d6f617bd567c217575cb7be21e51130a
CONTRIBUTOR_HUB_CLASS_HASH = 0x02323347d434f2546b4dc1966a7bc3c6b72430c22b88ef32ad8e84a71a1dbaab

COLLECTOR_ADDRESS = 0x072032fab9135306fd48b38c3be22532a9b8ae786897329e0cece34ab12db00c
COLLECTOR_CLASS_HASH = 0x06059d3cadf49aa1728b6ef02bd1ffb946604aa9e4285902b5d9fb2e80aa4ec9

PROVIDER_ADDRESS = 0x06228386dcba7494effd28d088d20b2ad69a1ea67cb3f3d94c736ba981bf4190
PROVIDER_CLASS_HASH = 0x06c49a3f7d07b3493f9cdd91196ca75a85915878a4845b85947b32fd48414765

FEE_COLLECTOR_ADDRESS = 0x06b45742dc433ac5f1f6cea4b5374ae3f6d208f3d5f63102f517acefa0e3934f
FEE_COLLECTOR_CLASS_HASH = 0x07938878f5e1ca30d60b0536aab48d18ac77903def029609be2ab3f3206e096c

ETH_GASTOKEN = 0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7

RPC_URL = https://starknet-sepolia.public.blastapi.io/rpc/v0_7

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

# === RESERVOIR ===
.PHONY: declare-reservoir
declare-reservoir:
	starkli declare \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  --watch ./target/dev/core_v0_EntropyReservoir.contract_class.json

.PHONY: deploy-reservoir
deploy-reservoir:
	starkli deploy \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(RESERVOIR_CLASS_HASH) \
	  $(ADMIN_ADDRESS)

.PHONY: reservoir-set-collector
reservoir-set-collector:
	starkli invoke \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(RESERVOIR_ADDRESS) \
	  set_collector \
	  $(COLLECTOR_ADDRESS)

.PHONY: reservoir-set-provider
reservoir-set-provider:
	starkli invoke \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(RESERVOIR_ADDRESS) \
	  set_provider \
	  $(PROVIDER_ADDRESS)
# === RESERVOIR ===

# === COLLECTOR ===
.PHONY: declare-collector
declare-collector:
	starkli declare \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  --watch ./target/dev/core_v0_Collector.contract_class.json

.PHONY: deploy-collector
deploy-collector:
	starkli deploy \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(COLLECTOR_CLASS_HASH) \
	  $(ADMIN_ADDRESS) $(CONTRIBUTOR_HUB_ADDRESS)

.PHONY: collector-set-reservoir
collector-set-reservoir:
	starkli invoke \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(COLLECTOR_ADDRESS) \
	  set_reservoir \
	  $(RESERVOIR_ADDRESS)

.PHONY: collector-set-contributors-hub
collector-set-contributors-hub:
	starkli invoke \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(COLLECTOR_ADDRESS) \
	  set_contributors_hub \
	  $(CONTRIBUTOR_HUB_ADDRESS)
# === COLLECTOR ===

.PHONY: declare-fee-collector
declare-fee-collector:
	starkli declare \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  --watch ./target/dev/core_v0_FeeCollector.contract_class.json

.PHONY: deploy-fee-collector
deploy-fee-collector:
	starkli deploy \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(FEE_COLLECTOR_CLASS_HASH) \
	  $(ETH_GASTOKEN) $(ADMIN_ADDRESS)


# === PROVIDER ===
.PHONY: declare-provider
declare-provider:
	starkli declare \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  --watch ./target/dev/core_v0_RandomProvider.contract_class.json

.PHONY: deploy-provider
deploy-provider:
	starkli deploy \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(PROVIDER_CLASS_HASH) \
	  $(ADMIN_ADDRESS)

.PHONY: provider-set-reservoir
provider-set-reservoir:
	starkli invoke \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(PROVIDER_ADDRESS) \
	  set_reservoir \
	  $(RESERVOIR_ADDRESS)

.PHONY: provider-set-fee-collector
provider-set-fee-collector:
	starkli invoke \
	  --rpc $(RPC_URL) \
	  --keystore $(KEY_STORE) \
	  --account $(ACCOUNT) \
	  $(PROVIDER_ADDRESS) \
	  set_fee_collector \
	  $(FEE_COLLECTOR_ADDRESS)
# === PROVIDER ===
