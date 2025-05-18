use starknet::ContractAddress;

#[starknet::interface]
pub trait IRandomProvider<TContractState> {
    fn rand(ref self: TContractState, amount: u256) -> u256;

    fn set_reservoir(ref self: TContractState, new_reservoir: ContractAddress);
    fn set_fee_collector(ref self: TContractState, new_fee_collector: ContractAddress);
}

#[starknet::contract]
mod RandomProvider {
    use starknet::event::EventEmitter;
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};
    use core_v0::reservoir::{IEntropyReservoirSafeDispatcher, IEntropyReservoirSafeDispatcherTrait};
    use core_v0::fee_collector::{IFeeCollectorDispatcher, IFeeCollectorDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        reservoir: IEntropyReservoirSafeDispatcher,
        fee_collector: IFeeCollectorDispatcher,
    }

    // Events must derive the `starknet::Event` trait
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Rand {
        pub value: u256,
    }

    #[event]
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        Rand: Rand,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl RandomProviderImpl of super::IRandomProvider<ContractState> {
        fn rand(ref self: ContractState, amount: u256) -> u256 {
            self.get_fee_collector().collect(get_caller_address(), amount);

            let entropy = match self.get_reservoir().get() {
                Result::Ok(result) => result,
                Result::Err(_) => core::panic_with_felt252('not enough entropy'),
            };

            self.emit(Event::Rand(Rand { value: entropy }));

            entropy
        }

        fn set_reservoir(ref self: ContractState, new_reservoir: ContractAddress) {
            self.only_owner();
            self.reservoir.write(IEntropyReservoirSafeDispatcher{contract_address: new_reservoir});
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

        fn get_reservoir(self: @ContractState) -> IEntropyReservoirSafeDispatcher {
            self.reservoir.read()
        }

        fn get_fee_collector(self: @ContractState) -> IFeeCollectorDispatcher {
            self.fee_collector.read()
        }
    }
}