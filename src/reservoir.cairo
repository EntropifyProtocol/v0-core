use starknet::ContractAddress;

#[starknet::interface]
pub trait IEntropyReservoir<TContractState> {
    fn put(ref self: TContractState, entropy: u256);
    fn get(ref self: TContractState) -> u256;

    fn get_count(self: @TContractState) -> u64;

    fn set_collector(ref self: TContractState, new_collector: ContractAddress);
    fn set_provider(ref self: TContractState, new_provider: ContractAddress);
}

#[starknet::contract]
mod EntropyReservoir {
    use starknet::storage::{
        Map,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerWriteAccess,
        StoragePointerReadAccess,
    };

    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        collector: ContractAddress,
        provider: ContractAddress,
        reservoir: Map<u64, u256>,
        next_index: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl EntropyReservoirImpl of super::IEntropyReservoir<ContractState> {
        fn put(ref self: ContractState, entropy: u256) {
            self.only_collector();

            let next_index = self.next_index.read();
            self.reservoir.write(next_index, entropy);
            self.next_index.write(next_index + 1);
        }

        fn get(ref self: ContractState) -> u256 {
            self.only_provider();

            let next_index = self.next_index.read();
            assert(next_index > 0, 'EMPTY_RESERVOIR');

            let last_saved_index = next_index - 1;
            let entropy = self.reservoir.read(last_saved_index);

            self.reservoir.write(last_saved_index, 0);
            self.next_index.write(last_saved_index);

            entropy
        }

        fn get_count(self: @ContractState) -> u64 {
            self.next_index.read()
        }

        fn set_collector(ref self: ContractState, new_collector: ContractAddress) {
            self.only_owner();
            self.collector.write(new_collector);
        }

        fn set_provider(ref self: ContractState, new_provider: ContractAddress) {
            self.only_owner();
            self.provider.write(new_provider);
        }
    }

    #[generate_trait]
    impl PrivateFunctions of PrivateFunctionsTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'ONLY_OWNER');
        }

        fn only_collector(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.collector.read(), 'ONLY_COLLECTOR');
        }

        fn only_provider(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.provider.read(), 'ONLY_PROVIDER');
        }
    }
}