use starknet::ContractAddress;

#[starknet::interface]
pub trait IRandomProvider<TContractState> {
    fn rand(ref self: TContractState, amount: u256) -> u256;

    fn set_reservoir(ref self: TContractState, new_reservoir: ContractAddress);
    fn set_fee_collector(ref self: TContractState, new_fee_collector: ContractAddress);
}

#[starknet::contract]
mod RandomProvider {
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};
    use core_v0::reservoir::{IEntropyReservoirDispatcher, IEntropyReservoirDispatcherTrait};
    use core_v0::fee_collector::{IFeeCollectorDispatcher, IFeeCollectorDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        reservoir: IEntropyReservoirDispatcher,
        fee_collector: IFeeCollectorDispatcher,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl RandomProviderImpl of super::IRandomProvider<ContractState> {
        fn rand(ref self: ContractState, amount: u256) -> u256 {
            self.get_fee_collector().collect(get_caller_address(), amount);
            self.get_reservoir().get()
        }

        fn set_reservoir(ref self: ContractState, new_reservoir: ContractAddress) {
            self.only_owner();
            self.reservoir.write(IEntropyReservoirDispatcher{contract_address: new_reservoir});
        }

        fn set_fee_collector(ref self: ContractState, new_fee_collector: ContractAddress) {
            self.only_owner();
            self.fee_collector.write(IFeeCollectorDispatcher{contract_address: new_fee_collector});
        }
    }

    #[generate_trait]
    impl PrivateFunctions of PrivateFunctionsTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'ONLY_OWNER');
        }

        fn get_reservoir(self: @ContractState) -> IEntropyReservoirDispatcher {
            self.reservoir.read()
        }

        fn get_fee_collector(self: @ContractState) -> IFeeCollectorDispatcher {
            self.fee_collector.read()
        }
    }
}